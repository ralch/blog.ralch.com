$("#mc-embedded-subscribe-form").ajaxChimp({
    url: "http://ralch.us10.list-manage.com/subscribe/post?u=c50cb2de19171a2729300e252&amp;id=3e61802d58",
    callback: function(response) {
        const info = $("#form-subscribe-info");
        const input = $("#mc-embedded-subscribe-form input");

        const style = response.result;
        const message = response.msg.replace(/([0-9]|-)/g, '');

        info.removeClass();
        input.removeClass();

        info.text(message);
        info.addClass(style);
        input.addClass(style);
    }
});

$(document.links)
    .filter(function() {
        return !this.hostname.endsWith('ralch.com')
    })
    .attr('target', '_blank');
