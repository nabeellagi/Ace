import streamlit as st
import numpy as np
import math
import os
import json
import subprocess
import matplotlib.pyplot as plt
from helper.constant import LOVE_PATH

# Physical constants
PI = math.pi
SIGMA = 5.670374419e-8  # Stefan-Boltzmann constant (W·m⁻²·K⁻⁴)
WIEN_DISPLACEMENT = 2.897771955e-3  # m·K
h = 6.62607015e-34    # Planck constant (J·s)
c = 2.99792458e8    # Speed of light (m/s)
k = 1.380649e-23      # Boltzmann constant (J/K)

# Solar constants for comparison
L_SUN_WATT = 3.828e26 # Solar Luminosity (W)
F_SUN_W_PER_M2 = 1361.0 # Solar Constant (W/m^2) at Earth's average distance (1 AU)

# Color science
from colour import SpectralShape, sd_blackbody, sd_to_XYZ
from colour.models import XYZ_to_sRGB

# --- Helper Functions ---
def sci_notation(val, precision=3):
    """
    Formats a number into scientific notation string for LaTeX display.
    """
    if val == 0:
        return "0"
    exponent = int(math.floor(math.log10(abs(val))))
    coeff = val / (10 ** exponent)
    return f"{coeff:.{precision}f} \\times 10^{{{exponent}}}"

def scientific_input(label, key_prefix, default_coeff, default_exp, exp_range=(0, 100), reset=False):
    """
    Creates Streamlit number inputs for scientific notation coefficient and exponent.
    Handles reset functionality.
    """
    if reset:
        st.session_state[f"{key_prefix}_coeff"] = default_coeff
        st.session_state[f"{key_prefix}_exp"] = default_exp

    cols = st.columns([3, 2])
    with cols[0]:
        coeff = st.number_input(
            f"{label} - Coefficient",
            key=f"{key_prefix}_coeff",
            value=st.session_state.get(f"{key_prefix}_coeff", default_coeff),
            step=0.001,
            format="%.3f"
        )
    with cols[1]:
        exp = st.number_input(
            f"{label} - Exponent",
            key=f"{key_prefix}_exp",
            value=st.session_state.get(f"{key_prefix}_exp", default_exp),
            step=1,
            min_value=exp_range[0],
            max_value=exp_range[1]
        )
    return coeff * (10 ** exp), coeff, exp

def accurate_color_from_temperature(T):
    """
    Calculates the sRGB hex color perceived for a blackbody at temperature T.
    Uses the 'colour' library for accurate color space conversion.
    """
    shape = SpectralShape(380, 780, 5) # Define visible spectrum shape
    sd = sd_blackbody(T, shape) # Get spectral distribution for blackbody
    XYZ = sd_to_XYZ(sd) # Convert to CIE XYZ tristimulus values
    rgb = XYZ_to_sRGB(XYZ / np.max(XYZ)) # Convert to sRGB, normalizing for peak intensity
    rgb = np.clip(rgb, 0, 1) # Clip values to ensure they are within [0, 1] range
    hex_color = '#%02x%02x%02x' % tuple((rgb * 255).astype(int)) # Convert to hex string
    return hex_color, rgb

def get_spectrum_color(wavelength_nm):
    """
    Approximates the sRGB hex color for a given wavelength (380-750nm)
    for visual representation of the spectrum.
    This is a simplified model, not a precise colorimetric conversion.
    """
    R, G, B = 0.0, 0.0, 0.0 # Initialize RGB components

    # Define color regions and their approximate transitions
    if 380 <= wavelength_nm < 440:  # Violet
        R = -(wavelength_nm - 440) / (440 - 380)
        B = 1.0
    elif 440 <= wavelength_nm < 490:  # Blue
        G = (wavelength_nm - 440) / (490 - 440)
        B = 1.0
    elif 490 <= wavelength_nm < 510:  # Cyan
        G = 1.0
        B = -(wavelength_nm - 510) / (510 - 490)
    elif 510 <= wavelength_nm < 580:  # Green
        R = (wavelength_nm - 510) / (580 - 510)
        G = 1.0
    elif 580 <= wavelength_nm < 645:  # Yellow to Orange
        R = 1.0
        G = -(wavelength_nm - 645) / (645 - 580)
    elif 645 <= wavelength_nm <= 750: # Red
        R = 1.0
    else:  # Out of visible range or invalid
        return '#000000' # Black

    # Apply intensity fall-off at the ends of the spectrum for a more natural look
    factor = 1.0
    if 380 <= wavelength_nm < 420:
        factor = 0.3 + 0.7 * (wavelength_nm - 380) / (420 - 380)
    elif 700 < wavelength_nm <= 750:
        factor = 0.3 + 0.7 * (750 - wavelength_nm) / (750 - 700)

    # Convert RGB components to 0-255 range and then to hex
    R_int = int(255 * R * factor)
    G_int = int(255 * G * factor)
    B_int = int(255 * B * factor)

    return f'#{R_int:02x}{G_int:02x}{B_int:02x}'


def planck_law(wavelength_m, T):
    exp_term = (h * c) / (wavelength_m * k * T)
    # Handle potential overflow/underflow for np.exp
    if exp_term > 700: # np.exp(709) is approx max for float64 before inf
        return 0.0 # Intensity is effectively zero
    return (2 * h * c**2) / (wavelength_m**5 * (np.exp(exp_term) - 1))

def plot_planck_curve(T):
    """
    Generates a Matplotlib graph of the Planck curve for a given temperature,
    including a background color spectrum.
    """
    wavelengths_nm = np.linspace(100, 3000, 500)
    wavelengths_m = wavelengths_nm * 1e-9
    intensities = np.array([planck_law(wl_m, T) for wl_m in wavelengths_m])

    y_max = np.max(intensities[np.isfinite(intensities)]) if np.any(np.isfinite(intensities)) else 1.0
    if y_max == 0:
        y_max = 1.0

    fig, ax = plt.subplots(figsize=(10, 5))

    # Draw visible spectrum background
    visible_spectrum_start_nm = 380
    visible_spectrum_end_nm = 750
    spectrum_step = 2
    for wl in np.arange(visible_spectrum_start_nm, visible_spectrum_end_nm + spectrum_step, spectrum_step):
        color = get_spectrum_color(wl)
        ax.axvspan(wl, wl + spectrum_step, color=color, alpha=0.8, zorder=0)

    # Plot the Planck curve
    ax.plot(wavelengths_nm, intensities, color='orange', linewidth=2.5, label=f'T = {T} K', zorder=1)

    # Axis styling
    ax.set_title('Spectral Radiance (Planck Curve) with Visible Spectrum')
    ax.set_xlabel('Wavelength (nm)')
    ax.set_ylabel('Spectral Radiance (W·sr⁻¹·m⁻³)')
    ax.set_xlim(100, 3000)
    ax.set_ylim(0, y_max * 1.1)
    ax.grid(True, linestyle='--', linewidth=0.5, alpha=0.5)
    ax.legend()

    fig.tight_layout()
    return fig

# --- Main App ---
def app():
    st.set_page_config(page_title="Stellar Color and Luminosity Calculator", layout="centered")
    st.title("🌟 Stellar Calculator: Luminosity, Flux, and Color")
    st.markdown("Use physical laws to calculate a star's **luminosity**, **flux** at a distance, and **color** based on surface temperature.")

    # Reset button to set inputs to Sun's default values
    reset = st.button("🔁 Reset to Default (Sun's Values)")

    st.subheader("☀️ Input Parameters (Default: Sun)")
    # Input fields for Radius, Temperature, and Distance using scientific notation helper
    R, R_coeff, R_exp = scientific_input("Star Radius (R) [m]", "R", 6.96, 8, reset=reset)
    T, T_coeff, T_exp = scientific_input("Surface Temperature (T) [K]", "T", 5.778, 3, reset=reset)
    D, D_coeff, D_exp = scientific_input("Distance from Star (D) [m]", "D", 1.496, 11, reset=reset)

    # Only perform calculations and display if inputs are valid
    if R > 0 and T > 0 and D > 0:
        # --- Calculations ---
        L = 4 * PI * R**2 * SIGMA * T**4 # Stellar Luminosity (Stefan-Boltzmann Law)
        F = L / (4 * PI * D**2) # Stellar Flux at distance D
        wavelength_peak = WIEN_DISPLACEMENT / T # Wien's Displacement Law
        wavelength_nm = wavelength_peak * 1e9 # Convert peak wavelength to nanometers
        hex_color, rgb_vals = accurate_color_from_temperature(T) # Get perceived color

        # Calculate luminosity and flux relative to the Sun's values
        L_solar_units = L / L_SUN_WATT
        F_solar_units = F / F_SUN_W_PER_M2

        # --- Display Luminosity ---
        st.markdown("---")
        st.subheader("🔌 Luminosity (L)")
        st.latex(fr"L = 4\pi R^2 \sigma T^4") # Formula in LaTeX
        st.latex(fr"""
        L = 4\pi ({R_coeff} \times 10^{{{R_exp}}})^2 \cdot {SIGMA:.2e} \cdot ({T_coeff} \times 10^{{{T_exp}}})^4 = {sci_notation(L)} \ \text{{W}}""")
        st.markdown(f"**Luminosity Relative to Sun ($L_\odot$):** ${sci_notation(L_solar_units)}$ $L_\odot$")

        # --- Display Flux ---
        st.markdown("---")
        st.subheader("📊 Flux (F)")
        st.latex(r"F = \frac{L}{4\pi D^2}") # Formula in LaTeX
        st.latex(fr"""
        F = \frac{{{sci_notation(L)}}}{{4\pi ({D_coeff} \times 10^{{{D_exp}}})^2}} = {sci_notation(F)} \ \text{{W/m²}}""")
        st.markdown(f"**Flux Relative to Sun ($F_\odot$):** ${sci_notation(F_solar_units)}$ $F_\odot$")

        # --- Display Color and Plot ---
        st.markdown("---")
        st.subheader("🖌️ Star Color")
        st.latex(fr"\lambda_{{max}} = {wavelength_nm:.0f} \ \text{{nm}}") # Peak wavelength
        st.markdown(f"**Spectral RGB Color:** <span style='color:{hex_color}'>{hex_color}</span>", unsafe_allow_html=True)
        st.color_picker("🖌 Accurate Color Preview", value=hex_color, label_visibility="collapsed")

        # Display the Planck curve with spectrum background
        st.pyplot(plot_planck_curve(T), use_container_width=True)

        # --- Launch Visualization Button (unchanged) ---
        if st.button("🚀 Launch Visualization"):
            os.makedirs("./visual/luminosity", exist_ok=True)
            data = {
                "star_radius": {"value": R, "coeff": R_coeff, "exp": R_exp},
                "star_temp": {"value": T, "coeff": T_coeff, "exp": T_exp},
                "distance": {"value": D, "coeff": D_coeff, "exp": D_exp},
                "luminosity_watt": L,
                "flux_watt_per_m2": F,
                "peak_wavelength_nm": wavelength_nm,
                "spectral_rgb": rgb_vals.tolist(),
                "hex_color": hex_color,
                "luminosity_readable": f"{sci_notation(L)} W",
                "flux_readable": f"{sci_notation(F)} W/m²",
                "luminosity_solar_units": L_solar_units, # Added solar units to JSON
                "flux_solar_units": F_solar_units # Added solar units to JSON
            }
            file_path = "./visual/luminosity/data.json"
            with open(file_path, "w") as f:
                json.dump(data, f, indent=4)

            st.success(f"✅ Data saved to `{file_path}`!")
            st.json(data)

            try:
                # Attempt to launch an external visualization (Love2D application)
                # This part assumes Love2D is installed and configured in the system's PATH.
                subprocess.Popen([LOVE_PATH, os.path.abspath("./visual/luminosity")])
                st.info("🔄 Love2D visualization launched. Check your system for the pop-up window.")
            except FileNotFoundError:
                st.error("❌ Love2D not found. Make sure it's installed and in your PATH. Skipping visualization launch.")
            except Exception as e:
                st.error(f"An error occurred while trying to launch Love2D: {e}")
    else:
        st.warning("All input values must be greater than zero to proceed with calculation.")
