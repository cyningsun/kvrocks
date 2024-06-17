// DebugInserter.cpp
#include "clang/AST/AST.h"
#include "clang/AST/ASTConsumer.h"
#include "clang/Frontend/FrontendActions.h"
#include "clang/Frontend/CompilerInstance.h"
#include "clang/Rewrite/Core/Rewriter.h"
#include "clang/Tooling/CommonOptionsParser.h"
#include "clang/Tooling/Tooling.h"
#include "clang/ASTMatchers/ASTMatchers.h"
#include "clang/ASTMatchers/ASTMatchFinder.h"
#include "clang/Frontend/FrontendActions.h"
#include "llvm/Support/CommandLine.h"
#include <iostream>


using namespace llvm;
using namespace clang;
using namespace clang::tooling;
using namespace clang::ast_matchers;

class DebugInserter : public MatchFinder::MatchCallback {
public:
    DebugInserter(Rewriter &Rewrite) : Rewrite(Rewrite) {}

    virtual void run(const MatchFinder::MatchResult &Result) {
        const FunctionDecl *Func = Result.Nodes.getNodeAs<FunctionDecl>("funcDecl");
        if (Func && Func->hasBody()) {
            const Stmt *FuncBody = Func->getBody();
            SourceLocation ST = FuncBody->getBeginLoc();
            Rewrite.InsertText(ST, "std::cout << \"Debug: Entering function\\n\";", true, true);
        }
    }

private:
    Rewriter &Rewrite;
};

class DebugInserterASTConsumer : public ASTConsumer {
public:
    DebugInserterASTConsumer(Rewriter &R) : HandlerForFunc(R) {
        Matcher.addMatcher(functionDecl(isDefinition()).bind("funcDecl"), &HandlerForFunc);
    }

    void HandleTranslationUnit(ASTContext &Context) override {
        Matcher.matchAST(Context);
    }

private:
    DebugInserter HandlerForFunc;
    MatchFinder Matcher;
};

class DebugInserterFrontendAction : public ASTFrontendAction {
public:
    DebugInserterFrontendAction() {}

    void EndSourceFileAction() override {
        SourceManager &SM = TheRewriter.getSourceMgr();
        llvm::errs() << "** EndSourceFileAction for: "
                     << SM.getFileEntryForID(SM.getMainFileID())->getName() << "\n";
        TheRewriter.getEditBuffer(SM.getMainFileID()).write(llvm::outs());
    }

    std::unique_ptr<ASTConsumer> CreateASTConsumer(CompilerInstance &CI, StringRef file) override {
        TheRewriter.setSourceMgr(CI.getSourceManager(), CI.getLangOpts());
        return std::make_unique<DebugInserterASTConsumer>(TheRewriter);
    }

private:
    Rewriter TheRewriter;
};

static cl::OptionCategory MyToolCategory("my-tool options");

int main(int argc, const char **argv) {
    // Use the static create method
    auto ExpectedParser = CommonOptionsParser::create(argc, argv, MyToolCategory);
    if (!ExpectedParser) {
        // Handle the error, e.g., print the error message
        llvm::errs() << ExpectedParser.takeError();
        return 1;
    }
    
    CommonOptionsParser& OptionsParser = *ExpectedParser;
    ClangTool Tool(OptionsParser.getCompilations(), OptionsParser.getSourcePathList());
    return Tool.run(newFrontendActionFactory<DebugInserterFrontendAction>().get());
}