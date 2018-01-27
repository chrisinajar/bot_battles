var OnHeroSelect = null;
var HeroSelectEvent = null;

(function () {
  const heroSelectionEvent = Event();
  OnHeroSelect = heroSelectionEvent.listen;
  HeroSelectEvent = heroSelectionEvent.broadcast;
}());

function init () {
  CustomNetTables.SubscribeNetTableListener('hero_selection', updateExpandedHeroes);
  updateExpandedHeroes(null, 'selection', CustomNetTables.GetTableValue('hero_selection', 'selection'));

  splitConfigInit();

  function updateExpandedHeroes (table, key, data) {
    if (key !== 'selection') {
      return;
    }
    data = data || {
      isSelecting: true
    };

    if (!data.isSelecting) {
      $.GetContextPanel().AddClass('hidden');
    } else {
      $.GetContextPanel().RemoveClass('hidden');
    }
  }
}

function StartGame () {
  GameEvents.SendCustomGameEventToServer('startgame', {});
}
