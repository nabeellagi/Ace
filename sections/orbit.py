import streamlit as st
import math
import subprocess
import json, os
from helper.constant import LOVE_PATH

# Global gravitational constant
G = 6.67430e-11  # m^3 kg^-1 s^-2

def scientific_input(label, key_prefix, default_coeff, default_exp, exp_range=(1, 100), reset=False):
    """Creates a scientific notation input with coefficient and exponent."""
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
    st.title("🌌 Orbital Period Calculator")
    st.markdown("Enter values for mass and distance using scientific notation (coefficient × 10^exponent).")

    # Reset button
    reset = st.button("🔁 Reset to Default Values")

    # Inputs with session-based state to support reset
    M, M_coeff, M_exp = scientific_input("Mass of larger object (M) [kg]", "M", 1.989, 30, reset=reset)
    m, m_coeff, m_exp = scientific_input("Mass of smaller object (m) [kg]", "m", 5.972, 24, reset=reset)
    a, a_coeff, a_exp = scientific_input("Semi-major axis (a) [m]", "a", 1.496, 11, reset=reset)

    e_key = "eccentricity"
    if reset:
        st.session_state[e_key] = 0.0167  # Earth's eccentricity as default
    e = st.number_input(
        "Eccentricity (e) of the orbit", 
        key=e_key, 
        min_value=0.0, 
        max_value=1.0, 
        step=0.0001, 
        format="%.4f", 
        value=st.session_state.get(e_key, 0.0167)
    )
    


    if M > 0 and m > 0 and a > 0:
        T_squared = (4 * math.pi**2 * a**3) / (G * (M + m))
        T_seconds = math.sqrt(T_squared)
        T_days = T_seconds / (60 * 60 * 24)
        T_years = T_days / 365.25

        st.subheader("🧮 Orbital Period Results")
        st.write(f"**T (seconds):** {T_seconds:,.3f}")
        st.write(f"**T (days):** {T_days:,.3f}")
        st.write(f"**T (years):** {T_years:,.6f}")

        st.markdown("---")
        st.subheader("📘 Calculation Breakdown")
        st.latex(r"T^2 = \frac{4\pi^2 a^3}{G(M + m)}")

        st.latex(fr"""
            T^2 = \frac{{4 \times \pi^2 \times ({a_coeff} \times 10^{{{a_exp}}})^3}} 
            {{6.67430 \times 10^{{-11}} \times (({M_coeff} \times 10^{{{M_exp}}}) + ({m_coeff} \times 10^{{{m_exp}}}))}}
        """)

        st.latex(fr"T = \sqrt{{T^2}} = {T_seconds:,.3f} \ \text{{seconds}}")
        st.markdown(f"Also equivalent to **{T_days:,.3f} days** or **{T_years:,.6f} years**.")
                # Save button
        if st.button("Launch"):
            os.makedirs("./visual/orbits", exist_ok=True)

            data = {
                "central_mass": {
                    "value": M,
                    "coeff": M_coeff,
                    "exp": M_exp
                },
                "planets": [
                    {
                        "planet": "Planet 1",
                        "mass": {"value": m, "coeff": m_coeff, "exp": m_exp},
                        "semi_major_axis": {"value": a, "coeff": a_coeff, "exp": a_exp},
                        "eccentricity": e,
                        "T_seconds": T_seconds,
                        "T_days": T_days,
                        "T_years": T_years
                    }
                ]
            }

            file_path = "./visual/orbits/data.json"
            with open(file_path, "w") as f:
                json.dump(data, f, indent=4)

            st.success(f"✅ Data saved to `{file_path}`!")
            st.json(data)
            love2d_path = LOVE_PATH  # Make sure LOVE is in your system's PATH
            love_project_folder = os.path.abspath("./visual/orbits")

            try:
                subprocess.Popen([love2d_path, love_project_folder])
                st.info("🌀 Love2D visualization launched.")
            except FileNotFoundError:
                st.error("❌ Could not launch Love2D. Make sure it is installed and available in your PATH.")
        
        if st.button("Launch Kepler Visual"):

            love2d_path = LOVE_PATH
            love_project_folder = os.path.abspath("./visual/kepler")

            try:
                subprocess.Popen([love2d_path, love_project_folder])
                st.info("🌀 Love2D visualization launched.")
            except FileNotFoundError:
                st.error("❌ Love2D not found. Please make sure it's installed and in your PATH.")

    else:
        st.warning("All input values must be positive.")
