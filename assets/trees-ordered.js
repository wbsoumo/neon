// Encapsulate the component in an IIFE to avoid polluting the global scope and prevent redeclaration errors
(() => {
  if (!customElements.get("veritree-trees-ordered")) {
    // Use <link> rather than @import so the rest of the stylesheet applies immediately
    // instead of being held back while the Google Fonts CSS is fetched.
    const FONT_LINK = `<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Inter:ital,opsz,wght@0,14..32,100..900;1,14..32,100..900&display=swap">`;

    const NUMBER_FORMATTER = new Intl.NumberFormat();

    const ERROR_MESSAGE = "Unable to load";

    const STYLES = `
      <style>
        :host * {
          box-sizing: border-box;
          margin: 0;
          padding: 0;
          font-family: 'Inter', sans-serif;
        }

        .vt-widget {
          border-radius: var(--v-radius, 8px);
          display: grid;
          font-size: 16px;
          overflow: hidden;
          padding: 0;
          text-align: center;
          max-width: 100%;
        }

        .vt-divider {
          background-color: var(--v-divider-color, currentColor);
          opacity: 0.25;
        }

        .vt-widget__logo {
          display: grid;
          place-items: center;
          color: var(--v-logo-color, currentColor);

          svg {
            height: auto;
          }
        }

        .vt-widget__content {
          display: grid;
          place-items: center;
          position: relative;

          h2 {
            font-weight: 600;
            line-height: 1;
            margin: 0;
          }

          p {
            line-height: 1;
          }
        }

        /* orientations */
        .vt-widget--horizontal {
          grid-template-columns: repeat(2, 1fr);
          grid-template-rows: 1fr;

          .vt-divider {
            position: absolute;
            top: 50%;
            left: 0;
            transform: translate(0, -50%);
            height: 60%;
            width: 1px;
          }
        }

        .vt-widget--vertical {
          width: 500px;
          height: 500px;
          grid-template-columns: 1fr;
          grid-template-rows: repeat(2, 1fr);

          .vt-divider {
            position: absolute;
            top: 0;
            left: 50%;
            transform: translate(-50%, 0);
            width: 60%;
            height: 1px;
          }

          .vt-widget__content h2 {
            font-size: 88px;
          }
        }

        /* sizes */
        .vt-widget--small {
          p {
            font-size: 13.2px;
            margin-top: 5.2px;
          }

          &.vt-widget--horizontal {
            height: 100px;
            width: 240px;

            svg {
              width: 76px;
            }

            h2 {
              font-size: 19.6px;
            }
          }

          &.vt-widget--vertical {
            height: 175px;
            width: 175px;

            svg {
              width: 78px;
            }

            h2 {
              font-size: 28px;
            }
          }
        }

        .vt-widget--large {
          width: 325px;
          height: 145px;

          svg {
            width: 112px;
          }

          h2 {
            font-size: 26.4px;
          }

          p {
            font-size: 18px;
            margin-top: 5.2px;
          }

          &.vt-widget--vertical {
            height: 300px;
            width: 300px;

            svg {
              width: 145px;
            }

            h2 {
              font-size: 48px;
            }

            p {
              font-size: 28px;
            }
          }
        }

        /* variants */
        .vt-widget--solid {
          color: var(--v-color, #F4EFE9);
          background: var(--v-color-background, #152227);
          border: var(--v-width-border, 1px) solid var(--v-color-border, #152227);

          &.vt-widget--dark {
            color: var(--v-color, #F4EFE9);
            background: var(--v-color-background, transparent);
            border: var(--v-width-border, 1px) solid var(--v-color-border, currentColor);
          }
        }

        .vt-widget--bicolor {
          color: var(--v-content-color, #152227);
          border: var(--v-width-border, 2px) solid var(--v-color-border, currentColor);

          .vt-divider {
            display: none;
          }

          .vt-widget__logo {
            color: var(--v-color, #F4EFE9);
            background-color: var(--v-logo-color-background, #152227);
          }

          .vt-widget__content {
            background: var(--v-content-color-background, #FFFFFF);
          }

          &.vt-widget--dark {
            color: var(--v-content-color, #F4EFE9);

            .vt-widget__logo {
              color: var(--v-color, #152227);
              background-color: var(--v-logo-color-background, #F4EFE9);
            }

            .vt-widget__content {
              background: var(--v-content-color-background, transparent);
            }
          }
        }

      </style>
    `;

    const LOGO_SVG = `
      <svg width="211" height="126" viewBox="0 0 211 126" fill="none" xmlns="http://www.w3.org/2000/svg" aria-hidden="true">
        <path d="M26.183 93.3995L17.5425 114.4C17.3008 114.985 16.4426 114.993 16.1927 114.4L7.35218 93.3915C7.24386 93.1268 6.97723 92.9504 6.67727 92.9504H0.728063C0.211465 92.9504 -0.138488 93.4556 0.0531532 93.9127L13.0431 124.255C13.1597 124.519 13.418 124.688 13.718 124.688H19.3839C19.6755 124.688 19.9422 124.511 20.0588 124.255L33.0487 93.9127C33.2487 93.4556 32.8904 92.9504 32.3738 92.9504H26.8579C26.5579 92.9504 26.2913 93.1268 26.183 93.3915" fill="currentColor"/>
        <path d="M91.1327 124.704H96.8236C97.2235 124.704 97.5485 124.391 97.5485 124.006V93.6639C97.5485 93.279 97.2235 92.9663 96.8236 92.9663H91.1327C90.7327 92.9663 90.4078 93.279 90.4078 93.6639V124.006C90.4078 124.391 90.7327 124.704 91.1327 124.704Z" fill="currentColor"/>
        <path d="M48.48 97.593C53.8793 97.593 56.3373 101.282 56.9205 105.146C56.9872 105.571 56.6456 105.956 56.204 105.956H40.0978C39.6228 105.956 39.2729 105.523 39.3895 105.082C40.3811 101.354 43.1974 97.593 48.4717 97.593M57.9787 114.809C57.6954 114.809 57.4455 114.977 57.3205 115.218C55.7707 118.377 52.9794 119.925 48.8466 119.925C43.8473 119.925 39.9311 116.501 39.1062 111.609C39.0313 111.184 39.3729 110.783 39.8228 110.783H63.628C64.0279 110.783 64.3529 110.471 64.3529 110.086V107.945C64.3529 98.3307 58.1204 92.1084 48.4883 92.1084C38.8563 92.1084 31.8156 99.3331 31.8156 109.276C31.8156 119.219 38.7896 125.529 48.78 125.529C56.204 125.529 61.5283 121.977 63.678 115.731C63.8363 115.274 63.4947 114.801 62.9947 114.801H57.9787V114.809Z" fill="currentColor"/>
        <path d="M160.324 97.593C165.723 97.593 168.181 101.282 168.764 105.146C168.831 105.571 168.489 105.956 168.048 105.956H151.941C151.466 105.956 151.116 105.523 151.233 105.082C152.225 101.354 155.041 97.593 160.315 97.593M169.814 114.809C169.531 114.809 169.281 114.977 169.156 115.218C167.606 118.377 164.815 119.925 160.682 119.925C155.682 119.925 151.766 116.501 150.941 111.609C150.866 111.184 151.208 110.783 151.658 110.783H175.463C175.863 110.783 176.188 110.471 176.188 110.086V107.945C176.188 98.3307 169.956 92.1084 160.324 92.1084C150.691 92.1084 143.651 99.3331 143.651 109.276C143.651 119.219 150.625 125.529 160.615 125.529C168.039 125.529 173.363 121.977 175.513 115.731C175.671 115.274 175.33 114.801 174.83 114.801H169.814V114.809Z" fill="currentColor"/>
        <path d="M195.127 97.593C200.526 97.593 202.984 101.282 203.568 105.146C203.634 105.571 203.293 105.956 202.851 105.956H186.745C186.27 105.956 185.92 105.523 186.037 105.082C187.028 101.354 189.845 97.593 195.119 97.593M204.626 114.809C204.343 114.809 204.093 114.977 203.968 115.218C202.418 118.377 199.627 119.925 195.494 119.925C190.494 119.925 186.578 116.501 185.753 111.609C185.678 111.184 186.02 110.783 186.47 110.783H210.275C210.675 110.783 211 110.471 211 110.086V107.945C211 98.3307 204.768 92.1084 195.135 92.1084C185.503 92.1084 178.463 99.3331 178.463 109.276C178.463 119.219 185.437 125.529 195.427 125.529C202.851 125.529 208.175 121.977 210.325 115.731C210.483 115.274 210.142 114.801 209.642 114.801H204.626V114.809Z" fill="currentColor"/>
        <path d="M143.659 93.5919C143.659 93.3433 143.534 93.1108 143.309 92.9905C142.243 92.4131 140.959 92.1165 139.41 92.1165C135.193 92.1165 130.902 96.2941 130.902 100.063V93.664C130.902 93.2791 130.577 92.9664 130.177 92.9664H124.487C124.087 92.9664 123.762 93.2791 123.762 93.664V124.006C123.762 124.391 124.087 124.704 124.487 124.704H130.177C130.577 124.704 130.902 124.391 130.902 124.006V107.953C130.902 102.436 133.977 98.5713 138.385 98.5713C140.201 98.5713 141.343 98.86 143.084 99.7741L143.651 100.071V93.5919H143.659Z" fill="currentColor"/>
        <path d="M87.6082 93.5919C87.6082 93.3433 87.4832 93.1108 87.2582 92.9905C86.1917 92.4131 84.9085 92.1165 83.3587 92.1165C79.1426 92.1165 74.8515 96.2941 74.8515 100.063V93.664C74.8515 93.2791 74.5266 92.9664 74.1266 92.9664H68.4357C68.0358 92.9664 67.7108 93.2791 67.7108 93.664V124.006C67.7108 124.391 68.0358 124.704 68.4357 124.704H74.1266C74.5266 124.704 74.8515 124.391 74.8515 124.006V107.953C74.8515 102.436 77.9261 98.5713 82.3339 98.5713C84.1503 98.5713 85.2918 98.86 87.0332 99.7741L87.5998 100.071V93.5919H87.6082Z" fill="currentColor"/>
        <path d="M120.479 119.524C120.479 119.027 119.937 118.69 119.462 118.89C118.021 119.484 116.704 119.796 115.546 119.796C113.105 119.796 112.147 118.818 112.147 116.316V98.9242C112.147 98.5393 112.472 98.2266 112.871 98.2266H120.395C120.795 98.2266 121.12 97.9139 121.12 97.529V93.664C121.12 93.2792 120.795 92.9664 120.395 92.9664H112.871C112.472 92.9664 112.147 92.6537 112.147 92.2688V84.4749H105.797C105.397 84.4749 105.072 84.7876 105.072 85.1725V92.2769C105.072 92.6617 104.748 92.9745 104.348 92.9745H100.981C100.581 92.9745 100.256 93.2872 100.256 93.6721V98.2346H104.348C104.748 98.2346 105.072 98.5473 105.072 98.9322V117.022C105.072 122.683 107.855 125.554 113.355 125.554C115.988 125.554 118.062 125.064 120.112 123.942C120.337 123.822 120.479 123.581 120.479 123.332V119.54V119.524Z" fill="currentColor"/>
        <path d="M93.974 79.4392C91.7993 79.4392 90.0412 81.1391 90.0412 83.2239C90.0412 85.3087 91.7993 87.0087 93.974 87.0087C96.1487 87.0087 97.9068 85.3087 97.9068 83.2239C97.9068 81.1391 96.1487 79.4392 93.974 79.4392Z" fill="currentColor"/>
        <path d="M104.023 53.6117C101.848 53.6117 100.09 55.3116 100.09 57.3964C100.09 59.4812 101.848 61.1891 104.023 61.1891C106.197 61.1891 107.955 59.4892 107.955 57.3964C107.955 55.3036 106.197 53.6117 104.023 53.6117ZM111.888 40.5094C109.713 40.5094 107.955 42.2013 107.955 44.2942C107.955 46.387 109.713 48.0789 111.888 48.0789C114.063 48.0789 115.821 46.387 115.821 44.2942C115.821 42.2013 114.063 40.5094 111.888 40.5094ZM96.157 39.3227C93.3074 39.3227 90.991 41.5438 90.991 44.2942C90.991 47.0445 93.3074 49.2656 96.157 49.2656C99.0066 49.2656 101.323 47.0445 101.323 44.2942C101.323 41.5438 99.0149 39.3227 96.157 39.3227ZM111.888 21.8183C114.063 21.8183 115.821 20.1264 115.821 18.0336C115.821 15.9408 114.063 14.2489 111.888 14.2489C109.713 14.2489 107.955 15.9408 107.955 18.0336C107.955 20.1264 109.713 21.8183 111.888 21.8183ZM127.611 13.0621C124.761 13.0621 122.445 15.2833 122.445 18.0336C122.445 20.7839 124.753 23.0051 127.611 23.0051C130.469 23.0051 132.777 20.7759 132.777 18.0336C132.777 15.2913 130.461 13.0621 127.611 13.0621ZM135.477 0C132.627 0 130.311 2.22112 130.311 4.97147C130.311 7.72181 132.627 9.94293 135.477 9.94293C138.326 9.94293 140.643 7.71379 140.643 4.97147C140.643 2.22914 138.335 0 135.477 0ZM72.5684 2.83855C71.3436 2.83855 70.3604 3.79275 70.3604 4.97147C70.3604 6.15019 71.3519 7.10439 72.5684 7.10439C73.785 7.10439 74.7848 6.15019 74.7848 4.97147C74.7848 3.79275 73.7933 2.83855 72.5684 2.83855ZM88.2914 7.10439C89.5162 7.10439 90.4994 6.15019 90.4994 4.97147C90.4994 3.79275 89.5079 2.83855 88.2914 2.83855C87.0748 2.83855 86.075 3.79275 86.075 4.97147C86.075 6.15019 87.0665 7.10439 88.2914 7.10439ZM96.157 21.8664C98.3317 21.8664 100.09 20.1745 100.09 18.0817C100.09 15.9889 98.3317 14.289 96.157 14.289C93.9823 14.289 92.2242 15.9889 92.2242 18.0817C92.2242 20.1745 93.9823 21.8664 96.157 21.8664ZM119.745 8.7562C121.92 8.7562 123.687 7.05628 123.687 4.97147C123.687 2.88666 121.929 1.17872 119.745 1.17872C117.562 1.17872 115.813 2.87864 115.813 4.97147C115.813 7.06429 117.571 8.7562 119.745 8.7562ZM119.745 26.2125C116.896 26.2125 114.58 28.4336 114.58 31.1839C114.58 33.9343 116.888 36.1554 119.745 36.1554C122.603 36.1554 124.911 33.9263 124.911 31.1839C124.911 28.4416 122.603 26.2125 119.745 26.2125ZM92.2242 31.1839C92.2242 29.0911 90.4661 27.3992 88.2914 27.3992C86.1166 27.3992 84.3502 29.0911 84.3502 31.1839C84.3502 33.2768 86.1083 34.9687 88.2914 34.9687C90.4744 34.9687 92.2242 33.2768 92.2242 31.1839ZM104.014 36.1554C106.864 36.1554 109.18 33.9263 109.18 31.1839C109.18 28.4416 106.872 26.2125 104.014 26.2125C101.156 26.2125 98.8483 28.4336 98.8483 31.1839C98.8483 33.9343 101.156 36.1554 104.014 36.1554ZM80.4257 15.2351C78.7926 15.2351 77.4761 16.5021 77.4761 18.0737C77.4761 19.6453 78.8009 20.9122 80.4257 20.9122C82.0505 20.9122 83.3753 19.6453 83.3753 18.0737C83.3753 16.5021 82.0588 15.2351 80.4257 15.2351Z" fill="currentColor"/>
      </svg>
    `;

    class VeritreeTreesOrdered extends HTMLElement {
      static get observedAttributes() {
        return ["id", "size", "orientation", "variant", "theme", "api_url"];
      }

      constructor() {
        super();

        /** @type {string} Organization ID for fetching stats */
        this._id = "";
        /** @type {string} Widget orientation: 'horizontal' or 'vertical' */
        this._orientation = "horizontal";
        /** @type {string} Widget variant: 'solid' or 'bicolor' */
        this._variant = "solid";
        /** @type {string} Widget theme: 'light' or 'dark' */
        this._theme = "light";
        /** @type {string} Widget size: 'small' or 'large' */
        this._size = "large";
        /** @type {string} API base URL */
        this._api_url = "https://api.veritree.com/api";

        /** @type {Object|null} Statistics data from API */
        this._stats = null;
        /** @type {string} Organization domain for impact link */
        this._domain = "";
        // Start loading so the initial render shows "—" rather than a transient "0" before the first fetch starts.
        this._is_loading = true;
        this._has_error = false;

        /** @type {AbortController|null} Controls cancellation of the current in-flight fetch */
        this._abortController = null;

        this._rendered = false;
        this._rootEl = null;
        this._linkEl = null;
        this._countEl = null;
        this._copyEl = null;

        this._shadow = this.attachShadow({ mode: "open" });
      }

      get _card_class() {
        return `vt-widget--${this._orientation} vt-widget--${this._size} vt-widget--${this._variant} vt-widget--${this._theme}`;
      }

      get _totalOrdered() {
        if (this._is_loading || this._has_error) {
          return "—";
        }

        if (!this._stats) {
          return 0;
        }

        const kelp_ordered = this._stats.kelp_ordered || 0;
        const trees_ordered = this._stats.trees_ordered || 0;
        const trees_legacy = this._stats.trees_legacy || 0;

        return kelp_ordered + trees_ordered + trees_legacy;
      }

      get _copy() {
        if (this._has_error) {
          return ERROR_MESSAGE;
        }

        if (this._is_loading || !this._stats) {
          return "";
        }

        const { kelp_ordered } = this._stats;
        return kelp_ordered ? "Trees & Kelp" : "Trees";
      }

      async attributeChangedCallback(property, oldValue, newValue) {
        if (oldValue === newValue) {
          return;
        }

        this[`_${property}`] = newValue;

        // Skip fetching at parse time; connectedCallback handles the initial fetch.
        if (property === "id" && this.isConnected) {
          await this._refetch();
        }

        this.updateView();
      }

      async connectedCallback() {
        await this._refetch();
        this.updateView();
      }

      async _refetch() {
        if (!this._id) {
          if (this._abortController) {
            this._abortController.abort();
            this._abortController = null;
          }
          this._stats = null;
          this._domain = "";
          this._has_error = false;
          this._is_loading = false;
          return;
        }

        await this.getStats();
      }

      async getStats() {
        if (this._abortController) {
          this._abortController.abort();
        }

        const controller = new AbortController();
        this._abortController = controller;

        this._is_loading = true;
        this._has_error = false;

        const url = `${this._api_url}/orgs/pstats?org_id=${encodeURIComponent(this._id)}&org_type=sponsorAccount&subsite_view_type=sponsor`;

        try {
          const response = await fetch(url, { signal: controller.signal });

          if (!response.ok) {
            throw new Error(`HTTP ${response.status} ${response.statusText}`);
          }

          const payload = await response.json();
          const { data: stats, _org: { org } = { org: null } } = payload;

          this._stats = stats;
          this._domain = (org && org.domain) || "";
          this._has_error = false;
        } catch (error) {
          if (error.name === "AbortError") {
            // Superseded by a newer request — leave state to the winning call.
            return;
          }
          console.error("VeritreeTreesOrdered: Error fetching stats:", error);
          this._stats = null;
          this._has_error = true;
        } finally {
          // Only the latest request clears the loading flag, so a stale abort doesn't flip state.
          if (this._abortController === controller) {
            this._is_loading = false;
            this._abortController = null;
          }
        }
      }

      updateView() {
        if (!this._rendered) {
          this._renderScaffold();
        }

        this._updateState();
      }

      _renderScaffold() {
        this._shadow.innerHTML = `
          ${FONT_LINK}
          ${STYLES}
          <div class="vt-widget">
            <a class="vt-widget__logo" target="_blank" rel="noopener noreferrer" aria-label="View Veritree impact data">
              ${LOGO_SVG}
            </a>
            <div class="vt-widget__content">
              <span class="vt-divider"></span>
              <div>
                <h2></h2>
                <p></p>
              </div>
            </div>
          </div>
        `;

        this._rootEl = this._shadow.querySelector(".vt-widget");
        this._linkEl = this._shadow.querySelector(".vt-widget__logo");
        this._countEl = this._shadow.querySelector(".vt-widget__content h2");
        this._copyEl = this._shadow.querySelector(".vt-widget__content p");
        this._rendered = true;
      }

      _updateState() {
        this._rootEl.className = `vt-widget ${this._card_class}`;

        this._linkEl.href = `https://impact.veritree.com/${this._domain || ""}?utm_source=veritree-widget`;

        const count = this._totalOrdered;
        this._countEl.textContent = typeof count === "number" ? NUMBER_FORMATTER.format(count) : count;
        this._copyEl.textContent = this._copy;
      }
    }

    customElements.define("veritree-trees-ordered", VeritreeTreesOrdered);
  }
})();
