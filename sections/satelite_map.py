import streamlit as st
import streamlit.components.v1 as components

def app():
    st.title("🛰️ Satelite Map Viewer")
    st.markdown("Embed and explore the interactive **satelite** visualized using D3.js.")

    st.markdown("### 🗺️ Embedded Satelite Map")
    components.html(
        '<iframe src="https://fluffy-fenglisu-8c73f5.netlify.app/satelite/" width="100%" height="900" style="border: none;"></iframe>',
        height=900
    )