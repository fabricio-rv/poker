import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Retorna o usuário atual
  User? get currentUser => _auth.currentUser;

  /// Verifica se está logado
  bool get isLoggedIn => _auth.currentUser != null;

  /// Stream para ouvir mudanças de estado (Logado/Deslogado)
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Login com Email e Senha
  /// Login com Email e Senha
  Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      return {
        'success': true,
        'uid': credential.user!.uid,
        'message': 'Login realizado com sucesso!',
      };
    } on FirebaseAuthException catch (e) {
      return {'success': false, 'message': e.message ?? 'Erro ao fazer login.'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Cadastro Completo (Auth + Firestore)
  Future<Map<String, dynamic>> signUp(
    String email,
    String password,
    String name,
  ) async {
    User? user;
    try {
      // 1. Cria o usuário no Firebase Auth
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      user = credential.user;

      if (user == null) {
        return {'success': false, 'message': 'Erro ao criar usuário.'};
      }

      // 2. Atualiza o nome de exibição no Auth
      await user.updateDisplayName(name);

      // 3. CRUCIAL: Cria o documento no Firestore E ESPERA (await)
      // Isso garante que os dados existam antes do app tentar ler.
      await _firestore.collection('users').doc(user.uid).set({
        'id': user.uid,
        'username': name,
        'email': email.trim(),
        'currentXP': 0,
        'totalWins': 0,
        'totalMatches': 0,
        'avatarUrl': '',
        'joinDate': FieldValue.serverTimestamp(),
      });

      return {
        'success': true,
        'message': 'Cadastro realizado com sucesso!',
        'uid': user.uid,
      };
    } on FirebaseAuthException catch (e) {
      return {'success': false, 'message': _getAuthErrorMessage(e.code)};
    } catch (e) {
      // ROLLBACK: Se der erro no banco de dados, deleta o usuário do Auth
      // para permitir tentar cadastrar de novo com o mesmo email.
      if (user != null) {
        await user.delete();
      }
      return {
        'success': false,
        'message': 'Erro ao salvar dados. Tente novamente. Detalhes: $e',
      };
    }
  }

  /// Sair (Logout)
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Recuperar Senha
  Future<Map<String, dynamic>> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());

      return {
        'success': true,
        'message':
            'Email de recuperação enviado! Verifique sua caixa de entrada.',
      };
    } on FirebaseAuthException catch (e) {
      return {'success': false, 'message': _getAuthErrorMessage(e.code)};
    } catch (e) {
      return {
        'success': false,
        'message': 'Erro ao enviar email: ${e.toString()}',
      };
    }
  }

  /// Tradutor de Erros do Firebase
  String _getAuthErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'user-not-found':
        return 'Usuário não encontrado. Verifique o email.';
      case 'wrong-password':
        return 'Senha incorreta.';
      case 'invalid-email':
        return 'Email inválido.';
      case 'user-disabled':
        return 'Esta conta foi desabilitada.';
      case 'email-already-in-use':
        return 'Este email já está em uso.';
      case 'weak-password':
        return 'Senha muito fraca. Use pelo menos 6 caracteres.';
      case 'operation-not-allowed':
        return 'Operação não permitida.';
      case 'invalid-credential':
        return 'Credenciais inválidas.';
      case 'too-many-requests':
        return 'Muitas tentativas. Tente novamente mais tarde.';
      case 'network-request-failed':
        return 'Erro de conexão. Verifique sua internet.';
      default:
        return 'Erro de autenticação: $errorCode';
    }
  }
}
