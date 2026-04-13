(function() {
  'use strict';
  angular.module('SOGo.Common')
    .config(configure)

  configure.$inject = ['$mdThemingProvider'];
  function configure($mdThemingProvider) {
    var navyPalette = $mdThemingProvider.extendPalette('blue', {
      '500': '0d244c',
      '600': '091b38',
      '700': '061229',
      '800': '040d1c',
      'A200': '0d244c',
      'A400': '091b38',
      'A700': '061229',
      'contrastDefaultColor': 'light'
    });
    $mdThemingProvider.definePalette('calapan-navy', navyPalette);
    var greenPalette = $mdThemingProvider.extendPalette('green', {
      '500': '1a6b3c',
      '600': '155a31',
      '700': '114a28',
      '800': '0d3a1f',
      'A200': '1a6b3c',
      'A400': '155a31',
      'A700': '114a28',
      'contrastDefaultColor': 'light'
    });
    $mdThemingProvider.definePalette('calapan-green', greenPalette);
    $mdThemingProvider.theme('default')
      .primaryPalette('calapan-navy', {
        'default': '500',
        'hue-1': '600',
        'hue-2': '700',
        'hue-3': 'A700'
      })
      .accentPalette('calapan-green', {
        'default': '500',
        'hue-1': '600',
        'hue-2': '700',
        'hue-3': 'A700'
      })
      .backgroundPalette('grey');
    $mdThemingProvider.generateThemesOnDemand(false);
  }
})();
