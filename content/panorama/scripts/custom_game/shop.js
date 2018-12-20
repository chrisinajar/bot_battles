
var HUD = $.GetContextPanel().GetParent().GetParent().GetParent().FindChildTraverse("HUDElements");
var radiantScore = HUD.FindChildTraverse("TopBarRadiantScore");
var direScore = HUD.FindChildTraverse("TopBarDireScore");

(function () {
  CustomNetTables.SubscribeNetTableListener('hero_selection', updateHeroSelection);
  updateHeroSelection(null, 'selection', CustomNetTables.GetTableValue('hero_selection', 'selection'));
  updateHeroSelection(null, 'items', CustomNetTables.GetTableValue('hero_selection', 'items'));
})();

function updateHeroSelection (table, key, data) {
  switch (key) {
    case 'selection':
      return updateMenuVisibility(table, key, data);
    case 'items':
      return updateButtons(table, key, data);
  }
}

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

function updateButtons (table, key, data) {
  if (key !== 'items') {
    return;
  }

  $.Msg(data);

  data = data || {};

  if (data.isSelecting) {
    $('#DoneShopping').RemoveClass('hidden');
    $('#Repeat').AddClass('hidden');
    $.GetContextPanel().RemoveClass('autohide');
  } else {
    $('#DoneShopping').AddClass('hidden');
    $('#Repeat').RemoveClass('hidden');
    $.GetContextPanel().AddClass('autohide');
  }
  radiantScore.text = data.radiantKills || 0;
  direScore.text = data.direKills || 0;
}

function DoneShopping () {
  GameEvents.SendCustomGameEventToServer('done_shopping', {});
}
function Repeat () {
  GameEvents.SendCustomGameEventToServer('repeat_fight', {});
}

function ShopHoverIn () {
  $.GetContextPanel().AddClass('hover');
}
function ShopHoverOut () {
  $.GetContextPanel().RemoveClass('hover');
}
