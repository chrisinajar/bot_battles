var OnHeroSelected = null;
var HeroSelectedEvent = null;

(function () {
  const heroSelectedEvent = Event();
  OnHeroSelected = heroSelectedEvent.listen;
  HeroSelectedEvent = heroSelectedEvent.broadcast;

  CustomNetTables.SubscribeNetTableListener('hero_selection', updateHeroList);
  updateHeroList(null, 'herolist', CustomNetTables.GetTableValue('hero_selection', 'herolist'));

  OnHeroSelect(function (team) {
    FindDotaHudElement('HeroPanel').RemoveClass('hidden');
  });
  OnHeroSelected(function (team) {
    FindDotaHudElement('HeroPanel').AddClass('hidden');
  });
}());

function updateHeroList (table, key, data) {
  if (key !== 'herolist') {
    return;
  }
  if (!data) {
    return;
  }
  $.Msg(data);

  var strengthholder = FindDotaHudElement('StrengthHeroes');
  var agilityholder = FindDotaHudElement('AgilityHeroes');
  var intelligenceholder = FindDotaHudElement('IntelligenceHeroes');
  Object.keys(data.herolist).sort().forEach(function (heroName) {
    var currentstat = null;
    switch (data.herolist[heroName]) {
      case 'DOTA_ATTRIBUTE_STRENGTH':
        currentstat = strengthholder;
        break;
      case 'DOTA_ATTRIBUTE_AGILITY':
        currentstat = agilityholder;
        break;
      case 'DOTA_ATTRIBUTE_INTELLECT':
        currentstat = intelligenceholder;
        break;
    }
    var newhero = $.CreatePanel('RadioButton', currentstat, heroName);
    newhero.group = 'HeroChoices';
    newhero.SetPanelEvent('onactivate', function () { HeroSelectedEvent(heroName); });
    var newheroimage = $.CreatePanel('DOTAHeroImage', newhero, '');
    newheroimage.hittest = false;
    newheroimage.AddClass('HeroCard');
    newheroimage.heroname = heroName;
  });
}
