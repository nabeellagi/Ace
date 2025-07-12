import streamlit as st
import math
import numpy as np
import matplotlib.pyplot as plt

G = 6.67430e-11  # gravitational constant in m^3 kg^-1 s^-2

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
    st.title("🚀 Escape Velocity Calculator")
    st.markdown("Calculate the **escape velocity**, the minimum speed needed to break free from a celestial body's gravitational pull.")

    reset = st.button("🔁 Reset to Default Values")

    # Earth's mass and radius as default
    M, M_coeff, M_exp = scientific_input("Mass of the celestial body (M) [kg]", "M", 5.972, 24, reset=reset)
    R, R_coeff, R_exp = scientific_input("Radius from center (R) [m]", "R", 6.371, 6, reset=reset)

    if M > 0 and R > 0:
        escape_velocity = math.sqrt((2 * G * M) / R)  # in m/s
        escape_km_s = escape_velocity / 1000  # in km/s

        st.subheader("📏 Escape Velocity Result")
        st.write(f"**Escape Velocity (m/s):** {escape_velocity:,.3f} m/s")
        st.write(f"**Escape Velocity (km/s):** {escape_km_s:,.3f} km/s")

        st.markdown("---")
        st.subheader("📘 Calculation Breakdown")
        st.latex(r"v = \sqrt{\frac{2GM}{r}}")
        st.latex(fr"""
            v = \sqrt{{\frac{{2 \times 6.674 \times 10^{{-11}} \times ({M_coeff} \times 10^{{{M_exp}}})}}{{{R_coeff} \times 10^{{{R_exp}}}}}}}
            = {escape_velocity:,.3f} \ \text{{m/s}}
        """)

        st.markdown("---")
        st.subheader("📈 Speed vs. Escape Progress")

        # Speeds from 0 to 1.5 * escape velocity
        speeds = np.linspace(0, 1.5 * escape_velocity, 300)
        escape_kinetic = 0.5 * escape_velocity ** 2

        # Energy ratio: how close a speed's kinetic energy is to escape energy
        progress = 0.5 * (speeds ** 2) / escape_kinetic * 100  # in %

        fig, ax = plt.subplots(figsize=(10, 6))
        ax.plot(speeds / 1000, progress, color='tomato', label="Energy toward escape")
        ax.axvline(x=escape_velocity / 1000, color='green', linestyle='--', label="Escape Velocity")

        ax.set_title("Progress Toward Escape vs. Speed")
        ax.set_xlabel("Speed (km/s)")
        ax.set_ylabel("Kinetic Energy (% of required to escape)")
        ax.set_ylim(0, 160)
        ax.grid(True)
        ax.legend()

        st.pyplot(fig)

    else:
        st.warning("Mass and radius must be positive values.")