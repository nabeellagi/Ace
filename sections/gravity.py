import streamlit as st
import math
import os
import json
import subprocess
from helper.constant import LOVE_PATH

G = 6.67430e-11  # gravitational constant

def scientific_input(label, key_prefix, default_coeff, default_exp, exp_range=(1, 100), reset=False):
    if reset:
        st.session_state[f"{key_prefix}_coeff"] = default_coeff
        st.session_state[f"{key_prefix}_exp"] = default_exp

    cols = st.columns([3, 2])
    with cols[0]:
        coeff = st.number_input(
            f"{label} - Coefficient", 
            key=f"{key_prefix}_coeff", 
            value=default_coeff, 
            step=0.001, 
            format="%.3f"
        )
    with cols[1]:
        exp = st.number_input(
            f"{label} - Exponent", 
            key=f"{key_prefix}_exp", 
            value=default_exp, 
            step=1, 
            min_value=exp_range[0], 
            max_value=exp_range[1]
        )
    return coeff * (10 ** exp), coeff, exp

def app():
    st.title("🌍 Surface Gravity Calculator")
    st.markdown("Compute the **surface gravity** of a celestial body using its mass and radius.")

    reset = st.button("🔁 Reset to Default Values")

    # Earth default
    M, M_coeff, M_exp = scientific_input("Mass (M) [kg]", "M", 5.972, 24, reset=reset)
    R, R_coeff, R_exp = scientific_input("Radius (R) [m]", "R", 6.371, 6, reset=reset)

    if M > 0 and R > 0:
        gravity = (G * M) / (R ** 2)
        gravity_g = gravity / 9.80665  # in g

        st.subheader("📏 Gravity Result")
        st.write(f"**Surface Gravity (m/s²):** {gravity:,.5f} m/s²")
        st.write(f"**Compared to Earth's gravity (g):** {gravity_g:,.3f} g")

        st.markdown("---")
        st.subheader("📘 Formula Breakdown")
        st.latex(r"g = \frac{GM}{R^2}")
        st.latex(fr"""
            g = \frac{{6.674 \times 10^{{-11}} \times ({M_coeff} \times 10^{{{M_exp}}})}}{{({R_coeff} \times 10^{{{R_exp}}})^2}} 
            = {gravity:,.5f} \ \text{{m/s²}}
        """)

        if st.button("Launch"):
            os.makedirs("./visual/gravity", exist_ok=True)

            data = {
                "planet_mass": {"value": M, "coeff": M_coeff, "exp": M_exp},
                "planet_radius": {"value": R, "coeff": R_coeff, "exp": R_exp},
                "gravity_m_per_s2": gravity,
                "gravity_in_g": gravity_g
            }

            file_path = "./visual/gravity/data.json"
            with open(file_path, "w") as f:
                json.dump(data, f, indent=4)

            st.success(f"✅ Data saved to `{file_path}`!")
            st.json(data)

            love2d_path = LOVE_PATH
            love_project_folder = os.path.abspath("./visual/gravity")

            try:
                subprocess.Popen([love2d_path, love_project_folder])
                st.info("🌀 Love2D visualization launched.")
            except FileNotFoundError:
                st.error("❌ Love2D not found. Please make sure it's installed and in your PATH.")

        if st.button("Launch Pong Game"):
            os.makedirs("./visual/pong", exist_ok=True)

            data = {
                "planet_mass": {"value": M, "coeff": M_coeff, "exp": M_exp},
                "planet_radius": {"value": R, "coeff": R_coeff, "exp": R_exp},
                "gravity_m_per_s2": gravity,
                "gravity_in_g": gravity_g
            }

            file_path = "./visual/pong/data.json"
            with open(file_path, "w") as f:
                json.dump(data, f, indent=4)

            st.success(f"✅ Data saved to `{file_path}`!")
            st.json(data)

            love2d_path = LOVE_PATH
            love_project_folder = os.path.abspath("./visual/pong")

            try:
                subprocess.Popen([love2d_path, love_project_folder])
                st.info("🌀 Love2D visualization launched.")
            except FileNotFoundError:
                st.error("❌ Love2D not found. Please make sure it's installed and in your PATH.")

    else:
        st.warning("Mass and radius must be positive values.")
