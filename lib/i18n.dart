String currentLang = 'sw';

const Map<String, List<String>> _s = {
  'hello': ['Hi', 'Habari'],
  'home': ['Home', 'Nyumbani'],
  'goals': ['Goals', 'Malengo'],
  'history': ['History', 'Historia'],
  'insights': ['Insights', 'Takwimu'],
  'log': ['Log', 'Ingiza'],
  'saving': ['Saving', 'Akiba'],
  'spending': ['Spending', 'Matumizi'],
  'welcome': ['Welcome to Akiba', 'Karibu Akiba'],
  'welcomeSub': [
    'Turn your big goal into small daily steps.',
    'Geuza lengo lako kubwa kuwa hatua ndogo za kila siku.'
  ],
  'language': ['Language', 'Lugha'],
  'yourName': ['Your name', 'Jina lako'],
  'firstGoal': ['Your main saving goal', 'Lengo lako kuu la akiba'],
  'goalName': ['What are you saving for?', 'Unaweka akiba kwa ajili ya nini?'],
  'goalAmount': ['Amount (TZS)', 'Kiasi (TZS)'],
  'deadline': ['Deadline', 'Tarehe ya mwisho'],
  'start': ['Start saving', 'Anza kuweka akiba'],
  'dailyTargetPreview': ['Daily target', 'Lengo la kila siku'],
  'required': ['Please fill in the name', 'Tafadhali jaza jina'],
  'invalidAmount': ['Enter a valid amount', 'Weka kiasi sahihi'],
  'deadlinePast': ['Deadline must be after today', 'Tarehe lazima iwe baada ya leo'],
  'deadlinePassed': ['Deadline passed', 'Muda umepita'],
  'mainGoal': ['Main goal', 'Lengo kuu'],
  'miniGoal': ['Mini-goal', 'Lengo dogo'],
  'miniGoals': ['Mini-goals', 'Malengo madogo'],
  'noMainGoal': ['You have no main goal yet', 'Bado huna lengo kuu'],
  'createGoal': ['Create goal', 'Unda lengo'],
  'newGoal': ['New goal', 'Lengo jipya'],
  'editGoal': ['Edit goal', 'Hariri lengo'],
  'saved': ['Saved', 'Umeweka'],
  'of': ['of', 'kati ya'],
  'daysLeft': ['days left', 'siku zimebaki'],
  'today': ['Today', 'Leo'],
  'yesterday': ['Yesterday', 'Jana'],
  'todayTarget': ["Today's target", 'Lengo la leo'],
  'savedToday': ['Saved today', 'Umeweka leo'],
  'spentToday': ['Spent today', 'Umetumia leo'],
  'remainingToday': ['Still to save today', 'Bado kuweka leo'],
  'targetMet': ["Today's target met!", 'Umefikia lengo la leo!'],
  'extraToday': ['Extra today', 'Ziada ya leo'],
  'extraPot': ['Extra pot', 'Mfuko wa ziada'],
  'extraTotal': ['Total extra saved', 'Jumla ya ziada'],
  'extraGoesTo': ['Extra goes to', 'Ziada inaenda'],
  'toGoal': ['Main goal (finish early)', 'Lengo kuu (maliza mapema)'],
  'toBuffer': ['Emergency buffer', 'Akiba ya dharura'],
  'buffer': ['Emergency buffer', 'Akiba ya dharura'],
  'shortYesterday': [
    "Yesterday you were short by {a}. Today's target is now {b}.",
    'Jana ulipungukiwa {a}. Lengo la leo sasa ni {b}.'
  ],
  'missedYesterday': [
    "You didn't save yesterday. Today's target is now {b}.",
    'Jana hukuweka akiba. Lengo la leo sasa ni {b}.'
  ],
  'extendDeadline': ['Extend deadline', 'Ongeza muda'],
  'streak': ['Day streak', 'Siku mfululizo'],
  'onTrack': ['On track', 'Uko sawa'],
  'behind': ['Behind schedule', 'Uko nyuma'],
  'projected': ['Projected finish', 'Utamaliza karibu'],
  'noProjection': [
    'Save a few days to see your finish date',
    'Weka akiba siku chache uone tarehe ya kumaliza'
  ],
  'goalDone': ['Goal reached! Congratulations', 'Umefikia lengo! Hongera'],
  'startNewGoal': ['Start a new main goal', 'Anza lengo kuu jipya'],
  'recent': ['Recent entries', 'Kumbukumbu za karibuni'],
  'seeAll': ['See all', 'Ona zote'],
  'noEntries': ['No entries yet', 'Bado hakuna kumbukumbu'],
  'days': ['Days', 'Siku'],
  'entries': ['Entries', 'Kumbukumbu'],
  'statusAbove': ['Above', 'Juu ya lengo'],
  'statusOn': ['On target', 'Kwenye lengo'],
  'statusShort': ['Short', 'Pungufu'],
  'statusMissed': ['Missed', 'Hukuweka'],
  'statusPending': ['Pending', 'Inasubiri'],
  'statusDone': ['Done', 'Imekamilika'],
  'target': ['Target', 'Lengo'],
  'actual': ['Actual', 'Halisi'],
  'deleteEntry': ['Delete this entry?', 'Futa kumbukumbu hii?'],
  'delete': ['Delete', 'Futa'],
  'cancel': ['Cancel', 'Ghairi'],
  'save': ['Save', 'Hifadhi'],
  'ok': ['OK', 'Sawa'],
  'amount': ['Amount (TZS)', 'Kiasi (TZS)'],
  'goal': ['Goal', 'Lengo'],
  'location': ['Where is the money?', 'Pesa ziko wapi?'],
  'paidFrom': ['Paid from (optional)', 'Imelipwa kutoka (si lazima)'],
  'category': ['Category', 'Aina'],
  'date': ['Date', 'Tarehe'],
  'note': ['Note (optional)', 'Maelezo (si lazima)'],
  'otherDay': ['Other day', 'Siku nyingine'],
  'savedMsg': ['Saved {a}', 'Umeweka {a}'],
  'savedExtraMsg': ['Saved {a}. Extra today: {b}', 'Umeweka {a}. Ziada ya leo: {b}'],
  'spentMsg': ['Recorded spending of {a}', 'Matumizi ya {a} yamerekodiwa'],
  'cat_food': ['Food', 'Chakula'],
  'cat_transport': ['Transport', 'Usafiri'],
  'cat_airtime': ['Airtime & data', 'Vocha na bando'],
  'cat_bills': ['Bills', 'Bili'],
  'cat_family': ['Family', 'Familia'],
  'cat_other': ['Other', 'Mengineyo'],
  'thisWeek': ['Last 7 days', 'Siku 7 zilizopita'],
  'savedVsSpent': ['Saved vs spent', 'Akiba dhidi ya matumizi'],
  'topSpending': ['Top spending this week', 'Matumizi makubwa wiki hii'],
  'spendingByCat': ['Spending by category (30 days)', 'Matumizi kwa aina (siku 30)'],
  'byLocation': ['Savings by location', 'Akiba kwa mahali'],
  'nothingYet': ['Nothing yet', 'Bado hakuna kitu'],
  'settings': ['Settings', 'Mipangilio'],
  'locations': ['Savings locations', 'Mahali pa akiba'],
  'addLocation': ['Add location', 'Ongeza mahali'],
  'backup': ['Backup', 'Nakala ya data'],
  'copyBackup': ['Copy backup', 'Nakili nakala'],
  'copyBackupSub': [
    'Paste it somewhere safe, e.g. WhatsApp to yourself',
    'Ibandike mahali salama, mfano WhatsApp kwako mwenyewe'
  ],
  'backupCopied': ['Backup copied', 'Nakala imenakiliwa'],
  'restore': ['Restore from backup', 'Rejesha kutoka nakala'],
  'pasteBackup': ['Paste your backup text', 'Bandika maandishi ya nakala'],
  'restored': ['Data restored', 'Data imerejeshwa'],
  'restoreFailed': ['That backup text is not valid', 'Maandishi hayo si nakala sahihi'],
  'resetAll': ['Delete all data', 'Futa data yote'],
  'resetConfirm': [
    'This deletes all goals and entries on this phone. Continue?',
    'Hii itafuta malengo na kumbukumbu zote kwenye simu hii. Endelea?'
  ],
  'archive': ['Mark as finished', 'Weka kama imekamilika'],
  'deleteGoal': ['Delete goal', 'Futa lengo'],
  'deleteGoalConfirm': [
    'Delete this goal and all its entries?',
    'Futa lengo hili na kumbukumbu zake zote?'
  ],
  'completed': ['Finished goals', 'Malengo yaliyokamilika'],
  'perDay': ['per day', 'kwa siku'],
  'due': ['Due', 'Mwisho'],
  'addMini': ['Add mini-goal', 'Ongeza lengo dogo'],
  'name': ['Name', 'Jina'],
  'legendSaved': ['Saved', 'Akiba'],
  'legendSpent': ['Spent', 'Matumizi'],
  'total': ['Total', 'Jumla'],
  'about': ['About', 'Kuhusu'],
};

String t(String key) {
  final v = _s[key];
  if (v == null) return key;
  return currentLang == 'sw' ? v[1] : v[0];
}

String tf(String key, Map<String, String> params) {
  var s = t(key);
  params.forEach((k, v) {
    s = s.replaceAll('{$k}', v);
  });
  return s;
}

const List<String> _monthsEn = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
];
const List<String> _monthsSw = [
  'Jan', 'Feb', 'Mac', 'Apr', 'Mei', 'Jun',
  'Jul', 'Ago', 'Sep', 'Okt', 'Nov', 'Des'
];
const List<String> _daysEn = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const List<String> _daysSw = ['Jtt', 'Jnn', 'Jtn', 'Alh', 'Iju', 'Jms', 'Jpl'];

String monthShort(int m) => (currentLang == 'sw' ? _monthsSw : _monthsEn)[m - 1];
String weekdayShort(int weekday) => (currentLang == 'sw' ? _daysSw : _daysEn)[weekday - 1];
