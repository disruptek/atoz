
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5,
  base64, httpcore, sigv4

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
  Scheme* {.pure.} = enum
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

  OpenApiRestCall_402656044 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_402656044](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base,
             route: t.route, schemes: t.schemes, validator: t.validator,
             url: t.url)

proc pickScheme(t: OpenApiRestCall_402656044): Option[Scheme] {.used.} =
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

proc hydratePath(input: JsonNode; segments: seq[PathToken]): Option[string] {.
    used.} =
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
  awsServers = {Scheme.Https: {"ap-northeast-1": "codecommit.ap-northeast-1.amazonaws.com", "ap-southeast-1": "codecommit.ap-southeast-1.amazonaws.com", "us-west-2": "codecommit.us-west-2.amazonaws.com", "eu-west-2": "codecommit.eu-west-2.amazonaws.com", "ap-northeast-3": "codecommit.ap-northeast-3.amazonaws.com", "eu-central-1": "codecommit.eu-central-1.amazonaws.com", "us-east-2": "codecommit.us-east-2.amazonaws.com", "us-east-1": "codecommit.us-east-1.amazonaws.com", "cn-northwest-1": "codecommit.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "codecommit.ap-south-1.amazonaws.com", "eu-north-1": "codecommit.eu-north-1.amazonaws.com", "ap-northeast-2": "codecommit.ap-northeast-2.amazonaws.com", "us-west-1": "codecommit.us-west-1.amazonaws.com", "us-gov-east-1": "codecommit.us-gov-east-1.amazonaws.com", "eu-west-3": "codecommit.eu-west-3.amazonaws.com", "cn-north-1": "codecommit.cn-north-1.amazonaws.com.cn", "sa-east-1": "codecommit.sa-east-1.amazonaws.com", "eu-west-1": "codecommit.eu-west-1.amazonaws.com", "us-gov-west-1": "codecommit.us-gov-west-1.amazonaws.com", "ap-southeast-2": "codecommit.ap-southeast-2.amazonaws.com", "ca-central-1": "codecommit.ca-central-1.amazonaws.com"}.toTable, Scheme.Http: {
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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode;
                body: string = ""): Recallable {.base.}
type
  Call_AssociateApprovalRuleTemplateWithRepository_402656294 = ref object of OpenApiRestCall_402656044
proc url_AssociateApprovalRuleTemplateWithRepository_402656296(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AssociateApprovalRuleTemplateWithRepository_402656295(
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656390 = header.getOrDefault("X-Amz-Target")
  valid_402656390 = validateParameter(valid_402656390, JString, required = true, default = newJString(
      "CodeCommit_20150413.AssociateApprovalRuleTemplateWithRepository"))
  if valid_402656390 != nil:
    section.add "X-Amz-Target", valid_402656390
  var valid_402656391 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656391 = validateParameter(valid_402656391, JString,
                                      required = false, default = nil)
  if valid_402656391 != nil:
    section.add "X-Amz-Security-Token", valid_402656391
  var valid_402656392 = header.getOrDefault("X-Amz-Signature")
  valid_402656392 = validateParameter(valid_402656392, JString,
                                      required = false, default = nil)
  if valid_402656392 != nil:
    section.add "X-Amz-Signature", valid_402656392
  var valid_402656393 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656393 = validateParameter(valid_402656393, JString,
                                      required = false, default = nil)
  if valid_402656393 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656393
  var valid_402656394 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656394 = validateParameter(valid_402656394, JString,
                                      required = false, default = nil)
  if valid_402656394 != nil:
    section.add "X-Amz-Algorithm", valid_402656394
  var valid_402656395 = header.getOrDefault("X-Amz-Date")
  valid_402656395 = validateParameter(valid_402656395, JString,
                                      required = false, default = nil)
  if valid_402656395 != nil:
    section.add "X-Amz-Date", valid_402656395
  var valid_402656396 = header.getOrDefault("X-Amz-Credential")
  valid_402656396 = validateParameter(valid_402656396, JString,
                                      required = false, default = nil)
  if valid_402656396 != nil:
    section.add "X-Amz-Credential", valid_402656396
  var valid_402656397 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656397 = validateParameter(valid_402656397, JString,
                                      required = false, default = nil)
  if valid_402656397 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656397
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

proc call*(call_402656412: Call_AssociateApprovalRuleTemplateWithRepository_402656294;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates an association between an approval rule template and a specified repository. Then, the next time a pull request is created in the repository where the destination reference (if specified) matches the destination reference (branch) for the pull request, an approval rule that matches the template conditions is automatically created for that pull request. If no destination references are specified in the template, an approval rule that matches the template contents is created for all pull requests in that repository.
                                                                                         ## 
  let valid = call_402656412.validator(path, query, header, formData, body, _)
  let scheme = call_402656412.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656412.makeUrl(scheme.get, call_402656412.host, call_402656412.base,
                                   call_402656412.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656412, uri, valid, _)

proc call*(call_402656461: Call_AssociateApprovalRuleTemplateWithRepository_402656294;
           body: JsonNode): Recallable =
  ## associateApprovalRuleTemplateWithRepository
  ## Creates an association between an approval rule template and a specified repository. Then, the next time a pull request is created in the repository where the destination reference (if specified) matches the destination reference (branch) for the pull request, an approval rule that matches the template conditions is automatically created for that pull request. If no destination references are specified in the template, an approval rule that matches the template contents is created for all pull requests in that repository.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## body: JObject (required)
  var body_402656462 = newJObject()
  if body != nil:
    body_402656462 = body
  result = call_402656461.call(nil, nil, nil, nil, body_402656462)

var associateApprovalRuleTemplateWithRepository* = Call_AssociateApprovalRuleTemplateWithRepository_402656294(
    name: "associateApprovalRuleTemplateWithRepository",
    meth: HttpMethod.HttpPost, host: "codecommit.amazonaws.com", route: "/#X-Amz-Target=CodeCommit_20150413.AssociateApprovalRuleTemplateWithRepository",
    validator: validate_AssociateApprovalRuleTemplateWithRepository_402656295,
    base: "/", makeUrl: url_AssociateApprovalRuleTemplateWithRepository_402656296,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchAssociateApprovalRuleTemplateWithRepositories_402656489 = ref object of OpenApiRestCall_402656044
proc url_BatchAssociateApprovalRuleTemplateWithRepositories_402656491(
    protocol: Scheme; host: string; base: string; route: string; path: JsonNode;
    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_BatchAssociateApprovalRuleTemplateWithRepositories_402656490(
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656492 = header.getOrDefault("X-Amz-Target")
  valid_402656492 = validateParameter(valid_402656492, JString, required = true, default = newJString(
      "CodeCommit_20150413.BatchAssociateApprovalRuleTemplateWithRepositories"))
  if valid_402656492 != nil:
    section.add "X-Amz-Target", valid_402656492
  var valid_402656493 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656493 = validateParameter(valid_402656493, JString,
                                      required = false, default = nil)
  if valid_402656493 != nil:
    section.add "X-Amz-Security-Token", valid_402656493
  var valid_402656494 = header.getOrDefault("X-Amz-Signature")
  valid_402656494 = validateParameter(valid_402656494, JString,
                                      required = false, default = nil)
  if valid_402656494 != nil:
    section.add "X-Amz-Signature", valid_402656494
  var valid_402656495 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656495 = validateParameter(valid_402656495, JString,
                                      required = false, default = nil)
  if valid_402656495 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656495
  var valid_402656496 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656496 = validateParameter(valid_402656496, JString,
                                      required = false, default = nil)
  if valid_402656496 != nil:
    section.add "X-Amz-Algorithm", valid_402656496
  var valid_402656497 = header.getOrDefault("X-Amz-Date")
  valid_402656497 = validateParameter(valid_402656497, JString,
                                      required = false, default = nil)
  if valid_402656497 != nil:
    section.add "X-Amz-Date", valid_402656497
  var valid_402656498 = header.getOrDefault("X-Amz-Credential")
  valid_402656498 = validateParameter(valid_402656498, JString,
                                      required = false, default = nil)
  if valid_402656498 != nil:
    section.add "X-Amz-Credential", valid_402656498
  var valid_402656499 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656499 = validateParameter(valid_402656499, JString,
                                      required = false, default = nil)
  if valid_402656499 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656499
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

proc call*(call_402656501: Call_BatchAssociateApprovalRuleTemplateWithRepositories_402656489;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates an association between an approval rule template and one or more specified repositories. 
                                                                                         ## 
  let valid = call_402656501.validator(path, query, header, formData, body, _)
  let scheme = call_402656501.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656501.makeUrl(scheme.get, call_402656501.host, call_402656501.base,
                                   call_402656501.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656501, uri, valid, _)

proc call*(call_402656502: Call_BatchAssociateApprovalRuleTemplateWithRepositories_402656489;
           body: JsonNode): Recallable =
  ## batchAssociateApprovalRuleTemplateWithRepositories
  ## Creates an association between an approval rule template and one or more specified repositories. 
  ##   
                                                                                                      ## body: JObject (required)
  var body_402656503 = newJObject()
  if body != nil:
    body_402656503 = body
  result = call_402656502.call(nil, nil, nil, nil, body_402656503)

var batchAssociateApprovalRuleTemplateWithRepositories* = Call_BatchAssociateApprovalRuleTemplateWithRepositories_402656489(
    name: "batchAssociateApprovalRuleTemplateWithRepositories",
    meth: HttpMethod.HttpPost, host: "codecommit.amazonaws.com", route: "/#X-Amz-Target=CodeCommit_20150413.BatchAssociateApprovalRuleTemplateWithRepositories",
    validator: validate_BatchAssociateApprovalRuleTemplateWithRepositories_402656490,
    base: "/", makeUrl: url_BatchAssociateApprovalRuleTemplateWithRepositories_402656491,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchDescribeMergeConflicts_402656504 = ref object of OpenApiRestCall_402656044
proc url_BatchDescribeMergeConflicts_402656506(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_BatchDescribeMergeConflicts_402656505(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Returns information about one or more merge conflicts in the attempted merge of two commit specifiers using the squash or three-way merge strategy.
                                            ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656507 = header.getOrDefault("X-Amz-Target")
  valid_402656507 = validateParameter(valid_402656507, JString, required = true, default = newJString(
      "CodeCommit_20150413.BatchDescribeMergeConflicts"))
  if valid_402656507 != nil:
    section.add "X-Amz-Target", valid_402656507
  var valid_402656508 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656508 = validateParameter(valid_402656508, JString,
                                      required = false, default = nil)
  if valid_402656508 != nil:
    section.add "X-Amz-Security-Token", valid_402656508
  var valid_402656509 = header.getOrDefault("X-Amz-Signature")
  valid_402656509 = validateParameter(valid_402656509, JString,
                                      required = false, default = nil)
  if valid_402656509 != nil:
    section.add "X-Amz-Signature", valid_402656509
  var valid_402656510 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656510 = validateParameter(valid_402656510, JString,
                                      required = false, default = nil)
  if valid_402656510 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656510
  var valid_402656511 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656511 = validateParameter(valid_402656511, JString,
                                      required = false, default = nil)
  if valid_402656511 != nil:
    section.add "X-Amz-Algorithm", valid_402656511
  var valid_402656512 = header.getOrDefault("X-Amz-Date")
  valid_402656512 = validateParameter(valid_402656512, JString,
                                      required = false, default = nil)
  if valid_402656512 != nil:
    section.add "X-Amz-Date", valid_402656512
  var valid_402656513 = header.getOrDefault("X-Amz-Credential")
  valid_402656513 = validateParameter(valid_402656513, JString,
                                      required = false, default = nil)
  if valid_402656513 != nil:
    section.add "X-Amz-Credential", valid_402656513
  var valid_402656514 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656514 = validateParameter(valid_402656514, JString,
                                      required = false, default = nil)
  if valid_402656514 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656514
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

proc call*(call_402656516: Call_BatchDescribeMergeConflicts_402656504;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns information about one or more merge conflicts in the attempted merge of two commit specifiers using the squash or three-way merge strategy.
                                                                                         ## 
  let valid = call_402656516.validator(path, query, header, formData, body, _)
  let scheme = call_402656516.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656516.makeUrl(scheme.get, call_402656516.host, call_402656516.base,
                                   call_402656516.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656516, uri, valid, _)

proc call*(call_402656517: Call_BatchDescribeMergeConflicts_402656504;
           body: JsonNode): Recallable =
  ## batchDescribeMergeConflicts
  ## Returns information about one or more merge conflicts in the attempted merge of two commit specifiers using the squash or three-way merge strategy.
  ##   
                                                                                                                                                        ## body: JObject (required)
  var body_402656518 = newJObject()
  if body != nil:
    body_402656518 = body
  result = call_402656517.call(nil, nil, nil, nil, body_402656518)

var batchDescribeMergeConflicts* = Call_BatchDescribeMergeConflicts_402656504(
    name: "batchDescribeMergeConflicts", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.BatchDescribeMergeConflicts",
    validator: validate_BatchDescribeMergeConflicts_402656505, base: "/",
    makeUrl: url_BatchDescribeMergeConflicts_402656506,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchDisassociateApprovalRuleTemplateFromRepositories_402656519 = ref object of OpenApiRestCall_402656044
proc url_BatchDisassociateApprovalRuleTemplateFromRepositories_402656521(
    protocol: Scheme; host: string; base: string; route: string; path: JsonNode;
    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_BatchDisassociateApprovalRuleTemplateFromRepositories_402656520(
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656522 = header.getOrDefault("X-Amz-Target")
  valid_402656522 = validateParameter(valid_402656522, JString, required = true, default = newJString("CodeCommit_20150413.BatchDisassociateApprovalRuleTemplateFromRepositories"))
  if valid_402656522 != nil:
    section.add "X-Amz-Target", valid_402656522
  var valid_402656523 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656523 = validateParameter(valid_402656523, JString,
                                      required = false, default = nil)
  if valid_402656523 != nil:
    section.add "X-Amz-Security-Token", valid_402656523
  var valid_402656524 = header.getOrDefault("X-Amz-Signature")
  valid_402656524 = validateParameter(valid_402656524, JString,
                                      required = false, default = nil)
  if valid_402656524 != nil:
    section.add "X-Amz-Signature", valid_402656524
  var valid_402656525 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656525 = validateParameter(valid_402656525, JString,
                                      required = false, default = nil)
  if valid_402656525 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656525
  var valid_402656526 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656526 = validateParameter(valid_402656526, JString,
                                      required = false, default = nil)
  if valid_402656526 != nil:
    section.add "X-Amz-Algorithm", valid_402656526
  var valid_402656527 = header.getOrDefault("X-Amz-Date")
  valid_402656527 = validateParameter(valid_402656527, JString,
                                      required = false, default = nil)
  if valid_402656527 != nil:
    section.add "X-Amz-Date", valid_402656527
  var valid_402656528 = header.getOrDefault("X-Amz-Credential")
  valid_402656528 = validateParameter(valid_402656528, JString,
                                      required = false, default = nil)
  if valid_402656528 != nil:
    section.add "X-Amz-Credential", valid_402656528
  var valid_402656529 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656529 = validateParameter(valid_402656529, JString,
                                      required = false, default = nil)
  if valid_402656529 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656529
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

proc call*(call_402656531: Call_BatchDisassociateApprovalRuleTemplateFromRepositories_402656519;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Removes the association between an approval rule template and one or more specified repositories. 
                                                                                         ## 
  let valid = call_402656531.validator(path, query, header, formData, body, _)
  let scheme = call_402656531.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656531.makeUrl(scheme.get, call_402656531.host, call_402656531.base,
                                   call_402656531.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656531, uri, valid, _)

proc call*(call_402656532: Call_BatchDisassociateApprovalRuleTemplateFromRepositories_402656519;
           body: JsonNode): Recallable =
  ## batchDisassociateApprovalRuleTemplateFromRepositories
  ## Removes the association between an approval rule template and one or more specified repositories. 
  ##   
                                                                                                       ## body: JObject (required)
  var body_402656533 = newJObject()
  if body != nil:
    body_402656533 = body
  result = call_402656532.call(nil, nil, nil, nil, body_402656533)

var batchDisassociateApprovalRuleTemplateFromRepositories* = Call_BatchDisassociateApprovalRuleTemplateFromRepositories_402656519(
    name: "batchDisassociateApprovalRuleTemplateFromRepositories",
    meth: HttpMethod.HttpPost, host: "codecommit.amazonaws.com", route: "/#X-Amz-Target=CodeCommit_20150413.BatchDisassociateApprovalRuleTemplateFromRepositories",
    validator: validate_BatchDisassociateApprovalRuleTemplateFromRepositories_402656520,
    base: "/",
    makeUrl: url_BatchDisassociateApprovalRuleTemplateFromRepositories_402656521,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchGetCommits_402656534 = ref object of OpenApiRestCall_402656044
proc url_BatchGetCommits_402656536(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode;
                                   query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_BatchGetCommits_402656535(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656537 = header.getOrDefault("X-Amz-Target")
  valid_402656537 = validateParameter(valid_402656537, JString, required = true, default = newJString(
      "CodeCommit_20150413.BatchGetCommits"))
  if valid_402656537 != nil:
    section.add "X-Amz-Target", valid_402656537
  var valid_402656538 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656538 = validateParameter(valid_402656538, JString,
                                      required = false, default = nil)
  if valid_402656538 != nil:
    section.add "X-Amz-Security-Token", valid_402656538
  var valid_402656539 = header.getOrDefault("X-Amz-Signature")
  valid_402656539 = validateParameter(valid_402656539, JString,
                                      required = false, default = nil)
  if valid_402656539 != nil:
    section.add "X-Amz-Signature", valid_402656539
  var valid_402656540 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656540 = validateParameter(valid_402656540, JString,
                                      required = false, default = nil)
  if valid_402656540 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656540
  var valid_402656541 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656541 = validateParameter(valid_402656541, JString,
                                      required = false, default = nil)
  if valid_402656541 != nil:
    section.add "X-Amz-Algorithm", valid_402656541
  var valid_402656542 = header.getOrDefault("X-Amz-Date")
  valid_402656542 = validateParameter(valid_402656542, JString,
                                      required = false, default = nil)
  if valid_402656542 != nil:
    section.add "X-Amz-Date", valid_402656542
  var valid_402656543 = header.getOrDefault("X-Amz-Credential")
  valid_402656543 = validateParameter(valid_402656543, JString,
                                      required = false, default = nil)
  if valid_402656543 != nil:
    section.add "X-Amz-Credential", valid_402656543
  var valid_402656544 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656544 = validateParameter(valid_402656544, JString,
                                      required = false, default = nil)
  if valid_402656544 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656544
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

proc call*(call_402656546: Call_BatchGetCommits_402656534; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns information about the contents of one or more commits in a repository.
                                                                                         ## 
  let valid = call_402656546.validator(path, query, header, formData, body, _)
  let scheme = call_402656546.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656546.makeUrl(scheme.get, call_402656546.host, call_402656546.base,
                                   call_402656546.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656546, uri, valid, _)

proc call*(call_402656547: Call_BatchGetCommits_402656534; body: JsonNode): Recallable =
  ## batchGetCommits
  ## Returns information about the contents of one or more commits in a repository.
  ##   
                                                                                   ## body: JObject (required)
  var body_402656548 = newJObject()
  if body != nil:
    body_402656548 = body
  result = call_402656547.call(nil, nil, nil, nil, body_402656548)

var batchGetCommits* = Call_BatchGetCommits_402656534(name: "batchGetCommits",
    meth: HttpMethod.HttpPost, host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.BatchGetCommits",
    validator: validate_BatchGetCommits_402656535, base: "/",
    makeUrl: url_BatchGetCommits_402656536, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchGetRepositories_402656549 = ref object of OpenApiRestCall_402656044
proc url_BatchGetRepositories_402656551(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_BatchGetRepositories_402656550(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656552 = header.getOrDefault("X-Amz-Target")
  valid_402656552 = validateParameter(valid_402656552, JString, required = true, default = newJString(
      "CodeCommit_20150413.BatchGetRepositories"))
  if valid_402656552 != nil:
    section.add "X-Amz-Target", valid_402656552
  var valid_402656553 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656553 = validateParameter(valid_402656553, JString,
                                      required = false, default = nil)
  if valid_402656553 != nil:
    section.add "X-Amz-Security-Token", valid_402656553
  var valid_402656554 = header.getOrDefault("X-Amz-Signature")
  valid_402656554 = validateParameter(valid_402656554, JString,
                                      required = false, default = nil)
  if valid_402656554 != nil:
    section.add "X-Amz-Signature", valid_402656554
  var valid_402656555 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656555 = validateParameter(valid_402656555, JString,
                                      required = false, default = nil)
  if valid_402656555 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656555
  var valid_402656556 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656556 = validateParameter(valid_402656556, JString,
                                      required = false, default = nil)
  if valid_402656556 != nil:
    section.add "X-Amz-Algorithm", valid_402656556
  var valid_402656557 = header.getOrDefault("X-Amz-Date")
  valid_402656557 = validateParameter(valid_402656557, JString,
                                      required = false, default = nil)
  if valid_402656557 != nil:
    section.add "X-Amz-Date", valid_402656557
  var valid_402656558 = header.getOrDefault("X-Amz-Credential")
  valid_402656558 = validateParameter(valid_402656558, JString,
                                      required = false, default = nil)
  if valid_402656558 != nil:
    section.add "X-Amz-Credential", valid_402656558
  var valid_402656559 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656559 = validateParameter(valid_402656559, JString,
                                      required = false, default = nil)
  if valid_402656559 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656559
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

proc call*(call_402656561: Call_BatchGetRepositories_402656549;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns information about one or more repositories.</p> <note> <p>The description field for a repository accepts all HTML characters and all valid Unicode characters. Applications that do not HTML-encode the description and display it in a webpage can expose users to potentially malicious code. Make sure that you HTML-encode the description field in any application that uses this API to display the repository description on a webpage.</p> </note>
                                                                                         ## 
  let valid = call_402656561.validator(path, query, header, formData, body, _)
  let scheme = call_402656561.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656561.makeUrl(scheme.get, call_402656561.host, call_402656561.base,
                                   call_402656561.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656561, uri, valid, _)

proc call*(call_402656562: Call_BatchGetRepositories_402656549; body: JsonNode): Recallable =
  ## batchGetRepositories
  ## <p>Returns information about one or more repositories.</p> <note> <p>The description field for a repository accepts all HTML characters and all valid Unicode characters. Applications that do not HTML-encode the description and display it in a webpage can expose users to potentially malicious code. Make sure that you HTML-encode the description field in any application that uses this API to display the repository description on a webpage.</p> </note>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## body: JObject (required)
  var body_402656563 = newJObject()
  if body != nil:
    body_402656563 = body
  result = call_402656562.call(nil, nil, nil, nil, body_402656563)

var batchGetRepositories* = Call_BatchGetRepositories_402656549(
    name: "batchGetRepositories", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.BatchGetRepositories",
    validator: validate_BatchGetRepositories_402656550, base: "/",
    makeUrl: url_BatchGetRepositories_402656551,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateApprovalRuleTemplate_402656564 = ref object of OpenApiRestCall_402656044
proc url_CreateApprovalRuleTemplate_402656566(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateApprovalRuleTemplate_402656565(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Creates a template for approval rules that can then be associated with one or more repositories in your AWS account. When you associate a template with a repository, AWS CodeCommit creates an approval rule that matches the conditions of the template for all pull requests that meet the conditions of the template. For more information, see <a>AssociateApprovalRuleTemplateWithRepository</a>.
                                            ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656567 = header.getOrDefault("X-Amz-Target")
  valid_402656567 = validateParameter(valid_402656567, JString, required = true, default = newJString(
      "CodeCommit_20150413.CreateApprovalRuleTemplate"))
  if valid_402656567 != nil:
    section.add "X-Amz-Target", valid_402656567
  var valid_402656568 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656568 = validateParameter(valid_402656568, JString,
                                      required = false, default = nil)
  if valid_402656568 != nil:
    section.add "X-Amz-Security-Token", valid_402656568
  var valid_402656569 = header.getOrDefault("X-Amz-Signature")
  valid_402656569 = validateParameter(valid_402656569, JString,
                                      required = false, default = nil)
  if valid_402656569 != nil:
    section.add "X-Amz-Signature", valid_402656569
  var valid_402656570 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656570 = validateParameter(valid_402656570, JString,
                                      required = false, default = nil)
  if valid_402656570 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656570
  var valid_402656571 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656571 = validateParameter(valid_402656571, JString,
                                      required = false, default = nil)
  if valid_402656571 != nil:
    section.add "X-Amz-Algorithm", valid_402656571
  var valid_402656572 = header.getOrDefault("X-Amz-Date")
  valid_402656572 = validateParameter(valid_402656572, JString,
                                      required = false, default = nil)
  if valid_402656572 != nil:
    section.add "X-Amz-Date", valid_402656572
  var valid_402656573 = header.getOrDefault("X-Amz-Credential")
  valid_402656573 = validateParameter(valid_402656573, JString,
                                      required = false, default = nil)
  if valid_402656573 != nil:
    section.add "X-Amz-Credential", valid_402656573
  var valid_402656574 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656574 = validateParameter(valid_402656574, JString,
                                      required = false, default = nil)
  if valid_402656574 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656574
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

proc call*(call_402656576: Call_CreateApprovalRuleTemplate_402656564;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a template for approval rules that can then be associated with one or more repositories in your AWS account. When you associate a template with a repository, AWS CodeCommit creates an approval rule that matches the conditions of the template for all pull requests that meet the conditions of the template. For more information, see <a>AssociateApprovalRuleTemplateWithRepository</a>.
                                                                                         ## 
  let valid = call_402656576.validator(path, query, header, formData, body, _)
  let scheme = call_402656576.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656576.makeUrl(scheme.get, call_402656576.host, call_402656576.base,
                                   call_402656576.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656576, uri, valid, _)

proc call*(call_402656577: Call_CreateApprovalRuleTemplate_402656564;
           body: JsonNode): Recallable =
  ## createApprovalRuleTemplate
  ## Creates a template for approval rules that can then be associated with one or more repositories in your AWS account. When you associate a template with a repository, AWS CodeCommit creates an approval rule that matches the conditions of the template for all pull requests that meet the conditions of the template. For more information, see <a>AssociateApprovalRuleTemplateWithRepository</a>.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                            ## body: JObject (required)
  var body_402656578 = newJObject()
  if body != nil:
    body_402656578 = body
  result = call_402656577.call(nil, nil, nil, nil, body_402656578)

var createApprovalRuleTemplate* = Call_CreateApprovalRuleTemplate_402656564(
    name: "createApprovalRuleTemplate", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.CreateApprovalRuleTemplate",
    validator: validate_CreateApprovalRuleTemplate_402656565, base: "/",
    makeUrl: url_CreateApprovalRuleTemplate_402656566,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateBranch_402656579 = ref object of OpenApiRestCall_402656044
proc url_CreateBranch_402656581(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateBranch_402656580(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Creates a branch in a repository and points the branch to a commit.</p> <note> <p>Calling the create branch operation does not set a repository's default branch. To do this, call the update default branch operation.</p> </note>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656582 = header.getOrDefault("X-Amz-Target")
  valid_402656582 = validateParameter(valid_402656582, JString, required = true, default = newJString(
      "CodeCommit_20150413.CreateBranch"))
  if valid_402656582 != nil:
    section.add "X-Amz-Target", valid_402656582
  var valid_402656583 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656583 = validateParameter(valid_402656583, JString,
                                      required = false, default = nil)
  if valid_402656583 != nil:
    section.add "X-Amz-Security-Token", valid_402656583
  var valid_402656584 = header.getOrDefault("X-Amz-Signature")
  valid_402656584 = validateParameter(valid_402656584, JString,
                                      required = false, default = nil)
  if valid_402656584 != nil:
    section.add "X-Amz-Signature", valid_402656584
  var valid_402656585 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656585 = validateParameter(valid_402656585, JString,
                                      required = false, default = nil)
  if valid_402656585 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656585
  var valid_402656586 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656586 = validateParameter(valid_402656586, JString,
                                      required = false, default = nil)
  if valid_402656586 != nil:
    section.add "X-Amz-Algorithm", valid_402656586
  var valid_402656587 = header.getOrDefault("X-Amz-Date")
  valid_402656587 = validateParameter(valid_402656587, JString,
                                      required = false, default = nil)
  if valid_402656587 != nil:
    section.add "X-Amz-Date", valid_402656587
  var valid_402656588 = header.getOrDefault("X-Amz-Credential")
  valid_402656588 = validateParameter(valid_402656588, JString,
                                      required = false, default = nil)
  if valid_402656588 != nil:
    section.add "X-Amz-Credential", valid_402656588
  var valid_402656589 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656589 = validateParameter(valid_402656589, JString,
                                      required = false, default = nil)
  if valid_402656589 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656589
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

proc call*(call_402656591: Call_CreateBranch_402656579; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates a branch in a repository and points the branch to a commit.</p> <note> <p>Calling the create branch operation does not set a repository's default branch. To do this, call the update default branch operation.</p> </note>
                                                                                         ## 
  let valid = call_402656591.validator(path, query, header, formData, body, _)
  let scheme = call_402656591.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656591.makeUrl(scheme.get, call_402656591.host, call_402656591.base,
                                   call_402656591.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656591, uri, valid, _)

proc call*(call_402656592: Call_CreateBranch_402656579; body: JsonNode): Recallable =
  ## createBranch
  ## <p>Creates a branch in a repository and points the branch to a commit.</p> <note> <p>Calling the create branch operation does not set a repository's default branch. To do this, call the update default branch operation.</p> </note>
  ##   
                                                                                                                                                                                                                                           ## body: JObject (required)
  var body_402656593 = newJObject()
  if body != nil:
    body_402656593 = body
  result = call_402656592.call(nil, nil, nil, nil, body_402656593)

var createBranch* = Call_CreateBranch_402656579(name: "createBranch",
    meth: HttpMethod.HttpPost, host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.CreateBranch",
    validator: validate_CreateBranch_402656580, base: "/",
    makeUrl: url_CreateBranch_402656581, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateCommit_402656594 = ref object of OpenApiRestCall_402656044
proc url_CreateCommit_402656596(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateCommit_402656595(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Creates a commit for a repository on the tip of a specified branch.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656597 = header.getOrDefault("X-Amz-Target")
  valid_402656597 = validateParameter(valid_402656597, JString, required = true, default = newJString(
      "CodeCommit_20150413.CreateCommit"))
  if valid_402656597 != nil:
    section.add "X-Amz-Target", valid_402656597
  var valid_402656598 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656598 = validateParameter(valid_402656598, JString,
                                      required = false, default = nil)
  if valid_402656598 != nil:
    section.add "X-Amz-Security-Token", valid_402656598
  var valid_402656599 = header.getOrDefault("X-Amz-Signature")
  valid_402656599 = validateParameter(valid_402656599, JString,
                                      required = false, default = nil)
  if valid_402656599 != nil:
    section.add "X-Amz-Signature", valid_402656599
  var valid_402656600 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656600 = validateParameter(valid_402656600, JString,
                                      required = false, default = nil)
  if valid_402656600 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656600
  var valid_402656601 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656601 = validateParameter(valid_402656601, JString,
                                      required = false, default = nil)
  if valid_402656601 != nil:
    section.add "X-Amz-Algorithm", valid_402656601
  var valid_402656602 = header.getOrDefault("X-Amz-Date")
  valid_402656602 = validateParameter(valid_402656602, JString,
                                      required = false, default = nil)
  if valid_402656602 != nil:
    section.add "X-Amz-Date", valid_402656602
  var valid_402656603 = header.getOrDefault("X-Amz-Credential")
  valid_402656603 = validateParameter(valid_402656603, JString,
                                      required = false, default = nil)
  if valid_402656603 != nil:
    section.add "X-Amz-Credential", valid_402656603
  var valid_402656604 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656604 = validateParameter(valid_402656604, JString,
                                      required = false, default = nil)
  if valid_402656604 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656604
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

proc call*(call_402656606: Call_CreateCommit_402656594; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a commit for a repository on the tip of a specified branch.
                                                                                         ## 
  let valid = call_402656606.validator(path, query, header, formData, body, _)
  let scheme = call_402656606.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656606.makeUrl(scheme.get, call_402656606.host, call_402656606.base,
                                   call_402656606.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656606, uri, valid, _)

proc call*(call_402656607: Call_CreateCommit_402656594; body: JsonNode): Recallable =
  ## createCommit
  ## Creates a commit for a repository on the tip of a specified branch.
  ##   body: JObject 
                                                                        ## (required)
  var body_402656608 = newJObject()
  if body != nil:
    body_402656608 = body
  result = call_402656607.call(nil, nil, nil, nil, body_402656608)

var createCommit* = Call_CreateCommit_402656594(name: "createCommit",
    meth: HttpMethod.HttpPost, host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.CreateCommit",
    validator: validate_CreateCommit_402656595, base: "/",
    makeUrl: url_CreateCommit_402656596, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePullRequest_402656609 = ref object of OpenApiRestCall_402656044
proc url_CreatePullRequest_402656611(protocol: Scheme; host: string;
                                     base: string; route: string;
                                     path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreatePullRequest_402656610(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656612 = header.getOrDefault("X-Amz-Target")
  valid_402656612 = validateParameter(valid_402656612, JString, required = true, default = newJString(
      "CodeCommit_20150413.CreatePullRequest"))
  if valid_402656612 != nil:
    section.add "X-Amz-Target", valid_402656612
  var valid_402656613 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656613 = validateParameter(valid_402656613, JString,
                                      required = false, default = nil)
  if valid_402656613 != nil:
    section.add "X-Amz-Security-Token", valid_402656613
  var valid_402656614 = header.getOrDefault("X-Amz-Signature")
  valid_402656614 = validateParameter(valid_402656614, JString,
                                      required = false, default = nil)
  if valid_402656614 != nil:
    section.add "X-Amz-Signature", valid_402656614
  var valid_402656615 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656615 = validateParameter(valid_402656615, JString,
                                      required = false, default = nil)
  if valid_402656615 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656615
  var valid_402656616 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656616 = validateParameter(valid_402656616, JString,
                                      required = false, default = nil)
  if valid_402656616 != nil:
    section.add "X-Amz-Algorithm", valid_402656616
  var valid_402656617 = header.getOrDefault("X-Amz-Date")
  valid_402656617 = validateParameter(valid_402656617, JString,
                                      required = false, default = nil)
  if valid_402656617 != nil:
    section.add "X-Amz-Date", valid_402656617
  var valid_402656618 = header.getOrDefault("X-Amz-Credential")
  valid_402656618 = validateParameter(valid_402656618, JString,
                                      required = false, default = nil)
  if valid_402656618 != nil:
    section.add "X-Amz-Credential", valid_402656618
  var valid_402656619 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656619 = validateParameter(valid_402656619, JString,
                                      required = false, default = nil)
  if valid_402656619 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656619
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

proc call*(call_402656621: Call_CreatePullRequest_402656609;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a pull request in the specified repository.
                                                                                         ## 
  let valid = call_402656621.validator(path, query, header, formData, body, _)
  let scheme = call_402656621.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656621.makeUrl(scheme.get, call_402656621.host, call_402656621.base,
                                   call_402656621.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656621, uri, valid, _)

proc call*(call_402656622: Call_CreatePullRequest_402656609; body: JsonNode): Recallable =
  ## createPullRequest
  ## Creates a pull request in the specified repository.
  ##   body: JObject (required)
  var body_402656623 = newJObject()
  if body != nil:
    body_402656623 = body
  result = call_402656622.call(nil, nil, nil, nil, body_402656623)

var createPullRequest* = Call_CreatePullRequest_402656609(
    name: "createPullRequest", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.CreatePullRequest",
    validator: validate_CreatePullRequest_402656610, base: "/",
    makeUrl: url_CreatePullRequest_402656611,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePullRequestApprovalRule_402656624 = ref object of OpenApiRestCall_402656044
proc url_CreatePullRequestApprovalRule_402656626(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreatePullRequestApprovalRule_402656625(path: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656627 = header.getOrDefault("X-Amz-Target")
  valid_402656627 = validateParameter(valid_402656627, JString, required = true, default = newJString(
      "CodeCommit_20150413.CreatePullRequestApprovalRule"))
  if valid_402656627 != nil:
    section.add "X-Amz-Target", valid_402656627
  var valid_402656628 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656628 = validateParameter(valid_402656628, JString,
                                      required = false, default = nil)
  if valid_402656628 != nil:
    section.add "X-Amz-Security-Token", valid_402656628
  var valid_402656629 = header.getOrDefault("X-Amz-Signature")
  valid_402656629 = validateParameter(valid_402656629, JString,
                                      required = false, default = nil)
  if valid_402656629 != nil:
    section.add "X-Amz-Signature", valid_402656629
  var valid_402656630 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656630 = validateParameter(valid_402656630, JString,
                                      required = false, default = nil)
  if valid_402656630 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656630
  var valid_402656631 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656631 = validateParameter(valid_402656631, JString,
                                      required = false, default = nil)
  if valid_402656631 != nil:
    section.add "X-Amz-Algorithm", valid_402656631
  var valid_402656632 = header.getOrDefault("X-Amz-Date")
  valid_402656632 = validateParameter(valid_402656632, JString,
                                      required = false, default = nil)
  if valid_402656632 != nil:
    section.add "X-Amz-Date", valid_402656632
  var valid_402656633 = header.getOrDefault("X-Amz-Credential")
  valid_402656633 = validateParameter(valid_402656633, JString,
                                      required = false, default = nil)
  if valid_402656633 != nil:
    section.add "X-Amz-Credential", valid_402656633
  var valid_402656634 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656634 = validateParameter(valid_402656634, JString,
                                      required = false, default = nil)
  if valid_402656634 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656634
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

proc call*(call_402656636: Call_CreatePullRequestApprovalRule_402656624;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates an approval rule for a pull request.
                                                                                         ## 
  let valid = call_402656636.validator(path, query, header, formData, body, _)
  let scheme = call_402656636.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656636.makeUrl(scheme.get, call_402656636.host, call_402656636.base,
                                   call_402656636.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656636, uri, valid, _)

proc call*(call_402656637: Call_CreatePullRequestApprovalRule_402656624;
           body: JsonNode): Recallable =
  ## createPullRequestApprovalRule
  ## Creates an approval rule for a pull request.
  ##   body: JObject (required)
  var body_402656638 = newJObject()
  if body != nil:
    body_402656638 = body
  result = call_402656637.call(nil, nil, nil, nil, body_402656638)

var createPullRequestApprovalRule* = Call_CreatePullRequestApprovalRule_402656624(
    name: "createPullRequestApprovalRule", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.CreatePullRequestApprovalRule",
    validator: validate_CreatePullRequestApprovalRule_402656625, base: "/",
    makeUrl: url_CreatePullRequestApprovalRule_402656626,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateRepository_402656639 = ref object of OpenApiRestCall_402656044
proc url_CreateRepository_402656641(protocol: Scheme; host: string;
                                    base: string; route: string; path: JsonNode;
                                    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateRepository_402656640(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656642 = header.getOrDefault("X-Amz-Target")
  valid_402656642 = validateParameter(valid_402656642, JString, required = true, default = newJString(
      "CodeCommit_20150413.CreateRepository"))
  if valid_402656642 != nil:
    section.add "X-Amz-Target", valid_402656642
  var valid_402656643 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656643 = validateParameter(valid_402656643, JString,
                                      required = false, default = nil)
  if valid_402656643 != nil:
    section.add "X-Amz-Security-Token", valid_402656643
  var valid_402656644 = header.getOrDefault("X-Amz-Signature")
  valid_402656644 = validateParameter(valid_402656644, JString,
                                      required = false, default = nil)
  if valid_402656644 != nil:
    section.add "X-Amz-Signature", valid_402656644
  var valid_402656645 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656645 = validateParameter(valid_402656645, JString,
                                      required = false, default = nil)
  if valid_402656645 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656645
  var valid_402656646 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656646 = validateParameter(valid_402656646, JString,
                                      required = false, default = nil)
  if valid_402656646 != nil:
    section.add "X-Amz-Algorithm", valid_402656646
  var valid_402656647 = header.getOrDefault("X-Amz-Date")
  valid_402656647 = validateParameter(valid_402656647, JString,
                                      required = false, default = nil)
  if valid_402656647 != nil:
    section.add "X-Amz-Date", valid_402656647
  var valid_402656648 = header.getOrDefault("X-Amz-Credential")
  valid_402656648 = validateParameter(valid_402656648, JString,
                                      required = false, default = nil)
  if valid_402656648 != nil:
    section.add "X-Amz-Credential", valid_402656648
  var valid_402656649 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656649 = validateParameter(valid_402656649, JString,
                                      required = false, default = nil)
  if valid_402656649 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656649
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

proc call*(call_402656651: Call_CreateRepository_402656639;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a new, empty repository.
                                                                                         ## 
  let valid = call_402656651.validator(path, query, header, formData, body, _)
  let scheme = call_402656651.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656651.makeUrl(scheme.get, call_402656651.host, call_402656651.base,
                                   call_402656651.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656651, uri, valid, _)

proc call*(call_402656652: Call_CreateRepository_402656639; body: JsonNode): Recallable =
  ## createRepository
  ## Creates a new, empty repository.
  ##   body: JObject (required)
  var body_402656653 = newJObject()
  if body != nil:
    body_402656653 = body
  result = call_402656652.call(nil, nil, nil, nil, body_402656653)

var createRepository* = Call_CreateRepository_402656639(
    name: "createRepository", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.CreateRepository",
    validator: validate_CreateRepository_402656640, base: "/",
    makeUrl: url_CreateRepository_402656641,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateUnreferencedMergeCommit_402656654 = ref object of OpenApiRestCall_402656044
proc url_CreateUnreferencedMergeCommit_402656656(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateUnreferencedMergeCommit_402656655(path: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656657 = header.getOrDefault("X-Amz-Target")
  valid_402656657 = validateParameter(valid_402656657, JString, required = true, default = newJString(
      "CodeCommit_20150413.CreateUnreferencedMergeCommit"))
  if valid_402656657 != nil:
    section.add "X-Amz-Target", valid_402656657
  var valid_402656658 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656658 = validateParameter(valid_402656658, JString,
                                      required = false, default = nil)
  if valid_402656658 != nil:
    section.add "X-Amz-Security-Token", valid_402656658
  var valid_402656659 = header.getOrDefault("X-Amz-Signature")
  valid_402656659 = validateParameter(valid_402656659, JString,
                                      required = false, default = nil)
  if valid_402656659 != nil:
    section.add "X-Amz-Signature", valid_402656659
  var valid_402656660 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656660 = validateParameter(valid_402656660, JString,
                                      required = false, default = nil)
  if valid_402656660 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656660
  var valid_402656661 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656661 = validateParameter(valid_402656661, JString,
                                      required = false, default = nil)
  if valid_402656661 != nil:
    section.add "X-Amz-Algorithm", valid_402656661
  var valid_402656662 = header.getOrDefault("X-Amz-Date")
  valid_402656662 = validateParameter(valid_402656662, JString,
                                      required = false, default = nil)
  if valid_402656662 != nil:
    section.add "X-Amz-Date", valid_402656662
  var valid_402656663 = header.getOrDefault("X-Amz-Credential")
  valid_402656663 = validateParameter(valid_402656663, JString,
                                      required = false, default = nil)
  if valid_402656663 != nil:
    section.add "X-Amz-Credential", valid_402656663
  var valid_402656664 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656664 = validateParameter(valid_402656664, JString,
                                      required = false, default = nil)
  if valid_402656664 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656664
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

proc call*(call_402656666: Call_CreateUnreferencedMergeCommit_402656654;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates an unreferenced commit that represents the result of merging two branches using a specified merge strategy. This can help you determine the outcome of a potential merge. This API cannot be used with the fast-forward merge strategy because that strategy does not create a merge commit.</p> <note> <p>This unreferenced merge commit can only be accessed using the GetCommit API or through git commands such as git fetch. To retrieve this commit, you must specify its commit ID or otherwise reference it.</p> </note>
                                                                                         ## 
  let valid = call_402656666.validator(path, query, header, formData, body, _)
  let scheme = call_402656666.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656666.makeUrl(scheme.get, call_402656666.host, call_402656666.base,
                                   call_402656666.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656666, uri, valid, _)

proc call*(call_402656667: Call_CreateUnreferencedMergeCommit_402656654;
           body: JsonNode): Recallable =
  ## createUnreferencedMergeCommit
  ## <p>Creates an unreferenced commit that represents the result of merging two branches using a specified merge strategy. This can help you determine the outcome of a potential merge. This API cannot be used with the fast-forward merge strategy because that strategy does not create a merge commit.</p> <note> <p>This unreferenced merge commit can only be accessed using the GetCommit API or through git commands such as git fetch. To retrieve this commit, you must specify its commit ID or otherwise reference it.</p> </note>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## body: JObject (required)
  var body_402656668 = newJObject()
  if body != nil:
    body_402656668 = body
  result = call_402656667.call(nil, nil, nil, nil, body_402656668)

var createUnreferencedMergeCommit* = Call_CreateUnreferencedMergeCommit_402656654(
    name: "createUnreferencedMergeCommit", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.CreateUnreferencedMergeCommit",
    validator: validate_CreateUnreferencedMergeCommit_402656655, base: "/",
    makeUrl: url_CreateUnreferencedMergeCommit_402656656,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteApprovalRuleTemplate_402656669 = ref object of OpenApiRestCall_402656044
proc url_DeleteApprovalRuleTemplate_402656671(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteApprovalRuleTemplate_402656670(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Deletes a specified approval rule template. Deleting a template does not remove approval rules on pull requests already created with the template.
                                            ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656672 = header.getOrDefault("X-Amz-Target")
  valid_402656672 = validateParameter(valid_402656672, JString, required = true, default = newJString(
      "CodeCommit_20150413.DeleteApprovalRuleTemplate"))
  if valid_402656672 != nil:
    section.add "X-Amz-Target", valid_402656672
  var valid_402656673 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656673 = validateParameter(valid_402656673, JString,
                                      required = false, default = nil)
  if valid_402656673 != nil:
    section.add "X-Amz-Security-Token", valid_402656673
  var valid_402656674 = header.getOrDefault("X-Amz-Signature")
  valid_402656674 = validateParameter(valid_402656674, JString,
                                      required = false, default = nil)
  if valid_402656674 != nil:
    section.add "X-Amz-Signature", valid_402656674
  var valid_402656675 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656675 = validateParameter(valid_402656675, JString,
                                      required = false, default = nil)
  if valid_402656675 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656675
  var valid_402656676 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656676 = validateParameter(valid_402656676, JString,
                                      required = false, default = nil)
  if valid_402656676 != nil:
    section.add "X-Amz-Algorithm", valid_402656676
  var valid_402656677 = header.getOrDefault("X-Amz-Date")
  valid_402656677 = validateParameter(valid_402656677, JString,
                                      required = false, default = nil)
  if valid_402656677 != nil:
    section.add "X-Amz-Date", valid_402656677
  var valid_402656678 = header.getOrDefault("X-Amz-Credential")
  valid_402656678 = validateParameter(valid_402656678, JString,
                                      required = false, default = nil)
  if valid_402656678 != nil:
    section.add "X-Amz-Credential", valid_402656678
  var valid_402656679 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656679 = validateParameter(valid_402656679, JString,
                                      required = false, default = nil)
  if valid_402656679 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656679
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

proc call*(call_402656681: Call_DeleteApprovalRuleTemplate_402656669;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a specified approval rule template. Deleting a template does not remove approval rules on pull requests already created with the template.
                                                                                         ## 
  let valid = call_402656681.validator(path, query, header, formData, body, _)
  let scheme = call_402656681.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656681.makeUrl(scheme.get, call_402656681.host, call_402656681.base,
                                   call_402656681.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656681, uri, valid, _)

proc call*(call_402656682: Call_DeleteApprovalRuleTemplate_402656669;
           body: JsonNode): Recallable =
  ## deleteApprovalRuleTemplate
  ## Deletes a specified approval rule template. Deleting a template does not remove approval rules on pull requests already created with the template.
  ##   
                                                                                                                                                       ## body: JObject (required)
  var body_402656683 = newJObject()
  if body != nil:
    body_402656683 = body
  result = call_402656682.call(nil, nil, nil, nil, body_402656683)

var deleteApprovalRuleTemplate* = Call_DeleteApprovalRuleTemplate_402656669(
    name: "deleteApprovalRuleTemplate", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.DeleteApprovalRuleTemplate",
    validator: validate_DeleteApprovalRuleTemplate_402656670, base: "/",
    makeUrl: url_DeleteApprovalRuleTemplate_402656671,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBranch_402656684 = ref object of OpenApiRestCall_402656044
proc url_DeleteBranch_402656686(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteBranch_402656685(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes a branch from a repository, unless that branch is the default branch for the repository. 
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656687 = header.getOrDefault("X-Amz-Target")
  valid_402656687 = validateParameter(valid_402656687, JString, required = true, default = newJString(
      "CodeCommit_20150413.DeleteBranch"))
  if valid_402656687 != nil:
    section.add "X-Amz-Target", valid_402656687
  var valid_402656688 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656688 = validateParameter(valid_402656688, JString,
                                      required = false, default = nil)
  if valid_402656688 != nil:
    section.add "X-Amz-Security-Token", valid_402656688
  var valid_402656689 = header.getOrDefault("X-Amz-Signature")
  valid_402656689 = validateParameter(valid_402656689, JString,
                                      required = false, default = nil)
  if valid_402656689 != nil:
    section.add "X-Amz-Signature", valid_402656689
  var valid_402656690 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656690 = validateParameter(valid_402656690, JString,
                                      required = false, default = nil)
  if valid_402656690 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656690
  var valid_402656691 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656691 = validateParameter(valid_402656691, JString,
                                      required = false, default = nil)
  if valid_402656691 != nil:
    section.add "X-Amz-Algorithm", valid_402656691
  var valid_402656692 = header.getOrDefault("X-Amz-Date")
  valid_402656692 = validateParameter(valid_402656692, JString,
                                      required = false, default = nil)
  if valid_402656692 != nil:
    section.add "X-Amz-Date", valid_402656692
  var valid_402656693 = header.getOrDefault("X-Amz-Credential")
  valid_402656693 = validateParameter(valid_402656693, JString,
                                      required = false, default = nil)
  if valid_402656693 != nil:
    section.add "X-Amz-Credential", valid_402656693
  var valid_402656694 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656694 = validateParameter(valid_402656694, JString,
                                      required = false, default = nil)
  if valid_402656694 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656694
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

proc call*(call_402656696: Call_DeleteBranch_402656684; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a branch from a repository, unless that branch is the default branch for the repository. 
                                                                                         ## 
  let valid = call_402656696.validator(path, query, header, formData, body, _)
  let scheme = call_402656696.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656696.makeUrl(scheme.get, call_402656696.host, call_402656696.base,
                                   call_402656696.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656696, uri, valid, _)

proc call*(call_402656697: Call_DeleteBranch_402656684; body: JsonNode): Recallable =
  ## deleteBranch
  ## Deletes a branch from a repository, unless that branch is the default branch for the repository. 
  ##   
                                                                                                      ## body: JObject (required)
  var body_402656698 = newJObject()
  if body != nil:
    body_402656698 = body
  result = call_402656697.call(nil, nil, nil, nil, body_402656698)

var deleteBranch* = Call_DeleteBranch_402656684(name: "deleteBranch",
    meth: HttpMethod.HttpPost, host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.DeleteBranch",
    validator: validate_DeleteBranch_402656685, base: "/",
    makeUrl: url_DeleteBranch_402656686, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteCommentContent_402656699 = ref object of OpenApiRestCall_402656044
proc url_DeleteCommentContent_402656701(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteCommentContent_402656700(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656702 = header.getOrDefault("X-Amz-Target")
  valid_402656702 = validateParameter(valid_402656702, JString, required = true, default = newJString(
      "CodeCommit_20150413.DeleteCommentContent"))
  if valid_402656702 != nil:
    section.add "X-Amz-Target", valid_402656702
  var valid_402656703 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656703 = validateParameter(valid_402656703, JString,
                                      required = false, default = nil)
  if valid_402656703 != nil:
    section.add "X-Amz-Security-Token", valid_402656703
  var valid_402656704 = header.getOrDefault("X-Amz-Signature")
  valid_402656704 = validateParameter(valid_402656704, JString,
                                      required = false, default = nil)
  if valid_402656704 != nil:
    section.add "X-Amz-Signature", valid_402656704
  var valid_402656705 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656705 = validateParameter(valid_402656705, JString,
                                      required = false, default = nil)
  if valid_402656705 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656705
  var valid_402656706 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656706 = validateParameter(valid_402656706, JString,
                                      required = false, default = nil)
  if valid_402656706 != nil:
    section.add "X-Amz-Algorithm", valid_402656706
  var valid_402656707 = header.getOrDefault("X-Amz-Date")
  valid_402656707 = validateParameter(valid_402656707, JString,
                                      required = false, default = nil)
  if valid_402656707 != nil:
    section.add "X-Amz-Date", valid_402656707
  var valid_402656708 = header.getOrDefault("X-Amz-Credential")
  valid_402656708 = validateParameter(valid_402656708, JString,
                                      required = false, default = nil)
  if valid_402656708 != nil:
    section.add "X-Amz-Credential", valid_402656708
  var valid_402656709 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656709 = validateParameter(valid_402656709, JString,
                                      required = false, default = nil)
  if valid_402656709 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656709
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

proc call*(call_402656711: Call_DeleteCommentContent_402656699;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes the content of a comment made on a change, file, or commit in a repository.
                                                                                         ## 
  let valid = call_402656711.validator(path, query, header, formData, body, _)
  let scheme = call_402656711.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656711.makeUrl(scheme.get, call_402656711.host, call_402656711.base,
                                   call_402656711.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656711, uri, valid, _)

proc call*(call_402656712: Call_DeleteCommentContent_402656699; body: JsonNode): Recallable =
  ## deleteCommentContent
  ## Deletes the content of a comment made on a change, file, or commit in a repository.
  ##   
                                                                                        ## body: JObject (required)
  var body_402656713 = newJObject()
  if body != nil:
    body_402656713 = body
  result = call_402656712.call(nil, nil, nil, nil, body_402656713)

var deleteCommentContent* = Call_DeleteCommentContent_402656699(
    name: "deleteCommentContent", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.DeleteCommentContent",
    validator: validate_DeleteCommentContent_402656700, base: "/",
    makeUrl: url_DeleteCommentContent_402656701,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteFile_402656714 = ref object of OpenApiRestCall_402656044
proc url_DeleteFile_402656716(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteFile_402656715(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656717 = header.getOrDefault("X-Amz-Target")
  valid_402656717 = validateParameter(valid_402656717, JString, required = true, default = newJString(
      "CodeCommit_20150413.DeleteFile"))
  if valid_402656717 != nil:
    section.add "X-Amz-Target", valid_402656717
  var valid_402656718 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656718 = validateParameter(valid_402656718, JString,
                                      required = false, default = nil)
  if valid_402656718 != nil:
    section.add "X-Amz-Security-Token", valid_402656718
  var valid_402656719 = header.getOrDefault("X-Amz-Signature")
  valid_402656719 = validateParameter(valid_402656719, JString,
                                      required = false, default = nil)
  if valid_402656719 != nil:
    section.add "X-Amz-Signature", valid_402656719
  var valid_402656720 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656720 = validateParameter(valid_402656720, JString,
                                      required = false, default = nil)
  if valid_402656720 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656720
  var valid_402656721 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656721 = validateParameter(valid_402656721, JString,
                                      required = false, default = nil)
  if valid_402656721 != nil:
    section.add "X-Amz-Algorithm", valid_402656721
  var valid_402656722 = header.getOrDefault("X-Amz-Date")
  valid_402656722 = validateParameter(valid_402656722, JString,
                                      required = false, default = nil)
  if valid_402656722 != nil:
    section.add "X-Amz-Date", valid_402656722
  var valid_402656723 = header.getOrDefault("X-Amz-Credential")
  valid_402656723 = validateParameter(valid_402656723, JString,
                                      required = false, default = nil)
  if valid_402656723 != nil:
    section.add "X-Amz-Credential", valid_402656723
  var valid_402656724 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656724 = validateParameter(valid_402656724, JString,
                                      required = false, default = nil)
  if valid_402656724 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656724
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

proc call*(call_402656726: Call_DeleteFile_402656714; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a specified file from a specified branch. A commit is created on the branch that contains the revision. The file still exists in the commits earlier to the commit that contains the deletion.
                                                                                         ## 
  let valid = call_402656726.validator(path, query, header, formData, body, _)
  let scheme = call_402656726.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656726.makeUrl(scheme.get, call_402656726.host, call_402656726.base,
                                   call_402656726.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656726, uri, valid, _)

proc call*(call_402656727: Call_DeleteFile_402656714; body: JsonNode): Recallable =
  ## deleteFile
  ## Deletes a specified file from a specified branch. A commit is created on the branch that contains the revision. The file still exists in the commits earlier to the commit that contains the deletion.
  ##   
                                                                                                                                                                                                           ## body: JObject (required)
  var body_402656728 = newJObject()
  if body != nil:
    body_402656728 = body
  result = call_402656727.call(nil, nil, nil, nil, body_402656728)

var deleteFile* = Call_DeleteFile_402656714(name: "deleteFile",
    meth: HttpMethod.HttpPost, host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.DeleteFile",
    validator: validate_DeleteFile_402656715, base: "/",
    makeUrl: url_DeleteFile_402656716, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeletePullRequestApprovalRule_402656729 = ref object of OpenApiRestCall_402656044
proc url_DeletePullRequestApprovalRule_402656731(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeletePullRequestApprovalRule_402656730(path: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656732 = header.getOrDefault("X-Amz-Target")
  valid_402656732 = validateParameter(valid_402656732, JString, required = true, default = newJString(
      "CodeCommit_20150413.DeletePullRequestApprovalRule"))
  if valid_402656732 != nil:
    section.add "X-Amz-Target", valid_402656732
  var valid_402656733 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656733 = validateParameter(valid_402656733, JString,
                                      required = false, default = nil)
  if valid_402656733 != nil:
    section.add "X-Amz-Security-Token", valid_402656733
  var valid_402656734 = header.getOrDefault("X-Amz-Signature")
  valid_402656734 = validateParameter(valid_402656734, JString,
                                      required = false, default = nil)
  if valid_402656734 != nil:
    section.add "X-Amz-Signature", valid_402656734
  var valid_402656735 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656735 = validateParameter(valid_402656735, JString,
                                      required = false, default = nil)
  if valid_402656735 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656735
  var valid_402656736 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656736 = validateParameter(valid_402656736, JString,
                                      required = false, default = nil)
  if valid_402656736 != nil:
    section.add "X-Amz-Algorithm", valid_402656736
  var valid_402656737 = header.getOrDefault("X-Amz-Date")
  valid_402656737 = validateParameter(valid_402656737, JString,
                                      required = false, default = nil)
  if valid_402656737 != nil:
    section.add "X-Amz-Date", valid_402656737
  var valid_402656738 = header.getOrDefault("X-Amz-Credential")
  valid_402656738 = validateParameter(valid_402656738, JString,
                                      required = false, default = nil)
  if valid_402656738 != nil:
    section.add "X-Amz-Credential", valid_402656738
  var valid_402656739 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656739 = validateParameter(valid_402656739, JString,
                                      required = false, default = nil)
  if valid_402656739 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656739
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

proc call*(call_402656741: Call_DeletePullRequestApprovalRule_402656729;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes an approval rule from a specified pull request. Approval rules can be deleted from a pull request only if the pull request is open, and if the approval rule was created specifically for a pull request and not generated from an approval rule template associated with the repository where the pull request was created. You cannot delete an approval rule from a merged or closed pull request.
                                                                                         ## 
  let valid = call_402656741.validator(path, query, header, formData, body, _)
  let scheme = call_402656741.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656741.makeUrl(scheme.get, call_402656741.host, call_402656741.base,
                                   call_402656741.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656741, uri, valid, _)

proc call*(call_402656742: Call_DeletePullRequestApprovalRule_402656729;
           body: JsonNode): Recallable =
  ## deletePullRequestApprovalRule
  ## Deletes an approval rule from a specified pull request. Approval rules can be deleted from a pull request only if the pull request is open, and if the approval rule was created specifically for a pull request and not generated from an approval rule template associated with the repository where the pull request was created. You cannot delete an approval rule from a merged or closed pull request.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                  ## body: JObject (required)
  var body_402656743 = newJObject()
  if body != nil:
    body_402656743 = body
  result = call_402656742.call(nil, nil, nil, nil, body_402656743)

var deletePullRequestApprovalRule* = Call_DeletePullRequestApprovalRule_402656729(
    name: "deletePullRequestApprovalRule", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.DeletePullRequestApprovalRule",
    validator: validate_DeletePullRequestApprovalRule_402656730, base: "/",
    makeUrl: url_DeletePullRequestApprovalRule_402656731,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRepository_402656744 = ref object of OpenApiRestCall_402656044
proc url_DeleteRepository_402656746(protocol: Scheme; host: string;
                                    base: string; route: string; path: JsonNode;
                                    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteRepository_402656745(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656747 = header.getOrDefault("X-Amz-Target")
  valid_402656747 = validateParameter(valid_402656747, JString, required = true, default = newJString(
      "CodeCommit_20150413.DeleteRepository"))
  if valid_402656747 != nil:
    section.add "X-Amz-Target", valid_402656747
  var valid_402656748 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656748 = validateParameter(valid_402656748, JString,
                                      required = false, default = nil)
  if valid_402656748 != nil:
    section.add "X-Amz-Security-Token", valid_402656748
  var valid_402656749 = header.getOrDefault("X-Amz-Signature")
  valid_402656749 = validateParameter(valid_402656749, JString,
                                      required = false, default = nil)
  if valid_402656749 != nil:
    section.add "X-Amz-Signature", valid_402656749
  var valid_402656750 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656750 = validateParameter(valid_402656750, JString,
                                      required = false, default = nil)
  if valid_402656750 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656750
  var valid_402656751 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656751 = validateParameter(valid_402656751, JString,
                                      required = false, default = nil)
  if valid_402656751 != nil:
    section.add "X-Amz-Algorithm", valid_402656751
  var valid_402656752 = header.getOrDefault("X-Amz-Date")
  valid_402656752 = validateParameter(valid_402656752, JString,
                                      required = false, default = nil)
  if valid_402656752 != nil:
    section.add "X-Amz-Date", valid_402656752
  var valid_402656753 = header.getOrDefault("X-Amz-Credential")
  valid_402656753 = validateParameter(valid_402656753, JString,
                                      required = false, default = nil)
  if valid_402656753 != nil:
    section.add "X-Amz-Credential", valid_402656753
  var valid_402656754 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656754 = validateParameter(valid_402656754, JString,
                                      required = false, default = nil)
  if valid_402656754 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656754
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

proc call*(call_402656756: Call_DeleteRepository_402656744;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deletes a repository. If a specified repository was already deleted, a null repository ID is returned.</p> <important> <p>Deleting a repository also deletes all associated objects and metadata. After a repository is deleted, all future push calls to the deleted repository fail.</p> </important>
                                                                                         ## 
  let valid = call_402656756.validator(path, query, header, formData, body, _)
  let scheme = call_402656756.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656756.makeUrl(scheme.get, call_402656756.host, call_402656756.base,
                                   call_402656756.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656756, uri, valid, _)

proc call*(call_402656757: Call_DeleteRepository_402656744; body: JsonNode): Recallable =
  ## deleteRepository
  ## <p>Deletes a repository. If a specified repository was already deleted, a null repository ID is returned.</p> <important> <p>Deleting a repository also deletes all associated objects and metadata. After a repository is deleted, all future push calls to the deleted repository fail.</p> </important>
  ##   
                                                                                                                                                                                                                                                                                                               ## body: JObject (required)
  var body_402656758 = newJObject()
  if body != nil:
    body_402656758 = body
  result = call_402656757.call(nil, nil, nil, nil, body_402656758)

var deleteRepository* = Call_DeleteRepository_402656744(
    name: "deleteRepository", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.DeleteRepository",
    validator: validate_DeleteRepository_402656745, base: "/",
    makeUrl: url_DeleteRepository_402656746,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeMergeConflicts_402656759 = ref object of OpenApiRestCall_402656044
proc url_DescribeMergeConflicts_402656761(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeMergeConflicts_402656760(path: JsonNode; query: JsonNode;
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
  var valid_402656762 = query.getOrDefault("maxMergeHunks")
  valid_402656762 = validateParameter(valid_402656762, JString,
                                      required = false, default = nil)
  if valid_402656762 != nil:
    section.add "maxMergeHunks", valid_402656762
  var valid_402656763 = query.getOrDefault("nextToken")
  valid_402656763 = validateParameter(valid_402656763, JString,
                                      required = false, default = nil)
  if valid_402656763 != nil:
    section.add "nextToken", valid_402656763
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656764 = header.getOrDefault("X-Amz-Target")
  valid_402656764 = validateParameter(valid_402656764, JString, required = true, default = newJString(
      "CodeCommit_20150413.DescribeMergeConflicts"))
  if valid_402656764 != nil:
    section.add "X-Amz-Target", valid_402656764
  var valid_402656765 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656765 = validateParameter(valid_402656765, JString,
                                      required = false, default = nil)
  if valid_402656765 != nil:
    section.add "X-Amz-Security-Token", valid_402656765
  var valid_402656766 = header.getOrDefault("X-Amz-Signature")
  valid_402656766 = validateParameter(valid_402656766, JString,
                                      required = false, default = nil)
  if valid_402656766 != nil:
    section.add "X-Amz-Signature", valid_402656766
  var valid_402656767 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656767 = validateParameter(valid_402656767, JString,
                                      required = false, default = nil)
  if valid_402656767 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656767
  var valid_402656768 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656768 = validateParameter(valid_402656768, JString,
                                      required = false, default = nil)
  if valid_402656768 != nil:
    section.add "X-Amz-Algorithm", valid_402656768
  var valid_402656769 = header.getOrDefault("X-Amz-Date")
  valid_402656769 = validateParameter(valid_402656769, JString,
                                      required = false, default = nil)
  if valid_402656769 != nil:
    section.add "X-Amz-Date", valid_402656769
  var valid_402656770 = header.getOrDefault("X-Amz-Credential")
  valid_402656770 = validateParameter(valid_402656770, JString,
                                      required = false, default = nil)
  if valid_402656770 != nil:
    section.add "X-Amz-Credential", valid_402656770
  var valid_402656771 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656771 = validateParameter(valid_402656771, JString,
                                      required = false, default = nil)
  if valid_402656771 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656771
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

proc call*(call_402656773: Call_DescribeMergeConflicts_402656759;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns information about one or more merge conflicts in the attempted merge of two commit specifiers using the squash or three-way merge strategy. If the merge option for the attempted merge is specified as FAST_FORWARD_MERGE, an exception is thrown.
                                                                                         ## 
  let valid = call_402656773.validator(path, query, header, formData, body, _)
  let scheme = call_402656773.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656773.makeUrl(scheme.get, call_402656773.host, call_402656773.base,
                                   call_402656773.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656773, uri, valid, _)

proc call*(call_402656774: Call_DescribeMergeConflicts_402656759;
           body: JsonNode; maxMergeHunks: string = ""; nextToken: string = ""): Recallable =
  ## describeMergeConflicts
  ## Returns information about one or more merge conflicts in the attempted merge of two commit specifiers using the squash or three-way merge strategy. If the merge option for the attempted merge is specified as FAST_FORWARD_MERGE, an exception is thrown.
  ##   
                                                                                                                                                                                                                                                                ## maxMergeHunks: string
                                                                                                                                                                                                                                                                ##                
                                                                                                                                                                                                                                                                ## : 
                                                                                                                                                                                                                                                                ## Pagination 
                                                                                                                                                                                                                                                                ## limit
  ##   
                                                                                                                                                                                                                                                                        ## nextToken: string
                                                                                                                                                                                                                                                                        ##            
                                                                                                                                                                                                                                                                        ## : 
                                                                                                                                                                                                                                                                        ## Pagination 
                                                                                                                                                                                                                                                                        ## token
  ##   
                                                                                                                                                                                                                                                                                ## body: JObject (required)
  var query_402656775 = newJObject()
  var body_402656776 = newJObject()
  add(query_402656775, "maxMergeHunks", newJString(maxMergeHunks))
  add(query_402656775, "nextToken", newJString(nextToken))
  if body != nil:
    body_402656776 = body
  result = call_402656774.call(nil, query_402656775, nil, nil, body_402656776)

var describeMergeConflicts* = Call_DescribeMergeConflicts_402656759(
    name: "describeMergeConflicts", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.DescribeMergeConflicts",
    validator: validate_DescribeMergeConflicts_402656760, base: "/",
    makeUrl: url_DescribeMergeConflicts_402656761,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribePullRequestEvents_402656777 = ref object of OpenApiRestCall_402656044
proc url_DescribePullRequestEvents_402656779(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribePullRequestEvents_402656778(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_402656780 = query.getOrDefault("maxResults")
  valid_402656780 = validateParameter(valid_402656780, JString,
                                      required = false, default = nil)
  if valid_402656780 != nil:
    section.add "maxResults", valid_402656780
  var valid_402656781 = query.getOrDefault("nextToken")
  valid_402656781 = validateParameter(valid_402656781, JString,
                                      required = false, default = nil)
  if valid_402656781 != nil:
    section.add "nextToken", valid_402656781
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656782 = header.getOrDefault("X-Amz-Target")
  valid_402656782 = validateParameter(valid_402656782, JString, required = true, default = newJString(
      "CodeCommit_20150413.DescribePullRequestEvents"))
  if valid_402656782 != nil:
    section.add "X-Amz-Target", valid_402656782
  var valid_402656783 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656783 = validateParameter(valid_402656783, JString,
                                      required = false, default = nil)
  if valid_402656783 != nil:
    section.add "X-Amz-Security-Token", valid_402656783
  var valid_402656784 = header.getOrDefault("X-Amz-Signature")
  valid_402656784 = validateParameter(valid_402656784, JString,
                                      required = false, default = nil)
  if valid_402656784 != nil:
    section.add "X-Amz-Signature", valid_402656784
  var valid_402656785 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656785 = validateParameter(valid_402656785, JString,
                                      required = false, default = nil)
  if valid_402656785 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656785
  var valid_402656786 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656786 = validateParameter(valid_402656786, JString,
                                      required = false, default = nil)
  if valid_402656786 != nil:
    section.add "X-Amz-Algorithm", valid_402656786
  var valid_402656787 = header.getOrDefault("X-Amz-Date")
  valid_402656787 = validateParameter(valid_402656787, JString,
                                      required = false, default = nil)
  if valid_402656787 != nil:
    section.add "X-Amz-Date", valid_402656787
  var valid_402656788 = header.getOrDefault("X-Amz-Credential")
  valid_402656788 = validateParameter(valid_402656788, JString,
                                      required = false, default = nil)
  if valid_402656788 != nil:
    section.add "X-Amz-Credential", valid_402656788
  var valid_402656789 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656789 = validateParameter(valid_402656789, JString,
                                      required = false, default = nil)
  if valid_402656789 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656789
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

proc call*(call_402656791: Call_DescribePullRequestEvents_402656777;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns information about one or more pull request events.
                                                                                         ## 
  let valid = call_402656791.validator(path, query, header, formData, body, _)
  let scheme = call_402656791.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656791.makeUrl(scheme.get, call_402656791.host, call_402656791.base,
                                   call_402656791.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656791, uri, valid, _)

proc call*(call_402656792: Call_DescribePullRequestEvents_402656777;
           body: JsonNode; maxResults: string = ""; nextToken: string = ""): Recallable =
  ## describePullRequestEvents
  ## Returns information about one or more pull request events.
  ##   maxResults: string
                                                               ##             : Pagination limit
  ##   
                                                                                                ## nextToken: string
                                                                                                ##            
                                                                                                ## : 
                                                                                                ## Pagination 
                                                                                                ## token
  ##   
                                                                                                        ## body: JObject (required)
  var query_402656793 = newJObject()
  var body_402656794 = newJObject()
  add(query_402656793, "maxResults", newJString(maxResults))
  add(query_402656793, "nextToken", newJString(nextToken))
  if body != nil:
    body_402656794 = body
  result = call_402656792.call(nil, query_402656793, nil, nil, body_402656794)

var describePullRequestEvents* = Call_DescribePullRequestEvents_402656777(
    name: "describePullRequestEvents", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.DescribePullRequestEvents",
    validator: validate_DescribePullRequestEvents_402656778, base: "/",
    makeUrl: url_DescribePullRequestEvents_402656779,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateApprovalRuleTemplateFromRepository_402656795 = ref object of OpenApiRestCall_402656044
proc url_DisassociateApprovalRuleTemplateFromRepository_402656797(
    protocol: Scheme; host: string; base: string; route: string; path: JsonNode;
    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DisassociateApprovalRuleTemplateFromRepository_402656796(
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656798 = header.getOrDefault("X-Amz-Target")
  valid_402656798 = validateParameter(valid_402656798, JString, required = true, default = newJString(
      "CodeCommit_20150413.DisassociateApprovalRuleTemplateFromRepository"))
  if valid_402656798 != nil:
    section.add "X-Amz-Target", valid_402656798
  var valid_402656799 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656799 = validateParameter(valid_402656799, JString,
                                      required = false, default = nil)
  if valid_402656799 != nil:
    section.add "X-Amz-Security-Token", valid_402656799
  var valid_402656800 = header.getOrDefault("X-Amz-Signature")
  valid_402656800 = validateParameter(valid_402656800, JString,
                                      required = false, default = nil)
  if valid_402656800 != nil:
    section.add "X-Amz-Signature", valid_402656800
  var valid_402656801 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656801 = validateParameter(valid_402656801, JString,
                                      required = false, default = nil)
  if valid_402656801 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656801
  var valid_402656802 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656802 = validateParameter(valid_402656802, JString,
                                      required = false, default = nil)
  if valid_402656802 != nil:
    section.add "X-Amz-Algorithm", valid_402656802
  var valid_402656803 = header.getOrDefault("X-Amz-Date")
  valid_402656803 = validateParameter(valid_402656803, JString,
                                      required = false, default = nil)
  if valid_402656803 != nil:
    section.add "X-Amz-Date", valid_402656803
  var valid_402656804 = header.getOrDefault("X-Amz-Credential")
  valid_402656804 = validateParameter(valid_402656804, JString,
                                      required = false, default = nil)
  if valid_402656804 != nil:
    section.add "X-Amz-Credential", valid_402656804
  var valid_402656805 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656805 = validateParameter(valid_402656805, JString,
                                      required = false, default = nil)
  if valid_402656805 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656805
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

proc call*(call_402656807: Call_DisassociateApprovalRuleTemplateFromRepository_402656795;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Removes the association between a template and a repository so that approval rules based on the template are not automatically created when pull requests are created in the specified repository. This does not delete any approval rules previously created for pull requests through the template association.
                                                                                         ## 
  let valid = call_402656807.validator(path, query, header, formData, body, _)
  let scheme = call_402656807.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656807.makeUrl(scheme.get, call_402656807.host, call_402656807.base,
                                   call_402656807.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656807, uri, valid, _)

proc call*(call_402656808: Call_DisassociateApprovalRuleTemplateFromRepository_402656795;
           body: JsonNode): Recallable =
  ## disassociateApprovalRuleTemplateFromRepository
  ## Removes the association between a template and a repository so that approval rules based on the template are not automatically created when pull requests are created in the specified repository. This does not delete any approval rules previously created for pull requests through the template association.
  ##   
                                                                                                                                                                                                                                                                                                                      ## body: JObject (required)
  var body_402656809 = newJObject()
  if body != nil:
    body_402656809 = body
  result = call_402656808.call(nil, nil, nil, nil, body_402656809)

var disassociateApprovalRuleTemplateFromRepository* = Call_DisassociateApprovalRuleTemplateFromRepository_402656795(
    name: "disassociateApprovalRuleTemplateFromRepository",
    meth: HttpMethod.HttpPost, host: "codecommit.amazonaws.com", route: "/#X-Amz-Target=CodeCommit_20150413.DisassociateApprovalRuleTemplateFromRepository",
    validator: validate_DisassociateApprovalRuleTemplateFromRepository_402656796,
    base: "/", makeUrl: url_DisassociateApprovalRuleTemplateFromRepository_402656797,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_EvaluatePullRequestApprovalRules_402656810 = ref object of OpenApiRestCall_402656044
proc url_EvaluatePullRequestApprovalRules_402656812(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_EvaluatePullRequestApprovalRules_402656811(path: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656813 = header.getOrDefault("X-Amz-Target")
  valid_402656813 = validateParameter(valid_402656813, JString, required = true, default = newJString(
      "CodeCommit_20150413.EvaluatePullRequestApprovalRules"))
  if valid_402656813 != nil:
    section.add "X-Amz-Target", valid_402656813
  var valid_402656814 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656814 = validateParameter(valid_402656814, JString,
                                      required = false, default = nil)
  if valid_402656814 != nil:
    section.add "X-Amz-Security-Token", valid_402656814
  var valid_402656815 = header.getOrDefault("X-Amz-Signature")
  valid_402656815 = validateParameter(valid_402656815, JString,
                                      required = false, default = nil)
  if valid_402656815 != nil:
    section.add "X-Amz-Signature", valid_402656815
  var valid_402656816 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656816 = validateParameter(valid_402656816, JString,
                                      required = false, default = nil)
  if valid_402656816 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656816
  var valid_402656817 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656817 = validateParameter(valid_402656817, JString,
                                      required = false, default = nil)
  if valid_402656817 != nil:
    section.add "X-Amz-Algorithm", valid_402656817
  var valid_402656818 = header.getOrDefault("X-Amz-Date")
  valid_402656818 = validateParameter(valid_402656818, JString,
                                      required = false, default = nil)
  if valid_402656818 != nil:
    section.add "X-Amz-Date", valid_402656818
  var valid_402656819 = header.getOrDefault("X-Amz-Credential")
  valid_402656819 = validateParameter(valid_402656819, JString,
                                      required = false, default = nil)
  if valid_402656819 != nil:
    section.add "X-Amz-Credential", valid_402656819
  var valid_402656820 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656820 = validateParameter(valid_402656820, JString,
                                      required = false, default = nil)
  if valid_402656820 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656820
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

proc call*(call_402656822: Call_EvaluatePullRequestApprovalRules_402656810;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Evaluates whether a pull request has met all the conditions specified in its associated approval rules.
                                                                                         ## 
  let valid = call_402656822.validator(path, query, header, formData, body, _)
  let scheme = call_402656822.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656822.makeUrl(scheme.get, call_402656822.host, call_402656822.base,
                                   call_402656822.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656822, uri, valid, _)

proc call*(call_402656823: Call_EvaluatePullRequestApprovalRules_402656810;
           body: JsonNode): Recallable =
  ## evaluatePullRequestApprovalRules
  ## Evaluates whether a pull request has met all the conditions specified in its associated approval rules.
  ##   
                                                                                                            ## body: JObject (required)
  var body_402656824 = newJObject()
  if body != nil:
    body_402656824 = body
  result = call_402656823.call(nil, nil, nil, nil, body_402656824)

var evaluatePullRequestApprovalRules* = Call_EvaluatePullRequestApprovalRules_402656810(
    name: "evaluatePullRequestApprovalRules", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com", route: "/#X-Amz-Target=CodeCommit_20150413.EvaluatePullRequestApprovalRules",
    validator: validate_EvaluatePullRequestApprovalRules_402656811, base: "/",
    makeUrl: url_EvaluatePullRequestApprovalRules_402656812,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApprovalRuleTemplate_402656825 = ref object of OpenApiRestCall_402656044
proc url_GetApprovalRuleTemplate_402656827(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetApprovalRuleTemplate_402656826(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656828 = header.getOrDefault("X-Amz-Target")
  valid_402656828 = validateParameter(valid_402656828, JString, required = true, default = newJString(
      "CodeCommit_20150413.GetApprovalRuleTemplate"))
  if valid_402656828 != nil:
    section.add "X-Amz-Target", valid_402656828
  var valid_402656829 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656829 = validateParameter(valid_402656829, JString,
                                      required = false, default = nil)
  if valid_402656829 != nil:
    section.add "X-Amz-Security-Token", valid_402656829
  var valid_402656830 = header.getOrDefault("X-Amz-Signature")
  valid_402656830 = validateParameter(valid_402656830, JString,
                                      required = false, default = nil)
  if valid_402656830 != nil:
    section.add "X-Amz-Signature", valid_402656830
  var valid_402656831 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656831 = validateParameter(valid_402656831, JString,
                                      required = false, default = nil)
  if valid_402656831 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656831
  var valid_402656832 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656832 = validateParameter(valid_402656832, JString,
                                      required = false, default = nil)
  if valid_402656832 != nil:
    section.add "X-Amz-Algorithm", valid_402656832
  var valid_402656833 = header.getOrDefault("X-Amz-Date")
  valid_402656833 = validateParameter(valid_402656833, JString,
                                      required = false, default = nil)
  if valid_402656833 != nil:
    section.add "X-Amz-Date", valid_402656833
  var valid_402656834 = header.getOrDefault("X-Amz-Credential")
  valid_402656834 = validateParameter(valid_402656834, JString,
                                      required = false, default = nil)
  if valid_402656834 != nil:
    section.add "X-Amz-Credential", valid_402656834
  var valid_402656835 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656835 = validateParameter(valid_402656835, JString,
                                      required = false, default = nil)
  if valid_402656835 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656835
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

proc call*(call_402656837: Call_GetApprovalRuleTemplate_402656825;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns information about a specified approval rule template.
                                                                                         ## 
  let valid = call_402656837.validator(path, query, header, formData, body, _)
  let scheme = call_402656837.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656837.makeUrl(scheme.get, call_402656837.host, call_402656837.base,
                                   call_402656837.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656837, uri, valid, _)

proc call*(call_402656838: Call_GetApprovalRuleTemplate_402656825;
           body: JsonNode): Recallable =
  ## getApprovalRuleTemplate
  ## Returns information about a specified approval rule template.
  ##   body: JObject (required)
  var body_402656839 = newJObject()
  if body != nil:
    body_402656839 = body
  result = call_402656838.call(nil, nil, nil, nil, body_402656839)

var getApprovalRuleTemplate* = Call_GetApprovalRuleTemplate_402656825(
    name: "getApprovalRuleTemplate", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.GetApprovalRuleTemplate",
    validator: validate_GetApprovalRuleTemplate_402656826, base: "/",
    makeUrl: url_GetApprovalRuleTemplate_402656827,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBlob_402656840 = ref object of OpenApiRestCall_402656044
proc url_GetBlob_402656842(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetBlob_402656841(path: JsonNode; query: JsonNode;
                                header: JsonNode; formData: JsonNode;
                                body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656843 = header.getOrDefault("X-Amz-Target")
  valid_402656843 = validateParameter(valid_402656843, JString, required = true, default = newJString(
      "CodeCommit_20150413.GetBlob"))
  if valid_402656843 != nil:
    section.add "X-Amz-Target", valid_402656843
  var valid_402656844 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656844 = validateParameter(valid_402656844, JString,
                                      required = false, default = nil)
  if valid_402656844 != nil:
    section.add "X-Amz-Security-Token", valid_402656844
  var valid_402656845 = header.getOrDefault("X-Amz-Signature")
  valid_402656845 = validateParameter(valid_402656845, JString,
                                      required = false, default = nil)
  if valid_402656845 != nil:
    section.add "X-Amz-Signature", valid_402656845
  var valid_402656846 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656846 = validateParameter(valid_402656846, JString,
                                      required = false, default = nil)
  if valid_402656846 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656846
  var valid_402656847 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656847 = validateParameter(valid_402656847, JString,
                                      required = false, default = nil)
  if valid_402656847 != nil:
    section.add "X-Amz-Algorithm", valid_402656847
  var valid_402656848 = header.getOrDefault("X-Amz-Date")
  valid_402656848 = validateParameter(valid_402656848, JString,
                                      required = false, default = nil)
  if valid_402656848 != nil:
    section.add "X-Amz-Date", valid_402656848
  var valid_402656849 = header.getOrDefault("X-Amz-Credential")
  valid_402656849 = validateParameter(valid_402656849, JString,
                                      required = false, default = nil)
  if valid_402656849 != nil:
    section.add "X-Amz-Credential", valid_402656849
  var valid_402656850 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656850 = validateParameter(valid_402656850, JString,
                                      required = false, default = nil)
  if valid_402656850 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656850
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

proc call*(call_402656852: Call_GetBlob_402656840; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns the base-64 encoded content of an individual blob in a repository.
                                                                                         ## 
  let valid = call_402656852.validator(path, query, header, formData, body, _)
  let scheme = call_402656852.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656852.makeUrl(scheme.get, call_402656852.host, call_402656852.base,
                                   call_402656852.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656852, uri, valid, _)

proc call*(call_402656853: Call_GetBlob_402656840; body: JsonNode): Recallable =
  ## getBlob
  ## Returns the base-64 encoded content of an individual blob in a repository.
  ##   
                                                                               ## body: JObject (required)
  var body_402656854 = newJObject()
  if body != nil:
    body_402656854 = body
  result = call_402656853.call(nil, nil, nil, nil, body_402656854)

var getBlob* = Call_GetBlob_402656840(name: "getBlob",
                                      meth: HttpMethod.HttpPost,
                                      host: "codecommit.amazonaws.com", route: "/#X-Amz-Target=CodeCommit_20150413.GetBlob",
                                      validator: validate_GetBlob_402656841,
                                      base: "/", makeUrl: url_GetBlob_402656842,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBranch_402656855 = ref object of OpenApiRestCall_402656044
proc url_GetBranch_402656857(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetBranch_402656856(path: JsonNode; query: JsonNode;
                                  header: JsonNode; formData: JsonNode;
                                  body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656858 = header.getOrDefault("X-Amz-Target")
  valid_402656858 = validateParameter(valid_402656858, JString, required = true, default = newJString(
      "CodeCommit_20150413.GetBranch"))
  if valid_402656858 != nil:
    section.add "X-Amz-Target", valid_402656858
  var valid_402656859 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656859 = validateParameter(valid_402656859, JString,
                                      required = false, default = nil)
  if valid_402656859 != nil:
    section.add "X-Amz-Security-Token", valid_402656859
  var valid_402656860 = header.getOrDefault("X-Amz-Signature")
  valid_402656860 = validateParameter(valid_402656860, JString,
                                      required = false, default = nil)
  if valid_402656860 != nil:
    section.add "X-Amz-Signature", valid_402656860
  var valid_402656861 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656861 = validateParameter(valid_402656861, JString,
                                      required = false, default = nil)
  if valid_402656861 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656861
  var valid_402656862 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656862 = validateParameter(valid_402656862, JString,
                                      required = false, default = nil)
  if valid_402656862 != nil:
    section.add "X-Amz-Algorithm", valid_402656862
  var valid_402656863 = header.getOrDefault("X-Amz-Date")
  valid_402656863 = validateParameter(valid_402656863, JString,
                                      required = false, default = nil)
  if valid_402656863 != nil:
    section.add "X-Amz-Date", valid_402656863
  var valid_402656864 = header.getOrDefault("X-Amz-Credential")
  valid_402656864 = validateParameter(valid_402656864, JString,
                                      required = false, default = nil)
  if valid_402656864 != nil:
    section.add "X-Amz-Credential", valid_402656864
  var valid_402656865 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656865 = validateParameter(valid_402656865, JString,
                                      required = false, default = nil)
  if valid_402656865 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656865
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

proc call*(call_402656867: Call_GetBranch_402656855; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns information about a repository branch, including its name and the last commit ID.
                                                                                         ## 
  let valid = call_402656867.validator(path, query, header, formData, body, _)
  let scheme = call_402656867.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656867.makeUrl(scheme.get, call_402656867.host, call_402656867.base,
                                   call_402656867.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656867, uri, valid, _)

proc call*(call_402656868: Call_GetBranch_402656855; body: JsonNode): Recallable =
  ## getBranch
  ## Returns information about a repository branch, including its name and the last commit ID.
  ##   
                                                                                              ## body: JObject (required)
  var body_402656869 = newJObject()
  if body != nil:
    body_402656869 = body
  result = call_402656868.call(nil, nil, nil, nil, body_402656869)

var getBranch* = Call_GetBranch_402656855(name: "getBranch",
    meth: HttpMethod.HttpPost, host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.GetBranch",
    validator: validate_GetBranch_402656856, base: "/", makeUrl: url_GetBranch_402656857,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetComment_402656870 = ref object of OpenApiRestCall_402656044
proc url_GetComment_402656872(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetComment_402656871(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656873 = header.getOrDefault("X-Amz-Target")
  valid_402656873 = validateParameter(valid_402656873, JString, required = true, default = newJString(
      "CodeCommit_20150413.GetComment"))
  if valid_402656873 != nil:
    section.add "X-Amz-Target", valid_402656873
  var valid_402656874 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656874 = validateParameter(valid_402656874, JString,
                                      required = false, default = nil)
  if valid_402656874 != nil:
    section.add "X-Amz-Security-Token", valid_402656874
  var valid_402656875 = header.getOrDefault("X-Amz-Signature")
  valid_402656875 = validateParameter(valid_402656875, JString,
                                      required = false, default = nil)
  if valid_402656875 != nil:
    section.add "X-Amz-Signature", valid_402656875
  var valid_402656876 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656876 = validateParameter(valid_402656876, JString,
                                      required = false, default = nil)
  if valid_402656876 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656876
  var valid_402656877 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656877 = validateParameter(valid_402656877, JString,
                                      required = false, default = nil)
  if valid_402656877 != nil:
    section.add "X-Amz-Algorithm", valid_402656877
  var valid_402656878 = header.getOrDefault("X-Amz-Date")
  valid_402656878 = validateParameter(valid_402656878, JString,
                                      required = false, default = nil)
  if valid_402656878 != nil:
    section.add "X-Amz-Date", valid_402656878
  var valid_402656879 = header.getOrDefault("X-Amz-Credential")
  valid_402656879 = validateParameter(valid_402656879, JString,
                                      required = false, default = nil)
  if valid_402656879 != nil:
    section.add "X-Amz-Credential", valid_402656879
  var valid_402656880 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656880 = validateParameter(valid_402656880, JString,
                                      required = false, default = nil)
  if valid_402656880 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656880
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

proc call*(call_402656882: Call_GetComment_402656870; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns the content of a comment made on a change, file, or commit in a repository.
                                                                                         ## 
  let valid = call_402656882.validator(path, query, header, formData, body, _)
  let scheme = call_402656882.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656882.makeUrl(scheme.get, call_402656882.host, call_402656882.base,
                                   call_402656882.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656882, uri, valid, _)

proc call*(call_402656883: Call_GetComment_402656870; body: JsonNode): Recallable =
  ## getComment
  ## Returns the content of a comment made on a change, file, or commit in a repository.
  ##   
                                                                                        ## body: JObject (required)
  var body_402656884 = newJObject()
  if body != nil:
    body_402656884 = body
  result = call_402656883.call(nil, nil, nil, nil, body_402656884)

var getComment* = Call_GetComment_402656870(name: "getComment",
    meth: HttpMethod.HttpPost, host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.GetComment",
    validator: validate_GetComment_402656871, base: "/",
    makeUrl: url_GetComment_402656872, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCommentsForComparedCommit_402656885 = ref object of OpenApiRestCall_402656044
proc url_GetCommentsForComparedCommit_402656887(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCommentsForComparedCommit_402656886(path: JsonNode;
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
  var valid_402656888 = query.getOrDefault("maxResults")
  valid_402656888 = validateParameter(valid_402656888, JString,
                                      required = false, default = nil)
  if valid_402656888 != nil:
    section.add "maxResults", valid_402656888
  var valid_402656889 = query.getOrDefault("nextToken")
  valid_402656889 = validateParameter(valid_402656889, JString,
                                      required = false, default = nil)
  if valid_402656889 != nil:
    section.add "nextToken", valid_402656889
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656890 = header.getOrDefault("X-Amz-Target")
  valid_402656890 = validateParameter(valid_402656890, JString, required = true, default = newJString(
      "CodeCommit_20150413.GetCommentsForComparedCommit"))
  if valid_402656890 != nil:
    section.add "X-Amz-Target", valid_402656890
  var valid_402656891 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656891 = validateParameter(valid_402656891, JString,
                                      required = false, default = nil)
  if valid_402656891 != nil:
    section.add "X-Amz-Security-Token", valid_402656891
  var valid_402656892 = header.getOrDefault("X-Amz-Signature")
  valid_402656892 = validateParameter(valid_402656892, JString,
                                      required = false, default = nil)
  if valid_402656892 != nil:
    section.add "X-Amz-Signature", valid_402656892
  var valid_402656893 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656893 = validateParameter(valid_402656893, JString,
                                      required = false, default = nil)
  if valid_402656893 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656893
  var valid_402656894 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656894 = validateParameter(valid_402656894, JString,
                                      required = false, default = nil)
  if valid_402656894 != nil:
    section.add "X-Amz-Algorithm", valid_402656894
  var valid_402656895 = header.getOrDefault("X-Amz-Date")
  valid_402656895 = validateParameter(valid_402656895, JString,
                                      required = false, default = nil)
  if valid_402656895 != nil:
    section.add "X-Amz-Date", valid_402656895
  var valid_402656896 = header.getOrDefault("X-Amz-Credential")
  valid_402656896 = validateParameter(valid_402656896, JString,
                                      required = false, default = nil)
  if valid_402656896 != nil:
    section.add "X-Amz-Credential", valid_402656896
  var valid_402656897 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656897 = validateParameter(valid_402656897, JString,
                                      required = false, default = nil)
  if valid_402656897 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656897
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

proc call*(call_402656899: Call_GetCommentsForComparedCommit_402656885;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns information about comments made on the comparison between two commits.
                                                                                         ## 
  let valid = call_402656899.validator(path, query, header, formData, body, _)
  let scheme = call_402656899.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656899.makeUrl(scheme.get, call_402656899.host, call_402656899.base,
                                   call_402656899.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656899, uri, valid, _)

proc call*(call_402656900: Call_GetCommentsForComparedCommit_402656885;
           body: JsonNode; maxResults: string = ""; nextToken: string = ""): Recallable =
  ## getCommentsForComparedCommit
  ## Returns information about comments made on the comparison between two commits.
  ##   
                                                                                   ## maxResults: string
                                                                                   ##             
                                                                                   ## : 
                                                                                   ## Pagination 
                                                                                   ## limit
  ##   
                                                                                           ## nextToken: string
                                                                                           ##            
                                                                                           ## : 
                                                                                           ## Pagination 
                                                                                           ## token
  ##   
                                                                                                   ## body: JObject (required)
  var query_402656901 = newJObject()
  var body_402656902 = newJObject()
  add(query_402656901, "maxResults", newJString(maxResults))
  add(query_402656901, "nextToken", newJString(nextToken))
  if body != nil:
    body_402656902 = body
  result = call_402656900.call(nil, query_402656901, nil, nil, body_402656902)

var getCommentsForComparedCommit* = Call_GetCommentsForComparedCommit_402656885(
    name: "getCommentsForComparedCommit", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.GetCommentsForComparedCommit",
    validator: validate_GetCommentsForComparedCommit_402656886, base: "/",
    makeUrl: url_GetCommentsForComparedCommit_402656887,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCommentsForPullRequest_402656903 = ref object of OpenApiRestCall_402656044
proc url_GetCommentsForPullRequest_402656905(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCommentsForPullRequest_402656904(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_402656906 = query.getOrDefault("maxResults")
  valid_402656906 = validateParameter(valid_402656906, JString,
                                      required = false, default = nil)
  if valid_402656906 != nil:
    section.add "maxResults", valid_402656906
  var valid_402656907 = query.getOrDefault("nextToken")
  valid_402656907 = validateParameter(valid_402656907, JString,
                                      required = false, default = nil)
  if valid_402656907 != nil:
    section.add "nextToken", valid_402656907
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656908 = header.getOrDefault("X-Amz-Target")
  valid_402656908 = validateParameter(valid_402656908, JString, required = true, default = newJString(
      "CodeCommit_20150413.GetCommentsForPullRequest"))
  if valid_402656908 != nil:
    section.add "X-Amz-Target", valid_402656908
  var valid_402656909 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656909 = validateParameter(valid_402656909, JString,
                                      required = false, default = nil)
  if valid_402656909 != nil:
    section.add "X-Amz-Security-Token", valid_402656909
  var valid_402656910 = header.getOrDefault("X-Amz-Signature")
  valid_402656910 = validateParameter(valid_402656910, JString,
                                      required = false, default = nil)
  if valid_402656910 != nil:
    section.add "X-Amz-Signature", valid_402656910
  var valid_402656911 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656911 = validateParameter(valid_402656911, JString,
                                      required = false, default = nil)
  if valid_402656911 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656911
  var valid_402656912 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656912 = validateParameter(valid_402656912, JString,
                                      required = false, default = nil)
  if valid_402656912 != nil:
    section.add "X-Amz-Algorithm", valid_402656912
  var valid_402656913 = header.getOrDefault("X-Amz-Date")
  valid_402656913 = validateParameter(valid_402656913, JString,
                                      required = false, default = nil)
  if valid_402656913 != nil:
    section.add "X-Amz-Date", valid_402656913
  var valid_402656914 = header.getOrDefault("X-Amz-Credential")
  valid_402656914 = validateParameter(valid_402656914, JString,
                                      required = false, default = nil)
  if valid_402656914 != nil:
    section.add "X-Amz-Credential", valid_402656914
  var valid_402656915 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656915 = validateParameter(valid_402656915, JString,
                                      required = false, default = nil)
  if valid_402656915 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656915
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

proc call*(call_402656917: Call_GetCommentsForPullRequest_402656903;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns comments made on a pull request.
                                                                                         ## 
  let valid = call_402656917.validator(path, query, header, formData, body, _)
  let scheme = call_402656917.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656917.makeUrl(scheme.get, call_402656917.host, call_402656917.base,
                                   call_402656917.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656917, uri, valid, _)

proc call*(call_402656918: Call_GetCommentsForPullRequest_402656903;
           body: JsonNode; maxResults: string = ""; nextToken: string = ""): Recallable =
  ## getCommentsForPullRequest
  ## Returns comments made on a pull request.
  ##   maxResults: string
                                             ##             : Pagination limit
  ##   
                                                                              ## nextToken: string
                                                                              ##            
                                                                              ## : 
                                                                              ## Pagination 
                                                                              ## token
  ##   
                                                                                      ## body: JObject (required)
  var query_402656919 = newJObject()
  var body_402656920 = newJObject()
  add(query_402656919, "maxResults", newJString(maxResults))
  add(query_402656919, "nextToken", newJString(nextToken))
  if body != nil:
    body_402656920 = body
  result = call_402656918.call(nil, query_402656919, nil, nil, body_402656920)

var getCommentsForPullRequest* = Call_GetCommentsForPullRequest_402656903(
    name: "getCommentsForPullRequest", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.GetCommentsForPullRequest",
    validator: validate_GetCommentsForPullRequest_402656904, base: "/",
    makeUrl: url_GetCommentsForPullRequest_402656905,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCommit_402656921 = ref object of OpenApiRestCall_402656044
proc url_GetCommit_402656923(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCommit_402656922(path: JsonNode; query: JsonNode;
                                  header: JsonNode; formData: JsonNode;
                                  body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656924 = header.getOrDefault("X-Amz-Target")
  valid_402656924 = validateParameter(valid_402656924, JString, required = true, default = newJString(
      "CodeCommit_20150413.GetCommit"))
  if valid_402656924 != nil:
    section.add "X-Amz-Target", valid_402656924
  var valid_402656925 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656925 = validateParameter(valid_402656925, JString,
                                      required = false, default = nil)
  if valid_402656925 != nil:
    section.add "X-Amz-Security-Token", valid_402656925
  var valid_402656926 = header.getOrDefault("X-Amz-Signature")
  valid_402656926 = validateParameter(valid_402656926, JString,
                                      required = false, default = nil)
  if valid_402656926 != nil:
    section.add "X-Amz-Signature", valid_402656926
  var valid_402656927 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656927 = validateParameter(valid_402656927, JString,
                                      required = false, default = nil)
  if valid_402656927 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656927
  var valid_402656928 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656928 = validateParameter(valid_402656928, JString,
                                      required = false, default = nil)
  if valid_402656928 != nil:
    section.add "X-Amz-Algorithm", valid_402656928
  var valid_402656929 = header.getOrDefault("X-Amz-Date")
  valid_402656929 = validateParameter(valid_402656929, JString,
                                      required = false, default = nil)
  if valid_402656929 != nil:
    section.add "X-Amz-Date", valid_402656929
  var valid_402656930 = header.getOrDefault("X-Amz-Credential")
  valid_402656930 = validateParameter(valid_402656930, JString,
                                      required = false, default = nil)
  if valid_402656930 != nil:
    section.add "X-Amz-Credential", valid_402656930
  var valid_402656931 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656931 = validateParameter(valid_402656931, JString,
                                      required = false, default = nil)
  if valid_402656931 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656931
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

proc call*(call_402656933: Call_GetCommit_402656921; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns information about a commit, including commit message and committer information.
                                                                                         ## 
  let valid = call_402656933.validator(path, query, header, formData, body, _)
  let scheme = call_402656933.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656933.makeUrl(scheme.get, call_402656933.host, call_402656933.base,
                                   call_402656933.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656933, uri, valid, _)

proc call*(call_402656934: Call_GetCommit_402656921; body: JsonNode): Recallable =
  ## getCommit
  ## Returns information about a commit, including commit message and committer information.
  ##   
                                                                                            ## body: JObject (required)
  var body_402656935 = newJObject()
  if body != nil:
    body_402656935 = body
  result = call_402656934.call(nil, nil, nil, nil, body_402656935)

var getCommit* = Call_GetCommit_402656921(name: "getCommit",
    meth: HttpMethod.HttpPost, host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.GetCommit",
    validator: validate_GetCommit_402656922, base: "/", makeUrl: url_GetCommit_402656923,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDifferences_402656936 = ref object of OpenApiRestCall_402656044
proc url_GetDifferences_402656938(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDifferences_402656937(path: JsonNode; query: JsonNode;
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
  ##   MaxResults: JString
                                  ##             : Pagination limit
  ##   NextToken: JString
                                                                   ##            : Pagination token
  section = newJObject()
  var valid_402656939 = query.getOrDefault("MaxResults")
  valid_402656939 = validateParameter(valid_402656939, JString,
                                      required = false, default = nil)
  if valid_402656939 != nil:
    section.add "MaxResults", valid_402656939
  var valid_402656940 = query.getOrDefault("NextToken")
  valid_402656940 = validateParameter(valid_402656940, JString,
                                      required = false, default = nil)
  if valid_402656940 != nil:
    section.add "NextToken", valid_402656940
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656941 = header.getOrDefault("X-Amz-Target")
  valid_402656941 = validateParameter(valid_402656941, JString, required = true, default = newJString(
      "CodeCommit_20150413.GetDifferences"))
  if valid_402656941 != nil:
    section.add "X-Amz-Target", valid_402656941
  var valid_402656942 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656942 = validateParameter(valid_402656942, JString,
                                      required = false, default = nil)
  if valid_402656942 != nil:
    section.add "X-Amz-Security-Token", valid_402656942
  var valid_402656943 = header.getOrDefault("X-Amz-Signature")
  valid_402656943 = validateParameter(valid_402656943, JString,
                                      required = false, default = nil)
  if valid_402656943 != nil:
    section.add "X-Amz-Signature", valid_402656943
  var valid_402656944 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656944 = validateParameter(valid_402656944, JString,
                                      required = false, default = nil)
  if valid_402656944 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656944
  var valid_402656945 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656945 = validateParameter(valid_402656945, JString,
                                      required = false, default = nil)
  if valid_402656945 != nil:
    section.add "X-Amz-Algorithm", valid_402656945
  var valid_402656946 = header.getOrDefault("X-Amz-Date")
  valid_402656946 = validateParameter(valid_402656946, JString,
                                      required = false, default = nil)
  if valid_402656946 != nil:
    section.add "X-Amz-Date", valid_402656946
  var valid_402656947 = header.getOrDefault("X-Amz-Credential")
  valid_402656947 = validateParameter(valid_402656947, JString,
                                      required = false, default = nil)
  if valid_402656947 != nil:
    section.add "X-Amz-Credential", valid_402656947
  var valid_402656948 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656948 = validateParameter(valid_402656948, JString,
                                      required = false, default = nil)
  if valid_402656948 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656948
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

proc call*(call_402656950: Call_GetDifferences_402656936; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns information about the differences in a valid commit specifier (such as a branch, tag, HEAD, commit ID, or other fully qualified reference). Results can be limited to a specified path.
                                                                                         ## 
  let valid = call_402656950.validator(path, query, header, formData, body, _)
  let scheme = call_402656950.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656950.makeUrl(scheme.get, call_402656950.host, call_402656950.base,
                                   call_402656950.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656950, uri, valid, _)

proc call*(call_402656951: Call_GetDifferences_402656936; body: JsonNode;
           MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getDifferences
  ## Returns information about the differences in a valid commit specifier (such as a branch, tag, HEAD, commit ID, or other fully qualified reference). Results can be limited to a specified path.
  ##   
                                                                                                                                                                                                    ## MaxResults: string
                                                                                                                                                                                                    ##             
                                                                                                                                                                                                    ## : 
                                                                                                                                                                                                    ## Pagination 
                                                                                                                                                                                                    ## limit
  ##   
                                                                                                                                                                                                            ## body: JObject (required)
  ##   
                                                                                                                                                                                                                                       ## NextToken: string
                                                                                                                                                                                                                                       ##            
                                                                                                                                                                                                                                       ## : 
                                                                                                                                                                                                                                       ## Pagination 
                                                                                                                                                                                                                                       ## token
  var query_402656952 = newJObject()
  var body_402656953 = newJObject()
  add(query_402656952, "MaxResults", newJString(MaxResults))
  if body != nil:
    body_402656953 = body
  add(query_402656952, "NextToken", newJString(NextToken))
  result = call_402656951.call(nil, query_402656952, nil, nil, body_402656953)

var getDifferences* = Call_GetDifferences_402656936(name: "getDifferences",
    meth: HttpMethod.HttpPost, host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.GetDifferences",
    validator: validate_GetDifferences_402656937, base: "/",
    makeUrl: url_GetDifferences_402656938, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFile_402656954 = ref object of OpenApiRestCall_402656044
proc url_GetFile_402656956(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetFile_402656955(path: JsonNode; query: JsonNode;
                                header: JsonNode; formData: JsonNode;
                                body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656957 = header.getOrDefault("X-Amz-Target")
  valid_402656957 = validateParameter(valid_402656957, JString, required = true, default = newJString(
      "CodeCommit_20150413.GetFile"))
  if valid_402656957 != nil:
    section.add "X-Amz-Target", valid_402656957
  var valid_402656958 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656958 = validateParameter(valid_402656958, JString,
                                      required = false, default = nil)
  if valid_402656958 != nil:
    section.add "X-Amz-Security-Token", valid_402656958
  var valid_402656959 = header.getOrDefault("X-Amz-Signature")
  valid_402656959 = validateParameter(valid_402656959, JString,
                                      required = false, default = nil)
  if valid_402656959 != nil:
    section.add "X-Amz-Signature", valid_402656959
  var valid_402656960 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656960 = validateParameter(valid_402656960, JString,
                                      required = false, default = nil)
  if valid_402656960 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656960
  var valid_402656961 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656961 = validateParameter(valid_402656961, JString,
                                      required = false, default = nil)
  if valid_402656961 != nil:
    section.add "X-Amz-Algorithm", valid_402656961
  var valid_402656962 = header.getOrDefault("X-Amz-Date")
  valid_402656962 = validateParameter(valid_402656962, JString,
                                      required = false, default = nil)
  if valid_402656962 != nil:
    section.add "X-Amz-Date", valid_402656962
  var valid_402656963 = header.getOrDefault("X-Amz-Credential")
  valid_402656963 = validateParameter(valid_402656963, JString,
                                      required = false, default = nil)
  if valid_402656963 != nil:
    section.add "X-Amz-Credential", valid_402656963
  var valid_402656964 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656964 = validateParameter(valid_402656964, JString,
                                      required = false, default = nil)
  if valid_402656964 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656964
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

proc call*(call_402656966: Call_GetFile_402656954; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns the base-64 encoded contents of a specified file and its metadata.
                                                                                         ## 
  let valid = call_402656966.validator(path, query, header, formData, body, _)
  let scheme = call_402656966.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656966.makeUrl(scheme.get, call_402656966.host, call_402656966.base,
                                   call_402656966.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656966, uri, valid, _)

proc call*(call_402656967: Call_GetFile_402656954; body: JsonNode): Recallable =
  ## getFile
  ## Returns the base-64 encoded contents of a specified file and its metadata.
  ##   
                                                                               ## body: JObject (required)
  var body_402656968 = newJObject()
  if body != nil:
    body_402656968 = body
  result = call_402656967.call(nil, nil, nil, nil, body_402656968)

var getFile* = Call_GetFile_402656954(name: "getFile",
                                      meth: HttpMethod.HttpPost,
                                      host: "codecommit.amazonaws.com", route: "/#X-Amz-Target=CodeCommit_20150413.GetFile",
                                      validator: validate_GetFile_402656955,
                                      base: "/", makeUrl: url_GetFile_402656956,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFolder_402656969 = ref object of OpenApiRestCall_402656044
proc url_GetFolder_402656971(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetFolder_402656970(path: JsonNode; query: JsonNode;
                                  header: JsonNode; formData: JsonNode;
                                  body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656972 = header.getOrDefault("X-Amz-Target")
  valid_402656972 = validateParameter(valid_402656972, JString, required = true, default = newJString(
      "CodeCommit_20150413.GetFolder"))
  if valid_402656972 != nil:
    section.add "X-Amz-Target", valid_402656972
  var valid_402656973 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656973 = validateParameter(valid_402656973, JString,
                                      required = false, default = nil)
  if valid_402656973 != nil:
    section.add "X-Amz-Security-Token", valid_402656973
  var valid_402656974 = header.getOrDefault("X-Amz-Signature")
  valid_402656974 = validateParameter(valid_402656974, JString,
                                      required = false, default = nil)
  if valid_402656974 != nil:
    section.add "X-Amz-Signature", valid_402656974
  var valid_402656975 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656975 = validateParameter(valid_402656975, JString,
                                      required = false, default = nil)
  if valid_402656975 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656975
  var valid_402656976 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656976 = validateParameter(valid_402656976, JString,
                                      required = false, default = nil)
  if valid_402656976 != nil:
    section.add "X-Amz-Algorithm", valid_402656976
  var valid_402656977 = header.getOrDefault("X-Amz-Date")
  valid_402656977 = validateParameter(valid_402656977, JString,
                                      required = false, default = nil)
  if valid_402656977 != nil:
    section.add "X-Amz-Date", valid_402656977
  var valid_402656978 = header.getOrDefault("X-Amz-Credential")
  valid_402656978 = validateParameter(valid_402656978, JString,
                                      required = false, default = nil)
  if valid_402656978 != nil:
    section.add "X-Amz-Credential", valid_402656978
  var valid_402656979 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656979 = validateParameter(valid_402656979, JString,
                                      required = false, default = nil)
  if valid_402656979 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656979
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

proc call*(call_402656981: Call_GetFolder_402656969; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns the contents of a specified folder in a repository.
                                                                                         ## 
  let valid = call_402656981.validator(path, query, header, formData, body, _)
  let scheme = call_402656981.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656981.makeUrl(scheme.get, call_402656981.host, call_402656981.base,
                                   call_402656981.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656981, uri, valid, _)

proc call*(call_402656982: Call_GetFolder_402656969; body: JsonNode): Recallable =
  ## getFolder
  ## Returns the contents of a specified folder in a repository.
  ##   body: JObject (required)
  var body_402656983 = newJObject()
  if body != nil:
    body_402656983 = body
  result = call_402656982.call(nil, nil, nil, nil, body_402656983)

var getFolder* = Call_GetFolder_402656969(name: "getFolder",
    meth: HttpMethod.HttpPost, host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.GetFolder",
    validator: validate_GetFolder_402656970, base: "/", makeUrl: url_GetFolder_402656971,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMergeCommit_402656984 = ref object of OpenApiRestCall_402656044
proc url_GetMergeCommit_402656986(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetMergeCommit_402656985(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656987 = header.getOrDefault("X-Amz-Target")
  valid_402656987 = validateParameter(valid_402656987, JString, required = true, default = newJString(
      "CodeCommit_20150413.GetMergeCommit"))
  if valid_402656987 != nil:
    section.add "X-Amz-Target", valid_402656987
  var valid_402656988 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656988 = validateParameter(valid_402656988, JString,
                                      required = false, default = nil)
  if valid_402656988 != nil:
    section.add "X-Amz-Security-Token", valid_402656988
  var valid_402656989 = header.getOrDefault("X-Amz-Signature")
  valid_402656989 = validateParameter(valid_402656989, JString,
                                      required = false, default = nil)
  if valid_402656989 != nil:
    section.add "X-Amz-Signature", valid_402656989
  var valid_402656990 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656990 = validateParameter(valid_402656990, JString,
                                      required = false, default = nil)
  if valid_402656990 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656990
  var valid_402656991 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656991 = validateParameter(valid_402656991, JString,
                                      required = false, default = nil)
  if valid_402656991 != nil:
    section.add "X-Amz-Algorithm", valid_402656991
  var valid_402656992 = header.getOrDefault("X-Amz-Date")
  valid_402656992 = validateParameter(valid_402656992, JString,
                                      required = false, default = nil)
  if valid_402656992 != nil:
    section.add "X-Amz-Date", valid_402656992
  var valid_402656993 = header.getOrDefault("X-Amz-Credential")
  valid_402656993 = validateParameter(valid_402656993, JString,
                                      required = false, default = nil)
  if valid_402656993 != nil:
    section.add "X-Amz-Credential", valid_402656993
  var valid_402656994 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656994 = validateParameter(valid_402656994, JString,
                                      required = false, default = nil)
  if valid_402656994 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656994
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

proc call*(call_402656996: Call_GetMergeCommit_402656984; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns information about a specified merge commit.
                                                                                         ## 
  let valid = call_402656996.validator(path, query, header, formData, body, _)
  let scheme = call_402656996.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656996.makeUrl(scheme.get, call_402656996.host, call_402656996.base,
                                   call_402656996.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656996, uri, valid, _)

proc call*(call_402656997: Call_GetMergeCommit_402656984; body: JsonNode): Recallable =
  ## getMergeCommit
  ## Returns information about a specified merge commit.
  ##   body: JObject (required)
  var body_402656998 = newJObject()
  if body != nil:
    body_402656998 = body
  result = call_402656997.call(nil, nil, nil, nil, body_402656998)

var getMergeCommit* = Call_GetMergeCommit_402656984(name: "getMergeCommit",
    meth: HttpMethod.HttpPost, host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.GetMergeCommit",
    validator: validate_GetMergeCommit_402656985, base: "/",
    makeUrl: url_GetMergeCommit_402656986, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMergeConflicts_402656999 = ref object of OpenApiRestCall_402656044
proc url_GetMergeConflicts_402657001(protocol: Scheme; host: string;
                                     base: string; route: string;
                                     path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetMergeConflicts_402657000(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
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
  ##   
                                                                  ## maxConflictFiles: JString
                                                                  ##                   
                                                                  ## : 
                                                                  ## Pagination limit
  section = newJObject()
  var valid_402657002 = query.getOrDefault("nextToken")
  valid_402657002 = validateParameter(valid_402657002, JString,
                                      required = false, default = nil)
  if valid_402657002 != nil:
    section.add "nextToken", valid_402657002
  var valid_402657003 = query.getOrDefault("maxConflictFiles")
  valid_402657003 = validateParameter(valid_402657003, JString,
                                      required = false, default = nil)
  if valid_402657003 != nil:
    section.add "maxConflictFiles", valid_402657003
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657004 = header.getOrDefault("X-Amz-Target")
  valid_402657004 = validateParameter(valid_402657004, JString, required = true, default = newJString(
      "CodeCommit_20150413.GetMergeConflicts"))
  if valid_402657004 != nil:
    section.add "X-Amz-Target", valid_402657004
  var valid_402657005 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657005 = validateParameter(valid_402657005, JString,
                                      required = false, default = nil)
  if valid_402657005 != nil:
    section.add "X-Amz-Security-Token", valid_402657005
  var valid_402657006 = header.getOrDefault("X-Amz-Signature")
  valid_402657006 = validateParameter(valid_402657006, JString,
                                      required = false, default = nil)
  if valid_402657006 != nil:
    section.add "X-Amz-Signature", valid_402657006
  var valid_402657007 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657007 = validateParameter(valid_402657007, JString,
                                      required = false, default = nil)
  if valid_402657007 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657007
  var valid_402657008 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657008 = validateParameter(valid_402657008, JString,
                                      required = false, default = nil)
  if valid_402657008 != nil:
    section.add "X-Amz-Algorithm", valid_402657008
  var valid_402657009 = header.getOrDefault("X-Amz-Date")
  valid_402657009 = validateParameter(valid_402657009, JString,
                                      required = false, default = nil)
  if valid_402657009 != nil:
    section.add "X-Amz-Date", valid_402657009
  var valid_402657010 = header.getOrDefault("X-Amz-Credential")
  valid_402657010 = validateParameter(valid_402657010, JString,
                                      required = false, default = nil)
  if valid_402657010 != nil:
    section.add "X-Amz-Credential", valid_402657010
  var valid_402657011 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657011 = validateParameter(valid_402657011, JString,
                                      required = false, default = nil)
  if valid_402657011 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657011
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

proc call*(call_402657013: Call_GetMergeConflicts_402656999;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns information about merge conflicts between the before and after commit IDs for a pull request in a repository.
                                                                                         ## 
  let valid = call_402657013.validator(path, query, header, formData, body, _)
  let scheme = call_402657013.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657013.makeUrl(scheme.get, call_402657013.host, call_402657013.base,
                                   call_402657013.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657013, uri, valid, _)

proc call*(call_402657014: Call_GetMergeConflicts_402656999; body: JsonNode;
           nextToken: string = ""; maxConflictFiles: string = ""): Recallable =
  ## getMergeConflicts
  ## Returns information about merge conflicts between the before and after commit IDs for a pull request in a repository.
  ##   
                                                                                                                          ## nextToken: string
                                                                                                                          ##            
                                                                                                                          ## : 
                                                                                                                          ## Pagination 
                                                                                                                          ## token
  ##   
                                                                                                                                  ## body: JObject (required)
  ##   
                                                                                                                                                             ## maxConflictFiles: string
                                                                                                                                                             ##                   
                                                                                                                                                             ## : 
                                                                                                                                                             ## Pagination 
                                                                                                                                                             ## limit
  var query_402657015 = newJObject()
  var body_402657016 = newJObject()
  add(query_402657015, "nextToken", newJString(nextToken))
  if body != nil:
    body_402657016 = body
  add(query_402657015, "maxConflictFiles", newJString(maxConflictFiles))
  result = call_402657014.call(nil, query_402657015, nil, nil, body_402657016)

var getMergeConflicts* = Call_GetMergeConflicts_402656999(
    name: "getMergeConflicts", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.GetMergeConflicts",
    validator: validate_GetMergeConflicts_402657000, base: "/",
    makeUrl: url_GetMergeConflicts_402657001,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMergeOptions_402657017 = ref object of OpenApiRestCall_402656044
proc url_GetMergeOptions_402657019(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode;
                                   query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetMergeOptions_402657018(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657020 = header.getOrDefault("X-Amz-Target")
  valid_402657020 = validateParameter(valid_402657020, JString, required = true, default = newJString(
      "CodeCommit_20150413.GetMergeOptions"))
  if valid_402657020 != nil:
    section.add "X-Amz-Target", valid_402657020
  var valid_402657021 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657021 = validateParameter(valid_402657021, JString,
                                      required = false, default = nil)
  if valid_402657021 != nil:
    section.add "X-Amz-Security-Token", valid_402657021
  var valid_402657022 = header.getOrDefault("X-Amz-Signature")
  valid_402657022 = validateParameter(valid_402657022, JString,
                                      required = false, default = nil)
  if valid_402657022 != nil:
    section.add "X-Amz-Signature", valid_402657022
  var valid_402657023 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657023 = validateParameter(valid_402657023, JString,
                                      required = false, default = nil)
  if valid_402657023 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657023
  var valid_402657024 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657024 = validateParameter(valid_402657024, JString,
                                      required = false, default = nil)
  if valid_402657024 != nil:
    section.add "X-Amz-Algorithm", valid_402657024
  var valid_402657025 = header.getOrDefault("X-Amz-Date")
  valid_402657025 = validateParameter(valid_402657025, JString,
                                      required = false, default = nil)
  if valid_402657025 != nil:
    section.add "X-Amz-Date", valid_402657025
  var valid_402657026 = header.getOrDefault("X-Amz-Credential")
  valid_402657026 = validateParameter(valid_402657026, JString,
                                      required = false, default = nil)
  if valid_402657026 != nil:
    section.add "X-Amz-Credential", valid_402657026
  var valid_402657027 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657027 = validateParameter(valid_402657027, JString,
                                      required = false, default = nil)
  if valid_402657027 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657027
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

proc call*(call_402657029: Call_GetMergeOptions_402657017; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns information about the merge options available for merging two specified branches. For details about why a merge option is not available, use GetMergeConflicts or DescribeMergeConflicts.
                                                                                         ## 
  let valid = call_402657029.validator(path, query, header, formData, body, _)
  let scheme = call_402657029.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657029.makeUrl(scheme.get, call_402657029.host, call_402657029.base,
                                   call_402657029.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657029, uri, valid, _)

proc call*(call_402657030: Call_GetMergeOptions_402657017; body: JsonNode): Recallable =
  ## getMergeOptions
  ## Returns information about the merge options available for merging two specified branches. For details about why a merge option is not available, use GetMergeConflicts or DescribeMergeConflicts.
  ##   
                                                                                                                                                                                                      ## body: JObject (required)
  var body_402657031 = newJObject()
  if body != nil:
    body_402657031 = body
  result = call_402657030.call(nil, nil, nil, nil, body_402657031)

var getMergeOptions* = Call_GetMergeOptions_402657017(name: "getMergeOptions",
    meth: HttpMethod.HttpPost, host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.GetMergeOptions",
    validator: validate_GetMergeOptions_402657018, base: "/",
    makeUrl: url_GetMergeOptions_402657019, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPullRequest_402657032 = ref object of OpenApiRestCall_402656044
proc url_GetPullRequest_402657034(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetPullRequest_402657033(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657035 = header.getOrDefault("X-Amz-Target")
  valid_402657035 = validateParameter(valid_402657035, JString, required = true, default = newJString(
      "CodeCommit_20150413.GetPullRequest"))
  if valid_402657035 != nil:
    section.add "X-Amz-Target", valid_402657035
  var valid_402657036 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657036 = validateParameter(valid_402657036, JString,
                                      required = false, default = nil)
  if valid_402657036 != nil:
    section.add "X-Amz-Security-Token", valid_402657036
  var valid_402657037 = header.getOrDefault("X-Amz-Signature")
  valid_402657037 = validateParameter(valid_402657037, JString,
                                      required = false, default = nil)
  if valid_402657037 != nil:
    section.add "X-Amz-Signature", valid_402657037
  var valid_402657038 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657038 = validateParameter(valid_402657038, JString,
                                      required = false, default = nil)
  if valid_402657038 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657038
  var valid_402657039 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657039 = validateParameter(valid_402657039, JString,
                                      required = false, default = nil)
  if valid_402657039 != nil:
    section.add "X-Amz-Algorithm", valid_402657039
  var valid_402657040 = header.getOrDefault("X-Amz-Date")
  valid_402657040 = validateParameter(valid_402657040, JString,
                                      required = false, default = nil)
  if valid_402657040 != nil:
    section.add "X-Amz-Date", valid_402657040
  var valid_402657041 = header.getOrDefault("X-Amz-Credential")
  valid_402657041 = validateParameter(valid_402657041, JString,
                                      required = false, default = nil)
  if valid_402657041 != nil:
    section.add "X-Amz-Credential", valid_402657041
  var valid_402657042 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657042 = validateParameter(valid_402657042, JString,
                                      required = false, default = nil)
  if valid_402657042 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657042
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

proc call*(call_402657044: Call_GetPullRequest_402657032; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets information about a pull request in a specified repository.
                                                                                         ## 
  let valid = call_402657044.validator(path, query, header, formData, body, _)
  let scheme = call_402657044.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657044.makeUrl(scheme.get, call_402657044.host, call_402657044.base,
                                   call_402657044.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657044, uri, valid, _)

proc call*(call_402657045: Call_GetPullRequest_402657032; body: JsonNode): Recallable =
  ## getPullRequest
  ## Gets information about a pull request in a specified repository.
  ##   body: JObject (required)
  var body_402657046 = newJObject()
  if body != nil:
    body_402657046 = body
  result = call_402657045.call(nil, nil, nil, nil, body_402657046)

var getPullRequest* = Call_GetPullRequest_402657032(name: "getPullRequest",
    meth: HttpMethod.HttpPost, host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.GetPullRequest",
    validator: validate_GetPullRequest_402657033, base: "/",
    makeUrl: url_GetPullRequest_402657034, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPullRequestApprovalStates_402657047 = ref object of OpenApiRestCall_402656044
proc url_GetPullRequestApprovalStates_402657049(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetPullRequestApprovalStates_402657048(path: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657050 = header.getOrDefault("X-Amz-Target")
  valid_402657050 = validateParameter(valid_402657050, JString, required = true, default = newJString(
      "CodeCommit_20150413.GetPullRequestApprovalStates"))
  if valid_402657050 != nil:
    section.add "X-Amz-Target", valid_402657050
  var valid_402657051 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657051 = validateParameter(valid_402657051, JString,
                                      required = false, default = nil)
  if valid_402657051 != nil:
    section.add "X-Amz-Security-Token", valid_402657051
  var valid_402657052 = header.getOrDefault("X-Amz-Signature")
  valid_402657052 = validateParameter(valid_402657052, JString,
                                      required = false, default = nil)
  if valid_402657052 != nil:
    section.add "X-Amz-Signature", valid_402657052
  var valid_402657053 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657053 = validateParameter(valid_402657053, JString,
                                      required = false, default = nil)
  if valid_402657053 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657053
  var valid_402657054 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657054 = validateParameter(valid_402657054, JString,
                                      required = false, default = nil)
  if valid_402657054 != nil:
    section.add "X-Amz-Algorithm", valid_402657054
  var valid_402657055 = header.getOrDefault("X-Amz-Date")
  valid_402657055 = validateParameter(valid_402657055, JString,
                                      required = false, default = nil)
  if valid_402657055 != nil:
    section.add "X-Amz-Date", valid_402657055
  var valid_402657056 = header.getOrDefault("X-Amz-Credential")
  valid_402657056 = validateParameter(valid_402657056, JString,
                                      required = false, default = nil)
  if valid_402657056 != nil:
    section.add "X-Amz-Credential", valid_402657056
  var valid_402657057 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657057 = validateParameter(valid_402657057, JString,
                                      required = false, default = nil)
  if valid_402657057 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657057
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

proc call*(call_402657059: Call_GetPullRequestApprovalStates_402657047;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets information about the approval states for a specified pull request. Approval states only apply to pull requests that have one or more approval rules applied to them.
                                                                                         ## 
  let valid = call_402657059.validator(path, query, header, formData, body, _)
  let scheme = call_402657059.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657059.makeUrl(scheme.get, call_402657059.host, call_402657059.base,
                                   call_402657059.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657059, uri, valid, _)

proc call*(call_402657060: Call_GetPullRequestApprovalStates_402657047;
           body: JsonNode): Recallable =
  ## getPullRequestApprovalStates
  ## Gets information about the approval states for a specified pull request. Approval states only apply to pull requests that have one or more approval rules applied to them.
  ##   
                                                                                                                                                                               ## body: JObject (required)
  var body_402657061 = newJObject()
  if body != nil:
    body_402657061 = body
  result = call_402657060.call(nil, nil, nil, nil, body_402657061)

var getPullRequestApprovalStates* = Call_GetPullRequestApprovalStates_402657047(
    name: "getPullRequestApprovalStates", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.GetPullRequestApprovalStates",
    validator: validate_GetPullRequestApprovalStates_402657048, base: "/",
    makeUrl: url_GetPullRequestApprovalStates_402657049,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPullRequestOverrideState_402657062 = ref object of OpenApiRestCall_402656044
proc url_GetPullRequestOverrideState_402657064(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetPullRequestOverrideState_402657063(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Returns information about whether approval rules have been set aside (overridden) for a pull request, and if so, the Amazon Resource Name (ARN) of the user or identity that overrode the rules and their requirements for the pull request.
                                            ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657065 = header.getOrDefault("X-Amz-Target")
  valid_402657065 = validateParameter(valid_402657065, JString, required = true, default = newJString(
      "CodeCommit_20150413.GetPullRequestOverrideState"))
  if valid_402657065 != nil:
    section.add "X-Amz-Target", valid_402657065
  var valid_402657066 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657066 = validateParameter(valid_402657066, JString,
                                      required = false, default = nil)
  if valid_402657066 != nil:
    section.add "X-Amz-Security-Token", valid_402657066
  var valid_402657067 = header.getOrDefault("X-Amz-Signature")
  valid_402657067 = validateParameter(valid_402657067, JString,
                                      required = false, default = nil)
  if valid_402657067 != nil:
    section.add "X-Amz-Signature", valid_402657067
  var valid_402657068 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657068 = validateParameter(valid_402657068, JString,
                                      required = false, default = nil)
  if valid_402657068 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657068
  var valid_402657069 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657069 = validateParameter(valid_402657069, JString,
                                      required = false, default = nil)
  if valid_402657069 != nil:
    section.add "X-Amz-Algorithm", valid_402657069
  var valid_402657070 = header.getOrDefault("X-Amz-Date")
  valid_402657070 = validateParameter(valid_402657070, JString,
                                      required = false, default = nil)
  if valid_402657070 != nil:
    section.add "X-Amz-Date", valid_402657070
  var valid_402657071 = header.getOrDefault("X-Amz-Credential")
  valid_402657071 = validateParameter(valid_402657071, JString,
                                      required = false, default = nil)
  if valid_402657071 != nil:
    section.add "X-Amz-Credential", valid_402657071
  var valid_402657072 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657072 = validateParameter(valid_402657072, JString,
                                      required = false, default = nil)
  if valid_402657072 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657072
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

proc call*(call_402657074: Call_GetPullRequestOverrideState_402657062;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns information about whether approval rules have been set aside (overridden) for a pull request, and if so, the Amazon Resource Name (ARN) of the user or identity that overrode the rules and their requirements for the pull request.
                                                                                         ## 
  let valid = call_402657074.validator(path, query, header, formData, body, _)
  let scheme = call_402657074.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657074.makeUrl(scheme.get, call_402657074.host, call_402657074.base,
                                   call_402657074.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657074, uri, valid, _)

proc call*(call_402657075: Call_GetPullRequestOverrideState_402657062;
           body: JsonNode): Recallable =
  ## getPullRequestOverrideState
  ## Returns information about whether approval rules have been set aside (overridden) for a pull request, and if so, the Amazon Resource Name (ARN) of the user or identity that overrode the rules and their requirements for the pull request.
  ##   
                                                                                                                                                                                                                                                 ## body: JObject (required)
  var body_402657076 = newJObject()
  if body != nil:
    body_402657076 = body
  result = call_402657075.call(nil, nil, nil, nil, body_402657076)

var getPullRequestOverrideState* = Call_GetPullRequestOverrideState_402657062(
    name: "getPullRequestOverrideState", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.GetPullRequestOverrideState",
    validator: validate_GetPullRequestOverrideState_402657063, base: "/",
    makeUrl: url_GetPullRequestOverrideState_402657064,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRepository_402657077 = ref object of OpenApiRestCall_402656044
proc url_GetRepository_402657079(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRepository_402657078(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Returns information about a repository.</p> <note> <p>The description field for a repository accepts all HTML characters and all valid Unicode characters. Applications that do not HTML-encode the description and display it in a webpage can expose users to potentially malicious code. Make sure that you HTML-encode the description field in any application that uses this API to display the repository description on a webpage.</p> </note>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657080 = header.getOrDefault("X-Amz-Target")
  valid_402657080 = validateParameter(valid_402657080, JString, required = true, default = newJString(
      "CodeCommit_20150413.GetRepository"))
  if valid_402657080 != nil:
    section.add "X-Amz-Target", valid_402657080
  var valid_402657081 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657081 = validateParameter(valid_402657081, JString,
                                      required = false, default = nil)
  if valid_402657081 != nil:
    section.add "X-Amz-Security-Token", valid_402657081
  var valid_402657082 = header.getOrDefault("X-Amz-Signature")
  valid_402657082 = validateParameter(valid_402657082, JString,
                                      required = false, default = nil)
  if valid_402657082 != nil:
    section.add "X-Amz-Signature", valid_402657082
  var valid_402657083 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657083 = validateParameter(valid_402657083, JString,
                                      required = false, default = nil)
  if valid_402657083 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657083
  var valid_402657084 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657084 = validateParameter(valid_402657084, JString,
                                      required = false, default = nil)
  if valid_402657084 != nil:
    section.add "X-Amz-Algorithm", valid_402657084
  var valid_402657085 = header.getOrDefault("X-Amz-Date")
  valid_402657085 = validateParameter(valid_402657085, JString,
                                      required = false, default = nil)
  if valid_402657085 != nil:
    section.add "X-Amz-Date", valid_402657085
  var valid_402657086 = header.getOrDefault("X-Amz-Credential")
  valid_402657086 = validateParameter(valid_402657086, JString,
                                      required = false, default = nil)
  if valid_402657086 != nil:
    section.add "X-Amz-Credential", valid_402657086
  var valid_402657087 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657087 = validateParameter(valid_402657087, JString,
                                      required = false, default = nil)
  if valid_402657087 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657087
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

proc call*(call_402657089: Call_GetRepository_402657077; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns information about a repository.</p> <note> <p>The description field for a repository accepts all HTML characters and all valid Unicode characters. Applications that do not HTML-encode the description and display it in a webpage can expose users to potentially malicious code. Make sure that you HTML-encode the description field in any application that uses this API to display the repository description on a webpage.</p> </note>
                                                                                         ## 
  let valid = call_402657089.validator(path, query, header, formData, body, _)
  let scheme = call_402657089.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657089.makeUrl(scheme.get, call_402657089.host, call_402657089.base,
                                   call_402657089.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657089, uri, valid, _)

proc call*(call_402657090: Call_GetRepository_402657077; body: JsonNode): Recallable =
  ## getRepository
  ## <p>Returns information about a repository.</p> <note> <p>The description field for a repository accepts all HTML characters and all valid Unicode characters. Applications that do not HTML-encode the description and display it in a webpage can expose users to potentially malicious code. Make sure that you HTML-encode the description field in any application that uses this API to display the repository description on a webpage.</p> </note>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## body: JObject (required)
  var body_402657091 = newJObject()
  if body != nil:
    body_402657091 = body
  result = call_402657090.call(nil, nil, nil, nil, body_402657091)

var getRepository* = Call_GetRepository_402657077(name: "getRepository",
    meth: HttpMethod.HttpPost, host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.GetRepository",
    validator: validate_GetRepository_402657078, base: "/",
    makeUrl: url_GetRepository_402657079, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRepositoryTriggers_402657092 = ref object of OpenApiRestCall_402656044
proc url_GetRepositoryTriggers_402657094(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRepositoryTriggers_402657093(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657095 = header.getOrDefault("X-Amz-Target")
  valid_402657095 = validateParameter(valid_402657095, JString, required = true, default = newJString(
      "CodeCommit_20150413.GetRepositoryTriggers"))
  if valid_402657095 != nil:
    section.add "X-Amz-Target", valid_402657095
  var valid_402657096 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657096 = validateParameter(valid_402657096, JString,
                                      required = false, default = nil)
  if valid_402657096 != nil:
    section.add "X-Amz-Security-Token", valid_402657096
  var valid_402657097 = header.getOrDefault("X-Amz-Signature")
  valid_402657097 = validateParameter(valid_402657097, JString,
                                      required = false, default = nil)
  if valid_402657097 != nil:
    section.add "X-Amz-Signature", valid_402657097
  var valid_402657098 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657098 = validateParameter(valid_402657098, JString,
                                      required = false, default = nil)
  if valid_402657098 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657098
  var valid_402657099 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657099 = validateParameter(valid_402657099, JString,
                                      required = false, default = nil)
  if valid_402657099 != nil:
    section.add "X-Amz-Algorithm", valid_402657099
  var valid_402657100 = header.getOrDefault("X-Amz-Date")
  valid_402657100 = validateParameter(valid_402657100, JString,
                                      required = false, default = nil)
  if valid_402657100 != nil:
    section.add "X-Amz-Date", valid_402657100
  var valid_402657101 = header.getOrDefault("X-Amz-Credential")
  valid_402657101 = validateParameter(valid_402657101, JString,
                                      required = false, default = nil)
  if valid_402657101 != nil:
    section.add "X-Amz-Credential", valid_402657101
  var valid_402657102 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657102 = validateParameter(valid_402657102, JString,
                                      required = false, default = nil)
  if valid_402657102 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657102
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

proc call*(call_402657104: Call_GetRepositoryTriggers_402657092;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets information about triggers configured for a repository.
                                                                                         ## 
  let valid = call_402657104.validator(path, query, header, formData, body, _)
  let scheme = call_402657104.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657104.makeUrl(scheme.get, call_402657104.host, call_402657104.base,
                                   call_402657104.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657104, uri, valid, _)

proc call*(call_402657105: Call_GetRepositoryTriggers_402657092; body: JsonNode): Recallable =
  ## getRepositoryTriggers
  ## Gets information about triggers configured for a repository.
  ##   body: JObject (required)
  var body_402657106 = newJObject()
  if body != nil:
    body_402657106 = body
  result = call_402657105.call(nil, nil, nil, nil, body_402657106)

var getRepositoryTriggers* = Call_GetRepositoryTriggers_402657092(
    name: "getRepositoryTriggers", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.GetRepositoryTriggers",
    validator: validate_GetRepositoryTriggers_402657093, base: "/",
    makeUrl: url_GetRepositoryTriggers_402657094,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListApprovalRuleTemplates_402657107 = ref object of OpenApiRestCall_402656044
proc url_ListApprovalRuleTemplates_402657109(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListApprovalRuleTemplates_402657108(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_402657110 = query.getOrDefault("maxResults")
  valid_402657110 = validateParameter(valid_402657110, JString,
                                      required = false, default = nil)
  if valid_402657110 != nil:
    section.add "maxResults", valid_402657110
  var valid_402657111 = query.getOrDefault("nextToken")
  valid_402657111 = validateParameter(valid_402657111, JString,
                                      required = false, default = nil)
  if valid_402657111 != nil:
    section.add "nextToken", valid_402657111
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657112 = header.getOrDefault("X-Amz-Target")
  valid_402657112 = validateParameter(valid_402657112, JString, required = true, default = newJString(
      "CodeCommit_20150413.ListApprovalRuleTemplates"))
  if valid_402657112 != nil:
    section.add "X-Amz-Target", valid_402657112
  var valid_402657113 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657113 = validateParameter(valid_402657113, JString,
                                      required = false, default = nil)
  if valid_402657113 != nil:
    section.add "X-Amz-Security-Token", valid_402657113
  var valid_402657114 = header.getOrDefault("X-Amz-Signature")
  valid_402657114 = validateParameter(valid_402657114, JString,
                                      required = false, default = nil)
  if valid_402657114 != nil:
    section.add "X-Amz-Signature", valid_402657114
  var valid_402657115 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657115 = validateParameter(valid_402657115, JString,
                                      required = false, default = nil)
  if valid_402657115 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657115
  var valid_402657116 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657116 = validateParameter(valid_402657116, JString,
                                      required = false, default = nil)
  if valid_402657116 != nil:
    section.add "X-Amz-Algorithm", valid_402657116
  var valid_402657117 = header.getOrDefault("X-Amz-Date")
  valid_402657117 = validateParameter(valid_402657117, JString,
                                      required = false, default = nil)
  if valid_402657117 != nil:
    section.add "X-Amz-Date", valid_402657117
  var valid_402657118 = header.getOrDefault("X-Amz-Credential")
  valid_402657118 = validateParameter(valid_402657118, JString,
                                      required = false, default = nil)
  if valid_402657118 != nil:
    section.add "X-Amz-Credential", valid_402657118
  var valid_402657119 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657119 = validateParameter(valid_402657119, JString,
                                      required = false, default = nil)
  if valid_402657119 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657119
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

proc call*(call_402657121: Call_ListApprovalRuleTemplates_402657107;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists all approval rule templates in the specified AWS Region in your AWS account. If an AWS Region is not specified, the AWS Region where you are signed in is used.
                                                                                         ## 
  let valid = call_402657121.validator(path, query, header, formData, body, _)
  let scheme = call_402657121.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657121.makeUrl(scheme.get, call_402657121.host, call_402657121.base,
                                   call_402657121.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657121, uri, valid, _)

proc call*(call_402657122: Call_ListApprovalRuleTemplates_402657107;
           body: JsonNode; maxResults: string = ""; nextToken: string = ""): Recallable =
  ## listApprovalRuleTemplates
  ## Lists all approval rule templates in the specified AWS Region in your AWS account. If an AWS Region is not specified, the AWS Region where you are signed in is used.
  ##   
                                                                                                                                                                          ## maxResults: string
                                                                                                                                                                          ##             
                                                                                                                                                                          ## : 
                                                                                                                                                                          ## Pagination 
                                                                                                                                                                          ## limit
  ##   
                                                                                                                                                                                  ## nextToken: string
                                                                                                                                                                                  ##            
                                                                                                                                                                                  ## : 
                                                                                                                                                                                  ## Pagination 
                                                                                                                                                                                  ## token
  ##   
                                                                                                                                                                                          ## body: JObject (required)
  var query_402657123 = newJObject()
  var body_402657124 = newJObject()
  add(query_402657123, "maxResults", newJString(maxResults))
  add(query_402657123, "nextToken", newJString(nextToken))
  if body != nil:
    body_402657124 = body
  result = call_402657122.call(nil, query_402657123, nil, nil, body_402657124)

var listApprovalRuleTemplates* = Call_ListApprovalRuleTemplates_402657107(
    name: "listApprovalRuleTemplates", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.ListApprovalRuleTemplates",
    validator: validate_ListApprovalRuleTemplates_402657108, base: "/",
    makeUrl: url_ListApprovalRuleTemplates_402657109,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAssociatedApprovalRuleTemplatesForRepository_402657125 = ref object of OpenApiRestCall_402656044
proc url_ListAssociatedApprovalRuleTemplatesForRepository_402657127(
    protocol: Scheme; host: string; base: string; route: string; path: JsonNode;
    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListAssociatedApprovalRuleTemplatesForRepository_402657126(
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
  var valid_402657128 = query.getOrDefault("maxResults")
  valid_402657128 = validateParameter(valid_402657128, JString,
                                      required = false, default = nil)
  if valid_402657128 != nil:
    section.add "maxResults", valid_402657128
  var valid_402657129 = query.getOrDefault("nextToken")
  valid_402657129 = validateParameter(valid_402657129, JString,
                                      required = false, default = nil)
  if valid_402657129 != nil:
    section.add "nextToken", valid_402657129
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657130 = header.getOrDefault("X-Amz-Target")
  valid_402657130 = validateParameter(valid_402657130, JString, required = true, default = newJString(
      "CodeCommit_20150413.ListAssociatedApprovalRuleTemplatesForRepository"))
  if valid_402657130 != nil:
    section.add "X-Amz-Target", valid_402657130
  var valid_402657131 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657131 = validateParameter(valid_402657131, JString,
                                      required = false, default = nil)
  if valid_402657131 != nil:
    section.add "X-Amz-Security-Token", valid_402657131
  var valid_402657132 = header.getOrDefault("X-Amz-Signature")
  valid_402657132 = validateParameter(valid_402657132, JString,
                                      required = false, default = nil)
  if valid_402657132 != nil:
    section.add "X-Amz-Signature", valid_402657132
  var valid_402657133 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657133 = validateParameter(valid_402657133, JString,
                                      required = false, default = nil)
  if valid_402657133 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657133
  var valid_402657134 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657134 = validateParameter(valid_402657134, JString,
                                      required = false, default = nil)
  if valid_402657134 != nil:
    section.add "X-Amz-Algorithm", valid_402657134
  var valid_402657135 = header.getOrDefault("X-Amz-Date")
  valid_402657135 = validateParameter(valid_402657135, JString,
                                      required = false, default = nil)
  if valid_402657135 != nil:
    section.add "X-Amz-Date", valid_402657135
  var valid_402657136 = header.getOrDefault("X-Amz-Credential")
  valid_402657136 = validateParameter(valid_402657136, JString,
                                      required = false, default = nil)
  if valid_402657136 != nil:
    section.add "X-Amz-Credential", valid_402657136
  var valid_402657137 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657137 = validateParameter(valid_402657137, JString,
                                      required = false, default = nil)
  if valid_402657137 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657137
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

proc call*(call_402657139: Call_ListAssociatedApprovalRuleTemplatesForRepository_402657125;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists all approval rule templates that are associated with a specified repository.
                                                                                         ## 
  let valid = call_402657139.validator(path, query, header, formData, body, _)
  let scheme = call_402657139.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657139.makeUrl(scheme.get, call_402657139.host, call_402657139.base,
                                   call_402657139.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657139, uri, valid, _)

proc call*(call_402657140: Call_ListAssociatedApprovalRuleTemplatesForRepository_402657125;
           body: JsonNode; maxResults: string = ""; nextToken: string = ""): Recallable =
  ## listAssociatedApprovalRuleTemplatesForRepository
  ## Lists all approval rule templates that are associated with a specified repository.
  ##   
                                                                                       ## maxResults: string
                                                                                       ##             
                                                                                       ## : 
                                                                                       ## Pagination 
                                                                                       ## limit
  ##   
                                                                                               ## nextToken: string
                                                                                               ##            
                                                                                               ## : 
                                                                                               ## Pagination 
                                                                                               ## token
  ##   
                                                                                                       ## body: JObject (required)
  var query_402657141 = newJObject()
  var body_402657142 = newJObject()
  add(query_402657141, "maxResults", newJString(maxResults))
  add(query_402657141, "nextToken", newJString(nextToken))
  if body != nil:
    body_402657142 = body
  result = call_402657140.call(nil, query_402657141, nil, nil, body_402657142)

var listAssociatedApprovalRuleTemplatesForRepository* = Call_ListAssociatedApprovalRuleTemplatesForRepository_402657125(
    name: "listAssociatedApprovalRuleTemplatesForRepository",
    meth: HttpMethod.HttpPost, host: "codecommit.amazonaws.com", route: "/#X-Amz-Target=CodeCommit_20150413.ListAssociatedApprovalRuleTemplatesForRepository",
    validator: validate_ListAssociatedApprovalRuleTemplatesForRepository_402657126,
    base: "/", makeUrl: url_ListAssociatedApprovalRuleTemplatesForRepository_402657127,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBranches_402657143 = ref object of OpenApiRestCall_402656044
proc url_ListBranches_402657145(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListBranches_402657144(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_402657146 = query.getOrDefault("nextToken")
  valid_402657146 = validateParameter(valid_402657146, JString,
                                      required = false, default = nil)
  if valid_402657146 != nil:
    section.add "nextToken", valid_402657146
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657147 = header.getOrDefault("X-Amz-Target")
  valid_402657147 = validateParameter(valid_402657147, JString, required = true, default = newJString(
      "CodeCommit_20150413.ListBranches"))
  if valid_402657147 != nil:
    section.add "X-Amz-Target", valid_402657147
  var valid_402657148 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657148 = validateParameter(valid_402657148, JString,
                                      required = false, default = nil)
  if valid_402657148 != nil:
    section.add "X-Amz-Security-Token", valid_402657148
  var valid_402657149 = header.getOrDefault("X-Amz-Signature")
  valid_402657149 = validateParameter(valid_402657149, JString,
                                      required = false, default = nil)
  if valid_402657149 != nil:
    section.add "X-Amz-Signature", valid_402657149
  var valid_402657150 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657150 = validateParameter(valid_402657150, JString,
                                      required = false, default = nil)
  if valid_402657150 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657150
  var valid_402657151 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657151 = validateParameter(valid_402657151, JString,
                                      required = false, default = nil)
  if valid_402657151 != nil:
    section.add "X-Amz-Algorithm", valid_402657151
  var valid_402657152 = header.getOrDefault("X-Amz-Date")
  valid_402657152 = validateParameter(valid_402657152, JString,
                                      required = false, default = nil)
  if valid_402657152 != nil:
    section.add "X-Amz-Date", valid_402657152
  var valid_402657153 = header.getOrDefault("X-Amz-Credential")
  valid_402657153 = validateParameter(valid_402657153, JString,
                                      required = false, default = nil)
  if valid_402657153 != nil:
    section.add "X-Amz-Credential", valid_402657153
  var valid_402657154 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657154 = validateParameter(valid_402657154, JString,
                                      required = false, default = nil)
  if valid_402657154 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657154
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

proc call*(call_402657156: Call_ListBranches_402657143; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets information about one or more branches in a repository.
                                                                                         ## 
  let valid = call_402657156.validator(path, query, header, formData, body, _)
  let scheme = call_402657156.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657156.makeUrl(scheme.get, call_402657156.host, call_402657156.base,
                                   call_402657156.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657156, uri, valid, _)

proc call*(call_402657157: Call_ListBranches_402657143; body: JsonNode;
           nextToken: string = ""): Recallable =
  ## listBranches
  ## Gets information about one or more branches in a repository.
  ##   nextToken: string
                                                                 ##            : Pagination token
  ##   
                                                                                                 ## body: JObject (required)
  var query_402657158 = newJObject()
  var body_402657159 = newJObject()
  add(query_402657158, "nextToken", newJString(nextToken))
  if body != nil:
    body_402657159 = body
  result = call_402657157.call(nil, query_402657158, nil, nil, body_402657159)

var listBranches* = Call_ListBranches_402657143(name: "listBranches",
    meth: HttpMethod.HttpPost, host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.ListBranches",
    validator: validate_ListBranches_402657144, base: "/",
    makeUrl: url_ListBranches_402657145, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPullRequests_402657160 = ref object of OpenApiRestCall_402656044
proc url_ListPullRequests_402657162(protocol: Scheme; host: string;
                                    base: string; route: string; path: JsonNode;
                                    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListPullRequests_402657161(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
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
  var valid_402657163 = query.getOrDefault("maxResults")
  valid_402657163 = validateParameter(valid_402657163, JString,
                                      required = false, default = nil)
  if valid_402657163 != nil:
    section.add "maxResults", valid_402657163
  var valid_402657164 = query.getOrDefault("nextToken")
  valid_402657164 = validateParameter(valid_402657164, JString,
                                      required = false, default = nil)
  if valid_402657164 != nil:
    section.add "nextToken", valid_402657164
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657165 = header.getOrDefault("X-Amz-Target")
  valid_402657165 = validateParameter(valid_402657165, JString, required = true, default = newJString(
      "CodeCommit_20150413.ListPullRequests"))
  if valid_402657165 != nil:
    section.add "X-Amz-Target", valid_402657165
  var valid_402657166 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657166 = validateParameter(valid_402657166, JString,
                                      required = false, default = nil)
  if valid_402657166 != nil:
    section.add "X-Amz-Security-Token", valid_402657166
  var valid_402657167 = header.getOrDefault("X-Amz-Signature")
  valid_402657167 = validateParameter(valid_402657167, JString,
                                      required = false, default = nil)
  if valid_402657167 != nil:
    section.add "X-Amz-Signature", valid_402657167
  var valid_402657168 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657168 = validateParameter(valid_402657168, JString,
                                      required = false, default = nil)
  if valid_402657168 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657168
  var valid_402657169 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657169 = validateParameter(valid_402657169, JString,
                                      required = false, default = nil)
  if valid_402657169 != nil:
    section.add "X-Amz-Algorithm", valid_402657169
  var valid_402657170 = header.getOrDefault("X-Amz-Date")
  valid_402657170 = validateParameter(valid_402657170, JString,
                                      required = false, default = nil)
  if valid_402657170 != nil:
    section.add "X-Amz-Date", valid_402657170
  var valid_402657171 = header.getOrDefault("X-Amz-Credential")
  valid_402657171 = validateParameter(valid_402657171, JString,
                                      required = false, default = nil)
  if valid_402657171 != nil:
    section.add "X-Amz-Credential", valid_402657171
  var valid_402657172 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657172 = validateParameter(valid_402657172, JString,
                                      required = false, default = nil)
  if valid_402657172 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657172
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

proc call*(call_402657174: Call_ListPullRequests_402657160;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a list of pull requests for a specified repository. The return list can be refined by pull request status or pull request author ARN.
                                                                                         ## 
  let valid = call_402657174.validator(path, query, header, formData, body, _)
  let scheme = call_402657174.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657174.makeUrl(scheme.get, call_402657174.host, call_402657174.base,
                                   call_402657174.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657174, uri, valid, _)

proc call*(call_402657175: Call_ListPullRequests_402657160; body: JsonNode;
           maxResults: string = ""; nextToken: string = ""): Recallable =
  ## listPullRequests
  ## Returns a list of pull requests for a specified repository. The return list can be refined by pull request status or pull request author ARN.
  ##   
                                                                                                                                                  ## maxResults: string
                                                                                                                                                  ##             
                                                                                                                                                  ## : 
                                                                                                                                                  ## Pagination 
                                                                                                                                                  ## limit
  ##   
                                                                                                                                                          ## nextToken: string
                                                                                                                                                          ##            
                                                                                                                                                          ## : 
                                                                                                                                                          ## Pagination 
                                                                                                                                                          ## token
  ##   
                                                                                                                                                                  ## body: JObject (required)
  var query_402657176 = newJObject()
  var body_402657177 = newJObject()
  add(query_402657176, "maxResults", newJString(maxResults))
  add(query_402657176, "nextToken", newJString(nextToken))
  if body != nil:
    body_402657177 = body
  result = call_402657175.call(nil, query_402657176, nil, nil, body_402657177)

var listPullRequests* = Call_ListPullRequests_402657160(
    name: "listPullRequests", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.ListPullRequests",
    validator: validate_ListPullRequests_402657161, base: "/",
    makeUrl: url_ListPullRequests_402657162,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRepositories_402657178 = ref object of OpenApiRestCall_402656044
proc url_ListRepositories_402657180(protocol: Scheme; host: string;
                                    base: string; route: string; path: JsonNode;
                                    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListRepositories_402657179(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
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
  var valid_402657181 = query.getOrDefault("nextToken")
  valid_402657181 = validateParameter(valid_402657181, JString,
                                      required = false, default = nil)
  if valid_402657181 != nil:
    section.add "nextToken", valid_402657181
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657182 = header.getOrDefault("X-Amz-Target")
  valid_402657182 = validateParameter(valid_402657182, JString, required = true, default = newJString(
      "CodeCommit_20150413.ListRepositories"))
  if valid_402657182 != nil:
    section.add "X-Amz-Target", valid_402657182
  var valid_402657183 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657183 = validateParameter(valid_402657183, JString,
                                      required = false, default = nil)
  if valid_402657183 != nil:
    section.add "X-Amz-Security-Token", valid_402657183
  var valid_402657184 = header.getOrDefault("X-Amz-Signature")
  valid_402657184 = validateParameter(valid_402657184, JString,
                                      required = false, default = nil)
  if valid_402657184 != nil:
    section.add "X-Amz-Signature", valid_402657184
  var valid_402657185 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657185 = validateParameter(valid_402657185, JString,
                                      required = false, default = nil)
  if valid_402657185 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657185
  var valid_402657186 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657186 = validateParameter(valid_402657186, JString,
                                      required = false, default = nil)
  if valid_402657186 != nil:
    section.add "X-Amz-Algorithm", valid_402657186
  var valid_402657187 = header.getOrDefault("X-Amz-Date")
  valid_402657187 = validateParameter(valid_402657187, JString,
                                      required = false, default = nil)
  if valid_402657187 != nil:
    section.add "X-Amz-Date", valid_402657187
  var valid_402657188 = header.getOrDefault("X-Amz-Credential")
  valid_402657188 = validateParameter(valid_402657188, JString,
                                      required = false, default = nil)
  if valid_402657188 != nil:
    section.add "X-Amz-Credential", valid_402657188
  var valid_402657189 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657189 = validateParameter(valid_402657189, JString,
                                      required = false, default = nil)
  if valid_402657189 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657189
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

proc call*(call_402657191: Call_ListRepositories_402657178;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets information about one or more repositories.
                                                                                         ## 
  let valid = call_402657191.validator(path, query, header, formData, body, _)
  let scheme = call_402657191.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657191.makeUrl(scheme.get, call_402657191.host, call_402657191.base,
                                   call_402657191.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657191, uri, valid, _)

proc call*(call_402657192: Call_ListRepositories_402657178; body: JsonNode;
           nextToken: string = ""): Recallable =
  ## listRepositories
  ## Gets information about one or more repositories.
  ##   nextToken: string
                                                     ##            : Pagination token
  ##   
                                                                                     ## body: JObject (required)
  var query_402657193 = newJObject()
  var body_402657194 = newJObject()
  add(query_402657193, "nextToken", newJString(nextToken))
  if body != nil:
    body_402657194 = body
  result = call_402657192.call(nil, query_402657193, nil, nil, body_402657194)

var listRepositories* = Call_ListRepositories_402657178(
    name: "listRepositories", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.ListRepositories",
    validator: validate_ListRepositories_402657179, base: "/",
    makeUrl: url_ListRepositories_402657180,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRepositoriesForApprovalRuleTemplate_402657195 = ref object of OpenApiRestCall_402656044
proc url_ListRepositoriesForApprovalRuleTemplate_402657197(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListRepositoriesForApprovalRuleTemplate_402657196(path: JsonNode;
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
  var valid_402657198 = query.getOrDefault("maxResults")
  valid_402657198 = validateParameter(valid_402657198, JString,
                                      required = false, default = nil)
  if valid_402657198 != nil:
    section.add "maxResults", valid_402657198
  var valid_402657199 = query.getOrDefault("nextToken")
  valid_402657199 = validateParameter(valid_402657199, JString,
                                      required = false, default = nil)
  if valid_402657199 != nil:
    section.add "nextToken", valid_402657199
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657200 = header.getOrDefault("X-Amz-Target")
  valid_402657200 = validateParameter(valid_402657200, JString, required = true, default = newJString(
      "CodeCommit_20150413.ListRepositoriesForApprovalRuleTemplate"))
  if valid_402657200 != nil:
    section.add "X-Amz-Target", valid_402657200
  var valid_402657201 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657201 = validateParameter(valid_402657201, JString,
                                      required = false, default = nil)
  if valid_402657201 != nil:
    section.add "X-Amz-Security-Token", valid_402657201
  var valid_402657202 = header.getOrDefault("X-Amz-Signature")
  valid_402657202 = validateParameter(valid_402657202, JString,
                                      required = false, default = nil)
  if valid_402657202 != nil:
    section.add "X-Amz-Signature", valid_402657202
  var valid_402657203 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657203 = validateParameter(valid_402657203, JString,
                                      required = false, default = nil)
  if valid_402657203 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657203
  var valid_402657204 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657204 = validateParameter(valid_402657204, JString,
                                      required = false, default = nil)
  if valid_402657204 != nil:
    section.add "X-Amz-Algorithm", valid_402657204
  var valid_402657205 = header.getOrDefault("X-Amz-Date")
  valid_402657205 = validateParameter(valid_402657205, JString,
                                      required = false, default = nil)
  if valid_402657205 != nil:
    section.add "X-Amz-Date", valid_402657205
  var valid_402657206 = header.getOrDefault("X-Amz-Credential")
  valid_402657206 = validateParameter(valid_402657206, JString,
                                      required = false, default = nil)
  if valid_402657206 != nil:
    section.add "X-Amz-Credential", valid_402657206
  var valid_402657207 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657207 = validateParameter(valid_402657207, JString,
                                      required = false, default = nil)
  if valid_402657207 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657207
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

proc call*(call_402657209: Call_ListRepositoriesForApprovalRuleTemplate_402657195;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists all repositories associated with the specified approval rule template.
                                                                                         ## 
  let valid = call_402657209.validator(path, query, header, formData, body, _)
  let scheme = call_402657209.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657209.makeUrl(scheme.get, call_402657209.host, call_402657209.base,
                                   call_402657209.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657209, uri, valid, _)

proc call*(call_402657210: Call_ListRepositoriesForApprovalRuleTemplate_402657195;
           body: JsonNode; maxResults: string = ""; nextToken: string = ""): Recallable =
  ## listRepositoriesForApprovalRuleTemplate
  ## Lists all repositories associated with the specified approval rule template.
  ##   
                                                                                 ## maxResults: string
                                                                                 ##             
                                                                                 ## : 
                                                                                 ## Pagination 
                                                                                 ## limit
  ##   
                                                                                         ## nextToken: string
                                                                                         ##            
                                                                                         ## : 
                                                                                         ## Pagination 
                                                                                         ## token
  ##   
                                                                                                 ## body: JObject (required)
  var query_402657211 = newJObject()
  var body_402657212 = newJObject()
  add(query_402657211, "maxResults", newJString(maxResults))
  add(query_402657211, "nextToken", newJString(nextToken))
  if body != nil:
    body_402657212 = body
  result = call_402657210.call(nil, query_402657211, nil, nil, body_402657212)

var listRepositoriesForApprovalRuleTemplate* = Call_ListRepositoriesForApprovalRuleTemplate_402657195(
    name: "listRepositoriesForApprovalRuleTemplate", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com", route: "/#X-Amz-Target=CodeCommit_20150413.ListRepositoriesForApprovalRuleTemplate",
    validator: validate_ListRepositoriesForApprovalRuleTemplate_402657196,
    base: "/", makeUrl: url_ListRepositoriesForApprovalRuleTemplate_402657197,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_402657213 = ref object of OpenApiRestCall_402656044
proc url_ListTagsForResource_402657215(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTagsForResource_402657214(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657216 = header.getOrDefault("X-Amz-Target")
  valid_402657216 = validateParameter(valid_402657216, JString, required = true, default = newJString(
      "CodeCommit_20150413.ListTagsForResource"))
  if valid_402657216 != nil:
    section.add "X-Amz-Target", valid_402657216
  var valid_402657217 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657217 = validateParameter(valid_402657217, JString,
                                      required = false, default = nil)
  if valid_402657217 != nil:
    section.add "X-Amz-Security-Token", valid_402657217
  var valid_402657218 = header.getOrDefault("X-Amz-Signature")
  valid_402657218 = validateParameter(valid_402657218, JString,
                                      required = false, default = nil)
  if valid_402657218 != nil:
    section.add "X-Amz-Signature", valid_402657218
  var valid_402657219 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657219 = validateParameter(valid_402657219, JString,
                                      required = false, default = nil)
  if valid_402657219 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657219
  var valid_402657220 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657220 = validateParameter(valid_402657220, JString,
                                      required = false, default = nil)
  if valid_402657220 != nil:
    section.add "X-Amz-Algorithm", valid_402657220
  var valid_402657221 = header.getOrDefault("X-Amz-Date")
  valid_402657221 = validateParameter(valid_402657221, JString,
                                      required = false, default = nil)
  if valid_402657221 != nil:
    section.add "X-Amz-Date", valid_402657221
  var valid_402657222 = header.getOrDefault("X-Amz-Credential")
  valid_402657222 = validateParameter(valid_402657222, JString,
                                      required = false, default = nil)
  if valid_402657222 != nil:
    section.add "X-Amz-Credential", valid_402657222
  var valid_402657223 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657223 = validateParameter(valid_402657223, JString,
                                      required = false, default = nil)
  if valid_402657223 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657223
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

proc call*(call_402657225: Call_ListTagsForResource_402657213;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets information about AWS tags for a specified Amazon Resource Name (ARN) in AWS CodeCommit. For a list of valid resources in AWS CodeCommit, see <a href="https://docs.aws.amazon.com/codecommit/latest/userguide/auth-and-access-control-iam-access-control-identity-based.html#arn-formats">CodeCommit Resources and Operations</a> in the<i> AWS CodeCommit User Guide</i>.
                                                                                         ## 
  let valid = call_402657225.validator(path, query, header, formData, body, _)
  let scheme = call_402657225.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657225.makeUrl(scheme.get, call_402657225.host, call_402657225.base,
                                   call_402657225.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657225, uri, valid, _)

proc call*(call_402657226: Call_ListTagsForResource_402657213; body: JsonNode): Recallable =
  ## listTagsForResource
  ## Gets information about AWS tags for a specified Amazon Resource Name (ARN) in AWS CodeCommit. For a list of valid resources in AWS CodeCommit, see <a href="https://docs.aws.amazon.com/codecommit/latest/userguide/auth-and-access-control-iam-access-control-identity-based.html#arn-formats">CodeCommit Resources and Operations</a> in the<i> AWS CodeCommit User Guide</i>.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                     ## body: JObject (required)
  var body_402657227 = newJObject()
  if body != nil:
    body_402657227 = body
  result = call_402657226.call(nil, nil, nil, nil, body_402657227)

var listTagsForResource* = Call_ListTagsForResource_402657213(
    name: "listTagsForResource", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.ListTagsForResource",
    validator: validate_ListTagsForResource_402657214, base: "/",
    makeUrl: url_ListTagsForResource_402657215,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_MergeBranchesByFastForward_402657228 = ref object of OpenApiRestCall_402656044
proc url_MergeBranchesByFastForward_402657230(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_MergeBranchesByFastForward_402657229(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Merges two branches using the fast-forward merge strategy.
                                            ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657231 = header.getOrDefault("X-Amz-Target")
  valid_402657231 = validateParameter(valid_402657231, JString, required = true, default = newJString(
      "CodeCommit_20150413.MergeBranchesByFastForward"))
  if valid_402657231 != nil:
    section.add "X-Amz-Target", valid_402657231
  var valid_402657232 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657232 = validateParameter(valid_402657232, JString,
                                      required = false, default = nil)
  if valid_402657232 != nil:
    section.add "X-Amz-Security-Token", valid_402657232
  var valid_402657233 = header.getOrDefault("X-Amz-Signature")
  valid_402657233 = validateParameter(valid_402657233, JString,
                                      required = false, default = nil)
  if valid_402657233 != nil:
    section.add "X-Amz-Signature", valid_402657233
  var valid_402657234 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657234 = validateParameter(valid_402657234, JString,
                                      required = false, default = nil)
  if valid_402657234 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657234
  var valid_402657235 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657235 = validateParameter(valid_402657235, JString,
                                      required = false, default = nil)
  if valid_402657235 != nil:
    section.add "X-Amz-Algorithm", valid_402657235
  var valid_402657236 = header.getOrDefault("X-Amz-Date")
  valid_402657236 = validateParameter(valid_402657236, JString,
                                      required = false, default = nil)
  if valid_402657236 != nil:
    section.add "X-Amz-Date", valid_402657236
  var valid_402657237 = header.getOrDefault("X-Amz-Credential")
  valid_402657237 = validateParameter(valid_402657237, JString,
                                      required = false, default = nil)
  if valid_402657237 != nil:
    section.add "X-Amz-Credential", valid_402657237
  var valid_402657238 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657238 = validateParameter(valid_402657238, JString,
                                      required = false, default = nil)
  if valid_402657238 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657238
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

proc call*(call_402657240: Call_MergeBranchesByFastForward_402657228;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Merges two branches using the fast-forward merge strategy.
                                                                                         ## 
  let valid = call_402657240.validator(path, query, header, formData, body, _)
  let scheme = call_402657240.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657240.makeUrl(scheme.get, call_402657240.host, call_402657240.base,
                                   call_402657240.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657240, uri, valid, _)

proc call*(call_402657241: Call_MergeBranchesByFastForward_402657228;
           body: JsonNode): Recallable =
  ## mergeBranchesByFastForward
  ## Merges two branches using the fast-forward merge strategy.
  ##   body: JObject (required)
  var body_402657242 = newJObject()
  if body != nil:
    body_402657242 = body
  result = call_402657241.call(nil, nil, nil, nil, body_402657242)

var mergeBranchesByFastForward* = Call_MergeBranchesByFastForward_402657228(
    name: "mergeBranchesByFastForward", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.MergeBranchesByFastForward",
    validator: validate_MergeBranchesByFastForward_402657229, base: "/",
    makeUrl: url_MergeBranchesByFastForward_402657230,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_MergeBranchesBySquash_402657243 = ref object of OpenApiRestCall_402656044
proc url_MergeBranchesBySquash_402657245(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_MergeBranchesBySquash_402657244(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657246 = header.getOrDefault("X-Amz-Target")
  valid_402657246 = validateParameter(valid_402657246, JString, required = true, default = newJString(
      "CodeCommit_20150413.MergeBranchesBySquash"))
  if valid_402657246 != nil:
    section.add "X-Amz-Target", valid_402657246
  var valid_402657247 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657247 = validateParameter(valid_402657247, JString,
                                      required = false, default = nil)
  if valid_402657247 != nil:
    section.add "X-Amz-Security-Token", valid_402657247
  var valid_402657248 = header.getOrDefault("X-Amz-Signature")
  valid_402657248 = validateParameter(valid_402657248, JString,
                                      required = false, default = nil)
  if valid_402657248 != nil:
    section.add "X-Amz-Signature", valid_402657248
  var valid_402657249 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657249 = validateParameter(valid_402657249, JString,
                                      required = false, default = nil)
  if valid_402657249 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657249
  var valid_402657250 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657250 = validateParameter(valid_402657250, JString,
                                      required = false, default = nil)
  if valid_402657250 != nil:
    section.add "X-Amz-Algorithm", valid_402657250
  var valid_402657251 = header.getOrDefault("X-Amz-Date")
  valid_402657251 = validateParameter(valid_402657251, JString,
                                      required = false, default = nil)
  if valid_402657251 != nil:
    section.add "X-Amz-Date", valid_402657251
  var valid_402657252 = header.getOrDefault("X-Amz-Credential")
  valid_402657252 = validateParameter(valid_402657252, JString,
                                      required = false, default = nil)
  if valid_402657252 != nil:
    section.add "X-Amz-Credential", valid_402657252
  var valid_402657253 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657253 = validateParameter(valid_402657253, JString,
                                      required = false, default = nil)
  if valid_402657253 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657253
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

proc call*(call_402657255: Call_MergeBranchesBySquash_402657243;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Merges two branches using the squash merge strategy.
                                                                                         ## 
  let valid = call_402657255.validator(path, query, header, formData, body, _)
  let scheme = call_402657255.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657255.makeUrl(scheme.get, call_402657255.host, call_402657255.base,
                                   call_402657255.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657255, uri, valid, _)

proc call*(call_402657256: Call_MergeBranchesBySquash_402657243; body: JsonNode): Recallable =
  ## mergeBranchesBySquash
  ## Merges two branches using the squash merge strategy.
  ##   body: JObject (required)
  var body_402657257 = newJObject()
  if body != nil:
    body_402657257 = body
  result = call_402657256.call(nil, nil, nil, nil, body_402657257)

var mergeBranchesBySquash* = Call_MergeBranchesBySquash_402657243(
    name: "mergeBranchesBySquash", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.MergeBranchesBySquash",
    validator: validate_MergeBranchesBySquash_402657244, base: "/",
    makeUrl: url_MergeBranchesBySquash_402657245,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_MergeBranchesByThreeWay_402657258 = ref object of OpenApiRestCall_402656044
proc url_MergeBranchesByThreeWay_402657260(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_MergeBranchesByThreeWay_402657259(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657261 = header.getOrDefault("X-Amz-Target")
  valid_402657261 = validateParameter(valid_402657261, JString, required = true, default = newJString(
      "CodeCommit_20150413.MergeBranchesByThreeWay"))
  if valid_402657261 != nil:
    section.add "X-Amz-Target", valid_402657261
  var valid_402657262 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657262 = validateParameter(valid_402657262, JString,
                                      required = false, default = nil)
  if valid_402657262 != nil:
    section.add "X-Amz-Security-Token", valid_402657262
  var valid_402657263 = header.getOrDefault("X-Amz-Signature")
  valid_402657263 = validateParameter(valid_402657263, JString,
                                      required = false, default = nil)
  if valid_402657263 != nil:
    section.add "X-Amz-Signature", valid_402657263
  var valid_402657264 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657264 = validateParameter(valid_402657264, JString,
                                      required = false, default = nil)
  if valid_402657264 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657264
  var valid_402657265 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657265 = validateParameter(valid_402657265, JString,
                                      required = false, default = nil)
  if valid_402657265 != nil:
    section.add "X-Amz-Algorithm", valid_402657265
  var valid_402657266 = header.getOrDefault("X-Amz-Date")
  valid_402657266 = validateParameter(valid_402657266, JString,
                                      required = false, default = nil)
  if valid_402657266 != nil:
    section.add "X-Amz-Date", valid_402657266
  var valid_402657267 = header.getOrDefault("X-Amz-Credential")
  valid_402657267 = validateParameter(valid_402657267, JString,
                                      required = false, default = nil)
  if valid_402657267 != nil:
    section.add "X-Amz-Credential", valid_402657267
  var valid_402657268 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657268 = validateParameter(valid_402657268, JString,
                                      required = false, default = nil)
  if valid_402657268 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657268
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

proc call*(call_402657270: Call_MergeBranchesByThreeWay_402657258;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Merges two specified branches using the three-way merge strategy.
                                                                                         ## 
  let valid = call_402657270.validator(path, query, header, formData, body, _)
  let scheme = call_402657270.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657270.makeUrl(scheme.get, call_402657270.host, call_402657270.base,
                                   call_402657270.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657270, uri, valid, _)

proc call*(call_402657271: Call_MergeBranchesByThreeWay_402657258;
           body: JsonNode): Recallable =
  ## mergeBranchesByThreeWay
  ## Merges two specified branches using the three-way merge strategy.
  ##   body: JObject (required)
  var body_402657272 = newJObject()
  if body != nil:
    body_402657272 = body
  result = call_402657271.call(nil, nil, nil, nil, body_402657272)

var mergeBranchesByThreeWay* = Call_MergeBranchesByThreeWay_402657258(
    name: "mergeBranchesByThreeWay", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.MergeBranchesByThreeWay",
    validator: validate_MergeBranchesByThreeWay_402657259, base: "/",
    makeUrl: url_MergeBranchesByThreeWay_402657260,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_MergePullRequestByFastForward_402657273 = ref object of OpenApiRestCall_402656044
proc url_MergePullRequestByFastForward_402657275(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_MergePullRequestByFastForward_402657274(path: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657276 = header.getOrDefault("X-Amz-Target")
  valid_402657276 = validateParameter(valid_402657276, JString, required = true, default = newJString(
      "CodeCommit_20150413.MergePullRequestByFastForward"))
  if valid_402657276 != nil:
    section.add "X-Amz-Target", valid_402657276
  var valid_402657277 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657277 = validateParameter(valid_402657277, JString,
                                      required = false, default = nil)
  if valid_402657277 != nil:
    section.add "X-Amz-Security-Token", valid_402657277
  var valid_402657278 = header.getOrDefault("X-Amz-Signature")
  valid_402657278 = validateParameter(valid_402657278, JString,
                                      required = false, default = nil)
  if valid_402657278 != nil:
    section.add "X-Amz-Signature", valid_402657278
  var valid_402657279 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657279 = validateParameter(valid_402657279, JString,
                                      required = false, default = nil)
  if valid_402657279 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657279
  var valid_402657280 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657280 = validateParameter(valid_402657280, JString,
                                      required = false, default = nil)
  if valid_402657280 != nil:
    section.add "X-Amz-Algorithm", valid_402657280
  var valid_402657281 = header.getOrDefault("X-Amz-Date")
  valid_402657281 = validateParameter(valid_402657281, JString,
                                      required = false, default = nil)
  if valid_402657281 != nil:
    section.add "X-Amz-Date", valid_402657281
  var valid_402657282 = header.getOrDefault("X-Amz-Credential")
  valid_402657282 = validateParameter(valid_402657282, JString,
                                      required = false, default = nil)
  if valid_402657282 != nil:
    section.add "X-Amz-Credential", valid_402657282
  var valid_402657283 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657283 = validateParameter(valid_402657283, JString,
                                      required = false, default = nil)
  if valid_402657283 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657283
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

proc call*(call_402657285: Call_MergePullRequestByFastForward_402657273;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Attempts to merge the source commit of a pull request into the specified destination branch for that pull request at the specified commit using the fast-forward merge strategy. If the merge is successful, it closes the pull request.
                                                                                         ## 
  let valid = call_402657285.validator(path, query, header, formData, body, _)
  let scheme = call_402657285.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657285.makeUrl(scheme.get, call_402657285.host, call_402657285.base,
                                   call_402657285.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657285, uri, valid, _)

proc call*(call_402657286: Call_MergePullRequestByFastForward_402657273;
           body: JsonNode): Recallable =
  ## mergePullRequestByFastForward
  ## Attempts to merge the source commit of a pull request into the specified destination branch for that pull request at the specified commit using the fast-forward merge strategy. If the merge is successful, it closes the pull request.
  ##   
                                                                                                                                                                                                                                             ## body: JObject (required)
  var body_402657287 = newJObject()
  if body != nil:
    body_402657287 = body
  result = call_402657286.call(nil, nil, nil, nil, body_402657287)

var mergePullRequestByFastForward* = Call_MergePullRequestByFastForward_402657273(
    name: "mergePullRequestByFastForward", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.MergePullRequestByFastForward",
    validator: validate_MergePullRequestByFastForward_402657274, base: "/",
    makeUrl: url_MergePullRequestByFastForward_402657275,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_MergePullRequestBySquash_402657288 = ref object of OpenApiRestCall_402656044
proc url_MergePullRequestBySquash_402657290(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_MergePullRequestBySquash_402657289(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Attempts to merge the source commit of a pull request into the specified destination branch for that pull request at the specified commit using the squash merge strategy. If the merge is successful, it closes the pull request.
                                            ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657291 = header.getOrDefault("X-Amz-Target")
  valid_402657291 = validateParameter(valid_402657291, JString, required = true, default = newJString(
      "CodeCommit_20150413.MergePullRequestBySquash"))
  if valid_402657291 != nil:
    section.add "X-Amz-Target", valid_402657291
  var valid_402657292 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657292 = validateParameter(valid_402657292, JString,
                                      required = false, default = nil)
  if valid_402657292 != nil:
    section.add "X-Amz-Security-Token", valid_402657292
  var valid_402657293 = header.getOrDefault("X-Amz-Signature")
  valid_402657293 = validateParameter(valid_402657293, JString,
                                      required = false, default = nil)
  if valid_402657293 != nil:
    section.add "X-Amz-Signature", valid_402657293
  var valid_402657294 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657294 = validateParameter(valid_402657294, JString,
                                      required = false, default = nil)
  if valid_402657294 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657294
  var valid_402657295 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657295 = validateParameter(valid_402657295, JString,
                                      required = false, default = nil)
  if valid_402657295 != nil:
    section.add "X-Amz-Algorithm", valid_402657295
  var valid_402657296 = header.getOrDefault("X-Amz-Date")
  valid_402657296 = validateParameter(valid_402657296, JString,
                                      required = false, default = nil)
  if valid_402657296 != nil:
    section.add "X-Amz-Date", valid_402657296
  var valid_402657297 = header.getOrDefault("X-Amz-Credential")
  valid_402657297 = validateParameter(valid_402657297, JString,
                                      required = false, default = nil)
  if valid_402657297 != nil:
    section.add "X-Amz-Credential", valid_402657297
  var valid_402657298 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657298 = validateParameter(valid_402657298, JString,
                                      required = false, default = nil)
  if valid_402657298 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657298
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

proc call*(call_402657300: Call_MergePullRequestBySquash_402657288;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Attempts to merge the source commit of a pull request into the specified destination branch for that pull request at the specified commit using the squash merge strategy. If the merge is successful, it closes the pull request.
                                                                                         ## 
  let valid = call_402657300.validator(path, query, header, formData, body, _)
  let scheme = call_402657300.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657300.makeUrl(scheme.get, call_402657300.host, call_402657300.base,
                                   call_402657300.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657300, uri, valid, _)

proc call*(call_402657301: Call_MergePullRequestBySquash_402657288;
           body: JsonNode): Recallable =
  ## mergePullRequestBySquash
  ## Attempts to merge the source commit of a pull request into the specified destination branch for that pull request at the specified commit using the squash merge strategy. If the merge is successful, it closes the pull request.
  ##   
                                                                                                                                                                                                                                       ## body: JObject (required)
  var body_402657302 = newJObject()
  if body != nil:
    body_402657302 = body
  result = call_402657301.call(nil, nil, nil, nil, body_402657302)

var mergePullRequestBySquash* = Call_MergePullRequestBySquash_402657288(
    name: "mergePullRequestBySquash", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.MergePullRequestBySquash",
    validator: validate_MergePullRequestBySquash_402657289, base: "/",
    makeUrl: url_MergePullRequestBySquash_402657290,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_MergePullRequestByThreeWay_402657303 = ref object of OpenApiRestCall_402656044
proc url_MergePullRequestByThreeWay_402657305(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_MergePullRequestByThreeWay_402657304(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Attempts to merge the source commit of a pull request into the specified destination branch for that pull request at the specified commit using the three-way merge strategy. If the merge is successful, it closes the pull request.
                                            ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657306 = header.getOrDefault("X-Amz-Target")
  valid_402657306 = validateParameter(valid_402657306, JString, required = true, default = newJString(
      "CodeCommit_20150413.MergePullRequestByThreeWay"))
  if valid_402657306 != nil:
    section.add "X-Amz-Target", valid_402657306
  var valid_402657307 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657307 = validateParameter(valid_402657307, JString,
                                      required = false, default = nil)
  if valid_402657307 != nil:
    section.add "X-Amz-Security-Token", valid_402657307
  var valid_402657308 = header.getOrDefault("X-Amz-Signature")
  valid_402657308 = validateParameter(valid_402657308, JString,
                                      required = false, default = nil)
  if valid_402657308 != nil:
    section.add "X-Amz-Signature", valid_402657308
  var valid_402657309 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657309 = validateParameter(valid_402657309, JString,
                                      required = false, default = nil)
  if valid_402657309 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657309
  var valid_402657310 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657310 = validateParameter(valid_402657310, JString,
                                      required = false, default = nil)
  if valid_402657310 != nil:
    section.add "X-Amz-Algorithm", valid_402657310
  var valid_402657311 = header.getOrDefault("X-Amz-Date")
  valid_402657311 = validateParameter(valid_402657311, JString,
                                      required = false, default = nil)
  if valid_402657311 != nil:
    section.add "X-Amz-Date", valid_402657311
  var valid_402657312 = header.getOrDefault("X-Amz-Credential")
  valid_402657312 = validateParameter(valid_402657312, JString,
                                      required = false, default = nil)
  if valid_402657312 != nil:
    section.add "X-Amz-Credential", valid_402657312
  var valid_402657313 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657313 = validateParameter(valid_402657313, JString,
                                      required = false, default = nil)
  if valid_402657313 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657313
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

proc call*(call_402657315: Call_MergePullRequestByThreeWay_402657303;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Attempts to merge the source commit of a pull request into the specified destination branch for that pull request at the specified commit using the three-way merge strategy. If the merge is successful, it closes the pull request.
                                                                                         ## 
  let valid = call_402657315.validator(path, query, header, formData, body, _)
  let scheme = call_402657315.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657315.makeUrl(scheme.get, call_402657315.host, call_402657315.base,
                                   call_402657315.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657315, uri, valid, _)

proc call*(call_402657316: Call_MergePullRequestByThreeWay_402657303;
           body: JsonNode): Recallable =
  ## mergePullRequestByThreeWay
  ## Attempts to merge the source commit of a pull request into the specified destination branch for that pull request at the specified commit using the three-way merge strategy. If the merge is successful, it closes the pull request.
  ##   
                                                                                                                                                                                                                                          ## body: JObject (required)
  var body_402657317 = newJObject()
  if body != nil:
    body_402657317 = body
  result = call_402657316.call(nil, nil, nil, nil, body_402657317)

var mergePullRequestByThreeWay* = Call_MergePullRequestByThreeWay_402657303(
    name: "mergePullRequestByThreeWay", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.MergePullRequestByThreeWay",
    validator: validate_MergePullRequestByThreeWay_402657304, base: "/",
    makeUrl: url_MergePullRequestByThreeWay_402657305,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_OverridePullRequestApprovalRules_402657318 = ref object of OpenApiRestCall_402656044
proc url_OverridePullRequestApprovalRules_402657320(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_OverridePullRequestApprovalRules_402657319(path: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657321 = header.getOrDefault("X-Amz-Target")
  valid_402657321 = validateParameter(valid_402657321, JString, required = true, default = newJString(
      "CodeCommit_20150413.OverridePullRequestApprovalRules"))
  if valid_402657321 != nil:
    section.add "X-Amz-Target", valid_402657321
  var valid_402657322 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657322 = validateParameter(valid_402657322, JString,
                                      required = false, default = nil)
  if valid_402657322 != nil:
    section.add "X-Amz-Security-Token", valid_402657322
  var valid_402657323 = header.getOrDefault("X-Amz-Signature")
  valid_402657323 = validateParameter(valid_402657323, JString,
                                      required = false, default = nil)
  if valid_402657323 != nil:
    section.add "X-Amz-Signature", valid_402657323
  var valid_402657324 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657324 = validateParameter(valid_402657324, JString,
                                      required = false, default = nil)
  if valid_402657324 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657324
  var valid_402657325 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657325 = validateParameter(valid_402657325, JString,
                                      required = false, default = nil)
  if valid_402657325 != nil:
    section.add "X-Amz-Algorithm", valid_402657325
  var valid_402657326 = header.getOrDefault("X-Amz-Date")
  valid_402657326 = validateParameter(valid_402657326, JString,
                                      required = false, default = nil)
  if valid_402657326 != nil:
    section.add "X-Amz-Date", valid_402657326
  var valid_402657327 = header.getOrDefault("X-Amz-Credential")
  valid_402657327 = validateParameter(valid_402657327, JString,
                                      required = false, default = nil)
  if valid_402657327 != nil:
    section.add "X-Amz-Credential", valid_402657327
  var valid_402657328 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657328 = validateParameter(valid_402657328, JString,
                                      required = false, default = nil)
  if valid_402657328 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657328
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

proc call*(call_402657330: Call_OverridePullRequestApprovalRules_402657318;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Sets aside (overrides) all approval rule requirements for a specified pull request.
                                                                                         ## 
  let valid = call_402657330.validator(path, query, header, formData, body, _)
  let scheme = call_402657330.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657330.makeUrl(scheme.get, call_402657330.host, call_402657330.base,
                                   call_402657330.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657330, uri, valid, _)

proc call*(call_402657331: Call_OverridePullRequestApprovalRules_402657318;
           body: JsonNode): Recallable =
  ## overridePullRequestApprovalRules
  ## Sets aside (overrides) all approval rule requirements for a specified pull request.
  ##   
                                                                                        ## body: JObject (required)
  var body_402657332 = newJObject()
  if body != nil:
    body_402657332 = body
  result = call_402657331.call(nil, nil, nil, nil, body_402657332)

var overridePullRequestApprovalRules* = Call_OverridePullRequestApprovalRules_402657318(
    name: "overridePullRequestApprovalRules", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com", route: "/#X-Amz-Target=CodeCommit_20150413.OverridePullRequestApprovalRules",
    validator: validate_OverridePullRequestApprovalRules_402657319, base: "/",
    makeUrl: url_OverridePullRequestApprovalRules_402657320,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCommentForComparedCommit_402657333 = ref object of OpenApiRestCall_402656044
proc url_PostCommentForComparedCommit_402657335(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCommentForComparedCommit_402657334(path: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657336 = header.getOrDefault("X-Amz-Target")
  valid_402657336 = validateParameter(valid_402657336, JString, required = true, default = newJString(
      "CodeCommit_20150413.PostCommentForComparedCommit"))
  if valid_402657336 != nil:
    section.add "X-Amz-Target", valid_402657336
  var valid_402657337 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657337 = validateParameter(valid_402657337, JString,
                                      required = false, default = nil)
  if valid_402657337 != nil:
    section.add "X-Amz-Security-Token", valid_402657337
  var valid_402657338 = header.getOrDefault("X-Amz-Signature")
  valid_402657338 = validateParameter(valid_402657338, JString,
                                      required = false, default = nil)
  if valid_402657338 != nil:
    section.add "X-Amz-Signature", valid_402657338
  var valid_402657339 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657339 = validateParameter(valid_402657339, JString,
                                      required = false, default = nil)
  if valid_402657339 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657339
  var valid_402657340 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657340 = validateParameter(valid_402657340, JString,
                                      required = false, default = nil)
  if valid_402657340 != nil:
    section.add "X-Amz-Algorithm", valid_402657340
  var valid_402657341 = header.getOrDefault("X-Amz-Date")
  valid_402657341 = validateParameter(valid_402657341, JString,
                                      required = false, default = nil)
  if valid_402657341 != nil:
    section.add "X-Amz-Date", valid_402657341
  var valid_402657342 = header.getOrDefault("X-Amz-Credential")
  valid_402657342 = validateParameter(valid_402657342, JString,
                                      required = false, default = nil)
  if valid_402657342 != nil:
    section.add "X-Amz-Credential", valid_402657342
  var valid_402657343 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657343 = validateParameter(valid_402657343, JString,
                                      required = false, default = nil)
  if valid_402657343 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657343
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

proc call*(call_402657345: Call_PostCommentForComparedCommit_402657333;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Posts a comment on the comparison between two commits.
                                                                                         ## 
  let valid = call_402657345.validator(path, query, header, formData, body, _)
  let scheme = call_402657345.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657345.makeUrl(scheme.get, call_402657345.host, call_402657345.base,
                                   call_402657345.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657345, uri, valid, _)

proc call*(call_402657346: Call_PostCommentForComparedCommit_402657333;
           body: JsonNode): Recallable =
  ## postCommentForComparedCommit
  ## Posts a comment on the comparison between two commits.
  ##   body: JObject (required)
  var body_402657347 = newJObject()
  if body != nil:
    body_402657347 = body
  result = call_402657346.call(nil, nil, nil, nil, body_402657347)

var postCommentForComparedCommit* = Call_PostCommentForComparedCommit_402657333(
    name: "postCommentForComparedCommit", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.PostCommentForComparedCommit",
    validator: validate_PostCommentForComparedCommit_402657334, base: "/",
    makeUrl: url_PostCommentForComparedCommit_402657335,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCommentForPullRequest_402657348 = ref object of OpenApiRestCall_402656044
proc url_PostCommentForPullRequest_402657350(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCommentForPullRequest_402657349(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Posts a comment on a pull request.
                                            ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657351 = header.getOrDefault("X-Amz-Target")
  valid_402657351 = validateParameter(valid_402657351, JString, required = true, default = newJString(
      "CodeCommit_20150413.PostCommentForPullRequest"))
  if valid_402657351 != nil:
    section.add "X-Amz-Target", valid_402657351
  var valid_402657352 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657352 = validateParameter(valid_402657352, JString,
                                      required = false, default = nil)
  if valid_402657352 != nil:
    section.add "X-Amz-Security-Token", valid_402657352
  var valid_402657353 = header.getOrDefault("X-Amz-Signature")
  valid_402657353 = validateParameter(valid_402657353, JString,
                                      required = false, default = nil)
  if valid_402657353 != nil:
    section.add "X-Amz-Signature", valid_402657353
  var valid_402657354 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657354 = validateParameter(valid_402657354, JString,
                                      required = false, default = nil)
  if valid_402657354 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657354
  var valid_402657355 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657355 = validateParameter(valid_402657355, JString,
                                      required = false, default = nil)
  if valid_402657355 != nil:
    section.add "X-Amz-Algorithm", valid_402657355
  var valid_402657356 = header.getOrDefault("X-Amz-Date")
  valid_402657356 = validateParameter(valid_402657356, JString,
                                      required = false, default = nil)
  if valid_402657356 != nil:
    section.add "X-Amz-Date", valid_402657356
  var valid_402657357 = header.getOrDefault("X-Amz-Credential")
  valid_402657357 = validateParameter(valid_402657357, JString,
                                      required = false, default = nil)
  if valid_402657357 != nil:
    section.add "X-Amz-Credential", valid_402657357
  var valid_402657358 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657358 = validateParameter(valid_402657358, JString,
                                      required = false, default = nil)
  if valid_402657358 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657358
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

proc call*(call_402657360: Call_PostCommentForPullRequest_402657348;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Posts a comment on a pull request.
                                                                                         ## 
  let valid = call_402657360.validator(path, query, header, formData, body, _)
  let scheme = call_402657360.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657360.makeUrl(scheme.get, call_402657360.host, call_402657360.base,
                                   call_402657360.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657360, uri, valid, _)

proc call*(call_402657361: Call_PostCommentForPullRequest_402657348;
           body: JsonNode): Recallable =
  ## postCommentForPullRequest
  ## Posts a comment on a pull request.
  ##   body: JObject (required)
  var body_402657362 = newJObject()
  if body != nil:
    body_402657362 = body
  result = call_402657361.call(nil, nil, nil, nil, body_402657362)

var postCommentForPullRequest* = Call_PostCommentForPullRequest_402657348(
    name: "postCommentForPullRequest", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.PostCommentForPullRequest",
    validator: validate_PostCommentForPullRequest_402657349, base: "/",
    makeUrl: url_PostCommentForPullRequest_402657350,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCommentReply_402657363 = ref object of OpenApiRestCall_402656044
proc url_PostCommentReply_402657365(protocol: Scheme; host: string;
                                    base: string; route: string; path: JsonNode;
                                    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCommentReply_402657364(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657366 = header.getOrDefault("X-Amz-Target")
  valid_402657366 = validateParameter(valid_402657366, JString, required = true, default = newJString(
      "CodeCommit_20150413.PostCommentReply"))
  if valid_402657366 != nil:
    section.add "X-Amz-Target", valid_402657366
  var valid_402657367 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657367 = validateParameter(valid_402657367, JString,
                                      required = false, default = nil)
  if valid_402657367 != nil:
    section.add "X-Amz-Security-Token", valid_402657367
  var valid_402657368 = header.getOrDefault("X-Amz-Signature")
  valid_402657368 = validateParameter(valid_402657368, JString,
                                      required = false, default = nil)
  if valid_402657368 != nil:
    section.add "X-Amz-Signature", valid_402657368
  var valid_402657369 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657369 = validateParameter(valid_402657369, JString,
                                      required = false, default = nil)
  if valid_402657369 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657369
  var valid_402657370 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657370 = validateParameter(valid_402657370, JString,
                                      required = false, default = nil)
  if valid_402657370 != nil:
    section.add "X-Amz-Algorithm", valid_402657370
  var valid_402657371 = header.getOrDefault("X-Amz-Date")
  valid_402657371 = validateParameter(valid_402657371, JString,
                                      required = false, default = nil)
  if valid_402657371 != nil:
    section.add "X-Amz-Date", valid_402657371
  var valid_402657372 = header.getOrDefault("X-Amz-Credential")
  valid_402657372 = validateParameter(valid_402657372, JString,
                                      required = false, default = nil)
  if valid_402657372 != nil:
    section.add "X-Amz-Credential", valid_402657372
  var valid_402657373 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657373 = validateParameter(valid_402657373, JString,
                                      required = false, default = nil)
  if valid_402657373 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657373
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

proc call*(call_402657375: Call_PostCommentReply_402657363;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Posts a comment in reply to an existing comment on a comparison between commits or a pull request.
                                                                                         ## 
  let valid = call_402657375.validator(path, query, header, formData, body, _)
  let scheme = call_402657375.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657375.makeUrl(scheme.get, call_402657375.host, call_402657375.base,
                                   call_402657375.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657375, uri, valid, _)

proc call*(call_402657376: Call_PostCommentReply_402657363; body: JsonNode): Recallable =
  ## postCommentReply
  ## Posts a comment in reply to an existing comment on a comparison between commits or a pull request.
  ##   
                                                                                                       ## body: JObject (required)
  var body_402657377 = newJObject()
  if body != nil:
    body_402657377 = body
  result = call_402657376.call(nil, nil, nil, nil, body_402657377)

var postCommentReply* = Call_PostCommentReply_402657363(
    name: "postCommentReply", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.PostCommentReply",
    validator: validate_PostCommentReply_402657364, base: "/",
    makeUrl: url_PostCommentReply_402657365,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutFile_402657378 = ref object of OpenApiRestCall_402656044
proc url_PutFile_402657380(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutFile_402657379(path: JsonNode; query: JsonNode;
                                header: JsonNode; formData: JsonNode;
                                body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657381 = header.getOrDefault("X-Amz-Target")
  valid_402657381 = validateParameter(valid_402657381, JString, required = true, default = newJString(
      "CodeCommit_20150413.PutFile"))
  if valid_402657381 != nil:
    section.add "X-Amz-Target", valid_402657381
  var valid_402657382 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657382 = validateParameter(valid_402657382, JString,
                                      required = false, default = nil)
  if valid_402657382 != nil:
    section.add "X-Amz-Security-Token", valid_402657382
  var valid_402657383 = header.getOrDefault("X-Amz-Signature")
  valid_402657383 = validateParameter(valid_402657383, JString,
                                      required = false, default = nil)
  if valid_402657383 != nil:
    section.add "X-Amz-Signature", valid_402657383
  var valid_402657384 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657384 = validateParameter(valid_402657384, JString,
                                      required = false, default = nil)
  if valid_402657384 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657384
  var valid_402657385 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657385 = validateParameter(valid_402657385, JString,
                                      required = false, default = nil)
  if valid_402657385 != nil:
    section.add "X-Amz-Algorithm", valid_402657385
  var valid_402657386 = header.getOrDefault("X-Amz-Date")
  valid_402657386 = validateParameter(valid_402657386, JString,
                                      required = false, default = nil)
  if valid_402657386 != nil:
    section.add "X-Amz-Date", valid_402657386
  var valid_402657387 = header.getOrDefault("X-Amz-Credential")
  valid_402657387 = validateParameter(valid_402657387, JString,
                                      required = false, default = nil)
  if valid_402657387 != nil:
    section.add "X-Amz-Credential", valid_402657387
  var valid_402657388 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657388 = validateParameter(valid_402657388, JString,
                                      required = false, default = nil)
  if valid_402657388 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657388
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

proc call*(call_402657390: Call_PutFile_402657378; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Adds or updates a file in a branch in an AWS CodeCommit repository, and generates a commit for the addition in the specified branch.
                                                                                         ## 
  let valid = call_402657390.validator(path, query, header, formData, body, _)
  let scheme = call_402657390.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657390.makeUrl(scheme.get, call_402657390.host, call_402657390.base,
                                   call_402657390.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657390, uri, valid, _)

proc call*(call_402657391: Call_PutFile_402657378; body: JsonNode): Recallable =
  ## putFile
  ## Adds or updates a file in a branch in an AWS CodeCommit repository, and generates a commit for the addition in the specified branch.
  ##   
                                                                                                                                         ## body: JObject (required)
  var body_402657392 = newJObject()
  if body != nil:
    body_402657392 = body
  result = call_402657391.call(nil, nil, nil, nil, body_402657392)

var putFile* = Call_PutFile_402657378(name: "putFile",
                                      meth: HttpMethod.HttpPost,
                                      host: "codecommit.amazonaws.com", route: "/#X-Amz-Target=CodeCommit_20150413.PutFile",
                                      validator: validate_PutFile_402657379,
                                      base: "/", makeUrl: url_PutFile_402657380,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutRepositoryTriggers_402657393 = ref object of OpenApiRestCall_402656044
proc url_PutRepositoryTriggers_402657395(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutRepositoryTriggers_402657394(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657396 = header.getOrDefault("X-Amz-Target")
  valid_402657396 = validateParameter(valid_402657396, JString, required = true, default = newJString(
      "CodeCommit_20150413.PutRepositoryTriggers"))
  if valid_402657396 != nil:
    section.add "X-Amz-Target", valid_402657396
  var valid_402657397 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657397 = validateParameter(valid_402657397, JString,
                                      required = false, default = nil)
  if valid_402657397 != nil:
    section.add "X-Amz-Security-Token", valid_402657397
  var valid_402657398 = header.getOrDefault("X-Amz-Signature")
  valid_402657398 = validateParameter(valid_402657398, JString,
                                      required = false, default = nil)
  if valid_402657398 != nil:
    section.add "X-Amz-Signature", valid_402657398
  var valid_402657399 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657399 = validateParameter(valid_402657399, JString,
                                      required = false, default = nil)
  if valid_402657399 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657399
  var valid_402657400 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657400 = validateParameter(valid_402657400, JString,
                                      required = false, default = nil)
  if valid_402657400 != nil:
    section.add "X-Amz-Algorithm", valid_402657400
  var valid_402657401 = header.getOrDefault("X-Amz-Date")
  valid_402657401 = validateParameter(valid_402657401, JString,
                                      required = false, default = nil)
  if valid_402657401 != nil:
    section.add "X-Amz-Date", valid_402657401
  var valid_402657402 = header.getOrDefault("X-Amz-Credential")
  valid_402657402 = validateParameter(valid_402657402, JString,
                                      required = false, default = nil)
  if valid_402657402 != nil:
    section.add "X-Amz-Credential", valid_402657402
  var valid_402657403 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657403 = validateParameter(valid_402657403, JString,
                                      required = false, default = nil)
  if valid_402657403 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657403
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

proc call*(call_402657405: Call_PutRepositoryTriggers_402657393;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Replaces all triggers for a repository. Used to create or delete triggers.
                                                                                         ## 
  let valid = call_402657405.validator(path, query, header, formData, body, _)
  let scheme = call_402657405.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657405.makeUrl(scheme.get, call_402657405.host, call_402657405.base,
                                   call_402657405.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657405, uri, valid, _)

proc call*(call_402657406: Call_PutRepositoryTriggers_402657393; body: JsonNode): Recallable =
  ## putRepositoryTriggers
  ## Replaces all triggers for a repository. Used to create or delete triggers.
  ##   
                                                                               ## body: JObject (required)
  var body_402657407 = newJObject()
  if body != nil:
    body_402657407 = body
  result = call_402657406.call(nil, nil, nil, nil, body_402657407)

var putRepositoryTriggers* = Call_PutRepositoryTriggers_402657393(
    name: "putRepositoryTriggers", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.PutRepositoryTriggers",
    validator: validate_PutRepositoryTriggers_402657394, base: "/",
    makeUrl: url_PutRepositoryTriggers_402657395,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_402657408 = ref object of OpenApiRestCall_402656044
proc url_TagResource_402657410(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_TagResource_402657409(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657411 = header.getOrDefault("X-Amz-Target")
  valid_402657411 = validateParameter(valid_402657411, JString, required = true, default = newJString(
      "CodeCommit_20150413.TagResource"))
  if valid_402657411 != nil:
    section.add "X-Amz-Target", valid_402657411
  var valid_402657412 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657412 = validateParameter(valid_402657412, JString,
                                      required = false, default = nil)
  if valid_402657412 != nil:
    section.add "X-Amz-Security-Token", valid_402657412
  var valid_402657413 = header.getOrDefault("X-Amz-Signature")
  valid_402657413 = validateParameter(valid_402657413, JString,
                                      required = false, default = nil)
  if valid_402657413 != nil:
    section.add "X-Amz-Signature", valid_402657413
  var valid_402657414 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657414 = validateParameter(valid_402657414, JString,
                                      required = false, default = nil)
  if valid_402657414 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657414
  var valid_402657415 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657415 = validateParameter(valid_402657415, JString,
                                      required = false, default = nil)
  if valid_402657415 != nil:
    section.add "X-Amz-Algorithm", valid_402657415
  var valid_402657416 = header.getOrDefault("X-Amz-Date")
  valid_402657416 = validateParameter(valid_402657416, JString,
                                      required = false, default = nil)
  if valid_402657416 != nil:
    section.add "X-Amz-Date", valid_402657416
  var valid_402657417 = header.getOrDefault("X-Amz-Credential")
  valid_402657417 = validateParameter(valid_402657417, JString,
                                      required = false, default = nil)
  if valid_402657417 != nil:
    section.add "X-Amz-Credential", valid_402657417
  var valid_402657418 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657418 = validateParameter(valid_402657418, JString,
                                      required = false, default = nil)
  if valid_402657418 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657418
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

proc call*(call_402657420: Call_TagResource_402657408; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Adds or updates tags for a resource in AWS CodeCommit. For a list of valid resources in AWS CodeCommit, see <a href="https://docs.aws.amazon.com/codecommit/latest/userguide/auth-and-access-control-iam-access-control-identity-based.html#arn-formats">CodeCommit Resources and Operations</a> in the <i>AWS CodeCommit User Guide</i>.
                                                                                         ## 
  let valid = call_402657420.validator(path, query, header, formData, body, _)
  let scheme = call_402657420.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657420.makeUrl(scheme.get, call_402657420.host, call_402657420.base,
                                   call_402657420.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657420, uri, valid, _)

proc call*(call_402657421: Call_TagResource_402657408; body: JsonNode): Recallable =
  ## tagResource
  ## Adds or updates tags for a resource in AWS CodeCommit. For a list of valid resources in AWS CodeCommit, see <a href="https://docs.aws.amazon.com/codecommit/latest/userguide/auth-and-access-control-iam-access-control-identity-based.html#arn-formats">CodeCommit Resources and Operations</a> in the <i>AWS CodeCommit User Guide</i>.
  ##   
                                                                                                                                                                                                                                                                                                                                              ## body: JObject (required)
  var body_402657422 = newJObject()
  if body != nil:
    body_402657422 = body
  result = call_402657421.call(nil, nil, nil, nil, body_402657422)

var tagResource* = Call_TagResource_402657408(name: "tagResource",
    meth: HttpMethod.HttpPost, host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.TagResource",
    validator: validate_TagResource_402657409, base: "/",
    makeUrl: url_TagResource_402657410, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TestRepositoryTriggers_402657423 = ref object of OpenApiRestCall_402656044
proc url_TestRepositoryTriggers_402657425(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_TestRepositoryTriggers_402657424(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657426 = header.getOrDefault("X-Amz-Target")
  valid_402657426 = validateParameter(valid_402657426, JString, required = true, default = newJString(
      "CodeCommit_20150413.TestRepositoryTriggers"))
  if valid_402657426 != nil:
    section.add "X-Amz-Target", valid_402657426
  var valid_402657427 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657427 = validateParameter(valid_402657427, JString,
                                      required = false, default = nil)
  if valid_402657427 != nil:
    section.add "X-Amz-Security-Token", valid_402657427
  var valid_402657428 = header.getOrDefault("X-Amz-Signature")
  valid_402657428 = validateParameter(valid_402657428, JString,
                                      required = false, default = nil)
  if valid_402657428 != nil:
    section.add "X-Amz-Signature", valid_402657428
  var valid_402657429 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657429 = validateParameter(valid_402657429, JString,
                                      required = false, default = nil)
  if valid_402657429 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657429
  var valid_402657430 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657430 = validateParameter(valid_402657430, JString,
                                      required = false, default = nil)
  if valid_402657430 != nil:
    section.add "X-Amz-Algorithm", valid_402657430
  var valid_402657431 = header.getOrDefault("X-Amz-Date")
  valid_402657431 = validateParameter(valid_402657431, JString,
                                      required = false, default = nil)
  if valid_402657431 != nil:
    section.add "X-Amz-Date", valid_402657431
  var valid_402657432 = header.getOrDefault("X-Amz-Credential")
  valid_402657432 = validateParameter(valid_402657432, JString,
                                      required = false, default = nil)
  if valid_402657432 != nil:
    section.add "X-Amz-Credential", valid_402657432
  var valid_402657433 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657433 = validateParameter(valid_402657433, JString,
                                      required = false, default = nil)
  if valid_402657433 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657433
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

proc call*(call_402657435: Call_TestRepositoryTriggers_402657423;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Tests the functionality of repository triggers by sending information to the trigger target. If real data is available in the repository, the test sends data from the last commit. If no data is available, sample data is generated.
                                                                                         ## 
  let valid = call_402657435.validator(path, query, header, formData, body, _)
  let scheme = call_402657435.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657435.makeUrl(scheme.get, call_402657435.host, call_402657435.base,
                                   call_402657435.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657435, uri, valid, _)

proc call*(call_402657436: Call_TestRepositoryTriggers_402657423; body: JsonNode): Recallable =
  ## testRepositoryTriggers
  ## Tests the functionality of repository triggers by sending information to the trigger target. If real data is available in the repository, the test sends data from the last commit. If no data is available, sample data is generated.
  ##   
                                                                                                                                                                                                                                           ## body: JObject (required)
  var body_402657437 = newJObject()
  if body != nil:
    body_402657437 = body
  result = call_402657436.call(nil, nil, nil, nil, body_402657437)

var testRepositoryTriggers* = Call_TestRepositoryTriggers_402657423(
    name: "testRepositoryTriggers", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.TestRepositoryTriggers",
    validator: validate_TestRepositoryTriggers_402657424, base: "/",
    makeUrl: url_TestRepositoryTriggers_402657425,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_402657438 = ref object of OpenApiRestCall_402656044
proc url_UntagResource_402657440(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UntagResource_402657439(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Removes tags for a resource in AWS CodeCommit. For a list of valid resources in AWS CodeCommit, see <a href="https://docs.aws.amazon.com/codecommit/latest/userguide/auth-and-access-control-iam-access-control-identity-based.html#arn-formats">CodeCommit Resources and Operations</a> in the <i>AWS CodeCommit User Guide</i>.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657441 = header.getOrDefault("X-Amz-Target")
  valid_402657441 = validateParameter(valid_402657441, JString, required = true, default = newJString(
      "CodeCommit_20150413.UntagResource"))
  if valid_402657441 != nil:
    section.add "X-Amz-Target", valid_402657441
  var valid_402657442 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657442 = validateParameter(valid_402657442, JString,
                                      required = false, default = nil)
  if valid_402657442 != nil:
    section.add "X-Amz-Security-Token", valid_402657442
  var valid_402657443 = header.getOrDefault("X-Amz-Signature")
  valid_402657443 = validateParameter(valid_402657443, JString,
                                      required = false, default = nil)
  if valid_402657443 != nil:
    section.add "X-Amz-Signature", valid_402657443
  var valid_402657444 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657444 = validateParameter(valid_402657444, JString,
                                      required = false, default = nil)
  if valid_402657444 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657444
  var valid_402657445 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657445 = validateParameter(valid_402657445, JString,
                                      required = false, default = nil)
  if valid_402657445 != nil:
    section.add "X-Amz-Algorithm", valid_402657445
  var valid_402657446 = header.getOrDefault("X-Amz-Date")
  valid_402657446 = validateParameter(valid_402657446, JString,
                                      required = false, default = nil)
  if valid_402657446 != nil:
    section.add "X-Amz-Date", valid_402657446
  var valid_402657447 = header.getOrDefault("X-Amz-Credential")
  valid_402657447 = validateParameter(valid_402657447, JString,
                                      required = false, default = nil)
  if valid_402657447 != nil:
    section.add "X-Amz-Credential", valid_402657447
  var valid_402657448 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657448 = validateParameter(valid_402657448, JString,
                                      required = false, default = nil)
  if valid_402657448 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657448
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

proc call*(call_402657450: Call_UntagResource_402657438; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Removes tags for a resource in AWS CodeCommit. For a list of valid resources in AWS CodeCommit, see <a href="https://docs.aws.amazon.com/codecommit/latest/userguide/auth-and-access-control-iam-access-control-identity-based.html#arn-formats">CodeCommit Resources and Operations</a> in the <i>AWS CodeCommit User Guide</i>.
                                                                                         ## 
  let valid = call_402657450.validator(path, query, header, formData, body, _)
  let scheme = call_402657450.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657450.makeUrl(scheme.get, call_402657450.host, call_402657450.base,
                                   call_402657450.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657450, uri, valid, _)

proc call*(call_402657451: Call_UntagResource_402657438; body: JsonNode): Recallable =
  ## untagResource
  ## Removes tags for a resource in AWS CodeCommit. For a list of valid resources in AWS CodeCommit, see <a href="https://docs.aws.amazon.com/codecommit/latest/userguide/auth-and-access-control-iam-access-control-identity-based.html#arn-formats">CodeCommit Resources and Operations</a> in the <i>AWS CodeCommit User Guide</i>.
  ##   
                                                                                                                                                                                                                                                                                                                                      ## body: JObject (required)
  var body_402657452 = newJObject()
  if body != nil:
    body_402657452 = body
  result = call_402657451.call(nil, nil, nil, nil, body_402657452)

var untagResource* = Call_UntagResource_402657438(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.UntagResource",
    validator: validate_UntagResource_402657439, base: "/",
    makeUrl: url_UntagResource_402657440, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateApprovalRuleTemplateContent_402657453 = ref object of OpenApiRestCall_402656044
proc url_UpdateApprovalRuleTemplateContent_402657455(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateApprovalRuleTemplateContent_402657454(path: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657456 = header.getOrDefault("X-Amz-Target")
  valid_402657456 = validateParameter(valid_402657456, JString, required = true, default = newJString(
      "CodeCommit_20150413.UpdateApprovalRuleTemplateContent"))
  if valid_402657456 != nil:
    section.add "X-Amz-Target", valid_402657456
  var valid_402657457 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657457 = validateParameter(valid_402657457, JString,
                                      required = false, default = nil)
  if valid_402657457 != nil:
    section.add "X-Amz-Security-Token", valid_402657457
  var valid_402657458 = header.getOrDefault("X-Amz-Signature")
  valid_402657458 = validateParameter(valid_402657458, JString,
                                      required = false, default = nil)
  if valid_402657458 != nil:
    section.add "X-Amz-Signature", valid_402657458
  var valid_402657459 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657459 = validateParameter(valid_402657459, JString,
                                      required = false, default = nil)
  if valid_402657459 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657459
  var valid_402657460 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657460 = validateParameter(valid_402657460, JString,
                                      required = false, default = nil)
  if valid_402657460 != nil:
    section.add "X-Amz-Algorithm", valid_402657460
  var valid_402657461 = header.getOrDefault("X-Amz-Date")
  valid_402657461 = validateParameter(valid_402657461, JString,
                                      required = false, default = nil)
  if valid_402657461 != nil:
    section.add "X-Amz-Date", valid_402657461
  var valid_402657462 = header.getOrDefault("X-Amz-Credential")
  valid_402657462 = validateParameter(valid_402657462, JString,
                                      required = false, default = nil)
  if valid_402657462 != nil:
    section.add "X-Amz-Credential", valid_402657462
  var valid_402657463 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657463 = validateParameter(valid_402657463, JString,
                                      required = false, default = nil)
  if valid_402657463 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657463
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

proc call*(call_402657465: Call_UpdateApprovalRuleTemplateContent_402657453;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates the content of an approval rule template. You can change the number of required approvals, the membership of the approval rule, and whether an approval pool is defined.
                                                                                         ## 
  let valid = call_402657465.validator(path, query, header, formData, body, _)
  let scheme = call_402657465.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657465.makeUrl(scheme.get, call_402657465.host, call_402657465.base,
                                   call_402657465.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657465, uri, valid, _)

proc call*(call_402657466: Call_UpdateApprovalRuleTemplateContent_402657453;
           body: JsonNode): Recallable =
  ## updateApprovalRuleTemplateContent
  ## Updates the content of an approval rule template. You can change the number of required approvals, the membership of the approval rule, and whether an approval pool is defined.
  ##   
                                                                                                                                                                                     ## body: JObject (required)
  var body_402657467 = newJObject()
  if body != nil:
    body_402657467 = body
  result = call_402657466.call(nil, nil, nil, nil, body_402657467)

var updateApprovalRuleTemplateContent* = Call_UpdateApprovalRuleTemplateContent_402657453(
    name: "updateApprovalRuleTemplateContent", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com", route: "/#X-Amz-Target=CodeCommit_20150413.UpdateApprovalRuleTemplateContent",
    validator: validate_UpdateApprovalRuleTemplateContent_402657454, base: "/",
    makeUrl: url_UpdateApprovalRuleTemplateContent_402657455,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateApprovalRuleTemplateDescription_402657468 = ref object of OpenApiRestCall_402656044
proc url_UpdateApprovalRuleTemplateDescription_402657470(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateApprovalRuleTemplateDescription_402657469(path: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657471 = header.getOrDefault("X-Amz-Target")
  valid_402657471 = validateParameter(valid_402657471, JString, required = true, default = newJString(
      "CodeCommit_20150413.UpdateApprovalRuleTemplateDescription"))
  if valid_402657471 != nil:
    section.add "X-Amz-Target", valid_402657471
  var valid_402657472 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657472 = validateParameter(valid_402657472, JString,
                                      required = false, default = nil)
  if valid_402657472 != nil:
    section.add "X-Amz-Security-Token", valid_402657472
  var valid_402657473 = header.getOrDefault("X-Amz-Signature")
  valid_402657473 = validateParameter(valid_402657473, JString,
                                      required = false, default = nil)
  if valid_402657473 != nil:
    section.add "X-Amz-Signature", valid_402657473
  var valid_402657474 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657474 = validateParameter(valid_402657474, JString,
                                      required = false, default = nil)
  if valid_402657474 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657474
  var valid_402657475 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657475 = validateParameter(valid_402657475, JString,
                                      required = false, default = nil)
  if valid_402657475 != nil:
    section.add "X-Amz-Algorithm", valid_402657475
  var valid_402657476 = header.getOrDefault("X-Amz-Date")
  valid_402657476 = validateParameter(valid_402657476, JString,
                                      required = false, default = nil)
  if valid_402657476 != nil:
    section.add "X-Amz-Date", valid_402657476
  var valid_402657477 = header.getOrDefault("X-Amz-Credential")
  valid_402657477 = validateParameter(valid_402657477, JString,
                                      required = false, default = nil)
  if valid_402657477 != nil:
    section.add "X-Amz-Credential", valid_402657477
  var valid_402657478 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657478 = validateParameter(valid_402657478, JString,
                                      required = false, default = nil)
  if valid_402657478 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657478
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

proc call*(call_402657480: Call_UpdateApprovalRuleTemplateDescription_402657468;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates the description for a specified approval rule template.
                                                                                         ## 
  let valid = call_402657480.validator(path, query, header, formData, body, _)
  let scheme = call_402657480.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657480.makeUrl(scheme.get, call_402657480.host, call_402657480.base,
                                   call_402657480.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657480, uri, valid, _)

proc call*(call_402657481: Call_UpdateApprovalRuleTemplateDescription_402657468;
           body: JsonNode): Recallable =
  ## updateApprovalRuleTemplateDescription
  ## Updates the description for a specified approval rule template.
  ##   body: JObject (required)
  var body_402657482 = newJObject()
  if body != nil:
    body_402657482 = body
  result = call_402657481.call(nil, nil, nil, nil, body_402657482)

var updateApprovalRuleTemplateDescription* = Call_UpdateApprovalRuleTemplateDescription_402657468(
    name: "updateApprovalRuleTemplateDescription", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com", route: "/#X-Amz-Target=CodeCommit_20150413.UpdateApprovalRuleTemplateDescription",
    validator: validate_UpdateApprovalRuleTemplateDescription_402657469,
    base: "/", makeUrl: url_UpdateApprovalRuleTemplateDescription_402657470,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateApprovalRuleTemplateName_402657483 = ref object of OpenApiRestCall_402656044
proc url_UpdateApprovalRuleTemplateName_402657485(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateApprovalRuleTemplateName_402657484(path: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657486 = header.getOrDefault("X-Amz-Target")
  valid_402657486 = validateParameter(valid_402657486, JString, required = true, default = newJString(
      "CodeCommit_20150413.UpdateApprovalRuleTemplateName"))
  if valid_402657486 != nil:
    section.add "X-Amz-Target", valid_402657486
  var valid_402657487 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657487 = validateParameter(valid_402657487, JString,
                                      required = false, default = nil)
  if valid_402657487 != nil:
    section.add "X-Amz-Security-Token", valid_402657487
  var valid_402657488 = header.getOrDefault("X-Amz-Signature")
  valid_402657488 = validateParameter(valid_402657488, JString,
                                      required = false, default = nil)
  if valid_402657488 != nil:
    section.add "X-Amz-Signature", valid_402657488
  var valid_402657489 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657489 = validateParameter(valid_402657489, JString,
                                      required = false, default = nil)
  if valid_402657489 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657489
  var valid_402657490 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657490 = validateParameter(valid_402657490, JString,
                                      required = false, default = nil)
  if valid_402657490 != nil:
    section.add "X-Amz-Algorithm", valid_402657490
  var valid_402657491 = header.getOrDefault("X-Amz-Date")
  valid_402657491 = validateParameter(valid_402657491, JString,
                                      required = false, default = nil)
  if valid_402657491 != nil:
    section.add "X-Amz-Date", valid_402657491
  var valid_402657492 = header.getOrDefault("X-Amz-Credential")
  valid_402657492 = validateParameter(valid_402657492, JString,
                                      required = false, default = nil)
  if valid_402657492 != nil:
    section.add "X-Amz-Credential", valid_402657492
  var valid_402657493 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657493 = validateParameter(valid_402657493, JString,
                                      required = false, default = nil)
  if valid_402657493 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657493
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

proc call*(call_402657495: Call_UpdateApprovalRuleTemplateName_402657483;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates the name of a specified approval rule template.
                                                                                         ## 
  let valid = call_402657495.validator(path, query, header, formData, body, _)
  let scheme = call_402657495.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657495.makeUrl(scheme.get, call_402657495.host, call_402657495.base,
                                   call_402657495.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657495, uri, valid, _)

proc call*(call_402657496: Call_UpdateApprovalRuleTemplateName_402657483;
           body: JsonNode): Recallable =
  ## updateApprovalRuleTemplateName
  ## Updates the name of a specified approval rule template.
  ##   body: JObject (required)
  var body_402657497 = newJObject()
  if body != nil:
    body_402657497 = body
  result = call_402657496.call(nil, nil, nil, nil, body_402657497)

var updateApprovalRuleTemplateName* = Call_UpdateApprovalRuleTemplateName_402657483(
    name: "updateApprovalRuleTemplateName", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.UpdateApprovalRuleTemplateName",
    validator: validate_UpdateApprovalRuleTemplateName_402657484, base: "/",
    makeUrl: url_UpdateApprovalRuleTemplateName_402657485,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateComment_402657498 = ref object of OpenApiRestCall_402656044
proc url_UpdateComment_402657500(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateComment_402657499(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Replaces the contents of a comment.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657501 = header.getOrDefault("X-Amz-Target")
  valid_402657501 = validateParameter(valid_402657501, JString, required = true, default = newJString(
      "CodeCommit_20150413.UpdateComment"))
  if valid_402657501 != nil:
    section.add "X-Amz-Target", valid_402657501
  var valid_402657502 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657502 = validateParameter(valid_402657502, JString,
                                      required = false, default = nil)
  if valid_402657502 != nil:
    section.add "X-Amz-Security-Token", valid_402657502
  var valid_402657503 = header.getOrDefault("X-Amz-Signature")
  valid_402657503 = validateParameter(valid_402657503, JString,
                                      required = false, default = nil)
  if valid_402657503 != nil:
    section.add "X-Amz-Signature", valid_402657503
  var valid_402657504 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657504 = validateParameter(valid_402657504, JString,
                                      required = false, default = nil)
  if valid_402657504 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657504
  var valid_402657505 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657505 = validateParameter(valid_402657505, JString,
                                      required = false, default = nil)
  if valid_402657505 != nil:
    section.add "X-Amz-Algorithm", valid_402657505
  var valid_402657506 = header.getOrDefault("X-Amz-Date")
  valid_402657506 = validateParameter(valid_402657506, JString,
                                      required = false, default = nil)
  if valid_402657506 != nil:
    section.add "X-Amz-Date", valid_402657506
  var valid_402657507 = header.getOrDefault("X-Amz-Credential")
  valid_402657507 = validateParameter(valid_402657507, JString,
                                      required = false, default = nil)
  if valid_402657507 != nil:
    section.add "X-Amz-Credential", valid_402657507
  var valid_402657508 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657508 = validateParameter(valid_402657508, JString,
                                      required = false, default = nil)
  if valid_402657508 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657508
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

proc call*(call_402657510: Call_UpdateComment_402657498; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Replaces the contents of a comment.
                                                                                         ## 
  let valid = call_402657510.validator(path, query, header, formData, body, _)
  let scheme = call_402657510.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657510.makeUrl(scheme.get, call_402657510.host, call_402657510.base,
                                   call_402657510.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657510, uri, valid, _)

proc call*(call_402657511: Call_UpdateComment_402657498; body: JsonNode): Recallable =
  ## updateComment
  ## Replaces the contents of a comment.
  ##   body: JObject (required)
  var body_402657512 = newJObject()
  if body != nil:
    body_402657512 = body
  result = call_402657511.call(nil, nil, nil, nil, body_402657512)

var updateComment* = Call_UpdateComment_402657498(name: "updateComment",
    meth: HttpMethod.HttpPost, host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.UpdateComment",
    validator: validate_UpdateComment_402657499, base: "/",
    makeUrl: url_UpdateComment_402657500, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDefaultBranch_402657513 = ref object of OpenApiRestCall_402656044
proc url_UpdateDefaultBranch_402657515(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateDefaultBranch_402657514(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657516 = header.getOrDefault("X-Amz-Target")
  valid_402657516 = validateParameter(valid_402657516, JString, required = true, default = newJString(
      "CodeCommit_20150413.UpdateDefaultBranch"))
  if valid_402657516 != nil:
    section.add "X-Amz-Target", valid_402657516
  var valid_402657517 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657517 = validateParameter(valid_402657517, JString,
                                      required = false, default = nil)
  if valid_402657517 != nil:
    section.add "X-Amz-Security-Token", valid_402657517
  var valid_402657518 = header.getOrDefault("X-Amz-Signature")
  valid_402657518 = validateParameter(valid_402657518, JString,
                                      required = false, default = nil)
  if valid_402657518 != nil:
    section.add "X-Amz-Signature", valid_402657518
  var valid_402657519 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657519 = validateParameter(valid_402657519, JString,
                                      required = false, default = nil)
  if valid_402657519 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657519
  var valid_402657520 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657520 = validateParameter(valid_402657520, JString,
                                      required = false, default = nil)
  if valid_402657520 != nil:
    section.add "X-Amz-Algorithm", valid_402657520
  var valid_402657521 = header.getOrDefault("X-Amz-Date")
  valid_402657521 = validateParameter(valid_402657521, JString,
                                      required = false, default = nil)
  if valid_402657521 != nil:
    section.add "X-Amz-Date", valid_402657521
  var valid_402657522 = header.getOrDefault("X-Amz-Credential")
  valid_402657522 = validateParameter(valid_402657522, JString,
                                      required = false, default = nil)
  if valid_402657522 != nil:
    section.add "X-Amz-Credential", valid_402657522
  var valid_402657523 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657523 = validateParameter(valid_402657523, JString,
                                      required = false, default = nil)
  if valid_402657523 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657523
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

proc call*(call_402657525: Call_UpdateDefaultBranch_402657513;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Sets or changes the default branch name for the specified repository.</p> <note> <p>If you use this operation to change the default branch name to the current default branch name, a success message is returned even though the default branch did not change.</p> </note>
                                                                                         ## 
  let valid = call_402657525.validator(path, query, header, formData, body, _)
  let scheme = call_402657525.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657525.makeUrl(scheme.get, call_402657525.host, call_402657525.base,
                                   call_402657525.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657525, uri, valid, _)

proc call*(call_402657526: Call_UpdateDefaultBranch_402657513; body: JsonNode): Recallable =
  ## updateDefaultBranch
  ## <p>Sets or changes the default branch name for the specified repository.</p> <note> <p>If you use this operation to change the default branch name to the current default branch name, a success message is returned even though the default branch did not change.</p> </note>
  ##   
                                                                                                                                                                                                                                                                                    ## body: JObject (required)
  var body_402657527 = newJObject()
  if body != nil:
    body_402657527 = body
  result = call_402657526.call(nil, nil, nil, nil, body_402657527)

var updateDefaultBranch* = Call_UpdateDefaultBranch_402657513(
    name: "updateDefaultBranch", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.UpdateDefaultBranch",
    validator: validate_UpdateDefaultBranch_402657514, base: "/",
    makeUrl: url_UpdateDefaultBranch_402657515,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdatePullRequestApprovalRuleContent_402657528 = ref object of OpenApiRestCall_402656044
proc url_UpdatePullRequestApprovalRuleContent_402657530(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdatePullRequestApprovalRuleContent_402657529(path: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657531 = header.getOrDefault("X-Amz-Target")
  valid_402657531 = validateParameter(valid_402657531, JString, required = true, default = newJString(
      "CodeCommit_20150413.UpdatePullRequestApprovalRuleContent"))
  if valid_402657531 != nil:
    section.add "X-Amz-Target", valid_402657531
  var valid_402657532 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657532 = validateParameter(valid_402657532, JString,
                                      required = false, default = nil)
  if valid_402657532 != nil:
    section.add "X-Amz-Security-Token", valid_402657532
  var valid_402657533 = header.getOrDefault("X-Amz-Signature")
  valid_402657533 = validateParameter(valid_402657533, JString,
                                      required = false, default = nil)
  if valid_402657533 != nil:
    section.add "X-Amz-Signature", valid_402657533
  var valid_402657534 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657534 = validateParameter(valid_402657534, JString,
                                      required = false, default = nil)
  if valid_402657534 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657534
  var valid_402657535 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657535 = validateParameter(valid_402657535, JString,
                                      required = false, default = nil)
  if valid_402657535 != nil:
    section.add "X-Amz-Algorithm", valid_402657535
  var valid_402657536 = header.getOrDefault("X-Amz-Date")
  valid_402657536 = validateParameter(valid_402657536, JString,
                                      required = false, default = nil)
  if valid_402657536 != nil:
    section.add "X-Amz-Date", valid_402657536
  var valid_402657537 = header.getOrDefault("X-Amz-Credential")
  valid_402657537 = validateParameter(valid_402657537, JString,
                                      required = false, default = nil)
  if valid_402657537 != nil:
    section.add "X-Amz-Credential", valid_402657537
  var valid_402657538 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657538 = validateParameter(valid_402657538, JString,
                                      required = false, default = nil)
  if valid_402657538 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657538
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

proc call*(call_402657540: Call_UpdatePullRequestApprovalRuleContent_402657528;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates the structure of an approval rule created specifically for a pull request. For example, you can change the number of required approvers and the approval pool for approvers. 
                                                                                         ## 
  let valid = call_402657540.validator(path, query, header, formData, body, _)
  let scheme = call_402657540.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657540.makeUrl(scheme.get, call_402657540.host, call_402657540.base,
                                   call_402657540.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657540, uri, valid, _)

proc call*(call_402657541: Call_UpdatePullRequestApprovalRuleContent_402657528;
           body: JsonNode): Recallable =
  ## updatePullRequestApprovalRuleContent
  ## Updates the structure of an approval rule created specifically for a pull request. For example, you can change the number of required approvers and the approval pool for approvers. 
  ##   
                                                                                                                                                                                          ## body: JObject (required)
  var body_402657542 = newJObject()
  if body != nil:
    body_402657542 = body
  result = call_402657541.call(nil, nil, nil, nil, body_402657542)

var updatePullRequestApprovalRuleContent* = Call_UpdatePullRequestApprovalRuleContent_402657528(
    name: "updatePullRequestApprovalRuleContent", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com", route: "/#X-Amz-Target=CodeCommit_20150413.UpdatePullRequestApprovalRuleContent",
    validator: validate_UpdatePullRequestApprovalRuleContent_402657529,
    base: "/", makeUrl: url_UpdatePullRequestApprovalRuleContent_402657530,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdatePullRequestApprovalState_402657543 = ref object of OpenApiRestCall_402656044
proc url_UpdatePullRequestApprovalState_402657545(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdatePullRequestApprovalState_402657544(path: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657546 = header.getOrDefault("X-Amz-Target")
  valid_402657546 = validateParameter(valid_402657546, JString, required = true, default = newJString(
      "CodeCommit_20150413.UpdatePullRequestApprovalState"))
  if valid_402657546 != nil:
    section.add "X-Amz-Target", valid_402657546
  var valid_402657547 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657547 = validateParameter(valid_402657547, JString,
                                      required = false, default = nil)
  if valid_402657547 != nil:
    section.add "X-Amz-Security-Token", valid_402657547
  var valid_402657548 = header.getOrDefault("X-Amz-Signature")
  valid_402657548 = validateParameter(valid_402657548, JString,
                                      required = false, default = nil)
  if valid_402657548 != nil:
    section.add "X-Amz-Signature", valid_402657548
  var valid_402657549 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657549 = validateParameter(valid_402657549, JString,
                                      required = false, default = nil)
  if valid_402657549 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657549
  var valid_402657550 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657550 = validateParameter(valid_402657550, JString,
                                      required = false, default = nil)
  if valid_402657550 != nil:
    section.add "X-Amz-Algorithm", valid_402657550
  var valid_402657551 = header.getOrDefault("X-Amz-Date")
  valid_402657551 = validateParameter(valid_402657551, JString,
                                      required = false, default = nil)
  if valid_402657551 != nil:
    section.add "X-Amz-Date", valid_402657551
  var valid_402657552 = header.getOrDefault("X-Amz-Credential")
  valid_402657552 = validateParameter(valid_402657552, JString,
                                      required = false, default = nil)
  if valid_402657552 != nil:
    section.add "X-Amz-Credential", valid_402657552
  var valid_402657553 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657553 = validateParameter(valid_402657553, JString,
                                      required = false, default = nil)
  if valid_402657553 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657553
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

proc call*(call_402657555: Call_UpdatePullRequestApprovalState_402657543;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates the state of a user's approval on a pull request. The user is derived from the signed-in account when the request is made.
                                                                                         ## 
  let valid = call_402657555.validator(path, query, header, formData, body, _)
  let scheme = call_402657555.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657555.makeUrl(scheme.get, call_402657555.host, call_402657555.base,
                                   call_402657555.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657555, uri, valid, _)

proc call*(call_402657556: Call_UpdatePullRequestApprovalState_402657543;
           body: JsonNode): Recallable =
  ## updatePullRequestApprovalState
  ## Updates the state of a user's approval on a pull request. The user is derived from the signed-in account when the request is made.
  ##   
                                                                                                                                       ## body: JObject (required)
  var body_402657557 = newJObject()
  if body != nil:
    body_402657557 = body
  result = call_402657556.call(nil, nil, nil, nil, body_402657557)

var updatePullRequestApprovalState* = Call_UpdatePullRequestApprovalState_402657543(
    name: "updatePullRequestApprovalState", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.UpdatePullRequestApprovalState",
    validator: validate_UpdatePullRequestApprovalState_402657544, base: "/",
    makeUrl: url_UpdatePullRequestApprovalState_402657545,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdatePullRequestDescription_402657558 = ref object of OpenApiRestCall_402656044
proc url_UpdatePullRequestDescription_402657560(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdatePullRequestDescription_402657559(path: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657561 = header.getOrDefault("X-Amz-Target")
  valid_402657561 = validateParameter(valid_402657561, JString, required = true, default = newJString(
      "CodeCommit_20150413.UpdatePullRequestDescription"))
  if valid_402657561 != nil:
    section.add "X-Amz-Target", valid_402657561
  var valid_402657562 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657562 = validateParameter(valid_402657562, JString,
                                      required = false, default = nil)
  if valid_402657562 != nil:
    section.add "X-Amz-Security-Token", valid_402657562
  var valid_402657563 = header.getOrDefault("X-Amz-Signature")
  valid_402657563 = validateParameter(valid_402657563, JString,
                                      required = false, default = nil)
  if valid_402657563 != nil:
    section.add "X-Amz-Signature", valid_402657563
  var valid_402657564 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657564 = validateParameter(valid_402657564, JString,
                                      required = false, default = nil)
  if valid_402657564 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657564
  var valid_402657565 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657565 = validateParameter(valid_402657565, JString,
                                      required = false, default = nil)
  if valid_402657565 != nil:
    section.add "X-Amz-Algorithm", valid_402657565
  var valid_402657566 = header.getOrDefault("X-Amz-Date")
  valid_402657566 = validateParameter(valid_402657566, JString,
                                      required = false, default = nil)
  if valid_402657566 != nil:
    section.add "X-Amz-Date", valid_402657566
  var valid_402657567 = header.getOrDefault("X-Amz-Credential")
  valid_402657567 = validateParameter(valid_402657567, JString,
                                      required = false, default = nil)
  if valid_402657567 != nil:
    section.add "X-Amz-Credential", valid_402657567
  var valid_402657568 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657568 = validateParameter(valid_402657568, JString,
                                      required = false, default = nil)
  if valid_402657568 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657568
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

proc call*(call_402657570: Call_UpdatePullRequestDescription_402657558;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Replaces the contents of the description of a pull request.
                                                                                         ## 
  let valid = call_402657570.validator(path, query, header, formData, body, _)
  let scheme = call_402657570.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657570.makeUrl(scheme.get, call_402657570.host, call_402657570.base,
                                   call_402657570.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657570, uri, valid, _)

proc call*(call_402657571: Call_UpdatePullRequestDescription_402657558;
           body: JsonNode): Recallable =
  ## updatePullRequestDescription
  ## Replaces the contents of the description of a pull request.
  ##   body: JObject (required)
  var body_402657572 = newJObject()
  if body != nil:
    body_402657572 = body
  result = call_402657571.call(nil, nil, nil, nil, body_402657572)

var updatePullRequestDescription* = Call_UpdatePullRequestDescription_402657558(
    name: "updatePullRequestDescription", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.UpdatePullRequestDescription",
    validator: validate_UpdatePullRequestDescription_402657559, base: "/",
    makeUrl: url_UpdatePullRequestDescription_402657560,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdatePullRequestStatus_402657573 = ref object of OpenApiRestCall_402656044
proc url_UpdatePullRequestStatus_402657575(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdatePullRequestStatus_402657574(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657576 = header.getOrDefault("X-Amz-Target")
  valid_402657576 = validateParameter(valid_402657576, JString, required = true, default = newJString(
      "CodeCommit_20150413.UpdatePullRequestStatus"))
  if valid_402657576 != nil:
    section.add "X-Amz-Target", valid_402657576
  var valid_402657577 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657577 = validateParameter(valid_402657577, JString,
                                      required = false, default = nil)
  if valid_402657577 != nil:
    section.add "X-Amz-Security-Token", valid_402657577
  var valid_402657578 = header.getOrDefault("X-Amz-Signature")
  valid_402657578 = validateParameter(valid_402657578, JString,
                                      required = false, default = nil)
  if valid_402657578 != nil:
    section.add "X-Amz-Signature", valid_402657578
  var valid_402657579 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657579 = validateParameter(valid_402657579, JString,
                                      required = false, default = nil)
  if valid_402657579 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657579
  var valid_402657580 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657580 = validateParameter(valid_402657580, JString,
                                      required = false, default = nil)
  if valid_402657580 != nil:
    section.add "X-Amz-Algorithm", valid_402657580
  var valid_402657581 = header.getOrDefault("X-Amz-Date")
  valid_402657581 = validateParameter(valid_402657581, JString,
                                      required = false, default = nil)
  if valid_402657581 != nil:
    section.add "X-Amz-Date", valid_402657581
  var valid_402657582 = header.getOrDefault("X-Amz-Credential")
  valid_402657582 = validateParameter(valid_402657582, JString,
                                      required = false, default = nil)
  if valid_402657582 != nil:
    section.add "X-Amz-Credential", valid_402657582
  var valid_402657583 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657583 = validateParameter(valid_402657583, JString,
                                      required = false, default = nil)
  if valid_402657583 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657583
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

proc call*(call_402657585: Call_UpdatePullRequestStatus_402657573;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates the status of a pull request. 
                                                                                         ## 
  let valid = call_402657585.validator(path, query, header, formData, body, _)
  let scheme = call_402657585.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657585.makeUrl(scheme.get, call_402657585.host, call_402657585.base,
                                   call_402657585.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657585, uri, valid, _)

proc call*(call_402657586: Call_UpdatePullRequestStatus_402657573;
           body: JsonNode): Recallable =
  ## updatePullRequestStatus
  ## Updates the status of a pull request. 
  ##   body: JObject (required)
  var body_402657587 = newJObject()
  if body != nil:
    body_402657587 = body
  result = call_402657586.call(nil, nil, nil, nil, body_402657587)

var updatePullRequestStatus* = Call_UpdatePullRequestStatus_402657573(
    name: "updatePullRequestStatus", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.UpdatePullRequestStatus",
    validator: validate_UpdatePullRequestStatus_402657574, base: "/",
    makeUrl: url_UpdatePullRequestStatus_402657575,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdatePullRequestTitle_402657588 = ref object of OpenApiRestCall_402656044
proc url_UpdatePullRequestTitle_402657590(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdatePullRequestTitle_402657589(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657591 = header.getOrDefault("X-Amz-Target")
  valid_402657591 = validateParameter(valid_402657591, JString, required = true, default = newJString(
      "CodeCommit_20150413.UpdatePullRequestTitle"))
  if valid_402657591 != nil:
    section.add "X-Amz-Target", valid_402657591
  var valid_402657592 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657592 = validateParameter(valid_402657592, JString,
                                      required = false, default = nil)
  if valid_402657592 != nil:
    section.add "X-Amz-Security-Token", valid_402657592
  var valid_402657593 = header.getOrDefault("X-Amz-Signature")
  valid_402657593 = validateParameter(valid_402657593, JString,
                                      required = false, default = nil)
  if valid_402657593 != nil:
    section.add "X-Amz-Signature", valid_402657593
  var valid_402657594 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657594 = validateParameter(valid_402657594, JString,
                                      required = false, default = nil)
  if valid_402657594 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657594
  var valid_402657595 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657595 = validateParameter(valid_402657595, JString,
                                      required = false, default = nil)
  if valid_402657595 != nil:
    section.add "X-Amz-Algorithm", valid_402657595
  var valid_402657596 = header.getOrDefault("X-Amz-Date")
  valid_402657596 = validateParameter(valid_402657596, JString,
                                      required = false, default = nil)
  if valid_402657596 != nil:
    section.add "X-Amz-Date", valid_402657596
  var valid_402657597 = header.getOrDefault("X-Amz-Credential")
  valid_402657597 = validateParameter(valid_402657597, JString,
                                      required = false, default = nil)
  if valid_402657597 != nil:
    section.add "X-Amz-Credential", valid_402657597
  var valid_402657598 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657598 = validateParameter(valid_402657598, JString,
                                      required = false, default = nil)
  if valid_402657598 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657598
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

proc call*(call_402657600: Call_UpdatePullRequestTitle_402657588;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Replaces the title of a pull request.
                                                                                         ## 
  let valid = call_402657600.validator(path, query, header, formData, body, _)
  let scheme = call_402657600.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657600.makeUrl(scheme.get, call_402657600.host, call_402657600.base,
                                   call_402657600.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657600, uri, valid, _)

proc call*(call_402657601: Call_UpdatePullRequestTitle_402657588; body: JsonNode): Recallable =
  ## updatePullRequestTitle
  ## Replaces the title of a pull request.
  ##   body: JObject (required)
  var body_402657602 = newJObject()
  if body != nil:
    body_402657602 = body
  result = call_402657601.call(nil, nil, nil, nil, body_402657602)

var updatePullRequestTitle* = Call_UpdatePullRequestTitle_402657588(
    name: "updatePullRequestTitle", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.UpdatePullRequestTitle",
    validator: validate_UpdatePullRequestTitle_402657589, base: "/",
    makeUrl: url_UpdatePullRequestTitle_402657590,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateRepositoryDescription_402657603 = ref object of OpenApiRestCall_402656044
proc url_UpdateRepositoryDescription_402657605(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateRepositoryDescription_402657604(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## <p>Sets or changes the comment or description for a repository.</p> <note> <p>The description field for a repository accepts all HTML characters and all valid Unicode characters. Applications that do not HTML-encode the description and display it in a webpage can expose users to potentially malicious code. Make sure that you HTML-encode the description field in any application that uses this API to display the repository description on a webpage.</p> </note>
                                            ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657606 = header.getOrDefault("X-Amz-Target")
  valid_402657606 = validateParameter(valid_402657606, JString, required = true, default = newJString(
      "CodeCommit_20150413.UpdateRepositoryDescription"))
  if valid_402657606 != nil:
    section.add "X-Amz-Target", valid_402657606
  var valid_402657607 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657607 = validateParameter(valid_402657607, JString,
                                      required = false, default = nil)
  if valid_402657607 != nil:
    section.add "X-Amz-Security-Token", valid_402657607
  var valid_402657608 = header.getOrDefault("X-Amz-Signature")
  valid_402657608 = validateParameter(valid_402657608, JString,
                                      required = false, default = nil)
  if valid_402657608 != nil:
    section.add "X-Amz-Signature", valid_402657608
  var valid_402657609 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657609 = validateParameter(valid_402657609, JString,
                                      required = false, default = nil)
  if valid_402657609 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657609
  var valid_402657610 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657610 = validateParameter(valid_402657610, JString,
                                      required = false, default = nil)
  if valid_402657610 != nil:
    section.add "X-Amz-Algorithm", valid_402657610
  var valid_402657611 = header.getOrDefault("X-Amz-Date")
  valid_402657611 = validateParameter(valid_402657611, JString,
                                      required = false, default = nil)
  if valid_402657611 != nil:
    section.add "X-Amz-Date", valid_402657611
  var valid_402657612 = header.getOrDefault("X-Amz-Credential")
  valid_402657612 = validateParameter(valid_402657612, JString,
                                      required = false, default = nil)
  if valid_402657612 != nil:
    section.add "X-Amz-Credential", valid_402657612
  var valid_402657613 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657613 = validateParameter(valid_402657613, JString,
                                      required = false, default = nil)
  if valid_402657613 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657613
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

proc call*(call_402657615: Call_UpdateRepositoryDescription_402657603;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Sets or changes the comment or description for a repository.</p> <note> <p>The description field for a repository accepts all HTML characters and all valid Unicode characters. Applications that do not HTML-encode the description and display it in a webpage can expose users to potentially malicious code. Make sure that you HTML-encode the description field in any application that uses this API to display the repository description on a webpage.</p> </note>
                                                                                         ## 
  let valid = call_402657615.validator(path, query, header, formData, body, _)
  let scheme = call_402657615.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657615.makeUrl(scheme.get, call_402657615.host, call_402657615.base,
                                   call_402657615.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657615, uri, valid, _)

proc call*(call_402657616: Call_UpdateRepositoryDescription_402657603;
           body: JsonNode): Recallable =
  ## updateRepositoryDescription
  ## <p>Sets or changes the comment or description for a repository.</p> <note> <p>The description field for a repository accepts all HTML characters and all valid Unicode characters. Applications that do not HTML-encode the description and display it in a webpage can expose users to potentially malicious code. Make sure that you HTML-encode the description field in any application that uses this API to display the repository description on a webpage.</p> </note>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## body: JObject (required)
  var body_402657617 = newJObject()
  if body != nil:
    body_402657617 = body
  result = call_402657616.call(nil, nil, nil, nil, body_402657617)

var updateRepositoryDescription* = Call_UpdateRepositoryDescription_402657603(
    name: "updateRepositoryDescription", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.UpdateRepositoryDescription",
    validator: validate_UpdateRepositoryDescription_402657604, base: "/",
    makeUrl: url_UpdateRepositoryDescription_402657605,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateRepositoryName_402657618 = ref object of OpenApiRestCall_402656044
proc url_UpdateRepositoryName_402657620(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateRepositoryName_402657619(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657621 = header.getOrDefault("X-Amz-Target")
  valid_402657621 = validateParameter(valid_402657621, JString, required = true, default = newJString(
      "CodeCommit_20150413.UpdateRepositoryName"))
  if valid_402657621 != nil:
    section.add "X-Amz-Target", valid_402657621
  var valid_402657622 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657622 = validateParameter(valid_402657622, JString,
                                      required = false, default = nil)
  if valid_402657622 != nil:
    section.add "X-Amz-Security-Token", valid_402657622
  var valid_402657623 = header.getOrDefault("X-Amz-Signature")
  valid_402657623 = validateParameter(valid_402657623, JString,
                                      required = false, default = nil)
  if valid_402657623 != nil:
    section.add "X-Amz-Signature", valid_402657623
  var valid_402657624 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657624 = validateParameter(valid_402657624, JString,
                                      required = false, default = nil)
  if valid_402657624 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657624
  var valid_402657625 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657625 = validateParameter(valid_402657625, JString,
                                      required = false, default = nil)
  if valid_402657625 != nil:
    section.add "X-Amz-Algorithm", valid_402657625
  var valid_402657626 = header.getOrDefault("X-Amz-Date")
  valid_402657626 = validateParameter(valid_402657626, JString,
                                      required = false, default = nil)
  if valid_402657626 != nil:
    section.add "X-Amz-Date", valid_402657626
  var valid_402657627 = header.getOrDefault("X-Amz-Credential")
  valid_402657627 = validateParameter(valid_402657627, JString,
                                      required = false, default = nil)
  if valid_402657627 != nil:
    section.add "X-Amz-Credential", valid_402657627
  var valid_402657628 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657628 = validateParameter(valid_402657628, JString,
                                      required = false, default = nil)
  if valid_402657628 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657628
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

proc call*(call_402657630: Call_UpdateRepositoryName_402657618;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Renames a repository. The repository name must be unique across the calling AWS account. Repository names are limited to 100 alphanumeric, dash, and underscore characters, and cannot include certain characters. The suffix .git is prohibited. For more information about the limits on repository names, see <a href="https://docs.aws.amazon.com/codecommit/latest/userguide/limits.html">Limits</a> in the AWS CodeCommit User Guide.
                                                                                         ## 
  let valid = call_402657630.validator(path, query, header, formData, body, _)
  let scheme = call_402657630.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657630.makeUrl(scheme.get, call_402657630.host, call_402657630.base,
                                   call_402657630.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657630, uri, valid, _)

proc call*(call_402657631: Call_UpdateRepositoryName_402657618; body: JsonNode): Recallable =
  ## updateRepositoryName
  ## Renames a repository. The repository name must be unique across the calling AWS account. Repository names are limited to 100 alphanumeric, dash, and underscore characters, and cannot include certain characters. The suffix .git is prohibited. For more information about the limits on repository names, see <a href="https://docs.aws.amazon.com/codecommit/latest/userguide/limits.html">Limits</a> in the AWS CodeCommit User Guide.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                ## body: JObject (required)
  var body_402657632 = newJObject()
  if body != nil:
    body_402657632 = body
  result = call_402657631.call(nil, nil, nil, nil, body_402657632)

var updateRepositoryName* = Call_UpdateRepositoryName_402657618(
    name: "updateRepositoryName", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.UpdateRepositoryName",
    validator: validate_UpdateRepositoryName_402657619, base: "/",
    makeUrl: url_UpdateRepositoryName_402657620,
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
    SecurityToken = "X-Amz-Security-Token",
    ContentSha256 = "X-Amz-Content-Sha256"
proc atozSign(recall: var Recallable; query: JsonNode;
              algo: SigningAlgo = SHA256) =
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
    scope = credentialScope(region = region, service = awsServiceName,
                            date = date)
    request = canonicalRequest(recall.meth, $url, query, recall.headers,
                               recall.body, normalize = normal, digest = algo)
    sts = stringToSign(request.hash(algo), scope, date = date, digest = algo)
    signature = calculateSignature(secret = secret, date = date,
                                   region = region, service = awsServiceName,
                                   sts, digest = algo)
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