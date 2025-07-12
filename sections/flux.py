import streamlit as st
from lightkurve import search_targetpixelfile
import matplotlib.pyplot as plt
import tempfile
import os
import warnings

warnings.filterwarnings("ignore")  # Suppress Lightkurve and Matplotlib warnings


def app():
    st.title("🌟 Light Curve Explorer")
    st.markdown("""
    Explore the light curves of stars and galaxies using **[Lightkurve](https://lightkurve.github.io/)**, a Python package for Kepler and TESS time series data.

    Simply input a valid **KIC, TIC, or EPIC ID** to fetch and visualize photometric data.
    """)

    object_id = st.text_input("🔭 Enter Target ID (e.g., KIC 8462852):", value="KIC 8462852")
    quarter = st.number_input("📅 Enter Kepler Quarter:", min_value=0, max_value=17, step=1, value=16)

    if st.button("📥 Fetch and Visualize"):
        with st.spinner("🔍 Downloading pixel file... Hang on, this might take time"):
            try:
                tpf = search_targetpixelfile(object_id, quarter=quarter).download()
                st.success("✅ Data fetched successfully!")

                # Plot the target pixel file frame
                st.subheader("🖼️ Target Pixel Frame")
                tpf.plot(frame=1)  # Plot onto the current figure
                fig = plt.gcf()    # Get the current matplotlib figure
                st.pyplot(fig)
                plt.close(fig)

                # Generate and plot light curve
                st.subheader("📉 Light Curve")
                lc = tpf.to_lightcurve(aperture_mask='pipeline')
                st.line_chart(lc.flux, use_container_width=True)

                st.markdown("---")
                st.subheader("📘 Metadata")
                st.write(lc)

            except Exception as e:
                st.error(f"❌ Failed to fetch data for '{object_id}' in Quarter {quarter}. Please ensure the ID is valid and the data is available.")
                st.exception(e)


# This function should be called from your main streamlit app router or __main__ block
# Example usage in your main file:
# from lightcurve_page import app as lightcurve_app
# lightcurve_app()
