import streamlit as st
import math
import subprocess
import os
import json
from helper.constant import LOVE_PATH

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
    st.title("🪐 Roche Limit Calculator")
    st.markdown("Calculate the **Roche Limit**, the distance at which a celestial body will disintegrate due to tidal forces.")

    reset = st.button("🔁 Reset to Default Values")

    # Inputs
    M, M_coeff, M_exp = scientific_input("Mass of the primary object (M) [kg]", "M", 5.972, 24, reset=reset)
    m, m_coeff, m_exp = scientific_input("Mass of the satellite (m) [kg]", "m", 7.348, 22, reset=reset)
    R, R_coeff, R_exp = scientific_input("Radius of the satellite (R) [m]", "R", 1.737, 6, reset=reset)

    if M > 0 and m > 0 and R > 0:
        ratio = M / m
        roche_limit = R * 2.44 * (ratio ** (1/3))

        roche_km = roche_limit / 1000
        roche_earth_radii = roche_limit / 6.371e6

        st.subheader("📏 Roche Limit Result")
        st.write(f"**Roche Limit (meters):** {roche_limit:,.3f} m")
        st.write(f"**Roche Limit (kilometers):** {roche_km:,.3f} km")
        st.write(f"**Roche Limit (Earth radii):** {roche_earth_radii:,.3f} R⊕")

        st.markdown("---")
        st.subheader("📘 Calculation Breakdown")
        st.latex(r"d = R \cdot 2.44 \cdot \left( \frac{M}{m} \right)^{1/3}")

        st.latex(fr"""
            d = ({R_coeff} \times 10^{{{R_exp}}}) \cdot 2.44 \cdot 
            \left( \frac{{{M_coeff} \times 10^{{{M_exp}}}}}{{{m_coeff} \times 10^{{{m_exp}}}}} \right)^{{1/3}} 
            = {roche_limit:,.3f} \ \text{{meters}}
        """)

        if st.button("Launch"):
            os.makedirs("./visual/roche", exist_ok=True)
            data = {
                "primary_mass": {"value": M, "coeff": M_coeff, "exp": M_exp},
                "satellite_mass": {"value": m, "coeff": m_coeff, "exp": m_exp},
                "satellite_radius": {"value": R, "coeff": R_coeff, "exp": R_exp},
                "roche_limit_m": roche_limit,
                "roche_limit_km": roche_km,
                "roche_limit_earth_radii": roche_earth_radii
            }

            file_path = "./visual/roche/data.json"
            with open(file_path, "w") as f:
                json.dump(data, f, indent=4)

            st.success(f"✅ Data saved to `{file_path}`!")
            st.json(data)

            love2d_path = LOVE_PATH
            love_project_folder = os.path.abspath("./visual/roche")
            try:
                subprocess.Popen([love2d_path, love_project_folder])
                st.info("🌀 Love2D visualization launched.")
            except FileNotFoundError:
                st.error("❌ Love2D not found. Please make sure it's installed and in your PATH.")

    else:
        st.warning("All input values must be positive.")