import streamlit as st
import streamlit.components.v1 as components

def app():
    st.title("🛰️ Radio and Telescope Map")

    st.markdown("### 🗺️ Embedded Map")
    components.html(
        '<iframe src="https://fluffy-fenglisu-8c73f5.netlify.app/radiotelescope/" width="100%" height="900" style="border: none;"></iframe>',
        height=900
    )