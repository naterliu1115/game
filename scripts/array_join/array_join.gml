/// @function array_join(arr, delimiter)
/// @description Joins the elements of an array into a string using a specified delimiter.
/// @param {array} arr The array to join.
/// @param {string} delimiter The delimiter string to insert between elements.
/// @returns {string}
function array_join(arr, delimiter) {
    var result = "";
    var len = array_length(arr);

    for (var i = 0; i < len; i++) {
        result += string(arr[i]); // Convert element to string
        if (i < len - 1) { // If not the last element
            result += delimiter; // Add delimiter
        }
    }

    return result;
}