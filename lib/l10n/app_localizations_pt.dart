// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'Tabs';

  @override
  String get signIn => 'Entrar';

  @override
  String get signUp => 'Cadastrar';

  @override
  String get email => 'E-mail';

  @override
  String get password => 'Senha';

  @override
  String get confirmPassword => 'Confirmar Senha';

  @override
  String get name => 'Nome';

  @override
  String get continueWithGoogle => 'Continuar com Google';

  @override
  String get dontHaveAccount => 'Não tem uma conta?';

  @override
  String get alreadyHaveAccount => 'Já tem uma conta?';

  @override
  String get createAccount => 'Criar Conta';

  @override
  String get forgotPassword => 'Esqueceu a senha?';

  @override
  String get splitExpensesWithEase => 'Divida despesas facilmente';

  @override
  String get addExpense => 'Adicionar Despesa';

  @override
  String get editExpense => 'Editar Despesa';

  @override
  String get save => 'Salvar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get description => 'Descrição';

  @override
  String get amount => 'Valor';

  @override
  String get category => 'Categoria';

  @override
  String get date => 'Data';

  @override
  String get paidBy => 'Pago por';

  @override
  String get split => 'dividido';

  @override
  String get you => 'Você';

  @override
  String get equally => 'Igualmente';

  @override
  String get splitOptions => 'Opções de Divisão';

  @override
  String get exactAmounts => 'Valores Exatos';

  @override
  String get percentages => 'Porcentagens';

  @override
  String get remaining => 'Restante';

  @override
  String get total => 'Total';

  @override
  String get errorGeneric => 'Algo deu errado';

  @override
  String get errorRequired => 'Obrigatório';

  @override
  String get or => 'ou';

  @override
  String get joinTabs => 'Junte-se ao Tabs e comece a dividir despesas';

  @override
  String get enterEmail => 'Por favor, insira seu e-mail';

  @override
  String get validEmail => 'Por favor, insira um e-mail válido';

  @override
  String get enterPassword => 'Por favor, insira sua senha';

  @override
  String get passwordLength => 'A senha deve ter pelo menos 6 caracteres';

  @override
  String get enterName => 'Por favor, insira seu nome';

  @override
  String get confirmPasswordRequired => 'Por favor, confirme sua senha';

  @override
  String get passwordsDoNotMatch => 'As senhas não coincidem';

  @override
  String get notes => 'Notas';

  @override
  String get unequally => 'desigualmente';

  @override
  String get invalidAmount => 'Valor inválido';

  @override
  String get done => 'Pronto';

  @override
  String get selectCategory => 'Selecionar Categoria';

  @override
  String get newGroup => 'Novo Grupo';

  @override
  String get noGroupsYet => 'Ainda sem grupos';

  @override
  String get createGroupPrompt =>
      'Crie um grupo para começar a dividir despesas com amigos e família.';

  @override
  String get createGroup => 'Criar Grupo';

  @override
  String get signOut => 'Sair';

  @override
  String get loading => 'Carregando...';

  @override
  String get settledTabs => 'Grupos Quitados';

  @override
  String get tapToView => 'Toque para ver';

  @override
  String settledDaysAgo(int days) {
    return 'Quitado há $days dias';
  }

  @override
  String get tabDeleted => 'Grupo excluído';

  @override
  String get undo => 'Desfazer';

  @override
  String get noSettledTabs => 'Nenhum grupo quitado';
}
