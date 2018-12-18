
var HUD = $.GetContextPanel().GetParent().GetParent().GetParent().FindChildTraverse("HUDElements");
var radiantScore = HUD.FindChildTraverse("TopBarRadiantScore");
var direScore = HUD.FindChildTraverse("TopBarDireScore");

(function () {
  CustomNetTables.SubscribeNetTableListener('hero_selection', updateMenuVisibility);
  updateMenuVisibility(null, 'selection', CustomNetTables.GetTableValue('hero_selection', 'selection'));
})();

function updateMenuVisibility (table, key, data) {
  if (key !== 'selection') {
    return;
  }

  data = data || {};

  if (data.isSelecting) {
    $.GetContextPanel().AddClass('hidden');
  } else {
    $.GetContextPanel().RemoveClass('hidden');
  }
  radiantScore.text = data.radiantKills || 0;
  direScore.text = data.direKills || 0;
}

function DoneShopping () {
  GameEvents.SendCustomGameEventToServer('done_shopping', {});
}
