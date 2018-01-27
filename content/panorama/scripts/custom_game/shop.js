
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
}

function DoneShopping () {
  GameEvents.SendCustomGameEventToServer('done_shopping', {});
}
