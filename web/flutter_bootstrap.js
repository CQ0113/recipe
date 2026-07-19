{{flutter_js}}
{{flutter_build_config}}

const loading = document.querySelector('#app-loading');
const loadingStatus = document.querySelector('#app-loading-status');

_flutter.loader.load({
  onEntrypointLoaded: async (engineInitializer) => {
    try {
      if (loadingStatus) loadingStatus.textContent = 'Starting Savora…';
      const appRunner = await engineInitializer.initializeEngine();
      await appRunner.runApp();

      // Let the browser paint Flutter's first frame before removing the
      // branded loading surface underneath it.
      requestAnimationFrame(() => {
        requestAnimationFrame(() => loading?.remove());
      });
    } catch (error) {
      if (loadingStatus) {
        loadingStatus.textContent =
          'Savora could not start. Check your connection and refresh.';
      }
      throw error;
    }
  },
});
