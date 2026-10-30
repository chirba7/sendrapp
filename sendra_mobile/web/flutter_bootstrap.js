{{flutter_js}}
{{flutter_build_config}}

// L'application s'affiche dans le cadre du téléphone (#flutter_host) et non
// dans toute la fenêtre.
_flutter.loader.load({
  onEntrypointLoaded: async function (engineInitializer) {
    const appRunner = await engineInitializer.initializeEngine({
      hostElement: document.querySelector('#flutter_host'),
    });
    await appRunner.runApp();
  },
});
