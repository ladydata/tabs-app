// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Tabs';

  @override
  String get signIn => 'Anmelden';

  @override
  String get signUp => 'Registrieren';

  @override
  String get email => 'E-Mail';

  @override
  String get password => 'Passwort';

  @override
  String get confirmPassword => 'Passwort bestätigen';

  @override
  String get name => 'Name';

  @override
  String get continueWithGoogle => 'Weiter mit Google';

  @override
  String get dontHaveAccount => 'Kein Konto?';

  @override
  String get alreadyHaveAccount => 'Bereits registriert?';

  @override
  String get createAccount => 'Konto erstellen';

  @override
  String get forgotPassword => 'Passwort vergessen?';

  @override
  String get splitExpensesWithEase => 'Ausgaben einfach teilen';

  @override
  String get addExpense => 'Ausgabe hinzufügen';

  @override
  String get editExpense => 'Ausgabe bearbeiten';

  @override
  String get save => 'Speichern';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get description => 'Beschreibung';

  @override
  String get amount => 'Betrag';

  @override
  String get category => 'Kategorie';

  @override
  String get date => 'Datum';

  @override
  String get paidBy => 'Bezahlt von';

  @override
  String get split => 'aufgeteilt';

  @override
  String get you => 'Dir';

  @override
  String get equally => 'Gleichmäßig';

  @override
  String get splitOptions => 'Aufteilungsoptionen';

  @override
  String get exactAmounts => 'Exakte Beträge';

  @override
  String get percentages => 'Prozentsätze';

  @override
  String get remaining => 'Verbleibend';

  @override
  String get total => 'Gesamt';

  @override
  String get errorGeneric => 'Etwas ist schiefgelaufen';

  @override
  String get errorRequired => 'Erforderlich';

  @override
  String get or => 'oder';

  @override
  String get joinTabs => 'Tritt Tabs bei und teile Ausgaben';

  @override
  String get enterEmail => 'Bitte E-Mail eingeben';

  @override
  String get validEmail => 'Bitte gültige E-Mail eingeben';

  @override
  String get enterPassword => 'Bitte Passwort eingeben';

  @override
  String get passwordLength => 'Passwort muss mind. 6 Zeichen haben';

  @override
  String get enterName => 'Bitte Namen eingeben';

  @override
  String get confirmPasswordRequired => 'Bitte Passwort bestätigen';

  @override
  String get passwordsDoNotMatch => 'Passwörter stimmen nicht überein';

  @override
  String get notes => 'Notizen';

  @override
  String get unequally => 'ungleichmäßig';

  @override
  String get invalidAmount => 'Ungültiger Betrag';

  @override
  String get done => 'Fertig';

  @override
  String get selectCategory => 'Kategorie wählen';

  @override
  String get newGroup => 'Neue Gruppe';

  @override
  String get noGroupsYet => 'Noch keine Gruppen';

  @override
  String get createGroupPrompt =>
      'Erstelle eine Gruppe, um Ausgaben mit Freunden und Familie zu teilen.';

  @override
  String get createGroup => 'Gruppe erstellen';

  @override
  String get signOut => 'Abmelden';

  @override
  String get loading => 'Lädt...';

  @override
  String get settledTabs => 'Abgerechnete Tabs';

  @override
  String get tapToView => 'Tippen zum Anzeigen';

  @override
  String settledDaysAgo(int days) {
    return 'Vor $days Tagen abgerechnet';
  }

  @override
  String get tabDeleted => 'Tab gelöscht';

  @override
  String get undo => 'Rückgängig';

  @override
  String get noSettledTabs => 'Keine abgerechneten Tabs';

  @override
  String get settledTabsEmptySubtitle =>
      'Gruppen erscheinen hier 30 Tage nach der Abrechnung';
}
