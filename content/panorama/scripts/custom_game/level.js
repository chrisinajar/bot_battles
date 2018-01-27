
(function () {
  CustomNetTables.SubscribeNetTableListener('hero_selection', updateLevel);

  levelInit();
})();

function updateLevel (table, key, data) {
  if (key !== 'selection') {
    return;
  }

  if (data.level) {
    $("#LevelDisplay").text = data.level;
  }
}

function levelInit () {
  updateLevel(null, 'selection', CustomNetTables.GetTableValue('hero_selection', 'selection'));
}

function LevelUp () {
  GameEvents.SendCustomGameEventToServer('level_up', {
  });
}

function LevelDown () {
  GameEvents.SendCustomGameEventToServer('level_down', {
  });
}
