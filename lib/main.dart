import 'package:flutter/material.dart';
import 'dart:math';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:async';
import 'package:share_plus/share_plus.dart';
import 'package:screenshot/screenshot.dart'; // 👈 Novo
import 'package:path_provider/path_provider.dart'; // 👈 Novo
import 'dart:typed_data';
import 'dart:io';

Future<void> main() async {
  // Garante que o Flutter esteja pronto antes de chamar o Firebase
  WidgetsFlutterBinding.ensureInitialized();

  // Inicia a conexão com o banco de dados usando as chaves recém-criadas
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const RodizioApp()); // Mantenha o nome da sua classe principal aqui
}

class RodizioApp extends StatelessWidget {
  const RodizioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
        useMaterial3: true,
      ),
      home: const WelcomePage(),
    );
  }
}

// --- TELA DE BOAS-VINDAS ---
class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.all(30),
        width: double.infinity,
        color: Colors.orange[50],
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/logo.png',
              height: 190, // Ajuste a altura conforme o design do seu logo
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 0),
            const Text(
              'RodízioScore',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: Colors.orange,
              ),
            ),
            const Text(
              'O terror dos restaurantes',
              style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 20),
            _botaoBoasVindas(
              context,
              'Mesa para um',
              'Aproveitar o rodízio em paz',
              Icons.person,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SelecaoPage()),
              ),
            ),
            const SizedBox(height: 20),
            _botaoBoasVindas(
              context,
              'Mesa de Amigos',
              'O prejuízo vem forte',
              Icons.group,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const GroupMenuPage()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _botaoBoasVindas(
    BuildContext context,
    String titulo,
    String subtitulo,
    IconData icone,
    VoidCallback acao,
  ) {
    return ElevatedButton(
      onPressed: acao,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        elevation: 5,
      ),
      child: Row(
        children: [
          Icon(icone, size: 40, color: Colors.orange),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Text(
                subtitulo,
                style: const TextStyle(fontSize: 14, color: Colors.black54),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// --- MENU DE GRUPO ---
class GroupMenuPage extends StatefulWidget {
  const GroupMenuPage({super.key});

  @override
  State<GroupMenuPage> createState() => _GroupMenuPageState();
}

class _GroupMenuPageState extends State<GroupMenuPage> {
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _codigoController = TextEditingController();
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  String _gerarCodigo() {
    const chars = '0123456789';
    return String.fromCharCodes(
      Iterable.generate(
        4,
        (_) => chars.codeUnitAt(Random().nextInt(chars.length)),
      ),
    );
  }

  void _abrirDialogoCriarMesa() {
    String? erroNome;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Criar Nova Mesa'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _nomeController,
                    decoration: InputDecoration(
                      // 👈 REMOVIDO O 'const' DAQUI
                      labelText: 'Seu Nome',
                      errorText: erroNome,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'O que vamos devorar?',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    children: _opcoesBuffet.map((opcao) {
                      bool selecionado = _tipoSelecionado == opcao['tipo'];
                      return ChoiceChip(
                        label: Text(
                          opcao['emoji']!,
                          style: const TextStyle(fontSize: 24),
                        ),
                        selected: selecionado,
                        onSelected: (bool selected) {
                          setDialogState(() {
                            _tipoSelecionado = opcao['tipo']!;
                            _emojiSelecionado = opcao['emoji']!;
                          });
                        },
                        selectedColor: Colors.orange[200],
                      );
                    }).toList(),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    // 1. Resetamos o erro no início do clique 🧹
                    setDialogState(() => erroNome = null);

                    // 2. Validação 🛑
                    if (_nomeController.text.trim().isEmpty) {
                      setDialogState(() {
                        erroNome = 'Esqueceu o nome, fominha!';
                      });
                      return;
                    }

                    // 3. Se passou, gera a mesa 🚀
                    String codigo = _gerarCodigo();
                    String nome = _nomeController.text;

                    await _database.child('mesas').child(codigo).set({
                      'status': 'espera',
                      'criador': nome,
                      'tipo': _tipoSelecionado,
                      'emoji': _emojiSelecionado,
                      'participantes': {
                        nome: {'nome': nome, 'pontuacao': 0},
                      },
                    });

                    if (context.mounted) {
                      Navigator.pop(context);
                      _mostrarCodigoGerado(codigo);
                    }
                  },
                  child: const Text('CRIAR MESA'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _mostrarCodigoGerado(String codigo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mesa Criada!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Compartilhe este código com seus amigos:'),
            const SizedBox(height: 20),
            Text(
              codigo,
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.w900,
                color: Colors.orange,
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SalaEsperaPage(
                    codigo: codigo,
                    seuNome: _nomeController.text,
                  ),
                ),
              );
            },
            child: const Text('ENTRAR NA SALA'),
          ),
        ],
      ),
    );
  }

  void _abrirDialogoEntrarMesa() {
    String? erroNome;
    String? erroCodigo;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          // 👈 Necessário para atualizar os erros no diálogo
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Entrar na Mesa'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _nomeController,
                      decoration: InputDecoration(
                        // 👈 'const' removido para usar variáveis
                        labelText: 'Seu Nome',
                        border: const OutlineInputBorder(),
                        errorText: erroNome, // 👈 Vincula o erro ao campo
                      ),
                    ),
                    const SizedBox(height: 15),
                    const Text('Código da Mesa:'),
                    TextField(
                      controller: _codigoController,
                      maxLength: 4,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 10,
                        color: Colors.orange,
                      ),
                      decoration: InputDecoration(
                        // 👈 'const' removido
                        hintText: '____',
                        border: const OutlineInputBorder(),
                        errorText: erroCodigo, // 👈 Vincula o erro ao campo
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    // 1. Resetamos os estados de erro no clique 🧹
                    setDialogState(() {
                      erroNome = null;
                      erroCodigo = null;
                    });

                    bool temErro = false;

                    // 2. Validações Básicas 🛑
                    if (_nomeController.text.trim().isEmpty) {
                      setDialogState(() => erroNome = 'Quem é você?');
                      temErro = true;
                    }
                    if (_codigoController.text.length < 4) {
                      setDialogState(() => erroCodigo = 'São 4 dígitos!');
                      temErro = true;
                    }

                    if (temErro) return;

                    // 3. Busca no Firebase 🚀
                    String codigoDigitado = _codigoController.text
                        .toUpperCase();
                    String nomeUsuario = _nomeController.text.trim();

                    DataSnapshot snapshot = await _database
                        .child('mesas')
                        .child(codigoDigitado)
                        .get();

                    if (snapshot.exists) {
                      Map<dynamic, dynamic> mesaData =
                          snapshot.value as Map<dynamic, dynamic>;
                      Map<dynamic, dynamic> participantes =
                          mesaData['participantes'] ?? {};

                      // 🛑 TRAVA DE NOME DUPLICADO (Agora no campo de erro)
                      if (participantes.containsKey(nomeUsuario)) {
                        setDialogState(() => erroNome = 'Nome já ocupado!');
                        return;
                      }

                      // Se passou em tudo, entra normalmente
                      await _database
                          .child('mesas')
                          .child(codigoDigitado)
                          .child('participantes')
                          .child(nomeUsuario)
                          .set({'nome': nomeUsuario, 'pontuacao': 0});

                      if (context.mounted) {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SalaEsperaPage(
                              codigo: codigoDigitado,
                              seuNome: nomeUsuario,
                            ),
                          ),
                        );
                      }
                    } else {
                      // 🛑 Se a mesa não existe, avisamos direto no campo de código
                      setDialogState(() => erroCodigo = 'Mesa não encontrada!');
                    }
                  },
                  child: const Text('ENTRAR NA SALA'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configurar Mesa')),
      body: Padding(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/mesa.png',
              height: 200,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 10),
            const Text(
              'Mesa de Amigos',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'O ranking atualiza em tempo real enquanto vocês comem!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _abrirDialogoCriarMesa,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 60),
                backgroundColor: Colors.orange,
              ),
              child: const Text(
                'COMEÇAR UMA MESA',
                style: TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(height: 15),
            OutlinedButton(
              onPressed: _abrirDialogoEntrarMesa,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 60),
              ),
              child: const Text('ENTRAR EM UMA MESA EXISTENTE'),
            ),
          ],
        ),
      ),
    );
  }
}

// Dentro da classe _GroupMenuPageState
String _tipoSelecionado = 'sushi';
String _emojiSelecionado = '🍣';

final List<Map<String, String>> _opcoesBuffet = [
  {'tipo': 'sushi', 'emoji': '🍣'},
  {'tipo': 'pizza', 'emoji': '🍕'},
  {'tipo': 'carne', 'emoji': '🍖'},
  {'tipo': 'esfirra', 'emoji': '🫓'},
  {'tipo': 'variado', 'emoji': '🍽️'},
];

// --- TELA DE SALA DE ESPERA (MULTIPLAYER AO VIVO) ---
class SalaEsperaPage extends StatefulWidget {
  final String codigo;
  final String seuNome;

  const SalaEsperaPage({
    super.key,
    required this.codigo,
    required this.seuNome,
  });

  @override
  State<SalaEsperaPage> createState() => _SalaEsperaPageState();
}

class _SalaEsperaPageState extends State<SalaEsperaPage> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  late StreamSubscription _mesaSubscription;

  @override
  void initState() {
    super.initState();
    _mesaSubscription = _database
        .child('mesas')
        .child(widget.codigo)
        .onValue
        .listen((event) {
          if (event.snapshot.exists) {
            Map<dynamic, dynamic> mesaData =
                event.snapshot.value as Map<dynamic, dynamic>;

            // No initState da SalaEsperaPage, onde você escuta o status 'iniciado'
            if (mesaData['status'] == 'iniciado') {
              if (mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ContadorPage(
                      codigo: widget.codigo,
                      tipo: mesaData['tipo'] ?? 'sushi', // 👈 Busca do Firebase
                      emoji: mesaData['emoji'] ?? '🍣', // 👈 Busca do Firebase
                      nome: widget.seuNome,
                    ),
                  ),
                );
              }
            }
          }
        });
  }

  @override
  void dispose() {
    _mesaSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sala de Espera')),
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(25),
        child: Column(
          children: [
            const Text(
              'CÓDIGO DA MESA',
              style: TextStyle(letterSpacing: 2, fontWeight: FontWeight.bold),
            ),
            Text(
              widget.codigo,
              style: const TextStyle(
                fontSize: 60,
                fontWeight: FontWeight.w900,
                color: Colors.orange,
                letterSpacing: 8,
              ),
            ),
            const Divider(height: 40),
            const Text(
              'QUEM JÁ CHEGOU NO RESTAURANTE:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 20),

            Expanded(
              child: StreamBuilder(
                stream: _database.child('mesas').child(widget.codigo).onValue,
                builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.orange),
                    );
                  }

                  if (snapshot.hasData &&
                      snapshot.data!.snapshot.value != null) {
                    Map<dynamic, dynamic> mesaData =
                        snapshot.data!.snapshot.value as Map<dynamic, dynamic>;

                    String lider = mesaData['criador'] ?? '';
                    bool souLider = lider == widget.seuNome;

                    Map<dynamic, dynamic> participantesMap =
                        mesaData['participantes'] ?? {};
                    List<dynamic> participantesLista = participantesMap.values
                        .toList();

                    bool todosProntos = true;
                    bool euEstouPronto = false;

                    for (var p in participantesLista) {
                      if (p['nome'] == widget.seuNome && p['pronto'] == true) {
                        euEstouPronto = true;
                      }
                      if (p['nome'] != lider &&
                          (p['pronto'] == null || p['pronto'] == false)) {
                        todosProntos = false;
                      }
                    }

                    return Column(
                      children: [
                        Expanded(
                          child: ListView.builder(
                            itemCount: participantesLista.length,
                            itemBuilder: (context, index) {
                              var participante = participantesLista[index];
                              // 👈 Emoji agora é fixo e neutro
                              const String emojiNeutro = '👤';
                              bool isLiderThisUser =
                                  participante['nome'] == lider;
                              bool isPronto = participante['pronto'] == true;

                              return Card(
                                elevation: 2,
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.orange.shade100,
                                    child: const Text(
                                      emojiNeutro,
                                      style: TextStyle(fontSize: 24),
                                    ),
                                  ),
                                  title: Row(
                                    children: [
                                      Text(
                                        participante['nome'],
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      if (isLiderThisUser)
                                        const Text(
                                          ' 👑',
                                          style: TextStyle(fontSize: 16),
                                        ),
                                    ],
                                  ),
                                  trailing: isLiderThisUser
                                      ? const Text(
                                          'Líder',
                                          style: TextStyle(
                                            color: Colors.orange,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        )
                                      : (isPronto
                                            ? const Text(
                                                'Pronto ✅',
                                                style: TextStyle(
                                                  color: Colors.green,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              )
                                            : const Text(
                                                'Aguardando...',
                                                style: TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: 12,
                                                ),
                                              )),
                                ),
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 20),

                        if (souLider)
                          ElevatedButton(
                            onPressed: todosProntos
                                ? () async {
                                    await _database
                                        .child('mesas')
                                        .child(widget.codigo)
                                        .update({'status': 'iniciado'});
                                  }
                                : null,
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 60),
                              backgroundColor: Colors.green,
                              disabledBackgroundColor: Colors.grey.shade300,
                              foregroundColor: Colors.white,
                            ),
                            child: Text(
                              todosProntos
                                  ? 'INICIAR COMPETIÇÃO!'
                                  : 'Aguardando jogadores...',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        else
                          ElevatedButton(
                            onPressed: euEstouPronto
                                ? null
                                : () async {
                                    await _database
                                        .child('mesas')
                                        .child(widget.codigo)
                                        .child('participantes')
                                        .child(widget.seuNome)
                                        .update({'pronto': true});
                                  },
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 60),
                              backgroundColor: Colors.blue,
                              disabledBackgroundColor: Colors.grey.shade300,
                              foregroundColor: Colors.white,
                            ),
                            child: Text(
                              euEstouPronto
                                  ? 'Aguardando o Líder iniciar...'
                                  : 'ESTOU PRONTO ✋',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    );
                  }

                  return const Center(child: Text('Ninguém na mesa ainda.'));
                },
              ),
            ),

            TextButton(
              onPressed: () async {
                // 1. Antes de sair, verificamos quem é o dono da mesa 👑
                DataSnapshot snapshot = await _database
                    .child('mesas')
                    .child(widget.codigo)
                    .get();

                if (snapshot.exists) {
                  Map<dynamic, dynamic> mesaData =
                      snapshot.value as Map<dynamic, dynamic>;
                  String lider = mesaData['criador'] ?? '';

                  // 2. Se VOCÊ for o líder, a mesa é removida para todos
                  if (widget.seuNome == lider) {
                    debugPrint(
                      "🧹 Líder abandonou a espera. Deletando mesa ${widget.codigo}",
                    );
                    await _database
                        .child('mesas')
                        .child(widget.codigo)
                        .remove();
                  } else {
                    // 3. Se for convidado, apenas remove o seu nome da lista de participantes
                    debugPrint("🚶 Convidado saiu da mesa.");
                    await _database
                        .child('mesas')
                        .child(widget.codigo)
                        .child('participantes')
                        .child(widget.seuNome)
                        .remove();
                  }
                }

                // 4. Volta para a tela anterior
                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
              child: const Text(
                'Sair da Mesa',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- TELA DE SELEÇÃO ---
class SelecaoPage extends StatefulWidget {
  const SelecaoPage({super.key});

  @override
  State<SelecaoPage> createState() => _SelecaoPageState();
}

class _SelecaoPageState extends State<SelecaoPage> {
  final TextEditingController _nomeController = TextEditingController();

  void abrirContador(BuildContext context, String tipo, String emoji) {
    if (_nomeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ei! Digite seu nome para começar o prejuízo! 🫵'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ContadorPage(
          tipo: tipo,
          emoji: emoji,
          nome: _nomeController.text,
          // Gênero removido daqui
        ),
      ),
    );
  }

  void perguntarNomeItem(BuildContext context) {
    String nomePersonalizado = "";
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Rodízio de quê? 🤔'),
          content: TextField(
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Ex: Massa, Sorvete, Pastel...',
            ),
            onChanged: (val) => nomePersonalizado = val,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nomePersonalizado.isNotEmpty) {
                  Navigator.pop(context);
                  abrirContador(context, nomePersonalizado, '🍽️');
                }
              },
              child: const Text('Bora!'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Qual é o rodízio de hoje?')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(
              controller: _nomeController,
              decoration: InputDecoration(
                labelText: 'Seu nome',
                prefixIcon: const Icon(Icons.person),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
            const SizedBox(height: 25), // Aumentei um pouco o espaço aqui
            // A Row de gênero que ficava aqui foi removida para simplificar o fluxo.
            _botao(context, 'Rodízio de sushi', '🍣', Colors.red[50]!, 'sushi'),
            const SizedBox(height: 15),
            _botao(
              context,
              'Rodízio de pizza',
              '🍕',
              Colors.orange[50]!,
              'pizza',
            ),
            const SizedBox(height: 15),
            _botao(
              context,
              'Rodízio de carne',
              '🍖',
              const Color.fromARGB(255, 236, 215, 204),
              'carne',
            ),
            const SizedBox(height: 15),
            _botao(
              context,
              'Rodízio de esfirra',
              '🫓',
              Colors.green[50]!,
              'esfirra',
            ),
            const SizedBox(height: 15),
            _botao(
              context,
              'Rodízio variado',
              '🍽️',
              Colors.blue[50]!,
              'variado',
              custom: true,
            ),
          ],
        ),
      ),
    );
  }

  // Widget _botaoGenero removido para manter a neutralidade.

  Widget _botao(
    BuildContext context,
    String label,
    String emoji,
    Color cor,
    String tipo, {
    bool custom = false,
  }) {
    return InkWell(
      onTap: () => custom
          ? perguntarNomeItem(context)
          : abrirContador(context, tipo, emoji),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(
          color: cor,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.black12),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 30)),
            const SizedBox(width: 20),
            Text(
              label,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

// --- TELA DO CONTADOR ---
class ContadorPage extends StatefulWidget {
  final String? codigo;
  final String tipo;
  final String emoji;
  final String nome;
  // Gênero removido do construtor 👈

  const ContadorPage({
    super.key,
    this.codigo,
    required this.tipo,
    required this.emoji,
    required this.nome,
  });

  @override
  State<ContadorPage> createState() => _ContadorPageState();
}

class _ContadorPageState extends State<ContadorPage> {
  int contador = 0;
  double _escala = 1.0;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  late StreamSubscription? _mesaSubscription;

  @override
  void initState() {
    super.initState();
    if (widget.codigo != null) {
      _mesaSubscription = _database
          .child('mesas')
          .child(widget.codigo!)
          .onValue
          .listen((event) {
            if (event.snapshot.exists) {
              Map<dynamic, dynamic> mesaData =
                  event.snapshot.value as Map<dynamic, dynamic>;
              if (mesaData['status'] == 'finalizado') {
                if (mounted) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ResultadoPage(
                        codigo: widget.codigo,
                        tipo: widget.tipo,
                        emoji: widget.emoji,
                        total: contador,
                        nome: widget.nome,
                      ),
                    ),
                  );
                }
              }
            }
          });
    }
  }

  @override
  void dispose() {
    if (widget.codigo != null) _mesaSubscription?.cancel();
    super.dispose();
  }

  final Map<String, String> _imagens = {
    'sushi': 'assets/images/sushi.png',
    'pizza': 'assets/images/pizza.png',
    'carne': 'assets/images/carne.png',
    'esfirra': 'assets/images/esfirra.png',
    'variado': 'assets/images/variados.png',
  };

  String obterFrase() {
    if (contador == 0) return "Ainda no zero? O dono agradece!";
    if (widget.tipo == 'sushi') {
      if (contador <= 5) return "Só no aquecimento?";
      if (contador <= 10) return "O sushiman começou a te encarar";
      if (contador <= 20) return "O dono do rodízio está chorando no estoque";
      if (contador <= 35) return "Extinção do salmão detectada";
      return "O JAPÃO LIGOU RECLAMANDO";
    }

    if (widget.tipo == 'pizza') {
      if (contador <= 3) return "Isso foi só a borda?";
      if (contador <= 6) return "O queijo está começando a pesar...";
      if (contador <= 9) return "A pizzaria está operando no vermelho!";
      if (contador <= 15) return "Seu estômago é um buraco negro?";
      return "A Itália declarou guerra contra você";
    }

    if (widget.tipo == 'carne') {
      if (contador <= 4) return "Isso foi só o pãozinho de alho?";
      if (contador <= 8) return "O garçom da picanha passou direto";
      if (contador <= 12) return "O boi lá fora está ficando nervoso";
      if (contador <= 20) return "Você já comeu metade de um bezerro!";
      return "Bad ending: O restaurante vai fechar para balanço";
    }

    if (widget.tipo == 'esfirra') {
      if (contador <= 5) return "Só as de queijo para abrir o apetite?";
      if (contador <= 10) return "O limão acabou, mas a sua fome não!";
      if (contador <= 15) {
        return "A pilha de pratinhos está ficando perigosa...";
      }
      if (contador <= 25) {
        return "O Sheikh ligou: o estoque mundial de trigo acabou!";
      }
      return "O gênio da lâmpada fugiu de medo da sua fome";
    }

    if (contador <= 5) return "Começando os trabalhos...";
    if (contador <= 10) return "Já deu pra sentir o gosto!";
    if (contador <= 15) return "O prato está indo e voltando sem parar!";
    if (contador <= 25) return "Rumo à falência... do restaurante!";
    return "A COZINHA PEDIU ARREGO!";
  }

  @override
  Widget build(BuildContext context) {
    String imagemAtiva = _imagens[widget.tipo] ?? 'assets/images/variados.png';

    return Scaffold(
      appBar: AppBar(
        title: Text('Contador de ${widget.nome}'),
        backgroundColor: Colors.transparent,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.orange[50]!, Colors.orange[100]!],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  obterFrase(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.deepOrange,
                  ),
                ),
              ),

              // Placar ao vivo (Neutralizado)
              if (widget.codigo != null)
                Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 15,
                  ),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.orange.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  height: 107,
                  child: StreamBuilder(
                    stream: _database
                        .child('mesas')
                        .child(widget.codigo!)
                        .child('participantes')
                        .onValue,
                    builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
                      if (!snapshot.hasData ||
                          snapshot.data!.snapshot.value == null) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: Colors.orange,
                          ),
                        );
                      }
                      Map<dynamic, dynamic> participantesMap =
                          snapshot.data!.snapshot.value
                              as Map<dynamic, dynamic>;
                      List<dynamic> participantes = participantesMap.values
                          .toList();
                      participantes.sort(
                        (a, b) => (b['pontuacao'] ?? 0).compareTo(
                          a['pontuacao'] ?? 0,
                        ),
                      );

                      return ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: participantes.length,
                        itemBuilder: (context, index) {
                          var p = participantes[index];
                          bool souEu = p['nome'] == widget.nome;
                          bool jaTerminou = p['terminou'] == true;
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  index == 0 && p['pontuacao'] > 0
                                      ? '👑'
                                      : '👤',
                                  style: TextStyle(
                                    fontSize: 24,
                                    color: jaTerminou
                                        ? Colors.grey.withValues(alpha: 0.5)
                                        : null,
                                  ),
                                ),
                                Text(
                                  p['nome'] + (jaTerminou ? ' 🏁' : ''),
                                  style: TextStyle(
                                    fontWeight: souEu
                                        ? FontWeight.w900
                                        : FontWeight.bold,
                                    color: jaTerminou
                                        ? Colors.grey
                                        : (souEu
                                              ? Colors.deepOrange
                                              : Colors.black87),
                                    decoration: jaTerminou
                                        ? TextDecoration.lineThrough
                                        : null,
                                  ),
                                ),
                                Text(
                                  '${p['pontuacao']} ${widget.emoji}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 18,
                                    color: jaTerminou
                                        ? Colors.grey
                                        : Colors.orange,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),

              const Spacer(),
              GestureDetector(
                onTapDown: (_) => setState(() => _escala = 0.95),
                onTapUp: (_) {
                  setState(() {
                    _escala = 1.0;
                    contador++;
                  });
                  if (widget.codigo != null) {
                    _database
                        .child('mesas')
                        .child(widget.codigo!)
                        .child('participantes')
                        .child(widget.nome)
                        .update({'pontuacao': contador});
                  }
                },
                child: AnimatedScale(
                  scale: _escala,
                  duration: const Duration(milliseconds: 100),
                  child: Image.asset(
                    imagemAtiva,
                    width: 220,
                    height: 220,
                    fit: BoxFit.contain,
                  ),
                ),
              ),

              Text(
                '$contador',
                style: TextStyle(
                  fontSize: 80,
                  color: Colors.orange[900],
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Toque para devorar ${widget.emoji}',
                style: TextStyle(
                  color: Colors.orange[900],
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),

              // --- 🛠️ OS BOTÕES INTELIGENTES ---
              if (widget.codigo == null) ...[
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ResultadoPage(
                          codigo: null,
                          tipo: widget.tipo,
                          emoji: widget.emoji,
                          total: contador,
                          nome: widget.nome,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 15,
                    ),
                  ),
                  child: const Text(
                    'FECHAR A CONTA 🧾',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ] else ...[
                StreamBuilder(
                  stream: _database
                      .child('mesas')
                      .child(widget.codigo!)
                      .onValue,
                  builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
                    if (!snapshot.hasData ||
                        snapshot.data!.snapshot.value == null) {
                      return const CircularProgressIndicator(
                        color: Colors.orange,
                      );
                    }

                    Map<dynamic, dynamic> mesaData =
                        snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
                    String lider = mesaData['criador'] ?? '';
                    bool souLider = lider == widget.nome;
                    Map<dynamic, dynamic> participantesMap =
                        mesaData['participantes'] ?? {};
                    List<dynamic> participantesLista = participantesMap.values
                        .toList();

                    bool todosTerminaram = true;
                    bool euTerminei = false;

                    for (var p in participantesLista) {
                      if (p['nome'] == widget.nome && p['terminou'] == true) {
                        euTerminei = true;
                      }
                      if (p['nome'] != lider &&
                          (p['terminou'] == null || p['terminou'] == false)) {
                        todosTerminaram = false;
                      }
                    }

                    if (souLider) {
                      return ElevatedButton(
                        onPressed: todosTerminaram
                            ? () async {
                                await _database
                                    .child('mesas')
                                    .child(widget.codigo!)
                                    .update({'status': 'finalizado'});
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          disabledBackgroundColor: Colors.grey.shade300,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 15,
                          ),
                        ),
                        child: Text(
                          todosTerminaram
                              ? 'ENCERRAR RODÍZIO 🧾'
                              : 'Alguém ainda está com fome...',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      );
                    } else {
                      return ElevatedButton(
                        onPressed: euTerminei
                            ? null
                            : () async {
                                await _database
                                    .child('mesas')
                                    .child(widget.codigo!)
                                    .child('participantes')
                                    .child(widget.nome)
                                    .update({'terminou': true});
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          disabledBackgroundColor: Colors.grey.shade300,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 15,
                          ),
                        ),
                        child: Text(
                          euTerminei
                              ? 'Aguardando o Líder encerrar...'
                              : 'CHEGA, ENCHI! 🥵',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      );
                    }
                  },
                ),
              ],

              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "Sair da Mesa",
                  style: TextStyle(color: Colors.red),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// --- TELA DE RESULTADO (FINAL E HÍBRIDA) ---
class ResultadoPage extends StatefulWidget {
  final String? codigo;
  final String tipo;
  final String emoji;
  final int total;
  final String nome;

  const ResultadoPage({
    super.key,
    this.codigo,
    required this.tipo,
    required this.emoji,
    required this.total,
    required this.nome,
  });

  @override
  State<ResultadoPage> createState() => _ResultadoPageState();
}

class _ResultadoPageState extends State<ResultadoPage> {
  final ScreenshotController screenshotController = ScreenshotController();
  late String tituloConquistado;

  @override
  void initState() {
    super.initState();
    tituloConquistado = obterTituloAleatorio();

    if (widget.codigo != null) {
      _configurarLimpezaInvisivel();
    }
  }

  void _configurarLimpezaInvisivel() async {
    final refMesa = FirebaseDatabase.instance
        .ref()
        .child('mesas')
        .child(widget.codigo!);
    DataSnapshot snapshot = await refMesa.get();

    if (snapshot.exists) {
      Map mesaData = snapshot.value as Map;
      String criador = mesaData['criador'] ?? '';

      if (widget.nome == criador) {
        // ✅ debugPrint resolve o aviso de linting do VS Code
        debugPrint(
          "⏳ Timer de 10 minutos iniciado para a mesa ${widget.codigo}",
        );

        // 💡 Ajustado para 10 minutos conforme planejado
        Future.delayed(const Duration(minutes: 10), () async {
          DataSnapshot check = await refMesa.get();
          if (check.exists) {
            await refMesa.remove();
            debugPrint("🧹 Mesa ${widget.codigo} deletada automaticamente.");
          }
        });
      }
    }
  }

  String obterImagemResultado() {
    final Map<String, String> imagensFim = {
      'sushi': 'assets/images/sushi_fim.png',
      'pizza': 'assets/images/pizza_fim.png',
      'carne': 'assets/images/carne_fim.png',
      'esfirra': 'assets/images/esfirra_fim.png',
      'variado': 'assets/images/variados_fim.png',
    };
    return imagensFim[widget.tipo] ?? 'assets/images/variados_fim.png';
  }

  String obterTituloAleatorio() {
    final titulos = [
      "A LENDA DO RODÍZIO",
      "ESTÔMAGO SEM FUNDO",
      "CEO DO BUFFET",
      "O TERROR DA GERÊNCIA",
      "A MÁQUINA DE TRITURAR",
      "FENÔMENO DA DEGUSTAÇÃO",
      "PERSONA NON GRATA NO ESTABELECIMENTO",
      "DESTRUIDOR DE ESTOQUE",
    ];
    return (List.from(titulos)..shuffle()).first;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('O Veredito Final')),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 10),

              Screenshot(
                controller: screenshotController,
                child: Container(
                  width: 360,
                  height: 640,
                  color: Colors.orange[50],
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const SizedBox(height: 15),
                      Text(
                        widget.nome.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Colors.deepOrange,
                        ),
                      ),
                      Text(
                        tituloConquistado,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          letterSpacing: 1,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            obterImagemResultado(),
                            height: 90,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(width: 15),
                          Text(
                            '${widget.total}',
                            style: const TextStyle(
                              fontSize: 55,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'itens de ${widget.tipo} devorados!',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 15),
                      if (widget.codigo != null) ...[
                        const Text(
                          '🏆 RANKING FINAL 🏆',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: Colors.orange,
                          ),
                        ),
                        const SizedBox(height: 5),
                        StreamBuilder(
                          stream: FirebaseDatabase.instance
                              .ref()
                              .child('mesas')
                              .child(widget.codigo!)
                              .child('participantes')
                              .onValue,
                          builder:
                              (context, AsyncSnapshot<DatabaseEvent> snapshot) {
                                if (!snapshot.hasData ||
                                    snapshot.data!.snapshot.value == null) {
                                  return const SizedBox();
                                }
                                Map<dynamic, dynamic> map =
                                    snapshot.data!.snapshot.value
                                        as Map<dynamic, dynamic>;
                                List<dynamic> participantes = map.values
                                    .toList();
                                participantes.sort(
                                  (a, b) => (b['pontuacao'] ?? 0).compareTo(
                                    a['pontuacao'] ?? 0,
                                  ),
                                );
                                var topExibicao = participantes
                                    .take(10)
                                    .toList();
                                return Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(15),
                                    border: Border.all(
                                      color: Colors.orange.withValues(
                                        alpha: 0.3,
                                      ),
                                    ),
                                  ),
                                  child: Column(
                                    children: topExibicao.asMap().entries.map((
                                      entry,
                                    ) {
                                      int idx = entry.key;
                                      var p = entry.value;
                                      return ListTile(
                                        dense: true,
                                        visualDensity: const VisualDensity(
                                          vertical: -4,
                                        ),
                                        leading: Text(
                                          idx == 0 ? '👑' : '#${idx + 1}',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        title: Text(
                                          p['nome'].toString().toUpperCase(),
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        trailing: Text(
                                          '${p['pontuacao']} ${widget.emoji}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w900,
                                            color: Colors.orange,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                );
                              },
                        ),
                      ],
                      const SizedBox(height: 15),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              ElevatedButton.icon(
                onPressed: () async {
                  final RenderBox? box =
                      context.findRenderObject() as RenderBox?;
                  final Uint8List? imageBytes = await screenshotController
                      .capture(pixelRatio: 3.0);
                  if (imageBytes != null) {
                    final tempDir = await getTemporaryDirectory();
                    final file = await File(
                      '${tempDir.path}/proeza_916.png',
                    ).create();
                    await file.writeAsBytes(imageBytes);
                    await Share.shareXFiles(
                      [XFile(file.path)],
                      text:
                          "🔥 ${widget.nome.toUpperCase()} ACABOU COM O RODÍZIO! 🔥",
                      sharePositionOrigin: box != null
                          ? box.localToGlobal(Offset.zero) & box.size
                          : null,
                    );
                  }
                },
                icon: const Icon(Icons.share),
                label: const Text(
                  'COMPARTILHAR PROEZA',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(250, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),

              TextButton(
                onPressed: () {
                  // 💡 REMOVIDA a exclusão imediata (ref.remove()) daqui!
                  // Agora apenas o timer invisível de 10 minutos cuida da limpeza.
                  debugPrint(
                    "🚪 Líder saindo. A mesa continuará ativa pelo timer.",
                  );

                  if (context.mounted) {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  }
                },
                child: const Text(
                  'Voltar ao Início',
                  style: TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
