module UtilitiesTests

using Compat.Test

import Documenter
import Documenter: IdDict

module UnitTests
    module SubModule end

    # Does `submodules` collect *all* the submodules?
    module A
        module B
            module C
                module D end
            end
        end
    end

    mutable struct T end
    mutable struct S{T} end

    "Documenter unit tests."
    Base.length(::T) = 1

    f(x) = x

    const pi = 3.0
end

module OuterModule
module InnerModule
import ..OuterModule
export OuterModule
end
end

@testset "Utilities" begin
    let doc = @doc(length)
        a = Documenter.Utilities.filterdocs(doc, Set{Module}())
        b = Documenter.Utilities.filterdocs(doc, Set{Module}([UnitTests]))
        c = Documenter.Utilities.filterdocs(doc, Set{Module}([Base]))
        d = Documenter.Utilities.filterdocs(doc, Set{Module}([UtilitiesTests]))

        @test a !== nothing
        @test a === doc
        @test b !== nothing
        @test contains(stringmime("text/plain", b), "Documenter unit tests.")
        @test c !== nothing
        @test !contains(stringmime("text/plain", c), "Documenter unit tests.")
        @test d === nothing
    end

    # Documenter.Utilities.issubmodule
    @test Documenter.Utilities.issubmodule(Main, Main) === true
    @test Documenter.Utilities.issubmodule(UnitTests, UnitTests) === true
    @test Documenter.Utilities.issubmodule(UnitTests.SubModule, Main) === true
    @test Documenter.Utilities.issubmodule(UnitTests.SubModule, UnitTests) === true
    @test Documenter.Utilities.issubmodule(UnitTests.SubModule, Base) === false
    @test Documenter.Utilities.issubmodule(UnitTests, UnitTests.SubModule) === false

    @test UnitTests.A in Documenter.Utilities.submodules(UnitTests.A)
    @test UnitTests.A.B in Documenter.Utilities.submodules(UnitTests.A)
    @test UnitTests.A.B.C in Documenter.Utilities.submodules(UnitTests.A)
    @test UnitTests.A.B.C.D in Documenter.Utilities.submodules(UnitTests.A)
    @test OuterModule in Documenter.Utilities.submodules(OuterModule)
    @test OuterModule.InnerModule in Documenter.Utilities.submodules(OuterModule)
    @test length(Documenter.Utilities.submodules(OuterModule)) == 2

    @test Documenter.Utilities.isabsurl("file.md") === false
    @test Documenter.Utilities.isabsurl("../file.md") === false
    @test Documenter.Utilities.isabsurl(".") === false
    @test Documenter.Utilities.isabsurl("https://example.org/file.md") === true
    @test Documenter.Utilities.isabsurl("http://example.org") === true
    @test Documenter.Utilities.isabsurl("ftp://user:pw@example.org") === true
    @test Documenter.Utilities.isabsurl("/fs/absolute/path") === false

    @test Documenter.Utilities.doccat(UnitTests) == "Module"
    @test Documenter.Utilities.doccat(UnitTests.T) == "Type"
    @test Documenter.Utilities.doccat(UnitTests.S) == "Type"
    @test Documenter.Utilities.doccat(UnitTests.f) == "Function"
    @test Documenter.Utilities.doccat(UnitTests.pi) == "Constant"

    # repo type
    @test Documenter.Utilities.repo_host_from_url("https://bitbucket.org/somerepo") == Documenter.Utilities.RepoBitbucket
    @test Documenter.Utilities.repo_host_from_url("https://www.bitbucket.org/somerepo") == Documenter.Utilities.RepoBitbucket
    @test Documenter.Utilities.repo_host_from_url("http://bitbucket.org/somethingelse") == Documenter.Utilities.RepoBitbucket
    @test Documenter.Utilities.repo_host_from_url("http://github.com/Whatever") == Documenter.Utilities.RepoGithub
    @test Documenter.Utilities.repo_host_from_url("https://github.com/Whatever") == Documenter.Utilities.RepoGithub
    @test Documenter.Utilities.repo_host_from_url("https://www.github.com/Whatever") == Documenter.Utilities.RepoGithub
    @test Documenter.Utilities.repo_host_from_url("https://gitlab.com/Whatever") == Documenter.Utilities.RepoGitlab

    # line range
    let
        repo_type = Documenter.Utilities.RepoGithub
        line_range = 2:5
        expected_string = "L2-L5"

        formatting = Documenter.Utilities.LineRangeFormatting(repo_type)
        @test Documenter.Utilities.format_line(line_range, formatting) == expected_string
    end

    let
        repo_type = Documenter.Utilities.RepoBitbucket
        line_range = 2:5
        expected_string = "2:5"

        formatting = Documenter.Utilities.LineRangeFormatting(repo_type)
        @test Documenter.Utilities.format_line(line_range, formatting) == expected_string
    end

    import Documenter.Documents: Document, Page, Globals
    let page = Page("source", "build", [], IdDict(), Globals()), doc = Document()
        code = """
        x += 3
        γγγ_γγγ
        γγγ
        """
        exprs = Documenter.Utilities.parseblock(code, doc, page)

        @test isa(exprs, Vector)
        @test length(exprs) === 3

        @test isa(exprs[1][1], Expr)
        @test exprs[1][1].head === :+=
        @test exprs[1][2] == "x += 3\n"

        @test exprs[2][2] == "γγγ_γγγ\n"

        @test exprs[3][1] === :γγγ
        @test exprs[3][2] == "γγγ\n"
    end

    @testset "TextDiff" begin
        import Documenter.Utilities.TextDiff: splitby
        @test splitby(r"\s+", "X Y  Z") == ["X ", "Y  ", "Z"]
        @test splitby(r"[~]", "X~Y~Z") == ["X~", "Y~", "Z"]
        @test splitby(r"[▶]", "X▶Y▶Z") == ["X▶", "Y▶", "Z"]
        @test splitby(r"[▶]+", "X▶▶Y▶Z▶") == ["X▶▶", "Y▶", "Z▶"]
        @test splitby(r"[▶]+", "▶▶Y▶Z▶") == ["▶▶", "Y▶", "Z▶"]
        @test splitby(r"[▶]+", "Ω▶▶Y▶Z▶") == ["Ω▶▶", "Y▶", "Z▶"]
        @test splitby(r"[▶]+", "Ω▶▶Y▶Z▶κ") == ["Ω▶▶", "Y▶", "Z▶", "κ"]
    end
end

end
