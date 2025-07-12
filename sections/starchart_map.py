import streamlit as st
import streamlit.components.v1 as components

def app():
    st.title("🛰️ Sky Map Viewer")
    st.markdown("Embed and explore the interactive **sky map** visualized using D3.js. Press space to pause rotation")

    st.markdown("### 🗺️ Embedded Sky Map")
    components.html(
        '<iframe src="https://fluffy-fenglisu-8c73f5.netlify.app/skymap/" width="100%" height="900" style="border: none;"></iframe>',
        height=900
    )