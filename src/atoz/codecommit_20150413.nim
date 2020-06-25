
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5, base64,
  httpcore, sigv4

## auto-generated via openapi macro
## title: AWS CodeCommit
## version: 2015-04-13
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <fullname>AWS CodeCommit</fullname> <p>This is the <i>AWS CodeCommit API Reference</i>. This reference provides descriptions of the operations and data types for AWS CodeCommit API along with usage examples.</p> <p>You can use the AWS CodeCommit API to work with the following objects:</p> <p>Repositories, by calling the following:</p> <ul> <li> <p> <a>BatchGetRepositories</a>, which returns information about one or more repositories associated with your AWS account.</p> </li> <li> <p> <a>CreateRepository</a>, which creates an AWS CodeCommit repository.</p> </li> <li> <p> <a>DeleteRepository</a>, which deletes an AWS CodeCommit repository.</p> </li> <li> <p> <a>GetRepository</a>, which returns information about a specified repository.</p> </li> <li> <p> <a>ListRepositories</a>, which lists all AWS CodeCommit repositories associated with your AWS account.</p> </li> <li> <p> <a>UpdateRepositoryDescription</a>, which sets or updates the description of the repository.</p> </li> <li> <p> <a>UpdateRepositoryName</a>, which changes the name of the repository. If you change the name of a repository, no other users of that repository can access it until you send them the new HTTPS or SSH URL to use.</p> </li> </ul> <p>Branches, by calling the following:</p> <ul> <li> <p> <a>CreateBranch</a>, which creates a branch in a specified repository.</p> </li> <li> <p> <a>DeleteBranch</a>, which deletes the specified branch in a repository unless it is the default branch.</p> </li> <li> <p> <a>GetBranch</a>, which returns information about a specified branch.</p> </li> <li> <p> <a>ListBranches</a>, which lists all branches for a specified repository.</p> </li> <li> <p> <a>UpdateDefaultBranch</a>, which changes the default branch for a repository.</p> </li> </ul> <p>Files, by calling the following:</p> <ul> <li> <p> <a>DeleteFile</a>, which deletes the content of a specified file from a specified branch.</p> </li> <li> <p> <a>GetBlob</a>, which returns the base-64 encoded content of an individual Git blob object in a repository.</p> </li> <li> <p> <a>GetFile</a>, which returns the base-64 encoded content of a specified file.</p> </li> <li> <p> <a>GetFolder</a>, which returns the contents of a specified folder or directory.</p> </li> <li> <p> <a>PutFile</a>, which adds or modifies a single file in a specified repository and branch.</p> </li> </ul> <p>Commits, by calling the following:</p> <ul> <li> <p> <a>BatchGetCommits</a>, which returns information about one or more commits in a repository.</p> </li> <li> <p> <a>CreateCommit</a>, which creates a commit for changes to a repository.</p> </li> <li> <p> <a>GetCommit</a>, which returns information about a commit, including commit messages and author and committer information.</p> </li> <li> <p> <a>GetDifferences</a>, which returns information about the differences in a valid commit specifier (such as a branch, tag, HEAD, commit ID, or other fully qualified reference).</p> </li> </ul> <p>Merges, by calling the following:</p> <ul> <li> <p> <a>BatchDescribeMergeConflicts</a>, which returns information about conflicts in a merge between commits in a repository.</p> </li> <li> <p> <a>CreateUnreferencedMergeCommit</a>, which creates an unreferenced commit between two branches or commits for the purpose of comparing them and identifying any potential conflicts.</p> </li> <li> <p> <a>DescribeMergeConflicts</a>, which returns information about merge conflicts between the base, source, and destination versions of a file in a potential merge.</p> </li> <li> <p> <a>GetMergeCommit</a>, which returns information about the merge between a source and destination commit. </p> </li> <li> <p> <a>GetMergeConflicts</a>, which returns information about merge conflicts between the source and destination branch in a pull request.</p> </li> <li> <p> <a>GetMergeOptions</a>, which returns information about the available merge options between two branches or commit specifiers.</p> </li> <li> <p> <a>MergeBranchesByFastForward</a>, which merges two branches using the fast-forward merge option.</p> </li> <li> <p> <a>MergeBranchesBySquash</a>, which merges two branches using the squash merge option.</p> </li> <li> <p> <a>MergeBranchesByThreeWay</a>, which merges two branches using the three-way merge option.</p> </li> </ul> <p>Pull requests, by calling the following:</p> <ul> <li> <p> <a>CreatePullRequest</a>, which creates a pull request in a specified repository.</p> </li> <li> <p> <a>CreatePullRequestApprovalRule</a>, which creates an approval rule for a specified pull request.</p> </li> <li> <p> <a>DeletePullRequestApprovalRule</a>, which deletes an approval rule for a specified pull request.</p> </li> <li> <p> <a>DescribePullRequestEvents</a>, which returns information about one or more pull request events.</p> </li> <li> <p> <a>EvaluatePullRequestApprovalRules</a>, which evaluates whether a pull request has met all the conditions specified in its associated approval rules.</p> </li> <li> <p> <a>GetCommentsForPullRequest</a>, which returns information about comments on a specified pull request.</p> </li> <li> <p> <a>GetPullRequest</a>, which returns information about a specified pull request.</p> </li> <li> <p> <a>GetPullRequestApprovalStates</a>, which returns information about the approval states for a specified pull request.</p> </li> <li> <p> <a>GetPullRequestOverrideState</a>, which returns information about whether approval rules have been set aside (overriden) for a pull request, and if so, the Amazon Resource Name (ARN) of the user or identity that overrode the rules and their requirements for the pull request.</p> </li> <li> <p> <a>ListPullRequests</a>, which lists all pull requests for a repository.</p> </li> <li> <p> <a>MergePullRequestByFastForward</a>, which merges the source destination branch of a pull request into the specified destination branch for that pull request using the fast-forward merge option.</p> </li> <li> <p> <a>MergePullRequestBySquash</a>, which merges the source destination branch of a pull request into the specified destination branch for that pull request using the squash merge option.</p> </li> <li> <p> <a>MergePullRequestByThreeWay</a>. which merges the source destination branch of a pull request into the specified destination branch for that pull request using the three-way merge option.</p> </li> <li> <p> <a>OverridePullRequestApprovalRules</a>, which sets aside all approval rule requirements for a pull request.</p> </li> <li> <p> <a>PostCommentForPullRequest</a>, which posts a comment to a pull request at the specified line, file, or request.</p> </li> <li> <p> <a>UpdatePullRequestApprovalRuleContent</a>, which updates the structure of an approval rule for a pull request.</p> </li> <li> <p> <a>UpdatePullRequestApprovalState</a>, which updates the state of an approval on a pull request.</p> </li> <li> <p> <a>UpdatePullRequestDescription</a>, which updates the description of a pull request.</p> </li> <li> <p> <a>UpdatePullRequestStatus</a>, which updates the status of a pull request.</p> </li> <li> <p> <a>UpdatePullRequestTitle</a>, which updates the title of a pull request.</p> </li> </ul> <p>Approval rule templates, by calling the following:</p> <ul> <li> <p> <a>AssociateApprovalRuleTemplateWithRepository</a>, which associates a template with a specified repository. After the template is associated with a repository, AWS CodeCommit creates approval rules that match the template conditions on every pull request created in the specified repository.</p> </li> <li> <p> <a>BatchAssociateApprovalRuleTemplateWithRepositories</a>, which associates a template with one or more specified repositories. After the template is associated with a repository, AWS CodeCommit creates approval rules that match the template conditions on every pull request created in the specified repositories.</p> </li> <li> <p> <a>BatchDisassociateApprovalRuleTemplateFromRepositories</a>, which removes the association between a template and specified repositories so that approval rules based on the template are not automatically created when pull requests are created in those repositories.</p> </li> <li> <p> <a>CreateApprovalRuleTemplate</a>, which creates a template for approval rules that can then be associated with one or more repositories in your AWS account.</p> </li> <li> <p> <a>DeleteApprovalRuleTemplate</a>, which deletes the specified template. It does not remove approval rules on pull requests already created with the template.</p> </li> <li> <p> <a>DisassociateApprovalRuleTemplateFromRepository</a>, which removes the association between a template and a repository so that approval rules based on the template are not automatically created when pull requests are created in the specified repository.</p> </li> <li> <p> <a>GetApprovalRuleTemplate</a>, which returns information about an approval rule template.</p> </li> <li> <p> <a>ListApprovalRuleTemplates</a>, which lists all approval rule templates in the AWS Region in your AWS account.</p> </li> <li> <p> <a>ListAssociatedApprovalRuleTemplatesForRepository</a>, which lists all approval rule templates that are associated with a specified repository.</p> </li> <li> <p> <a>ListRepositoriesForApprovalRuleTemplate</a>, which lists all repositories associated with the specified approval rule template.</p> </li> <li> <p> <a>UpdateApprovalRuleTemplateDescription</a>, which updates the description of an approval rule template.</p> </li> <li> <p> <a>UpdateApprovalRuleTemplateName</a>, which updates the name of an approval rule template.</p> </li> <li> <p> <a>UpdateApprovalRuleTemplateContent</a>, which updates the content of an approval rule template.</p> </li> </ul> <p>Comments in a repository, by calling the following:</p> <ul> <li> <p> <a>DeleteCommentContent</a>, which deletes the content of a comment on a commit in a repository.</p> </li> <li> <p> <a>GetComment</a>, which returns information about a comment on a commit.</p> </li> <li> <p> <a>GetCommentsForComparedCommit</a>, which returns information about comments on the comparison between two commit specifiers in a repository.</p> </li> <li> <p> <a>PostCommentForComparedCommit</a>, which creates a comment on the comparison between two commit specifiers in a repository.</p> </li> <li> <p> <a>PostCommentReply</a>, which creates a reply to a comment.</p> </li> <li> <p> <a>UpdateComment</a>, which updates the content of a comment on a commit in a repository.</p> </li> </ul> <p>Tags used to tag resources in AWS CodeCommit (not Git tags), by calling the following:</p> <ul> <li> <p> <a>ListTagsForResource</a>, which gets information about AWS tags for a specified Amazon Resource Name (ARN) in AWS CodeCommit.</p> </li> <li> <p> <a>TagResource</a>, which adds or updates tags for a resource in AWS CodeCommit.</p> </li> <li> <p> <a>UntagResource</a>, which removes tags for a resource in AWS CodeCommit.</p> </li> </ul> <p>Triggers, by calling the following:</p> <ul> <li> <p> <a>GetRepositoryTriggers</a>, which returns information about triggers configured for a repository.</p> </li> <li> <p> <a>PutRepositoryTriggers</a>, which replaces all triggers for a repository and can be used to create or delete triggers.</p> </li> <li> <p> <a>TestRepositoryTriggers</a>, which tests the functionality of a repository trigger by sending data to the trigger target.</p> </li> </ul> <p>For information about how to use AWS CodeCommit, see the <a href="https://docs.aws.amazon.com/codecommit/latest/userguide/welcome.html">AWS CodeCommit User Guide</a>.</p>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/codecommit/
type
  Scheme {.pure.} = enum
    Https = "https", Http = "http", Wss = "wss", Ws = "ws"
  ValidatorSignature = proc (path: JsonNode = nil; query: JsonNode = nil;
                          header: JsonNode = nil; formData: JsonNode = nil;
                          body: JsonNode = nil; _: string = ""): JsonNode
  OpenApiRestCall = ref object of RestCall
    validator*: ValidatorSignature
    route*: string
    base*: string
    host*: string
    schemes*: set[Scheme]
    makeUrl*: proc (protocol: Scheme; host: string; base: string; route: string;
                  path: JsonNode; query: JsonNode): Uri

  OpenApiRestCall_21625435 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_21625435](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_21625435): Option[Scheme] {.used.} =
  ## select a supported scheme from a set of candidates
  for scheme in Scheme.low .. Scheme.high:
    if scheme notin t.schemes:
      continue
    if scheme in [Scheme.Https, Scheme.Wss]:
      when defined(ssl):
        return some(scheme)
      else:
        continue
    return some(scheme)

proc validateParameter(js: JsonNode; kind: JsonNodeKind; required: bool;
                      default: JsonNode = nil): JsonNode =
  ## ensure an input is of the correct json type and yield
  ## a suitable default value when appropriate
  if js == nil:
    if required:
      if default != nil:
        return validateParameter(default, kind, required = required)
  result = js
  if result == nil:
    assert not required, $kind & " expected; received nil"
    if required:
      result = newJNull()
  else:
    assert js.kind == kind, $kind & " expected; received " & $js.kind

type
  KeyVal {.used.} = tuple[key: string, val: string]
  PathTokenKind = enum
    ConstantSegment, VariableSegment
  PathToken = tuple[kind: PathTokenKind, value: string]
proc queryString(query: JsonNode): string {.used.} =
  var qs: seq[KeyVal]
  if query == nil:
    return ""
  for k, v in query.pairs:
    qs.add (key: k, val: v.getStr)
  result = encodeQuery(qs)

proc hydratePath(input: JsonNode; segments: seq[PathToken]): Option[string] {.used.} =
  ## reconstitute a path with constants and variable values taken from json
  var head: string
  if segments.len == 0:
    return some("")
  head = segments[0].value
  case segments[0].kind
  of ConstantSegment:
    discard
  of VariableSegment:
    if head notin input:
      return
    let js = input[head]
    case js.kind
    of JInt, JFloat, JNull, JBool:
      head = $js
    of JString:
      head = js.getStr
    else:
      return
  var remainder = input.hydratePath(segments[1 ..^ 1])
  if remainder.isNone:
    return
  result = some(head & remainder.get)

const
  awsServers = {Scheme.Http: {"ap-northeast-1": "codecommit.ap-northeast-1.amazonaws.com", "ap-southeast-1": "codecommit.ap-southeast-1.amazonaws.com",
                           "us-west-2": "codecommit.us-west-2.amazonaws.com",
                           "eu-west-2": "codecommit.eu-west-2.amazonaws.com", "ap-northeast-3": "codecommit.ap-northeast-3.amazonaws.com", "eu-central-1": "codecommit.eu-central-1.amazonaws.com",
                           "us-east-2": "codecommit.us-east-2.amazonaws.com",
                           "us-east-1": "codecommit.us-east-1.amazonaws.com", "cn-northwest-1": "codecommit.cn-northwest-1.amazonaws.com.cn",
                           "ap-south-1": "codecommit.ap-south-1.amazonaws.com",
                           "eu-north-1": "codecommit.eu-north-1.amazonaws.com", "ap-northeast-2": "codecommit.ap-northeast-2.amazonaws.com",
                           "us-west-1": "codecommit.us-west-1.amazonaws.com", "us-gov-east-1": "codecommit.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "codecommit.eu-west-3.amazonaws.com", "cn-north-1": "codecommit.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "codecommit.sa-east-1.amazonaws.com",
                           "eu-west-1": "codecommit.eu-west-1.amazonaws.com", "us-gov-west-1": "codecommit.us-gov-west-1.amazonaws.com", "ap-southeast-2": "codecommit.ap-southeast-2.amazonaws.com", "ca-central-1": "codecommit.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "codecommit.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "codecommit.ap-southeast-1.amazonaws.com",
      "us-west-2": "codecommit.us-west-2.amazonaws.com",
      "eu-west-2": "codecommit.eu-west-2.amazonaws.com",
      "ap-northeast-3": "codecommit.ap-northeast-3.amazonaws.com",
      "eu-central-1": "codecommit.eu-central-1.amazonaws.com",
      "us-east-2": "codecommit.us-east-2.amazonaws.com",
      "us-east-1": "codecommit.us-east-1.amazonaws.com",
      "cn-northwest-1": "codecommit.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "codecommit.ap-south-1.amazonaws.com",
      "eu-north-1": "codecommit.eu-north-1.amazonaws.com",
      "ap-northeast-2": "codecommit.ap-northeast-2.amazonaws.com",
      "us-west-1": "codecommit.us-west-1.amazonaws.com",
      "us-gov-east-1": "codecommit.us-gov-east-1.amazonaws.com",
      "eu-west-3": "codecommit.eu-west-3.amazonaws.com",
      "cn-north-1": "codecommit.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "codecommit.sa-east-1.amazonaws.com",
      "eu-west-1": "codecommit.eu-west-1.amazonaws.com",
      "us-gov-west-1": "codecommit.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "codecommit.ap-southeast-2.amazonaws.com",
      "ca-central-1": "codecommit.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "codecommit"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode; body: string = ""): Recallable {.
    base.}
type
  Call_AssociateApprovalRuleTemplateWithRepository_21625779 = ref object of OpenApiRestCall_21625435
proc url_AssociateApprovalRuleTemplateWithRepository_21625781(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AssociateApprovalRuleTemplateWithRepository_21625780(
    path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Creates an association between an approval rule template and a specified repository. Then, the next time a pull request is created in the repository where the destination reference (if specified) matches the destination reference (branch) for the pull request, an approval rule that matches the template conditions is automatically created for that pull request. If no destination references are specified in the template, an approval rule that matches the template contents is created for all pull requests in that repository.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21625882 = header.getOrDefault("X-Amz-Date")
  valid_21625882 = validateParameter(valid_21625882, JString, required = false,
                                   default = nil)
  if valid_21625882 != nil:
    section.add "X-Amz-Date", valid_21625882
  var valid_21625883 = header.getOrDefault("X-Amz-Security-Token")
  valid_21625883 = validateParameter(valid_21625883, JString, required = false,
                                   default = nil)
  if valid_21625883 != nil:
    section.add "X-Amz-Security-Token", valid_21625883
  var valid_21625898 = header.getOrDefault("X-Amz-Target")
  valid_21625898 = validateParameter(valid_21625898, JString, required = true, default = newJString(
      "CodeCommit_20150413.AssociateApprovalRuleTemplateWithRepository"))
  if valid_21625898 != nil:
    section.add "X-Amz-Target", valid_21625898
  var valid_21625899 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21625899 = validateParameter(valid_21625899, JString, required = false,
                                   default = nil)
  if valid_21625899 != nil:
    section.add "X-Amz-Content-Sha256", valid_21625899
  var valid_21625900 = header.getOrDefault("X-Amz-Algorithm")
  valid_21625900 = validateParameter(valid_21625900, JString, required = false,
                                   default = nil)
  if valid_21625900 != nil:
    section.add "X-Amz-Algorithm", valid_21625900
  var valid_21625901 = header.getOrDefault("X-Amz-Signature")
  valid_21625901 = validateParameter(valid_21625901, JString, required = false,
                                   default = nil)
  if valid_21625901 != nil:
    section.add "X-Amz-Signature", valid_21625901
  var valid_21625902 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21625902 = validateParameter(valid_21625902, JString, required = false,
                                   default = nil)
  if valid_21625902 != nil:
    section.add "X-Amz-SignedHeaders", valid_21625902
  var valid_21625903 = header.getOrDefault("X-Amz-Credential")
  valid_21625903 = validateParameter(valid_21625903, JString, required = false,
                                   default = nil)
  if valid_21625903 != nil:
    section.add "X-Amz-Credential", valid_21625903
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21625929: Call_AssociateApprovalRuleTemplateWithRepository_21625779;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates an association between an approval rule template and a specified repository. Then, the next time a pull request is created in the repository where the destination reference (if specified) matches the destination reference (branch) for the pull request, an approval rule that matches the template conditions is automatically created for that pull request. If no destination references are specified in the template, an approval rule that matches the template contents is created for all pull requests in that repository.
  ## 
  let valid = call_21625929.validator(path, query, header, formData, body, _)
  let scheme = call_21625929.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21625929.makeUrl(scheme.get, call_21625929.host, call_21625929.base,
                               call_21625929.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21625929, uri, valid, _)

proc call*(call_21625992: Call_AssociateApprovalRuleTemplateWithRepository_21625779;
          body: JsonNode): Recallable =
  ## associateApprovalRuleTemplateWithRepository
  ## Creates an association between an approval rule template and a specified repository. Then, the next time a pull request is created in the repository where the destination reference (if specified) matches the destination reference (branch) for the pull request, an approval rule that matches the template conditions is automatically created for that pull request. If no destination references are specified in the template, an approval rule that matches the template contents is created for all pull requests in that repository.
  ##   body: JObject (required)
  var body_21625993 = newJObject()
  if body != nil:
    body_21625993 = body
  result = call_21625992.call(nil, nil, nil, nil, body_21625993)

var associateApprovalRuleTemplateWithRepository* = Call_AssociateApprovalRuleTemplateWithRepository_21625779(
    name: "associateApprovalRuleTemplateWithRepository",
    meth: HttpMethod.HttpPost, host: "codecommit.amazonaws.com", route: "/#X-Amz-Target=CodeCommit_20150413.AssociateApprovalRuleTemplateWithRepository",
    validator: validate_AssociateApprovalRuleTemplateWithRepository_21625780,
    base: "/", makeUrl: url_AssociateApprovalRuleTemplateWithRepository_21625781,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchAssociateApprovalRuleTemplateWithRepositories_21626029 = ref object of OpenApiRestCall_21625435
proc url_BatchAssociateApprovalRuleTemplateWithRepositories_21626031(
    protocol: Scheme; host: string; base: string; route: string; path: JsonNode;
    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_BatchAssociateApprovalRuleTemplateWithRepositories_21626030(
    path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Creates an association between an approval rule template and one or more specified repositories. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626032 = header.getOrDefault("X-Amz-Date")
  valid_21626032 = validateParameter(valid_21626032, JString, required = false,
                                   default = nil)
  if valid_21626032 != nil:
    section.add "X-Amz-Date", valid_21626032
  var valid_21626033 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626033 = validateParameter(valid_21626033, JString, required = false,
                                   default = nil)
  if valid_21626033 != nil:
    section.add "X-Amz-Security-Token", valid_21626033
  var valid_21626034 = header.getOrDefault("X-Amz-Target")
  valid_21626034 = validateParameter(valid_21626034, JString, required = true, default = newJString(
      "CodeCommit_20150413.BatchAssociateApprovalRuleTemplateWithRepositories"))
  if valid_21626034 != nil:
    section.add "X-Amz-Target", valid_21626034
  var valid_21626035 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626035 = validateParameter(valid_21626035, JString, required = false,
                                   default = nil)
  if valid_21626035 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626035
  var valid_21626036 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626036 = validateParameter(valid_21626036, JString, required = false,
                                   default = nil)
  if valid_21626036 != nil:
    section.add "X-Amz-Algorithm", valid_21626036
  var valid_21626037 = header.getOrDefault("X-Amz-Signature")
  valid_21626037 = validateParameter(valid_21626037, JString, required = false,
                                   default = nil)
  if valid_21626037 != nil:
    section.add "X-Amz-Signature", valid_21626037
  var valid_21626038 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626038 = validateParameter(valid_21626038, JString, required = false,
                                   default = nil)
  if valid_21626038 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626038
  var valid_21626039 = header.getOrDefault("X-Amz-Credential")
  valid_21626039 = validateParameter(valid_21626039, JString, required = false,
                                   default = nil)
  if valid_21626039 != nil:
    section.add "X-Amz-Credential", valid_21626039
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626041: Call_BatchAssociateApprovalRuleTemplateWithRepositories_21626029;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates an association between an approval rule template and one or more specified repositories. 
  ## 
  let valid = call_21626041.validator(path, query, header, formData, body, _)
  let scheme = call_21626041.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626041.makeUrl(scheme.get, call_21626041.host, call_21626041.base,
                               call_21626041.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626041, uri, valid, _)

proc call*(call_21626042: Call_BatchAssociateApprovalRuleTemplateWithRepositories_21626029;
          body: JsonNode): Recallable =
  ## batchAssociateApprovalRuleTemplateWithRepositories
  ## Creates an association between an approval rule template and one or more specified repositories. 
  ##   body: JObject (required)
  var body_21626043 = newJObject()
  if body != nil:
    body_21626043 = body
  result = call_21626042.call(nil, nil, nil, nil, body_21626043)

var batchAssociateApprovalRuleTemplateWithRepositories* = Call_BatchAssociateApprovalRuleTemplateWithRepositories_21626029(
    name: "batchAssociateApprovalRuleTemplateWithRepositories",
    meth: HttpMethod.HttpPost, host: "codecommit.amazonaws.com", route: "/#X-Amz-Target=CodeCommit_20150413.BatchAssociateApprovalRuleTemplateWithRepositories",
    validator: validate_BatchAssociateApprovalRuleTemplateWithRepositories_21626030,
    base: "/", makeUrl: url_BatchAssociateApprovalRuleTemplateWithRepositories_21626031,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchDescribeMergeConflicts_21626044 = ref object of OpenApiRestCall_21625435
proc url_BatchDescribeMergeConflicts_21626046(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_BatchDescribeMergeConflicts_21626045(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns information about one or more merge conflicts in the attempted merge of two commit specifiers using the squash or three-way merge strategy.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626047 = header.getOrDefault("X-Amz-Date")
  valid_21626047 = validateParameter(valid_21626047, JString, required = false,
                                   default = nil)
  if valid_21626047 != nil:
    section.add "X-Amz-Date", valid_21626047
  var valid_21626048 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626048 = validateParameter(valid_21626048, JString, required = false,
                                   default = nil)
  if valid_21626048 != nil:
    section.add "X-Amz-Security-Token", valid_21626048
  var valid_21626049 = header.getOrDefault("X-Amz-Target")
  valid_21626049 = validateParameter(valid_21626049, JString, required = true, default = newJString(
      "CodeCommit_20150413.BatchDescribeMergeConflicts"))
  if valid_21626049 != nil:
    section.add "X-Amz-Target", valid_21626049
  var valid_21626050 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626050 = validateParameter(valid_21626050, JString, required = false,
                                   default = nil)
  if valid_21626050 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626050
  var valid_21626051 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626051 = validateParameter(valid_21626051, JString, required = false,
                                   default = nil)
  if valid_21626051 != nil:
    section.add "X-Amz-Algorithm", valid_21626051
  var valid_21626052 = header.getOrDefault("X-Amz-Signature")
  valid_21626052 = validateParameter(valid_21626052, JString, required = false,
                                   default = nil)
  if valid_21626052 != nil:
    section.add "X-Amz-Signature", valid_21626052
  var valid_21626053 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626053 = validateParameter(valid_21626053, JString, required = false,
                                   default = nil)
  if valid_21626053 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626053
  var valid_21626054 = header.getOrDefault("X-Amz-Credential")
  valid_21626054 = validateParameter(valid_21626054, JString, required = false,
                                   default = nil)
  if valid_21626054 != nil:
    section.add "X-Amz-Credential", valid_21626054
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626056: Call_BatchDescribeMergeConflicts_21626044;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns information about one or more merge conflicts in the attempted merge of two commit specifiers using the squash or three-way merge strategy.
  ## 
  let valid = call_21626056.validator(path, query, header, formData, body, _)
  let scheme = call_21626056.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626056.makeUrl(scheme.get, call_21626056.host, call_21626056.base,
                               call_21626056.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626056, uri, valid, _)

proc call*(call_21626057: Call_BatchDescribeMergeConflicts_21626044; body: JsonNode): Recallable =
  ## batchDescribeMergeConflicts
  ## Returns information about one or more merge conflicts in the attempted merge of two commit specifiers using the squash or three-way merge strategy.
  ##   body: JObject (required)
  var body_21626058 = newJObject()
  if body != nil:
    body_21626058 = body
  result = call_21626057.call(nil, nil, nil, nil, body_21626058)

var batchDescribeMergeConflicts* = Call_BatchDescribeMergeConflicts_21626044(
    name: "batchDescribeMergeConflicts", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.BatchDescribeMergeConflicts",
    validator: validate_BatchDescribeMergeConflicts_21626045, base: "/",
    makeUrl: url_BatchDescribeMergeConflicts_21626046,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchDisassociateApprovalRuleTemplateFromRepositories_21626059 = ref object of OpenApiRestCall_21625435
proc url_BatchDisassociateApprovalRuleTemplateFromRepositories_21626061(
    protocol: Scheme; host: string; base: string; route: string; path: JsonNode;
    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_BatchDisassociateApprovalRuleTemplateFromRepositories_21626060(
    path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Removes the association between an approval rule template and one or more specified repositories. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626062 = header.getOrDefault("X-Amz-Date")
  valid_21626062 = validateParameter(valid_21626062, JString, required = false,
                                   default = nil)
  if valid_21626062 != nil:
    section.add "X-Amz-Date", valid_21626062
  var valid_21626063 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626063 = validateParameter(valid_21626063, JString, required = false,
                                   default = nil)
  if valid_21626063 != nil:
    section.add "X-Amz-Security-Token", valid_21626063
  var valid_21626064 = header.getOrDefault("X-Amz-Target")
  valid_21626064 = validateParameter(valid_21626064, JString, required = true, default = newJString("CodeCommit_20150413.BatchDisassociateApprovalRuleTemplateFromRepositories"))
  if valid_21626064 != nil:
    section.add "X-Amz-Target", valid_21626064
  var valid_21626065 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626065 = validateParameter(valid_21626065, JString, required = false,
                                   default = nil)
  if valid_21626065 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626065
  var valid_21626066 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626066 = validateParameter(valid_21626066, JString, required = false,
                                   default = nil)
  if valid_21626066 != nil:
    section.add "X-Amz-Algorithm", valid_21626066
  var valid_21626067 = header.getOrDefault("X-Amz-Signature")
  valid_21626067 = validateParameter(valid_21626067, JString, required = false,
                                   default = nil)
  if valid_21626067 != nil:
    section.add "X-Amz-Signature", valid_21626067
  var valid_21626068 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626068 = validateParameter(valid_21626068, JString, required = false,
                                   default = nil)
  if valid_21626068 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626068
  var valid_21626069 = header.getOrDefault("X-Amz-Credential")
  valid_21626069 = validateParameter(valid_21626069, JString, required = false,
                                   default = nil)
  if valid_21626069 != nil:
    section.add "X-Amz-Credential", valid_21626069
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626071: Call_BatchDisassociateApprovalRuleTemplateFromRepositories_21626059;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Removes the association between an approval rule template and one or more specified repositories. 
  ## 
  let valid = call_21626071.validator(path, query, header, formData, body, _)
  let scheme = call_21626071.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626071.makeUrl(scheme.get, call_21626071.host, call_21626071.base,
                               call_21626071.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626071, uri, valid, _)

proc call*(call_21626072: Call_BatchDisassociateApprovalRuleTemplateFromRepositories_21626059;
          body: JsonNode): Recallable =
  ## batchDisassociateApprovalRuleTemplateFromRepositories
  ## Removes the association between an approval rule template and one or more specified repositories. 
  ##   body: JObject (required)
  var body_21626073 = newJObject()
  if body != nil:
    body_21626073 = body
  result = call_21626072.call(nil, nil, nil, nil, body_21626073)

var batchDisassociateApprovalRuleTemplateFromRepositories* = Call_BatchDisassociateApprovalRuleTemplateFromRepositories_21626059(
    name: "batchDisassociateApprovalRuleTemplateFromRepositories",
    meth: HttpMethod.HttpPost, host: "codecommit.amazonaws.com", route: "/#X-Amz-Target=CodeCommit_20150413.BatchDisassociateApprovalRuleTemplateFromRepositories",
    validator: validate_BatchDisassociateApprovalRuleTemplateFromRepositories_21626060,
    base: "/", makeUrl: url_BatchDisassociateApprovalRuleTemplateFromRepositories_21626061,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchGetCommits_21626074 = ref object of OpenApiRestCall_21625435
proc url_BatchGetCommits_21626076(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_BatchGetCommits_21626075(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns information about the contents of one or more commits in a repository.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626077 = header.getOrDefault("X-Amz-Date")
  valid_21626077 = validateParameter(valid_21626077, JString, required = false,
                                   default = nil)
  if valid_21626077 != nil:
    section.add "X-Amz-Date", valid_21626077
  var valid_21626078 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626078 = validateParameter(valid_21626078, JString, required = false,
                                   default = nil)
  if valid_21626078 != nil:
    section.add "X-Amz-Security-Token", valid_21626078
  var valid_21626079 = header.getOrDefault("X-Amz-Target")
  valid_21626079 = validateParameter(valid_21626079, JString, required = true, default = newJString(
      "CodeCommit_20150413.BatchGetCommits"))
  if valid_21626079 != nil:
    section.add "X-Amz-Target", valid_21626079
  var valid_21626080 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626080 = validateParameter(valid_21626080, JString, required = false,
                                   default = nil)
  if valid_21626080 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626080
  var valid_21626081 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626081 = validateParameter(valid_21626081, JString, required = false,
                                   default = nil)
  if valid_21626081 != nil:
    section.add "X-Amz-Algorithm", valid_21626081
  var valid_21626082 = header.getOrDefault("X-Amz-Signature")
  valid_21626082 = validateParameter(valid_21626082, JString, required = false,
                                   default = nil)
  if valid_21626082 != nil:
    section.add "X-Amz-Signature", valid_21626082
  var valid_21626083 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626083 = validateParameter(valid_21626083, JString, required = false,
                                   default = nil)
  if valid_21626083 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626083
  var valid_21626084 = header.getOrDefault("X-Amz-Credential")
  valid_21626084 = validateParameter(valid_21626084, JString, required = false,
                                   default = nil)
  if valid_21626084 != nil:
    section.add "X-Amz-Credential", valid_21626084
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626086: Call_BatchGetCommits_21626074; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns information about the contents of one or more commits in a repository.
  ## 
  let valid = call_21626086.validator(path, query, header, formData, body, _)
  let scheme = call_21626086.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626086.makeUrl(scheme.get, call_21626086.host, call_21626086.base,
                               call_21626086.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626086, uri, valid, _)

proc call*(call_21626087: Call_BatchGetCommits_21626074; body: JsonNode): Recallable =
  ## batchGetCommits
  ## Returns information about the contents of one or more commits in a repository.
  ##   body: JObject (required)
  var body_21626088 = newJObject()
  if body != nil:
    body_21626088 = body
  result = call_21626087.call(nil, nil, nil, nil, body_21626088)

var batchGetCommits* = Call_BatchGetCommits_21626074(name: "batchGetCommits",
    meth: HttpMethod.HttpPost, host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.BatchGetCommits",
    validator: validate_BatchGetCommits_21626075, base: "/",
    makeUrl: url_BatchGetCommits_21626076, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchGetRepositories_21626089 = ref object of OpenApiRestCall_21625435
proc url_BatchGetRepositories_21626091(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_BatchGetRepositories_21626090(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Returns information about one or more repositories.</p> <note> <p>The description field for a repository accepts all HTML characters and all valid Unicode characters. Applications that do not HTML-encode the description and display it in a webpage can expose users to potentially malicious code. Make sure that you HTML-encode the description field in any application that uses this API to display the repository description on a webpage.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626092 = header.getOrDefault("X-Amz-Date")
  valid_21626092 = validateParameter(valid_21626092, JString, required = false,
                                   default = nil)
  if valid_21626092 != nil:
    section.add "X-Amz-Date", valid_21626092
  var valid_21626093 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626093 = validateParameter(valid_21626093, JString, required = false,
                                   default = nil)
  if valid_21626093 != nil:
    section.add "X-Amz-Security-Token", valid_21626093
  var valid_21626094 = header.getOrDefault("X-Amz-Target")
  valid_21626094 = validateParameter(valid_21626094, JString, required = true, default = newJString(
      "CodeCommit_20150413.BatchGetRepositories"))
  if valid_21626094 != nil:
    section.add "X-Amz-Target", valid_21626094
  var valid_21626095 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626095 = validateParameter(valid_21626095, JString, required = false,
                                   default = nil)
  if valid_21626095 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626095
  var valid_21626096 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626096 = validateParameter(valid_21626096, JString, required = false,
                                   default = nil)
  if valid_21626096 != nil:
    section.add "X-Amz-Algorithm", valid_21626096
  var valid_21626097 = header.getOrDefault("X-Amz-Signature")
  valid_21626097 = validateParameter(valid_21626097, JString, required = false,
                                   default = nil)
  if valid_21626097 != nil:
    section.add "X-Amz-Signature", valid_21626097
  var valid_21626098 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626098 = validateParameter(valid_21626098, JString, required = false,
                                   default = nil)
  if valid_21626098 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626098
  var valid_21626099 = header.getOrDefault("X-Amz-Credential")
  valid_21626099 = validateParameter(valid_21626099, JString, required = false,
                                   default = nil)
  if valid_21626099 != nil:
    section.add "X-Amz-Credential", valid_21626099
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626101: Call_BatchGetRepositories_21626089; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns information about one or more repositories.</p> <note> <p>The description field for a repository accepts all HTML characters and all valid Unicode characters. Applications that do not HTML-encode the description and display it in a webpage can expose users to potentially malicious code. Make sure that you HTML-encode the description field in any application that uses this API to display the repository description on a webpage.</p> </note>
  ## 
  let valid = call_21626101.validator(path, query, header, formData, body, _)
  let scheme = call_21626101.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626101.makeUrl(scheme.get, call_21626101.host, call_21626101.base,
                               call_21626101.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626101, uri, valid, _)

proc call*(call_21626102: Call_BatchGetRepositories_21626089; body: JsonNode): Recallable =
  ## batchGetRepositories
  ## <p>Returns information about one or more repositories.</p> <note> <p>The description field for a repository accepts all HTML characters and all valid Unicode characters. Applications that do not HTML-encode the description and display it in a webpage can expose users to potentially malicious code. Make sure that you HTML-encode the description field in any application that uses this API to display the repository description on a webpage.</p> </note>
  ##   body: JObject (required)
  var body_21626103 = newJObject()
  if body != nil:
    body_21626103 = body
  result = call_21626102.call(nil, nil, nil, nil, body_21626103)

var batchGetRepositories* = Call_BatchGetRepositories_21626089(
    name: "batchGetRepositories", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.BatchGetRepositories",
    validator: validate_BatchGetRepositories_21626090, base: "/",
    makeUrl: url_BatchGetRepositories_21626091,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateApprovalRuleTemplate_21626104 = ref object of OpenApiRestCall_21625435
proc url_CreateApprovalRuleTemplate_21626106(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateApprovalRuleTemplate_21626105(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Creates a template for approval rules that can then be associated with one or more repositories in your AWS account. When you associate a template with a repository, AWS CodeCommit creates an approval rule that matches the conditions of the template for all pull requests that meet the conditions of the template. For more information, see <a>AssociateApprovalRuleTemplateWithRepository</a>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626107 = header.getOrDefault("X-Amz-Date")
  valid_21626107 = validateParameter(valid_21626107, JString, required = false,
                                   default = nil)
  if valid_21626107 != nil:
    section.add "X-Amz-Date", valid_21626107
  var valid_21626108 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626108 = validateParameter(valid_21626108, JString, required = false,
                                   default = nil)
  if valid_21626108 != nil:
    section.add "X-Amz-Security-Token", valid_21626108
  var valid_21626109 = header.getOrDefault("X-Amz-Target")
  valid_21626109 = validateParameter(valid_21626109, JString, required = true, default = newJString(
      "CodeCommit_20150413.CreateApprovalRuleTemplate"))
  if valid_21626109 != nil:
    section.add "X-Amz-Target", valid_21626109
  var valid_21626110 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626110 = validateParameter(valid_21626110, JString, required = false,
                                   default = nil)
  if valid_21626110 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626110
  var valid_21626111 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626111 = validateParameter(valid_21626111, JString, required = false,
                                   default = nil)
  if valid_21626111 != nil:
    section.add "X-Amz-Algorithm", valid_21626111
  var valid_21626112 = header.getOrDefault("X-Amz-Signature")
  valid_21626112 = validateParameter(valid_21626112, JString, required = false,
                                   default = nil)
  if valid_21626112 != nil:
    section.add "X-Amz-Signature", valid_21626112
  var valid_21626113 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626113 = validateParameter(valid_21626113, JString, required = false,
                                   default = nil)
  if valid_21626113 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626113
  var valid_21626114 = header.getOrDefault("X-Amz-Credential")
  valid_21626114 = validateParameter(valid_21626114, JString, required = false,
                                   default = nil)
  if valid_21626114 != nil:
    section.add "X-Amz-Credential", valid_21626114
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626116: Call_CreateApprovalRuleTemplate_21626104;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a template for approval rules that can then be associated with one or more repositories in your AWS account. When you associate a template with a repository, AWS CodeCommit creates an approval rule that matches the conditions of the template for all pull requests that meet the conditions of the template. For more information, see <a>AssociateApprovalRuleTemplateWithRepository</a>.
  ## 
  let valid = call_21626116.validator(path, query, header, formData, body, _)
  let scheme = call_21626116.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626116.makeUrl(scheme.get, call_21626116.host, call_21626116.base,
                               call_21626116.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626116, uri, valid, _)

proc call*(call_21626117: Call_CreateApprovalRuleTemplate_21626104; body: JsonNode): Recallable =
  ## createApprovalRuleTemplate
  ## Creates a template for approval rules that can then be associated with one or more repositories in your AWS account. When you associate a template with a repository, AWS CodeCommit creates an approval rule that matches the conditions of the template for all pull requests that meet the conditions of the template. For more information, see <a>AssociateApprovalRuleTemplateWithRepository</a>.
  ##   body: JObject (required)
  var body_21626118 = newJObject()
  if body != nil:
    body_21626118 = body
  result = call_21626117.call(nil, nil, nil, nil, body_21626118)

var createApprovalRuleTemplate* = Call_CreateApprovalRuleTemplate_21626104(
    name: "createApprovalRuleTemplate", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.CreateApprovalRuleTemplate",
    validator: validate_CreateApprovalRuleTemplate_21626105, base: "/",
    makeUrl: url_CreateApprovalRuleTemplate_21626106,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateBranch_21626119 = ref object of OpenApiRestCall_21625435
proc url_CreateBranch_21626121(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateBranch_21626120(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## <p>Creates a branch in a repository and points the branch to a commit.</p> <note> <p>Calling the create branch operation does not set a repository's default branch. To do this, call the update default branch operation.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626122 = header.getOrDefault("X-Amz-Date")
  valid_21626122 = validateParameter(valid_21626122, JString, required = false,
                                   default = nil)
  if valid_21626122 != nil:
    section.add "X-Amz-Date", valid_21626122
  var valid_21626123 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626123 = validateParameter(valid_21626123, JString, required = false,
                                   default = nil)
  if valid_21626123 != nil:
    section.add "X-Amz-Security-Token", valid_21626123
  var valid_21626124 = header.getOrDefault("X-Amz-Target")
  valid_21626124 = validateParameter(valid_21626124, JString, required = true, default = newJString(
      "CodeCommit_20150413.CreateBranch"))
  if valid_21626124 != nil:
    section.add "X-Amz-Target", valid_21626124
  var valid_21626125 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626125 = validateParameter(valid_21626125, JString, required = false,
                                   default = nil)
  if valid_21626125 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626125
  var valid_21626126 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626126 = validateParameter(valid_21626126, JString, required = false,
                                   default = nil)
  if valid_21626126 != nil:
    section.add "X-Amz-Algorithm", valid_21626126
  var valid_21626127 = header.getOrDefault("X-Amz-Signature")
  valid_21626127 = validateParameter(valid_21626127, JString, required = false,
                                   default = nil)
  if valid_21626127 != nil:
    section.add "X-Amz-Signature", valid_21626127
  var valid_21626128 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626128 = validateParameter(valid_21626128, JString, required = false,
                                   default = nil)
  if valid_21626128 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626128
  var valid_21626129 = header.getOrDefault("X-Amz-Credential")
  valid_21626129 = validateParameter(valid_21626129, JString, required = false,
                                   default = nil)
  if valid_21626129 != nil:
    section.add "X-Amz-Credential", valid_21626129
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626131: Call_CreateBranch_21626119; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates a branch in a repository and points the branch to a commit.</p> <note> <p>Calling the create branch operation does not set a repository's default branch. To do this, call the update default branch operation.</p> </note>
  ## 
  let valid = call_21626131.validator(path, query, header, formData, body, _)
  let scheme = call_21626131.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626131.makeUrl(scheme.get, call_21626131.host, call_21626131.base,
                               call_21626131.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626131, uri, valid, _)

proc call*(call_21626132: Call_CreateBranch_21626119; body: JsonNode): Recallable =
  ## createBranch
  ## <p>Creates a branch in a repository and points the branch to a commit.</p> <note> <p>Calling the create branch operation does not set a repository's default branch. To do this, call the update default branch operation.</p> </note>
  ##   body: JObject (required)
  var body_21626133 = newJObject()
  if body != nil:
    body_21626133 = body
  result = call_21626132.call(nil, nil, nil, nil, body_21626133)

var createBranch* = Call_CreateBranch_21626119(name: "createBranch",
    meth: HttpMethod.HttpPost, host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.CreateBranch",
    validator: validate_CreateBranch_21626120, base: "/", makeUrl: url_CreateBranch_21626121,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateCommit_21626134 = ref object of OpenApiRestCall_21625435
proc url_CreateCommit_21626136(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateCommit_21626135(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Creates a commit for a repository on the tip of a specified branch.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626137 = header.getOrDefault("X-Amz-Date")
  valid_21626137 = validateParameter(valid_21626137, JString, required = false,
                                   default = nil)
  if valid_21626137 != nil:
    section.add "X-Amz-Date", valid_21626137
  var valid_21626138 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626138 = validateParameter(valid_21626138, JString, required = false,
                                   default = nil)
  if valid_21626138 != nil:
    section.add "X-Amz-Security-Token", valid_21626138
  var valid_21626139 = header.getOrDefault("X-Amz-Target")
  valid_21626139 = validateParameter(valid_21626139, JString, required = true, default = newJString(
      "CodeCommit_20150413.CreateCommit"))
  if valid_21626139 != nil:
    section.add "X-Amz-Target", valid_21626139
  var valid_21626140 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626140 = validateParameter(valid_21626140, JString, required = false,
                                   default = nil)
  if valid_21626140 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626140
  var valid_21626141 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626141 = validateParameter(valid_21626141, JString, required = false,
                                   default = nil)
  if valid_21626141 != nil:
    section.add "X-Amz-Algorithm", valid_21626141
  var valid_21626142 = header.getOrDefault("X-Amz-Signature")
  valid_21626142 = validateParameter(valid_21626142, JString, required = false,
                                   default = nil)
  if valid_21626142 != nil:
    section.add "X-Amz-Signature", valid_21626142
  var valid_21626143 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626143 = validateParameter(valid_21626143, JString, required = false,
                                   default = nil)
  if valid_21626143 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626143
  var valid_21626144 = header.getOrDefault("X-Amz-Credential")
  valid_21626144 = validateParameter(valid_21626144, JString, required = false,
                                   default = nil)
  if valid_21626144 != nil:
    section.add "X-Amz-Credential", valid_21626144
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626146: Call_CreateCommit_21626134; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a commit for a repository on the tip of a specified branch.
  ## 
  let valid = call_21626146.validator(path, query, header, formData, body, _)
  let scheme = call_21626146.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626146.makeUrl(scheme.get, call_21626146.host, call_21626146.base,
                               call_21626146.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626146, uri, valid, _)

proc call*(call_21626147: Call_CreateCommit_21626134; body: JsonNode): Recallable =
  ## createCommit
  ## Creates a commit for a repository on the tip of a specified branch.
  ##   body: JObject (required)
  var body_21626148 = newJObject()
  if body != nil:
    body_21626148 = body
  result = call_21626147.call(nil, nil, nil, nil, body_21626148)

var createCommit* = Call_CreateCommit_21626134(name: "createCommit",
    meth: HttpMethod.HttpPost, host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.CreateCommit",
    validator: validate_CreateCommit_21626135, base: "/", makeUrl: url_CreateCommit_21626136,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePullRequest_21626149 = ref object of OpenApiRestCall_21625435
proc url_CreatePullRequest_21626151(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreatePullRequest_21626150(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Creates a pull request in the specified repository.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626152 = header.getOrDefault("X-Amz-Date")
  valid_21626152 = validateParameter(valid_21626152, JString, required = false,
                                   default = nil)
  if valid_21626152 != nil:
    section.add "X-Amz-Date", valid_21626152
  var valid_21626153 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626153 = validateParameter(valid_21626153, JString, required = false,
                                   default = nil)
  if valid_21626153 != nil:
    section.add "X-Amz-Security-Token", valid_21626153
  var valid_21626154 = header.getOrDefault("X-Amz-Target")
  valid_21626154 = validateParameter(valid_21626154, JString, required = true, default = newJString(
      "CodeCommit_20150413.CreatePullRequest"))
  if valid_21626154 != nil:
    section.add "X-Amz-Target", valid_21626154
  var valid_21626155 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626155 = validateParameter(valid_21626155, JString, required = false,
                                   default = nil)
  if valid_21626155 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626155
  var valid_21626156 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626156 = validateParameter(valid_21626156, JString, required = false,
                                   default = nil)
  if valid_21626156 != nil:
    section.add "X-Amz-Algorithm", valid_21626156
  var valid_21626157 = header.getOrDefault("X-Amz-Signature")
  valid_21626157 = validateParameter(valid_21626157, JString, required = false,
                                   default = nil)
  if valid_21626157 != nil:
    section.add "X-Amz-Signature", valid_21626157
  var valid_21626158 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626158 = validateParameter(valid_21626158, JString, required = false,
                                   default = nil)
  if valid_21626158 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626158
  var valid_21626159 = header.getOrDefault("X-Amz-Credential")
  valid_21626159 = validateParameter(valid_21626159, JString, required = false,
                                   default = nil)
  if valid_21626159 != nil:
    section.add "X-Amz-Credential", valid_21626159
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626161: Call_CreatePullRequest_21626149; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a pull request in the specified repository.
  ## 
  let valid = call_21626161.validator(path, query, header, formData, body, _)
  let scheme = call_21626161.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626161.makeUrl(scheme.get, call_21626161.host, call_21626161.base,
                               call_21626161.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626161, uri, valid, _)

proc call*(call_21626162: Call_CreatePullRequest_21626149; body: JsonNode): Recallable =
  ## createPullRequest
  ## Creates a pull request in the specified repository.
  ##   body: JObject (required)
  var body_21626163 = newJObject()
  if body != nil:
    body_21626163 = body
  result = call_21626162.call(nil, nil, nil, nil, body_21626163)

var createPullRequest* = Call_CreatePullRequest_21626149(name: "createPullRequest",
    meth: HttpMethod.HttpPost, host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.CreatePullRequest",
    validator: validate_CreatePullRequest_21626150, base: "/",
    makeUrl: url_CreatePullRequest_21626151, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePullRequestApprovalRule_21626164 = ref object of OpenApiRestCall_21625435
proc url_CreatePullRequestApprovalRule_21626166(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreatePullRequestApprovalRule_21626165(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Creates an approval rule for a pull request.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626167 = header.getOrDefault("X-Amz-Date")
  valid_21626167 = validateParameter(valid_21626167, JString, required = false,
                                   default = nil)
  if valid_21626167 != nil:
    section.add "X-Amz-Date", valid_21626167
  var valid_21626168 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626168 = validateParameter(valid_21626168, JString, required = false,
                                   default = nil)
  if valid_21626168 != nil:
    section.add "X-Amz-Security-Token", valid_21626168
  var valid_21626169 = header.getOrDefault("X-Amz-Target")
  valid_21626169 = validateParameter(valid_21626169, JString, required = true, default = newJString(
      "CodeCommit_20150413.CreatePullRequestApprovalRule"))
  if valid_21626169 != nil:
    section.add "X-Amz-Target", valid_21626169
  var valid_21626170 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626170 = validateParameter(valid_21626170, JString, required = false,
                                   default = nil)
  if valid_21626170 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626170
  var valid_21626171 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626171 = validateParameter(valid_21626171, JString, required = false,
                                   default = nil)
  if valid_21626171 != nil:
    section.add "X-Amz-Algorithm", valid_21626171
  var valid_21626172 = header.getOrDefault("X-Amz-Signature")
  valid_21626172 = validateParameter(valid_21626172, JString, required = false,
                                   default = nil)
  if valid_21626172 != nil:
    section.add "X-Amz-Signature", valid_21626172
  var valid_21626173 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626173 = validateParameter(valid_21626173, JString, required = false,
                                   default = nil)
  if valid_21626173 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626173
  var valid_21626174 = header.getOrDefault("X-Amz-Credential")
  valid_21626174 = validateParameter(valid_21626174, JString, required = false,
                                   default = nil)
  if valid_21626174 != nil:
    section.add "X-Amz-Credential", valid_21626174
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626176: Call_CreatePullRequestApprovalRule_21626164;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates an approval rule for a pull request.
  ## 
  let valid = call_21626176.validator(path, query, header, formData, body, _)
  let scheme = call_21626176.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626176.makeUrl(scheme.get, call_21626176.host, call_21626176.base,
                               call_21626176.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626176, uri, valid, _)

proc call*(call_21626177: Call_CreatePullRequestApprovalRule_21626164;
          body: JsonNode): Recallable =
  ## createPullRequestApprovalRule
  ## Creates an approval rule for a pull request.
  ##   body: JObject (required)
  var body_21626178 = newJObject()
  if body != nil:
    body_21626178 = body
  result = call_21626177.call(nil, nil, nil, nil, body_21626178)

var createPullRequestApprovalRule* = Call_CreatePullRequestApprovalRule_21626164(
    name: "createPullRequestApprovalRule", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.CreatePullRequestApprovalRule",
    validator: validate_CreatePullRequestApprovalRule_21626165, base: "/",
    makeUrl: url_CreatePullRequestApprovalRule_21626166,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateRepository_21626179 = ref object of OpenApiRestCall_21625435
proc url_CreateRepository_21626181(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateRepository_21626180(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Creates a new, empty repository.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626182 = header.getOrDefault("X-Amz-Date")
  valid_21626182 = validateParameter(valid_21626182, JString, required = false,
                                   default = nil)
  if valid_21626182 != nil:
    section.add "X-Amz-Date", valid_21626182
  var valid_21626183 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626183 = validateParameter(valid_21626183, JString, required = false,
                                   default = nil)
  if valid_21626183 != nil:
    section.add "X-Amz-Security-Token", valid_21626183
  var valid_21626184 = header.getOrDefault("X-Amz-Target")
  valid_21626184 = validateParameter(valid_21626184, JString, required = true, default = newJString(
      "CodeCommit_20150413.CreateRepository"))
  if valid_21626184 != nil:
    section.add "X-Amz-Target", valid_21626184
  var valid_21626185 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626185 = validateParameter(valid_21626185, JString, required = false,
                                   default = nil)
  if valid_21626185 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626185
  var valid_21626186 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626186 = validateParameter(valid_21626186, JString, required = false,
                                   default = nil)
  if valid_21626186 != nil:
    section.add "X-Amz-Algorithm", valid_21626186
  var valid_21626187 = header.getOrDefault("X-Amz-Signature")
  valid_21626187 = validateParameter(valid_21626187, JString, required = false,
                                   default = nil)
  if valid_21626187 != nil:
    section.add "X-Amz-Signature", valid_21626187
  var valid_21626188 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626188 = validateParameter(valid_21626188, JString, required = false,
                                   default = nil)
  if valid_21626188 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626188
  var valid_21626189 = header.getOrDefault("X-Amz-Credential")
  valid_21626189 = validateParameter(valid_21626189, JString, required = false,
                                   default = nil)
  if valid_21626189 != nil:
    section.add "X-Amz-Credential", valid_21626189
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626191: Call_CreateRepository_21626179; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a new, empty repository.
  ## 
  let valid = call_21626191.validator(path, query, header, formData, body, _)
  let scheme = call_21626191.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626191.makeUrl(scheme.get, call_21626191.host, call_21626191.base,
                               call_21626191.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626191, uri, valid, _)

proc call*(call_21626192: Call_CreateRepository_21626179; body: JsonNode): Recallable =
  ## createRepository
  ## Creates a new, empty repository.
  ##   body: JObject (required)
  var body_21626193 = newJObject()
  if body != nil:
    body_21626193 = body
  result = call_21626192.call(nil, nil, nil, nil, body_21626193)

var createRepository* = Call_CreateRepository_21626179(name: "createRepository",
    meth: HttpMethod.HttpPost, host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.CreateRepository",
    validator: validate_CreateRepository_21626180, base: "/",
    makeUrl: url_CreateRepository_21626181, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateUnreferencedMergeCommit_21626194 = ref object of OpenApiRestCall_21625435
proc url_CreateUnreferencedMergeCommit_21626196(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateUnreferencedMergeCommit_21626195(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## <p>Creates an unreferenced commit that represents the result of merging two branches using a specified merge strategy. This can help you determine the outcome of a potential merge. This API cannot be used with the fast-forward merge strategy because that strategy does not create a merge commit.</p> <note> <p>This unreferenced merge commit can only be accessed using the GetCommit API or through git commands such as git fetch. To retrieve this commit, you must specify its commit ID or otherwise reference it.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626197 = header.getOrDefault("X-Amz-Date")
  valid_21626197 = validateParameter(valid_21626197, JString, required = false,
                                   default = nil)
  if valid_21626197 != nil:
    section.add "X-Amz-Date", valid_21626197
  var valid_21626198 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626198 = validateParameter(valid_21626198, JString, required = false,
                                   default = nil)
  if valid_21626198 != nil:
    section.add "X-Amz-Security-Token", valid_21626198
  var valid_21626199 = header.getOrDefault("X-Amz-Target")
  valid_21626199 = validateParameter(valid_21626199, JString, required = true, default = newJString(
      "CodeCommit_20150413.CreateUnreferencedMergeCommit"))
  if valid_21626199 != nil:
    section.add "X-Amz-Target", valid_21626199
  var valid_21626200 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626200 = validateParameter(valid_21626200, JString, required = false,
                                   default = nil)
  if valid_21626200 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626200
  var valid_21626201 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626201 = validateParameter(valid_21626201, JString, required = false,
                                   default = nil)
  if valid_21626201 != nil:
    section.add "X-Amz-Algorithm", valid_21626201
  var valid_21626202 = header.getOrDefault("X-Amz-Signature")
  valid_21626202 = validateParameter(valid_21626202, JString, required = false,
                                   default = nil)
  if valid_21626202 != nil:
    section.add "X-Amz-Signature", valid_21626202
  var valid_21626203 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626203 = validateParameter(valid_21626203, JString, required = false,
                                   default = nil)
  if valid_21626203 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626203
  var valid_21626204 = header.getOrDefault("X-Amz-Credential")
  valid_21626204 = validateParameter(valid_21626204, JString, required = false,
                                   default = nil)
  if valid_21626204 != nil:
    section.add "X-Amz-Credential", valid_21626204
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626206: Call_CreateUnreferencedMergeCommit_21626194;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates an unreferenced commit that represents the result of merging two branches using a specified merge strategy. This can help you determine the outcome of a potential merge. This API cannot be used with the fast-forward merge strategy because that strategy does not create a merge commit.</p> <note> <p>This unreferenced merge commit can only be accessed using the GetCommit API or through git commands such as git fetch. To retrieve this commit, you must specify its commit ID or otherwise reference it.</p> </note>
  ## 
  let valid = call_21626206.validator(path, query, header, formData, body, _)
  let scheme = call_21626206.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626206.makeUrl(scheme.get, call_21626206.host, call_21626206.base,
                               call_21626206.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626206, uri, valid, _)

proc call*(call_21626207: Call_CreateUnreferencedMergeCommit_21626194;
          body: JsonNode): Recallable =
  ## createUnreferencedMergeCommit
  ## <p>Creates an unreferenced commit that represents the result of merging two branches using a specified merge strategy. This can help you determine the outcome of a potential merge. This API cannot be used with the fast-forward merge strategy because that strategy does not create a merge commit.</p> <note> <p>This unreferenced merge commit can only be accessed using the GetCommit API or through git commands such as git fetch. To retrieve this commit, you must specify its commit ID or otherwise reference it.</p> </note>
  ##   body: JObject (required)
  var body_21626208 = newJObject()
  if body != nil:
    body_21626208 = body
  result = call_21626207.call(nil, nil, nil, nil, body_21626208)

var createUnreferencedMergeCommit* = Call_CreateUnreferencedMergeCommit_21626194(
    name: "createUnreferencedMergeCommit", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.CreateUnreferencedMergeCommit",
    validator: validate_CreateUnreferencedMergeCommit_21626195, base: "/",
    makeUrl: url_CreateUnreferencedMergeCommit_21626196,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteApprovalRuleTemplate_21626209 = ref object of OpenApiRestCall_21625435
proc url_DeleteApprovalRuleTemplate_21626211(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteApprovalRuleTemplate_21626210(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes a specified approval rule template. Deleting a template does not remove approval rules on pull requests already created with the template.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626212 = header.getOrDefault("X-Amz-Date")
  valid_21626212 = validateParameter(valid_21626212, JString, required = false,
                                   default = nil)
  if valid_21626212 != nil:
    section.add "X-Amz-Date", valid_21626212
  var valid_21626213 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626213 = validateParameter(valid_21626213, JString, required = false,
                                   default = nil)
  if valid_21626213 != nil:
    section.add "X-Amz-Security-Token", valid_21626213
  var valid_21626214 = header.getOrDefault("X-Amz-Target")
  valid_21626214 = validateParameter(valid_21626214, JString, required = true, default = newJString(
      "CodeCommit_20150413.DeleteApprovalRuleTemplate"))
  if valid_21626214 != nil:
    section.add "X-Amz-Target", valid_21626214
  var valid_21626215 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626215 = validateParameter(valid_21626215, JString, required = false,
                                   default = nil)
  if valid_21626215 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626215
  var valid_21626216 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626216 = validateParameter(valid_21626216, JString, required = false,
                                   default = nil)
  if valid_21626216 != nil:
    section.add "X-Amz-Algorithm", valid_21626216
  var valid_21626217 = header.getOrDefault("X-Amz-Signature")
  valid_21626217 = validateParameter(valid_21626217, JString, required = false,
                                   default = nil)
  if valid_21626217 != nil:
    section.add "X-Amz-Signature", valid_21626217
  var valid_21626218 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626218 = validateParameter(valid_21626218, JString, required = false,
                                   default = nil)
  if valid_21626218 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626218
  var valid_21626219 = header.getOrDefault("X-Amz-Credential")
  valid_21626219 = validateParameter(valid_21626219, JString, required = false,
                                   default = nil)
  if valid_21626219 != nil:
    section.add "X-Amz-Credential", valid_21626219
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626221: Call_DeleteApprovalRuleTemplate_21626209;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a specified approval rule template. Deleting a template does not remove approval rules on pull requests already created with the template.
  ## 
  let valid = call_21626221.validator(path, query, header, formData, body, _)
  let scheme = call_21626221.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626221.makeUrl(scheme.get, call_21626221.host, call_21626221.base,
                               call_21626221.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626221, uri, valid, _)

proc call*(call_21626222: Call_DeleteApprovalRuleTemplate_21626209; body: JsonNode): Recallable =
  ## deleteApprovalRuleTemplate
  ## Deletes a specified approval rule template. Deleting a template does not remove approval rules on pull requests already created with the template.
  ##   body: JObject (required)
  var body_21626223 = newJObject()
  if body != nil:
    body_21626223 = body
  result = call_21626222.call(nil, nil, nil, nil, body_21626223)

var deleteApprovalRuleTemplate* = Call_DeleteApprovalRuleTemplate_21626209(
    name: "deleteApprovalRuleTemplate", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.DeleteApprovalRuleTemplate",
    validator: validate_DeleteApprovalRuleTemplate_21626210, base: "/",
    makeUrl: url_DeleteApprovalRuleTemplate_21626211,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBranch_21626224 = ref object of OpenApiRestCall_21625435
proc url_DeleteBranch_21626226(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteBranch_21626225(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Deletes a branch from a repository, unless that branch is the default branch for the repository. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626227 = header.getOrDefault("X-Amz-Date")
  valid_21626227 = validateParameter(valid_21626227, JString, required = false,
                                   default = nil)
  if valid_21626227 != nil:
    section.add "X-Amz-Date", valid_21626227
  var valid_21626228 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626228 = validateParameter(valid_21626228, JString, required = false,
                                   default = nil)
  if valid_21626228 != nil:
    section.add "X-Amz-Security-Token", valid_21626228
  var valid_21626229 = header.getOrDefault("X-Amz-Target")
  valid_21626229 = validateParameter(valid_21626229, JString, required = true, default = newJString(
      "CodeCommit_20150413.DeleteBranch"))
  if valid_21626229 != nil:
    section.add "X-Amz-Target", valid_21626229
  var valid_21626230 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626230 = validateParameter(valid_21626230, JString, required = false,
                                   default = nil)
  if valid_21626230 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626230
  var valid_21626231 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626231 = validateParameter(valid_21626231, JString, required = false,
                                   default = nil)
  if valid_21626231 != nil:
    section.add "X-Amz-Algorithm", valid_21626231
  var valid_21626232 = header.getOrDefault("X-Amz-Signature")
  valid_21626232 = validateParameter(valid_21626232, JString, required = false,
                                   default = nil)
  if valid_21626232 != nil:
    section.add "X-Amz-Signature", valid_21626232
  var valid_21626233 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626233 = validateParameter(valid_21626233, JString, required = false,
                                   default = nil)
  if valid_21626233 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626233
  var valid_21626234 = header.getOrDefault("X-Amz-Credential")
  valid_21626234 = validateParameter(valid_21626234, JString, required = false,
                                   default = nil)
  if valid_21626234 != nil:
    section.add "X-Amz-Credential", valid_21626234
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626236: Call_DeleteBranch_21626224; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a branch from a repository, unless that branch is the default branch for the repository. 
  ## 
  let valid = call_21626236.validator(path, query, header, formData, body, _)
  let scheme = call_21626236.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626236.makeUrl(scheme.get, call_21626236.host, call_21626236.base,
                               call_21626236.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626236, uri, valid, _)

proc call*(call_21626237: Call_DeleteBranch_21626224; body: JsonNode): Recallable =
  ## deleteBranch
  ## Deletes a branch from a repository, unless that branch is the default branch for the repository. 
  ##   body: JObject (required)
  var body_21626238 = newJObject()
  if body != nil:
    body_21626238 = body
  result = call_21626237.call(nil, nil, nil, nil, body_21626238)

var deleteBranch* = Call_DeleteBranch_21626224(name: "deleteBranch",
    meth: HttpMethod.HttpPost, host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.DeleteBranch",
    validator: validate_DeleteBranch_21626225, base: "/", makeUrl: url_DeleteBranch_21626226,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteCommentContent_21626239 = ref object of OpenApiRestCall_21625435
proc url_DeleteCommentContent_21626241(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteCommentContent_21626240(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes the content of a comment made on a change, file, or commit in a repository.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626242 = header.getOrDefault("X-Amz-Date")
  valid_21626242 = validateParameter(valid_21626242, JString, required = false,
                                   default = nil)
  if valid_21626242 != nil:
    section.add "X-Amz-Date", valid_21626242
  var valid_21626243 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626243 = validateParameter(valid_21626243, JString, required = false,
                                   default = nil)
  if valid_21626243 != nil:
    section.add "X-Amz-Security-Token", valid_21626243
  var valid_21626244 = header.getOrDefault("X-Amz-Target")
  valid_21626244 = validateParameter(valid_21626244, JString, required = true, default = newJString(
      "CodeCommit_20150413.DeleteCommentContent"))
  if valid_21626244 != nil:
    section.add "X-Amz-Target", valid_21626244
  var valid_21626245 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626245 = validateParameter(valid_21626245, JString, required = false,
                                   default = nil)
  if valid_21626245 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626245
  var valid_21626246 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626246 = validateParameter(valid_21626246, JString, required = false,
                                   default = nil)
  if valid_21626246 != nil:
    section.add "X-Amz-Algorithm", valid_21626246
  var valid_21626247 = header.getOrDefault("X-Amz-Signature")
  valid_21626247 = validateParameter(valid_21626247, JString, required = false,
                                   default = nil)
  if valid_21626247 != nil:
    section.add "X-Amz-Signature", valid_21626247
  var valid_21626248 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626248 = validateParameter(valid_21626248, JString, required = false,
                                   default = nil)
  if valid_21626248 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626248
  var valid_21626249 = header.getOrDefault("X-Amz-Credential")
  valid_21626249 = validateParameter(valid_21626249, JString, required = false,
                                   default = nil)
  if valid_21626249 != nil:
    section.add "X-Amz-Credential", valid_21626249
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626251: Call_DeleteCommentContent_21626239; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes the content of a comment made on a change, file, or commit in a repository.
  ## 
  let valid = call_21626251.validator(path, query, header, formData, body, _)
  let scheme = call_21626251.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626251.makeUrl(scheme.get, call_21626251.host, call_21626251.base,
                               call_21626251.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626251, uri, valid, _)

proc call*(call_21626252: Call_DeleteCommentContent_21626239; body: JsonNode): Recallable =
  ## deleteCommentContent
  ## Deletes the content of a comment made on a change, file, or commit in a repository.
  ##   body: JObject (required)
  var body_21626253 = newJObject()
  if body != nil:
    body_21626253 = body
  result = call_21626252.call(nil, nil, nil, nil, body_21626253)

var deleteCommentContent* = Call_DeleteCommentContent_21626239(
    name: "deleteCommentContent", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.DeleteCommentContent",
    validator: validate_DeleteCommentContent_21626240, base: "/",
    makeUrl: url_DeleteCommentContent_21626241,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteFile_21626254 = ref object of OpenApiRestCall_21625435
proc url_DeleteFile_21626256(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteFile_21626255(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes a specified file from a specified branch. A commit is created on the branch that contains the revision. The file still exists in the commits earlier to the commit that contains the deletion.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626257 = header.getOrDefault("X-Amz-Date")
  valid_21626257 = validateParameter(valid_21626257, JString, required = false,
                                   default = nil)
  if valid_21626257 != nil:
    section.add "X-Amz-Date", valid_21626257
  var valid_21626258 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626258 = validateParameter(valid_21626258, JString, required = false,
                                   default = nil)
  if valid_21626258 != nil:
    section.add "X-Amz-Security-Token", valid_21626258
  var valid_21626259 = header.getOrDefault("X-Amz-Target")
  valid_21626259 = validateParameter(valid_21626259, JString, required = true, default = newJString(
      "CodeCommit_20150413.DeleteFile"))
  if valid_21626259 != nil:
    section.add "X-Amz-Target", valid_21626259
  var valid_21626260 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626260 = validateParameter(valid_21626260, JString, required = false,
                                   default = nil)
  if valid_21626260 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626260
  var valid_21626261 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626261 = validateParameter(valid_21626261, JString, required = false,
                                   default = nil)
  if valid_21626261 != nil:
    section.add "X-Amz-Algorithm", valid_21626261
  var valid_21626262 = header.getOrDefault("X-Amz-Signature")
  valid_21626262 = validateParameter(valid_21626262, JString, required = false,
                                   default = nil)
  if valid_21626262 != nil:
    section.add "X-Amz-Signature", valid_21626262
  var valid_21626263 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626263 = validateParameter(valid_21626263, JString, required = false,
                                   default = nil)
  if valid_21626263 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626263
  var valid_21626264 = header.getOrDefault("X-Amz-Credential")
  valid_21626264 = validateParameter(valid_21626264, JString, required = false,
                                   default = nil)
  if valid_21626264 != nil:
    section.add "X-Amz-Credential", valid_21626264
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626266: Call_DeleteFile_21626254; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a specified file from a specified branch. A commit is created on the branch that contains the revision. The file still exists in the commits earlier to the commit that contains the deletion.
  ## 
  let valid = call_21626266.validator(path, query, header, formData, body, _)
  let scheme = call_21626266.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626266.makeUrl(scheme.get, call_21626266.host, call_21626266.base,
                               call_21626266.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626266, uri, valid, _)

proc call*(call_21626267: Call_DeleteFile_21626254; body: JsonNode): Recallable =
  ## deleteFile
  ## Deletes a specified file from a specified branch. A commit is created on the branch that contains the revision. The file still exists in the commits earlier to the commit that contains the deletion.
  ##   body: JObject (required)
  var body_21626268 = newJObject()
  if body != nil:
    body_21626268 = body
  result = call_21626267.call(nil, nil, nil, nil, body_21626268)

var deleteFile* = Call_DeleteFile_21626254(name: "deleteFile",
                                        meth: HttpMethod.HttpPost,
                                        host: "codecommit.amazonaws.com", route: "/#X-Amz-Target=CodeCommit_20150413.DeleteFile",
                                        validator: validate_DeleteFile_21626255,
                                        base: "/", makeUrl: url_DeleteFile_21626256,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeletePullRequestApprovalRule_21626269 = ref object of OpenApiRestCall_21625435
proc url_DeletePullRequestApprovalRule_21626271(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeletePullRequestApprovalRule_21626270(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Deletes an approval rule from a specified pull request. Approval rules can be deleted from a pull request only if the pull request is open, and if the approval rule was created specifically for a pull request and not generated from an approval rule template associated with the repository where the pull request was created. You cannot delete an approval rule from a merged or closed pull request.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626272 = header.getOrDefault("X-Amz-Date")
  valid_21626272 = validateParameter(valid_21626272, JString, required = false,
                                   default = nil)
  if valid_21626272 != nil:
    section.add "X-Amz-Date", valid_21626272
  var valid_21626273 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626273 = validateParameter(valid_21626273, JString, required = false,
                                   default = nil)
  if valid_21626273 != nil:
    section.add "X-Amz-Security-Token", valid_21626273
  var valid_21626274 = header.getOrDefault("X-Amz-Target")
  valid_21626274 = validateParameter(valid_21626274, JString, required = true, default = newJString(
      "CodeCommit_20150413.DeletePullRequestApprovalRule"))
  if valid_21626274 != nil:
    section.add "X-Amz-Target", valid_21626274
  var valid_21626275 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626275 = validateParameter(valid_21626275, JString, required = false,
                                   default = nil)
  if valid_21626275 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626275
  var valid_21626276 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626276 = validateParameter(valid_21626276, JString, required = false,
                                   default = nil)
  if valid_21626276 != nil:
    section.add "X-Amz-Algorithm", valid_21626276
  var valid_21626277 = header.getOrDefault("X-Amz-Signature")
  valid_21626277 = validateParameter(valid_21626277, JString, required = false,
                                   default = nil)
  if valid_21626277 != nil:
    section.add "X-Amz-Signature", valid_21626277
  var valid_21626278 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626278 = validateParameter(valid_21626278, JString, required = false,
                                   default = nil)
  if valid_21626278 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626278
  var valid_21626279 = header.getOrDefault("X-Amz-Credential")
  valid_21626279 = validateParameter(valid_21626279, JString, required = false,
                                   default = nil)
  if valid_21626279 != nil:
    section.add "X-Amz-Credential", valid_21626279
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626281: Call_DeletePullRequestApprovalRule_21626269;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes an approval rule from a specified pull request. Approval rules can be deleted from a pull request only if the pull request is open, and if the approval rule was created specifically for a pull request and not generated from an approval rule template associated with the repository where the pull request was created. You cannot delete an approval rule from a merged or closed pull request.
  ## 
  let valid = call_21626281.validator(path, query, header, formData, body, _)
  let scheme = call_21626281.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626281.makeUrl(scheme.get, call_21626281.host, call_21626281.base,
                               call_21626281.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626281, uri, valid, _)

proc call*(call_21626282: Call_DeletePullRequestApprovalRule_21626269;
          body: JsonNode): Recallable =
  ## deletePullRequestApprovalRule
  ## Deletes an approval rule from a specified pull request. Approval rules can be deleted from a pull request only if the pull request is open, and if the approval rule was created specifically for a pull request and not generated from an approval rule template associated with the repository where the pull request was created. You cannot delete an approval rule from a merged or closed pull request.
  ##   body: JObject (required)
  var body_21626283 = newJObject()
  if body != nil:
    body_21626283 = body
  result = call_21626282.call(nil, nil, nil, nil, body_21626283)

var deletePullRequestApprovalRule* = Call_DeletePullRequestApprovalRule_21626269(
    name: "deletePullRequestApprovalRule", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.DeletePullRequestApprovalRule",
    validator: validate_DeletePullRequestApprovalRule_21626270, base: "/",
    makeUrl: url_DeletePullRequestApprovalRule_21626271,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRepository_21626284 = ref object of OpenApiRestCall_21625435
proc url_DeleteRepository_21626286(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteRepository_21626285(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Deletes a repository. If a specified repository was already deleted, a null repository ID is returned.</p> <important> <p>Deleting a repository also deletes all associated objects and metadata. After a repository is deleted, all future push calls to the deleted repository fail.</p> </important>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626287 = header.getOrDefault("X-Amz-Date")
  valid_21626287 = validateParameter(valid_21626287, JString, required = false,
                                   default = nil)
  if valid_21626287 != nil:
    section.add "X-Amz-Date", valid_21626287
  var valid_21626288 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626288 = validateParameter(valid_21626288, JString, required = false,
                                   default = nil)
  if valid_21626288 != nil:
    section.add "X-Amz-Security-Token", valid_21626288
  var valid_21626289 = header.getOrDefault("X-Amz-Target")
  valid_21626289 = validateParameter(valid_21626289, JString, required = true, default = newJString(
      "CodeCommit_20150413.DeleteRepository"))
  if valid_21626289 != nil:
    section.add "X-Amz-Target", valid_21626289
  var valid_21626290 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626290 = validateParameter(valid_21626290, JString, required = false,
                                   default = nil)
  if valid_21626290 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626290
  var valid_21626291 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626291 = validateParameter(valid_21626291, JString, required = false,
                                   default = nil)
  if valid_21626291 != nil:
    section.add "X-Amz-Algorithm", valid_21626291
  var valid_21626292 = header.getOrDefault("X-Amz-Signature")
  valid_21626292 = validateParameter(valid_21626292, JString, required = false,
                                   default = nil)
  if valid_21626292 != nil:
    section.add "X-Amz-Signature", valid_21626292
  var valid_21626293 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626293 = validateParameter(valid_21626293, JString, required = false,
                                   default = nil)
  if valid_21626293 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626293
  var valid_21626294 = header.getOrDefault("X-Amz-Credential")
  valid_21626294 = validateParameter(valid_21626294, JString, required = false,
                                   default = nil)
  if valid_21626294 != nil:
    section.add "X-Amz-Credential", valid_21626294
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626296: Call_DeleteRepository_21626284; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deletes a repository. If a specified repository was already deleted, a null repository ID is returned.</p> <important> <p>Deleting a repository also deletes all associated objects and metadata. After a repository is deleted, all future push calls to the deleted repository fail.</p> </important>
  ## 
  let valid = call_21626296.validator(path, query, header, formData, body, _)
  let scheme = call_21626296.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626296.makeUrl(scheme.get, call_21626296.host, call_21626296.base,
                               call_21626296.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626296, uri, valid, _)

proc call*(call_21626297: Call_DeleteRepository_21626284; body: JsonNode): Recallable =
  ## deleteRepository
  ## <p>Deletes a repository. If a specified repository was already deleted, a null repository ID is returned.</p> <important> <p>Deleting a repository also deletes all associated objects and metadata. After a repository is deleted, all future push calls to the deleted repository fail.</p> </important>
  ##   body: JObject (required)
  var body_21626298 = newJObject()
  if body != nil:
    body_21626298 = body
  result = call_21626297.call(nil, nil, nil, nil, body_21626298)

var deleteRepository* = Call_DeleteRepository_21626284(name: "deleteRepository",
    meth: HttpMethod.HttpPost, host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.DeleteRepository",
    validator: validate_DeleteRepository_21626285, base: "/",
    makeUrl: url_DeleteRepository_21626286, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeMergeConflicts_21626299 = ref object of OpenApiRestCall_21625435
proc url_DescribeMergeConflicts_21626301(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeMergeConflicts_21626300(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns information about one or more merge conflicts in the attempted merge of two commit specifiers using the squash or three-way merge strategy. If the merge option for the attempted merge is specified as FAST_FORWARD_MERGE, an exception is thrown.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxMergeHunks: JString
  ##                : Pagination limit
  ##   nextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_21626302 = query.getOrDefault("maxMergeHunks")
  valid_21626302 = validateParameter(valid_21626302, JString, required = false,
                                   default = nil)
  if valid_21626302 != nil:
    section.add "maxMergeHunks", valid_21626302
  var valid_21626303 = query.getOrDefault("nextToken")
  valid_21626303 = validateParameter(valid_21626303, JString, required = false,
                                   default = nil)
  if valid_21626303 != nil:
    section.add "nextToken", valid_21626303
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626304 = header.getOrDefault("X-Amz-Date")
  valid_21626304 = validateParameter(valid_21626304, JString, required = false,
                                   default = nil)
  if valid_21626304 != nil:
    section.add "X-Amz-Date", valid_21626304
  var valid_21626305 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626305 = validateParameter(valid_21626305, JString, required = false,
                                   default = nil)
  if valid_21626305 != nil:
    section.add "X-Amz-Security-Token", valid_21626305
  var valid_21626306 = header.getOrDefault("X-Amz-Target")
  valid_21626306 = validateParameter(valid_21626306, JString, required = true, default = newJString(
      "CodeCommit_20150413.DescribeMergeConflicts"))
  if valid_21626306 != nil:
    section.add "X-Amz-Target", valid_21626306
  var valid_21626307 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626307 = validateParameter(valid_21626307, JString, required = false,
                                   default = nil)
  if valid_21626307 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626307
  var valid_21626308 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626308 = validateParameter(valid_21626308, JString, required = false,
                                   default = nil)
  if valid_21626308 != nil:
    section.add "X-Amz-Algorithm", valid_21626308
  var valid_21626309 = header.getOrDefault("X-Amz-Signature")
  valid_21626309 = validateParameter(valid_21626309, JString, required = false,
                                   default = nil)
  if valid_21626309 != nil:
    section.add "X-Amz-Signature", valid_21626309
  var valid_21626310 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626310 = validateParameter(valid_21626310, JString, required = false,
                                   default = nil)
  if valid_21626310 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626310
  var valid_21626311 = header.getOrDefault("X-Amz-Credential")
  valid_21626311 = validateParameter(valid_21626311, JString, required = false,
                                   default = nil)
  if valid_21626311 != nil:
    section.add "X-Amz-Credential", valid_21626311
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626313: Call_DescribeMergeConflicts_21626299;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns information about one or more merge conflicts in the attempted merge of two commit specifiers using the squash or three-way merge strategy. If the merge option for the attempted merge is specified as FAST_FORWARD_MERGE, an exception is thrown.
  ## 
  let valid = call_21626313.validator(path, query, header, formData, body, _)
  let scheme = call_21626313.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626313.makeUrl(scheme.get, call_21626313.host, call_21626313.base,
                               call_21626313.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626313, uri, valid, _)

proc call*(call_21626314: Call_DescribeMergeConflicts_21626299; body: JsonNode;
          maxMergeHunks: string = ""; nextToken: string = ""): Recallable =
  ## describeMergeConflicts
  ## Returns information about one or more merge conflicts in the attempted merge of two commit specifiers using the squash or three-way merge strategy. If the merge option for the attempted merge is specified as FAST_FORWARD_MERGE, an exception is thrown.
  ##   maxMergeHunks: string
  ##                : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_21626316 = newJObject()
  var body_21626317 = newJObject()
  add(query_21626316, "maxMergeHunks", newJString(maxMergeHunks))
  add(query_21626316, "nextToken", newJString(nextToken))
  if body != nil:
    body_21626317 = body
  result = call_21626314.call(nil, query_21626316, nil, nil, body_21626317)

var describeMergeConflicts* = Call_DescribeMergeConflicts_21626299(
    name: "describeMergeConflicts", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.DescribeMergeConflicts",
    validator: validate_DescribeMergeConflicts_21626300, base: "/",
    makeUrl: url_DescribeMergeConflicts_21626301,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribePullRequestEvents_21626321 = ref object of OpenApiRestCall_21625435
proc url_DescribePullRequestEvents_21626323(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribePullRequestEvents_21626322(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns information about one or more pull request events.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JString
  ##             : Pagination limit
  ##   nextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_21626324 = query.getOrDefault("maxResults")
  valid_21626324 = validateParameter(valid_21626324, JString, required = false,
                                   default = nil)
  if valid_21626324 != nil:
    section.add "maxResults", valid_21626324
  var valid_21626325 = query.getOrDefault("nextToken")
  valid_21626325 = validateParameter(valid_21626325, JString, required = false,
                                   default = nil)
  if valid_21626325 != nil:
    section.add "nextToken", valid_21626325
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626326 = header.getOrDefault("X-Amz-Date")
  valid_21626326 = validateParameter(valid_21626326, JString, required = false,
                                   default = nil)
  if valid_21626326 != nil:
    section.add "X-Amz-Date", valid_21626326
  var valid_21626327 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626327 = validateParameter(valid_21626327, JString, required = false,
                                   default = nil)
  if valid_21626327 != nil:
    section.add "X-Amz-Security-Token", valid_21626327
  var valid_21626328 = header.getOrDefault("X-Amz-Target")
  valid_21626328 = validateParameter(valid_21626328, JString, required = true, default = newJString(
      "CodeCommit_20150413.DescribePullRequestEvents"))
  if valid_21626328 != nil:
    section.add "X-Amz-Target", valid_21626328
  var valid_21626329 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626329 = validateParameter(valid_21626329, JString, required = false,
                                   default = nil)
  if valid_21626329 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626329
  var valid_21626330 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626330 = validateParameter(valid_21626330, JString, required = false,
                                   default = nil)
  if valid_21626330 != nil:
    section.add "X-Amz-Algorithm", valid_21626330
  var valid_21626331 = header.getOrDefault("X-Amz-Signature")
  valid_21626331 = validateParameter(valid_21626331, JString, required = false,
                                   default = nil)
  if valid_21626331 != nil:
    section.add "X-Amz-Signature", valid_21626331
  var valid_21626332 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626332 = validateParameter(valid_21626332, JString, required = false,
                                   default = nil)
  if valid_21626332 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626332
  var valid_21626333 = header.getOrDefault("X-Amz-Credential")
  valid_21626333 = validateParameter(valid_21626333, JString, required = false,
                                   default = nil)
  if valid_21626333 != nil:
    section.add "X-Amz-Credential", valid_21626333
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626335: Call_DescribePullRequestEvents_21626321;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns information about one or more pull request events.
  ## 
  let valid = call_21626335.validator(path, query, header, formData, body, _)
  let scheme = call_21626335.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626335.makeUrl(scheme.get, call_21626335.host, call_21626335.base,
                               call_21626335.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626335, uri, valid, _)

proc call*(call_21626336: Call_DescribePullRequestEvents_21626321; body: JsonNode;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## describePullRequestEvents
  ## Returns information about one or more pull request events.
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_21626337 = newJObject()
  var body_21626338 = newJObject()
  add(query_21626337, "maxResults", newJString(maxResults))
  add(query_21626337, "nextToken", newJString(nextToken))
  if body != nil:
    body_21626338 = body
  result = call_21626336.call(nil, query_21626337, nil, nil, body_21626338)

var describePullRequestEvents* = Call_DescribePullRequestEvents_21626321(
    name: "describePullRequestEvents", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.DescribePullRequestEvents",
    validator: validate_DescribePullRequestEvents_21626322, base: "/",
    makeUrl: url_DescribePullRequestEvents_21626323,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateApprovalRuleTemplateFromRepository_21626339 = ref object of OpenApiRestCall_21625435
proc url_DisassociateApprovalRuleTemplateFromRepository_21626341(
    protocol: Scheme; host: string; base: string; route: string; path: JsonNode;
    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DisassociateApprovalRuleTemplateFromRepository_21626340(
    path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Removes the association between a template and a repository so that approval rules based on the template are not automatically created when pull requests are created in the specified repository. This does not delete any approval rules previously created for pull requests through the template association.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626342 = header.getOrDefault("X-Amz-Date")
  valid_21626342 = validateParameter(valid_21626342, JString, required = false,
                                   default = nil)
  if valid_21626342 != nil:
    section.add "X-Amz-Date", valid_21626342
  var valid_21626343 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626343 = validateParameter(valid_21626343, JString, required = false,
                                   default = nil)
  if valid_21626343 != nil:
    section.add "X-Amz-Security-Token", valid_21626343
  var valid_21626344 = header.getOrDefault("X-Amz-Target")
  valid_21626344 = validateParameter(valid_21626344, JString, required = true, default = newJString(
      "CodeCommit_20150413.DisassociateApprovalRuleTemplateFromRepository"))
  if valid_21626344 != nil:
    section.add "X-Amz-Target", valid_21626344
  var valid_21626345 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626345 = validateParameter(valid_21626345, JString, required = false,
                                   default = nil)
  if valid_21626345 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626345
  var valid_21626346 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626346 = validateParameter(valid_21626346, JString, required = false,
                                   default = nil)
  if valid_21626346 != nil:
    section.add "X-Amz-Algorithm", valid_21626346
  var valid_21626347 = header.getOrDefault("X-Amz-Signature")
  valid_21626347 = validateParameter(valid_21626347, JString, required = false,
                                   default = nil)
  if valid_21626347 != nil:
    section.add "X-Amz-Signature", valid_21626347
  var valid_21626348 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626348 = validateParameter(valid_21626348, JString, required = false,
                                   default = nil)
  if valid_21626348 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626348
  var valid_21626349 = header.getOrDefault("X-Amz-Credential")
  valid_21626349 = validateParameter(valid_21626349, JString, required = false,
                                   default = nil)
  if valid_21626349 != nil:
    section.add "X-Amz-Credential", valid_21626349
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626351: Call_DisassociateApprovalRuleTemplateFromRepository_21626339;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Removes the association between a template and a repository so that approval rules based on the template are not automatically created when pull requests are created in the specified repository. This does not delete any approval rules previously created for pull requests through the template association.
  ## 
  let valid = call_21626351.validator(path, query, header, formData, body, _)
  let scheme = call_21626351.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626351.makeUrl(scheme.get, call_21626351.host, call_21626351.base,
                               call_21626351.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626351, uri, valid, _)

proc call*(call_21626352: Call_DisassociateApprovalRuleTemplateFromRepository_21626339;
          body: JsonNode): Recallable =
  ## disassociateApprovalRuleTemplateFromRepository
  ## Removes the association between a template and a repository so that approval rules based on the template are not automatically created when pull requests are created in the specified repository. This does not delete any approval rules previously created for pull requests through the template association.
  ##   body: JObject (required)
  var body_21626353 = newJObject()
  if body != nil:
    body_21626353 = body
  result = call_21626352.call(nil, nil, nil, nil, body_21626353)

var disassociateApprovalRuleTemplateFromRepository* = Call_DisassociateApprovalRuleTemplateFromRepository_21626339(
    name: "disassociateApprovalRuleTemplateFromRepository",
    meth: HttpMethod.HttpPost, host: "codecommit.amazonaws.com", route: "/#X-Amz-Target=CodeCommit_20150413.DisassociateApprovalRuleTemplateFromRepository",
    validator: validate_DisassociateApprovalRuleTemplateFromRepository_21626340,
    base: "/", makeUrl: url_DisassociateApprovalRuleTemplateFromRepository_21626341,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_EvaluatePullRequestApprovalRules_21626354 = ref object of OpenApiRestCall_21625435
proc url_EvaluatePullRequestApprovalRules_21626356(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_EvaluatePullRequestApprovalRules_21626355(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Evaluates whether a pull request has met all the conditions specified in its associated approval rules.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626357 = header.getOrDefault("X-Amz-Date")
  valid_21626357 = validateParameter(valid_21626357, JString, required = false,
                                   default = nil)
  if valid_21626357 != nil:
    section.add "X-Amz-Date", valid_21626357
  var valid_21626358 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626358 = validateParameter(valid_21626358, JString, required = false,
                                   default = nil)
  if valid_21626358 != nil:
    section.add "X-Amz-Security-Token", valid_21626358
  var valid_21626359 = header.getOrDefault("X-Amz-Target")
  valid_21626359 = validateParameter(valid_21626359, JString, required = true, default = newJString(
      "CodeCommit_20150413.EvaluatePullRequestApprovalRules"))
  if valid_21626359 != nil:
    section.add "X-Amz-Target", valid_21626359
  var valid_21626360 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626360 = validateParameter(valid_21626360, JString, required = false,
                                   default = nil)
  if valid_21626360 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626360
  var valid_21626361 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626361 = validateParameter(valid_21626361, JString, required = false,
                                   default = nil)
  if valid_21626361 != nil:
    section.add "X-Amz-Algorithm", valid_21626361
  var valid_21626362 = header.getOrDefault("X-Amz-Signature")
  valid_21626362 = validateParameter(valid_21626362, JString, required = false,
                                   default = nil)
  if valid_21626362 != nil:
    section.add "X-Amz-Signature", valid_21626362
  var valid_21626363 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626363 = validateParameter(valid_21626363, JString, required = false,
                                   default = nil)
  if valid_21626363 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626363
  var valid_21626364 = header.getOrDefault("X-Amz-Credential")
  valid_21626364 = validateParameter(valid_21626364, JString, required = false,
                                   default = nil)
  if valid_21626364 != nil:
    section.add "X-Amz-Credential", valid_21626364
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626366: Call_EvaluatePullRequestApprovalRules_21626354;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Evaluates whether a pull request has met all the conditions specified in its associated approval rules.
  ## 
  let valid = call_21626366.validator(path, query, header, formData, body, _)
  let scheme = call_21626366.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626366.makeUrl(scheme.get, call_21626366.host, call_21626366.base,
                               call_21626366.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626366, uri, valid, _)

proc call*(call_21626367: Call_EvaluatePullRequestApprovalRules_21626354;
          body: JsonNode): Recallable =
  ## evaluatePullRequestApprovalRules
  ## Evaluates whether a pull request has met all the conditions specified in its associated approval rules.
  ##   body: JObject (required)
  var body_21626368 = newJObject()
  if body != nil:
    body_21626368 = body
  result = call_21626367.call(nil, nil, nil, nil, body_21626368)

var evaluatePullRequestApprovalRules* = Call_EvaluatePullRequestApprovalRules_21626354(
    name: "evaluatePullRequestApprovalRules", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com", route: "/#X-Amz-Target=CodeCommit_20150413.EvaluatePullRequestApprovalRules",
    validator: validate_EvaluatePullRequestApprovalRules_21626355, base: "/",
    makeUrl: url_EvaluatePullRequestApprovalRules_21626356,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApprovalRuleTemplate_21626369 = ref object of OpenApiRestCall_21625435
proc url_GetApprovalRuleTemplate_21626371(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetApprovalRuleTemplate_21626370(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns information about a specified approval rule template.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626372 = header.getOrDefault("X-Amz-Date")
  valid_21626372 = validateParameter(valid_21626372, JString, required = false,
                                   default = nil)
  if valid_21626372 != nil:
    section.add "X-Amz-Date", valid_21626372
  var valid_21626373 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626373 = validateParameter(valid_21626373, JString, required = false,
                                   default = nil)
  if valid_21626373 != nil:
    section.add "X-Amz-Security-Token", valid_21626373
  var valid_21626374 = header.getOrDefault("X-Amz-Target")
  valid_21626374 = validateParameter(valid_21626374, JString, required = true, default = newJString(
      "CodeCommit_20150413.GetApprovalRuleTemplate"))
  if valid_21626374 != nil:
    section.add "X-Amz-Target", valid_21626374
  var valid_21626375 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626375 = validateParameter(valid_21626375, JString, required = false,
                                   default = nil)
  if valid_21626375 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626375
  var valid_21626376 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626376 = validateParameter(valid_21626376, JString, required = false,
                                   default = nil)
  if valid_21626376 != nil:
    section.add "X-Amz-Algorithm", valid_21626376
  var valid_21626377 = header.getOrDefault("X-Amz-Signature")
  valid_21626377 = validateParameter(valid_21626377, JString, required = false,
                                   default = nil)
  if valid_21626377 != nil:
    section.add "X-Amz-Signature", valid_21626377
  var valid_21626378 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626378 = validateParameter(valid_21626378, JString, required = false,
                                   default = nil)
  if valid_21626378 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626378
  var valid_21626379 = header.getOrDefault("X-Amz-Credential")
  valid_21626379 = validateParameter(valid_21626379, JString, required = false,
                                   default = nil)
  if valid_21626379 != nil:
    section.add "X-Amz-Credential", valid_21626379
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626381: Call_GetApprovalRuleTemplate_21626369;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns information about a specified approval rule template.
  ## 
  let valid = call_21626381.validator(path, query, header, formData, body, _)
  let scheme = call_21626381.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626381.makeUrl(scheme.get, call_21626381.host, call_21626381.base,
                               call_21626381.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626381, uri, valid, _)

proc call*(call_21626382: Call_GetApprovalRuleTemplate_21626369; body: JsonNode): Recallable =
  ## getApprovalRuleTemplate
  ## Returns information about a specified approval rule template.
  ##   body: JObject (required)
  var body_21626383 = newJObject()
  if body != nil:
    body_21626383 = body
  result = call_21626382.call(nil, nil, nil, nil, body_21626383)

var getApprovalRuleTemplate* = Call_GetApprovalRuleTemplate_21626369(
    name: "getApprovalRuleTemplate", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.GetApprovalRuleTemplate",
    validator: validate_GetApprovalRuleTemplate_21626370, base: "/",
    makeUrl: url_GetApprovalRuleTemplate_21626371,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBlob_21626384 = ref object of OpenApiRestCall_21625435
proc url_GetBlob_21626386(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetBlob_21626385(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns the base-64 encoded content of an individual blob in a repository.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626387 = header.getOrDefault("X-Amz-Date")
  valid_21626387 = validateParameter(valid_21626387, JString, required = false,
                                   default = nil)
  if valid_21626387 != nil:
    section.add "X-Amz-Date", valid_21626387
  var valid_21626388 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626388 = validateParameter(valid_21626388, JString, required = false,
                                   default = nil)
  if valid_21626388 != nil:
    section.add "X-Amz-Security-Token", valid_21626388
  var valid_21626389 = header.getOrDefault("X-Amz-Target")
  valid_21626389 = validateParameter(valid_21626389, JString, required = true, default = newJString(
      "CodeCommit_20150413.GetBlob"))
  if valid_21626389 != nil:
    section.add "X-Amz-Target", valid_21626389
  var valid_21626390 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626390 = validateParameter(valid_21626390, JString, required = false,
                                   default = nil)
  if valid_21626390 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626390
  var valid_21626391 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626391 = validateParameter(valid_21626391, JString, required = false,
                                   default = nil)
  if valid_21626391 != nil:
    section.add "X-Amz-Algorithm", valid_21626391
  var valid_21626392 = header.getOrDefault("X-Amz-Signature")
  valid_21626392 = validateParameter(valid_21626392, JString, required = false,
                                   default = nil)
  if valid_21626392 != nil:
    section.add "X-Amz-Signature", valid_21626392
  var valid_21626393 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626393 = validateParameter(valid_21626393, JString, required = false,
                                   default = nil)
  if valid_21626393 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626393
  var valid_21626394 = header.getOrDefault("X-Amz-Credential")
  valid_21626394 = validateParameter(valid_21626394, JString, required = false,
                                   default = nil)
  if valid_21626394 != nil:
    section.add "X-Amz-Credential", valid_21626394
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626396: Call_GetBlob_21626384; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns the base-64 encoded content of an individual blob in a repository.
  ## 
  let valid = call_21626396.validator(path, query, header, formData, body, _)
  let scheme = call_21626396.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626396.makeUrl(scheme.get, call_21626396.host, call_21626396.base,
                               call_21626396.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626396, uri, valid, _)

proc call*(call_21626397: Call_GetBlob_21626384; body: JsonNode): Recallable =
  ## getBlob
  ## Returns the base-64 encoded content of an individual blob in a repository.
  ##   body: JObject (required)
  var body_21626398 = newJObject()
  if body != nil:
    body_21626398 = body
  result = call_21626397.call(nil, nil, nil, nil, body_21626398)

var getBlob* = Call_GetBlob_21626384(name: "getBlob", meth: HttpMethod.HttpPost,
                                  host: "codecommit.amazonaws.com", route: "/#X-Amz-Target=CodeCommit_20150413.GetBlob",
                                  validator: validate_GetBlob_21626385, base: "/",
                                  makeUrl: url_GetBlob_21626386,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBranch_21626399 = ref object of OpenApiRestCall_21625435
proc url_GetBranch_21626401(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetBranch_21626400(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns information about a repository branch, including its name and the last commit ID.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626402 = header.getOrDefault("X-Amz-Date")
  valid_21626402 = validateParameter(valid_21626402, JString, required = false,
                                   default = nil)
  if valid_21626402 != nil:
    section.add "X-Amz-Date", valid_21626402
  var valid_21626403 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626403 = validateParameter(valid_21626403, JString, required = false,
                                   default = nil)
  if valid_21626403 != nil:
    section.add "X-Amz-Security-Token", valid_21626403
  var valid_21626404 = header.getOrDefault("X-Amz-Target")
  valid_21626404 = validateParameter(valid_21626404, JString, required = true, default = newJString(
      "CodeCommit_20150413.GetBranch"))
  if valid_21626404 != nil:
    section.add "X-Amz-Target", valid_21626404
  var valid_21626405 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626405 = validateParameter(valid_21626405, JString, required = false,
                                   default = nil)
  if valid_21626405 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626405
  var valid_21626406 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626406 = validateParameter(valid_21626406, JString, required = false,
                                   default = nil)
  if valid_21626406 != nil:
    section.add "X-Amz-Algorithm", valid_21626406
  var valid_21626407 = header.getOrDefault("X-Amz-Signature")
  valid_21626407 = validateParameter(valid_21626407, JString, required = false,
                                   default = nil)
  if valid_21626407 != nil:
    section.add "X-Amz-Signature", valid_21626407
  var valid_21626408 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626408 = validateParameter(valid_21626408, JString, required = false,
                                   default = nil)
  if valid_21626408 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626408
  var valid_21626409 = header.getOrDefault("X-Amz-Credential")
  valid_21626409 = validateParameter(valid_21626409, JString, required = false,
                                   default = nil)
  if valid_21626409 != nil:
    section.add "X-Amz-Credential", valid_21626409
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626411: Call_GetBranch_21626399; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns information about a repository branch, including its name and the last commit ID.
  ## 
  let valid = call_21626411.validator(path, query, header, formData, body, _)
  let scheme = call_21626411.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626411.makeUrl(scheme.get, call_21626411.host, call_21626411.base,
                               call_21626411.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626411, uri, valid, _)

proc call*(call_21626412: Call_GetBranch_21626399; body: JsonNode): Recallable =
  ## getBranch
  ## Returns information about a repository branch, including its name and the last commit ID.
  ##   body: JObject (required)
  var body_21626413 = newJObject()
  if body != nil:
    body_21626413 = body
  result = call_21626412.call(nil, nil, nil, nil, body_21626413)

var getBranch* = Call_GetBranch_21626399(name: "getBranch",
                                      meth: HttpMethod.HttpPost,
                                      host: "codecommit.amazonaws.com", route: "/#X-Amz-Target=CodeCommit_20150413.GetBranch",
                                      validator: validate_GetBranch_21626400,
                                      base: "/", makeUrl: url_GetBranch_21626401,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetComment_21626414 = ref object of OpenApiRestCall_21625435
proc url_GetComment_21626416(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetComment_21626415(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns the content of a comment made on a change, file, or commit in a repository.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626417 = header.getOrDefault("X-Amz-Date")
  valid_21626417 = validateParameter(valid_21626417, JString, required = false,
                                   default = nil)
  if valid_21626417 != nil:
    section.add "X-Amz-Date", valid_21626417
  var valid_21626418 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626418 = validateParameter(valid_21626418, JString, required = false,
                                   default = nil)
  if valid_21626418 != nil:
    section.add "X-Amz-Security-Token", valid_21626418
  var valid_21626419 = header.getOrDefault("X-Amz-Target")
  valid_21626419 = validateParameter(valid_21626419, JString, required = true, default = newJString(
      "CodeCommit_20150413.GetComment"))
  if valid_21626419 != nil:
    section.add "X-Amz-Target", valid_21626419
  var valid_21626420 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626420 = validateParameter(valid_21626420, JString, required = false,
                                   default = nil)
  if valid_21626420 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626420
  var valid_21626421 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626421 = validateParameter(valid_21626421, JString, required = false,
                                   default = nil)
  if valid_21626421 != nil:
    section.add "X-Amz-Algorithm", valid_21626421
  var valid_21626422 = header.getOrDefault("X-Amz-Signature")
  valid_21626422 = validateParameter(valid_21626422, JString, required = false,
                                   default = nil)
  if valid_21626422 != nil:
    section.add "X-Amz-Signature", valid_21626422
  var valid_21626423 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626423 = validateParameter(valid_21626423, JString, required = false,
                                   default = nil)
  if valid_21626423 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626423
  var valid_21626424 = header.getOrDefault("X-Amz-Credential")
  valid_21626424 = validateParameter(valid_21626424, JString, required = false,
                                   default = nil)
  if valid_21626424 != nil:
    section.add "X-Amz-Credential", valid_21626424
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626426: Call_GetComment_21626414; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns the content of a comment made on a change, file, or commit in a repository.
  ## 
  let valid = call_21626426.validator(path, query, header, formData, body, _)
  let scheme = call_21626426.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626426.makeUrl(scheme.get, call_21626426.host, call_21626426.base,
                               call_21626426.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626426, uri, valid, _)

proc call*(call_21626427: Call_GetComment_21626414; body: JsonNode): Recallable =
  ## getComment
  ## Returns the content of a comment made on a change, file, or commit in a repository.
  ##   body: JObject (required)
  var body_21626428 = newJObject()
  if body != nil:
    body_21626428 = body
  result = call_21626427.call(nil, nil, nil, nil, body_21626428)

var getComment* = Call_GetComment_21626414(name: "getComment",
                                        meth: HttpMethod.HttpPost,
                                        host: "codecommit.amazonaws.com", route: "/#X-Amz-Target=CodeCommit_20150413.GetComment",
                                        validator: validate_GetComment_21626415,
                                        base: "/", makeUrl: url_GetComment_21626416,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCommentsForComparedCommit_21626429 = ref object of OpenApiRestCall_21625435
proc url_GetCommentsForComparedCommit_21626431(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCommentsForComparedCommit_21626430(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Returns information about comments made on the comparison between two commits.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JString
  ##             : Pagination limit
  ##   nextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_21626432 = query.getOrDefault("maxResults")
  valid_21626432 = validateParameter(valid_21626432, JString, required = false,
                                   default = nil)
  if valid_21626432 != nil:
    section.add "maxResults", valid_21626432
  var valid_21626433 = query.getOrDefault("nextToken")
  valid_21626433 = validateParameter(valid_21626433, JString, required = false,
                                   default = nil)
  if valid_21626433 != nil:
    section.add "nextToken", valid_21626433
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626434 = header.getOrDefault("X-Amz-Date")
  valid_21626434 = validateParameter(valid_21626434, JString, required = false,
                                   default = nil)
  if valid_21626434 != nil:
    section.add "X-Amz-Date", valid_21626434
  var valid_21626435 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626435 = validateParameter(valid_21626435, JString, required = false,
                                   default = nil)
  if valid_21626435 != nil:
    section.add "X-Amz-Security-Token", valid_21626435
  var valid_21626436 = header.getOrDefault("X-Amz-Target")
  valid_21626436 = validateParameter(valid_21626436, JString, required = true, default = newJString(
      "CodeCommit_20150413.GetCommentsForComparedCommit"))
  if valid_21626436 != nil:
    section.add "X-Amz-Target", valid_21626436
  var valid_21626437 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626437 = validateParameter(valid_21626437, JString, required = false,
                                   default = nil)
  if valid_21626437 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626437
  var valid_21626438 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626438 = validateParameter(valid_21626438, JString, required = false,
                                   default = nil)
  if valid_21626438 != nil:
    section.add "X-Amz-Algorithm", valid_21626438
  var valid_21626439 = header.getOrDefault("X-Amz-Signature")
  valid_21626439 = validateParameter(valid_21626439, JString, required = false,
                                   default = nil)
  if valid_21626439 != nil:
    section.add "X-Amz-Signature", valid_21626439
  var valid_21626440 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626440 = validateParameter(valid_21626440, JString, required = false,
                                   default = nil)
  if valid_21626440 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626440
  var valid_21626441 = header.getOrDefault("X-Amz-Credential")
  valid_21626441 = validateParameter(valid_21626441, JString, required = false,
                                   default = nil)
  if valid_21626441 != nil:
    section.add "X-Amz-Credential", valid_21626441
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626443: Call_GetCommentsForComparedCommit_21626429;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns information about comments made on the comparison between two commits.
  ## 
  let valid = call_21626443.validator(path, query, header, formData, body, _)
  let scheme = call_21626443.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626443.makeUrl(scheme.get, call_21626443.host, call_21626443.base,
                               call_21626443.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626443, uri, valid, _)

proc call*(call_21626444: Call_GetCommentsForComparedCommit_21626429;
          body: JsonNode; maxResults: string = ""; nextToken: string = ""): Recallable =
  ## getCommentsForComparedCommit
  ## Returns information about comments made on the comparison between two commits.
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_21626445 = newJObject()
  var body_21626446 = newJObject()
  add(query_21626445, "maxResults", newJString(maxResults))
  add(query_21626445, "nextToken", newJString(nextToken))
  if body != nil:
    body_21626446 = body
  result = call_21626444.call(nil, query_21626445, nil, nil, body_21626446)

var getCommentsForComparedCommit* = Call_GetCommentsForComparedCommit_21626429(
    name: "getCommentsForComparedCommit", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.GetCommentsForComparedCommit",
    validator: validate_GetCommentsForComparedCommit_21626430, base: "/",
    makeUrl: url_GetCommentsForComparedCommit_21626431,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCommentsForPullRequest_21626447 = ref object of OpenApiRestCall_21625435
proc url_GetCommentsForPullRequest_21626449(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCommentsForPullRequest_21626448(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns comments made on a pull request.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JString
  ##             : Pagination limit
  ##   nextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_21626450 = query.getOrDefault("maxResults")
  valid_21626450 = validateParameter(valid_21626450, JString, required = false,
                                   default = nil)
  if valid_21626450 != nil:
    section.add "maxResults", valid_21626450
  var valid_21626451 = query.getOrDefault("nextToken")
  valid_21626451 = validateParameter(valid_21626451, JString, required = false,
                                   default = nil)
  if valid_21626451 != nil:
    section.add "nextToken", valid_21626451
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626452 = header.getOrDefault("X-Amz-Date")
  valid_21626452 = validateParameter(valid_21626452, JString, required = false,
                                   default = nil)
  if valid_21626452 != nil:
    section.add "X-Amz-Date", valid_21626452
  var valid_21626453 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626453 = validateParameter(valid_21626453, JString, required = false,
                                   default = nil)
  if valid_21626453 != nil:
    section.add "X-Amz-Security-Token", valid_21626453
  var valid_21626454 = header.getOrDefault("X-Amz-Target")
  valid_21626454 = validateParameter(valid_21626454, JString, required = true, default = newJString(
      "CodeCommit_20150413.GetCommentsForPullRequest"))
  if valid_21626454 != nil:
    section.add "X-Amz-Target", valid_21626454
  var valid_21626455 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626455 = validateParameter(valid_21626455, JString, required = false,
                                   default = nil)
  if valid_21626455 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626455
  var valid_21626456 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626456 = validateParameter(valid_21626456, JString, required = false,
                                   default = nil)
  if valid_21626456 != nil:
    section.add "X-Amz-Algorithm", valid_21626456
  var valid_21626457 = header.getOrDefault("X-Amz-Signature")
  valid_21626457 = validateParameter(valid_21626457, JString, required = false,
                                   default = nil)
  if valid_21626457 != nil:
    section.add "X-Amz-Signature", valid_21626457
  var valid_21626458 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626458 = validateParameter(valid_21626458, JString, required = false,
                                   default = nil)
  if valid_21626458 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626458
  var valid_21626459 = header.getOrDefault("X-Amz-Credential")
  valid_21626459 = validateParameter(valid_21626459, JString, required = false,
                                   default = nil)
  if valid_21626459 != nil:
    section.add "X-Amz-Credential", valid_21626459
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626461: Call_GetCommentsForPullRequest_21626447;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns comments made on a pull request.
  ## 
  let valid = call_21626461.validator(path, query, header, formData, body, _)
  let scheme = call_21626461.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626461.makeUrl(scheme.get, call_21626461.host, call_21626461.base,
                               call_21626461.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626461, uri, valid, _)

proc call*(call_21626462: Call_GetCommentsForPullRequest_21626447; body: JsonNode;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## getCommentsForPullRequest
  ## Returns comments made on a pull request.
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_21626463 = newJObject()
  var body_21626464 = newJObject()
  add(query_21626463, "maxResults", newJString(maxResults))
  add(query_21626463, "nextToken", newJString(nextToken))
  if body != nil:
    body_21626464 = body
  result = call_21626462.call(nil, query_21626463, nil, nil, body_21626464)

var getCommentsForPullRequest* = Call_GetCommentsForPullRequest_21626447(
    name: "getCommentsForPullRequest", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.GetCommentsForPullRequest",
    validator: validate_GetCommentsForPullRequest_21626448, base: "/",
    makeUrl: url_GetCommentsForPullRequest_21626449,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCommit_21626465 = ref object of OpenApiRestCall_21625435
proc url_GetCommit_21626467(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCommit_21626466(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns information about a commit, including commit message and committer information.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626468 = header.getOrDefault("X-Amz-Date")
  valid_21626468 = validateParameter(valid_21626468, JString, required = false,
                                   default = nil)
  if valid_21626468 != nil:
    section.add "X-Amz-Date", valid_21626468
  var valid_21626469 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626469 = validateParameter(valid_21626469, JString, required = false,
                                   default = nil)
  if valid_21626469 != nil:
    section.add "X-Amz-Security-Token", valid_21626469
  var valid_21626470 = header.getOrDefault("X-Amz-Target")
  valid_21626470 = validateParameter(valid_21626470, JString, required = true, default = newJString(
      "CodeCommit_20150413.GetCommit"))
  if valid_21626470 != nil:
    section.add "X-Amz-Target", valid_21626470
  var valid_21626471 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626471 = validateParameter(valid_21626471, JString, required = false,
                                   default = nil)
  if valid_21626471 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626471
  var valid_21626472 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626472 = validateParameter(valid_21626472, JString, required = false,
                                   default = nil)
  if valid_21626472 != nil:
    section.add "X-Amz-Algorithm", valid_21626472
  var valid_21626473 = header.getOrDefault("X-Amz-Signature")
  valid_21626473 = validateParameter(valid_21626473, JString, required = false,
                                   default = nil)
  if valid_21626473 != nil:
    section.add "X-Amz-Signature", valid_21626473
  var valid_21626474 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626474 = validateParameter(valid_21626474, JString, required = false,
                                   default = nil)
  if valid_21626474 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626474
  var valid_21626475 = header.getOrDefault("X-Amz-Credential")
  valid_21626475 = validateParameter(valid_21626475, JString, required = false,
                                   default = nil)
  if valid_21626475 != nil:
    section.add "X-Amz-Credential", valid_21626475
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626477: Call_GetCommit_21626465; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns information about a commit, including commit message and committer information.
  ## 
  let valid = call_21626477.validator(path, query, header, formData, body, _)
  let scheme = call_21626477.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626477.makeUrl(scheme.get, call_21626477.host, call_21626477.base,
                               call_21626477.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626477, uri, valid, _)

proc call*(call_21626478: Call_GetCommit_21626465; body: JsonNode): Recallable =
  ## getCommit
  ## Returns information about a commit, including commit message and committer information.
  ##   body: JObject (required)
  var body_21626479 = newJObject()
  if body != nil:
    body_21626479 = body
  result = call_21626478.call(nil, nil, nil, nil, body_21626479)

var getCommit* = Call_GetCommit_21626465(name: "getCommit",
                                      meth: HttpMethod.HttpPost,
                                      host: "codecommit.amazonaws.com", route: "/#X-Amz-Target=CodeCommit_20150413.GetCommit",
                                      validator: validate_GetCommit_21626466,
                                      base: "/", makeUrl: url_GetCommit_21626467,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDifferences_21626480 = ref object of OpenApiRestCall_21625435
proc url_GetDifferences_21626482(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDifferences_21626481(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns information about the differences in a valid commit specifier (such as a branch, tag, HEAD, commit ID, or other fully qualified reference). Results can be limited to a specified path.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_21626483 = query.getOrDefault("NextToken")
  valid_21626483 = validateParameter(valid_21626483, JString, required = false,
                                   default = nil)
  if valid_21626483 != nil:
    section.add "NextToken", valid_21626483
  var valid_21626484 = query.getOrDefault("MaxResults")
  valid_21626484 = validateParameter(valid_21626484, JString, required = false,
                                   default = nil)
  if valid_21626484 != nil:
    section.add "MaxResults", valid_21626484
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626485 = header.getOrDefault("X-Amz-Date")
  valid_21626485 = validateParameter(valid_21626485, JString, required = false,
                                   default = nil)
  if valid_21626485 != nil:
    section.add "X-Amz-Date", valid_21626485
  var valid_21626486 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626486 = validateParameter(valid_21626486, JString, required = false,
                                   default = nil)
  if valid_21626486 != nil:
    section.add "X-Amz-Security-Token", valid_21626486
  var valid_21626487 = header.getOrDefault("X-Amz-Target")
  valid_21626487 = validateParameter(valid_21626487, JString, required = true, default = newJString(
      "CodeCommit_20150413.GetDifferences"))
  if valid_21626487 != nil:
    section.add "X-Amz-Target", valid_21626487
  var valid_21626488 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626488 = validateParameter(valid_21626488, JString, required = false,
                                   default = nil)
  if valid_21626488 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626488
  var valid_21626489 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626489 = validateParameter(valid_21626489, JString, required = false,
                                   default = nil)
  if valid_21626489 != nil:
    section.add "X-Amz-Algorithm", valid_21626489
  var valid_21626490 = header.getOrDefault("X-Amz-Signature")
  valid_21626490 = validateParameter(valid_21626490, JString, required = false,
                                   default = nil)
  if valid_21626490 != nil:
    section.add "X-Amz-Signature", valid_21626490
  var valid_21626491 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626491 = validateParameter(valid_21626491, JString, required = false,
                                   default = nil)
  if valid_21626491 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626491
  var valid_21626492 = header.getOrDefault("X-Amz-Credential")
  valid_21626492 = validateParameter(valid_21626492, JString, required = false,
                                   default = nil)
  if valid_21626492 != nil:
    section.add "X-Amz-Credential", valid_21626492
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626494: Call_GetDifferences_21626480; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns information about the differences in a valid commit specifier (such as a branch, tag, HEAD, commit ID, or other fully qualified reference). Results can be limited to a specified path.
  ## 
  let valid = call_21626494.validator(path, query, header, formData, body, _)
  let scheme = call_21626494.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626494.makeUrl(scheme.get, call_21626494.host, call_21626494.base,
                               call_21626494.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626494, uri, valid, _)

proc call*(call_21626495: Call_GetDifferences_21626480; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## getDifferences
  ## Returns information about the differences in a valid commit specifier (such as a branch, tag, HEAD, commit ID, or other fully qualified reference). Results can be limited to a specified path.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_21626496 = newJObject()
  var body_21626497 = newJObject()
  add(query_21626496, "NextToken", newJString(NextToken))
  if body != nil:
    body_21626497 = body
  add(query_21626496, "MaxResults", newJString(MaxResults))
  result = call_21626495.call(nil, query_21626496, nil, nil, body_21626497)

var getDifferences* = Call_GetDifferences_21626480(name: "getDifferences",
    meth: HttpMethod.HttpPost, host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.GetDifferences",
    validator: validate_GetDifferences_21626481, base: "/",
    makeUrl: url_GetDifferences_21626482, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFile_21626498 = ref object of OpenApiRestCall_21625435
proc url_GetFile_21626500(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetFile_21626499(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns the base-64 encoded contents of a specified file and its metadata.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626501 = header.getOrDefault("X-Amz-Date")
  valid_21626501 = validateParameter(valid_21626501, JString, required = false,
                                   default = nil)
  if valid_21626501 != nil:
    section.add "X-Amz-Date", valid_21626501
  var valid_21626502 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626502 = validateParameter(valid_21626502, JString, required = false,
                                   default = nil)
  if valid_21626502 != nil:
    section.add "X-Amz-Security-Token", valid_21626502
  var valid_21626503 = header.getOrDefault("X-Amz-Target")
  valid_21626503 = validateParameter(valid_21626503, JString, required = true, default = newJString(
      "CodeCommit_20150413.GetFile"))
  if valid_21626503 != nil:
    section.add "X-Amz-Target", valid_21626503
  var valid_21626504 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626504 = validateParameter(valid_21626504, JString, required = false,
                                   default = nil)
  if valid_21626504 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626504
  var valid_21626505 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626505 = validateParameter(valid_21626505, JString, required = false,
                                   default = nil)
  if valid_21626505 != nil:
    section.add "X-Amz-Algorithm", valid_21626505
  var valid_21626506 = header.getOrDefault("X-Amz-Signature")
  valid_21626506 = validateParameter(valid_21626506, JString, required = false,
                                   default = nil)
  if valid_21626506 != nil:
    section.add "X-Amz-Signature", valid_21626506
  var valid_21626507 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626507 = validateParameter(valid_21626507, JString, required = false,
                                   default = nil)
  if valid_21626507 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626507
  var valid_21626508 = header.getOrDefault("X-Amz-Credential")
  valid_21626508 = validateParameter(valid_21626508, JString, required = false,
                                   default = nil)
  if valid_21626508 != nil:
    section.add "X-Amz-Credential", valid_21626508
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626510: Call_GetFile_21626498; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns the base-64 encoded contents of a specified file and its metadata.
  ## 
  let valid = call_21626510.validator(path, query, header, formData, body, _)
  let scheme = call_21626510.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626510.makeUrl(scheme.get, call_21626510.host, call_21626510.base,
                               call_21626510.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626510, uri, valid, _)

proc call*(call_21626511: Call_GetFile_21626498; body: JsonNode): Recallable =
  ## getFile
  ## Returns the base-64 encoded contents of a specified file and its metadata.
  ##   body: JObject (required)
  var body_21626512 = newJObject()
  if body != nil:
    body_21626512 = body
  result = call_21626511.call(nil, nil, nil, nil, body_21626512)

var getFile* = Call_GetFile_21626498(name: "getFile", meth: HttpMethod.HttpPost,
                                  host: "codecommit.amazonaws.com", route: "/#X-Amz-Target=CodeCommit_20150413.GetFile",
                                  validator: validate_GetFile_21626499, base: "/",
                                  makeUrl: url_GetFile_21626500,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFolder_21626513 = ref object of OpenApiRestCall_21625435
proc url_GetFolder_21626515(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetFolder_21626514(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns the contents of a specified folder in a repository.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626516 = header.getOrDefault("X-Amz-Date")
  valid_21626516 = validateParameter(valid_21626516, JString, required = false,
                                   default = nil)
  if valid_21626516 != nil:
    section.add "X-Amz-Date", valid_21626516
  var valid_21626517 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626517 = validateParameter(valid_21626517, JString, required = false,
                                   default = nil)
  if valid_21626517 != nil:
    section.add "X-Amz-Security-Token", valid_21626517
  var valid_21626518 = header.getOrDefault("X-Amz-Target")
  valid_21626518 = validateParameter(valid_21626518, JString, required = true, default = newJString(
      "CodeCommit_20150413.GetFolder"))
  if valid_21626518 != nil:
    section.add "X-Amz-Target", valid_21626518
  var valid_21626519 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626519 = validateParameter(valid_21626519, JString, required = false,
                                   default = nil)
  if valid_21626519 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626519
  var valid_21626520 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626520 = validateParameter(valid_21626520, JString, required = false,
                                   default = nil)
  if valid_21626520 != nil:
    section.add "X-Amz-Algorithm", valid_21626520
  var valid_21626521 = header.getOrDefault("X-Amz-Signature")
  valid_21626521 = validateParameter(valid_21626521, JString, required = false,
                                   default = nil)
  if valid_21626521 != nil:
    section.add "X-Amz-Signature", valid_21626521
  var valid_21626522 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626522 = validateParameter(valid_21626522, JString, required = false,
                                   default = nil)
  if valid_21626522 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626522
  var valid_21626523 = header.getOrDefault("X-Amz-Credential")
  valid_21626523 = validateParameter(valid_21626523, JString, required = false,
                                   default = nil)
  if valid_21626523 != nil:
    section.add "X-Amz-Credential", valid_21626523
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626525: Call_GetFolder_21626513; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns the contents of a specified folder in a repository.
  ## 
  let valid = call_21626525.validator(path, query, header, formData, body, _)
  let scheme = call_21626525.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626525.makeUrl(scheme.get, call_21626525.host, call_21626525.base,
                               call_21626525.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626525, uri, valid, _)

proc call*(call_21626526: Call_GetFolder_21626513; body: JsonNode): Recallable =
  ## getFolder
  ## Returns the contents of a specified folder in a repository.
  ##   body: JObject (required)
  var body_21626527 = newJObject()
  if body != nil:
    body_21626527 = body
  result = call_21626526.call(nil, nil, nil, nil, body_21626527)

var getFolder* = Call_GetFolder_21626513(name: "getFolder",
                                      meth: HttpMethod.HttpPost,
                                      host: "codecommit.amazonaws.com", route: "/#X-Amz-Target=CodeCommit_20150413.GetFolder",
                                      validator: validate_GetFolder_21626514,
                                      base: "/", makeUrl: url_GetFolder_21626515,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMergeCommit_21626528 = ref object of OpenApiRestCall_21625435
proc url_GetMergeCommit_21626530(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetMergeCommit_21626529(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns information about a specified merge commit.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626531 = header.getOrDefault("X-Amz-Date")
  valid_21626531 = validateParameter(valid_21626531, JString, required = false,
                                   default = nil)
  if valid_21626531 != nil:
    section.add "X-Amz-Date", valid_21626531
  var valid_21626532 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626532 = validateParameter(valid_21626532, JString, required = false,
                                   default = nil)
  if valid_21626532 != nil:
    section.add "X-Amz-Security-Token", valid_21626532
  var valid_21626533 = header.getOrDefault("X-Amz-Target")
  valid_21626533 = validateParameter(valid_21626533, JString, required = true, default = newJString(
      "CodeCommit_20150413.GetMergeCommit"))
  if valid_21626533 != nil:
    section.add "X-Amz-Target", valid_21626533
  var valid_21626534 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626534 = validateParameter(valid_21626534, JString, required = false,
                                   default = nil)
  if valid_21626534 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626534
  var valid_21626535 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626535 = validateParameter(valid_21626535, JString, required = false,
                                   default = nil)
  if valid_21626535 != nil:
    section.add "X-Amz-Algorithm", valid_21626535
  var valid_21626536 = header.getOrDefault("X-Amz-Signature")
  valid_21626536 = validateParameter(valid_21626536, JString, required = false,
                                   default = nil)
  if valid_21626536 != nil:
    section.add "X-Amz-Signature", valid_21626536
  var valid_21626537 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626537 = validateParameter(valid_21626537, JString, required = false,
                                   default = nil)
  if valid_21626537 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626537
  var valid_21626538 = header.getOrDefault("X-Amz-Credential")
  valid_21626538 = validateParameter(valid_21626538, JString, required = false,
                                   default = nil)
  if valid_21626538 != nil:
    section.add "X-Amz-Credential", valid_21626538
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626540: Call_GetMergeCommit_21626528; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns information about a specified merge commit.
  ## 
  let valid = call_21626540.validator(path, query, header, formData, body, _)
  let scheme = call_21626540.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626540.makeUrl(scheme.get, call_21626540.host, call_21626540.base,
                               call_21626540.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626540, uri, valid, _)

proc call*(call_21626541: Call_GetMergeCommit_21626528; body: JsonNode): Recallable =
  ## getMergeCommit
  ## Returns information about a specified merge commit.
  ##   body: JObject (required)
  var body_21626542 = newJObject()
  if body != nil:
    body_21626542 = body
  result = call_21626541.call(nil, nil, nil, nil, body_21626542)

var getMergeCommit* = Call_GetMergeCommit_21626528(name: "getMergeCommit",
    meth: HttpMethod.HttpPost, host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.GetMergeCommit",
    validator: validate_GetMergeCommit_21626529, base: "/",
    makeUrl: url_GetMergeCommit_21626530, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMergeConflicts_21626543 = ref object of OpenApiRestCall_21625435
proc url_GetMergeConflicts_21626545(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetMergeConflicts_21626544(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns information about merge conflicts between the before and after commit IDs for a pull request in a repository.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Pagination token
  ##   maxConflictFiles: JString
  ##                   : Pagination limit
  section = newJObject()
  var valid_21626546 = query.getOrDefault("nextToken")
  valid_21626546 = validateParameter(valid_21626546, JString, required = false,
                                   default = nil)
  if valid_21626546 != nil:
    section.add "nextToken", valid_21626546
  var valid_21626547 = query.getOrDefault("maxConflictFiles")
  valid_21626547 = validateParameter(valid_21626547, JString, required = false,
                                   default = nil)
  if valid_21626547 != nil:
    section.add "maxConflictFiles", valid_21626547
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626548 = header.getOrDefault("X-Amz-Date")
  valid_21626548 = validateParameter(valid_21626548, JString, required = false,
                                   default = nil)
  if valid_21626548 != nil:
    section.add "X-Amz-Date", valid_21626548
  var valid_21626549 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626549 = validateParameter(valid_21626549, JString, required = false,
                                   default = nil)
  if valid_21626549 != nil:
    section.add "X-Amz-Security-Token", valid_21626549
  var valid_21626550 = header.getOrDefault("X-Amz-Target")
  valid_21626550 = validateParameter(valid_21626550, JString, required = true, default = newJString(
      "CodeCommit_20150413.GetMergeConflicts"))
  if valid_21626550 != nil:
    section.add "X-Amz-Target", valid_21626550
  var valid_21626551 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626551 = validateParameter(valid_21626551, JString, required = false,
                                   default = nil)
  if valid_21626551 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626551
  var valid_21626552 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626552 = validateParameter(valid_21626552, JString, required = false,
                                   default = nil)
  if valid_21626552 != nil:
    section.add "X-Amz-Algorithm", valid_21626552
  var valid_21626553 = header.getOrDefault("X-Amz-Signature")
  valid_21626553 = validateParameter(valid_21626553, JString, required = false,
                                   default = nil)
  if valid_21626553 != nil:
    section.add "X-Amz-Signature", valid_21626553
  var valid_21626554 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626554 = validateParameter(valid_21626554, JString, required = false,
                                   default = nil)
  if valid_21626554 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626554
  var valid_21626555 = header.getOrDefault("X-Amz-Credential")
  valid_21626555 = validateParameter(valid_21626555, JString, required = false,
                                   default = nil)
  if valid_21626555 != nil:
    section.add "X-Amz-Credential", valid_21626555
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626557: Call_GetMergeConflicts_21626543; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns information about merge conflicts between the before and after commit IDs for a pull request in a repository.
  ## 
  let valid = call_21626557.validator(path, query, header, formData, body, _)
  let scheme = call_21626557.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626557.makeUrl(scheme.get, call_21626557.host, call_21626557.base,
                               call_21626557.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626557, uri, valid, _)

proc call*(call_21626558: Call_GetMergeConflicts_21626543; body: JsonNode;
          nextToken: string = ""; maxConflictFiles: string = ""): Recallable =
  ## getMergeConflicts
  ## Returns information about merge conflicts between the before and after commit IDs for a pull request in a repository.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxConflictFiles: string
  ##                   : Pagination limit
  var query_21626559 = newJObject()
  var body_21626560 = newJObject()
  add(query_21626559, "nextToken", newJString(nextToken))
  if body != nil:
    body_21626560 = body
  add(query_21626559, "maxConflictFiles", newJString(maxConflictFiles))
  result = call_21626558.call(nil, query_21626559, nil, nil, body_21626560)

var getMergeConflicts* = Call_GetMergeConflicts_21626543(name: "getMergeConflicts",
    meth: HttpMethod.HttpPost, host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.GetMergeConflicts",
    validator: validate_GetMergeConflicts_21626544, base: "/",
    makeUrl: url_GetMergeConflicts_21626545, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMergeOptions_21626561 = ref object of OpenApiRestCall_21625435
proc url_GetMergeOptions_21626563(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetMergeOptions_21626562(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns information about the merge options available for merging two specified branches. For details about why a merge option is not available, use GetMergeConflicts or DescribeMergeConflicts.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626564 = header.getOrDefault("X-Amz-Date")
  valid_21626564 = validateParameter(valid_21626564, JString, required = false,
                                   default = nil)
  if valid_21626564 != nil:
    section.add "X-Amz-Date", valid_21626564
  var valid_21626565 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626565 = validateParameter(valid_21626565, JString, required = false,
                                   default = nil)
  if valid_21626565 != nil:
    section.add "X-Amz-Security-Token", valid_21626565
  var valid_21626566 = header.getOrDefault("X-Amz-Target")
  valid_21626566 = validateParameter(valid_21626566, JString, required = true, default = newJString(
      "CodeCommit_20150413.GetMergeOptions"))
  if valid_21626566 != nil:
    section.add "X-Amz-Target", valid_21626566
  var valid_21626567 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626567 = validateParameter(valid_21626567, JString, required = false,
                                   default = nil)
  if valid_21626567 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626567
  var valid_21626568 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626568 = validateParameter(valid_21626568, JString, required = false,
                                   default = nil)
  if valid_21626568 != nil:
    section.add "X-Amz-Algorithm", valid_21626568
  var valid_21626569 = header.getOrDefault("X-Amz-Signature")
  valid_21626569 = validateParameter(valid_21626569, JString, required = false,
                                   default = nil)
  if valid_21626569 != nil:
    section.add "X-Amz-Signature", valid_21626569
  var valid_21626570 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626570 = validateParameter(valid_21626570, JString, required = false,
                                   default = nil)
  if valid_21626570 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626570
  var valid_21626571 = header.getOrDefault("X-Amz-Credential")
  valid_21626571 = validateParameter(valid_21626571, JString, required = false,
                                   default = nil)
  if valid_21626571 != nil:
    section.add "X-Amz-Credential", valid_21626571
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626573: Call_GetMergeOptions_21626561; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns information about the merge options available for merging two specified branches. For details about why a merge option is not available, use GetMergeConflicts or DescribeMergeConflicts.
  ## 
  let valid = call_21626573.validator(path, query, header, formData, body, _)
  let scheme = call_21626573.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626573.makeUrl(scheme.get, call_21626573.host, call_21626573.base,
                               call_21626573.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626573, uri, valid, _)

proc call*(call_21626574: Call_GetMergeOptions_21626561; body: JsonNode): Recallable =
  ## getMergeOptions
  ## Returns information about the merge options available for merging two specified branches. For details about why a merge option is not available, use GetMergeConflicts or DescribeMergeConflicts.
  ##   body: JObject (required)
  var body_21626575 = newJObject()
  if body != nil:
    body_21626575 = body
  result = call_21626574.call(nil, nil, nil, nil, body_21626575)

var getMergeOptions* = Call_GetMergeOptions_21626561(name: "getMergeOptions",
    meth: HttpMethod.HttpPost, host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.GetMergeOptions",
    validator: validate_GetMergeOptions_21626562, base: "/",
    makeUrl: url_GetMergeOptions_21626563, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPullRequest_21626576 = ref object of OpenApiRestCall_21625435
proc url_GetPullRequest_21626578(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetPullRequest_21626577(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Gets information about a pull request in a specified repository.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626579 = header.getOrDefault("X-Amz-Date")
  valid_21626579 = validateParameter(valid_21626579, JString, required = false,
                                   default = nil)
  if valid_21626579 != nil:
    section.add "X-Amz-Date", valid_21626579
  var valid_21626580 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626580 = validateParameter(valid_21626580, JString, required = false,
                                   default = nil)
  if valid_21626580 != nil:
    section.add "X-Amz-Security-Token", valid_21626580
  var valid_21626581 = header.getOrDefault("X-Amz-Target")
  valid_21626581 = validateParameter(valid_21626581, JString, required = true, default = newJString(
      "CodeCommit_20150413.GetPullRequest"))
  if valid_21626581 != nil:
    section.add "X-Amz-Target", valid_21626581
  var valid_21626582 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626582 = validateParameter(valid_21626582, JString, required = false,
                                   default = nil)
  if valid_21626582 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626582
  var valid_21626583 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626583 = validateParameter(valid_21626583, JString, required = false,
                                   default = nil)
  if valid_21626583 != nil:
    section.add "X-Amz-Algorithm", valid_21626583
  var valid_21626584 = header.getOrDefault("X-Amz-Signature")
  valid_21626584 = validateParameter(valid_21626584, JString, required = false,
                                   default = nil)
  if valid_21626584 != nil:
    section.add "X-Amz-Signature", valid_21626584
  var valid_21626585 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626585 = validateParameter(valid_21626585, JString, required = false,
                                   default = nil)
  if valid_21626585 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626585
  var valid_21626586 = header.getOrDefault("X-Amz-Credential")
  valid_21626586 = validateParameter(valid_21626586, JString, required = false,
                                   default = nil)
  if valid_21626586 != nil:
    section.add "X-Amz-Credential", valid_21626586
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626588: Call_GetPullRequest_21626576; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets information about a pull request in a specified repository.
  ## 
  let valid = call_21626588.validator(path, query, header, formData, body, _)
  let scheme = call_21626588.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626588.makeUrl(scheme.get, call_21626588.host, call_21626588.base,
                               call_21626588.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626588, uri, valid, _)

proc call*(call_21626589: Call_GetPullRequest_21626576; body: JsonNode): Recallable =
  ## getPullRequest
  ## Gets information about a pull request in a specified repository.
  ##   body: JObject (required)
  var body_21626590 = newJObject()
  if body != nil:
    body_21626590 = body
  result = call_21626589.call(nil, nil, nil, nil, body_21626590)

var getPullRequest* = Call_GetPullRequest_21626576(name: "getPullRequest",
    meth: HttpMethod.HttpPost, host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.GetPullRequest",
    validator: validate_GetPullRequest_21626577, base: "/",
    makeUrl: url_GetPullRequest_21626578, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPullRequestApprovalStates_21626591 = ref object of OpenApiRestCall_21625435
proc url_GetPullRequestApprovalStates_21626593(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetPullRequestApprovalStates_21626592(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Gets information about the approval states for a specified pull request. Approval states only apply to pull requests that have one or more approval rules applied to them.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626594 = header.getOrDefault("X-Amz-Date")
  valid_21626594 = validateParameter(valid_21626594, JString, required = false,
                                   default = nil)
  if valid_21626594 != nil:
    section.add "X-Amz-Date", valid_21626594
  var valid_21626595 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626595 = validateParameter(valid_21626595, JString, required = false,
                                   default = nil)
  if valid_21626595 != nil:
    section.add "X-Amz-Security-Token", valid_21626595
  var valid_21626596 = header.getOrDefault("X-Amz-Target")
  valid_21626596 = validateParameter(valid_21626596, JString, required = true, default = newJString(
      "CodeCommit_20150413.GetPullRequestApprovalStates"))
  if valid_21626596 != nil:
    section.add "X-Amz-Target", valid_21626596
  var valid_21626597 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626597 = validateParameter(valid_21626597, JString, required = false,
                                   default = nil)
  if valid_21626597 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626597
  var valid_21626598 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626598 = validateParameter(valid_21626598, JString, required = false,
                                   default = nil)
  if valid_21626598 != nil:
    section.add "X-Amz-Algorithm", valid_21626598
  var valid_21626599 = header.getOrDefault("X-Amz-Signature")
  valid_21626599 = validateParameter(valid_21626599, JString, required = false,
                                   default = nil)
  if valid_21626599 != nil:
    section.add "X-Amz-Signature", valid_21626599
  var valid_21626600 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626600 = validateParameter(valid_21626600, JString, required = false,
                                   default = nil)
  if valid_21626600 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626600
  var valid_21626601 = header.getOrDefault("X-Amz-Credential")
  valid_21626601 = validateParameter(valid_21626601, JString, required = false,
                                   default = nil)
  if valid_21626601 != nil:
    section.add "X-Amz-Credential", valid_21626601
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626603: Call_GetPullRequestApprovalStates_21626591;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets information about the approval states for a specified pull request. Approval states only apply to pull requests that have one or more approval rules applied to them.
  ## 
  let valid = call_21626603.validator(path, query, header, formData, body, _)
  let scheme = call_21626603.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626603.makeUrl(scheme.get, call_21626603.host, call_21626603.base,
                               call_21626603.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626603, uri, valid, _)

proc call*(call_21626604: Call_GetPullRequestApprovalStates_21626591;
          body: JsonNode): Recallable =
  ## getPullRequestApprovalStates
  ## Gets information about the approval states for a specified pull request. Approval states only apply to pull requests that have one or more approval rules applied to them.
  ##   body: JObject (required)
  var body_21626605 = newJObject()
  if body != nil:
    body_21626605 = body
  result = call_21626604.call(nil, nil, nil, nil, body_21626605)

var getPullRequestApprovalStates* = Call_GetPullRequestApprovalStates_21626591(
    name: "getPullRequestApprovalStates", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.GetPullRequestApprovalStates",
    validator: validate_GetPullRequestApprovalStates_21626592, base: "/",
    makeUrl: url_GetPullRequestApprovalStates_21626593,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPullRequestOverrideState_21626606 = ref object of OpenApiRestCall_21625435
proc url_GetPullRequestOverrideState_21626608(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetPullRequestOverrideState_21626607(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns information about whether approval rules have been set aside (overridden) for a pull request, and if so, the Amazon Resource Name (ARN) of the user or identity that overrode the rules and their requirements for the pull request.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626609 = header.getOrDefault("X-Amz-Date")
  valid_21626609 = validateParameter(valid_21626609, JString, required = false,
                                   default = nil)
  if valid_21626609 != nil:
    section.add "X-Amz-Date", valid_21626609
  var valid_21626610 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626610 = validateParameter(valid_21626610, JString, required = false,
                                   default = nil)
  if valid_21626610 != nil:
    section.add "X-Amz-Security-Token", valid_21626610
  var valid_21626611 = header.getOrDefault("X-Amz-Target")
  valid_21626611 = validateParameter(valid_21626611, JString, required = true, default = newJString(
      "CodeCommit_20150413.GetPullRequestOverrideState"))
  if valid_21626611 != nil:
    section.add "X-Amz-Target", valid_21626611
  var valid_21626612 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626612 = validateParameter(valid_21626612, JString, required = false,
                                   default = nil)
  if valid_21626612 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626612
  var valid_21626613 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626613 = validateParameter(valid_21626613, JString, required = false,
                                   default = nil)
  if valid_21626613 != nil:
    section.add "X-Amz-Algorithm", valid_21626613
  var valid_21626614 = header.getOrDefault("X-Amz-Signature")
  valid_21626614 = validateParameter(valid_21626614, JString, required = false,
                                   default = nil)
  if valid_21626614 != nil:
    section.add "X-Amz-Signature", valid_21626614
  var valid_21626615 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626615 = validateParameter(valid_21626615, JString, required = false,
                                   default = nil)
  if valid_21626615 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626615
  var valid_21626616 = header.getOrDefault("X-Amz-Credential")
  valid_21626616 = validateParameter(valid_21626616, JString, required = false,
                                   default = nil)
  if valid_21626616 != nil:
    section.add "X-Amz-Credential", valid_21626616
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626618: Call_GetPullRequestOverrideState_21626606;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns information about whether approval rules have been set aside (overridden) for a pull request, and if so, the Amazon Resource Name (ARN) of the user or identity that overrode the rules and their requirements for the pull request.
  ## 
  let valid = call_21626618.validator(path, query, header, formData, body, _)
  let scheme = call_21626618.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626618.makeUrl(scheme.get, call_21626618.host, call_21626618.base,
                               call_21626618.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626618, uri, valid, _)

proc call*(call_21626619: Call_GetPullRequestOverrideState_21626606; body: JsonNode): Recallable =
  ## getPullRequestOverrideState
  ## Returns information about whether approval rules have been set aside (overridden) for a pull request, and if so, the Amazon Resource Name (ARN) of the user or identity that overrode the rules and their requirements for the pull request.
  ##   body: JObject (required)
  var body_21626620 = newJObject()
  if body != nil:
    body_21626620 = body
  result = call_21626619.call(nil, nil, nil, nil, body_21626620)

var getPullRequestOverrideState* = Call_GetPullRequestOverrideState_21626606(
    name: "getPullRequestOverrideState", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.GetPullRequestOverrideState",
    validator: validate_GetPullRequestOverrideState_21626607, base: "/",
    makeUrl: url_GetPullRequestOverrideState_21626608,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRepository_21626621 = ref object of OpenApiRestCall_21625435
proc url_GetRepository_21626623(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRepository_21626622(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## <p>Returns information about a repository.</p> <note> <p>The description field for a repository accepts all HTML characters and all valid Unicode characters. Applications that do not HTML-encode the description and display it in a webpage can expose users to potentially malicious code. Make sure that you HTML-encode the description field in any application that uses this API to display the repository description on a webpage.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626624 = header.getOrDefault("X-Amz-Date")
  valid_21626624 = validateParameter(valid_21626624, JString, required = false,
                                   default = nil)
  if valid_21626624 != nil:
    section.add "X-Amz-Date", valid_21626624
  var valid_21626625 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626625 = validateParameter(valid_21626625, JString, required = false,
                                   default = nil)
  if valid_21626625 != nil:
    section.add "X-Amz-Security-Token", valid_21626625
  var valid_21626626 = header.getOrDefault("X-Amz-Target")
  valid_21626626 = validateParameter(valid_21626626, JString, required = true, default = newJString(
      "CodeCommit_20150413.GetRepository"))
  if valid_21626626 != nil:
    section.add "X-Amz-Target", valid_21626626
  var valid_21626627 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626627 = validateParameter(valid_21626627, JString, required = false,
                                   default = nil)
  if valid_21626627 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626627
  var valid_21626628 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626628 = validateParameter(valid_21626628, JString, required = false,
                                   default = nil)
  if valid_21626628 != nil:
    section.add "X-Amz-Algorithm", valid_21626628
  var valid_21626629 = header.getOrDefault("X-Amz-Signature")
  valid_21626629 = validateParameter(valid_21626629, JString, required = false,
                                   default = nil)
  if valid_21626629 != nil:
    section.add "X-Amz-Signature", valid_21626629
  var valid_21626630 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626630 = validateParameter(valid_21626630, JString, required = false,
                                   default = nil)
  if valid_21626630 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626630
  var valid_21626631 = header.getOrDefault("X-Amz-Credential")
  valid_21626631 = validateParameter(valid_21626631, JString, required = false,
                                   default = nil)
  if valid_21626631 != nil:
    section.add "X-Amz-Credential", valid_21626631
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626633: Call_GetRepository_21626621; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns information about a repository.</p> <note> <p>The description field for a repository accepts all HTML characters and all valid Unicode characters. Applications that do not HTML-encode the description and display it in a webpage can expose users to potentially malicious code. Make sure that you HTML-encode the description field in any application that uses this API to display the repository description on a webpage.</p> </note>
  ## 
  let valid = call_21626633.validator(path, query, header, formData, body, _)
  let scheme = call_21626633.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626633.makeUrl(scheme.get, call_21626633.host, call_21626633.base,
                               call_21626633.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626633, uri, valid, _)

proc call*(call_21626634: Call_GetRepository_21626621; body: JsonNode): Recallable =
  ## getRepository
  ## <p>Returns information about a repository.</p> <note> <p>The description field for a repository accepts all HTML characters and all valid Unicode characters. Applications that do not HTML-encode the description and display it in a webpage can expose users to potentially malicious code. Make sure that you HTML-encode the description field in any application that uses this API to display the repository description on a webpage.</p> </note>
  ##   body: JObject (required)
  var body_21626635 = newJObject()
  if body != nil:
    body_21626635 = body
  result = call_21626634.call(nil, nil, nil, nil, body_21626635)

var getRepository* = Call_GetRepository_21626621(name: "getRepository",
    meth: HttpMethod.HttpPost, host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.GetRepository",
    validator: validate_GetRepository_21626622, base: "/",
    makeUrl: url_GetRepository_21626623, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRepositoryTriggers_21626636 = ref object of OpenApiRestCall_21625435
proc url_GetRepositoryTriggers_21626638(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRepositoryTriggers_21626637(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Gets information about triggers configured for a repository.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626639 = header.getOrDefault("X-Amz-Date")
  valid_21626639 = validateParameter(valid_21626639, JString, required = false,
                                   default = nil)
  if valid_21626639 != nil:
    section.add "X-Amz-Date", valid_21626639
  var valid_21626640 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626640 = validateParameter(valid_21626640, JString, required = false,
                                   default = nil)
  if valid_21626640 != nil:
    section.add "X-Amz-Security-Token", valid_21626640
  var valid_21626641 = header.getOrDefault("X-Amz-Target")
  valid_21626641 = validateParameter(valid_21626641, JString, required = true, default = newJString(
      "CodeCommit_20150413.GetRepositoryTriggers"))
  if valid_21626641 != nil:
    section.add "X-Amz-Target", valid_21626641
  var valid_21626642 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626642 = validateParameter(valid_21626642, JString, required = false,
                                   default = nil)
  if valid_21626642 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626642
  var valid_21626643 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626643 = validateParameter(valid_21626643, JString, required = false,
                                   default = nil)
  if valid_21626643 != nil:
    section.add "X-Amz-Algorithm", valid_21626643
  var valid_21626644 = header.getOrDefault("X-Amz-Signature")
  valid_21626644 = validateParameter(valid_21626644, JString, required = false,
                                   default = nil)
  if valid_21626644 != nil:
    section.add "X-Amz-Signature", valid_21626644
  var valid_21626645 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626645 = validateParameter(valid_21626645, JString, required = false,
                                   default = nil)
  if valid_21626645 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626645
  var valid_21626646 = header.getOrDefault("X-Amz-Credential")
  valid_21626646 = validateParameter(valid_21626646, JString, required = false,
                                   default = nil)
  if valid_21626646 != nil:
    section.add "X-Amz-Credential", valid_21626646
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626648: Call_GetRepositoryTriggers_21626636;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets information about triggers configured for a repository.
  ## 
  let valid = call_21626648.validator(path, query, header, formData, body, _)
  let scheme = call_21626648.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626648.makeUrl(scheme.get, call_21626648.host, call_21626648.base,
                               call_21626648.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626648, uri, valid, _)

proc call*(call_21626649: Call_GetRepositoryTriggers_21626636; body: JsonNode): Recallable =
  ## getRepositoryTriggers
  ## Gets information about triggers configured for a repository.
  ##   body: JObject (required)
  var body_21626650 = newJObject()
  if body != nil:
    body_21626650 = body
  result = call_21626649.call(nil, nil, nil, nil, body_21626650)

var getRepositoryTriggers* = Call_GetRepositoryTriggers_21626636(
    name: "getRepositoryTriggers", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.GetRepositoryTriggers",
    validator: validate_GetRepositoryTriggers_21626637, base: "/",
    makeUrl: url_GetRepositoryTriggers_21626638,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListApprovalRuleTemplates_21626651 = ref object of OpenApiRestCall_21625435
proc url_ListApprovalRuleTemplates_21626653(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListApprovalRuleTemplates_21626652(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Lists all approval rule templates in the specified AWS Region in your AWS account. If an AWS Region is not specified, the AWS Region where you are signed in is used.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JString
  ##             : Pagination limit
  ##   nextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_21626654 = query.getOrDefault("maxResults")
  valid_21626654 = validateParameter(valid_21626654, JString, required = false,
                                   default = nil)
  if valid_21626654 != nil:
    section.add "maxResults", valid_21626654
  var valid_21626655 = query.getOrDefault("nextToken")
  valid_21626655 = validateParameter(valid_21626655, JString, required = false,
                                   default = nil)
  if valid_21626655 != nil:
    section.add "nextToken", valid_21626655
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626656 = header.getOrDefault("X-Amz-Date")
  valid_21626656 = validateParameter(valid_21626656, JString, required = false,
                                   default = nil)
  if valid_21626656 != nil:
    section.add "X-Amz-Date", valid_21626656
  var valid_21626657 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626657 = validateParameter(valid_21626657, JString, required = false,
                                   default = nil)
  if valid_21626657 != nil:
    section.add "X-Amz-Security-Token", valid_21626657
  var valid_21626658 = header.getOrDefault("X-Amz-Target")
  valid_21626658 = validateParameter(valid_21626658, JString, required = true, default = newJString(
      "CodeCommit_20150413.ListApprovalRuleTemplates"))
  if valid_21626658 != nil:
    section.add "X-Amz-Target", valid_21626658
  var valid_21626659 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626659 = validateParameter(valid_21626659, JString, required = false,
                                   default = nil)
  if valid_21626659 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626659
  var valid_21626660 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626660 = validateParameter(valid_21626660, JString, required = false,
                                   default = nil)
  if valid_21626660 != nil:
    section.add "X-Amz-Algorithm", valid_21626660
  var valid_21626661 = header.getOrDefault("X-Amz-Signature")
  valid_21626661 = validateParameter(valid_21626661, JString, required = false,
                                   default = nil)
  if valid_21626661 != nil:
    section.add "X-Amz-Signature", valid_21626661
  var valid_21626662 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626662 = validateParameter(valid_21626662, JString, required = false,
                                   default = nil)
  if valid_21626662 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626662
  var valid_21626663 = header.getOrDefault("X-Amz-Credential")
  valid_21626663 = validateParameter(valid_21626663, JString, required = false,
                                   default = nil)
  if valid_21626663 != nil:
    section.add "X-Amz-Credential", valid_21626663
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626665: Call_ListApprovalRuleTemplates_21626651;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists all approval rule templates in the specified AWS Region in your AWS account. If an AWS Region is not specified, the AWS Region where you are signed in is used.
  ## 
  let valid = call_21626665.validator(path, query, header, formData, body, _)
  let scheme = call_21626665.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626665.makeUrl(scheme.get, call_21626665.host, call_21626665.base,
                               call_21626665.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626665, uri, valid, _)

proc call*(call_21626666: Call_ListApprovalRuleTemplates_21626651; body: JsonNode;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## listApprovalRuleTemplates
  ## Lists all approval rule templates in the specified AWS Region in your AWS account. If an AWS Region is not specified, the AWS Region where you are signed in is used.
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_21626667 = newJObject()
  var body_21626668 = newJObject()
  add(query_21626667, "maxResults", newJString(maxResults))
  add(query_21626667, "nextToken", newJString(nextToken))
  if body != nil:
    body_21626668 = body
  result = call_21626666.call(nil, query_21626667, nil, nil, body_21626668)

var listApprovalRuleTemplates* = Call_ListApprovalRuleTemplates_21626651(
    name: "listApprovalRuleTemplates", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.ListApprovalRuleTemplates",
    validator: validate_ListApprovalRuleTemplates_21626652, base: "/",
    makeUrl: url_ListApprovalRuleTemplates_21626653,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAssociatedApprovalRuleTemplatesForRepository_21626669 = ref object of OpenApiRestCall_21625435
proc url_ListAssociatedApprovalRuleTemplatesForRepository_21626671(
    protocol: Scheme; host: string; base: string; route: string; path: JsonNode;
    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListAssociatedApprovalRuleTemplatesForRepository_21626670(
    path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Lists all approval rule templates that are associated with a specified repository.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JString
  ##             : Pagination limit
  ##   nextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_21626672 = query.getOrDefault("maxResults")
  valid_21626672 = validateParameter(valid_21626672, JString, required = false,
                                   default = nil)
  if valid_21626672 != nil:
    section.add "maxResults", valid_21626672
  var valid_21626673 = query.getOrDefault("nextToken")
  valid_21626673 = validateParameter(valid_21626673, JString, required = false,
                                   default = nil)
  if valid_21626673 != nil:
    section.add "nextToken", valid_21626673
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626674 = header.getOrDefault("X-Amz-Date")
  valid_21626674 = validateParameter(valid_21626674, JString, required = false,
                                   default = nil)
  if valid_21626674 != nil:
    section.add "X-Amz-Date", valid_21626674
  var valid_21626675 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626675 = validateParameter(valid_21626675, JString, required = false,
                                   default = nil)
  if valid_21626675 != nil:
    section.add "X-Amz-Security-Token", valid_21626675
  var valid_21626676 = header.getOrDefault("X-Amz-Target")
  valid_21626676 = validateParameter(valid_21626676, JString, required = true, default = newJString(
      "CodeCommit_20150413.ListAssociatedApprovalRuleTemplatesForRepository"))
  if valid_21626676 != nil:
    section.add "X-Amz-Target", valid_21626676
  var valid_21626677 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626677 = validateParameter(valid_21626677, JString, required = false,
                                   default = nil)
  if valid_21626677 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626677
  var valid_21626678 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626678 = validateParameter(valid_21626678, JString, required = false,
                                   default = nil)
  if valid_21626678 != nil:
    section.add "X-Amz-Algorithm", valid_21626678
  var valid_21626679 = header.getOrDefault("X-Amz-Signature")
  valid_21626679 = validateParameter(valid_21626679, JString, required = false,
                                   default = nil)
  if valid_21626679 != nil:
    section.add "X-Amz-Signature", valid_21626679
  var valid_21626680 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626680 = validateParameter(valid_21626680, JString, required = false,
                                   default = nil)
  if valid_21626680 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626680
  var valid_21626681 = header.getOrDefault("X-Amz-Credential")
  valid_21626681 = validateParameter(valid_21626681, JString, required = false,
                                   default = nil)
  if valid_21626681 != nil:
    section.add "X-Amz-Credential", valid_21626681
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626683: Call_ListAssociatedApprovalRuleTemplatesForRepository_21626669;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists all approval rule templates that are associated with a specified repository.
  ## 
  let valid = call_21626683.validator(path, query, header, formData, body, _)
  let scheme = call_21626683.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626683.makeUrl(scheme.get, call_21626683.host, call_21626683.base,
                               call_21626683.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626683, uri, valid, _)

proc call*(call_21626684: Call_ListAssociatedApprovalRuleTemplatesForRepository_21626669;
          body: JsonNode; maxResults: string = ""; nextToken: string = ""): Recallable =
  ## listAssociatedApprovalRuleTemplatesForRepository
  ## Lists all approval rule templates that are associated with a specified repository.
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_21626685 = newJObject()
  var body_21626686 = newJObject()
  add(query_21626685, "maxResults", newJString(maxResults))
  add(query_21626685, "nextToken", newJString(nextToken))
  if body != nil:
    body_21626686 = body
  result = call_21626684.call(nil, query_21626685, nil, nil, body_21626686)

var listAssociatedApprovalRuleTemplatesForRepository* = Call_ListAssociatedApprovalRuleTemplatesForRepository_21626669(
    name: "listAssociatedApprovalRuleTemplatesForRepository",
    meth: HttpMethod.HttpPost, host: "codecommit.amazonaws.com", route: "/#X-Amz-Target=CodeCommit_20150413.ListAssociatedApprovalRuleTemplatesForRepository",
    validator: validate_ListAssociatedApprovalRuleTemplatesForRepository_21626670,
    base: "/", makeUrl: url_ListAssociatedApprovalRuleTemplatesForRepository_21626671,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBranches_21626687 = ref object of OpenApiRestCall_21625435
proc url_ListBranches_21626689(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListBranches_21626688(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Gets information about one or more branches in a repository.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_21626690 = query.getOrDefault("nextToken")
  valid_21626690 = validateParameter(valid_21626690, JString, required = false,
                                   default = nil)
  if valid_21626690 != nil:
    section.add "nextToken", valid_21626690
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626691 = header.getOrDefault("X-Amz-Date")
  valid_21626691 = validateParameter(valid_21626691, JString, required = false,
                                   default = nil)
  if valid_21626691 != nil:
    section.add "X-Amz-Date", valid_21626691
  var valid_21626692 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626692 = validateParameter(valid_21626692, JString, required = false,
                                   default = nil)
  if valid_21626692 != nil:
    section.add "X-Amz-Security-Token", valid_21626692
  var valid_21626693 = header.getOrDefault("X-Amz-Target")
  valid_21626693 = validateParameter(valid_21626693, JString, required = true, default = newJString(
      "CodeCommit_20150413.ListBranches"))
  if valid_21626693 != nil:
    section.add "X-Amz-Target", valid_21626693
  var valid_21626694 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626694 = validateParameter(valid_21626694, JString, required = false,
                                   default = nil)
  if valid_21626694 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626694
  var valid_21626695 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626695 = validateParameter(valid_21626695, JString, required = false,
                                   default = nil)
  if valid_21626695 != nil:
    section.add "X-Amz-Algorithm", valid_21626695
  var valid_21626696 = header.getOrDefault("X-Amz-Signature")
  valid_21626696 = validateParameter(valid_21626696, JString, required = false,
                                   default = nil)
  if valid_21626696 != nil:
    section.add "X-Amz-Signature", valid_21626696
  var valid_21626697 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626697 = validateParameter(valid_21626697, JString, required = false,
                                   default = nil)
  if valid_21626697 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626697
  var valid_21626698 = header.getOrDefault("X-Amz-Credential")
  valid_21626698 = validateParameter(valid_21626698, JString, required = false,
                                   default = nil)
  if valid_21626698 != nil:
    section.add "X-Amz-Credential", valid_21626698
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626700: Call_ListBranches_21626687; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets information about one or more branches in a repository.
  ## 
  let valid = call_21626700.validator(path, query, header, formData, body, _)
  let scheme = call_21626700.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626700.makeUrl(scheme.get, call_21626700.host, call_21626700.base,
                               call_21626700.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626700, uri, valid, _)

proc call*(call_21626701: Call_ListBranches_21626687; body: JsonNode;
          nextToken: string = ""): Recallable =
  ## listBranches
  ## Gets information about one or more branches in a repository.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_21626702 = newJObject()
  var body_21626703 = newJObject()
  add(query_21626702, "nextToken", newJString(nextToken))
  if body != nil:
    body_21626703 = body
  result = call_21626701.call(nil, query_21626702, nil, nil, body_21626703)

var listBranches* = Call_ListBranches_21626687(name: "listBranches",
    meth: HttpMethod.HttpPost, host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.ListBranches",
    validator: validate_ListBranches_21626688, base: "/", makeUrl: url_ListBranches_21626689,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPullRequests_21626704 = ref object of OpenApiRestCall_21625435
proc url_ListPullRequests_21626706(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListPullRequests_21626705(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns a list of pull requests for a specified repository. The return list can be refined by pull request status or pull request author ARN.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JString
  ##             : Pagination limit
  ##   nextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_21626707 = query.getOrDefault("maxResults")
  valid_21626707 = validateParameter(valid_21626707, JString, required = false,
                                   default = nil)
  if valid_21626707 != nil:
    section.add "maxResults", valid_21626707
  var valid_21626708 = query.getOrDefault("nextToken")
  valid_21626708 = validateParameter(valid_21626708, JString, required = false,
                                   default = nil)
  if valid_21626708 != nil:
    section.add "nextToken", valid_21626708
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626709 = header.getOrDefault("X-Amz-Date")
  valid_21626709 = validateParameter(valid_21626709, JString, required = false,
                                   default = nil)
  if valid_21626709 != nil:
    section.add "X-Amz-Date", valid_21626709
  var valid_21626710 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626710 = validateParameter(valid_21626710, JString, required = false,
                                   default = nil)
  if valid_21626710 != nil:
    section.add "X-Amz-Security-Token", valid_21626710
  var valid_21626711 = header.getOrDefault("X-Amz-Target")
  valid_21626711 = validateParameter(valid_21626711, JString, required = true, default = newJString(
      "CodeCommit_20150413.ListPullRequests"))
  if valid_21626711 != nil:
    section.add "X-Amz-Target", valid_21626711
  var valid_21626712 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626712 = validateParameter(valid_21626712, JString, required = false,
                                   default = nil)
  if valid_21626712 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626712
  var valid_21626713 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626713 = validateParameter(valid_21626713, JString, required = false,
                                   default = nil)
  if valid_21626713 != nil:
    section.add "X-Amz-Algorithm", valid_21626713
  var valid_21626714 = header.getOrDefault("X-Amz-Signature")
  valid_21626714 = validateParameter(valid_21626714, JString, required = false,
                                   default = nil)
  if valid_21626714 != nil:
    section.add "X-Amz-Signature", valid_21626714
  var valid_21626715 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626715 = validateParameter(valid_21626715, JString, required = false,
                                   default = nil)
  if valid_21626715 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626715
  var valid_21626716 = header.getOrDefault("X-Amz-Credential")
  valid_21626716 = validateParameter(valid_21626716, JString, required = false,
                                   default = nil)
  if valid_21626716 != nil:
    section.add "X-Amz-Credential", valid_21626716
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626718: Call_ListPullRequests_21626704; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a list of pull requests for a specified repository. The return list can be refined by pull request status or pull request author ARN.
  ## 
  let valid = call_21626718.validator(path, query, header, formData, body, _)
  let scheme = call_21626718.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626718.makeUrl(scheme.get, call_21626718.host, call_21626718.base,
                               call_21626718.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626718, uri, valid, _)

proc call*(call_21626719: Call_ListPullRequests_21626704; body: JsonNode;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## listPullRequests
  ## Returns a list of pull requests for a specified repository. The return list can be refined by pull request status or pull request author ARN.
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_21626720 = newJObject()
  var body_21626721 = newJObject()
  add(query_21626720, "maxResults", newJString(maxResults))
  add(query_21626720, "nextToken", newJString(nextToken))
  if body != nil:
    body_21626721 = body
  result = call_21626719.call(nil, query_21626720, nil, nil, body_21626721)

var listPullRequests* = Call_ListPullRequests_21626704(name: "listPullRequests",
    meth: HttpMethod.HttpPost, host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.ListPullRequests",
    validator: validate_ListPullRequests_21626705, base: "/",
    makeUrl: url_ListPullRequests_21626706, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRepositories_21626722 = ref object of OpenApiRestCall_21625435
proc url_ListRepositories_21626724(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListRepositories_21626723(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Gets information about one or more repositories.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_21626725 = query.getOrDefault("nextToken")
  valid_21626725 = validateParameter(valid_21626725, JString, required = false,
                                   default = nil)
  if valid_21626725 != nil:
    section.add "nextToken", valid_21626725
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626726 = header.getOrDefault("X-Amz-Date")
  valid_21626726 = validateParameter(valid_21626726, JString, required = false,
                                   default = nil)
  if valid_21626726 != nil:
    section.add "X-Amz-Date", valid_21626726
  var valid_21626727 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626727 = validateParameter(valid_21626727, JString, required = false,
                                   default = nil)
  if valid_21626727 != nil:
    section.add "X-Amz-Security-Token", valid_21626727
  var valid_21626728 = header.getOrDefault("X-Amz-Target")
  valid_21626728 = validateParameter(valid_21626728, JString, required = true, default = newJString(
      "CodeCommit_20150413.ListRepositories"))
  if valid_21626728 != nil:
    section.add "X-Amz-Target", valid_21626728
  var valid_21626729 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626729 = validateParameter(valid_21626729, JString, required = false,
                                   default = nil)
  if valid_21626729 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626729
  var valid_21626730 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626730 = validateParameter(valid_21626730, JString, required = false,
                                   default = nil)
  if valid_21626730 != nil:
    section.add "X-Amz-Algorithm", valid_21626730
  var valid_21626731 = header.getOrDefault("X-Amz-Signature")
  valid_21626731 = validateParameter(valid_21626731, JString, required = false,
                                   default = nil)
  if valid_21626731 != nil:
    section.add "X-Amz-Signature", valid_21626731
  var valid_21626732 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626732 = validateParameter(valid_21626732, JString, required = false,
                                   default = nil)
  if valid_21626732 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626732
  var valid_21626733 = header.getOrDefault("X-Amz-Credential")
  valid_21626733 = validateParameter(valid_21626733, JString, required = false,
                                   default = nil)
  if valid_21626733 != nil:
    section.add "X-Amz-Credential", valid_21626733
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626735: Call_ListRepositories_21626722; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets information about one or more repositories.
  ## 
  let valid = call_21626735.validator(path, query, header, formData, body, _)
  let scheme = call_21626735.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626735.makeUrl(scheme.get, call_21626735.host, call_21626735.base,
                               call_21626735.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626735, uri, valid, _)

proc call*(call_21626736: Call_ListRepositories_21626722; body: JsonNode;
          nextToken: string = ""): Recallable =
  ## listRepositories
  ## Gets information about one or more repositories.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_21626737 = newJObject()
  var body_21626738 = newJObject()
  add(query_21626737, "nextToken", newJString(nextToken))
  if body != nil:
    body_21626738 = body
  result = call_21626736.call(nil, query_21626737, nil, nil, body_21626738)

var listRepositories* = Call_ListRepositories_21626722(name: "listRepositories",
    meth: HttpMethod.HttpPost, host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.ListRepositories",
    validator: validate_ListRepositories_21626723, base: "/",
    makeUrl: url_ListRepositories_21626724, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRepositoriesForApprovalRuleTemplate_21626739 = ref object of OpenApiRestCall_21625435
proc url_ListRepositoriesForApprovalRuleTemplate_21626741(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListRepositoriesForApprovalRuleTemplate_21626740(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Lists all repositories associated with the specified approval rule template.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JString
  ##             : Pagination limit
  ##   nextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_21626742 = query.getOrDefault("maxResults")
  valid_21626742 = validateParameter(valid_21626742, JString, required = false,
                                   default = nil)
  if valid_21626742 != nil:
    section.add "maxResults", valid_21626742
  var valid_21626743 = query.getOrDefault("nextToken")
  valid_21626743 = validateParameter(valid_21626743, JString, required = false,
                                   default = nil)
  if valid_21626743 != nil:
    section.add "nextToken", valid_21626743
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626744 = header.getOrDefault("X-Amz-Date")
  valid_21626744 = validateParameter(valid_21626744, JString, required = false,
                                   default = nil)
  if valid_21626744 != nil:
    section.add "X-Amz-Date", valid_21626744
  var valid_21626745 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626745 = validateParameter(valid_21626745, JString, required = false,
                                   default = nil)
  if valid_21626745 != nil:
    section.add "X-Amz-Security-Token", valid_21626745
  var valid_21626746 = header.getOrDefault("X-Amz-Target")
  valid_21626746 = validateParameter(valid_21626746, JString, required = true, default = newJString(
      "CodeCommit_20150413.ListRepositoriesForApprovalRuleTemplate"))
  if valid_21626746 != nil:
    section.add "X-Amz-Target", valid_21626746
  var valid_21626747 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626747 = validateParameter(valid_21626747, JString, required = false,
                                   default = nil)
  if valid_21626747 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626747
  var valid_21626748 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626748 = validateParameter(valid_21626748, JString, required = false,
                                   default = nil)
  if valid_21626748 != nil:
    section.add "X-Amz-Algorithm", valid_21626748
  var valid_21626749 = header.getOrDefault("X-Amz-Signature")
  valid_21626749 = validateParameter(valid_21626749, JString, required = false,
                                   default = nil)
  if valid_21626749 != nil:
    section.add "X-Amz-Signature", valid_21626749
  var valid_21626750 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626750 = validateParameter(valid_21626750, JString, required = false,
                                   default = nil)
  if valid_21626750 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626750
  var valid_21626751 = header.getOrDefault("X-Amz-Credential")
  valid_21626751 = validateParameter(valid_21626751, JString, required = false,
                                   default = nil)
  if valid_21626751 != nil:
    section.add "X-Amz-Credential", valid_21626751
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626753: Call_ListRepositoriesForApprovalRuleTemplate_21626739;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists all repositories associated with the specified approval rule template.
  ## 
  let valid = call_21626753.validator(path, query, header, formData, body, _)
  let scheme = call_21626753.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626753.makeUrl(scheme.get, call_21626753.host, call_21626753.base,
                               call_21626753.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626753, uri, valid, _)

proc call*(call_21626754: Call_ListRepositoriesForApprovalRuleTemplate_21626739;
          body: JsonNode; maxResults: string = ""; nextToken: string = ""): Recallable =
  ## listRepositoriesForApprovalRuleTemplate
  ## Lists all repositories associated with the specified approval rule template.
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_21626755 = newJObject()
  var body_21626756 = newJObject()
  add(query_21626755, "maxResults", newJString(maxResults))
  add(query_21626755, "nextToken", newJString(nextToken))
  if body != nil:
    body_21626756 = body
  result = call_21626754.call(nil, query_21626755, nil, nil, body_21626756)

var listRepositoriesForApprovalRuleTemplate* = Call_ListRepositoriesForApprovalRuleTemplate_21626739(
    name: "listRepositoriesForApprovalRuleTemplate", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com", route: "/#X-Amz-Target=CodeCommit_20150413.ListRepositoriesForApprovalRuleTemplate",
    validator: validate_ListRepositoriesForApprovalRuleTemplate_21626740,
    base: "/", makeUrl: url_ListRepositoriesForApprovalRuleTemplate_21626741,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_21626757 = ref object of OpenApiRestCall_21625435
proc url_ListTagsForResource_21626759(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTagsForResource_21626758(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Gets information about AWS tags for a specified Amazon Resource Name (ARN) in AWS CodeCommit. For a list of valid resources in AWS CodeCommit, see <a href="https://docs.aws.amazon.com/codecommit/latest/userguide/auth-and-access-control-iam-access-control-identity-based.html#arn-formats">CodeCommit Resources and Operations</a> in the<i> AWS CodeCommit User Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626760 = header.getOrDefault("X-Amz-Date")
  valid_21626760 = validateParameter(valid_21626760, JString, required = false,
                                   default = nil)
  if valid_21626760 != nil:
    section.add "X-Amz-Date", valid_21626760
  var valid_21626761 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626761 = validateParameter(valid_21626761, JString, required = false,
                                   default = nil)
  if valid_21626761 != nil:
    section.add "X-Amz-Security-Token", valid_21626761
  var valid_21626762 = header.getOrDefault("X-Amz-Target")
  valid_21626762 = validateParameter(valid_21626762, JString, required = true, default = newJString(
      "CodeCommit_20150413.ListTagsForResource"))
  if valid_21626762 != nil:
    section.add "X-Amz-Target", valid_21626762
  var valid_21626763 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626763 = validateParameter(valid_21626763, JString, required = false,
                                   default = nil)
  if valid_21626763 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626763
  var valid_21626764 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626764 = validateParameter(valid_21626764, JString, required = false,
                                   default = nil)
  if valid_21626764 != nil:
    section.add "X-Amz-Algorithm", valid_21626764
  var valid_21626765 = header.getOrDefault("X-Amz-Signature")
  valid_21626765 = validateParameter(valid_21626765, JString, required = false,
                                   default = nil)
  if valid_21626765 != nil:
    section.add "X-Amz-Signature", valid_21626765
  var valid_21626766 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626766 = validateParameter(valid_21626766, JString, required = false,
                                   default = nil)
  if valid_21626766 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626766
  var valid_21626767 = header.getOrDefault("X-Amz-Credential")
  valid_21626767 = validateParameter(valid_21626767, JString, required = false,
                                   default = nil)
  if valid_21626767 != nil:
    section.add "X-Amz-Credential", valid_21626767
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626769: Call_ListTagsForResource_21626757; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets information about AWS tags for a specified Amazon Resource Name (ARN) in AWS CodeCommit. For a list of valid resources in AWS CodeCommit, see <a href="https://docs.aws.amazon.com/codecommit/latest/userguide/auth-and-access-control-iam-access-control-identity-based.html#arn-formats">CodeCommit Resources and Operations</a> in the<i> AWS CodeCommit User Guide</i>.
  ## 
  let valid = call_21626769.validator(path, query, header, formData, body, _)
  let scheme = call_21626769.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626769.makeUrl(scheme.get, call_21626769.host, call_21626769.base,
                               call_21626769.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626769, uri, valid, _)

proc call*(call_21626770: Call_ListTagsForResource_21626757; body: JsonNode): Recallable =
  ## listTagsForResource
  ## Gets information about AWS tags for a specified Amazon Resource Name (ARN) in AWS CodeCommit. For a list of valid resources in AWS CodeCommit, see <a href="https://docs.aws.amazon.com/codecommit/latest/userguide/auth-and-access-control-iam-access-control-identity-based.html#arn-formats">CodeCommit Resources and Operations</a> in the<i> AWS CodeCommit User Guide</i>.
  ##   body: JObject (required)
  var body_21626771 = newJObject()
  if body != nil:
    body_21626771 = body
  result = call_21626770.call(nil, nil, nil, nil, body_21626771)

var listTagsForResource* = Call_ListTagsForResource_21626757(
    name: "listTagsForResource", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.ListTagsForResource",
    validator: validate_ListTagsForResource_21626758, base: "/",
    makeUrl: url_ListTagsForResource_21626759,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_MergeBranchesByFastForward_21626772 = ref object of OpenApiRestCall_21625435
proc url_MergeBranchesByFastForward_21626774(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_MergeBranchesByFastForward_21626773(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Merges two branches using the fast-forward merge strategy.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626775 = header.getOrDefault("X-Amz-Date")
  valid_21626775 = validateParameter(valid_21626775, JString, required = false,
                                   default = nil)
  if valid_21626775 != nil:
    section.add "X-Amz-Date", valid_21626775
  var valid_21626776 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626776 = validateParameter(valid_21626776, JString, required = false,
                                   default = nil)
  if valid_21626776 != nil:
    section.add "X-Amz-Security-Token", valid_21626776
  var valid_21626777 = header.getOrDefault("X-Amz-Target")
  valid_21626777 = validateParameter(valid_21626777, JString, required = true, default = newJString(
      "CodeCommit_20150413.MergeBranchesByFastForward"))
  if valid_21626777 != nil:
    section.add "X-Amz-Target", valid_21626777
  var valid_21626778 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626778 = validateParameter(valid_21626778, JString, required = false,
                                   default = nil)
  if valid_21626778 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626778
  var valid_21626779 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626779 = validateParameter(valid_21626779, JString, required = false,
                                   default = nil)
  if valid_21626779 != nil:
    section.add "X-Amz-Algorithm", valid_21626779
  var valid_21626780 = header.getOrDefault("X-Amz-Signature")
  valid_21626780 = validateParameter(valid_21626780, JString, required = false,
                                   default = nil)
  if valid_21626780 != nil:
    section.add "X-Amz-Signature", valid_21626780
  var valid_21626781 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626781 = validateParameter(valid_21626781, JString, required = false,
                                   default = nil)
  if valid_21626781 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626781
  var valid_21626782 = header.getOrDefault("X-Amz-Credential")
  valid_21626782 = validateParameter(valid_21626782, JString, required = false,
                                   default = nil)
  if valid_21626782 != nil:
    section.add "X-Amz-Credential", valid_21626782
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626784: Call_MergeBranchesByFastForward_21626772;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Merges two branches using the fast-forward merge strategy.
  ## 
  let valid = call_21626784.validator(path, query, header, formData, body, _)
  let scheme = call_21626784.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626784.makeUrl(scheme.get, call_21626784.host, call_21626784.base,
                               call_21626784.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626784, uri, valid, _)

proc call*(call_21626785: Call_MergeBranchesByFastForward_21626772; body: JsonNode): Recallable =
  ## mergeBranchesByFastForward
  ## Merges two branches using the fast-forward merge strategy.
  ##   body: JObject (required)
  var body_21626786 = newJObject()
  if body != nil:
    body_21626786 = body
  result = call_21626785.call(nil, nil, nil, nil, body_21626786)

var mergeBranchesByFastForward* = Call_MergeBranchesByFastForward_21626772(
    name: "mergeBranchesByFastForward", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.MergeBranchesByFastForward",
    validator: validate_MergeBranchesByFastForward_21626773, base: "/",
    makeUrl: url_MergeBranchesByFastForward_21626774,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_MergeBranchesBySquash_21626787 = ref object of OpenApiRestCall_21625435
proc url_MergeBranchesBySquash_21626789(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_MergeBranchesBySquash_21626788(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Merges two branches using the squash merge strategy.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626790 = header.getOrDefault("X-Amz-Date")
  valid_21626790 = validateParameter(valid_21626790, JString, required = false,
                                   default = nil)
  if valid_21626790 != nil:
    section.add "X-Amz-Date", valid_21626790
  var valid_21626791 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626791 = validateParameter(valid_21626791, JString, required = false,
                                   default = nil)
  if valid_21626791 != nil:
    section.add "X-Amz-Security-Token", valid_21626791
  var valid_21626792 = header.getOrDefault("X-Amz-Target")
  valid_21626792 = validateParameter(valid_21626792, JString, required = true, default = newJString(
      "CodeCommit_20150413.MergeBranchesBySquash"))
  if valid_21626792 != nil:
    section.add "X-Amz-Target", valid_21626792
  var valid_21626793 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626793 = validateParameter(valid_21626793, JString, required = false,
                                   default = nil)
  if valid_21626793 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626793
  var valid_21626794 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626794 = validateParameter(valid_21626794, JString, required = false,
                                   default = nil)
  if valid_21626794 != nil:
    section.add "X-Amz-Algorithm", valid_21626794
  var valid_21626795 = header.getOrDefault("X-Amz-Signature")
  valid_21626795 = validateParameter(valid_21626795, JString, required = false,
                                   default = nil)
  if valid_21626795 != nil:
    section.add "X-Amz-Signature", valid_21626795
  var valid_21626796 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626796 = validateParameter(valid_21626796, JString, required = false,
                                   default = nil)
  if valid_21626796 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626796
  var valid_21626797 = header.getOrDefault("X-Amz-Credential")
  valid_21626797 = validateParameter(valid_21626797, JString, required = false,
                                   default = nil)
  if valid_21626797 != nil:
    section.add "X-Amz-Credential", valid_21626797
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626799: Call_MergeBranchesBySquash_21626787;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Merges two branches using the squash merge strategy.
  ## 
  let valid = call_21626799.validator(path, query, header, formData, body, _)
  let scheme = call_21626799.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626799.makeUrl(scheme.get, call_21626799.host, call_21626799.base,
                               call_21626799.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626799, uri, valid, _)

proc call*(call_21626800: Call_MergeBranchesBySquash_21626787; body: JsonNode): Recallable =
  ## mergeBranchesBySquash
  ## Merges two branches using the squash merge strategy.
  ##   body: JObject (required)
  var body_21626801 = newJObject()
  if body != nil:
    body_21626801 = body
  result = call_21626800.call(nil, nil, nil, nil, body_21626801)

var mergeBranchesBySquash* = Call_MergeBranchesBySquash_21626787(
    name: "mergeBranchesBySquash", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.MergeBranchesBySquash",
    validator: validate_MergeBranchesBySquash_21626788, base: "/",
    makeUrl: url_MergeBranchesBySquash_21626789,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_MergeBranchesByThreeWay_21626802 = ref object of OpenApiRestCall_21625435
proc url_MergeBranchesByThreeWay_21626804(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_MergeBranchesByThreeWay_21626803(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Merges two specified branches using the three-way merge strategy.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626805 = header.getOrDefault("X-Amz-Date")
  valid_21626805 = validateParameter(valid_21626805, JString, required = false,
                                   default = nil)
  if valid_21626805 != nil:
    section.add "X-Amz-Date", valid_21626805
  var valid_21626806 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626806 = validateParameter(valid_21626806, JString, required = false,
                                   default = nil)
  if valid_21626806 != nil:
    section.add "X-Amz-Security-Token", valid_21626806
  var valid_21626807 = header.getOrDefault("X-Amz-Target")
  valid_21626807 = validateParameter(valid_21626807, JString, required = true, default = newJString(
      "CodeCommit_20150413.MergeBranchesByThreeWay"))
  if valid_21626807 != nil:
    section.add "X-Amz-Target", valid_21626807
  var valid_21626808 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626808 = validateParameter(valid_21626808, JString, required = false,
                                   default = nil)
  if valid_21626808 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626808
  var valid_21626809 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626809 = validateParameter(valid_21626809, JString, required = false,
                                   default = nil)
  if valid_21626809 != nil:
    section.add "X-Amz-Algorithm", valid_21626809
  var valid_21626810 = header.getOrDefault("X-Amz-Signature")
  valid_21626810 = validateParameter(valid_21626810, JString, required = false,
                                   default = nil)
  if valid_21626810 != nil:
    section.add "X-Amz-Signature", valid_21626810
  var valid_21626811 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626811 = validateParameter(valid_21626811, JString, required = false,
                                   default = nil)
  if valid_21626811 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626811
  var valid_21626812 = header.getOrDefault("X-Amz-Credential")
  valid_21626812 = validateParameter(valid_21626812, JString, required = false,
                                   default = nil)
  if valid_21626812 != nil:
    section.add "X-Amz-Credential", valid_21626812
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626814: Call_MergeBranchesByThreeWay_21626802;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Merges two specified branches using the three-way merge strategy.
  ## 
  let valid = call_21626814.validator(path, query, header, formData, body, _)
  let scheme = call_21626814.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626814.makeUrl(scheme.get, call_21626814.host, call_21626814.base,
                               call_21626814.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626814, uri, valid, _)

proc call*(call_21626815: Call_MergeBranchesByThreeWay_21626802; body: JsonNode): Recallable =
  ## mergeBranchesByThreeWay
  ## Merges two specified branches using the three-way merge strategy.
  ##   body: JObject (required)
  var body_21626816 = newJObject()
  if body != nil:
    body_21626816 = body
  result = call_21626815.call(nil, nil, nil, nil, body_21626816)

var mergeBranchesByThreeWay* = Call_MergeBranchesByThreeWay_21626802(
    name: "mergeBranchesByThreeWay", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.MergeBranchesByThreeWay",
    validator: validate_MergeBranchesByThreeWay_21626803, base: "/",
    makeUrl: url_MergeBranchesByThreeWay_21626804,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_MergePullRequestByFastForward_21626817 = ref object of OpenApiRestCall_21625435
proc url_MergePullRequestByFastForward_21626819(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_MergePullRequestByFastForward_21626818(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Attempts to merge the source commit of a pull request into the specified destination branch for that pull request at the specified commit using the fast-forward merge strategy. If the merge is successful, it closes the pull request.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626820 = header.getOrDefault("X-Amz-Date")
  valid_21626820 = validateParameter(valid_21626820, JString, required = false,
                                   default = nil)
  if valid_21626820 != nil:
    section.add "X-Amz-Date", valid_21626820
  var valid_21626821 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626821 = validateParameter(valid_21626821, JString, required = false,
                                   default = nil)
  if valid_21626821 != nil:
    section.add "X-Amz-Security-Token", valid_21626821
  var valid_21626822 = header.getOrDefault("X-Amz-Target")
  valid_21626822 = validateParameter(valid_21626822, JString, required = true, default = newJString(
      "CodeCommit_20150413.MergePullRequestByFastForward"))
  if valid_21626822 != nil:
    section.add "X-Amz-Target", valid_21626822
  var valid_21626823 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626823 = validateParameter(valid_21626823, JString, required = false,
                                   default = nil)
  if valid_21626823 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626823
  var valid_21626824 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626824 = validateParameter(valid_21626824, JString, required = false,
                                   default = nil)
  if valid_21626824 != nil:
    section.add "X-Amz-Algorithm", valid_21626824
  var valid_21626825 = header.getOrDefault("X-Amz-Signature")
  valid_21626825 = validateParameter(valid_21626825, JString, required = false,
                                   default = nil)
  if valid_21626825 != nil:
    section.add "X-Amz-Signature", valid_21626825
  var valid_21626826 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626826 = validateParameter(valid_21626826, JString, required = false,
                                   default = nil)
  if valid_21626826 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626826
  var valid_21626827 = header.getOrDefault("X-Amz-Credential")
  valid_21626827 = validateParameter(valid_21626827, JString, required = false,
                                   default = nil)
  if valid_21626827 != nil:
    section.add "X-Amz-Credential", valid_21626827
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626829: Call_MergePullRequestByFastForward_21626817;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Attempts to merge the source commit of a pull request into the specified destination branch for that pull request at the specified commit using the fast-forward merge strategy. If the merge is successful, it closes the pull request.
  ## 
  let valid = call_21626829.validator(path, query, header, formData, body, _)
  let scheme = call_21626829.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626829.makeUrl(scheme.get, call_21626829.host, call_21626829.base,
                               call_21626829.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626829, uri, valid, _)

proc call*(call_21626830: Call_MergePullRequestByFastForward_21626817;
          body: JsonNode): Recallable =
  ## mergePullRequestByFastForward
  ## Attempts to merge the source commit of a pull request into the specified destination branch for that pull request at the specified commit using the fast-forward merge strategy. If the merge is successful, it closes the pull request.
  ##   body: JObject (required)
  var body_21626831 = newJObject()
  if body != nil:
    body_21626831 = body
  result = call_21626830.call(nil, nil, nil, nil, body_21626831)

var mergePullRequestByFastForward* = Call_MergePullRequestByFastForward_21626817(
    name: "mergePullRequestByFastForward", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.MergePullRequestByFastForward",
    validator: validate_MergePullRequestByFastForward_21626818, base: "/",
    makeUrl: url_MergePullRequestByFastForward_21626819,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_MergePullRequestBySquash_21626832 = ref object of OpenApiRestCall_21625435
proc url_MergePullRequestBySquash_21626834(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_MergePullRequestBySquash_21626833(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Attempts to merge the source commit of a pull request into the specified destination branch for that pull request at the specified commit using the squash merge strategy. If the merge is successful, it closes the pull request.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626835 = header.getOrDefault("X-Amz-Date")
  valid_21626835 = validateParameter(valid_21626835, JString, required = false,
                                   default = nil)
  if valid_21626835 != nil:
    section.add "X-Amz-Date", valid_21626835
  var valid_21626836 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626836 = validateParameter(valid_21626836, JString, required = false,
                                   default = nil)
  if valid_21626836 != nil:
    section.add "X-Amz-Security-Token", valid_21626836
  var valid_21626837 = header.getOrDefault("X-Amz-Target")
  valid_21626837 = validateParameter(valid_21626837, JString, required = true, default = newJString(
      "CodeCommit_20150413.MergePullRequestBySquash"))
  if valid_21626837 != nil:
    section.add "X-Amz-Target", valid_21626837
  var valid_21626838 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626838 = validateParameter(valid_21626838, JString, required = false,
                                   default = nil)
  if valid_21626838 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626838
  var valid_21626839 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626839 = validateParameter(valid_21626839, JString, required = false,
                                   default = nil)
  if valid_21626839 != nil:
    section.add "X-Amz-Algorithm", valid_21626839
  var valid_21626840 = header.getOrDefault("X-Amz-Signature")
  valid_21626840 = validateParameter(valid_21626840, JString, required = false,
                                   default = nil)
  if valid_21626840 != nil:
    section.add "X-Amz-Signature", valid_21626840
  var valid_21626841 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626841 = validateParameter(valid_21626841, JString, required = false,
                                   default = nil)
  if valid_21626841 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626841
  var valid_21626842 = header.getOrDefault("X-Amz-Credential")
  valid_21626842 = validateParameter(valid_21626842, JString, required = false,
                                   default = nil)
  if valid_21626842 != nil:
    section.add "X-Amz-Credential", valid_21626842
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626844: Call_MergePullRequestBySquash_21626832;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Attempts to merge the source commit of a pull request into the specified destination branch for that pull request at the specified commit using the squash merge strategy. If the merge is successful, it closes the pull request.
  ## 
  let valid = call_21626844.validator(path, query, header, formData, body, _)
  let scheme = call_21626844.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626844.makeUrl(scheme.get, call_21626844.host, call_21626844.base,
                               call_21626844.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626844, uri, valid, _)

proc call*(call_21626845: Call_MergePullRequestBySquash_21626832; body: JsonNode): Recallable =
  ## mergePullRequestBySquash
  ## Attempts to merge the source commit of a pull request into the specified destination branch for that pull request at the specified commit using the squash merge strategy. If the merge is successful, it closes the pull request.
  ##   body: JObject (required)
  var body_21626846 = newJObject()
  if body != nil:
    body_21626846 = body
  result = call_21626845.call(nil, nil, nil, nil, body_21626846)

var mergePullRequestBySquash* = Call_MergePullRequestBySquash_21626832(
    name: "mergePullRequestBySquash", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.MergePullRequestBySquash",
    validator: validate_MergePullRequestBySquash_21626833, base: "/",
    makeUrl: url_MergePullRequestBySquash_21626834,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_MergePullRequestByThreeWay_21626847 = ref object of OpenApiRestCall_21625435
proc url_MergePullRequestByThreeWay_21626849(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_MergePullRequestByThreeWay_21626848(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Attempts to merge the source commit of a pull request into the specified destination branch for that pull request at the specified commit using the three-way merge strategy. If the merge is successful, it closes the pull request.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626850 = header.getOrDefault("X-Amz-Date")
  valid_21626850 = validateParameter(valid_21626850, JString, required = false,
                                   default = nil)
  if valid_21626850 != nil:
    section.add "X-Amz-Date", valid_21626850
  var valid_21626851 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626851 = validateParameter(valid_21626851, JString, required = false,
                                   default = nil)
  if valid_21626851 != nil:
    section.add "X-Amz-Security-Token", valid_21626851
  var valid_21626852 = header.getOrDefault("X-Amz-Target")
  valid_21626852 = validateParameter(valid_21626852, JString, required = true, default = newJString(
      "CodeCommit_20150413.MergePullRequestByThreeWay"))
  if valid_21626852 != nil:
    section.add "X-Amz-Target", valid_21626852
  var valid_21626853 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626853 = validateParameter(valid_21626853, JString, required = false,
                                   default = nil)
  if valid_21626853 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626853
  var valid_21626854 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626854 = validateParameter(valid_21626854, JString, required = false,
                                   default = nil)
  if valid_21626854 != nil:
    section.add "X-Amz-Algorithm", valid_21626854
  var valid_21626855 = header.getOrDefault("X-Amz-Signature")
  valid_21626855 = validateParameter(valid_21626855, JString, required = false,
                                   default = nil)
  if valid_21626855 != nil:
    section.add "X-Amz-Signature", valid_21626855
  var valid_21626856 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626856 = validateParameter(valid_21626856, JString, required = false,
                                   default = nil)
  if valid_21626856 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626856
  var valid_21626857 = header.getOrDefault("X-Amz-Credential")
  valid_21626857 = validateParameter(valid_21626857, JString, required = false,
                                   default = nil)
  if valid_21626857 != nil:
    section.add "X-Amz-Credential", valid_21626857
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626859: Call_MergePullRequestByThreeWay_21626847;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Attempts to merge the source commit of a pull request into the specified destination branch for that pull request at the specified commit using the three-way merge strategy. If the merge is successful, it closes the pull request.
  ## 
  let valid = call_21626859.validator(path, query, header, formData, body, _)
  let scheme = call_21626859.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626859.makeUrl(scheme.get, call_21626859.host, call_21626859.base,
                               call_21626859.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626859, uri, valid, _)

proc call*(call_21626860: Call_MergePullRequestByThreeWay_21626847; body: JsonNode): Recallable =
  ## mergePullRequestByThreeWay
  ## Attempts to merge the source commit of a pull request into the specified destination branch for that pull request at the specified commit using the three-way merge strategy. If the merge is successful, it closes the pull request.
  ##   body: JObject (required)
  var body_21626861 = newJObject()
  if body != nil:
    body_21626861 = body
  result = call_21626860.call(nil, nil, nil, nil, body_21626861)

var mergePullRequestByThreeWay* = Call_MergePullRequestByThreeWay_21626847(
    name: "mergePullRequestByThreeWay", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.MergePullRequestByThreeWay",
    validator: validate_MergePullRequestByThreeWay_21626848, base: "/",
    makeUrl: url_MergePullRequestByThreeWay_21626849,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_OverridePullRequestApprovalRules_21626862 = ref object of OpenApiRestCall_21625435
proc url_OverridePullRequestApprovalRules_21626864(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_OverridePullRequestApprovalRules_21626863(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Sets aside (overrides) all approval rule requirements for a specified pull request.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626865 = header.getOrDefault("X-Amz-Date")
  valid_21626865 = validateParameter(valid_21626865, JString, required = false,
                                   default = nil)
  if valid_21626865 != nil:
    section.add "X-Amz-Date", valid_21626865
  var valid_21626866 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626866 = validateParameter(valid_21626866, JString, required = false,
                                   default = nil)
  if valid_21626866 != nil:
    section.add "X-Amz-Security-Token", valid_21626866
  var valid_21626867 = header.getOrDefault("X-Amz-Target")
  valid_21626867 = validateParameter(valid_21626867, JString, required = true, default = newJString(
      "CodeCommit_20150413.OverridePullRequestApprovalRules"))
  if valid_21626867 != nil:
    section.add "X-Amz-Target", valid_21626867
  var valid_21626868 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626868 = validateParameter(valid_21626868, JString, required = false,
                                   default = nil)
  if valid_21626868 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626868
  var valid_21626869 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626869 = validateParameter(valid_21626869, JString, required = false,
                                   default = nil)
  if valid_21626869 != nil:
    section.add "X-Amz-Algorithm", valid_21626869
  var valid_21626870 = header.getOrDefault("X-Amz-Signature")
  valid_21626870 = validateParameter(valid_21626870, JString, required = false,
                                   default = nil)
  if valid_21626870 != nil:
    section.add "X-Amz-Signature", valid_21626870
  var valid_21626871 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626871 = validateParameter(valid_21626871, JString, required = false,
                                   default = nil)
  if valid_21626871 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626871
  var valid_21626872 = header.getOrDefault("X-Amz-Credential")
  valid_21626872 = validateParameter(valid_21626872, JString, required = false,
                                   default = nil)
  if valid_21626872 != nil:
    section.add "X-Amz-Credential", valid_21626872
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626874: Call_OverridePullRequestApprovalRules_21626862;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Sets aside (overrides) all approval rule requirements for a specified pull request.
  ## 
  let valid = call_21626874.validator(path, query, header, formData, body, _)
  let scheme = call_21626874.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626874.makeUrl(scheme.get, call_21626874.host, call_21626874.base,
                               call_21626874.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626874, uri, valid, _)

proc call*(call_21626875: Call_OverridePullRequestApprovalRules_21626862;
          body: JsonNode): Recallable =
  ## overridePullRequestApprovalRules
  ## Sets aside (overrides) all approval rule requirements for a specified pull request.
  ##   body: JObject (required)
  var body_21626876 = newJObject()
  if body != nil:
    body_21626876 = body
  result = call_21626875.call(nil, nil, nil, nil, body_21626876)

var overridePullRequestApprovalRules* = Call_OverridePullRequestApprovalRules_21626862(
    name: "overridePullRequestApprovalRules", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com", route: "/#X-Amz-Target=CodeCommit_20150413.OverridePullRequestApprovalRules",
    validator: validate_OverridePullRequestApprovalRules_21626863, base: "/",
    makeUrl: url_OverridePullRequestApprovalRules_21626864,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCommentForComparedCommit_21626877 = ref object of OpenApiRestCall_21625435
proc url_PostCommentForComparedCommit_21626879(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCommentForComparedCommit_21626878(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Posts a comment on the comparison between two commits.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626880 = header.getOrDefault("X-Amz-Date")
  valid_21626880 = validateParameter(valid_21626880, JString, required = false,
                                   default = nil)
  if valid_21626880 != nil:
    section.add "X-Amz-Date", valid_21626880
  var valid_21626881 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626881 = validateParameter(valid_21626881, JString, required = false,
                                   default = nil)
  if valid_21626881 != nil:
    section.add "X-Amz-Security-Token", valid_21626881
  var valid_21626882 = header.getOrDefault("X-Amz-Target")
  valid_21626882 = validateParameter(valid_21626882, JString, required = true, default = newJString(
      "CodeCommit_20150413.PostCommentForComparedCommit"))
  if valid_21626882 != nil:
    section.add "X-Amz-Target", valid_21626882
  var valid_21626883 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626883 = validateParameter(valid_21626883, JString, required = false,
                                   default = nil)
  if valid_21626883 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626883
  var valid_21626884 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626884 = validateParameter(valid_21626884, JString, required = false,
                                   default = nil)
  if valid_21626884 != nil:
    section.add "X-Amz-Algorithm", valid_21626884
  var valid_21626885 = header.getOrDefault("X-Amz-Signature")
  valid_21626885 = validateParameter(valid_21626885, JString, required = false,
                                   default = nil)
  if valid_21626885 != nil:
    section.add "X-Amz-Signature", valid_21626885
  var valid_21626886 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626886 = validateParameter(valid_21626886, JString, required = false,
                                   default = nil)
  if valid_21626886 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626886
  var valid_21626887 = header.getOrDefault("X-Amz-Credential")
  valid_21626887 = validateParameter(valid_21626887, JString, required = false,
                                   default = nil)
  if valid_21626887 != nil:
    section.add "X-Amz-Credential", valid_21626887
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626889: Call_PostCommentForComparedCommit_21626877;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Posts a comment on the comparison between two commits.
  ## 
  let valid = call_21626889.validator(path, query, header, formData, body, _)
  let scheme = call_21626889.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626889.makeUrl(scheme.get, call_21626889.host, call_21626889.base,
                               call_21626889.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626889, uri, valid, _)

proc call*(call_21626890: Call_PostCommentForComparedCommit_21626877;
          body: JsonNode): Recallable =
  ## postCommentForComparedCommit
  ## Posts a comment on the comparison between two commits.
  ##   body: JObject (required)
  var body_21626891 = newJObject()
  if body != nil:
    body_21626891 = body
  result = call_21626890.call(nil, nil, nil, nil, body_21626891)

var postCommentForComparedCommit* = Call_PostCommentForComparedCommit_21626877(
    name: "postCommentForComparedCommit", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.PostCommentForComparedCommit",
    validator: validate_PostCommentForComparedCommit_21626878, base: "/",
    makeUrl: url_PostCommentForComparedCommit_21626879,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCommentForPullRequest_21626892 = ref object of OpenApiRestCall_21625435
proc url_PostCommentForPullRequest_21626894(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCommentForPullRequest_21626893(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Posts a comment on a pull request.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626895 = header.getOrDefault("X-Amz-Date")
  valid_21626895 = validateParameter(valid_21626895, JString, required = false,
                                   default = nil)
  if valid_21626895 != nil:
    section.add "X-Amz-Date", valid_21626895
  var valid_21626896 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626896 = validateParameter(valid_21626896, JString, required = false,
                                   default = nil)
  if valid_21626896 != nil:
    section.add "X-Amz-Security-Token", valid_21626896
  var valid_21626897 = header.getOrDefault("X-Amz-Target")
  valid_21626897 = validateParameter(valid_21626897, JString, required = true, default = newJString(
      "CodeCommit_20150413.PostCommentForPullRequest"))
  if valid_21626897 != nil:
    section.add "X-Amz-Target", valid_21626897
  var valid_21626898 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626898 = validateParameter(valid_21626898, JString, required = false,
                                   default = nil)
  if valid_21626898 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626898
  var valid_21626899 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626899 = validateParameter(valid_21626899, JString, required = false,
                                   default = nil)
  if valid_21626899 != nil:
    section.add "X-Amz-Algorithm", valid_21626899
  var valid_21626900 = header.getOrDefault("X-Amz-Signature")
  valid_21626900 = validateParameter(valid_21626900, JString, required = false,
                                   default = nil)
  if valid_21626900 != nil:
    section.add "X-Amz-Signature", valid_21626900
  var valid_21626901 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626901 = validateParameter(valid_21626901, JString, required = false,
                                   default = nil)
  if valid_21626901 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626901
  var valid_21626902 = header.getOrDefault("X-Amz-Credential")
  valid_21626902 = validateParameter(valid_21626902, JString, required = false,
                                   default = nil)
  if valid_21626902 != nil:
    section.add "X-Amz-Credential", valid_21626902
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626904: Call_PostCommentForPullRequest_21626892;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Posts a comment on a pull request.
  ## 
  let valid = call_21626904.validator(path, query, header, formData, body, _)
  let scheme = call_21626904.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626904.makeUrl(scheme.get, call_21626904.host, call_21626904.base,
                               call_21626904.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626904, uri, valid, _)

proc call*(call_21626905: Call_PostCommentForPullRequest_21626892; body: JsonNode): Recallable =
  ## postCommentForPullRequest
  ## Posts a comment on a pull request.
  ##   body: JObject (required)
  var body_21626906 = newJObject()
  if body != nil:
    body_21626906 = body
  result = call_21626905.call(nil, nil, nil, nil, body_21626906)

var postCommentForPullRequest* = Call_PostCommentForPullRequest_21626892(
    name: "postCommentForPullRequest", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.PostCommentForPullRequest",
    validator: validate_PostCommentForPullRequest_21626893, base: "/",
    makeUrl: url_PostCommentForPullRequest_21626894,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCommentReply_21626907 = ref object of OpenApiRestCall_21625435
proc url_PostCommentReply_21626909(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCommentReply_21626908(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Posts a comment in reply to an existing comment on a comparison between commits or a pull request.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626910 = header.getOrDefault("X-Amz-Date")
  valid_21626910 = validateParameter(valid_21626910, JString, required = false,
                                   default = nil)
  if valid_21626910 != nil:
    section.add "X-Amz-Date", valid_21626910
  var valid_21626911 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626911 = validateParameter(valid_21626911, JString, required = false,
                                   default = nil)
  if valid_21626911 != nil:
    section.add "X-Amz-Security-Token", valid_21626911
  var valid_21626912 = header.getOrDefault("X-Amz-Target")
  valid_21626912 = validateParameter(valid_21626912, JString, required = true, default = newJString(
      "CodeCommit_20150413.PostCommentReply"))
  if valid_21626912 != nil:
    section.add "X-Amz-Target", valid_21626912
  var valid_21626913 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626913 = validateParameter(valid_21626913, JString, required = false,
                                   default = nil)
  if valid_21626913 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626913
  var valid_21626914 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626914 = validateParameter(valid_21626914, JString, required = false,
                                   default = nil)
  if valid_21626914 != nil:
    section.add "X-Amz-Algorithm", valid_21626914
  var valid_21626915 = header.getOrDefault("X-Amz-Signature")
  valid_21626915 = validateParameter(valid_21626915, JString, required = false,
                                   default = nil)
  if valid_21626915 != nil:
    section.add "X-Amz-Signature", valid_21626915
  var valid_21626916 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626916 = validateParameter(valid_21626916, JString, required = false,
                                   default = nil)
  if valid_21626916 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626916
  var valid_21626917 = header.getOrDefault("X-Amz-Credential")
  valid_21626917 = validateParameter(valid_21626917, JString, required = false,
                                   default = nil)
  if valid_21626917 != nil:
    section.add "X-Amz-Credential", valid_21626917
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626919: Call_PostCommentReply_21626907; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Posts a comment in reply to an existing comment on a comparison between commits or a pull request.
  ## 
  let valid = call_21626919.validator(path, query, header, formData, body, _)
  let scheme = call_21626919.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626919.makeUrl(scheme.get, call_21626919.host, call_21626919.base,
                               call_21626919.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626919, uri, valid, _)

proc call*(call_21626920: Call_PostCommentReply_21626907; body: JsonNode): Recallable =
  ## postCommentReply
  ## Posts a comment in reply to an existing comment on a comparison between commits or a pull request.
  ##   body: JObject (required)
  var body_21626921 = newJObject()
  if body != nil:
    body_21626921 = body
  result = call_21626920.call(nil, nil, nil, nil, body_21626921)

var postCommentReply* = Call_PostCommentReply_21626907(name: "postCommentReply",
    meth: HttpMethod.HttpPost, host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.PostCommentReply",
    validator: validate_PostCommentReply_21626908, base: "/",
    makeUrl: url_PostCommentReply_21626909, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutFile_21626922 = ref object of OpenApiRestCall_21625435
proc url_PutFile_21626924(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutFile_21626923(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Adds or updates a file in a branch in an AWS CodeCommit repository, and generates a commit for the addition in the specified branch.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626925 = header.getOrDefault("X-Amz-Date")
  valid_21626925 = validateParameter(valid_21626925, JString, required = false,
                                   default = nil)
  if valid_21626925 != nil:
    section.add "X-Amz-Date", valid_21626925
  var valid_21626926 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626926 = validateParameter(valid_21626926, JString, required = false,
                                   default = nil)
  if valid_21626926 != nil:
    section.add "X-Amz-Security-Token", valid_21626926
  var valid_21626927 = header.getOrDefault("X-Amz-Target")
  valid_21626927 = validateParameter(valid_21626927, JString, required = true, default = newJString(
      "CodeCommit_20150413.PutFile"))
  if valid_21626927 != nil:
    section.add "X-Amz-Target", valid_21626927
  var valid_21626928 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626928 = validateParameter(valid_21626928, JString, required = false,
                                   default = nil)
  if valid_21626928 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626928
  var valid_21626929 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626929 = validateParameter(valid_21626929, JString, required = false,
                                   default = nil)
  if valid_21626929 != nil:
    section.add "X-Amz-Algorithm", valid_21626929
  var valid_21626930 = header.getOrDefault("X-Amz-Signature")
  valid_21626930 = validateParameter(valid_21626930, JString, required = false,
                                   default = nil)
  if valid_21626930 != nil:
    section.add "X-Amz-Signature", valid_21626930
  var valid_21626931 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626931 = validateParameter(valid_21626931, JString, required = false,
                                   default = nil)
  if valid_21626931 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626931
  var valid_21626932 = header.getOrDefault("X-Amz-Credential")
  valid_21626932 = validateParameter(valid_21626932, JString, required = false,
                                   default = nil)
  if valid_21626932 != nil:
    section.add "X-Amz-Credential", valid_21626932
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626934: Call_PutFile_21626922; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Adds or updates a file in a branch in an AWS CodeCommit repository, and generates a commit for the addition in the specified branch.
  ## 
  let valid = call_21626934.validator(path, query, header, formData, body, _)
  let scheme = call_21626934.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626934.makeUrl(scheme.get, call_21626934.host, call_21626934.base,
                               call_21626934.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626934, uri, valid, _)

proc call*(call_21626935: Call_PutFile_21626922; body: JsonNode): Recallable =
  ## putFile
  ## Adds or updates a file in a branch in an AWS CodeCommit repository, and generates a commit for the addition in the specified branch.
  ##   body: JObject (required)
  var body_21626936 = newJObject()
  if body != nil:
    body_21626936 = body
  result = call_21626935.call(nil, nil, nil, nil, body_21626936)

var putFile* = Call_PutFile_21626922(name: "putFile", meth: HttpMethod.HttpPost,
                                  host: "codecommit.amazonaws.com", route: "/#X-Amz-Target=CodeCommit_20150413.PutFile",
                                  validator: validate_PutFile_21626923, base: "/",
                                  makeUrl: url_PutFile_21626924,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutRepositoryTriggers_21626937 = ref object of OpenApiRestCall_21625435
proc url_PutRepositoryTriggers_21626939(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutRepositoryTriggers_21626938(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Replaces all triggers for a repository. Used to create or delete triggers.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626940 = header.getOrDefault("X-Amz-Date")
  valid_21626940 = validateParameter(valid_21626940, JString, required = false,
                                   default = nil)
  if valid_21626940 != nil:
    section.add "X-Amz-Date", valid_21626940
  var valid_21626941 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626941 = validateParameter(valid_21626941, JString, required = false,
                                   default = nil)
  if valid_21626941 != nil:
    section.add "X-Amz-Security-Token", valid_21626941
  var valid_21626942 = header.getOrDefault("X-Amz-Target")
  valid_21626942 = validateParameter(valid_21626942, JString, required = true, default = newJString(
      "CodeCommit_20150413.PutRepositoryTriggers"))
  if valid_21626942 != nil:
    section.add "X-Amz-Target", valid_21626942
  var valid_21626943 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626943 = validateParameter(valid_21626943, JString, required = false,
                                   default = nil)
  if valid_21626943 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626943
  var valid_21626944 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626944 = validateParameter(valid_21626944, JString, required = false,
                                   default = nil)
  if valid_21626944 != nil:
    section.add "X-Amz-Algorithm", valid_21626944
  var valid_21626945 = header.getOrDefault("X-Amz-Signature")
  valid_21626945 = validateParameter(valid_21626945, JString, required = false,
                                   default = nil)
  if valid_21626945 != nil:
    section.add "X-Amz-Signature", valid_21626945
  var valid_21626946 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626946 = validateParameter(valid_21626946, JString, required = false,
                                   default = nil)
  if valid_21626946 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626946
  var valid_21626947 = header.getOrDefault("X-Amz-Credential")
  valid_21626947 = validateParameter(valid_21626947, JString, required = false,
                                   default = nil)
  if valid_21626947 != nil:
    section.add "X-Amz-Credential", valid_21626947
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626949: Call_PutRepositoryTriggers_21626937;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Replaces all triggers for a repository. Used to create or delete triggers.
  ## 
  let valid = call_21626949.validator(path, query, header, formData, body, _)
  let scheme = call_21626949.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626949.makeUrl(scheme.get, call_21626949.host, call_21626949.base,
                               call_21626949.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626949, uri, valid, _)

proc call*(call_21626950: Call_PutRepositoryTriggers_21626937; body: JsonNode): Recallable =
  ## putRepositoryTriggers
  ## Replaces all triggers for a repository. Used to create or delete triggers.
  ##   body: JObject (required)
  var body_21626951 = newJObject()
  if body != nil:
    body_21626951 = body
  result = call_21626950.call(nil, nil, nil, nil, body_21626951)

var putRepositoryTriggers* = Call_PutRepositoryTriggers_21626937(
    name: "putRepositoryTriggers", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.PutRepositoryTriggers",
    validator: validate_PutRepositoryTriggers_21626938, base: "/",
    makeUrl: url_PutRepositoryTriggers_21626939,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_21626952 = ref object of OpenApiRestCall_21625435
proc url_TagResource_21626954(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_TagResource_21626953(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Adds or updates tags for a resource in AWS CodeCommit. For a list of valid resources in AWS CodeCommit, see <a href="https://docs.aws.amazon.com/codecommit/latest/userguide/auth-and-access-control-iam-access-control-identity-based.html#arn-formats">CodeCommit Resources and Operations</a> in the <i>AWS CodeCommit User Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626955 = header.getOrDefault("X-Amz-Date")
  valid_21626955 = validateParameter(valid_21626955, JString, required = false,
                                   default = nil)
  if valid_21626955 != nil:
    section.add "X-Amz-Date", valid_21626955
  var valid_21626956 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626956 = validateParameter(valid_21626956, JString, required = false,
                                   default = nil)
  if valid_21626956 != nil:
    section.add "X-Amz-Security-Token", valid_21626956
  var valid_21626957 = header.getOrDefault("X-Amz-Target")
  valid_21626957 = validateParameter(valid_21626957, JString, required = true, default = newJString(
      "CodeCommit_20150413.TagResource"))
  if valid_21626957 != nil:
    section.add "X-Amz-Target", valid_21626957
  var valid_21626958 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626958 = validateParameter(valid_21626958, JString, required = false,
                                   default = nil)
  if valid_21626958 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626958
  var valid_21626959 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626959 = validateParameter(valid_21626959, JString, required = false,
                                   default = nil)
  if valid_21626959 != nil:
    section.add "X-Amz-Algorithm", valid_21626959
  var valid_21626960 = header.getOrDefault("X-Amz-Signature")
  valid_21626960 = validateParameter(valid_21626960, JString, required = false,
                                   default = nil)
  if valid_21626960 != nil:
    section.add "X-Amz-Signature", valid_21626960
  var valid_21626961 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626961 = validateParameter(valid_21626961, JString, required = false,
                                   default = nil)
  if valid_21626961 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626961
  var valid_21626962 = header.getOrDefault("X-Amz-Credential")
  valid_21626962 = validateParameter(valid_21626962, JString, required = false,
                                   default = nil)
  if valid_21626962 != nil:
    section.add "X-Amz-Credential", valid_21626962
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626964: Call_TagResource_21626952; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Adds or updates tags for a resource in AWS CodeCommit. For a list of valid resources in AWS CodeCommit, see <a href="https://docs.aws.amazon.com/codecommit/latest/userguide/auth-and-access-control-iam-access-control-identity-based.html#arn-formats">CodeCommit Resources and Operations</a> in the <i>AWS CodeCommit User Guide</i>.
  ## 
  let valid = call_21626964.validator(path, query, header, formData, body, _)
  let scheme = call_21626964.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626964.makeUrl(scheme.get, call_21626964.host, call_21626964.base,
                               call_21626964.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626964, uri, valid, _)

proc call*(call_21626965: Call_TagResource_21626952; body: JsonNode): Recallable =
  ## tagResource
  ## Adds or updates tags for a resource in AWS CodeCommit. For a list of valid resources in AWS CodeCommit, see <a href="https://docs.aws.amazon.com/codecommit/latest/userguide/auth-and-access-control-iam-access-control-identity-based.html#arn-formats">CodeCommit Resources and Operations</a> in the <i>AWS CodeCommit User Guide</i>.
  ##   body: JObject (required)
  var body_21626966 = newJObject()
  if body != nil:
    body_21626966 = body
  result = call_21626965.call(nil, nil, nil, nil, body_21626966)

var tagResource* = Call_TagResource_21626952(name: "tagResource",
    meth: HttpMethod.HttpPost, host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.TagResource",
    validator: validate_TagResource_21626953, base: "/", makeUrl: url_TagResource_21626954,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TestRepositoryTriggers_21626967 = ref object of OpenApiRestCall_21625435
proc url_TestRepositoryTriggers_21626969(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_TestRepositoryTriggers_21626968(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Tests the functionality of repository triggers by sending information to the trigger target. If real data is available in the repository, the test sends data from the last commit. If no data is available, sample data is generated.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626970 = header.getOrDefault("X-Amz-Date")
  valid_21626970 = validateParameter(valid_21626970, JString, required = false,
                                   default = nil)
  if valid_21626970 != nil:
    section.add "X-Amz-Date", valid_21626970
  var valid_21626971 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626971 = validateParameter(valid_21626971, JString, required = false,
                                   default = nil)
  if valid_21626971 != nil:
    section.add "X-Amz-Security-Token", valid_21626971
  var valid_21626972 = header.getOrDefault("X-Amz-Target")
  valid_21626972 = validateParameter(valid_21626972, JString, required = true, default = newJString(
      "CodeCommit_20150413.TestRepositoryTriggers"))
  if valid_21626972 != nil:
    section.add "X-Amz-Target", valid_21626972
  var valid_21626973 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626973 = validateParameter(valid_21626973, JString, required = false,
                                   default = nil)
  if valid_21626973 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626973
  var valid_21626974 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626974 = validateParameter(valid_21626974, JString, required = false,
                                   default = nil)
  if valid_21626974 != nil:
    section.add "X-Amz-Algorithm", valid_21626974
  var valid_21626975 = header.getOrDefault("X-Amz-Signature")
  valid_21626975 = validateParameter(valid_21626975, JString, required = false,
                                   default = nil)
  if valid_21626975 != nil:
    section.add "X-Amz-Signature", valid_21626975
  var valid_21626976 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626976 = validateParameter(valid_21626976, JString, required = false,
                                   default = nil)
  if valid_21626976 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626976
  var valid_21626977 = header.getOrDefault("X-Amz-Credential")
  valid_21626977 = validateParameter(valid_21626977, JString, required = false,
                                   default = nil)
  if valid_21626977 != nil:
    section.add "X-Amz-Credential", valid_21626977
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626979: Call_TestRepositoryTriggers_21626967;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Tests the functionality of repository triggers by sending information to the trigger target. If real data is available in the repository, the test sends data from the last commit. If no data is available, sample data is generated.
  ## 
  let valid = call_21626979.validator(path, query, header, formData, body, _)
  let scheme = call_21626979.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626979.makeUrl(scheme.get, call_21626979.host, call_21626979.base,
                               call_21626979.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626979, uri, valid, _)

proc call*(call_21626980: Call_TestRepositoryTriggers_21626967; body: JsonNode): Recallable =
  ## testRepositoryTriggers
  ## Tests the functionality of repository triggers by sending information to the trigger target. If real data is available in the repository, the test sends data from the last commit. If no data is available, sample data is generated.
  ##   body: JObject (required)
  var body_21626981 = newJObject()
  if body != nil:
    body_21626981 = body
  result = call_21626980.call(nil, nil, nil, nil, body_21626981)

var testRepositoryTriggers* = Call_TestRepositoryTriggers_21626967(
    name: "testRepositoryTriggers", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.TestRepositoryTriggers",
    validator: validate_TestRepositoryTriggers_21626968, base: "/",
    makeUrl: url_TestRepositoryTriggers_21626969,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_21626982 = ref object of OpenApiRestCall_21625435
proc url_UntagResource_21626984(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UntagResource_21626983(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Removes tags for a resource in AWS CodeCommit. For a list of valid resources in AWS CodeCommit, see <a href="https://docs.aws.amazon.com/codecommit/latest/userguide/auth-and-access-control-iam-access-control-identity-based.html#arn-formats">CodeCommit Resources and Operations</a> in the <i>AWS CodeCommit User Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626985 = header.getOrDefault("X-Amz-Date")
  valid_21626985 = validateParameter(valid_21626985, JString, required = false,
                                   default = nil)
  if valid_21626985 != nil:
    section.add "X-Amz-Date", valid_21626985
  var valid_21626986 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626986 = validateParameter(valid_21626986, JString, required = false,
                                   default = nil)
  if valid_21626986 != nil:
    section.add "X-Amz-Security-Token", valid_21626986
  var valid_21626987 = header.getOrDefault("X-Amz-Target")
  valid_21626987 = validateParameter(valid_21626987, JString, required = true, default = newJString(
      "CodeCommit_20150413.UntagResource"))
  if valid_21626987 != nil:
    section.add "X-Amz-Target", valid_21626987
  var valid_21626988 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626988 = validateParameter(valid_21626988, JString, required = false,
                                   default = nil)
  if valid_21626988 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626988
  var valid_21626989 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626989 = validateParameter(valid_21626989, JString, required = false,
                                   default = nil)
  if valid_21626989 != nil:
    section.add "X-Amz-Algorithm", valid_21626989
  var valid_21626990 = header.getOrDefault("X-Amz-Signature")
  valid_21626990 = validateParameter(valid_21626990, JString, required = false,
                                   default = nil)
  if valid_21626990 != nil:
    section.add "X-Amz-Signature", valid_21626990
  var valid_21626991 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626991 = validateParameter(valid_21626991, JString, required = false,
                                   default = nil)
  if valid_21626991 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626991
  var valid_21626992 = header.getOrDefault("X-Amz-Credential")
  valid_21626992 = validateParameter(valid_21626992, JString, required = false,
                                   default = nil)
  if valid_21626992 != nil:
    section.add "X-Amz-Credential", valid_21626992
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626994: Call_UntagResource_21626982; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Removes tags for a resource in AWS CodeCommit. For a list of valid resources in AWS CodeCommit, see <a href="https://docs.aws.amazon.com/codecommit/latest/userguide/auth-and-access-control-iam-access-control-identity-based.html#arn-formats">CodeCommit Resources and Operations</a> in the <i>AWS CodeCommit User Guide</i>.
  ## 
  let valid = call_21626994.validator(path, query, header, formData, body, _)
  let scheme = call_21626994.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626994.makeUrl(scheme.get, call_21626994.host, call_21626994.base,
                               call_21626994.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626994, uri, valid, _)

proc call*(call_21626995: Call_UntagResource_21626982; body: JsonNode): Recallable =
  ## untagResource
  ## Removes tags for a resource in AWS CodeCommit. For a list of valid resources in AWS CodeCommit, see <a href="https://docs.aws.amazon.com/codecommit/latest/userguide/auth-and-access-control-iam-access-control-identity-based.html#arn-formats">CodeCommit Resources and Operations</a> in the <i>AWS CodeCommit User Guide</i>.
  ##   body: JObject (required)
  var body_21626996 = newJObject()
  if body != nil:
    body_21626996 = body
  result = call_21626995.call(nil, nil, nil, nil, body_21626996)

var untagResource* = Call_UntagResource_21626982(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.UntagResource",
    validator: validate_UntagResource_21626983, base: "/",
    makeUrl: url_UntagResource_21626984, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateApprovalRuleTemplateContent_21626997 = ref object of OpenApiRestCall_21625435
proc url_UpdateApprovalRuleTemplateContent_21626999(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateApprovalRuleTemplateContent_21626998(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Updates the content of an approval rule template. You can change the number of required approvals, the membership of the approval rule, and whether an approval pool is defined.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627000 = header.getOrDefault("X-Amz-Date")
  valid_21627000 = validateParameter(valid_21627000, JString, required = false,
                                   default = nil)
  if valid_21627000 != nil:
    section.add "X-Amz-Date", valid_21627000
  var valid_21627001 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627001 = validateParameter(valid_21627001, JString, required = false,
                                   default = nil)
  if valid_21627001 != nil:
    section.add "X-Amz-Security-Token", valid_21627001
  var valid_21627002 = header.getOrDefault("X-Amz-Target")
  valid_21627002 = validateParameter(valid_21627002, JString, required = true, default = newJString(
      "CodeCommit_20150413.UpdateApprovalRuleTemplateContent"))
  if valid_21627002 != nil:
    section.add "X-Amz-Target", valid_21627002
  var valid_21627003 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627003 = validateParameter(valid_21627003, JString, required = false,
                                   default = nil)
  if valid_21627003 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627003
  var valid_21627004 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627004 = validateParameter(valid_21627004, JString, required = false,
                                   default = nil)
  if valid_21627004 != nil:
    section.add "X-Amz-Algorithm", valid_21627004
  var valid_21627005 = header.getOrDefault("X-Amz-Signature")
  valid_21627005 = validateParameter(valid_21627005, JString, required = false,
                                   default = nil)
  if valid_21627005 != nil:
    section.add "X-Amz-Signature", valid_21627005
  var valid_21627006 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627006 = validateParameter(valid_21627006, JString, required = false,
                                   default = nil)
  if valid_21627006 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627006
  var valid_21627007 = header.getOrDefault("X-Amz-Credential")
  valid_21627007 = validateParameter(valid_21627007, JString, required = false,
                                   default = nil)
  if valid_21627007 != nil:
    section.add "X-Amz-Credential", valid_21627007
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21627009: Call_UpdateApprovalRuleTemplateContent_21626997;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates the content of an approval rule template. You can change the number of required approvals, the membership of the approval rule, and whether an approval pool is defined.
  ## 
  let valid = call_21627009.validator(path, query, header, formData, body, _)
  let scheme = call_21627009.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627009.makeUrl(scheme.get, call_21627009.host, call_21627009.base,
                               call_21627009.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627009, uri, valid, _)

proc call*(call_21627010: Call_UpdateApprovalRuleTemplateContent_21626997;
          body: JsonNode): Recallable =
  ## updateApprovalRuleTemplateContent
  ## Updates the content of an approval rule template. You can change the number of required approvals, the membership of the approval rule, and whether an approval pool is defined.
  ##   body: JObject (required)
  var body_21627011 = newJObject()
  if body != nil:
    body_21627011 = body
  result = call_21627010.call(nil, nil, nil, nil, body_21627011)

var updateApprovalRuleTemplateContent* = Call_UpdateApprovalRuleTemplateContent_21626997(
    name: "updateApprovalRuleTemplateContent", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com", route: "/#X-Amz-Target=CodeCommit_20150413.UpdateApprovalRuleTemplateContent",
    validator: validate_UpdateApprovalRuleTemplateContent_21626998, base: "/",
    makeUrl: url_UpdateApprovalRuleTemplateContent_21626999,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateApprovalRuleTemplateDescription_21627012 = ref object of OpenApiRestCall_21625435
proc url_UpdateApprovalRuleTemplateDescription_21627014(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateApprovalRuleTemplateDescription_21627013(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Updates the description for a specified approval rule template.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627015 = header.getOrDefault("X-Amz-Date")
  valid_21627015 = validateParameter(valid_21627015, JString, required = false,
                                   default = nil)
  if valid_21627015 != nil:
    section.add "X-Amz-Date", valid_21627015
  var valid_21627016 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627016 = validateParameter(valid_21627016, JString, required = false,
                                   default = nil)
  if valid_21627016 != nil:
    section.add "X-Amz-Security-Token", valid_21627016
  var valid_21627017 = header.getOrDefault("X-Amz-Target")
  valid_21627017 = validateParameter(valid_21627017, JString, required = true, default = newJString(
      "CodeCommit_20150413.UpdateApprovalRuleTemplateDescription"))
  if valid_21627017 != nil:
    section.add "X-Amz-Target", valid_21627017
  var valid_21627018 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627018 = validateParameter(valid_21627018, JString, required = false,
                                   default = nil)
  if valid_21627018 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627018
  var valid_21627019 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627019 = validateParameter(valid_21627019, JString, required = false,
                                   default = nil)
  if valid_21627019 != nil:
    section.add "X-Amz-Algorithm", valid_21627019
  var valid_21627020 = header.getOrDefault("X-Amz-Signature")
  valid_21627020 = validateParameter(valid_21627020, JString, required = false,
                                   default = nil)
  if valid_21627020 != nil:
    section.add "X-Amz-Signature", valid_21627020
  var valid_21627021 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627021 = validateParameter(valid_21627021, JString, required = false,
                                   default = nil)
  if valid_21627021 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627021
  var valid_21627022 = header.getOrDefault("X-Amz-Credential")
  valid_21627022 = validateParameter(valid_21627022, JString, required = false,
                                   default = nil)
  if valid_21627022 != nil:
    section.add "X-Amz-Credential", valid_21627022
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21627024: Call_UpdateApprovalRuleTemplateDescription_21627012;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates the description for a specified approval rule template.
  ## 
  let valid = call_21627024.validator(path, query, header, formData, body, _)
  let scheme = call_21627024.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627024.makeUrl(scheme.get, call_21627024.host, call_21627024.base,
                               call_21627024.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627024, uri, valid, _)

proc call*(call_21627025: Call_UpdateApprovalRuleTemplateDescription_21627012;
          body: JsonNode): Recallable =
  ## updateApprovalRuleTemplateDescription
  ## Updates the description for a specified approval rule template.
  ##   body: JObject (required)
  var body_21627026 = newJObject()
  if body != nil:
    body_21627026 = body
  result = call_21627025.call(nil, nil, nil, nil, body_21627026)

var updateApprovalRuleTemplateDescription* = Call_UpdateApprovalRuleTemplateDescription_21627012(
    name: "updateApprovalRuleTemplateDescription", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com", route: "/#X-Amz-Target=CodeCommit_20150413.UpdateApprovalRuleTemplateDescription",
    validator: validate_UpdateApprovalRuleTemplateDescription_21627013, base: "/",
    makeUrl: url_UpdateApprovalRuleTemplateDescription_21627014,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateApprovalRuleTemplateName_21627027 = ref object of OpenApiRestCall_21625435
proc url_UpdateApprovalRuleTemplateName_21627029(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateApprovalRuleTemplateName_21627028(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Updates the name of a specified approval rule template.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627030 = header.getOrDefault("X-Amz-Date")
  valid_21627030 = validateParameter(valid_21627030, JString, required = false,
                                   default = nil)
  if valid_21627030 != nil:
    section.add "X-Amz-Date", valid_21627030
  var valid_21627031 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627031 = validateParameter(valid_21627031, JString, required = false,
                                   default = nil)
  if valid_21627031 != nil:
    section.add "X-Amz-Security-Token", valid_21627031
  var valid_21627032 = header.getOrDefault("X-Amz-Target")
  valid_21627032 = validateParameter(valid_21627032, JString, required = true, default = newJString(
      "CodeCommit_20150413.UpdateApprovalRuleTemplateName"))
  if valid_21627032 != nil:
    section.add "X-Amz-Target", valid_21627032
  var valid_21627033 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627033 = validateParameter(valid_21627033, JString, required = false,
                                   default = nil)
  if valid_21627033 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627033
  var valid_21627034 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627034 = validateParameter(valid_21627034, JString, required = false,
                                   default = nil)
  if valid_21627034 != nil:
    section.add "X-Amz-Algorithm", valid_21627034
  var valid_21627035 = header.getOrDefault("X-Amz-Signature")
  valid_21627035 = validateParameter(valid_21627035, JString, required = false,
                                   default = nil)
  if valid_21627035 != nil:
    section.add "X-Amz-Signature", valid_21627035
  var valid_21627036 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627036 = validateParameter(valid_21627036, JString, required = false,
                                   default = nil)
  if valid_21627036 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627036
  var valid_21627037 = header.getOrDefault("X-Amz-Credential")
  valid_21627037 = validateParameter(valid_21627037, JString, required = false,
                                   default = nil)
  if valid_21627037 != nil:
    section.add "X-Amz-Credential", valid_21627037
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21627039: Call_UpdateApprovalRuleTemplateName_21627027;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates the name of a specified approval rule template.
  ## 
  let valid = call_21627039.validator(path, query, header, formData, body, _)
  let scheme = call_21627039.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627039.makeUrl(scheme.get, call_21627039.host, call_21627039.base,
                               call_21627039.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627039, uri, valid, _)

proc call*(call_21627040: Call_UpdateApprovalRuleTemplateName_21627027;
          body: JsonNode): Recallable =
  ## updateApprovalRuleTemplateName
  ## Updates the name of a specified approval rule template.
  ##   body: JObject (required)
  var body_21627041 = newJObject()
  if body != nil:
    body_21627041 = body
  result = call_21627040.call(nil, nil, nil, nil, body_21627041)

var updateApprovalRuleTemplateName* = Call_UpdateApprovalRuleTemplateName_21627027(
    name: "updateApprovalRuleTemplateName", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.UpdateApprovalRuleTemplateName",
    validator: validate_UpdateApprovalRuleTemplateName_21627028, base: "/",
    makeUrl: url_UpdateApprovalRuleTemplateName_21627029,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateComment_21627042 = ref object of OpenApiRestCall_21625435
proc url_UpdateComment_21627044(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateComment_21627043(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Replaces the contents of a comment.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627045 = header.getOrDefault("X-Amz-Date")
  valid_21627045 = validateParameter(valid_21627045, JString, required = false,
                                   default = nil)
  if valid_21627045 != nil:
    section.add "X-Amz-Date", valid_21627045
  var valid_21627046 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627046 = validateParameter(valid_21627046, JString, required = false,
                                   default = nil)
  if valid_21627046 != nil:
    section.add "X-Amz-Security-Token", valid_21627046
  var valid_21627047 = header.getOrDefault("X-Amz-Target")
  valid_21627047 = validateParameter(valid_21627047, JString, required = true, default = newJString(
      "CodeCommit_20150413.UpdateComment"))
  if valid_21627047 != nil:
    section.add "X-Amz-Target", valid_21627047
  var valid_21627048 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627048 = validateParameter(valid_21627048, JString, required = false,
                                   default = nil)
  if valid_21627048 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627048
  var valid_21627049 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627049 = validateParameter(valid_21627049, JString, required = false,
                                   default = nil)
  if valid_21627049 != nil:
    section.add "X-Amz-Algorithm", valid_21627049
  var valid_21627050 = header.getOrDefault("X-Amz-Signature")
  valid_21627050 = validateParameter(valid_21627050, JString, required = false,
                                   default = nil)
  if valid_21627050 != nil:
    section.add "X-Amz-Signature", valid_21627050
  var valid_21627051 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627051 = validateParameter(valid_21627051, JString, required = false,
                                   default = nil)
  if valid_21627051 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627051
  var valid_21627052 = header.getOrDefault("X-Amz-Credential")
  valid_21627052 = validateParameter(valid_21627052, JString, required = false,
                                   default = nil)
  if valid_21627052 != nil:
    section.add "X-Amz-Credential", valid_21627052
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21627054: Call_UpdateComment_21627042; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Replaces the contents of a comment.
  ## 
  let valid = call_21627054.validator(path, query, header, formData, body, _)
  let scheme = call_21627054.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627054.makeUrl(scheme.get, call_21627054.host, call_21627054.base,
                               call_21627054.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627054, uri, valid, _)

proc call*(call_21627055: Call_UpdateComment_21627042; body: JsonNode): Recallable =
  ## updateComment
  ## Replaces the contents of a comment.
  ##   body: JObject (required)
  var body_21627056 = newJObject()
  if body != nil:
    body_21627056 = body
  result = call_21627055.call(nil, nil, nil, nil, body_21627056)

var updateComment* = Call_UpdateComment_21627042(name: "updateComment",
    meth: HttpMethod.HttpPost, host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.UpdateComment",
    validator: validate_UpdateComment_21627043, base: "/",
    makeUrl: url_UpdateComment_21627044, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDefaultBranch_21627057 = ref object of OpenApiRestCall_21625435
proc url_UpdateDefaultBranch_21627059(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateDefaultBranch_21627058(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Sets or changes the default branch name for the specified repository.</p> <note> <p>If you use this operation to change the default branch name to the current default branch name, a success message is returned even though the default branch did not change.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627060 = header.getOrDefault("X-Amz-Date")
  valid_21627060 = validateParameter(valid_21627060, JString, required = false,
                                   default = nil)
  if valid_21627060 != nil:
    section.add "X-Amz-Date", valid_21627060
  var valid_21627061 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627061 = validateParameter(valid_21627061, JString, required = false,
                                   default = nil)
  if valid_21627061 != nil:
    section.add "X-Amz-Security-Token", valid_21627061
  var valid_21627062 = header.getOrDefault("X-Amz-Target")
  valid_21627062 = validateParameter(valid_21627062, JString, required = true, default = newJString(
      "CodeCommit_20150413.UpdateDefaultBranch"))
  if valid_21627062 != nil:
    section.add "X-Amz-Target", valid_21627062
  var valid_21627063 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627063 = validateParameter(valid_21627063, JString, required = false,
                                   default = nil)
  if valid_21627063 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627063
  var valid_21627064 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627064 = validateParameter(valid_21627064, JString, required = false,
                                   default = nil)
  if valid_21627064 != nil:
    section.add "X-Amz-Algorithm", valid_21627064
  var valid_21627065 = header.getOrDefault("X-Amz-Signature")
  valid_21627065 = validateParameter(valid_21627065, JString, required = false,
                                   default = nil)
  if valid_21627065 != nil:
    section.add "X-Amz-Signature", valid_21627065
  var valid_21627066 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627066 = validateParameter(valid_21627066, JString, required = false,
                                   default = nil)
  if valid_21627066 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627066
  var valid_21627067 = header.getOrDefault("X-Amz-Credential")
  valid_21627067 = validateParameter(valid_21627067, JString, required = false,
                                   default = nil)
  if valid_21627067 != nil:
    section.add "X-Amz-Credential", valid_21627067
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21627069: Call_UpdateDefaultBranch_21627057; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Sets or changes the default branch name for the specified repository.</p> <note> <p>If you use this operation to change the default branch name to the current default branch name, a success message is returned even though the default branch did not change.</p> </note>
  ## 
  let valid = call_21627069.validator(path, query, header, formData, body, _)
  let scheme = call_21627069.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627069.makeUrl(scheme.get, call_21627069.host, call_21627069.base,
                               call_21627069.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627069, uri, valid, _)

proc call*(call_21627070: Call_UpdateDefaultBranch_21627057; body: JsonNode): Recallable =
  ## updateDefaultBranch
  ## <p>Sets or changes the default branch name for the specified repository.</p> <note> <p>If you use this operation to change the default branch name to the current default branch name, a success message is returned even though the default branch did not change.</p> </note>
  ##   body: JObject (required)
  var body_21627071 = newJObject()
  if body != nil:
    body_21627071 = body
  result = call_21627070.call(nil, nil, nil, nil, body_21627071)

var updateDefaultBranch* = Call_UpdateDefaultBranch_21627057(
    name: "updateDefaultBranch", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.UpdateDefaultBranch",
    validator: validate_UpdateDefaultBranch_21627058, base: "/",
    makeUrl: url_UpdateDefaultBranch_21627059,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdatePullRequestApprovalRuleContent_21627072 = ref object of OpenApiRestCall_21625435
proc url_UpdatePullRequestApprovalRuleContent_21627074(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdatePullRequestApprovalRuleContent_21627073(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Updates the structure of an approval rule created specifically for a pull request. For example, you can change the number of required approvers and the approval pool for approvers. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627075 = header.getOrDefault("X-Amz-Date")
  valid_21627075 = validateParameter(valid_21627075, JString, required = false,
                                   default = nil)
  if valid_21627075 != nil:
    section.add "X-Amz-Date", valid_21627075
  var valid_21627076 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627076 = validateParameter(valid_21627076, JString, required = false,
                                   default = nil)
  if valid_21627076 != nil:
    section.add "X-Amz-Security-Token", valid_21627076
  var valid_21627077 = header.getOrDefault("X-Amz-Target")
  valid_21627077 = validateParameter(valid_21627077, JString, required = true, default = newJString(
      "CodeCommit_20150413.UpdatePullRequestApprovalRuleContent"))
  if valid_21627077 != nil:
    section.add "X-Amz-Target", valid_21627077
  var valid_21627078 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627078 = validateParameter(valid_21627078, JString, required = false,
                                   default = nil)
  if valid_21627078 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627078
  var valid_21627079 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627079 = validateParameter(valid_21627079, JString, required = false,
                                   default = nil)
  if valid_21627079 != nil:
    section.add "X-Amz-Algorithm", valid_21627079
  var valid_21627080 = header.getOrDefault("X-Amz-Signature")
  valid_21627080 = validateParameter(valid_21627080, JString, required = false,
                                   default = nil)
  if valid_21627080 != nil:
    section.add "X-Amz-Signature", valid_21627080
  var valid_21627081 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627081 = validateParameter(valid_21627081, JString, required = false,
                                   default = nil)
  if valid_21627081 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627081
  var valid_21627082 = header.getOrDefault("X-Amz-Credential")
  valid_21627082 = validateParameter(valid_21627082, JString, required = false,
                                   default = nil)
  if valid_21627082 != nil:
    section.add "X-Amz-Credential", valid_21627082
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21627084: Call_UpdatePullRequestApprovalRuleContent_21627072;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates the structure of an approval rule created specifically for a pull request. For example, you can change the number of required approvers and the approval pool for approvers. 
  ## 
  let valid = call_21627084.validator(path, query, header, formData, body, _)
  let scheme = call_21627084.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627084.makeUrl(scheme.get, call_21627084.host, call_21627084.base,
                               call_21627084.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627084, uri, valid, _)

proc call*(call_21627085: Call_UpdatePullRequestApprovalRuleContent_21627072;
          body: JsonNode): Recallable =
  ## updatePullRequestApprovalRuleContent
  ## Updates the structure of an approval rule created specifically for a pull request. For example, you can change the number of required approvers and the approval pool for approvers. 
  ##   body: JObject (required)
  var body_21627086 = newJObject()
  if body != nil:
    body_21627086 = body
  result = call_21627085.call(nil, nil, nil, nil, body_21627086)

var updatePullRequestApprovalRuleContent* = Call_UpdatePullRequestApprovalRuleContent_21627072(
    name: "updatePullRequestApprovalRuleContent", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com", route: "/#X-Amz-Target=CodeCommit_20150413.UpdatePullRequestApprovalRuleContent",
    validator: validate_UpdatePullRequestApprovalRuleContent_21627073, base: "/",
    makeUrl: url_UpdatePullRequestApprovalRuleContent_21627074,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdatePullRequestApprovalState_21627087 = ref object of OpenApiRestCall_21625435
proc url_UpdatePullRequestApprovalState_21627089(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdatePullRequestApprovalState_21627088(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Updates the state of a user's approval on a pull request. The user is derived from the signed-in account when the request is made.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627090 = header.getOrDefault("X-Amz-Date")
  valid_21627090 = validateParameter(valid_21627090, JString, required = false,
                                   default = nil)
  if valid_21627090 != nil:
    section.add "X-Amz-Date", valid_21627090
  var valid_21627091 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627091 = validateParameter(valid_21627091, JString, required = false,
                                   default = nil)
  if valid_21627091 != nil:
    section.add "X-Amz-Security-Token", valid_21627091
  var valid_21627092 = header.getOrDefault("X-Amz-Target")
  valid_21627092 = validateParameter(valid_21627092, JString, required = true, default = newJString(
      "CodeCommit_20150413.UpdatePullRequestApprovalState"))
  if valid_21627092 != nil:
    section.add "X-Amz-Target", valid_21627092
  var valid_21627093 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627093 = validateParameter(valid_21627093, JString, required = false,
                                   default = nil)
  if valid_21627093 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627093
  var valid_21627094 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627094 = validateParameter(valid_21627094, JString, required = false,
                                   default = nil)
  if valid_21627094 != nil:
    section.add "X-Amz-Algorithm", valid_21627094
  var valid_21627095 = header.getOrDefault("X-Amz-Signature")
  valid_21627095 = validateParameter(valid_21627095, JString, required = false,
                                   default = nil)
  if valid_21627095 != nil:
    section.add "X-Amz-Signature", valid_21627095
  var valid_21627096 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627096 = validateParameter(valid_21627096, JString, required = false,
                                   default = nil)
  if valid_21627096 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627096
  var valid_21627097 = header.getOrDefault("X-Amz-Credential")
  valid_21627097 = validateParameter(valid_21627097, JString, required = false,
                                   default = nil)
  if valid_21627097 != nil:
    section.add "X-Amz-Credential", valid_21627097
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21627099: Call_UpdatePullRequestApprovalState_21627087;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates the state of a user's approval on a pull request. The user is derived from the signed-in account when the request is made.
  ## 
  let valid = call_21627099.validator(path, query, header, formData, body, _)
  let scheme = call_21627099.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627099.makeUrl(scheme.get, call_21627099.host, call_21627099.base,
                               call_21627099.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627099, uri, valid, _)

proc call*(call_21627100: Call_UpdatePullRequestApprovalState_21627087;
          body: JsonNode): Recallable =
  ## updatePullRequestApprovalState
  ## Updates the state of a user's approval on a pull request. The user is derived from the signed-in account when the request is made.
  ##   body: JObject (required)
  var body_21627101 = newJObject()
  if body != nil:
    body_21627101 = body
  result = call_21627100.call(nil, nil, nil, nil, body_21627101)

var updatePullRequestApprovalState* = Call_UpdatePullRequestApprovalState_21627087(
    name: "updatePullRequestApprovalState", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.UpdatePullRequestApprovalState",
    validator: validate_UpdatePullRequestApprovalState_21627088, base: "/",
    makeUrl: url_UpdatePullRequestApprovalState_21627089,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdatePullRequestDescription_21627102 = ref object of OpenApiRestCall_21625435
proc url_UpdatePullRequestDescription_21627104(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdatePullRequestDescription_21627103(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Replaces the contents of the description of a pull request.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627105 = header.getOrDefault("X-Amz-Date")
  valid_21627105 = validateParameter(valid_21627105, JString, required = false,
                                   default = nil)
  if valid_21627105 != nil:
    section.add "X-Amz-Date", valid_21627105
  var valid_21627106 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627106 = validateParameter(valid_21627106, JString, required = false,
                                   default = nil)
  if valid_21627106 != nil:
    section.add "X-Amz-Security-Token", valid_21627106
  var valid_21627107 = header.getOrDefault("X-Amz-Target")
  valid_21627107 = validateParameter(valid_21627107, JString, required = true, default = newJString(
      "CodeCommit_20150413.UpdatePullRequestDescription"))
  if valid_21627107 != nil:
    section.add "X-Amz-Target", valid_21627107
  var valid_21627108 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627108 = validateParameter(valid_21627108, JString, required = false,
                                   default = nil)
  if valid_21627108 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627108
  var valid_21627109 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627109 = validateParameter(valid_21627109, JString, required = false,
                                   default = nil)
  if valid_21627109 != nil:
    section.add "X-Amz-Algorithm", valid_21627109
  var valid_21627110 = header.getOrDefault("X-Amz-Signature")
  valid_21627110 = validateParameter(valid_21627110, JString, required = false,
                                   default = nil)
  if valid_21627110 != nil:
    section.add "X-Amz-Signature", valid_21627110
  var valid_21627111 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627111 = validateParameter(valid_21627111, JString, required = false,
                                   default = nil)
  if valid_21627111 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627111
  var valid_21627112 = header.getOrDefault("X-Amz-Credential")
  valid_21627112 = validateParameter(valid_21627112, JString, required = false,
                                   default = nil)
  if valid_21627112 != nil:
    section.add "X-Amz-Credential", valid_21627112
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21627114: Call_UpdatePullRequestDescription_21627102;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Replaces the contents of the description of a pull request.
  ## 
  let valid = call_21627114.validator(path, query, header, formData, body, _)
  let scheme = call_21627114.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627114.makeUrl(scheme.get, call_21627114.host, call_21627114.base,
                               call_21627114.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627114, uri, valid, _)

proc call*(call_21627115: Call_UpdatePullRequestDescription_21627102;
          body: JsonNode): Recallable =
  ## updatePullRequestDescription
  ## Replaces the contents of the description of a pull request.
  ##   body: JObject (required)
  var body_21627116 = newJObject()
  if body != nil:
    body_21627116 = body
  result = call_21627115.call(nil, nil, nil, nil, body_21627116)

var updatePullRequestDescription* = Call_UpdatePullRequestDescription_21627102(
    name: "updatePullRequestDescription", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.UpdatePullRequestDescription",
    validator: validate_UpdatePullRequestDescription_21627103, base: "/",
    makeUrl: url_UpdatePullRequestDescription_21627104,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdatePullRequestStatus_21627117 = ref object of OpenApiRestCall_21625435
proc url_UpdatePullRequestStatus_21627119(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdatePullRequestStatus_21627118(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Updates the status of a pull request. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627120 = header.getOrDefault("X-Amz-Date")
  valid_21627120 = validateParameter(valid_21627120, JString, required = false,
                                   default = nil)
  if valid_21627120 != nil:
    section.add "X-Amz-Date", valid_21627120
  var valid_21627121 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627121 = validateParameter(valid_21627121, JString, required = false,
                                   default = nil)
  if valid_21627121 != nil:
    section.add "X-Amz-Security-Token", valid_21627121
  var valid_21627122 = header.getOrDefault("X-Amz-Target")
  valid_21627122 = validateParameter(valid_21627122, JString, required = true, default = newJString(
      "CodeCommit_20150413.UpdatePullRequestStatus"))
  if valid_21627122 != nil:
    section.add "X-Amz-Target", valid_21627122
  var valid_21627123 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627123 = validateParameter(valid_21627123, JString, required = false,
                                   default = nil)
  if valid_21627123 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627123
  var valid_21627124 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627124 = validateParameter(valid_21627124, JString, required = false,
                                   default = nil)
  if valid_21627124 != nil:
    section.add "X-Amz-Algorithm", valid_21627124
  var valid_21627125 = header.getOrDefault("X-Amz-Signature")
  valid_21627125 = validateParameter(valid_21627125, JString, required = false,
                                   default = nil)
  if valid_21627125 != nil:
    section.add "X-Amz-Signature", valid_21627125
  var valid_21627126 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627126 = validateParameter(valid_21627126, JString, required = false,
                                   default = nil)
  if valid_21627126 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627126
  var valid_21627127 = header.getOrDefault("X-Amz-Credential")
  valid_21627127 = validateParameter(valid_21627127, JString, required = false,
                                   default = nil)
  if valid_21627127 != nil:
    section.add "X-Amz-Credential", valid_21627127
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21627129: Call_UpdatePullRequestStatus_21627117;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates the status of a pull request. 
  ## 
  let valid = call_21627129.validator(path, query, header, formData, body, _)
  let scheme = call_21627129.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627129.makeUrl(scheme.get, call_21627129.host, call_21627129.base,
                               call_21627129.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627129, uri, valid, _)

proc call*(call_21627130: Call_UpdatePullRequestStatus_21627117; body: JsonNode): Recallable =
  ## updatePullRequestStatus
  ## Updates the status of a pull request. 
  ##   body: JObject (required)
  var body_21627131 = newJObject()
  if body != nil:
    body_21627131 = body
  result = call_21627130.call(nil, nil, nil, nil, body_21627131)

var updatePullRequestStatus* = Call_UpdatePullRequestStatus_21627117(
    name: "updatePullRequestStatus", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.UpdatePullRequestStatus",
    validator: validate_UpdatePullRequestStatus_21627118, base: "/",
    makeUrl: url_UpdatePullRequestStatus_21627119,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdatePullRequestTitle_21627132 = ref object of OpenApiRestCall_21625435
proc url_UpdatePullRequestTitle_21627134(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdatePullRequestTitle_21627133(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Replaces the title of a pull request.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627135 = header.getOrDefault("X-Amz-Date")
  valid_21627135 = validateParameter(valid_21627135, JString, required = false,
                                   default = nil)
  if valid_21627135 != nil:
    section.add "X-Amz-Date", valid_21627135
  var valid_21627136 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627136 = validateParameter(valid_21627136, JString, required = false,
                                   default = nil)
  if valid_21627136 != nil:
    section.add "X-Amz-Security-Token", valid_21627136
  var valid_21627137 = header.getOrDefault("X-Amz-Target")
  valid_21627137 = validateParameter(valid_21627137, JString, required = true, default = newJString(
      "CodeCommit_20150413.UpdatePullRequestTitle"))
  if valid_21627137 != nil:
    section.add "X-Amz-Target", valid_21627137
  var valid_21627138 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627138 = validateParameter(valid_21627138, JString, required = false,
                                   default = nil)
  if valid_21627138 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627138
  var valid_21627139 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627139 = validateParameter(valid_21627139, JString, required = false,
                                   default = nil)
  if valid_21627139 != nil:
    section.add "X-Amz-Algorithm", valid_21627139
  var valid_21627140 = header.getOrDefault("X-Amz-Signature")
  valid_21627140 = validateParameter(valid_21627140, JString, required = false,
                                   default = nil)
  if valid_21627140 != nil:
    section.add "X-Amz-Signature", valid_21627140
  var valid_21627141 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627141 = validateParameter(valid_21627141, JString, required = false,
                                   default = nil)
  if valid_21627141 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627141
  var valid_21627142 = header.getOrDefault("X-Amz-Credential")
  valid_21627142 = validateParameter(valid_21627142, JString, required = false,
                                   default = nil)
  if valid_21627142 != nil:
    section.add "X-Amz-Credential", valid_21627142
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21627144: Call_UpdatePullRequestTitle_21627132;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Replaces the title of a pull request.
  ## 
  let valid = call_21627144.validator(path, query, header, formData, body, _)
  let scheme = call_21627144.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627144.makeUrl(scheme.get, call_21627144.host, call_21627144.base,
                               call_21627144.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627144, uri, valid, _)

proc call*(call_21627145: Call_UpdatePullRequestTitle_21627132; body: JsonNode): Recallable =
  ## updatePullRequestTitle
  ## Replaces the title of a pull request.
  ##   body: JObject (required)
  var body_21627146 = newJObject()
  if body != nil:
    body_21627146 = body
  result = call_21627145.call(nil, nil, nil, nil, body_21627146)

var updatePullRequestTitle* = Call_UpdatePullRequestTitle_21627132(
    name: "updatePullRequestTitle", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.UpdatePullRequestTitle",
    validator: validate_UpdatePullRequestTitle_21627133, base: "/",
    makeUrl: url_UpdatePullRequestTitle_21627134,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateRepositoryDescription_21627147 = ref object of OpenApiRestCall_21625435
proc url_UpdateRepositoryDescription_21627149(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateRepositoryDescription_21627148(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Sets or changes the comment or description for a repository.</p> <note> <p>The description field for a repository accepts all HTML characters and all valid Unicode characters. Applications that do not HTML-encode the description and display it in a webpage can expose users to potentially malicious code. Make sure that you HTML-encode the description field in any application that uses this API to display the repository description on a webpage.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627150 = header.getOrDefault("X-Amz-Date")
  valid_21627150 = validateParameter(valid_21627150, JString, required = false,
                                   default = nil)
  if valid_21627150 != nil:
    section.add "X-Amz-Date", valid_21627150
  var valid_21627151 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627151 = validateParameter(valid_21627151, JString, required = false,
                                   default = nil)
  if valid_21627151 != nil:
    section.add "X-Amz-Security-Token", valid_21627151
  var valid_21627152 = header.getOrDefault("X-Amz-Target")
  valid_21627152 = validateParameter(valid_21627152, JString, required = true, default = newJString(
      "CodeCommit_20150413.UpdateRepositoryDescription"))
  if valid_21627152 != nil:
    section.add "X-Amz-Target", valid_21627152
  var valid_21627153 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627153 = validateParameter(valid_21627153, JString, required = false,
                                   default = nil)
  if valid_21627153 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627153
  var valid_21627154 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627154 = validateParameter(valid_21627154, JString, required = false,
                                   default = nil)
  if valid_21627154 != nil:
    section.add "X-Amz-Algorithm", valid_21627154
  var valid_21627155 = header.getOrDefault("X-Amz-Signature")
  valid_21627155 = validateParameter(valid_21627155, JString, required = false,
                                   default = nil)
  if valid_21627155 != nil:
    section.add "X-Amz-Signature", valid_21627155
  var valid_21627156 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627156 = validateParameter(valid_21627156, JString, required = false,
                                   default = nil)
  if valid_21627156 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627156
  var valid_21627157 = header.getOrDefault("X-Amz-Credential")
  valid_21627157 = validateParameter(valid_21627157, JString, required = false,
                                   default = nil)
  if valid_21627157 != nil:
    section.add "X-Amz-Credential", valid_21627157
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21627159: Call_UpdateRepositoryDescription_21627147;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Sets or changes the comment or description for a repository.</p> <note> <p>The description field for a repository accepts all HTML characters and all valid Unicode characters. Applications that do not HTML-encode the description and display it in a webpage can expose users to potentially malicious code. Make sure that you HTML-encode the description field in any application that uses this API to display the repository description on a webpage.</p> </note>
  ## 
  let valid = call_21627159.validator(path, query, header, formData, body, _)
  let scheme = call_21627159.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627159.makeUrl(scheme.get, call_21627159.host, call_21627159.base,
                               call_21627159.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627159, uri, valid, _)

proc call*(call_21627160: Call_UpdateRepositoryDescription_21627147; body: JsonNode): Recallable =
  ## updateRepositoryDescription
  ## <p>Sets or changes the comment or description for a repository.</p> <note> <p>The description field for a repository accepts all HTML characters and all valid Unicode characters. Applications that do not HTML-encode the description and display it in a webpage can expose users to potentially malicious code. Make sure that you HTML-encode the description field in any application that uses this API to display the repository description on a webpage.</p> </note>
  ##   body: JObject (required)
  var body_21627161 = newJObject()
  if body != nil:
    body_21627161 = body
  result = call_21627160.call(nil, nil, nil, nil, body_21627161)

var updateRepositoryDescription* = Call_UpdateRepositoryDescription_21627147(
    name: "updateRepositoryDescription", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.UpdateRepositoryDescription",
    validator: validate_UpdateRepositoryDescription_21627148, base: "/",
    makeUrl: url_UpdateRepositoryDescription_21627149,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateRepositoryName_21627162 = ref object of OpenApiRestCall_21625435
proc url_UpdateRepositoryName_21627164(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateRepositoryName_21627163(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Renames a repository. The repository name must be unique across the calling AWS account. Repository names are limited to 100 alphanumeric, dash, and underscore characters, and cannot include certain characters. The suffix .git is prohibited. For more information about the limits on repository names, see <a href="https://docs.aws.amazon.com/codecommit/latest/userguide/limits.html">Limits</a> in the AWS CodeCommit User Guide.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627165 = header.getOrDefault("X-Amz-Date")
  valid_21627165 = validateParameter(valid_21627165, JString, required = false,
                                   default = nil)
  if valid_21627165 != nil:
    section.add "X-Amz-Date", valid_21627165
  var valid_21627166 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627166 = validateParameter(valid_21627166, JString, required = false,
                                   default = nil)
  if valid_21627166 != nil:
    section.add "X-Amz-Security-Token", valid_21627166
  var valid_21627167 = header.getOrDefault("X-Amz-Target")
  valid_21627167 = validateParameter(valid_21627167, JString, required = true, default = newJString(
      "CodeCommit_20150413.UpdateRepositoryName"))
  if valid_21627167 != nil:
    section.add "X-Amz-Target", valid_21627167
  var valid_21627168 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627168 = validateParameter(valid_21627168, JString, required = false,
                                   default = nil)
  if valid_21627168 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627168
  var valid_21627169 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627169 = validateParameter(valid_21627169, JString, required = false,
                                   default = nil)
  if valid_21627169 != nil:
    section.add "X-Amz-Algorithm", valid_21627169
  var valid_21627170 = header.getOrDefault("X-Amz-Signature")
  valid_21627170 = validateParameter(valid_21627170, JString, required = false,
                                   default = nil)
  if valid_21627170 != nil:
    section.add "X-Amz-Signature", valid_21627170
  var valid_21627171 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627171 = validateParameter(valid_21627171, JString, required = false,
                                   default = nil)
  if valid_21627171 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627171
  var valid_21627172 = header.getOrDefault("X-Amz-Credential")
  valid_21627172 = validateParameter(valid_21627172, JString, required = false,
                                   default = nil)
  if valid_21627172 != nil:
    section.add "X-Amz-Credential", valid_21627172
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21627174: Call_UpdateRepositoryName_21627162; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Renames a repository. The repository name must be unique across the calling AWS account. Repository names are limited to 100 alphanumeric, dash, and underscore characters, and cannot include certain characters. The suffix .git is prohibited. For more information about the limits on repository names, see <a href="https://docs.aws.amazon.com/codecommit/latest/userguide/limits.html">Limits</a> in the AWS CodeCommit User Guide.
  ## 
  let valid = call_21627174.validator(path, query, header, formData, body, _)
  let scheme = call_21627174.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627174.makeUrl(scheme.get, call_21627174.host, call_21627174.base,
                               call_21627174.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627174, uri, valid, _)

proc call*(call_21627175: Call_UpdateRepositoryName_21627162; body: JsonNode): Recallable =
  ## updateRepositoryName
  ## Renames a repository. The repository name must be unique across the calling AWS account. Repository names are limited to 100 alphanumeric, dash, and underscore characters, and cannot include certain characters. The suffix .git is prohibited. For more information about the limits on repository names, see <a href="https://docs.aws.amazon.com/codecommit/latest/userguide/limits.html">Limits</a> in the AWS CodeCommit User Guide.
  ##   body: JObject (required)
  var body_21627176 = newJObject()
  if body != nil:
    body_21627176 = body
  result = call_21627175.call(nil, nil, nil, nil, body_21627176)

var updateRepositoryName* = Call_UpdateRepositoryName_21627162(
    name: "updateRepositoryName", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.UpdateRepositoryName",
    validator: validate_UpdateRepositoryName_21627163, base: "/",
    makeUrl: url_UpdateRepositoryName_21627164,
    schemes: {Scheme.Https, Scheme.Http})
export
  rest

type
  EnvKind = enum
    BakeIntoBinary = "Baking $1 into the binary",
    FetchFromEnv = "Fetch $1 from the environment"
template sloppyConst(via: EnvKind; name: untyped): untyped =
  import
    macros

  const
    name {.strdefine.}: string = case via
    of BakeIntoBinary:
      getEnv(astToStr(name), "")
    of FetchFromEnv:
      ""
  static :
    let msg = block:
      if name == "":
        "Missing $1 in the environment"
      else:
        $via
    warning msg % [astToStr(name)]

sloppyConst FetchFromEnv, AWS_ACCESS_KEY_ID
sloppyConst FetchFromEnv, AWS_SECRET_ACCESS_KEY
sloppyConst BakeIntoBinary, AWS_REGION
sloppyConst FetchFromEnv, AWS_ACCOUNT_ID
type
  XAmz = enum
    SecurityToken = "X-Amz-Security-Token", ContentSha256 = "X-Amz-Content-Sha256"
proc atozSign(recall: var Recallable; query: JsonNode; algo: SigningAlgo = SHA256) =
  let
    date = makeDateTime()
    access = os.getEnv("AWS_ACCESS_KEY_ID", AWS_ACCESS_KEY_ID)
    secret = os.getEnv("AWS_SECRET_ACCESS_KEY", AWS_SECRET_ACCESS_KEY)
    region = os.getEnv("AWS_REGION", AWS_REGION)
  assert secret != "", "need $AWS_SECRET_ACCESS_KEY in environment"
  assert access != "", "need $AWS_ACCESS_KEY_ID in environment"
  assert region != "", "need $AWS_REGION in environment"
  var
    normal: PathNormal
    url = normalizeUrl(recall.url, query, normalize = normal)
    scheme = parseEnum[Scheme](url.scheme)
  assert scheme in awsServers, "unknown scheme `" & $scheme & "`"
  assert region in awsServers[scheme], "unknown region `" & region & "`"
  url.hostname = awsServers[scheme][region]
  case awsServiceName.toLowerAscii
  of "s3":
    normal = PathNormal.S3
  else:
    normal = PathNormal.Default
  recall.headers["Host"] = url.hostname
  recall.headers["X-Amz-Date"] = date
  recall.headers[$ContentSha256] = hash(recall.body, SHA256)
  let
    scope = credentialScope(region = region, service = awsServiceName, date = date)
    request = canonicalRequest(recall.meth, $url, query, recall.headers, recall.body,
                             normalize = normal, digest = algo)
    sts = stringToSign(request.hash(algo), scope, date = date, digest = algo)
    signature = calculateSignature(secret = secret, date = date, region = region,
                                 service = awsServiceName, sts, digest = algo)
  var auth = $algo & " "
  auth &= "Credential=" & access / scope & ", "
  auth &= "SignedHeaders=" & recall.headers.signedHeaders & ", "
  auth &= "Signature=" & signature
  recall.headers["Authorization"] = auth
  recall.headers.del "Host"
  recall.url = $url

method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode; body = ""): Recallable {.
    base.} =
  ## the hook is a terrible earworm
  var
    headers = newHttpHeaders(massageHeaders(input.getOrDefault("header")))
    text = body
  if text.len == 0 and "body" in input:
    text = input.getOrDefault("body").getStr
    if not headers.hasKey("content-type"):
      headers["content-type"] = "application/x-amz-json-1.0"
  else:
    headers["content-md5"] = base64.encode text.toMD5
  if not headers.hasKey($SecurityToken):
    let session = getEnv("AWS_SESSION_TOKEN", "")
    if session != "":
      headers[$SecurityToken] = session
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)

when not defined(ssl):
  {.error: "use ssl".}