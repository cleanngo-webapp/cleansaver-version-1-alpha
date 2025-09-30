/** @type {import('tailwindcss').Config} */
module.exports = {
    content: [
        "./resources/**/*.blade.php",
        "./resources/**/*.js",
        "./resources/**/*.vue",
    ],
    theme: {
        extend: {
            colors: {
                brand: {
                    green: "#248639",
                    gray: "#D9D9D9",
                    highlight: "#42A457",
                },
            },
            fontFamily: {
                inter: ['"Inter"', "serif"],
            },
        },
    },
    plugins: [],
};
