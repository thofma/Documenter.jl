module MDFlattenTests
using Base.Test
using Base.Markdown
using Documenter.Utilities.MDFlatten

@testset "MDFlatten" begin
    @test mdflatten(Markdown.Paragraph("...")) == "..."
    @test mdflatten(Markdown.Header{1}("...")) == "..."

    # a simple test for blocks in top-level (each gets two newline appended to it)
    @test mdflatten(Markdown.parse("# Test\nTest")) == "Test\n\nTest\n\n"
    block_md = md"""
    # MDFlatten test


    ^^^ Ignoring extra whitespace.

    ```markdown
    code
    is forwarded as **is**
    ```
    """
    block_text = """
    MDFlatten test

    ^^^ Ignoring extra whitespace.

    code
    is forwarded as **is**

    """
    @test mdflatten(block_md) == block_text

    # blocks
    @test mdflatten(Markdown.parse("> Test\n> Test\n\n> Test")) == "Test Test\n\nTest\n\n"
    @test mdflatten(Markdown.parse("HRs\n\n---\n\nto whitespace")) == "HRs\n\n\n\nto whitespace\n\n"

    # test some inline blocks
    @test mdflatten(md"`code` *em* normal **strong**") == "code em normal strong\n\n"
    @test mdflatten(md"[link text *parsed*](link/itself/ignored)") == "link text parsed\n\n"
    @test mdflatten(md"![title text **unparsed**](image/link/ignored)") == "[Image: title text **unparsed**]\n\n"
    @test mdflatten(md"![title text **unparsed**](image/link/ignored)") == "[Image: title text **unparsed**]\n\n"
    @test mdflatten(md"``e=mc^2``") == "``e=mc^2``\n\n"

    # symbols in markdown
    @test mdflatten(Markdown.parse("A \$B C")) == "A B C\n\n"

    # linebreaks
    @test mdflatten(Markdown.parse("A\\\nB")) == "A\nB\n\n"

    # Only available on Julia 0.5.
    if isdefined(Base.Markdown, :Footnote)
        @test mdflatten(md"[^name]") == "[name]\n\n"
        @test mdflatten(md"[^name]:**Strong** text.") == "[name]: Strong text.\n\n"
    end

    if isdefined(Base.Markdown, :Admonition)
        @test mdflatten(Markdown.parse("!!! note \"Admonition Title\"\n    Test")) == "note: Admonition Title\nTest\n\n"
    end
end

end
