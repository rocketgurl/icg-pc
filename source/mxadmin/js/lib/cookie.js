// Courtesy Tyler, thanks Tyler!
// Handle browser cookies
window.cookie = {
    // Create a new or update a current cookie
    set: function (name, value, days) {
        var date, expires;

        if (days) {
            date = new Date();
            date.setTime(date.getTime() + (days * 24 * 60 * 60 * 1000));
            expires = '; expires=' + date.toGMTString();
        } else {
            expires = '';
        }

        document.cookie = name + '=' + value + expires + '; path=/';
    },

    // Read a cookie by its name
    get: function (name) {
        var cookies = document.cookie.split(';'),
            cookie,
            i;

        for (i = 0; i < cookies.length; i += 1) {
            cookie = cookies[i].replace(/^\s+|\s+$/g,'');// Trim

            if(cookie.indexOf(name+'=') >= 0){
                return cookie.substr(name.length+1);    // just get the value
            }
        }

        return null;
    },

    // Erase a cookie by setting its expiration date to a time in the past
    unset: function (name) {
        this.set(name, '', -1);
    }
};
