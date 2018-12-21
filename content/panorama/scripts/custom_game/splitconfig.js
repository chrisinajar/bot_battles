
(function () {
  CustomNetTables.SubscribeNetTableListener('hero_selection', updateExpandedHeroes);
  OnHeroSelect(selectHeroTeam);
  OnHeroSelected(selectHero);

  splitConfigInit();
})();

var radiantHero = false;
var direHero = false;
var currentSelection = null;

function selectHero (heroname) {
  $.Msg(currentSelection + ' ' + heroname);
  var data = {};
  if (currentSelection === 'radiant') {
    data.radiant = heroname;
  } else {
    data.dire = heroname;
  }

  currentSelection = null;

  GameEvents.SendCustomGameEventToServer('hero_selected', data);
}

function selectHeroTeam (team) {
  $.Msg('On hero select! ' + team);
  currentSelection = team;
  if (team === 'radiant') {
    FindDotaHudElement('LeftHeroPanel').AddClass('active');
    FindDotaHudElement('RightHeroPanel').RemoveClass('active');
  } else if (team === 'dire') {
    FindDotaHudElement('RightHeroPanel').AddClass('active');
    FindDotaHudElement('LeftHeroPanel').RemoveClass('active');
  }
}

function updateExpandedHeroes (table, key, data) {
  if (key !== 'selection') {
    return;
  }
  data = data || {};
  $.Msg('hero selection reading in!');
  $.Msg(data);

  var dires = tableToArray(data.dire);
  var radiants = tableToArray(data.radiant);
  var heroCount = data.heroCount;

  if (radiants.length < heroCount) {
    HeroSelectEvent('radiant');
  } else if (dires.length < heroCount) {
    HeroSelectEvent('dire');
  } else if (!currentSelection) {
    FindDotaHudElement('RightHeroPanel').RemoveClass('active');
    FindDotaHudElement('LeftHeroPanel').RemoveClass('active');
  }
  var preview = null;

  if (radiantHero !== data.radiant[1]) {
    radiantHero = data.radiant[1];
    preview = FindDotaHudElement('LeftHeroPanel');
    preview.RemoveAndDeleteChildren();
    CreateHeroPanel(preview, data.radiant[1]);
    $('#LeftHeroName').text = $.Localize('#' + data.radiant[1], $('#LeftHeroName'));
  }
  if (direHero !== data.dire[1]) {
    direHero = data.dire[1];
    preview = FindDotaHudElement('RightHeroPanel');
    preview.RemoveAndDeleteChildren();
    CreateHeroPanel(preview, data.dire[1]);
    $('#RightHeroName').text = $.Localize('#' + data.dire[1], $('#RightHeroName'));
  }
}

function splitConfigInit () {
  updateExpandedHeroes(null, 'selection', CustomNetTables.GetTableValue('hero_selection', 'selection'));
}

function CreateHeroPanel (parent, hero) {
  var id = 'Scene' + ~~(Math.random() * 100);
  var scene = parent.BCreateChildren('<DOTAScenePanel hittest="false" id="' + id + '" style="opacity-mask: url(\'s2r://panorama/images/masks/softedge_box_png.vtex\');" drawbackground="0" renderdeferred="false" particleonly="false" unit="' + hero + '" rotateonhover="true" yawmin="-10" yawmax="10" pitchmin="-10" pitchmax="10" />');
  $.DispatchEvent('DOTAGlobalSceneSetCameraEntity', id, 'camera_end_top', 1.0);

  return scene;
}

function tableToArray (table) {
  var arr = [];
  Object.keys(table).sort().forEach(function (key) {
    arr.push(table[key]);
  });
  return arr;
}

function SetHeroCount (count) {
  GameEvents.SendCustomGameEventToServer('set_hero_count', {
    heroCount: count
  });
}
