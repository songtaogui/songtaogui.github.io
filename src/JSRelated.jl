
# --------------------------------- #
# Working with Javascript Libraries #
# --------------------------------- #

function env_mermaid(e, _)
    content = Franklin.content(e)
    return """@@mermaid
        ~~~
        $content
        ~~~@@
        """
end
