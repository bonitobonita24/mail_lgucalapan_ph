(function() {
  'use strict';
  angular.module('SOGo.Common')
    .config(configure)

  configure.$inject = ['$mdThemingProvider'];
  function configure($mdThemingProvider) {
    var orangePalette = $mdThemingProvider.extendPalette('orange', {
      '500': 'f28237',
      '600': 'e0742e',
      '700': 'cc6826',
      '800': 'b85c1f',
      'A200': 'f28237',
      'A400': 'e0742e',
      'A700': 'cc6826',
      'contrastDefaultColor': 'light'
    });
    $mdThemingProvider.definePalette('mailcow-orange', orangePalette);
    $mdThemingProvider.theme('default')
      .primaryPalette('mailcow-orange', {
        'default': '500',
        'hue-1': '600',
        'hue-2': '700',
        'hue-3': 'A700'
      })
      .accentPalette('blue-grey', {
        'default': '600',
        'hue-1': '300',
        'hue-2': '300',
        'hue-3': 'A700'
      })
      .backgroundPalette('grey');
    $mdThemingProvider.generateThemesOnDemand(false);
  }
})();
