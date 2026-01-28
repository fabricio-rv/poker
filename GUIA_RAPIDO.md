# Guia Rápido - Poker Home Game Manager

## 🎯 Fluxo da Aplicação

### Login → Home → Escolher Ação

```
LOGIN
  ↓
HOME (Dashboard)
  ├─→ INICIAR JOGO
  │     ↓
  │   SETUP (4 etapas)
  │     ├─ 1. Escolher Modo (Multiplayer/Gerenciador)
  │     ├─ 2. Selecionar Jogadores (mín. 2)
  │     ├─ 3. Configurar Aposta (opcional)
  │     └─ 4. Calcular Fichas
  │           ↓
  │         JOGO EM ANDAMENTO
  │           ↓
  │         FIM DE JOGO → XP atribuído
  │
  ├─→ RANKING
  │     └─ Ver Top 5 em 4 categorias
  │
  └─→ PERFIL & CONQUISTAS
        └─ Ver stats, editar perfil, sair
```

## 🔑 Credenciais de Teste

**Todos usam senha: 123**

Usuários disponíveis: João, Maria, Pedro, Ana, Carlos, Fernanda, Ricardo, Juliana

## 🎮 Recursos Principais por Tela

### 1. Login
- Campo usuário e senha
- Validação básica
- Redirecionamento automático após login

### 2. Home
- Saudação personalizada
- **Barra de XP animada** com progresso circular
- 3 botões grandes de navegação

### 3. Ranking
- **4 Tabs**: Geral | Vitórias | XP | Partidas
- Top 5 com posições
- Troféu dourado para 1º lugar

### 4. Perfil
- Avatar circular com inicial
- 4 cards de estatísticas
- Info detalhada (data entrada, XP faltante)
- Botões: Editar | Sair

### 5. Setup do Jogo
**Indicador de progresso visual** (4 passos)

**Passo 1** - Modo:
- 2 cards grandes clicáveis
- Descrição de cada modo

**Passo 2** - Jogadores:
- Lista com checkboxes
- Exibe nível e vitórias de cada um

**Passo 3** - Aposta:
- Switch Sim/Não
- Se sim: campo numérico para valor

**Passo 4** - Fichas:
- Botão "Calcular Fichas"
- Card com distribuição detalhada
- Cores e quantidades por tipo

### 6. Tela de Jogo

**Cabeçalho** (ambos modos):
- Timer (mm:ss)
- Blinds atuais (ex: 5/10)

**Modo Gerenciador**:
- Lista de jogadores
- Ícone X para eliminar
- Botão "Rebuy" para eliminados
- Contador de ativos no rodapé

**Modo Multiplayer**:
- 2 cartas do jogador (placeholder)
- Barra de probabilidade colorida
- 5 cartas da mesa (placeholder)
- Botão "Atualizar Probabilidades"

**Fim de Jogo**:
- Dialog "Quem venceu?"
- Seleção do vencedor
- XP distribuído automaticamente
- Retorno ao Home

## 📐 Fórmulas e Cálculos

### XP e Nível
```
Level = √(XP / 100)
```
Exemplo: 2500 XP = Nível 5

### Ganho de XP por Partida
```
XP base: 100
Bônus vitória: +500
Total vencedor: 600 XP
Total perdedor: 100 XP
```

### Pontuação de Ranking
```
Score = (Vitórias × 10) + (Partidas × 2) + (Nível × 5)
```
Exemplo: 15 vitórias, 45 partidas, nível 5 = 265 pontos

### Taxa de Vitória
```
Win Rate = (Vitórias / Partidas) × 100
```
Exemplo: 15/45 = 33.3%

## 🎲 Distribuição de Fichas

**Total disponível**: 200 fichas físicas

**Valores**:
- Branca: R$ 1
- Vermelha: R$ 5
- Verde: R$ 10
- Azul: R$ 25
- Preta: R$ 50

**Algoritmo por grupo**:
| Jogadores | Fichas/Jogador | Estratégia |
|-----------|----------------|------------|
| 2-4 | ~50 | Mix balanceado |
| 5-6 | ~33-40 | Foco em médias |
| 7+ | ~28 | Eficiência alta |

## 🛠️ Dicas de Desenvolvimento

### Para adicionar novos usuários mock:
Edite: `lib/services/auth_service.dart` → lista `_mockUsers`

### Para ajustar cores do tema:
Edite: `lib/utils/constants.dart` → classe `AppColors`

### Para modificar algoritmo de fichas:
Edite: `lib/services/chip_calculator_service.dart`

### Para adicionar novos providers:
1. Crie em `lib/providers/`
2. Adicione em `main.dart` no `MultiProvider`

### Estrutura de navegação:
```dart
// Push simples
Navigator.push(context, MaterialPageRoute(builder: (_) => NovaScreen()));

// Replace (sem voltar)
Navigator.pushReplacement(context, MaterialPageRoute(...));

// Limpar stack e ir para Home
Navigator.pushAndRemoveUntil(context, 
  MaterialPageRoute(builder: (_) => HomeScreen()),
  (route) => false
);
```

## 🎨 Componentes Visuais Principais

### Cards de Menu
- Cor de fundo variável
- Ícone grande (48px)
- Texto em heading2
- Seta à direita

### Cards de Estatística
- Ícone colorido no topo
- Valor grande central
- Label descritiva embaixo

### Indicador de Progresso de XP
- Círculo com borda dourada
- Número do nível centralizado
- Barra linear animada
- Texto de progresso (X / Y XP)

### Lista de Ranking
- Badge circular com posição
- Cores especiais para top 3
- Troféu para 1º lugar
- Valor da categoria à direita

## 🔄 Ciclo de Vida de um Jogo

1. **Configuração**: GameProvider.startGame()
2. **Em andamento**: Timer incrementando, blinds aumentando
3. **Eliminações**: GameProvider.eliminatePlayer(userId)
4. **Rebuys**: GameProvider.rebuyPlayer(userId)
5. **Fim detectado**: isGameFinished = true (1 jogador)
6. **Seleção vencedor**: Dialog de escolha
7. **Finalização**: GameProvider.finishGame(winnerId)
8. **XP distribuído**: UserProvider.recordMatch(isWinner)
9. **Retorno**: Home com notificação de sucesso

## 💾 Preparação para Firebase (Futuro)

Os serviços já estão estruturados para fácil migração:

```dart
// AGORA (Mock)
class AuthService {
  Future<User?> login(...) async {
    // Busca em lista local
  }
}

// FUTURO (Firebase)
class AuthService {
  Future<User?> login(...) async {
    // return await FirebaseAuth.instance.signIn...
    // ou Firestore.collection('users').where...
  }
}
```

Mesma interface, implementação diferente!

---

**Precisa de ajuda?** Verifique os comentários no código ou consulte o README.md principal.
