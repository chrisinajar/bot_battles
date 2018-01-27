
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
  var data = {
    dire: direHero,
    radiant: radiantHero
  };
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

  if (!data.radiant) {
    HeroSelectEvent('radiant');
  } else if (!data.dire) {
    HeroSelectEvent('dire');
  } else if (!currentSelection) {
    FindDotaHudElement('RightHeroPanel').RemoveClass('active');
    FindDotaHudElement('LeftHeroPanel').RemoveClass('active');
  }
  var preview = null;

  if (radiantHero !== data.radiant) {
    radiantHero = data.radiant;
    preview = FindDotaHudElement('LeftHeroPanel');
    preview.RemoveAndDeleteChildren();
    CreateHeroPanel(preview, data.radiant);
    $('#LeftHeroName').text = $.Localize('#' + data.radiant, $('#LeftHeroName'));
  }
  if (direHero !== data.dire) {
    direHero = data.dire;
    preview = FindDotaHudElement('RightHeroPanel');
    preview.RemoveAndDeleteChildren();
    CreateHeroPanel(preview, data.dire);
    $('#RightHeroName').text = $.Localize('#' + data.dire, $('#RightHeroName'));
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
