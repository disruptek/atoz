
import
  json, options, hashes, uri, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: Amazon Simple Systems Manager (SSM)
## version: 2014-11-06
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <fullname>AWS Systems Manager</fullname> <p>AWS Systems Manager is a collection of capabilities that helps you automate management tasks such as collecting system inventory, applying operating system (OS) patches, automating the creation of Amazon Machine Images (AMIs), and configuring operating systems (OSs) and applications at scale. Systems Manager lets you remotely and securely manage the configuration of your managed instances. A <i>managed instance</i> is any Amazon EC2 instance or on-premises machine in your hybrid environment that has been configured for Systems Manager.</p> <p>This reference is intended to be used with the <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/">AWS Systems Manager User Guide</a>.</p> <p>To get started, verify prerequisites and configure managed instances. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-setting-up.html">Setting Up AWS Systems Manager</a> in the <i>AWS Systems Manager User Guide</i>.</p> <p>For information about other API actions you can perform on Amazon EC2 instances, see the <a href="http://docs.aws.amazon.com/AWSEC2/latest/APIReference/">Amazon EC2 API Reference</a>. For information about how to use a Query API, see <a href="http://docs.aws.amazon.com/AWSEC2/latest/APIReference/making-api-requests.html">Making API Requests</a>. </p>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/ssm/
type
  Scheme {.pure.} = enum
    Https = "https", Http = "http", Wss = "wss", Ws = "ws"
  ValidatorSignature = proc (query: JsonNode = nil; body: JsonNode = nil;
                          header: JsonNode = nil; path: JsonNode = nil;
                          formData: JsonNode = nil): JsonNode
  OpenApiRestCall = ref object of RestCall
    validator*: ValidatorSignature
    route*: string
    base*: string
    host*: string
    schemes*: set[Scheme]
    url*: proc (protocol: Scheme; host: string; base: string; route: string;
              path: JsonNode; query: JsonNode): Uri

  OpenApiRestCall_602466 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_602466](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_602466): Option[Scheme] {.used.} =
  ## select a supported scheme from a set of candidates
  for scheme in Scheme.low ..
      Scheme.high:
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
  if js ==
      nil:
    if default != nil:
      return validateParameter(default, kind, required = required)
  result = js
  if result ==
      nil:
    assert not required, $kind & " expected; received nil"
    if required:
      result = newJNull()
  else:
    assert js.kind ==
        kind, $kind & " expected; received " &
        $js.kind

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
    if js.kind notin {JString, JInt, JFloat, JNull, JBool}:
      return
    head = $js
  var remainder = input.hydratePath(segments[1 ..^ 1])
  if remainder.isNone:
    return
  result = some(head & remainder.get)

const
  awsServers = {Scheme.Http: {"ap-northeast-1": "ssm.ap-northeast-1.amazonaws.com", "ap-southeast-1": "ssm.ap-southeast-1.amazonaws.com",
                           "us-west-2": "ssm.us-west-2.amazonaws.com",
                           "eu-west-2": "ssm.eu-west-2.amazonaws.com", "ap-northeast-3": "ssm.ap-northeast-3.amazonaws.com",
                           "eu-central-1": "ssm.eu-central-1.amazonaws.com",
                           "us-east-2": "ssm.us-east-2.amazonaws.com",
                           "us-east-1": "ssm.us-east-1.amazonaws.com", "cn-northwest-1": "ssm.cn-northwest-1.amazonaws.com.cn",
                           "ap-south-1": "ssm.ap-south-1.amazonaws.com",
                           "eu-north-1": "ssm.eu-north-1.amazonaws.com", "ap-northeast-2": "ssm.ap-northeast-2.amazonaws.com",
                           "us-west-1": "ssm.us-west-1.amazonaws.com",
                           "us-gov-east-1": "ssm.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "ssm.eu-west-3.amazonaws.com",
                           "cn-north-1": "ssm.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "ssm.sa-east-1.amazonaws.com",
                           "eu-west-1": "ssm.eu-west-1.amazonaws.com",
                           "us-gov-west-1": "ssm.us-gov-west-1.amazonaws.com", "ap-southeast-2": "ssm.ap-southeast-2.amazonaws.com",
                           "ca-central-1": "ssm.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "ssm.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "ssm.ap-southeast-1.amazonaws.com",
      "us-west-2": "ssm.us-west-2.amazonaws.com",
      "eu-west-2": "ssm.eu-west-2.amazonaws.com",
      "ap-northeast-3": "ssm.ap-northeast-3.amazonaws.com",
      "eu-central-1": "ssm.eu-central-1.amazonaws.com",
      "us-east-2": "ssm.us-east-2.amazonaws.com",
      "us-east-1": "ssm.us-east-1.amazonaws.com",
      "cn-northwest-1": "ssm.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "ssm.ap-south-1.amazonaws.com",
      "eu-north-1": "ssm.eu-north-1.amazonaws.com",
      "ap-northeast-2": "ssm.ap-northeast-2.amazonaws.com",
      "us-west-1": "ssm.us-west-1.amazonaws.com",
      "us-gov-east-1": "ssm.us-gov-east-1.amazonaws.com",
      "eu-west-3": "ssm.eu-west-3.amazonaws.com",
      "cn-north-1": "ssm.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "ssm.sa-east-1.amazonaws.com",
      "eu-west-1": "ssm.eu-west-1.amazonaws.com",
      "us-gov-west-1": "ssm.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "ssm.ap-southeast-2.amazonaws.com",
      "ca-central-1": "ssm.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "ssm"
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_AddTagsToResource_602803 = ref object of OpenApiRestCall_602466
proc url_AddTagsToResource_602805(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_AddTagsToResource_602804(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p>Adds or overwrites one or more tags for the specified resource. Tags are metadata that you can assign to your documents, managed instances, maintenance windows, Parameter Store parameters, and patch baselines. Tags enable you to categorize your resources in different ways, for example, by purpose, owner, or environment. Each tag consists of a key and an optional value, both of which you define. For example, you could define a set of tags for your account's managed instances that helps you track each instance's owner and stack level. For example: Key=Owner and Value=DbAdmin, SysAdmin, or Dev. Or Key=Stack and Value=Production, Pre-Production, or Test.</p> <p>Each resource can have a maximum of 50 tags. </p> <p>We recommend that you devise a set of tag keys that meets your needs for each resource type. Using a consistent set of tag keys makes it easier for you to manage your resources. You can search and filter the resources based on the tags you add. Tags don't have any semantic meaning to Amazon EC2 and are interpreted strictly as a string of characters. </p> <p>For more information about tags, see <a href="http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/Using_Tags.html">Tagging Your Amazon EC2 Resources</a> in the <i>Amazon EC2 User Guide</i>.</p>
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
  var valid_602917 = header.getOrDefault("X-Amz-Date")
  valid_602917 = validateParameter(valid_602917, JString, required = false,
                                 default = nil)
  if valid_602917 != nil:
    section.add "X-Amz-Date", valid_602917
  var valid_602918 = header.getOrDefault("X-Amz-Security-Token")
  valid_602918 = validateParameter(valid_602918, JString, required = false,
                                 default = nil)
  if valid_602918 != nil:
    section.add "X-Amz-Security-Token", valid_602918
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602932 = header.getOrDefault("X-Amz-Target")
  valid_602932 = validateParameter(valid_602932, JString, required = true, default = newJString(
      "AmazonSSM.AddTagsToResource"))
  if valid_602932 != nil:
    section.add "X-Amz-Target", valid_602932
  var valid_602933 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602933 = validateParameter(valid_602933, JString, required = false,
                                 default = nil)
  if valid_602933 != nil:
    section.add "X-Amz-Content-Sha256", valid_602933
  var valid_602934 = header.getOrDefault("X-Amz-Algorithm")
  valid_602934 = validateParameter(valid_602934, JString, required = false,
                                 default = nil)
  if valid_602934 != nil:
    section.add "X-Amz-Algorithm", valid_602934
  var valid_602935 = header.getOrDefault("X-Amz-Signature")
  valid_602935 = validateParameter(valid_602935, JString, required = false,
                                 default = nil)
  if valid_602935 != nil:
    section.add "X-Amz-Signature", valid_602935
  var valid_602936 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602936 = validateParameter(valid_602936, JString, required = false,
                                 default = nil)
  if valid_602936 != nil:
    section.add "X-Amz-SignedHeaders", valid_602936
  var valid_602937 = header.getOrDefault("X-Amz-Credential")
  valid_602937 = validateParameter(valid_602937, JString, required = false,
                                 default = nil)
  if valid_602937 != nil:
    section.add "X-Amz-Credential", valid_602937
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602961: Call_AddTagsToResource_602803; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds or overwrites one or more tags for the specified resource. Tags are metadata that you can assign to your documents, managed instances, maintenance windows, Parameter Store parameters, and patch baselines. Tags enable you to categorize your resources in different ways, for example, by purpose, owner, or environment. Each tag consists of a key and an optional value, both of which you define. For example, you could define a set of tags for your account's managed instances that helps you track each instance's owner and stack level. For example: Key=Owner and Value=DbAdmin, SysAdmin, or Dev. Or Key=Stack and Value=Production, Pre-Production, or Test.</p> <p>Each resource can have a maximum of 50 tags. </p> <p>We recommend that you devise a set of tag keys that meets your needs for each resource type. Using a consistent set of tag keys makes it easier for you to manage your resources. You can search and filter the resources based on the tags you add. Tags don't have any semantic meaning to Amazon EC2 and are interpreted strictly as a string of characters. </p> <p>For more information about tags, see <a href="http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/Using_Tags.html">Tagging Your Amazon EC2 Resources</a> in the <i>Amazon EC2 User Guide</i>.</p>
  ## 
  let valid = call_602961.validator(path, query, header, formData, body)
  let scheme = call_602961.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602961.url(scheme.get, call_602961.host, call_602961.base,
                         call_602961.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602961, url, valid)

proc call*(call_603032: Call_AddTagsToResource_602803; body: JsonNode): Recallable =
  ## addTagsToResource
  ## <p>Adds or overwrites one or more tags for the specified resource. Tags are metadata that you can assign to your documents, managed instances, maintenance windows, Parameter Store parameters, and patch baselines. Tags enable you to categorize your resources in different ways, for example, by purpose, owner, or environment. Each tag consists of a key and an optional value, both of which you define. For example, you could define a set of tags for your account's managed instances that helps you track each instance's owner and stack level. For example: Key=Owner and Value=DbAdmin, SysAdmin, or Dev. Or Key=Stack and Value=Production, Pre-Production, or Test.</p> <p>Each resource can have a maximum of 50 tags. </p> <p>We recommend that you devise a set of tag keys that meets your needs for each resource type. Using a consistent set of tag keys makes it easier for you to manage your resources. You can search and filter the resources based on the tags you add. Tags don't have any semantic meaning to Amazon EC2 and are interpreted strictly as a string of characters. </p> <p>For more information about tags, see <a href="http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/Using_Tags.html">Tagging Your Amazon EC2 Resources</a> in the <i>Amazon EC2 User Guide</i>.</p>
  ##   body: JObject (required)
  var body_603033 = newJObject()
  if body != nil:
    body_603033 = body
  result = call_603032.call(nil, nil, nil, nil, body_603033)

var addTagsToResource* = Call_AddTagsToResource_602803(name: "addTagsToResource",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.AddTagsToResource",
    validator: validate_AddTagsToResource_602804, base: "/",
    url: url_AddTagsToResource_602805, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CancelCommand_603072 = ref object of OpenApiRestCall_602466
proc url_CancelCommand_603074(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CancelCommand_603073(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Attempts to cancel the command specified by the Command ID. There is no guarantee that the command will be terminated and the underlying process stopped.
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
  var valid_603075 = header.getOrDefault("X-Amz-Date")
  valid_603075 = validateParameter(valid_603075, JString, required = false,
                                 default = nil)
  if valid_603075 != nil:
    section.add "X-Amz-Date", valid_603075
  var valid_603076 = header.getOrDefault("X-Amz-Security-Token")
  valid_603076 = validateParameter(valid_603076, JString, required = false,
                                 default = nil)
  if valid_603076 != nil:
    section.add "X-Amz-Security-Token", valid_603076
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603077 = header.getOrDefault("X-Amz-Target")
  valid_603077 = validateParameter(valid_603077, JString, required = true, default = newJString(
      "AmazonSSM.CancelCommand"))
  if valid_603077 != nil:
    section.add "X-Amz-Target", valid_603077
  var valid_603078 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603078 = validateParameter(valid_603078, JString, required = false,
                                 default = nil)
  if valid_603078 != nil:
    section.add "X-Amz-Content-Sha256", valid_603078
  var valid_603079 = header.getOrDefault("X-Amz-Algorithm")
  valid_603079 = validateParameter(valid_603079, JString, required = false,
                                 default = nil)
  if valid_603079 != nil:
    section.add "X-Amz-Algorithm", valid_603079
  var valid_603080 = header.getOrDefault("X-Amz-Signature")
  valid_603080 = validateParameter(valid_603080, JString, required = false,
                                 default = nil)
  if valid_603080 != nil:
    section.add "X-Amz-Signature", valid_603080
  var valid_603081 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603081 = validateParameter(valid_603081, JString, required = false,
                                 default = nil)
  if valid_603081 != nil:
    section.add "X-Amz-SignedHeaders", valid_603081
  var valid_603082 = header.getOrDefault("X-Amz-Credential")
  valid_603082 = validateParameter(valid_603082, JString, required = false,
                                 default = nil)
  if valid_603082 != nil:
    section.add "X-Amz-Credential", valid_603082
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603084: Call_CancelCommand_603072; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Attempts to cancel the command specified by the Command ID. There is no guarantee that the command will be terminated and the underlying process stopped.
  ## 
  let valid = call_603084.validator(path, query, header, formData, body)
  let scheme = call_603084.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603084.url(scheme.get, call_603084.host, call_603084.base,
                         call_603084.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603084, url, valid)

proc call*(call_603085: Call_CancelCommand_603072; body: JsonNode): Recallable =
  ## cancelCommand
  ## Attempts to cancel the command specified by the Command ID. There is no guarantee that the command will be terminated and the underlying process stopped.
  ##   body: JObject (required)
  var body_603086 = newJObject()
  if body != nil:
    body_603086 = body
  result = call_603085.call(nil, nil, nil, nil, body_603086)

var cancelCommand* = Call_CancelCommand_603072(name: "cancelCommand",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.CancelCommand",
    validator: validate_CancelCommand_603073, base: "/", url: url_CancelCommand_603074,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CancelMaintenanceWindowExecution_603087 = ref object of OpenApiRestCall_602466
proc url_CancelMaintenanceWindowExecution_603089(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CancelMaintenanceWindowExecution_603088(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Stops a maintenance window execution that is already in progress and cancels any tasks in the window that have not already starting running. (Tasks already in progress will continue to completion.)
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
  var valid_603090 = header.getOrDefault("X-Amz-Date")
  valid_603090 = validateParameter(valid_603090, JString, required = false,
                                 default = nil)
  if valid_603090 != nil:
    section.add "X-Amz-Date", valid_603090
  var valid_603091 = header.getOrDefault("X-Amz-Security-Token")
  valid_603091 = validateParameter(valid_603091, JString, required = false,
                                 default = nil)
  if valid_603091 != nil:
    section.add "X-Amz-Security-Token", valid_603091
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603092 = header.getOrDefault("X-Amz-Target")
  valid_603092 = validateParameter(valid_603092, JString, required = true, default = newJString(
      "AmazonSSM.CancelMaintenanceWindowExecution"))
  if valid_603092 != nil:
    section.add "X-Amz-Target", valid_603092
  var valid_603093 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603093 = validateParameter(valid_603093, JString, required = false,
                                 default = nil)
  if valid_603093 != nil:
    section.add "X-Amz-Content-Sha256", valid_603093
  var valid_603094 = header.getOrDefault("X-Amz-Algorithm")
  valid_603094 = validateParameter(valid_603094, JString, required = false,
                                 default = nil)
  if valid_603094 != nil:
    section.add "X-Amz-Algorithm", valid_603094
  var valid_603095 = header.getOrDefault("X-Amz-Signature")
  valid_603095 = validateParameter(valid_603095, JString, required = false,
                                 default = nil)
  if valid_603095 != nil:
    section.add "X-Amz-Signature", valid_603095
  var valid_603096 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603096 = validateParameter(valid_603096, JString, required = false,
                                 default = nil)
  if valid_603096 != nil:
    section.add "X-Amz-SignedHeaders", valid_603096
  var valid_603097 = header.getOrDefault("X-Amz-Credential")
  valid_603097 = validateParameter(valid_603097, JString, required = false,
                                 default = nil)
  if valid_603097 != nil:
    section.add "X-Amz-Credential", valid_603097
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603099: Call_CancelMaintenanceWindowExecution_603087;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Stops a maintenance window execution that is already in progress and cancels any tasks in the window that have not already starting running. (Tasks already in progress will continue to completion.)
  ## 
  let valid = call_603099.validator(path, query, header, formData, body)
  let scheme = call_603099.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603099.url(scheme.get, call_603099.host, call_603099.base,
                         call_603099.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603099, url, valid)

proc call*(call_603100: Call_CancelMaintenanceWindowExecution_603087;
          body: JsonNode): Recallable =
  ## cancelMaintenanceWindowExecution
  ## Stops a maintenance window execution that is already in progress and cancels any tasks in the window that have not already starting running. (Tasks already in progress will continue to completion.)
  ##   body: JObject (required)
  var body_603101 = newJObject()
  if body != nil:
    body_603101 = body
  result = call_603100.call(nil, nil, nil, nil, body_603101)

var cancelMaintenanceWindowExecution* = Call_CancelMaintenanceWindowExecution_603087(
    name: "cancelMaintenanceWindowExecution", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.CancelMaintenanceWindowExecution",
    validator: validate_CancelMaintenanceWindowExecution_603088, base: "/",
    url: url_CancelMaintenanceWindowExecution_603089,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateActivation_603102 = ref object of OpenApiRestCall_602466
proc url_CreateActivation_603104(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateActivation_603103(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Registers your on-premises server or virtual machine with Amazon EC2 so that you can manage these resources using Run Command. An on-premises server or virtual machine that has been registered with EC2 is called a managed instance. For more information about activations, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-managedinstances.html">Setting Up AWS Systems Manager for Hybrid Environments</a>.
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
  var valid_603105 = header.getOrDefault("X-Amz-Date")
  valid_603105 = validateParameter(valid_603105, JString, required = false,
                                 default = nil)
  if valid_603105 != nil:
    section.add "X-Amz-Date", valid_603105
  var valid_603106 = header.getOrDefault("X-Amz-Security-Token")
  valid_603106 = validateParameter(valid_603106, JString, required = false,
                                 default = nil)
  if valid_603106 != nil:
    section.add "X-Amz-Security-Token", valid_603106
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603107 = header.getOrDefault("X-Amz-Target")
  valid_603107 = validateParameter(valid_603107, JString, required = true, default = newJString(
      "AmazonSSM.CreateActivation"))
  if valid_603107 != nil:
    section.add "X-Amz-Target", valid_603107
  var valid_603108 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603108 = validateParameter(valid_603108, JString, required = false,
                                 default = nil)
  if valid_603108 != nil:
    section.add "X-Amz-Content-Sha256", valid_603108
  var valid_603109 = header.getOrDefault("X-Amz-Algorithm")
  valid_603109 = validateParameter(valid_603109, JString, required = false,
                                 default = nil)
  if valid_603109 != nil:
    section.add "X-Amz-Algorithm", valid_603109
  var valid_603110 = header.getOrDefault("X-Amz-Signature")
  valid_603110 = validateParameter(valid_603110, JString, required = false,
                                 default = nil)
  if valid_603110 != nil:
    section.add "X-Amz-Signature", valid_603110
  var valid_603111 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603111 = validateParameter(valid_603111, JString, required = false,
                                 default = nil)
  if valid_603111 != nil:
    section.add "X-Amz-SignedHeaders", valid_603111
  var valid_603112 = header.getOrDefault("X-Amz-Credential")
  valid_603112 = validateParameter(valid_603112, JString, required = false,
                                 default = nil)
  if valid_603112 != nil:
    section.add "X-Amz-Credential", valid_603112
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603114: Call_CreateActivation_603102; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Registers your on-premises server or virtual machine with Amazon EC2 so that you can manage these resources using Run Command. An on-premises server or virtual machine that has been registered with EC2 is called a managed instance. For more information about activations, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-managedinstances.html">Setting Up AWS Systems Manager for Hybrid Environments</a>.
  ## 
  let valid = call_603114.validator(path, query, header, formData, body)
  let scheme = call_603114.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603114.url(scheme.get, call_603114.host, call_603114.base,
                         call_603114.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603114, url, valid)

proc call*(call_603115: Call_CreateActivation_603102; body: JsonNode): Recallable =
  ## createActivation
  ## Registers your on-premises server or virtual machine with Amazon EC2 so that you can manage these resources using Run Command. An on-premises server or virtual machine that has been registered with EC2 is called a managed instance. For more information about activations, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-managedinstances.html">Setting Up AWS Systems Manager for Hybrid Environments</a>.
  ##   body: JObject (required)
  var body_603116 = newJObject()
  if body != nil:
    body_603116 = body
  result = call_603115.call(nil, nil, nil, nil, body_603116)

var createActivation* = Call_CreateActivation_603102(name: "createActivation",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.CreateActivation",
    validator: validate_CreateActivation_603103, base: "/",
    url: url_CreateActivation_603104, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateAssociation_603117 = ref object of OpenApiRestCall_602466
proc url_CreateAssociation_603119(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateAssociation_603118(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p>Associates the specified Systems Manager document with the specified instances or targets.</p> <p>When you associate a document with one or more instances using instance IDs or tags, SSM Agent running on the instance processes the document and configures the instance as specified.</p> <p>If you associate a document with an instance that already has an associated document, the system returns the AssociationAlreadyExists exception.</p>
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
  var valid_603120 = header.getOrDefault("X-Amz-Date")
  valid_603120 = validateParameter(valid_603120, JString, required = false,
                                 default = nil)
  if valid_603120 != nil:
    section.add "X-Amz-Date", valid_603120
  var valid_603121 = header.getOrDefault("X-Amz-Security-Token")
  valid_603121 = validateParameter(valid_603121, JString, required = false,
                                 default = nil)
  if valid_603121 != nil:
    section.add "X-Amz-Security-Token", valid_603121
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603122 = header.getOrDefault("X-Amz-Target")
  valid_603122 = validateParameter(valid_603122, JString, required = true, default = newJString(
      "AmazonSSM.CreateAssociation"))
  if valid_603122 != nil:
    section.add "X-Amz-Target", valid_603122
  var valid_603123 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603123 = validateParameter(valid_603123, JString, required = false,
                                 default = nil)
  if valid_603123 != nil:
    section.add "X-Amz-Content-Sha256", valid_603123
  var valid_603124 = header.getOrDefault("X-Amz-Algorithm")
  valid_603124 = validateParameter(valid_603124, JString, required = false,
                                 default = nil)
  if valid_603124 != nil:
    section.add "X-Amz-Algorithm", valid_603124
  var valid_603125 = header.getOrDefault("X-Amz-Signature")
  valid_603125 = validateParameter(valid_603125, JString, required = false,
                                 default = nil)
  if valid_603125 != nil:
    section.add "X-Amz-Signature", valid_603125
  var valid_603126 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603126 = validateParameter(valid_603126, JString, required = false,
                                 default = nil)
  if valid_603126 != nil:
    section.add "X-Amz-SignedHeaders", valid_603126
  var valid_603127 = header.getOrDefault("X-Amz-Credential")
  valid_603127 = validateParameter(valid_603127, JString, required = false,
                                 default = nil)
  if valid_603127 != nil:
    section.add "X-Amz-Credential", valid_603127
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603129: Call_CreateAssociation_603117; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Associates the specified Systems Manager document with the specified instances or targets.</p> <p>When you associate a document with one or more instances using instance IDs or tags, SSM Agent running on the instance processes the document and configures the instance as specified.</p> <p>If you associate a document with an instance that already has an associated document, the system returns the AssociationAlreadyExists exception.</p>
  ## 
  let valid = call_603129.validator(path, query, header, formData, body)
  let scheme = call_603129.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603129.url(scheme.get, call_603129.host, call_603129.base,
                         call_603129.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603129, url, valid)

proc call*(call_603130: Call_CreateAssociation_603117; body: JsonNode): Recallable =
  ## createAssociation
  ## <p>Associates the specified Systems Manager document with the specified instances or targets.</p> <p>When you associate a document with one or more instances using instance IDs or tags, SSM Agent running on the instance processes the document and configures the instance as specified.</p> <p>If you associate a document with an instance that already has an associated document, the system returns the AssociationAlreadyExists exception.</p>
  ##   body: JObject (required)
  var body_603131 = newJObject()
  if body != nil:
    body_603131 = body
  result = call_603130.call(nil, nil, nil, nil, body_603131)

var createAssociation* = Call_CreateAssociation_603117(name: "createAssociation",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.CreateAssociation",
    validator: validate_CreateAssociation_603118, base: "/",
    url: url_CreateAssociation_603119, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateAssociationBatch_603132 = ref object of OpenApiRestCall_602466
proc url_CreateAssociationBatch_603134(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateAssociationBatch_603133(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Associates the specified Systems Manager document with the specified instances or targets.</p> <p>When you associate a document with one or more instances using instance IDs or tags, SSM Agent running on the instance processes the document and configures the instance as specified.</p> <p>If you associate a document with an instance that already has an associated document, the system returns the AssociationAlreadyExists exception.</p>
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
  var valid_603135 = header.getOrDefault("X-Amz-Date")
  valid_603135 = validateParameter(valid_603135, JString, required = false,
                                 default = nil)
  if valid_603135 != nil:
    section.add "X-Amz-Date", valid_603135
  var valid_603136 = header.getOrDefault("X-Amz-Security-Token")
  valid_603136 = validateParameter(valid_603136, JString, required = false,
                                 default = nil)
  if valid_603136 != nil:
    section.add "X-Amz-Security-Token", valid_603136
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603137 = header.getOrDefault("X-Amz-Target")
  valid_603137 = validateParameter(valid_603137, JString, required = true, default = newJString(
      "AmazonSSM.CreateAssociationBatch"))
  if valid_603137 != nil:
    section.add "X-Amz-Target", valid_603137
  var valid_603138 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603138 = validateParameter(valid_603138, JString, required = false,
                                 default = nil)
  if valid_603138 != nil:
    section.add "X-Amz-Content-Sha256", valid_603138
  var valid_603139 = header.getOrDefault("X-Amz-Algorithm")
  valid_603139 = validateParameter(valid_603139, JString, required = false,
                                 default = nil)
  if valid_603139 != nil:
    section.add "X-Amz-Algorithm", valid_603139
  var valid_603140 = header.getOrDefault("X-Amz-Signature")
  valid_603140 = validateParameter(valid_603140, JString, required = false,
                                 default = nil)
  if valid_603140 != nil:
    section.add "X-Amz-Signature", valid_603140
  var valid_603141 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603141 = validateParameter(valid_603141, JString, required = false,
                                 default = nil)
  if valid_603141 != nil:
    section.add "X-Amz-SignedHeaders", valid_603141
  var valid_603142 = header.getOrDefault("X-Amz-Credential")
  valid_603142 = validateParameter(valid_603142, JString, required = false,
                                 default = nil)
  if valid_603142 != nil:
    section.add "X-Amz-Credential", valid_603142
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603144: Call_CreateAssociationBatch_603132; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Associates the specified Systems Manager document with the specified instances or targets.</p> <p>When you associate a document with one or more instances using instance IDs or tags, SSM Agent running on the instance processes the document and configures the instance as specified.</p> <p>If you associate a document with an instance that already has an associated document, the system returns the AssociationAlreadyExists exception.</p>
  ## 
  let valid = call_603144.validator(path, query, header, formData, body)
  let scheme = call_603144.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603144.url(scheme.get, call_603144.host, call_603144.base,
                         call_603144.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603144, url, valid)

proc call*(call_603145: Call_CreateAssociationBatch_603132; body: JsonNode): Recallable =
  ## createAssociationBatch
  ## <p>Associates the specified Systems Manager document with the specified instances or targets.</p> <p>When you associate a document with one or more instances using instance IDs or tags, SSM Agent running on the instance processes the document and configures the instance as specified.</p> <p>If you associate a document with an instance that already has an associated document, the system returns the AssociationAlreadyExists exception.</p>
  ##   body: JObject (required)
  var body_603146 = newJObject()
  if body != nil:
    body_603146 = body
  result = call_603145.call(nil, nil, nil, nil, body_603146)

var createAssociationBatch* = Call_CreateAssociationBatch_603132(
    name: "createAssociationBatch", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.CreateAssociationBatch",
    validator: validate_CreateAssociationBatch_603133, base: "/",
    url: url_CreateAssociationBatch_603134, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDocument_603147 = ref object of OpenApiRestCall_602466
proc url_CreateDocument_603149(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateDocument_603148(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>Creates a Systems Manager document.</p> <p>After you create a document, you can use CreateAssociation to associate it with one or more running instances.</p>
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
  var valid_603150 = header.getOrDefault("X-Amz-Date")
  valid_603150 = validateParameter(valid_603150, JString, required = false,
                                 default = nil)
  if valid_603150 != nil:
    section.add "X-Amz-Date", valid_603150
  var valid_603151 = header.getOrDefault("X-Amz-Security-Token")
  valid_603151 = validateParameter(valid_603151, JString, required = false,
                                 default = nil)
  if valid_603151 != nil:
    section.add "X-Amz-Security-Token", valid_603151
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603152 = header.getOrDefault("X-Amz-Target")
  valid_603152 = validateParameter(valid_603152, JString, required = true, default = newJString(
      "AmazonSSM.CreateDocument"))
  if valid_603152 != nil:
    section.add "X-Amz-Target", valid_603152
  var valid_603153 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603153 = validateParameter(valid_603153, JString, required = false,
                                 default = nil)
  if valid_603153 != nil:
    section.add "X-Amz-Content-Sha256", valid_603153
  var valid_603154 = header.getOrDefault("X-Amz-Algorithm")
  valid_603154 = validateParameter(valid_603154, JString, required = false,
                                 default = nil)
  if valid_603154 != nil:
    section.add "X-Amz-Algorithm", valid_603154
  var valid_603155 = header.getOrDefault("X-Amz-Signature")
  valid_603155 = validateParameter(valid_603155, JString, required = false,
                                 default = nil)
  if valid_603155 != nil:
    section.add "X-Amz-Signature", valid_603155
  var valid_603156 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603156 = validateParameter(valid_603156, JString, required = false,
                                 default = nil)
  if valid_603156 != nil:
    section.add "X-Amz-SignedHeaders", valid_603156
  var valid_603157 = header.getOrDefault("X-Amz-Credential")
  valid_603157 = validateParameter(valid_603157, JString, required = false,
                                 default = nil)
  if valid_603157 != nil:
    section.add "X-Amz-Credential", valid_603157
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603159: Call_CreateDocument_603147; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a Systems Manager document.</p> <p>After you create a document, you can use CreateAssociation to associate it with one or more running instances.</p>
  ## 
  let valid = call_603159.validator(path, query, header, formData, body)
  let scheme = call_603159.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603159.url(scheme.get, call_603159.host, call_603159.base,
                         call_603159.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603159, url, valid)

proc call*(call_603160: Call_CreateDocument_603147; body: JsonNode): Recallable =
  ## createDocument
  ## <p>Creates a Systems Manager document.</p> <p>After you create a document, you can use CreateAssociation to associate it with one or more running instances.</p>
  ##   body: JObject (required)
  var body_603161 = newJObject()
  if body != nil:
    body_603161 = body
  result = call_603160.call(nil, nil, nil, nil, body_603161)

var createDocument* = Call_CreateDocument_603147(name: "createDocument",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.CreateDocument",
    validator: validate_CreateDocument_603148, base: "/", url: url_CreateDocument_603149,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateMaintenanceWindow_603162 = ref object of OpenApiRestCall_602466
proc url_CreateMaintenanceWindow_603164(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateMaintenanceWindow_603163(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates a new maintenance window.</p> <note> <p>The value you specify for <code>Duration</code> determines the specific end time for the maintenance window based on the time it begins. No maintenance window tasks are permitted to start after the resulting endtime minus the number of hours you specify for <code>Cutoff</code>. For example, if the maintenance window starts at 3 PM, the duration is three hours, and the value you specify for <code>Cutoff</code> is one hour, no maintenance window tasks can start after 5 PM.</p> </note>
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
  var valid_603165 = header.getOrDefault("X-Amz-Date")
  valid_603165 = validateParameter(valid_603165, JString, required = false,
                                 default = nil)
  if valid_603165 != nil:
    section.add "X-Amz-Date", valid_603165
  var valid_603166 = header.getOrDefault("X-Amz-Security-Token")
  valid_603166 = validateParameter(valid_603166, JString, required = false,
                                 default = nil)
  if valid_603166 != nil:
    section.add "X-Amz-Security-Token", valid_603166
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603167 = header.getOrDefault("X-Amz-Target")
  valid_603167 = validateParameter(valid_603167, JString, required = true, default = newJString(
      "AmazonSSM.CreateMaintenanceWindow"))
  if valid_603167 != nil:
    section.add "X-Amz-Target", valid_603167
  var valid_603168 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603168 = validateParameter(valid_603168, JString, required = false,
                                 default = nil)
  if valid_603168 != nil:
    section.add "X-Amz-Content-Sha256", valid_603168
  var valid_603169 = header.getOrDefault("X-Amz-Algorithm")
  valid_603169 = validateParameter(valid_603169, JString, required = false,
                                 default = nil)
  if valid_603169 != nil:
    section.add "X-Amz-Algorithm", valid_603169
  var valid_603170 = header.getOrDefault("X-Amz-Signature")
  valid_603170 = validateParameter(valid_603170, JString, required = false,
                                 default = nil)
  if valid_603170 != nil:
    section.add "X-Amz-Signature", valid_603170
  var valid_603171 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603171 = validateParameter(valid_603171, JString, required = false,
                                 default = nil)
  if valid_603171 != nil:
    section.add "X-Amz-SignedHeaders", valid_603171
  var valid_603172 = header.getOrDefault("X-Amz-Credential")
  valid_603172 = validateParameter(valid_603172, JString, required = false,
                                 default = nil)
  if valid_603172 != nil:
    section.add "X-Amz-Credential", valid_603172
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603174: Call_CreateMaintenanceWindow_603162; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a new maintenance window.</p> <note> <p>The value you specify for <code>Duration</code> determines the specific end time for the maintenance window based on the time it begins. No maintenance window tasks are permitted to start after the resulting endtime minus the number of hours you specify for <code>Cutoff</code>. For example, if the maintenance window starts at 3 PM, the duration is three hours, and the value you specify for <code>Cutoff</code> is one hour, no maintenance window tasks can start after 5 PM.</p> </note>
  ## 
  let valid = call_603174.validator(path, query, header, formData, body)
  let scheme = call_603174.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603174.url(scheme.get, call_603174.host, call_603174.base,
                         call_603174.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603174, url, valid)

proc call*(call_603175: Call_CreateMaintenanceWindow_603162; body: JsonNode): Recallable =
  ## createMaintenanceWindow
  ## <p>Creates a new maintenance window.</p> <note> <p>The value you specify for <code>Duration</code> determines the specific end time for the maintenance window based on the time it begins. No maintenance window tasks are permitted to start after the resulting endtime minus the number of hours you specify for <code>Cutoff</code>. For example, if the maintenance window starts at 3 PM, the duration is three hours, and the value you specify for <code>Cutoff</code> is one hour, no maintenance window tasks can start after 5 PM.</p> </note>
  ##   body: JObject (required)
  var body_603176 = newJObject()
  if body != nil:
    body_603176 = body
  result = call_603175.call(nil, nil, nil, nil, body_603176)

var createMaintenanceWindow* = Call_CreateMaintenanceWindow_603162(
    name: "createMaintenanceWindow", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.CreateMaintenanceWindow",
    validator: validate_CreateMaintenanceWindow_603163, base: "/",
    url: url_CreateMaintenanceWindow_603164, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateOpsItem_603177 = ref object of OpenApiRestCall_602466
proc url_CreateOpsItem_603179(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateOpsItem_603178(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates a new OpsItem. You must have permission in AWS Identity and Access Management (IAM) to create a new OpsItem. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter-getting-started.html">Getting Started with OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>.</p> <p>Operations engineers and IT professionals use OpsCenter to view, investigate, and remediate operational issues impacting the performance and health of their AWS resources. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter.html">AWS Systems Manager OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>. </p>
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
  var valid_603180 = header.getOrDefault("X-Amz-Date")
  valid_603180 = validateParameter(valid_603180, JString, required = false,
                                 default = nil)
  if valid_603180 != nil:
    section.add "X-Amz-Date", valid_603180
  var valid_603181 = header.getOrDefault("X-Amz-Security-Token")
  valid_603181 = validateParameter(valid_603181, JString, required = false,
                                 default = nil)
  if valid_603181 != nil:
    section.add "X-Amz-Security-Token", valid_603181
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603182 = header.getOrDefault("X-Amz-Target")
  valid_603182 = validateParameter(valid_603182, JString, required = true, default = newJString(
      "AmazonSSM.CreateOpsItem"))
  if valid_603182 != nil:
    section.add "X-Amz-Target", valid_603182
  var valid_603183 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603183 = validateParameter(valid_603183, JString, required = false,
                                 default = nil)
  if valid_603183 != nil:
    section.add "X-Amz-Content-Sha256", valid_603183
  var valid_603184 = header.getOrDefault("X-Amz-Algorithm")
  valid_603184 = validateParameter(valid_603184, JString, required = false,
                                 default = nil)
  if valid_603184 != nil:
    section.add "X-Amz-Algorithm", valid_603184
  var valid_603185 = header.getOrDefault("X-Amz-Signature")
  valid_603185 = validateParameter(valid_603185, JString, required = false,
                                 default = nil)
  if valid_603185 != nil:
    section.add "X-Amz-Signature", valid_603185
  var valid_603186 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603186 = validateParameter(valid_603186, JString, required = false,
                                 default = nil)
  if valid_603186 != nil:
    section.add "X-Amz-SignedHeaders", valid_603186
  var valid_603187 = header.getOrDefault("X-Amz-Credential")
  valid_603187 = validateParameter(valid_603187, JString, required = false,
                                 default = nil)
  if valid_603187 != nil:
    section.add "X-Amz-Credential", valid_603187
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603189: Call_CreateOpsItem_603177; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a new OpsItem. You must have permission in AWS Identity and Access Management (IAM) to create a new OpsItem. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter-getting-started.html">Getting Started with OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>.</p> <p>Operations engineers and IT professionals use OpsCenter to view, investigate, and remediate operational issues impacting the performance and health of their AWS resources. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter.html">AWS Systems Manager OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>. </p>
  ## 
  let valid = call_603189.validator(path, query, header, formData, body)
  let scheme = call_603189.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603189.url(scheme.get, call_603189.host, call_603189.base,
                         call_603189.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603189, url, valid)

proc call*(call_603190: Call_CreateOpsItem_603177; body: JsonNode): Recallable =
  ## createOpsItem
  ## <p>Creates a new OpsItem. You must have permission in AWS Identity and Access Management (IAM) to create a new OpsItem. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter-getting-started.html">Getting Started with OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>.</p> <p>Operations engineers and IT professionals use OpsCenter to view, investigate, and remediate operational issues impacting the performance and health of their AWS resources. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter.html">AWS Systems Manager OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>. </p>
  ##   body: JObject (required)
  var body_603191 = newJObject()
  if body != nil:
    body_603191 = body
  result = call_603190.call(nil, nil, nil, nil, body_603191)

var createOpsItem* = Call_CreateOpsItem_603177(name: "createOpsItem",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.CreateOpsItem",
    validator: validate_CreateOpsItem_603178, base: "/", url: url_CreateOpsItem_603179,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePatchBaseline_603192 = ref object of OpenApiRestCall_602466
proc url_CreatePatchBaseline_603194(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreatePatchBaseline_603193(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p>Creates a patch baseline.</p> <note> <p>For information about valid key and value pairs in <code>PatchFilters</code> for each supported operating system type, see <a href="http://docs.aws.amazon.com/systems-manager/latest/APIReference/API_PatchFilter.html">PatchFilter</a>.</p> </note>
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
  var valid_603195 = header.getOrDefault("X-Amz-Date")
  valid_603195 = validateParameter(valid_603195, JString, required = false,
                                 default = nil)
  if valid_603195 != nil:
    section.add "X-Amz-Date", valid_603195
  var valid_603196 = header.getOrDefault("X-Amz-Security-Token")
  valid_603196 = validateParameter(valid_603196, JString, required = false,
                                 default = nil)
  if valid_603196 != nil:
    section.add "X-Amz-Security-Token", valid_603196
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603197 = header.getOrDefault("X-Amz-Target")
  valid_603197 = validateParameter(valid_603197, JString, required = true, default = newJString(
      "AmazonSSM.CreatePatchBaseline"))
  if valid_603197 != nil:
    section.add "X-Amz-Target", valid_603197
  var valid_603198 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603198 = validateParameter(valid_603198, JString, required = false,
                                 default = nil)
  if valid_603198 != nil:
    section.add "X-Amz-Content-Sha256", valid_603198
  var valid_603199 = header.getOrDefault("X-Amz-Algorithm")
  valid_603199 = validateParameter(valid_603199, JString, required = false,
                                 default = nil)
  if valid_603199 != nil:
    section.add "X-Amz-Algorithm", valid_603199
  var valid_603200 = header.getOrDefault("X-Amz-Signature")
  valid_603200 = validateParameter(valid_603200, JString, required = false,
                                 default = nil)
  if valid_603200 != nil:
    section.add "X-Amz-Signature", valid_603200
  var valid_603201 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603201 = validateParameter(valid_603201, JString, required = false,
                                 default = nil)
  if valid_603201 != nil:
    section.add "X-Amz-SignedHeaders", valid_603201
  var valid_603202 = header.getOrDefault("X-Amz-Credential")
  valid_603202 = validateParameter(valid_603202, JString, required = false,
                                 default = nil)
  if valid_603202 != nil:
    section.add "X-Amz-Credential", valid_603202
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603204: Call_CreatePatchBaseline_603192; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a patch baseline.</p> <note> <p>For information about valid key and value pairs in <code>PatchFilters</code> for each supported operating system type, see <a href="http://docs.aws.amazon.com/systems-manager/latest/APIReference/API_PatchFilter.html">PatchFilter</a>.</p> </note>
  ## 
  let valid = call_603204.validator(path, query, header, formData, body)
  let scheme = call_603204.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603204.url(scheme.get, call_603204.host, call_603204.base,
                         call_603204.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603204, url, valid)

proc call*(call_603205: Call_CreatePatchBaseline_603192; body: JsonNode): Recallable =
  ## createPatchBaseline
  ## <p>Creates a patch baseline.</p> <note> <p>For information about valid key and value pairs in <code>PatchFilters</code> for each supported operating system type, see <a href="http://docs.aws.amazon.com/systems-manager/latest/APIReference/API_PatchFilter.html">PatchFilter</a>.</p> </note>
  ##   body: JObject (required)
  var body_603206 = newJObject()
  if body != nil:
    body_603206 = body
  result = call_603205.call(nil, nil, nil, nil, body_603206)

var createPatchBaseline* = Call_CreatePatchBaseline_603192(
    name: "createPatchBaseline", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.CreatePatchBaseline",
    validator: validate_CreatePatchBaseline_603193, base: "/",
    url: url_CreatePatchBaseline_603194, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateResourceDataSync_603207 = ref object of OpenApiRestCall_602466
proc url_CreateResourceDataSync_603209(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateResourceDataSync_603208(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates a resource data sync configuration to a single bucket in Amazon S3. This is an asynchronous operation that returns immediately. After a successful initial sync is completed, the system continuously syncs data to the Amazon S3 bucket. To check the status of the sync, use the <a>ListResourceDataSync</a>.</p> <p>By default, data is not encrypted in Amazon S3. We strongly recommend that you enable encryption in Amazon S3 to ensure secure data storage. We also recommend that you secure access to the Amazon S3 bucket by creating a restrictive bucket policy. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/sysman-inventory-datasync.html">Configuring Resource Data Sync for Inventory</a> in the <i>AWS Systems Manager User Guide</i>.</p>
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
  var valid_603210 = header.getOrDefault("X-Amz-Date")
  valid_603210 = validateParameter(valid_603210, JString, required = false,
                                 default = nil)
  if valid_603210 != nil:
    section.add "X-Amz-Date", valid_603210
  var valid_603211 = header.getOrDefault("X-Amz-Security-Token")
  valid_603211 = validateParameter(valid_603211, JString, required = false,
                                 default = nil)
  if valid_603211 != nil:
    section.add "X-Amz-Security-Token", valid_603211
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603212 = header.getOrDefault("X-Amz-Target")
  valid_603212 = validateParameter(valid_603212, JString, required = true, default = newJString(
      "AmazonSSM.CreateResourceDataSync"))
  if valid_603212 != nil:
    section.add "X-Amz-Target", valid_603212
  var valid_603213 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603213 = validateParameter(valid_603213, JString, required = false,
                                 default = nil)
  if valid_603213 != nil:
    section.add "X-Amz-Content-Sha256", valid_603213
  var valid_603214 = header.getOrDefault("X-Amz-Algorithm")
  valid_603214 = validateParameter(valid_603214, JString, required = false,
                                 default = nil)
  if valid_603214 != nil:
    section.add "X-Amz-Algorithm", valid_603214
  var valid_603215 = header.getOrDefault("X-Amz-Signature")
  valid_603215 = validateParameter(valid_603215, JString, required = false,
                                 default = nil)
  if valid_603215 != nil:
    section.add "X-Amz-Signature", valid_603215
  var valid_603216 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603216 = validateParameter(valid_603216, JString, required = false,
                                 default = nil)
  if valid_603216 != nil:
    section.add "X-Amz-SignedHeaders", valid_603216
  var valid_603217 = header.getOrDefault("X-Amz-Credential")
  valid_603217 = validateParameter(valid_603217, JString, required = false,
                                 default = nil)
  if valid_603217 != nil:
    section.add "X-Amz-Credential", valid_603217
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603219: Call_CreateResourceDataSync_603207; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a resource data sync configuration to a single bucket in Amazon S3. This is an asynchronous operation that returns immediately. After a successful initial sync is completed, the system continuously syncs data to the Amazon S3 bucket. To check the status of the sync, use the <a>ListResourceDataSync</a>.</p> <p>By default, data is not encrypted in Amazon S3. We strongly recommend that you enable encryption in Amazon S3 to ensure secure data storage. We also recommend that you secure access to the Amazon S3 bucket by creating a restrictive bucket policy. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/sysman-inventory-datasync.html">Configuring Resource Data Sync for Inventory</a> in the <i>AWS Systems Manager User Guide</i>.</p>
  ## 
  let valid = call_603219.validator(path, query, header, formData, body)
  let scheme = call_603219.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603219.url(scheme.get, call_603219.host, call_603219.base,
                         call_603219.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603219, url, valid)

proc call*(call_603220: Call_CreateResourceDataSync_603207; body: JsonNode): Recallable =
  ## createResourceDataSync
  ## <p>Creates a resource data sync configuration to a single bucket in Amazon S3. This is an asynchronous operation that returns immediately. After a successful initial sync is completed, the system continuously syncs data to the Amazon S3 bucket. To check the status of the sync, use the <a>ListResourceDataSync</a>.</p> <p>By default, data is not encrypted in Amazon S3. We strongly recommend that you enable encryption in Amazon S3 to ensure secure data storage. We also recommend that you secure access to the Amazon S3 bucket by creating a restrictive bucket policy. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/sysman-inventory-datasync.html">Configuring Resource Data Sync for Inventory</a> in the <i>AWS Systems Manager User Guide</i>.</p>
  ##   body: JObject (required)
  var body_603221 = newJObject()
  if body != nil:
    body_603221 = body
  result = call_603220.call(nil, nil, nil, nil, body_603221)

var createResourceDataSync* = Call_CreateResourceDataSync_603207(
    name: "createResourceDataSync", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.CreateResourceDataSync",
    validator: validate_CreateResourceDataSync_603208, base: "/",
    url: url_CreateResourceDataSync_603209, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteActivation_603222 = ref object of OpenApiRestCall_602466
proc url_DeleteActivation_603224(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteActivation_603223(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Deletes an activation. You are not required to delete an activation. If you delete an activation, you can no longer use it to register additional managed instances. Deleting an activation does not de-register managed instances. You must manually de-register managed instances.
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
  var valid_603225 = header.getOrDefault("X-Amz-Date")
  valid_603225 = validateParameter(valid_603225, JString, required = false,
                                 default = nil)
  if valid_603225 != nil:
    section.add "X-Amz-Date", valid_603225
  var valid_603226 = header.getOrDefault("X-Amz-Security-Token")
  valid_603226 = validateParameter(valid_603226, JString, required = false,
                                 default = nil)
  if valid_603226 != nil:
    section.add "X-Amz-Security-Token", valid_603226
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603227 = header.getOrDefault("X-Amz-Target")
  valid_603227 = validateParameter(valid_603227, JString, required = true, default = newJString(
      "AmazonSSM.DeleteActivation"))
  if valid_603227 != nil:
    section.add "X-Amz-Target", valid_603227
  var valid_603228 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603228 = validateParameter(valid_603228, JString, required = false,
                                 default = nil)
  if valid_603228 != nil:
    section.add "X-Amz-Content-Sha256", valid_603228
  var valid_603229 = header.getOrDefault("X-Amz-Algorithm")
  valid_603229 = validateParameter(valid_603229, JString, required = false,
                                 default = nil)
  if valid_603229 != nil:
    section.add "X-Amz-Algorithm", valid_603229
  var valid_603230 = header.getOrDefault("X-Amz-Signature")
  valid_603230 = validateParameter(valid_603230, JString, required = false,
                                 default = nil)
  if valid_603230 != nil:
    section.add "X-Amz-Signature", valid_603230
  var valid_603231 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603231 = validateParameter(valid_603231, JString, required = false,
                                 default = nil)
  if valid_603231 != nil:
    section.add "X-Amz-SignedHeaders", valid_603231
  var valid_603232 = header.getOrDefault("X-Amz-Credential")
  valid_603232 = validateParameter(valid_603232, JString, required = false,
                                 default = nil)
  if valid_603232 != nil:
    section.add "X-Amz-Credential", valid_603232
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603234: Call_DeleteActivation_603222; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an activation. You are not required to delete an activation. If you delete an activation, you can no longer use it to register additional managed instances. Deleting an activation does not de-register managed instances. You must manually de-register managed instances.
  ## 
  let valid = call_603234.validator(path, query, header, formData, body)
  let scheme = call_603234.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603234.url(scheme.get, call_603234.host, call_603234.base,
                         call_603234.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603234, url, valid)

proc call*(call_603235: Call_DeleteActivation_603222; body: JsonNode): Recallable =
  ## deleteActivation
  ## Deletes an activation. You are not required to delete an activation. If you delete an activation, you can no longer use it to register additional managed instances. Deleting an activation does not de-register managed instances. You must manually de-register managed instances.
  ##   body: JObject (required)
  var body_603236 = newJObject()
  if body != nil:
    body_603236 = body
  result = call_603235.call(nil, nil, nil, nil, body_603236)

var deleteActivation* = Call_DeleteActivation_603222(name: "deleteActivation",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DeleteActivation",
    validator: validate_DeleteActivation_603223, base: "/",
    url: url_DeleteActivation_603224, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAssociation_603237 = ref object of OpenApiRestCall_602466
proc url_DeleteAssociation_603239(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteAssociation_603238(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p>Disassociates the specified Systems Manager document from the specified instance.</p> <p>When you disassociate a document from an instance, it does not change the configuration of the instance. To change the configuration state of an instance after you disassociate a document, you must create a new document with the desired configuration and associate it with the instance.</p>
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
  var valid_603240 = header.getOrDefault("X-Amz-Date")
  valid_603240 = validateParameter(valid_603240, JString, required = false,
                                 default = nil)
  if valid_603240 != nil:
    section.add "X-Amz-Date", valid_603240
  var valid_603241 = header.getOrDefault("X-Amz-Security-Token")
  valid_603241 = validateParameter(valid_603241, JString, required = false,
                                 default = nil)
  if valid_603241 != nil:
    section.add "X-Amz-Security-Token", valid_603241
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603242 = header.getOrDefault("X-Amz-Target")
  valid_603242 = validateParameter(valid_603242, JString, required = true, default = newJString(
      "AmazonSSM.DeleteAssociation"))
  if valid_603242 != nil:
    section.add "X-Amz-Target", valid_603242
  var valid_603243 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603243 = validateParameter(valid_603243, JString, required = false,
                                 default = nil)
  if valid_603243 != nil:
    section.add "X-Amz-Content-Sha256", valid_603243
  var valid_603244 = header.getOrDefault("X-Amz-Algorithm")
  valid_603244 = validateParameter(valid_603244, JString, required = false,
                                 default = nil)
  if valid_603244 != nil:
    section.add "X-Amz-Algorithm", valid_603244
  var valid_603245 = header.getOrDefault("X-Amz-Signature")
  valid_603245 = validateParameter(valid_603245, JString, required = false,
                                 default = nil)
  if valid_603245 != nil:
    section.add "X-Amz-Signature", valid_603245
  var valid_603246 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603246 = validateParameter(valid_603246, JString, required = false,
                                 default = nil)
  if valid_603246 != nil:
    section.add "X-Amz-SignedHeaders", valid_603246
  var valid_603247 = header.getOrDefault("X-Amz-Credential")
  valid_603247 = validateParameter(valid_603247, JString, required = false,
                                 default = nil)
  if valid_603247 != nil:
    section.add "X-Amz-Credential", valid_603247
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603249: Call_DeleteAssociation_603237; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Disassociates the specified Systems Manager document from the specified instance.</p> <p>When you disassociate a document from an instance, it does not change the configuration of the instance. To change the configuration state of an instance after you disassociate a document, you must create a new document with the desired configuration and associate it with the instance.</p>
  ## 
  let valid = call_603249.validator(path, query, header, formData, body)
  let scheme = call_603249.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603249.url(scheme.get, call_603249.host, call_603249.base,
                         call_603249.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603249, url, valid)

proc call*(call_603250: Call_DeleteAssociation_603237; body: JsonNode): Recallable =
  ## deleteAssociation
  ## <p>Disassociates the specified Systems Manager document from the specified instance.</p> <p>When you disassociate a document from an instance, it does not change the configuration of the instance. To change the configuration state of an instance after you disassociate a document, you must create a new document with the desired configuration and associate it with the instance.</p>
  ##   body: JObject (required)
  var body_603251 = newJObject()
  if body != nil:
    body_603251 = body
  result = call_603250.call(nil, nil, nil, nil, body_603251)

var deleteAssociation* = Call_DeleteAssociation_603237(name: "deleteAssociation",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DeleteAssociation",
    validator: validate_DeleteAssociation_603238, base: "/",
    url: url_DeleteAssociation_603239, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDocument_603252 = ref object of OpenApiRestCall_602466
proc url_DeleteDocument_603254(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteDocument_603253(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>Deletes the Systems Manager document and all instance associations to the document.</p> <p>Before you delete the document, we recommend that you use <a>DeleteAssociation</a> to disassociate all instances that are associated with the document.</p>
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
  var valid_603255 = header.getOrDefault("X-Amz-Date")
  valid_603255 = validateParameter(valid_603255, JString, required = false,
                                 default = nil)
  if valid_603255 != nil:
    section.add "X-Amz-Date", valid_603255
  var valid_603256 = header.getOrDefault("X-Amz-Security-Token")
  valid_603256 = validateParameter(valid_603256, JString, required = false,
                                 default = nil)
  if valid_603256 != nil:
    section.add "X-Amz-Security-Token", valid_603256
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603257 = header.getOrDefault("X-Amz-Target")
  valid_603257 = validateParameter(valid_603257, JString, required = true, default = newJString(
      "AmazonSSM.DeleteDocument"))
  if valid_603257 != nil:
    section.add "X-Amz-Target", valid_603257
  var valid_603258 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603258 = validateParameter(valid_603258, JString, required = false,
                                 default = nil)
  if valid_603258 != nil:
    section.add "X-Amz-Content-Sha256", valid_603258
  var valid_603259 = header.getOrDefault("X-Amz-Algorithm")
  valid_603259 = validateParameter(valid_603259, JString, required = false,
                                 default = nil)
  if valid_603259 != nil:
    section.add "X-Amz-Algorithm", valid_603259
  var valid_603260 = header.getOrDefault("X-Amz-Signature")
  valid_603260 = validateParameter(valid_603260, JString, required = false,
                                 default = nil)
  if valid_603260 != nil:
    section.add "X-Amz-Signature", valid_603260
  var valid_603261 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603261 = validateParameter(valid_603261, JString, required = false,
                                 default = nil)
  if valid_603261 != nil:
    section.add "X-Amz-SignedHeaders", valid_603261
  var valid_603262 = header.getOrDefault("X-Amz-Credential")
  valid_603262 = validateParameter(valid_603262, JString, required = false,
                                 default = nil)
  if valid_603262 != nil:
    section.add "X-Amz-Credential", valid_603262
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603264: Call_DeleteDocument_603252; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the Systems Manager document and all instance associations to the document.</p> <p>Before you delete the document, we recommend that you use <a>DeleteAssociation</a> to disassociate all instances that are associated with the document.</p>
  ## 
  let valid = call_603264.validator(path, query, header, formData, body)
  let scheme = call_603264.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603264.url(scheme.get, call_603264.host, call_603264.base,
                         call_603264.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603264, url, valid)

proc call*(call_603265: Call_DeleteDocument_603252; body: JsonNode): Recallable =
  ## deleteDocument
  ## <p>Deletes the Systems Manager document and all instance associations to the document.</p> <p>Before you delete the document, we recommend that you use <a>DeleteAssociation</a> to disassociate all instances that are associated with the document.</p>
  ##   body: JObject (required)
  var body_603266 = newJObject()
  if body != nil:
    body_603266 = body
  result = call_603265.call(nil, nil, nil, nil, body_603266)

var deleteDocument* = Call_DeleteDocument_603252(name: "deleteDocument",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DeleteDocument",
    validator: validate_DeleteDocument_603253, base: "/", url: url_DeleteDocument_603254,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteInventory_603267 = ref object of OpenApiRestCall_602466
proc url_DeleteInventory_603269(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteInventory_603268(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Delete a custom inventory type, or the data associated with a custom Inventory type. Deleting a custom inventory type is also referred to as deleting a custom inventory schema.
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
  var valid_603270 = header.getOrDefault("X-Amz-Date")
  valid_603270 = validateParameter(valid_603270, JString, required = false,
                                 default = nil)
  if valid_603270 != nil:
    section.add "X-Amz-Date", valid_603270
  var valid_603271 = header.getOrDefault("X-Amz-Security-Token")
  valid_603271 = validateParameter(valid_603271, JString, required = false,
                                 default = nil)
  if valid_603271 != nil:
    section.add "X-Amz-Security-Token", valid_603271
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603272 = header.getOrDefault("X-Amz-Target")
  valid_603272 = validateParameter(valid_603272, JString, required = true, default = newJString(
      "AmazonSSM.DeleteInventory"))
  if valid_603272 != nil:
    section.add "X-Amz-Target", valid_603272
  var valid_603273 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603273 = validateParameter(valid_603273, JString, required = false,
                                 default = nil)
  if valid_603273 != nil:
    section.add "X-Amz-Content-Sha256", valid_603273
  var valid_603274 = header.getOrDefault("X-Amz-Algorithm")
  valid_603274 = validateParameter(valid_603274, JString, required = false,
                                 default = nil)
  if valid_603274 != nil:
    section.add "X-Amz-Algorithm", valid_603274
  var valid_603275 = header.getOrDefault("X-Amz-Signature")
  valid_603275 = validateParameter(valid_603275, JString, required = false,
                                 default = nil)
  if valid_603275 != nil:
    section.add "X-Amz-Signature", valid_603275
  var valid_603276 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603276 = validateParameter(valid_603276, JString, required = false,
                                 default = nil)
  if valid_603276 != nil:
    section.add "X-Amz-SignedHeaders", valid_603276
  var valid_603277 = header.getOrDefault("X-Amz-Credential")
  valid_603277 = validateParameter(valid_603277, JString, required = false,
                                 default = nil)
  if valid_603277 != nil:
    section.add "X-Amz-Credential", valid_603277
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603279: Call_DeleteInventory_603267; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Delete a custom inventory type, or the data associated with a custom Inventory type. Deleting a custom inventory type is also referred to as deleting a custom inventory schema.
  ## 
  let valid = call_603279.validator(path, query, header, formData, body)
  let scheme = call_603279.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603279.url(scheme.get, call_603279.host, call_603279.base,
                         call_603279.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603279, url, valid)

proc call*(call_603280: Call_DeleteInventory_603267; body: JsonNode): Recallable =
  ## deleteInventory
  ## Delete a custom inventory type, or the data associated with a custom Inventory type. Deleting a custom inventory type is also referred to as deleting a custom inventory schema.
  ##   body: JObject (required)
  var body_603281 = newJObject()
  if body != nil:
    body_603281 = body
  result = call_603280.call(nil, nil, nil, nil, body_603281)

var deleteInventory* = Call_DeleteInventory_603267(name: "deleteInventory",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DeleteInventory",
    validator: validate_DeleteInventory_603268, base: "/", url: url_DeleteInventory_603269,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteMaintenanceWindow_603282 = ref object of OpenApiRestCall_602466
proc url_DeleteMaintenanceWindow_603284(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteMaintenanceWindow_603283(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes a maintenance window.
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
  var valid_603285 = header.getOrDefault("X-Amz-Date")
  valid_603285 = validateParameter(valid_603285, JString, required = false,
                                 default = nil)
  if valid_603285 != nil:
    section.add "X-Amz-Date", valid_603285
  var valid_603286 = header.getOrDefault("X-Amz-Security-Token")
  valid_603286 = validateParameter(valid_603286, JString, required = false,
                                 default = nil)
  if valid_603286 != nil:
    section.add "X-Amz-Security-Token", valid_603286
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603287 = header.getOrDefault("X-Amz-Target")
  valid_603287 = validateParameter(valid_603287, JString, required = true, default = newJString(
      "AmazonSSM.DeleteMaintenanceWindow"))
  if valid_603287 != nil:
    section.add "X-Amz-Target", valid_603287
  var valid_603288 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603288 = validateParameter(valid_603288, JString, required = false,
                                 default = nil)
  if valid_603288 != nil:
    section.add "X-Amz-Content-Sha256", valid_603288
  var valid_603289 = header.getOrDefault("X-Amz-Algorithm")
  valid_603289 = validateParameter(valid_603289, JString, required = false,
                                 default = nil)
  if valid_603289 != nil:
    section.add "X-Amz-Algorithm", valid_603289
  var valid_603290 = header.getOrDefault("X-Amz-Signature")
  valid_603290 = validateParameter(valid_603290, JString, required = false,
                                 default = nil)
  if valid_603290 != nil:
    section.add "X-Amz-Signature", valid_603290
  var valid_603291 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603291 = validateParameter(valid_603291, JString, required = false,
                                 default = nil)
  if valid_603291 != nil:
    section.add "X-Amz-SignedHeaders", valid_603291
  var valid_603292 = header.getOrDefault("X-Amz-Credential")
  valid_603292 = validateParameter(valid_603292, JString, required = false,
                                 default = nil)
  if valid_603292 != nil:
    section.add "X-Amz-Credential", valid_603292
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603294: Call_DeleteMaintenanceWindow_603282; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a maintenance window.
  ## 
  let valid = call_603294.validator(path, query, header, formData, body)
  let scheme = call_603294.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603294.url(scheme.get, call_603294.host, call_603294.base,
                         call_603294.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603294, url, valid)

proc call*(call_603295: Call_DeleteMaintenanceWindow_603282; body: JsonNode): Recallable =
  ## deleteMaintenanceWindow
  ## Deletes a maintenance window.
  ##   body: JObject (required)
  var body_603296 = newJObject()
  if body != nil:
    body_603296 = body
  result = call_603295.call(nil, nil, nil, nil, body_603296)

var deleteMaintenanceWindow* = Call_DeleteMaintenanceWindow_603282(
    name: "deleteMaintenanceWindow", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DeleteMaintenanceWindow",
    validator: validate_DeleteMaintenanceWindow_603283, base: "/",
    url: url_DeleteMaintenanceWindow_603284, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteParameter_603297 = ref object of OpenApiRestCall_602466
proc url_DeleteParameter_603299(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteParameter_603298(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Delete a parameter from the system.
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
  var valid_603300 = header.getOrDefault("X-Amz-Date")
  valid_603300 = validateParameter(valid_603300, JString, required = false,
                                 default = nil)
  if valid_603300 != nil:
    section.add "X-Amz-Date", valid_603300
  var valid_603301 = header.getOrDefault("X-Amz-Security-Token")
  valid_603301 = validateParameter(valid_603301, JString, required = false,
                                 default = nil)
  if valid_603301 != nil:
    section.add "X-Amz-Security-Token", valid_603301
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603302 = header.getOrDefault("X-Amz-Target")
  valid_603302 = validateParameter(valid_603302, JString, required = true, default = newJString(
      "AmazonSSM.DeleteParameter"))
  if valid_603302 != nil:
    section.add "X-Amz-Target", valid_603302
  var valid_603303 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603303 = validateParameter(valid_603303, JString, required = false,
                                 default = nil)
  if valid_603303 != nil:
    section.add "X-Amz-Content-Sha256", valid_603303
  var valid_603304 = header.getOrDefault("X-Amz-Algorithm")
  valid_603304 = validateParameter(valid_603304, JString, required = false,
                                 default = nil)
  if valid_603304 != nil:
    section.add "X-Amz-Algorithm", valid_603304
  var valid_603305 = header.getOrDefault("X-Amz-Signature")
  valid_603305 = validateParameter(valid_603305, JString, required = false,
                                 default = nil)
  if valid_603305 != nil:
    section.add "X-Amz-Signature", valid_603305
  var valid_603306 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603306 = validateParameter(valid_603306, JString, required = false,
                                 default = nil)
  if valid_603306 != nil:
    section.add "X-Amz-SignedHeaders", valid_603306
  var valid_603307 = header.getOrDefault("X-Amz-Credential")
  valid_603307 = validateParameter(valid_603307, JString, required = false,
                                 default = nil)
  if valid_603307 != nil:
    section.add "X-Amz-Credential", valid_603307
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603309: Call_DeleteParameter_603297; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Delete a parameter from the system.
  ## 
  let valid = call_603309.validator(path, query, header, formData, body)
  let scheme = call_603309.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603309.url(scheme.get, call_603309.host, call_603309.base,
                         call_603309.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603309, url, valid)

proc call*(call_603310: Call_DeleteParameter_603297; body: JsonNode): Recallable =
  ## deleteParameter
  ## Delete a parameter from the system.
  ##   body: JObject (required)
  var body_603311 = newJObject()
  if body != nil:
    body_603311 = body
  result = call_603310.call(nil, nil, nil, nil, body_603311)

var deleteParameter* = Call_DeleteParameter_603297(name: "deleteParameter",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DeleteParameter",
    validator: validate_DeleteParameter_603298, base: "/", url: url_DeleteParameter_603299,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteParameters_603312 = ref object of OpenApiRestCall_602466
proc url_DeleteParameters_603314(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteParameters_603313(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Delete a list of parameters.
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
  var valid_603315 = header.getOrDefault("X-Amz-Date")
  valid_603315 = validateParameter(valid_603315, JString, required = false,
                                 default = nil)
  if valid_603315 != nil:
    section.add "X-Amz-Date", valid_603315
  var valid_603316 = header.getOrDefault("X-Amz-Security-Token")
  valid_603316 = validateParameter(valid_603316, JString, required = false,
                                 default = nil)
  if valid_603316 != nil:
    section.add "X-Amz-Security-Token", valid_603316
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603317 = header.getOrDefault("X-Amz-Target")
  valid_603317 = validateParameter(valid_603317, JString, required = true, default = newJString(
      "AmazonSSM.DeleteParameters"))
  if valid_603317 != nil:
    section.add "X-Amz-Target", valid_603317
  var valid_603318 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603318 = validateParameter(valid_603318, JString, required = false,
                                 default = nil)
  if valid_603318 != nil:
    section.add "X-Amz-Content-Sha256", valid_603318
  var valid_603319 = header.getOrDefault("X-Amz-Algorithm")
  valid_603319 = validateParameter(valid_603319, JString, required = false,
                                 default = nil)
  if valid_603319 != nil:
    section.add "X-Amz-Algorithm", valid_603319
  var valid_603320 = header.getOrDefault("X-Amz-Signature")
  valid_603320 = validateParameter(valid_603320, JString, required = false,
                                 default = nil)
  if valid_603320 != nil:
    section.add "X-Amz-Signature", valid_603320
  var valid_603321 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603321 = validateParameter(valid_603321, JString, required = false,
                                 default = nil)
  if valid_603321 != nil:
    section.add "X-Amz-SignedHeaders", valid_603321
  var valid_603322 = header.getOrDefault("X-Amz-Credential")
  valid_603322 = validateParameter(valid_603322, JString, required = false,
                                 default = nil)
  if valid_603322 != nil:
    section.add "X-Amz-Credential", valid_603322
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603324: Call_DeleteParameters_603312; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Delete a list of parameters.
  ## 
  let valid = call_603324.validator(path, query, header, formData, body)
  let scheme = call_603324.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603324.url(scheme.get, call_603324.host, call_603324.base,
                         call_603324.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603324, url, valid)

proc call*(call_603325: Call_DeleteParameters_603312; body: JsonNode): Recallable =
  ## deleteParameters
  ## Delete a list of parameters.
  ##   body: JObject (required)
  var body_603326 = newJObject()
  if body != nil:
    body_603326 = body
  result = call_603325.call(nil, nil, nil, nil, body_603326)

var deleteParameters* = Call_DeleteParameters_603312(name: "deleteParameters",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DeleteParameters",
    validator: validate_DeleteParameters_603313, base: "/",
    url: url_DeleteParameters_603314, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeletePatchBaseline_603327 = ref object of OpenApiRestCall_602466
proc url_DeletePatchBaseline_603329(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeletePatchBaseline_603328(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Deletes a patch baseline.
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
  var valid_603330 = header.getOrDefault("X-Amz-Date")
  valid_603330 = validateParameter(valid_603330, JString, required = false,
                                 default = nil)
  if valid_603330 != nil:
    section.add "X-Amz-Date", valid_603330
  var valid_603331 = header.getOrDefault("X-Amz-Security-Token")
  valid_603331 = validateParameter(valid_603331, JString, required = false,
                                 default = nil)
  if valid_603331 != nil:
    section.add "X-Amz-Security-Token", valid_603331
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603332 = header.getOrDefault("X-Amz-Target")
  valid_603332 = validateParameter(valid_603332, JString, required = true, default = newJString(
      "AmazonSSM.DeletePatchBaseline"))
  if valid_603332 != nil:
    section.add "X-Amz-Target", valid_603332
  var valid_603333 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603333 = validateParameter(valid_603333, JString, required = false,
                                 default = nil)
  if valid_603333 != nil:
    section.add "X-Amz-Content-Sha256", valid_603333
  var valid_603334 = header.getOrDefault("X-Amz-Algorithm")
  valid_603334 = validateParameter(valid_603334, JString, required = false,
                                 default = nil)
  if valid_603334 != nil:
    section.add "X-Amz-Algorithm", valid_603334
  var valid_603335 = header.getOrDefault("X-Amz-Signature")
  valid_603335 = validateParameter(valid_603335, JString, required = false,
                                 default = nil)
  if valid_603335 != nil:
    section.add "X-Amz-Signature", valid_603335
  var valid_603336 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603336 = validateParameter(valid_603336, JString, required = false,
                                 default = nil)
  if valid_603336 != nil:
    section.add "X-Amz-SignedHeaders", valid_603336
  var valid_603337 = header.getOrDefault("X-Amz-Credential")
  valid_603337 = validateParameter(valid_603337, JString, required = false,
                                 default = nil)
  if valid_603337 != nil:
    section.add "X-Amz-Credential", valid_603337
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603339: Call_DeletePatchBaseline_603327; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a patch baseline.
  ## 
  let valid = call_603339.validator(path, query, header, formData, body)
  let scheme = call_603339.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603339.url(scheme.get, call_603339.host, call_603339.base,
                         call_603339.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603339, url, valid)

proc call*(call_603340: Call_DeletePatchBaseline_603327; body: JsonNode): Recallable =
  ## deletePatchBaseline
  ## Deletes a patch baseline.
  ##   body: JObject (required)
  var body_603341 = newJObject()
  if body != nil:
    body_603341 = body
  result = call_603340.call(nil, nil, nil, nil, body_603341)

var deletePatchBaseline* = Call_DeletePatchBaseline_603327(
    name: "deletePatchBaseline", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DeletePatchBaseline",
    validator: validate_DeletePatchBaseline_603328, base: "/",
    url: url_DeletePatchBaseline_603329, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteResourceDataSync_603342 = ref object of OpenApiRestCall_602466
proc url_DeleteResourceDataSync_603344(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteResourceDataSync_603343(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes a Resource Data Sync configuration. After the configuration is deleted, changes to inventory data on managed instances are no longer synced with the target Amazon S3 bucket. Deleting a sync configuration does not delete data in the target Amazon S3 bucket.
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
  var valid_603345 = header.getOrDefault("X-Amz-Date")
  valid_603345 = validateParameter(valid_603345, JString, required = false,
                                 default = nil)
  if valid_603345 != nil:
    section.add "X-Amz-Date", valid_603345
  var valid_603346 = header.getOrDefault("X-Amz-Security-Token")
  valid_603346 = validateParameter(valid_603346, JString, required = false,
                                 default = nil)
  if valid_603346 != nil:
    section.add "X-Amz-Security-Token", valid_603346
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603347 = header.getOrDefault("X-Amz-Target")
  valid_603347 = validateParameter(valid_603347, JString, required = true, default = newJString(
      "AmazonSSM.DeleteResourceDataSync"))
  if valid_603347 != nil:
    section.add "X-Amz-Target", valid_603347
  var valid_603348 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603348 = validateParameter(valid_603348, JString, required = false,
                                 default = nil)
  if valid_603348 != nil:
    section.add "X-Amz-Content-Sha256", valid_603348
  var valid_603349 = header.getOrDefault("X-Amz-Algorithm")
  valid_603349 = validateParameter(valid_603349, JString, required = false,
                                 default = nil)
  if valid_603349 != nil:
    section.add "X-Amz-Algorithm", valid_603349
  var valid_603350 = header.getOrDefault("X-Amz-Signature")
  valid_603350 = validateParameter(valid_603350, JString, required = false,
                                 default = nil)
  if valid_603350 != nil:
    section.add "X-Amz-Signature", valid_603350
  var valid_603351 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603351 = validateParameter(valid_603351, JString, required = false,
                                 default = nil)
  if valid_603351 != nil:
    section.add "X-Amz-SignedHeaders", valid_603351
  var valid_603352 = header.getOrDefault("X-Amz-Credential")
  valid_603352 = validateParameter(valid_603352, JString, required = false,
                                 default = nil)
  if valid_603352 != nil:
    section.add "X-Amz-Credential", valid_603352
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603354: Call_DeleteResourceDataSync_603342; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a Resource Data Sync configuration. After the configuration is deleted, changes to inventory data on managed instances are no longer synced with the target Amazon S3 bucket. Deleting a sync configuration does not delete data in the target Amazon S3 bucket.
  ## 
  let valid = call_603354.validator(path, query, header, formData, body)
  let scheme = call_603354.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603354.url(scheme.get, call_603354.host, call_603354.base,
                         call_603354.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603354, url, valid)

proc call*(call_603355: Call_DeleteResourceDataSync_603342; body: JsonNode): Recallable =
  ## deleteResourceDataSync
  ## Deletes a Resource Data Sync configuration. After the configuration is deleted, changes to inventory data on managed instances are no longer synced with the target Amazon S3 bucket. Deleting a sync configuration does not delete data in the target Amazon S3 bucket.
  ##   body: JObject (required)
  var body_603356 = newJObject()
  if body != nil:
    body_603356 = body
  result = call_603355.call(nil, nil, nil, nil, body_603356)

var deleteResourceDataSync* = Call_DeleteResourceDataSync_603342(
    name: "deleteResourceDataSync", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DeleteResourceDataSync",
    validator: validate_DeleteResourceDataSync_603343, base: "/",
    url: url_DeleteResourceDataSync_603344, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeregisterManagedInstance_603357 = ref object of OpenApiRestCall_602466
proc url_DeregisterManagedInstance_603359(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeregisterManagedInstance_603358(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Removes the server or virtual machine from the list of registered servers. You can reregister the instance again at any time. If you don't plan to use Run Command on the server, we suggest uninstalling SSM Agent first.
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
  var valid_603360 = header.getOrDefault("X-Amz-Date")
  valid_603360 = validateParameter(valid_603360, JString, required = false,
                                 default = nil)
  if valid_603360 != nil:
    section.add "X-Amz-Date", valid_603360
  var valid_603361 = header.getOrDefault("X-Amz-Security-Token")
  valid_603361 = validateParameter(valid_603361, JString, required = false,
                                 default = nil)
  if valid_603361 != nil:
    section.add "X-Amz-Security-Token", valid_603361
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603362 = header.getOrDefault("X-Amz-Target")
  valid_603362 = validateParameter(valid_603362, JString, required = true, default = newJString(
      "AmazonSSM.DeregisterManagedInstance"))
  if valid_603362 != nil:
    section.add "X-Amz-Target", valid_603362
  var valid_603363 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603363 = validateParameter(valid_603363, JString, required = false,
                                 default = nil)
  if valid_603363 != nil:
    section.add "X-Amz-Content-Sha256", valid_603363
  var valid_603364 = header.getOrDefault("X-Amz-Algorithm")
  valid_603364 = validateParameter(valid_603364, JString, required = false,
                                 default = nil)
  if valid_603364 != nil:
    section.add "X-Amz-Algorithm", valid_603364
  var valid_603365 = header.getOrDefault("X-Amz-Signature")
  valid_603365 = validateParameter(valid_603365, JString, required = false,
                                 default = nil)
  if valid_603365 != nil:
    section.add "X-Amz-Signature", valid_603365
  var valid_603366 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603366 = validateParameter(valid_603366, JString, required = false,
                                 default = nil)
  if valid_603366 != nil:
    section.add "X-Amz-SignedHeaders", valid_603366
  var valid_603367 = header.getOrDefault("X-Amz-Credential")
  valid_603367 = validateParameter(valid_603367, JString, required = false,
                                 default = nil)
  if valid_603367 != nil:
    section.add "X-Amz-Credential", valid_603367
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603369: Call_DeregisterManagedInstance_603357; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes the server or virtual machine from the list of registered servers. You can reregister the instance again at any time. If you don't plan to use Run Command on the server, we suggest uninstalling SSM Agent first.
  ## 
  let valid = call_603369.validator(path, query, header, formData, body)
  let scheme = call_603369.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603369.url(scheme.get, call_603369.host, call_603369.base,
                         call_603369.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603369, url, valid)

proc call*(call_603370: Call_DeregisterManagedInstance_603357; body: JsonNode): Recallable =
  ## deregisterManagedInstance
  ## Removes the server or virtual machine from the list of registered servers. You can reregister the instance again at any time. If you don't plan to use Run Command on the server, we suggest uninstalling SSM Agent first.
  ##   body: JObject (required)
  var body_603371 = newJObject()
  if body != nil:
    body_603371 = body
  result = call_603370.call(nil, nil, nil, nil, body_603371)

var deregisterManagedInstance* = Call_DeregisterManagedInstance_603357(
    name: "deregisterManagedInstance", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DeregisterManagedInstance",
    validator: validate_DeregisterManagedInstance_603358, base: "/",
    url: url_DeregisterManagedInstance_603359,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeregisterPatchBaselineForPatchGroup_603372 = ref object of OpenApiRestCall_602466
proc url_DeregisterPatchBaselineForPatchGroup_603374(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeregisterPatchBaselineForPatchGroup_603373(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Removes a patch group from a patch baseline.
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
  var valid_603375 = header.getOrDefault("X-Amz-Date")
  valid_603375 = validateParameter(valid_603375, JString, required = false,
                                 default = nil)
  if valid_603375 != nil:
    section.add "X-Amz-Date", valid_603375
  var valid_603376 = header.getOrDefault("X-Amz-Security-Token")
  valid_603376 = validateParameter(valid_603376, JString, required = false,
                                 default = nil)
  if valid_603376 != nil:
    section.add "X-Amz-Security-Token", valid_603376
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603377 = header.getOrDefault("X-Amz-Target")
  valid_603377 = validateParameter(valid_603377, JString, required = true, default = newJString(
      "AmazonSSM.DeregisterPatchBaselineForPatchGroup"))
  if valid_603377 != nil:
    section.add "X-Amz-Target", valid_603377
  var valid_603378 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603378 = validateParameter(valid_603378, JString, required = false,
                                 default = nil)
  if valid_603378 != nil:
    section.add "X-Amz-Content-Sha256", valid_603378
  var valid_603379 = header.getOrDefault("X-Amz-Algorithm")
  valid_603379 = validateParameter(valid_603379, JString, required = false,
                                 default = nil)
  if valid_603379 != nil:
    section.add "X-Amz-Algorithm", valid_603379
  var valid_603380 = header.getOrDefault("X-Amz-Signature")
  valid_603380 = validateParameter(valid_603380, JString, required = false,
                                 default = nil)
  if valid_603380 != nil:
    section.add "X-Amz-Signature", valid_603380
  var valid_603381 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603381 = validateParameter(valid_603381, JString, required = false,
                                 default = nil)
  if valid_603381 != nil:
    section.add "X-Amz-SignedHeaders", valid_603381
  var valid_603382 = header.getOrDefault("X-Amz-Credential")
  valid_603382 = validateParameter(valid_603382, JString, required = false,
                                 default = nil)
  if valid_603382 != nil:
    section.add "X-Amz-Credential", valid_603382
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603384: Call_DeregisterPatchBaselineForPatchGroup_603372;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Removes a patch group from a patch baseline.
  ## 
  let valid = call_603384.validator(path, query, header, formData, body)
  let scheme = call_603384.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603384.url(scheme.get, call_603384.host, call_603384.base,
                         call_603384.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603384, url, valid)

proc call*(call_603385: Call_DeregisterPatchBaselineForPatchGroup_603372;
          body: JsonNode): Recallable =
  ## deregisterPatchBaselineForPatchGroup
  ## Removes a patch group from a patch baseline.
  ##   body: JObject (required)
  var body_603386 = newJObject()
  if body != nil:
    body_603386 = body
  result = call_603385.call(nil, nil, nil, nil, body_603386)

var deregisterPatchBaselineForPatchGroup* = Call_DeregisterPatchBaselineForPatchGroup_603372(
    name: "deregisterPatchBaselineForPatchGroup", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DeregisterPatchBaselineForPatchGroup",
    validator: validate_DeregisterPatchBaselineForPatchGroup_603373, base: "/",
    url: url_DeregisterPatchBaselineForPatchGroup_603374,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeregisterTargetFromMaintenanceWindow_603387 = ref object of OpenApiRestCall_602466
proc url_DeregisterTargetFromMaintenanceWindow_603389(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeregisterTargetFromMaintenanceWindow_603388(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Removes a target from a maintenance window.
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
  var valid_603390 = header.getOrDefault("X-Amz-Date")
  valid_603390 = validateParameter(valid_603390, JString, required = false,
                                 default = nil)
  if valid_603390 != nil:
    section.add "X-Amz-Date", valid_603390
  var valid_603391 = header.getOrDefault("X-Amz-Security-Token")
  valid_603391 = validateParameter(valid_603391, JString, required = false,
                                 default = nil)
  if valid_603391 != nil:
    section.add "X-Amz-Security-Token", valid_603391
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603392 = header.getOrDefault("X-Amz-Target")
  valid_603392 = validateParameter(valid_603392, JString, required = true, default = newJString(
      "AmazonSSM.DeregisterTargetFromMaintenanceWindow"))
  if valid_603392 != nil:
    section.add "X-Amz-Target", valid_603392
  var valid_603393 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603393 = validateParameter(valid_603393, JString, required = false,
                                 default = nil)
  if valid_603393 != nil:
    section.add "X-Amz-Content-Sha256", valid_603393
  var valid_603394 = header.getOrDefault("X-Amz-Algorithm")
  valid_603394 = validateParameter(valid_603394, JString, required = false,
                                 default = nil)
  if valid_603394 != nil:
    section.add "X-Amz-Algorithm", valid_603394
  var valid_603395 = header.getOrDefault("X-Amz-Signature")
  valid_603395 = validateParameter(valid_603395, JString, required = false,
                                 default = nil)
  if valid_603395 != nil:
    section.add "X-Amz-Signature", valid_603395
  var valid_603396 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603396 = validateParameter(valid_603396, JString, required = false,
                                 default = nil)
  if valid_603396 != nil:
    section.add "X-Amz-SignedHeaders", valid_603396
  var valid_603397 = header.getOrDefault("X-Amz-Credential")
  valid_603397 = validateParameter(valid_603397, JString, required = false,
                                 default = nil)
  if valid_603397 != nil:
    section.add "X-Amz-Credential", valid_603397
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603399: Call_DeregisterTargetFromMaintenanceWindow_603387;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Removes a target from a maintenance window.
  ## 
  let valid = call_603399.validator(path, query, header, formData, body)
  let scheme = call_603399.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603399.url(scheme.get, call_603399.host, call_603399.base,
                         call_603399.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603399, url, valid)

proc call*(call_603400: Call_DeregisterTargetFromMaintenanceWindow_603387;
          body: JsonNode): Recallable =
  ## deregisterTargetFromMaintenanceWindow
  ## Removes a target from a maintenance window.
  ##   body: JObject (required)
  var body_603401 = newJObject()
  if body != nil:
    body_603401 = body
  result = call_603400.call(nil, nil, nil, nil, body_603401)

var deregisterTargetFromMaintenanceWindow* = Call_DeregisterTargetFromMaintenanceWindow_603387(
    name: "deregisterTargetFromMaintenanceWindow", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DeregisterTargetFromMaintenanceWindow",
    validator: validate_DeregisterTargetFromMaintenanceWindow_603388, base: "/",
    url: url_DeregisterTargetFromMaintenanceWindow_603389,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeregisterTaskFromMaintenanceWindow_603402 = ref object of OpenApiRestCall_602466
proc url_DeregisterTaskFromMaintenanceWindow_603404(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeregisterTaskFromMaintenanceWindow_603403(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Removes a task from a maintenance window.
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
  var valid_603405 = header.getOrDefault("X-Amz-Date")
  valid_603405 = validateParameter(valid_603405, JString, required = false,
                                 default = nil)
  if valid_603405 != nil:
    section.add "X-Amz-Date", valid_603405
  var valid_603406 = header.getOrDefault("X-Amz-Security-Token")
  valid_603406 = validateParameter(valid_603406, JString, required = false,
                                 default = nil)
  if valid_603406 != nil:
    section.add "X-Amz-Security-Token", valid_603406
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603407 = header.getOrDefault("X-Amz-Target")
  valid_603407 = validateParameter(valid_603407, JString, required = true, default = newJString(
      "AmazonSSM.DeregisterTaskFromMaintenanceWindow"))
  if valid_603407 != nil:
    section.add "X-Amz-Target", valid_603407
  var valid_603408 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603408 = validateParameter(valid_603408, JString, required = false,
                                 default = nil)
  if valid_603408 != nil:
    section.add "X-Amz-Content-Sha256", valid_603408
  var valid_603409 = header.getOrDefault("X-Amz-Algorithm")
  valid_603409 = validateParameter(valid_603409, JString, required = false,
                                 default = nil)
  if valid_603409 != nil:
    section.add "X-Amz-Algorithm", valid_603409
  var valid_603410 = header.getOrDefault("X-Amz-Signature")
  valid_603410 = validateParameter(valid_603410, JString, required = false,
                                 default = nil)
  if valid_603410 != nil:
    section.add "X-Amz-Signature", valid_603410
  var valid_603411 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603411 = validateParameter(valid_603411, JString, required = false,
                                 default = nil)
  if valid_603411 != nil:
    section.add "X-Amz-SignedHeaders", valid_603411
  var valid_603412 = header.getOrDefault("X-Amz-Credential")
  valid_603412 = validateParameter(valid_603412, JString, required = false,
                                 default = nil)
  if valid_603412 != nil:
    section.add "X-Amz-Credential", valid_603412
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603414: Call_DeregisterTaskFromMaintenanceWindow_603402;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Removes a task from a maintenance window.
  ## 
  let valid = call_603414.validator(path, query, header, formData, body)
  let scheme = call_603414.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603414.url(scheme.get, call_603414.host, call_603414.base,
                         call_603414.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603414, url, valid)

proc call*(call_603415: Call_DeregisterTaskFromMaintenanceWindow_603402;
          body: JsonNode): Recallable =
  ## deregisterTaskFromMaintenanceWindow
  ## Removes a task from a maintenance window.
  ##   body: JObject (required)
  var body_603416 = newJObject()
  if body != nil:
    body_603416 = body
  result = call_603415.call(nil, nil, nil, nil, body_603416)

var deregisterTaskFromMaintenanceWindow* = Call_DeregisterTaskFromMaintenanceWindow_603402(
    name: "deregisterTaskFromMaintenanceWindow", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DeregisterTaskFromMaintenanceWindow",
    validator: validate_DeregisterTaskFromMaintenanceWindow_603403, base: "/",
    url: url_DeregisterTaskFromMaintenanceWindow_603404,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeActivations_603417 = ref object of OpenApiRestCall_602466
proc url_DescribeActivations_603419(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeActivations_603418(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Describes details about the activation, such as the date and time the activation was created, its expiration date, the IAM role assigned to the instances in the activation, and the number of instances registered by using this activation.
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
  var valid_603420 = query.getOrDefault("NextToken")
  valid_603420 = validateParameter(valid_603420, JString, required = false,
                                 default = nil)
  if valid_603420 != nil:
    section.add "NextToken", valid_603420
  var valid_603421 = query.getOrDefault("MaxResults")
  valid_603421 = validateParameter(valid_603421, JString, required = false,
                                 default = nil)
  if valid_603421 != nil:
    section.add "MaxResults", valid_603421
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
  var valid_603422 = header.getOrDefault("X-Amz-Date")
  valid_603422 = validateParameter(valid_603422, JString, required = false,
                                 default = nil)
  if valid_603422 != nil:
    section.add "X-Amz-Date", valid_603422
  var valid_603423 = header.getOrDefault("X-Amz-Security-Token")
  valid_603423 = validateParameter(valid_603423, JString, required = false,
                                 default = nil)
  if valid_603423 != nil:
    section.add "X-Amz-Security-Token", valid_603423
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603424 = header.getOrDefault("X-Amz-Target")
  valid_603424 = validateParameter(valid_603424, JString, required = true, default = newJString(
      "AmazonSSM.DescribeActivations"))
  if valid_603424 != nil:
    section.add "X-Amz-Target", valid_603424
  var valid_603425 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603425 = validateParameter(valid_603425, JString, required = false,
                                 default = nil)
  if valid_603425 != nil:
    section.add "X-Amz-Content-Sha256", valid_603425
  var valid_603426 = header.getOrDefault("X-Amz-Algorithm")
  valid_603426 = validateParameter(valid_603426, JString, required = false,
                                 default = nil)
  if valid_603426 != nil:
    section.add "X-Amz-Algorithm", valid_603426
  var valid_603427 = header.getOrDefault("X-Amz-Signature")
  valid_603427 = validateParameter(valid_603427, JString, required = false,
                                 default = nil)
  if valid_603427 != nil:
    section.add "X-Amz-Signature", valid_603427
  var valid_603428 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603428 = validateParameter(valid_603428, JString, required = false,
                                 default = nil)
  if valid_603428 != nil:
    section.add "X-Amz-SignedHeaders", valid_603428
  var valid_603429 = header.getOrDefault("X-Amz-Credential")
  valid_603429 = validateParameter(valid_603429, JString, required = false,
                                 default = nil)
  if valid_603429 != nil:
    section.add "X-Amz-Credential", valid_603429
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603431: Call_DescribeActivations_603417; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes details about the activation, such as the date and time the activation was created, its expiration date, the IAM role assigned to the instances in the activation, and the number of instances registered by using this activation.
  ## 
  let valid = call_603431.validator(path, query, header, formData, body)
  let scheme = call_603431.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603431.url(scheme.get, call_603431.host, call_603431.base,
                         call_603431.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603431, url, valid)

proc call*(call_603432: Call_DescribeActivations_603417; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## describeActivations
  ## Describes details about the activation, such as the date and time the activation was created, its expiration date, the IAM role assigned to the instances in the activation, and the number of instances registered by using this activation.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_603433 = newJObject()
  var body_603434 = newJObject()
  add(query_603433, "NextToken", newJString(NextToken))
  if body != nil:
    body_603434 = body
  add(query_603433, "MaxResults", newJString(MaxResults))
  result = call_603432.call(nil, query_603433, nil, nil, body_603434)

var describeActivations* = Call_DescribeActivations_603417(
    name: "describeActivations", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeActivations",
    validator: validate_DescribeActivations_603418, base: "/",
    url: url_DescribeActivations_603419, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAssociation_603436 = ref object of OpenApiRestCall_602466
proc url_DescribeAssociation_603438(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeAssociation_603437(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Describes the association for the specified target or instance. If you created the association by using the <code>Targets</code> parameter, then you must retrieve the association by using the association ID. If you created the association by specifying an instance ID and a Systems Manager document, then you retrieve the association by specifying the document name and the instance ID. 
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
  var valid_603439 = header.getOrDefault("X-Amz-Date")
  valid_603439 = validateParameter(valid_603439, JString, required = false,
                                 default = nil)
  if valid_603439 != nil:
    section.add "X-Amz-Date", valid_603439
  var valid_603440 = header.getOrDefault("X-Amz-Security-Token")
  valid_603440 = validateParameter(valid_603440, JString, required = false,
                                 default = nil)
  if valid_603440 != nil:
    section.add "X-Amz-Security-Token", valid_603440
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603441 = header.getOrDefault("X-Amz-Target")
  valid_603441 = validateParameter(valid_603441, JString, required = true, default = newJString(
      "AmazonSSM.DescribeAssociation"))
  if valid_603441 != nil:
    section.add "X-Amz-Target", valid_603441
  var valid_603442 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603442 = validateParameter(valid_603442, JString, required = false,
                                 default = nil)
  if valid_603442 != nil:
    section.add "X-Amz-Content-Sha256", valid_603442
  var valid_603443 = header.getOrDefault("X-Amz-Algorithm")
  valid_603443 = validateParameter(valid_603443, JString, required = false,
                                 default = nil)
  if valid_603443 != nil:
    section.add "X-Amz-Algorithm", valid_603443
  var valid_603444 = header.getOrDefault("X-Amz-Signature")
  valid_603444 = validateParameter(valid_603444, JString, required = false,
                                 default = nil)
  if valid_603444 != nil:
    section.add "X-Amz-Signature", valid_603444
  var valid_603445 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603445 = validateParameter(valid_603445, JString, required = false,
                                 default = nil)
  if valid_603445 != nil:
    section.add "X-Amz-SignedHeaders", valid_603445
  var valid_603446 = header.getOrDefault("X-Amz-Credential")
  valid_603446 = validateParameter(valid_603446, JString, required = false,
                                 default = nil)
  if valid_603446 != nil:
    section.add "X-Amz-Credential", valid_603446
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603448: Call_DescribeAssociation_603436; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the association for the specified target or instance. If you created the association by using the <code>Targets</code> parameter, then you must retrieve the association by using the association ID. If you created the association by specifying an instance ID and a Systems Manager document, then you retrieve the association by specifying the document name and the instance ID. 
  ## 
  let valid = call_603448.validator(path, query, header, formData, body)
  let scheme = call_603448.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603448.url(scheme.get, call_603448.host, call_603448.base,
                         call_603448.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603448, url, valid)

proc call*(call_603449: Call_DescribeAssociation_603436; body: JsonNode): Recallable =
  ## describeAssociation
  ## Describes the association for the specified target or instance. If you created the association by using the <code>Targets</code> parameter, then you must retrieve the association by using the association ID. If you created the association by specifying an instance ID and a Systems Manager document, then you retrieve the association by specifying the document name and the instance ID. 
  ##   body: JObject (required)
  var body_603450 = newJObject()
  if body != nil:
    body_603450 = body
  result = call_603449.call(nil, nil, nil, nil, body_603450)

var describeAssociation* = Call_DescribeAssociation_603436(
    name: "describeAssociation", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeAssociation",
    validator: validate_DescribeAssociation_603437, base: "/",
    url: url_DescribeAssociation_603438, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAssociationExecutionTargets_603451 = ref object of OpenApiRestCall_602466
proc url_DescribeAssociationExecutionTargets_603453(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeAssociationExecutionTargets_603452(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Use this API action to view information about a specific execution of a specific association.
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
  var valid_603454 = header.getOrDefault("X-Amz-Date")
  valid_603454 = validateParameter(valid_603454, JString, required = false,
                                 default = nil)
  if valid_603454 != nil:
    section.add "X-Amz-Date", valid_603454
  var valid_603455 = header.getOrDefault("X-Amz-Security-Token")
  valid_603455 = validateParameter(valid_603455, JString, required = false,
                                 default = nil)
  if valid_603455 != nil:
    section.add "X-Amz-Security-Token", valid_603455
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603456 = header.getOrDefault("X-Amz-Target")
  valid_603456 = validateParameter(valid_603456, JString, required = true, default = newJString(
      "AmazonSSM.DescribeAssociationExecutionTargets"))
  if valid_603456 != nil:
    section.add "X-Amz-Target", valid_603456
  var valid_603457 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603457 = validateParameter(valid_603457, JString, required = false,
                                 default = nil)
  if valid_603457 != nil:
    section.add "X-Amz-Content-Sha256", valid_603457
  var valid_603458 = header.getOrDefault("X-Amz-Algorithm")
  valid_603458 = validateParameter(valid_603458, JString, required = false,
                                 default = nil)
  if valid_603458 != nil:
    section.add "X-Amz-Algorithm", valid_603458
  var valid_603459 = header.getOrDefault("X-Amz-Signature")
  valid_603459 = validateParameter(valid_603459, JString, required = false,
                                 default = nil)
  if valid_603459 != nil:
    section.add "X-Amz-Signature", valid_603459
  var valid_603460 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603460 = validateParameter(valid_603460, JString, required = false,
                                 default = nil)
  if valid_603460 != nil:
    section.add "X-Amz-SignedHeaders", valid_603460
  var valid_603461 = header.getOrDefault("X-Amz-Credential")
  valid_603461 = validateParameter(valid_603461, JString, required = false,
                                 default = nil)
  if valid_603461 != nil:
    section.add "X-Amz-Credential", valid_603461
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603463: Call_DescribeAssociationExecutionTargets_603451;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Use this API action to view information about a specific execution of a specific association.
  ## 
  let valid = call_603463.validator(path, query, header, formData, body)
  let scheme = call_603463.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603463.url(scheme.get, call_603463.host, call_603463.base,
                         call_603463.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603463, url, valid)

proc call*(call_603464: Call_DescribeAssociationExecutionTargets_603451;
          body: JsonNode): Recallable =
  ## describeAssociationExecutionTargets
  ## Use this API action to view information about a specific execution of a specific association.
  ##   body: JObject (required)
  var body_603465 = newJObject()
  if body != nil:
    body_603465 = body
  result = call_603464.call(nil, nil, nil, nil, body_603465)

var describeAssociationExecutionTargets* = Call_DescribeAssociationExecutionTargets_603451(
    name: "describeAssociationExecutionTargets", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeAssociationExecutionTargets",
    validator: validate_DescribeAssociationExecutionTargets_603452, base: "/",
    url: url_DescribeAssociationExecutionTargets_603453,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAssociationExecutions_603466 = ref object of OpenApiRestCall_602466
proc url_DescribeAssociationExecutions_603468(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeAssociationExecutions_603467(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Use this API action to view all executions for a specific association ID. 
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
  var valid_603469 = header.getOrDefault("X-Amz-Date")
  valid_603469 = validateParameter(valid_603469, JString, required = false,
                                 default = nil)
  if valid_603469 != nil:
    section.add "X-Amz-Date", valid_603469
  var valid_603470 = header.getOrDefault("X-Amz-Security-Token")
  valid_603470 = validateParameter(valid_603470, JString, required = false,
                                 default = nil)
  if valid_603470 != nil:
    section.add "X-Amz-Security-Token", valid_603470
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603471 = header.getOrDefault("X-Amz-Target")
  valid_603471 = validateParameter(valid_603471, JString, required = true, default = newJString(
      "AmazonSSM.DescribeAssociationExecutions"))
  if valid_603471 != nil:
    section.add "X-Amz-Target", valid_603471
  var valid_603472 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603472 = validateParameter(valid_603472, JString, required = false,
                                 default = nil)
  if valid_603472 != nil:
    section.add "X-Amz-Content-Sha256", valid_603472
  var valid_603473 = header.getOrDefault("X-Amz-Algorithm")
  valid_603473 = validateParameter(valid_603473, JString, required = false,
                                 default = nil)
  if valid_603473 != nil:
    section.add "X-Amz-Algorithm", valid_603473
  var valid_603474 = header.getOrDefault("X-Amz-Signature")
  valid_603474 = validateParameter(valid_603474, JString, required = false,
                                 default = nil)
  if valid_603474 != nil:
    section.add "X-Amz-Signature", valid_603474
  var valid_603475 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603475 = validateParameter(valid_603475, JString, required = false,
                                 default = nil)
  if valid_603475 != nil:
    section.add "X-Amz-SignedHeaders", valid_603475
  var valid_603476 = header.getOrDefault("X-Amz-Credential")
  valid_603476 = validateParameter(valid_603476, JString, required = false,
                                 default = nil)
  if valid_603476 != nil:
    section.add "X-Amz-Credential", valid_603476
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603478: Call_DescribeAssociationExecutions_603466; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Use this API action to view all executions for a specific association ID. 
  ## 
  let valid = call_603478.validator(path, query, header, formData, body)
  let scheme = call_603478.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603478.url(scheme.get, call_603478.host, call_603478.base,
                         call_603478.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603478, url, valid)

proc call*(call_603479: Call_DescribeAssociationExecutions_603466; body: JsonNode): Recallable =
  ## describeAssociationExecutions
  ## Use this API action to view all executions for a specific association ID. 
  ##   body: JObject (required)
  var body_603480 = newJObject()
  if body != nil:
    body_603480 = body
  result = call_603479.call(nil, nil, nil, nil, body_603480)

var describeAssociationExecutions* = Call_DescribeAssociationExecutions_603466(
    name: "describeAssociationExecutions", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeAssociationExecutions",
    validator: validate_DescribeAssociationExecutions_603467, base: "/",
    url: url_DescribeAssociationExecutions_603468,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAutomationExecutions_603481 = ref object of OpenApiRestCall_602466
proc url_DescribeAutomationExecutions_603483(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeAutomationExecutions_603482(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Provides details about all active and terminated Automation executions.
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
  var valid_603484 = header.getOrDefault("X-Amz-Date")
  valid_603484 = validateParameter(valid_603484, JString, required = false,
                                 default = nil)
  if valid_603484 != nil:
    section.add "X-Amz-Date", valid_603484
  var valid_603485 = header.getOrDefault("X-Amz-Security-Token")
  valid_603485 = validateParameter(valid_603485, JString, required = false,
                                 default = nil)
  if valid_603485 != nil:
    section.add "X-Amz-Security-Token", valid_603485
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603486 = header.getOrDefault("X-Amz-Target")
  valid_603486 = validateParameter(valid_603486, JString, required = true, default = newJString(
      "AmazonSSM.DescribeAutomationExecutions"))
  if valid_603486 != nil:
    section.add "X-Amz-Target", valid_603486
  var valid_603487 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603487 = validateParameter(valid_603487, JString, required = false,
                                 default = nil)
  if valid_603487 != nil:
    section.add "X-Amz-Content-Sha256", valid_603487
  var valid_603488 = header.getOrDefault("X-Amz-Algorithm")
  valid_603488 = validateParameter(valid_603488, JString, required = false,
                                 default = nil)
  if valid_603488 != nil:
    section.add "X-Amz-Algorithm", valid_603488
  var valid_603489 = header.getOrDefault("X-Amz-Signature")
  valid_603489 = validateParameter(valid_603489, JString, required = false,
                                 default = nil)
  if valid_603489 != nil:
    section.add "X-Amz-Signature", valid_603489
  var valid_603490 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603490 = validateParameter(valid_603490, JString, required = false,
                                 default = nil)
  if valid_603490 != nil:
    section.add "X-Amz-SignedHeaders", valid_603490
  var valid_603491 = header.getOrDefault("X-Amz-Credential")
  valid_603491 = validateParameter(valid_603491, JString, required = false,
                                 default = nil)
  if valid_603491 != nil:
    section.add "X-Amz-Credential", valid_603491
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603493: Call_DescribeAutomationExecutions_603481; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provides details about all active and terminated Automation executions.
  ## 
  let valid = call_603493.validator(path, query, header, formData, body)
  let scheme = call_603493.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603493.url(scheme.get, call_603493.host, call_603493.base,
                         call_603493.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603493, url, valid)

proc call*(call_603494: Call_DescribeAutomationExecutions_603481; body: JsonNode): Recallable =
  ## describeAutomationExecutions
  ## Provides details about all active and terminated Automation executions.
  ##   body: JObject (required)
  var body_603495 = newJObject()
  if body != nil:
    body_603495 = body
  result = call_603494.call(nil, nil, nil, nil, body_603495)

var describeAutomationExecutions* = Call_DescribeAutomationExecutions_603481(
    name: "describeAutomationExecutions", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeAutomationExecutions",
    validator: validate_DescribeAutomationExecutions_603482, base: "/",
    url: url_DescribeAutomationExecutions_603483,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAutomationStepExecutions_603496 = ref object of OpenApiRestCall_602466
proc url_DescribeAutomationStepExecutions_603498(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeAutomationStepExecutions_603497(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Information about all active and terminated step executions in an Automation workflow.
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
  var valid_603499 = header.getOrDefault("X-Amz-Date")
  valid_603499 = validateParameter(valid_603499, JString, required = false,
                                 default = nil)
  if valid_603499 != nil:
    section.add "X-Amz-Date", valid_603499
  var valid_603500 = header.getOrDefault("X-Amz-Security-Token")
  valid_603500 = validateParameter(valid_603500, JString, required = false,
                                 default = nil)
  if valid_603500 != nil:
    section.add "X-Amz-Security-Token", valid_603500
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603501 = header.getOrDefault("X-Amz-Target")
  valid_603501 = validateParameter(valid_603501, JString, required = true, default = newJString(
      "AmazonSSM.DescribeAutomationStepExecutions"))
  if valid_603501 != nil:
    section.add "X-Amz-Target", valid_603501
  var valid_603502 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603502 = validateParameter(valid_603502, JString, required = false,
                                 default = nil)
  if valid_603502 != nil:
    section.add "X-Amz-Content-Sha256", valid_603502
  var valid_603503 = header.getOrDefault("X-Amz-Algorithm")
  valid_603503 = validateParameter(valid_603503, JString, required = false,
                                 default = nil)
  if valid_603503 != nil:
    section.add "X-Amz-Algorithm", valid_603503
  var valid_603504 = header.getOrDefault("X-Amz-Signature")
  valid_603504 = validateParameter(valid_603504, JString, required = false,
                                 default = nil)
  if valid_603504 != nil:
    section.add "X-Amz-Signature", valid_603504
  var valid_603505 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603505 = validateParameter(valid_603505, JString, required = false,
                                 default = nil)
  if valid_603505 != nil:
    section.add "X-Amz-SignedHeaders", valid_603505
  var valid_603506 = header.getOrDefault("X-Amz-Credential")
  valid_603506 = validateParameter(valid_603506, JString, required = false,
                                 default = nil)
  if valid_603506 != nil:
    section.add "X-Amz-Credential", valid_603506
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603508: Call_DescribeAutomationStepExecutions_603496;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Information about all active and terminated step executions in an Automation workflow.
  ## 
  let valid = call_603508.validator(path, query, header, formData, body)
  let scheme = call_603508.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603508.url(scheme.get, call_603508.host, call_603508.base,
                         call_603508.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603508, url, valid)

proc call*(call_603509: Call_DescribeAutomationStepExecutions_603496;
          body: JsonNode): Recallable =
  ## describeAutomationStepExecutions
  ## Information about all active and terminated step executions in an Automation workflow.
  ##   body: JObject (required)
  var body_603510 = newJObject()
  if body != nil:
    body_603510 = body
  result = call_603509.call(nil, nil, nil, nil, body_603510)

var describeAutomationStepExecutions* = Call_DescribeAutomationStepExecutions_603496(
    name: "describeAutomationStepExecutions", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeAutomationStepExecutions",
    validator: validate_DescribeAutomationStepExecutions_603497, base: "/",
    url: url_DescribeAutomationStepExecutions_603498,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAvailablePatches_603511 = ref object of OpenApiRestCall_602466
proc url_DescribeAvailablePatches_603513(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeAvailablePatches_603512(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists all patches eligible to be included in a patch baseline.
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
  var valid_603514 = header.getOrDefault("X-Amz-Date")
  valid_603514 = validateParameter(valid_603514, JString, required = false,
                                 default = nil)
  if valid_603514 != nil:
    section.add "X-Amz-Date", valid_603514
  var valid_603515 = header.getOrDefault("X-Amz-Security-Token")
  valid_603515 = validateParameter(valid_603515, JString, required = false,
                                 default = nil)
  if valid_603515 != nil:
    section.add "X-Amz-Security-Token", valid_603515
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603516 = header.getOrDefault("X-Amz-Target")
  valid_603516 = validateParameter(valid_603516, JString, required = true, default = newJString(
      "AmazonSSM.DescribeAvailablePatches"))
  if valid_603516 != nil:
    section.add "X-Amz-Target", valid_603516
  var valid_603517 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603517 = validateParameter(valid_603517, JString, required = false,
                                 default = nil)
  if valid_603517 != nil:
    section.add "X-Amz-Content-Sha256", valid_603517
  var valid_603518 = header.getOrDefault("X-Amz-Algorithm")
  valid_603518 = validateParameter(valid_603518, JString, required = false,
                                 default = nil)
  if valid_603518 != nil:
    section.add "X-Amz-Algorithm", valid_603518
  var valid_603519 = header.getOrDefault("X-Amz-Signature")
  valid_603519 = validateParameter(valid_603519, JString, required = false,
                                 default = nil)
  if valid_603519 != nil:
    section.add "X-Amz-Signature", valid_603519
  var valid_603520 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603520 = validateParameter(valid_603520, JString, required = false,
                                 default = nil)
  if valid_603520 != nil:
    section.add "X-Amz-SignedHeaders", valid_603520
  var valid_603521 = header.getOrDefault("X-Amz-Credential")
  valid_603521 = validateParameter(valid_603521, JString, required = false,
                                 default = nil)
  if valid_603521 != nil:
    section.add "X-Amz-Credential", valid_603521
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603523: Call_DescribeAvailablePatches_603511; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all patches eligible to be included in a patch baseline.
  ## 
  let valid = call_603523.validator(path, query, header, formData, body)
  let scheme = call_603523.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603523.url(scheme.get, call_603523.host, call_603523.base,
                         call_603523.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603523, url, valid)

proc call*(call_603524: Call_DescribeAvailablePatches_603511; body: JsonNode): Recallable =
  ## describeAvailablePatches
  ## Lists all patches eligible to be included in a patch baseline.
  ##   body: JObject (required)
  var body_603525 = newJObject()
  if body != nil:
    body_603525 = body
  result = call_603524.call(nil, nil, nil, nil, body_603525)

var describeAvailablePatches* = Call_DescribeAvailablePatches_603511(
    name: "describeAvailablePatches", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeAvailablePatches",
    validator: validate_DescribeAvailablePatches_603512, base: "/",
    url: url_DescribeAvailablePatches_603513, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDocument_603526 = ref object of OpenApiRestCall_602466
proc url_DescribeDocument_603528(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeDocument_603527(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Describes the specified Systems Manager document.
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
  var valid_603529 = header.getOrDefault("X-Amz-Date")
  valid_603529 = validateParameter(valid_603529, JString, required = false,
                                 default = nil)
  if valid_603529 != nil:
    section.add "X-Amz-Date", valid_603529
  var valid_603530 = header.getOrDefault("X-Amz-Security-Token")
  valid_603530 = validateParameter(valid_603530, JString, required = false,
                                 default = nil)
  if valid_603530 != nil:
    section.add "X-Amz-Security-Token", valid_603530
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603531 = header.getOrDefault("X-Amz-Target")
  valid_603531 = validateParameter(valid_603531, JString, required = true, default = newJString(
      "AmazonSSM.DescribeDocument"))
  if valid_603531 != nil:
    section.add "X-Amz-Target", valid_603531
  var valid_603532 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603532 = validateParameter(valid_603532, JString, required = false,
                                 default = nil)
  if valid_603532 != nil:
    section.add "X-Amz-Content-Sha256", valid_603532
  var valid_603533 = header.getOrDefault("X-Amz-Algorithm")
  valid_603533 = validateParameter(valid_603533, JString, required = false,
                                 default = nil)
  if valid_603533 != nil:
    section.add "X-Amz-Algorithm", valid_603533
  var valid_603534 = header.getOrDefault("X-Amz-Signature")
  valid_603534 = validateParameter(valid_603534, JString, required = false,
                                 default = nil)
  if valid_603534 != nil:
    section.add "X-Amz-Signature", valid_603534
  var valid_603535 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603535 = validateParameter(valid_603535, JString, required = false,
                                 default = nil)
  if valid_603535 != nil:
    section.add "X-Amz-SignedHeaders", valid_603535
  var valid_603536 = header.getOrDefault("X-Amz-Credential")
  valid_603536 = validateParameter(valid_603536, JString, required = false,
                                 default = nil)
  if valid_603536 != nil:
    section.add "X-Amz-Credential", valid_603536
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603538: Call_DescribeDocument_603526; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the specified Systems Manager document.
  ## 
  let valid = call_603538.validator(path, query, header, formData, body)
  let scheme = call_603538.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603538.url(scheme.get, call_603538.host, call_603538.base,
                         call_603538.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603538, url, valid)

proc call*(call_603539: Call_DescribeDocument_603526; body: JsonNode): Recallable =
  ## describeDocument
  ## Describes the specified Systems Manager document.
  ##   body: JObject (required)
  var body_603540 = newJObject()
  if body != nil:
    body_603540 = body
  result = call_603539.call(nil, nil, nil, nil, body_603540)

var describeDocument* = Call_DescribeDocument_603526(name: "describeDocument",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeDocument",
    validator: validate_DescribeDocument_603527, base: "/",
    url: url_DescribeDocument_603528, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDocumentPermission_603541 = ref object of OpenApiRestCall_602466
proc url_DescribeDocumentPermission_603543(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeDocumentPermission_603542(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Describes the permissions for a Systems Manager document. If you created the document, you are the owner. If a document is shared, it can either be shared privately (by specifying a user's AWS account ID) or publicly (<i>All</i>). 
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
  var valid_603544 = header.getOrDefault("X-Amz-Date")
  valid_603544 = validateParameter(valid_603544, JString, required = false,
                                 default = nil)
  if valid_603544 != nil:
    section.add "X-Amz-Date", valid_603544
  var valid_603545 = header.getOrDefault("X-Amz-Security-Token")
  valid_603545 = validateParameter(valid_603545, JString, required = false,
                                 default = nil)
  if valid_603545 != nil:
    section.add "X-Amz-Security-Token", valid_603545
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603546 = header.getOrDefault("X-Amz-Target")
  valid_603546 = validateParameter(valid_603546, JString, required = true, default = newJString(
      "AmazonSSM.DescribeDocumentPermission"))
  if valid_603546 != nil:
    section.add "X-Amz-Target", valid_603546
  var valid_603547 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603547 = validateParameter(valid_603547, JString, required = false,
                                 default = nil)
  if valid_603547 != nil:
    section.add "X-Amz-Content-Sha256", valid_603547
  var valid_603548 = header.getOrDefault("X-Amz-Algorithm")
  valid_603548 = validateParameter(valid_603548, JString, required = false,
                                 default = nil)
  if valid_603548 != nil:
    section.add "X-Amz-Algorithm", valid_603548
  var valid_603549 = header.getOrDefault("X-Amz-Signature")
  valid_603549 = validateParameter(valid_603549, JString, required = false,
                                 default = nil)
  if valid_603549 != nil:
    section.add "X-Amz-Signature", valid_603549
  var valid_603550 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603550 = validateParameter(valid_603550, JString, required = false,
                                 default = nil)
  if valid_603550 != nil:
    section.add "X-Amz-SignedHeaders", valid_603550
  var valid_603551 = header.getOrDefault("X-Amz-Credential")
  valid_603551 = validateParameter(valid_603551, JString, required = false,
                                 default = nil)
  if valid_603551 != nil:
    section.add "X-Amz-Credential", valid_603551
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603553: Call_DescribeDocumentPermission_603541; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the permissions for a Systems Manager document. If you created the document, you are the owner. If a document is shared, it can either be shared privately (by specifying a user's AWS account ID) or publicly (<i>All</i>). 
  ## 
  let valid = call_603553.validator(path, query, header, formData, body)
  let scheme = call_603553.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603553.url(scheme.get, call_603553.host, call_603553.base,
                         call_603553.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603553, url, valid)

proc call*(call_603554: Call_DescribeDocumentPermission_603541; body: JsonNode): Recallable =
  ## describeDocumentPermission
  ## Describes the permissions for a Systems Manager document. If you created the document, you are the owner. If a document is shared, it can either be shared privately (by specifying a user's AWS account ID) or publicly (<i>All</i>). 
  ##   body: JObject (required)
  var body_603555 = newJObject()
  if body != nil:
    body_603555 = body
  result = call_603554.call(nil, nil, nil, nil, body_603555)

var describeDocumentPermission* = Call_DescribeDocumentPermission_603541(
    name: "describeDocumentPermission", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeDocumentPermission",
    validator: validate_DescribeDocumentPermission_603542, base: "/",
    url: url_DescribeDocumentPermission_603543,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEffectiveInstanceAssociations_603556 = ref object of OpenApiRestCall_602466
proc url_DescribeEffectiveInstanceAssociations_603558(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeEffectiveInstanceAssociations_603557(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## All associations for the instance(s).
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
  var valid_603559 = header.getOrDefault("X-Amz-Date")
  valid_603559 = validateParameter(valid_603559, JString, required = false,
                                 default = nil)
  if valid_603559 != nil:
    section.add "X-Amz-Date", valid_603559
  var valid_603560 = header.getOrDefault("X-Amz-Security-Token")
  valid_603560 = validateParameter(valid_603560, JString, required = false,
                                 default = nil)
  if valid_603560 != nil:
    section.add "X-Amz-Security-Token", valid_603560
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603561 = header.getOrDefault("X-Amz-Target")
  valid_603561 = validateParameter(valid_603561, JString, required = true, default = newJString(
      "AmazonSSM.DescribeEffectiveInstanceAssociations"))
  if valid_603561 != nil:
    section.add "X-Amz-Target", valid_603561
  var valid_603562 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603562 = validateParameter(valid_603562, JString, required = false,
                                 default = nil)
  if valid_603562 != nil:
    section.add "X-Amz-Content-Sha256", valid_603562
  var valid_603563 = header.getOrDefault("X-Amz-Algorithm")
  valid_603563 = validateParameter(valid_603563, JString, required = false,
                                 default = nil)
  if valid_603563 != nil:
    section.add "X-Amz-Algorithm", valid_603563
  var valid_603564 = header.getOrDefault("X-Amz-Signature")
  valid_603564 = validateParameter(valid_603564, JString, required = false,
                                 default = nil)
  if valid_603564 != nil:
    section.add "X-Amz-Signature", valid_603564
  var valid_603565 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603565 = validateParameter(valid_603565, JString, required = false,
                                 default = nil)
  if valid_603565 != nil:
    section.add "X-Amz-SignedHeaders", valid_603565
  var valid_603566 = header.getOrDefault("X-Amz-Credential")
  valid_603566 = validateParameter(valid_603566, JString, required = false,
                                 default = nil)
  if valid_603566 != nil:
    section.add "X-Amz-Credential", valid_603566
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603568: Call_DescribeEffectiveInstanceAssociations_603556;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## All associations for the instance(s).
  ## 
  let valid = call_603568.validator(path, query, header, formData, body)
  let scheme = call_603568.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603568.url(scheme.get, call_603568.host, call_603568.base,
                         call_603568.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603568, url, valid)

proc call*(call_603569: Call_DescribeEffectiveInstanceAssociations_603556;
          body: JsonNode): Recallable =
  ## describeEffectiveInstanceAssociations
  ## All associations for the instance(s).
  ##   body: JObject (required)
  var body_603570 = newJObject()
  if body != nil:
    body_603570 = body
  result = call_603569.call(nil, nil, nil, nil, body_603570)

var describeEffectiveInstanceAssociations* = Call_DescribeEffectiveInstanceAssociations_603556(
    name: "describeEffectiveInstanceAssociations", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeEffectiveInstanceAssociations",
    validator: validate_DescribeEffectiveInstanceAssociations_603557, base: "/",
    url: url_DescribeEffectiveInstanceAssociations_603558,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEffectivePatchesForPatchBaseline_603571 = ref object of OpenApiRestCall_602466
proc url_DescribeEffectivePatchesForPatchBaseline_603573(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeEffectivePatchesForPatchBaseline_603572(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves the current effective patches (the patch and the approval state) for the specified patch baseline. Note that this API applies only to Windows patch baselines.
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
  var valid_603574 = header.getOrDefault("X-Amz-Date")
  valid_603574 = validateParameter(valid_603574, JString, required = false,
                                 default = nil)
  if valid_603574 != nil:
    section.add "X-Amz-Date", valid_603574
  var valid_603575 = header.getOrDefault("X-Amz-Security-Token")
  valid_603575 = validateParameter(valid_603575, JString, required = false,
                                 default = nil)
  if valid_603575 != nil:
    section.add "X-Amz-Security-Token", valid_603575
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603576 = header.getOrDefault("X-Amz-Target")
  valid_603576 = validateParameter(valid_603576, JString, required = true, default = newJString(
      "AmazonSSM.DescribeEffectivePatchesForPatchBaseline"))
  if valid_603576 != nil:
    section.add "X-Amz-Target", valid_603576
  var valid_603577 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603577 = validateParameter(valid_603577, JString, required = false,
                                 default = nil)
  if valid_603577 != nil:
    section.add "X-Amz-Content-Sha256", valid_603577
  var valid_603578 = header.getOrDefault("X-Amz-Algorithm")
  valid_603578 = validateParameter(valid_603578, JString, required = false,
                                 default = nil)
  if valid_603578 != nil:
    section.add "X-Amz-Algorithm", valid_603578
  var valid_603579 = header.getOrDefault("X-Amz-Signature")
  valid_603579 = validateParameter(valid_603579, JString, required = false,
                                 default = nil)
  if valid_603579 != nil:
    section.add "X-Amz-Signature", valid_603579
  var valid_603580 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603580 = validateParameter(valid_603580, JString, required = false,
                                 default = nil)
  if valid_603580 != nil:
    section.add "X-Amz-SignedHeaders", valid_603580
  var valid_603581 = header.getOrDefault("X-Amz-Credential")
  valid_603581 = validateParameter(valid_603581, JString, required = false,
                                 default = nil)
  if valid_603581 != nil:
    section.add "X-Amz-Credential", valid_603581
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603583: Call_DescribeEffectivePatchesForPatchBaseline_603571;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves the current effective patches (the patch and the approval state) for the specified patch baseline. Note that this API applies only to Windows patch baselines.
  ## 
  let valid = call_603583.validator(path, query, header, formData, body)
  let scheme = call_603583.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603583.url(scheme.get, call_603583.host, call_603583.base,
                         call_603583.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603583, url, valid)

proc call*(call_603584: Call_DescribeEffectivePatchesForPatchBaseline_603571;
          body: JsonNode): Recallable =
  ## describeEffectivePatchesForPatchBaseline
  ## Retrieves the current effective patches (the patch and the approval state) for the specified patch baseline. Note that this API applies only to Windows patch baselines.
  ##   body: JObject (required)
  var body_603585 = newJObject()
  if body != nil:
    body_603585 = body
  result = call_603584.call(nil, nil, nil, nil, body_603585)

var describeEffectivePatchesForPatchBaseline* = Call_DescribeEffectivePatchesForPatchBaseline_603571(
    name: "describeEffectivePatchesForPatchBaseline", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeEffectivePatchesForPatchBaseline",
    validator: validate_DescribeEffectivePatchesForPatchBaseline_603572,
    base: "/", url: url_DescribeEffectivePatchesForPatchBaseline_603573,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeInstanceAssociationsStatus_603586 = ref object of OpenApiRestCall_602466
proc url_DescribeInstanceAssociationsStatus_603588(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeInstanceAssociationsStatus_603587(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## The status of the associations for the instance(s).
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
  var valid_603589 = header.getOrDefault("X-Amz-Date")
  valid_603589 = validateParameter(valid_603589, JString, required = false,
                                 default = nil)
  if valid_603589 != nil:
    section.add "X-Amz-Date", valid_603589
  var valid_603590 = header.getOrDefault("X-Amz-Security-Token")
  valid_603590 = validateParameter(valid_603590, JString, required = false,
                                 default = nil)
  if valid_603590 != nil:
    section.add "X-Amz-Security-Token", valid_603590
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603591 = header.getOrDefault("X-Amz-Target")
  valid_603591 = validateParameter(valid_603591, JString, required = true, default = newJString(
      "AmazonSSM.DescribeInstanceAssociationsStatus"))
  if valid_603591 != nil:
    section.add "X-Amz-Target", valid_603591
  var valid_603592 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603592 = validateParameter(valid_603592, JString, required = false,
                                 default = nil)
  if valid_603592 != nil:
    section.add "X-Amz-Content-Sha256", valid_603592
  var valid_603593 = header.getOrDefault("X-Amz-Algorithm")
  valid_603593 = validateParameter(valid_603593, JString, required = false,
                                 default = nil)
  if valid_603593 != nil:
    section.add "X-Amz-Algorithm", valid_603593
  var valid_603594 = header.getOrDefault("X-Amz-Signature")
  valid_603594 = validateParameter(valid_603594, JString, required = false,
                                 default = nil)
  if valid_603594 != nil:
    section.add "X-Amz-Signature", valid_603594
  var valid_603595 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603595 = validateParameter(valid_603595, JString, required = false,
                                 default = nil)
  if valid_603595 != nil:
    section.add "X-Amz-SignedHeaders", valid_603595
  var valid_603596 = header.getOrDefault("X-Amz-Credential")
  valid_603596 = validateParameter(valid_603596, JString, required = false,
                                 default = nil)
  if valid_603596 != nil:
    section.add "X-Amz-Credential", valid_603596
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603598: Call_DescribeInstanceAssociationsStatus_603586;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## The status of the associations for the instance(s).
  ## 
  let valid = call_603598.validator(path, query, header, formData, body)
  let scheme = call_603598.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603598.url(scheme.get, call_603598.host, call_603598.base,
                         call_603598.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603598, url, valid)

proc call*(call_603599: Call_DescribeInstanceAssociationsStatus_603586;
          body: JsonNode): Recallable =
  ## describeInstanceAssociationsStatus
  ## The status of the associations for the instance(s).
  ##   body: JObject (required)
  var body_603600 = newJObject()
  if body != nil:
    body_603600 = body
  result = call_603599.call(nil, nil, nil, nil, body_603600)

var describeInstanceAssociationsStatus* = Call_DescribeInstanceAssociationsStatus_603586(
    name: "describeInstanceAssociationsStatus", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeInstanceAssociationsStatus",
    validator: validate_DescribeInstanceAssociationsStatus_603587, base: "/",
    url: url_DescribeInstanceAssociationsStatus_603588,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeInstanceInformation_603601 = ref object of OpenApiRestCall_602466
proc url_DescribeInstanceInformation_603603(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeInstanceInformation_603602(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Describes one or more of your instances. You can use this to get information about instances like the operating system platform, the SSM Agent version (Linux), status etc. If you specify one or more instance IDs, it returns information for those instances. If you do not specify instance IDs, it returns information for all your instances. If you specify an instance ID that is not valid or an instance that you do not own, you receive an error. </p> <note> <p>The IamRole field for this API action is the Amazon Identity and Access Management (IAM) role assigned to on-premises instances. This call does not return the IAM role for Amazon EC2 instances.</p> </note>
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
  var valid_603604 = query.getOrDefault("NextToken")
  valid_603604 = validateParameter(valid_603604, JString, required = false,
                                 default = nil)
  if valid_603604 != nil:
    section.add "NextToken", valid_603604
  var valid_603605 = query.getOrDefault("MaxResults")
  valid_603605 = validateParameter(valid_603605, JString, required = false,
                                 default = nil)
  if valid_603605 != nil:
    section.add "MaxResults", valid_603605
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
  var valid_603606 = header.getOrDefault("X-Amz-Date")
  valid_603606 = validateParameter(valid_603606, JString, required = false,
                                 default = nil)
  if valid_603606 != nil:
    section.add "X-Amz-Date", valid_603606
  var valid_603607 = header.getOrDefault("X-Amz-Security-Token")
  valid_603607 = validateParameter(valid_603607, JString, required = false,
                                 default = nil)
  if valid_603607 != nil:
    section.add "X-Amz-Security-Token", valid_603607
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603608 = header.getOrDefault("X-Amz-Target")
  valid_603608 = validateParameter(valid_603608, JString, required = true, default = newJString(
      "AmazonSSM.DescribeInstanceInformation"))
  if valid_603608 != nil:
    section.add "X-Amz-Target", valid_603608
  var valid_603609 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603609 = validateParameter(valid_603609, JString, required = false,
                                 default = nil)
  if valid_603609 != nil:
    section.add "X-Amz-Content-Sha256", valid_603609
  var valid_603610 = header.getOrDefault("X-Amz-Algorithm")
  valid_603610 = validateParameter(valid_603610, JString, required = false,
                                 default = nil)
  if valid_603610 != nil:
    section.add "X-Amz-Algorithm", valid_603610
  var valid_603611 = header.getOrDefault("X-Amz-Signature")
  valid_603611 = validateParameter(valid_603611, JString, required = false,
                                 default = nil)
  if valid_603611 != nil:
    section.add "X-Amz-Signature", valid_603611
  var valid_603612 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603612 = validateParameter(valid_603612, JString, required = false,
                                 default = nil)
  if valid_603612 != nil:
    section.add "X-Amz-SignedHeaders", valid_603612
  var valid_603613 = header.getOrDefault("X-Amz-Credential")
  valid_603613 = validateParameter(valid_603613, JString, required = false,
                                 default = nil)
  if valid_603613 != nil:
    section.add "X-Amz-Credential", valid_603613
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603615: Call_DescribeInstanceInformation_603601; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes one or more of your instances. You can use this to get information about instances like the operating system platform, the SSM Agent version (Linux), status etc. If you specify one or more instance IDs, it returns information for those instances. If you do not specify instance IDs, it returns information for all your instances. If you specify an instance ID that is not valid or an instance that you do not own, you receive an error. </p> <note> <p>The IamRole field for this API action is the Amazon Identity and Access Management (IAM) role assigned to on-premises instances. This call does not return the IAM role for Amazon EC2 instances.</p> </note>
  ## 
  let valid = call_603615.validator(path, query, header, formData, body)
  let scheme = call_603615.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603615.url(scheme.get, call_603615.host, call_603615.base,
                         call_603615.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603615, url, valid)

proc call*(call_603616: Call_DescribeInstanceInformation_603601; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## describeInstanceInformation
  ## <p>Describes one or more of your instances. You can use this to get information about instances like the operating system platform, the SSM Agent version (Linux), status etc. If you specify one or more instance IDs, it returns information for those instances. If you do not specify instance IDs, it returns information for all your instances. If you specify an instance ID that is not valid or an instance that you do not own, you receive an error. </p> <note> <p>The IamRole field for this API action is the Amazon Identity and Access Management (IAM) role assigned to on-premises instances. This call does not return the IAM role for Amazon EC2 instances.</p> </note>
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_603617 = newJObject()
  var body_603618 = newJObject()
  add(query_603617, "NextToken", newJString(NextToken))
  if body != nil:
    body_603618 = body
  add(query_603617, "MaxResults", newJString(MaxResults))
  result = call_603616.call(nil, query_603617, nil, nil, body_603618)

var describeInstanceInformation* = Call_DescribeInstanceInformation_603601(
    name: "describeInstanceInformation", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeInstanceInformation",
    validator: validate_DescribeInstanceInformation_603602, base: "/",
    url: url_DescribeInstanceInformation_603603,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeInstancePatchStates_603619 = ref object of OpenApiRestCall_602466
proc url_DescribeInstancePatchStates_603621(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeInstancePatchStates_603620(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves the high-level patch state of one or more instances.
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
  var valid_603622 = header.getOrDefault("X-Amz-Date")
  valid_603622 = validateParameter(valid_603622, JString, required = false,
                                 default = nil)
  if valid_603622 != nil:
    section.add "X-Amz-Date", valid_603622
  var valid_603623 = header.getOrDefault("X-Amz-Security-Token")
  valid_603623 = validateParameter(valid_603623, JString, required = false,
                                 default = nil)
  if valid_603623 != nil:
    section.add "X-Amz-Security-Token", valid_603623
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603624 = header.getOrDefault("X-Amz-Target")
  valid_603624 = validateParameter(valid_603624, JString, required = true, default = newJString(
      "AmazonSSM.DescribeInstancePatchStates"))
  if valid_603624 != nil:
    section.add "X-Amz-Target", valid_603624
  var valid_603625 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603625 = validateParameter(valid_603625, JString, required = false,
                                 default = nil)
  if valid_603625 != nil:
    section.add "X-Amz-Content-Sha256", valid_603625
  var valid_603626 = header.getOrDefault("X-Amz-Algorithm")
  valid_603626 = validateParameter(valid_603626, JString, required = false,
                                 default = nil)
  if valid_603626 != nil:
    section.add "X-Amz-Algorithm", valid_603626
  var valid_603627 = header.getOrDefault("X-Amz-Signature")
  valid_603627 = validateParameter(valid_603627, JString, required = false,
                                 default = nil)
  if valid_603627 != nil:
    section.add "X-Amz-Signature", valid_603627
  var valid_603628 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603628 = validateParameter(valid_603628, JString, required = false,
                                 default = nil)
  if valid_603628 != nil:
    section.add "X-Amz-SignedHeaders", valid_603628
  var valid_603629 = header.getOrDefault("X-Amz-Credential")
  valid_603629 = validateParameter(valid_603629, JString, required = false,
                                 default = nil)
  if valid_603629 != nil:
    section.add "X-Amz-Credential", valid_603629
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603631: Call_DescribeInstancePatchStates_603619; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the high-level patch state of one or more instances.
  ## 
  let valid = call_603631.validator(path, query, header, formData, body)
  let scheme = call_603631.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603631.url(scheme.get, call_603631.host, call_603631.base,
                         call_603631.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603631, url, valid)

proc call*(call_603632: Call_DescribeInstancePatchStates_603619; body: JsonNode): Recallable =
  ## describeInstancePatchStates
  ## Retrieves the high-level patch state of one or more instances.
  ##   body: JObject (required)
  var body_603633 = newJObject()
  if body != nil:
    body_603633 = body
  result = call_603632.call(nil, nil, nil, nil, body_603633)

var describeInstancePatchStates* = Call_DescribeInstancePatchStates_603619(
    name: "describeInstancePatchStates", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeInstancePatchStates",
    validator: validate_DescribeInstancePatchStates_603620, base: "/",
    url: url_DescribeInstancePatchStates_603621,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeInstancePatchStatesForPatchGroup_603634 = ref object of OpenApiRestCall_602466
proc url_DescribeInstancePatchStatesForPatchGroup_603636(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeInstancePatchStatesForPatchGroup_603635(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves the high-level patch state for the instances in the specified patch group.
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
  var valid_603637 = header.getOrDefault("X-Amz-Date")
  valid_603637 = validateParameter(valid_603637, JString, required = false,
                                 default = nil)
  if valid_603637 != nil:
    section.add "X-Amz-Date", valid_603637
  var valid_603638 = header.getOrDefault("X-Amz-Security-Token")
  valid_603638 = validateParameter(valid_603638, JString, required = false,
                                 default = nil)
  if valid_603638 != nil:
    section.add "X-Amz-Security-Token", valid_603638
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603639 = header.getOrDefault("X-Amz-Target")
  valid_603639 = validateParameter(valid_603639, JString, required = true, default = newJString(
      "AmazonSSM.DescribeInstancePatchStatesForPatchGroup"))
  if valid_603639 != nil:
    section.add "X-Amz-Target", valid_603639
  var valid_603640 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603640 = validateParameter(valid_603640, JString, required = false,
                                 default = nil)
  if valid_603640 != nil:
    section.add "X-Amz-Content-Sha256", valid_603640
  var valid_603641 = header.getOrDefault("X-Amz-Algorithm")
  valid_603641 = validateParameter(valid_603641, JString, required = false,
                                 default = nil)
  if valid_603641 != nil:
    section.add "X-Amz-Algorithm", valid_603641
  var valid_603642 = header.getOrDefault("X-Amz-Signature")
  valid_603642 = validateParameter(valid_603642, JString, required = false,
                                 default = nil)
  if valid_603642 != nil:
    section.add "X-Amz-Signature", valid_603642
  var valid_603643 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603643 = validateParameter(valid_603643, JString, required = false,
                                 default = nil)
  if valid_603643 != nil:
    section.add "X-Amz-SignedHeaders", valid_603643
  var valid_603644 = header.getOrDefault("X-Amz-Credential")
  valid_603644 = validateParameter(valid_603644, JString, required = false,
                                 default = nil)
  if valid_603644 != nil:
    section.add "X-Amz-Credential", valid_603644
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603646: Call_DescribeInstancePatchStatesForPatchGroup_603634;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves the high-level patch state for the instances in the specified patch group.
  ## 
  let valid = call_603646.validator(path, query, header, formData, body)
  let scheme = call_603646.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603646.url(scheme.get, call_603646.host, call_603646.base,
                         call_603646.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603646, url, valid)

proc call*(call_603647: Call_DescribeInstancePatchStatesForPatchGroup_603634;
          body: JsonNode): Recallable =
  ## describeInstancePatchStatesForPatchGroup
  ## Retrieves the high-level patch state for the instances in the specified patch group.
  ##   body: JObject (required)
  var body_603648 = newJObject()
  if body != nil:
    body_603648 = body
  result = call_603647.call(nil, nil, nil, nil, body_603648)

var describeInstancePatchStatesForPatchGroup* = Call_DescribeInstancePatchStatesForPatchGroup_603634(
    name: "describeInstancePatchStatesForPatchGroup", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeInstancePatchStatesForPatchGroup",
    validator: validate_DescribeInstancePatchStatesForPatchGroup_603635,
    base: "/", url: url_DescribeInstancePatchStatesForPatchGroup_603636,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeInstancePatches_603649 = ref object of OpenApiRestCall_602466
proc url_DescribeInstancePatches_603651(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeInstancePatches_603650(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves information about the patches on the specified instance and their state relative to the patch baseline being used for the instance.
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
  var valid_603652 = header.getOrDefault("X-Amz-Date")
  valid_603652 = validateParameter(valid_603652, JString, required = false,
                                 default = nil)
  if valid_603652 != nil:
    section.add "X-Amz-Date", valid_603652
  var valid_603653 = header.getOrDefault("X-Amz-Security-Token")
  valid_603653 = validateParameter(valid_603653, JString, required = false,
                                 default = nil)
  if valid_603653 != nil:
    section.add "X-Amz-Security-Token", valid_603653
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603654 = header.getOrDefault("X-Amz-Target")
  valid_603654 = validateParameter(valid_603654, JString, required = true, default = newJString(
      "AmazonSSM.DescribeInstancePatches"))
  if valid_603654 != nil:
    section.add "X-Amz-Target", valid_603654
  var valid_603655 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603655 = validateParameter(valid_603655, JString, required = false,
                                 default = nil)
  if valid_603655 != nil:
    section.add "X-Amz-Content-Sha256", valid_603655
  var valid_603656 = header.getOrDefault("X-Amz-Algorithm")
  valid_603656 = validateParameter(valid_603656, JString, required = false,
                                 default = nil)
  if valid_603656 != nil:
    section.add "X-Amz-Algorithm", valid_603656
  var valid_603657 = header.getOrDefault("X-Amz-Signature")
  valid_603657 = validateParameter(valid_603657, JString, required = false,
                                 default = nil)
  if valid_603657 != nil:
    section.add "X-Amz-Signature", valid_603657
  var valid_603658 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603658 = validateParameter(valid_603658, JString, required = false,
                                 default = nil)
  if valid_603658 != nil:
    section.add "X-Amz-SignedHeaders", valid_603658
  var valid_603659 = header.getOrDefault("X-Amz-Credential")
  valid_603659 = validateParameter(valid_603659, JString, required = false,
                                 default = nil)
  if valid_603659 != nil:
    section.add "X-Amz-Credential", valid_603659
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603661: Call_DescribeInstancePatches_603649; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the patches on the specified instance and their state relative to the patch baseline being used for the instance.
  ## 
  let valid = call_603661.validator(path, query, header, formData, body)
  let scheme = call_603661.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603661.url(scheme.get, call_603661.host, call_603661.base,
                         call_603661.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603661, url, valid)

proc call*(call_603662: Call_DescribeInstancePatches_603649; body: JsonNode): Recallable =
  ## describeInstancePatches
  ## Retrieves information about the patches on the specified instance and their state relative to the patch baseline being used for the instance.
  ##   body: JObject (required)
  var body_603663 = newJObject()
  if body != nil:
    body_603663 = body
  result = call_603662.call(nil, nil, nil, nil, body_603663)

var describeInstancePatches* = Call_DescribeInstancePatches_603649(
    name: "describeInstancePatches", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeInstancePatches",
    validator: validate_DescribeInstancePatches_603650, base: "/",
    url: url_DescribeInstancePatches_603651, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeInventoryDeletions_603664 = ref object of OpenApiRestCall_602466
proc url_DescribeInventoryDeletions_603666(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeInventoryDeletions_603665(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Describes a specific delete inventory operation.
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
  var valid_603667 = header.getOrDefault("X-Amz-Date")
  valid_603667 = validateParameter(valid_603667, JString, required = false,
                                 default = nil)
  if valid_603667 != nil:
    section.add "X-Amz-Date", valid_603667
  var valid_603668 = header.getOrDefault("X-Amz-Security-Token")
  valid_603668 = validateParameter(valid_603668, JString, required = false,
                                 default = nil)
  if valid_603668 != nil:
    section.add "X-Amz-Security-Token", valid_603668
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603669 = header.getOrDefault("X-Amz-Target")
  valid_603669 = validateParameter(valid_603669, JString, required = true, default = newJString(
      "AmazonSSM.DescribeInventoryDeletions"))
  if valid_603669 != nil:
    section.add "X-Amz-Target", valid_603669
  var valid_603670 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603670 = validateParameter(valid_603670, JString, required = false,
                                 default = nil)
  if valid_603670 != nil:
    section.add "X-Amz-Content-Sha256", valid_603670
  var valid_603671 = header.getOrDefault("X-Amz-Algorithm")
  valid_603671 = validateParameter(valid_603671, JString, required = false,
                                 default = nil)
  if valid_603671 != nil:
    section.add "X-Amz-Algorithm", valid_603671
  var valid_603672 = header.getOrDefault("X-Amz-Signature")
  valid_603672 = validateParameter(valid_603672, JString, required = false,
                                 default = nil)
  if valid_603672 != nil:
    section.add "X-Amz-Signature", valid_603672
  var valid_603673 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603673 = validateParameter(valid_603673, JString, required = false,
                                 default = nil)
  if valid_603673 != nil:
    section.add "X-Amz-SignedHeaders", valid_603673
  var valid_603674 = header.getOrDefault("X-Amz-Credential")
  valid_603674 = validateParameter(valid_603674, JString, required = false,
                                 default = nil)
  if valid_603674 != nil:
    section.add "X-Amz-Credential", valid_603674
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603676: Call_DescribeInventoryDeletions_603664; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes a specific delete inventory operation.
  ## 
  let valid = call_603676.validator(path, query, header, formData, body)
  let scheme = call_603676.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603676.url(scheme.get, call_603676.host, call_603676.base,
                         call_603676.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603676, url, valid)

proc call*(call_603677: Call_DescribeInventoryDeletions_603664; body: JsonNode): Recallable =
  ## describeInventoryDeletions
  ## Describes a specific delete inventory operation.
  ##   body: JObject (required)
  var body_603678 = newJObject()
  if body != nil:
    body_603678 = body
  result = call_603677.call(nil, nil, nil, nil, body_603678)

var describeInventoryDeletions* = Call_DescribeInventoryDeletions_603664(
    name: "describeInventoryDeletions", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeInventoryDeletions",
    validator: validate_DescribeInventoryDeletions_603665, base: "/",
    url: url_DescribeInventoryDeletions_603666,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeMaintenanceWindowExecutionTaskInvocations_603679 = ref object of OpenApiRestCall_602466
proc url_DescribeMaintenanceWindowExecutionTaskInvocations_603681(
    protocol: Scheme; host: string; base: string; route: string; path: JsonNode;
    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeMaintenanceWindowExecutionTaskInvocations_603680(
    path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
    body: JsonNode): JsonNode =
  ## Retrieves the individual task executions (one per target) for a particular task run as part of a maintenance window execution.
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
  var valid_603682 = header.getOrDefault("X-Amz-Date")
  valid_603682 = validateParameter(valid_603682, JString, required = false,
                                 default = nil)
  if valid_603682 != nil:
    section.add "X-Amz-Date", valid_603682
  var valid_603683 = header.getOrDefault("X-Amz-Security-Token")
  valid_603683 = validateParameter(valid_603683, JString, required = false,
                                 default = nil)
  if valid_603683 != nil:
    section.add "X-Amz-Security-Token", valid_603683
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603684 = header.getOrDefault("X-Amz-Target")
  valid_603684 = validateParameter(valid_603684, JString, required = true, default = newJString(
      "AmazonSSM.DescribeMaintenanceWindowExecutionTaskInvocations"))
  if valid_603684 != nil:
    section.add "X-Amz-Target", valid_603684
  var valid_603685 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603685 = validateParameter(valid_603685, JString, required = false,
                                 default = nil)
  if valid_603685 != nil:
    section.add "X-Amz-Content-Sha256", valid_603685
  var valid_603686 = header.getOrDefault("X-Amz-Algorithm")
  valid_603686 = validateParameter(valid_603686, JString, required = false,
                                 default = nil)
  if valid_603686 != nil:
    section.add "X-Amz-Algorithm", valid_603686
  var valid_603687 = header.getOrDefault("X-Amz-Signature")
  valid_603687 = validateParameter(valid_603687, JString, required = false,
                                 default = nil)
  if valid_603687 != nil:
    section.add "X-Amz-Signature", valid_603687
  var valid_603688 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603688 = validateParameter(valid_603688, JString, required = false,
                                 default = nil)
  if valid_603688 != nil:
    section.add "X-Amz-SignedHeaders", valid_603688
  var valid_603689 = header.getOrDefault("X-Amz-Credential")
  valid_603689 = validateParameter(valid_603689, JString, required = false,
                                 default = nil)
  if valid_603689 != nil:
    section.add "X-Amz-Credential", valid_603689
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603691: Call_DescribeMaintenanceWindowExecutionTaskInvocations_603679;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves the individual task executions (one per target) for a particular task run as part of a maintenance window execution.
  ## 
  let valid = call_603691.validator(path, query, header, formData, body)
  let scheme = call_603691.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603691.url(scheme.get, call_603691.host, call_603691.base,
                         call_603691.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603691, url, valid)

proc call*(call_603692: Call_DescribeMaintenanceWindowExecutionTaskInvocations_603679;
          body: JsonNode): Recallable =
  ## describeMaintenanceWindowExecutionTaskInvocations
  ## Retrieves the individual task executions (one per target) for a particular task run as part of a maintenance window execution.
  ##   body: JObject (required)
  var body_603693 = newJObject()
  if body != nil:
    body_603693 = body
  result = call_603692.call(nil, nil, nil, nil, body_603693)

var describeMaintenanceWindowExecutionTaskInvocations* = Call_DescribeMaintenanceWindowExecutionTaskInvocations_603679(
    name: "describeMaintenanceWindowExecutionTaskInvocations",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com", route: "/#X-Amz-Target=AmazonSSM.DescribeMaintenanceWindowExecutionTaskInvocations",
    validator: validate_DescribeMaintenanceWindowExecutionTaskInvocations_603680,
    base: "/", url: url_DescribeMaintenanceWindowExecutionTaskInvocations_603681,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeMaintenanceWindowExecutionTasks_603694 = ref object of OpenApiRestCall_602466
proc url_DescribeMaintenanceWindowExecutionTasks_603696(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeMaintenanceWindowExecutionTasks_603695(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## For a given maintenance window execution, lists the tasks that were run.
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
  var valid_603697 = header.getOrDefault("X-Amz-Date")
  valid_603697 = validateParameter(valid_603697, JString, required = false,
                                 default = nil)
  if valid_603697 != nil:
    section.add "X-Amz-Date", valid_603697
  var valid_603698 = header.getOrDefault("X-Amz-Security-Token")
  valid_603698 = validateParameter(valid_603698, JString, required = false,
                                 default = nil)
  if valid_603698 != nil:
    section.add "X-Amz-Security-Token", valid_603698
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603699 = header.getOrDefault("X-Amz-Target")
  valid_603699 = validateParameter(valid_603699, JString, required = true, default = newJString(
      "AmazonSSM.DescribeMaintenanceWindowExecutionTasks"))
  if valid_603699 != nil:
    section.add "X-Amz-Target", valid_603699
  var valid_603700 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603700 = validateParameter(valid_603700, JString, required = false,
                                 default = nil)
  if valid_603700 != nil:
    section.add "X-Amz-Content-Sha256", valid_603700
  var valid_603701 = header.getOrDefault("X-Amz-Algorithm")
  valid_603701 = validateParameter(valid_603701, JString, required = false,
                                 default = nil)
  if valid_603701 != nil:
    section.add "X-Amz-Algorithm", valid_603701
  var valid_603702 = header.getOrDefault("X-Amz-Signature")
  valid_603702 = validateParameter(valid_603702, JString, required = false,
                                 default = nil)
  if valid_603702 != nil:
    section.add "X-Amz-Signature", valid_603702
  var valid_603703 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603703 = validateParameter(valid_603703, JString, required = false,
                                 default = nil)
  if valid_603703 != nil:
    section.add "X-Amz-SignedHeaders", valid_603703
  var valid_603704 = header.getOrDefault("X-Amz-Credential")
  valid_603704 = validateParameter(valid_603704, JString, required = false,
                                 default = nil)
  if valid_603704 != nil:
    section.add "X-Amz-Credential", valid_603704
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603706: Call_DescribeMaintenanceWindowExecutionTasks_603694;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## For a given maintenance window execution, lists the tasks that were run.
  ## 
  let valid = call_603706.validator(path, query, header, formData, body)
  let scheme = call_603706.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603706.url(scheme.get, call_603706.host, call_603706.base,
                         call_603706.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603706, url, valid)

proc call*(call_603707: Call_DescribeMaintenanceWindowExecutionTasks_603694;
          body: JsonNode): Recallable =
  ## describeMaintenanceWindowExecutionTasks
  ## For a given maintenance window execution, lists the tasks that were run.
  ##   body: JObject (required)
  var body_603708 = newJObject()
  if body != nil:
    body_603708 = body
  result = call_603707.call(nil, nil, nil, nil, body_603708)

var describeMaintenanceWindowExecutionTasks* = Call_DescribeMaintenanceWindowExecutionTasks_603694(
    name: "describeMaintenanceWindowExecutionTasks", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeMaintenanceWindowExecutionTasks",
    validator: validate_DescribeMaintenanceWindowExecutionTasks_603695, base: "/",
    url: url_DescribeMaintenanceWindowExecutionTasks_603696,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeMaintenanceWindowExecutions_603709 = ref object of OpenApiRestCall_602466
proc url_DescribeMaintenanceWindowExecutions_603711(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeMaintenanceWindowExecutions_603710(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists the executions of a maintenance window. This includes information about when the maintenance window was scheduled to be active, and information about tasks registered and run with the maintenance window.
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
  var valid_603712 = header.getOrDefault("X-Amz-Date")
  valid_603712 = validateParameter(valid_603712, JString, required = false,
                                 default = nil)
  if valid_603712 != nil:
    section.add "X-Amz-Date", valid_603712
  var valid_603713 = header.getOrDefault("X-Amz-Security-Token")
  valid_603713 = validateParameter(valid_603713, JString, required = false,
                                 default = nil)
  if valid_603713 != nil:
    section.add "X-Amz-Security-Token", valid_603713
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603714 = header.getOrDefault("X-Amz-Target")
  valid_603714 = validateParameter(valid_603714, JString, required = true, default = newJString(
      "AmazonSSM.DescribeMaintenanceWindowExecutions"))
  if valid_603714 != nil:
    section.add "X-Amz-Target", valid_603714
  var valid_603715 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603715 = validateParameter(valid_603715, JString, required = false,
                                 default = nil)
  if valid_603715 != nil:
    section.add "X-Amz-Content-Sha256", valid_603715
  var valid_603716 = header.getOrDefault("X-Amz-Algorithm")
  valid_603716 = validateParameter(valid_603716, JString, required = false,
                                 default = nil)
  if valid_603716 != nil:
    section.add "X-Amz-Algorithm", valid_603716
  var valid_603717 = header.getOrDefault("X-Amz-Signature")
  valid_603717 = validateParameter(valid_603717, JString, required = false,
                                 default = nil)
  if valid_603717 != nil:
    section.add "X-Amz-Signature", valid_603717
  var valid_603718 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603718 = validateParameter(valid_603718, JString, required = false,
                                 default = nil)
  if valid_603718 != nil:
    section.add "X-Amz-SignedHeaders", valid_603718
  var valid_603719 = header.getOrDefault("X-Amz-Credential")
  valid_603719 = validateParameter(valid_603719, JString, required = false,
                                 default = nil)
  if valid_603719 != nil:
    section.add "X-Amz-Credential", valid_603719
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603721: Call_DescribeMaintenanceWindowExecutions_603709;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists the executions of a maintenance window. This includes information about when the maintenance window was scheduled to be active, and information about tasks registered and run with the maintenance window.
  ## 
  let valid = call_603721.validator(path, query, header, formData, body)
  let scheme = call_603721.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603721.url(scheme.get, call_603721.host, call_603721.base,
                         call_603721.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603721, url, valid)

proc call*(call_603722: Call_DescribeMaintenanceWindowExecutions_603709;
          body: JsonNode): Recallable =
  ## describeMaintenanceWindowExecutions
  ## Lists the executions of a maintenance window. This includes information about when the maintenance window was scheduled to be active, and information about tasks registered and run with the maintenance window.
  ##   body: JObject (required)
  var body_603723 = newJObject()
  if body != nil:
    body_603723 = body
  result = call_603722.call(nil, nil, nil, nil, body_603723)

var describeMaintenanceWindowExecutions* = Call_DescribeMaintenanceWindowExecutions_603709(
    name: "describeMaintenanceWindowExecutions", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeMaintenanceWindowExecutions",
    validator: validate_DescribeMaintenanceWindowExecutions_603710, base: "/",
    url: url_DescribeMaintenanceWindowExecutions_603711,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeMaintenanceWindowSchedule_603724 = ref object of OpenApiRestCall_602466
proc url_DescribeMaintenanceWindowSchedule_603726(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeMaintenanceWindowSchedule_603725(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves information about upcoming executions of a maintenance window.
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
  var valid_603727 = header.getOrDefault("X-Amz-Date")
  valid_603727 = validateParameter(valid_603727, JString, required = false,
                                 default = nil)
  if valid_603727 != nil:
    section.add "X-Amz-Date", valid_603727
  var valid_603728 = header.getOrDefault("X-Amz-Security-Token")
  valid_603728 = validateParameter(valid_603728, JString, required = false,
                                 default = nil)
  if valid_603728 != nil:
    section.add "X-Amz-Security-Token", valid_603728
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603729 = header.getOrDefault("X-Amz-Target")
  valid_603729 = validateParameter(valid_603729, JString, required = true, default = newJString(
      "AmazonSSM.DescribeMaintenanceWindowSchedule"))
  if valid_603729 != nil:
    section.add "X-Amz-Target", valid_603729
  var valid_603730 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603730 = validateParameter(valid_603730, JString, required = false,
                                 default = nil)
  if valid_603730 != nil:
    section.add "X-Amz-Content-Sha256", valid_603730
  var valid_603731 = header.getOrDefault("X-Amz-Algorithm")
  valid_603731 = validateParameter(valid_603731, JString, required = false,
                                 default = nil)
  if valid_603731 != nil:
    section.add "X-Amz-Algorithm", valid_603731
  var valid_603732 = header.getOrDefault("X-Amz-Signature")
  valid_603732 = validateParameter(valid_603732, JString, required = false,
                                 default = nil)
  if valid_603732 != nil:
    section.add "X-Amz-Signature", valid_603732
  var valid_603733 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603733 = validateParameter(valid_603733, JString, required = false,
                                 default = nil)
  if valid_603733 != nil:
    section.add "X-Amz-SignedHeaders", valid_603733
  var valid_603734 = header.getOrDefault("X-Amz-Credential")
  valid_603734 = validateParameter(valid_603734, JString, required = false,
                                 default = nil)
  if valid_603734 != nil:
    section.add "X-Amz-Credential", valid_603734
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603736: Call_DescribeMaintenanceWindowSchedule_603724;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves information about upcoming executions of a maintenance window.
  ## 
  let valid = call_603736.validator(path, query, header, formData, body)
  let scheme = call_603736.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603736.url(scheme.get, call_603736.host, call_603736.base,
                         call_603736.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603736, url, valid)

proc call*(call_603737: Call_DescribeMaintenanceWindowSchedule_603724;
          body: JsonNode): Recallable =
  ## describeMaintenanceWindowSchedule
  ## Retrieves information about upcoming executions of a maintenance window.
  ##   body: JObject (required)
  var body_603738 = newJObject()
  if body != nil:
    body_603738 = body
  result = call_603737.call(nil, nil, nil, nil, body_603738)

var describeMaintenanceWindowSchedule* = Call_DescribeMaintenanceWindowSchedule_603724(
    name: "describeMaintenanceWindowSchedule", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeMaintenanceWindowSchedule",
    validator: validate_DescribeMaintenanceWindowSchedule_603725, base: "/",
    url: url_DescribeMaintenanceWindowSchedule_603726,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeMaintenanceWindowTargets_603739 = ref object of OpenApiRestCall_602466
proc url_DescribeMaintenanceWindowTargets_603741(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeMaintenanceWindowTargets_603740(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists the targets registered with the maintenance window.
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
  var valid_603742 = header.getOrDefault("X-Amz-Date")
  valid_603742 = validateParameter(valid_603742, JString, required = false,
                                 default = nil)
  if valid_603742 != nil:
    section.add "X-Amz-Date", valid_603742
  var valid_603743 = header.getOrDefault("X-Amz-Security-Token")
  valid_603743 = validateParameter(valid_603743, JString, required = false,
                                 default = nil)
  if valid_603743 != nil:
    section.add "X-Amz-Security-Token", valid_603743
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603744 = header.getOrDefault("X-Amz-Target")
  valid_603744 = validateParameter(valid_603744, JString, required = true, default = newJString(
      "AmazonSSM.DescribeMaintenanceWindowTargets"))
  if valid_603744 != nil:
    section.add "X-Amz-Target", valid_603744
  var valid_603745 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603745 = validateParameter(valid_603745, JString, required = false,
                                 default = nil)
  if valid_603745 != nil:
    section.add "X-Amz-Content-Sha256", valid_603745
  var valid_603746 = header.getOrDefault("X-Amz-Algorithm")
  valid_603746 = validateParameter(valid_603746, JString, required = false,
                                 default = nil)
  if valid_603746 != nil:
    section.add "X-Amz-Algorithm", valid_603746
  var valid_603747 = header.getOrDefault("X-Amz-Signature")
  valid_603747 = validateParameter(valid_603747, JString, required = false,
                                 default = nil)
  if valid_603747 != nil:
    section.add "X-Amz-Signature", valid_603747
  var valid_603748 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603748 = validateParameter(valid_603748, JString, required = false,
                                 default = nil)
  if valid_603748 != nil:
    section.add "X-Amz-SignedHeaders", valid_603748
  var valid_603749 = header.getOrDefault("X-Amz-Credential")
  valid_603749 = validateParameter(valid_603749, JString, required = false,
                                 default = nil)
  if valid_603749 != nil:
    section.add "X-Amz-Credential", valid_603749
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603751: Call_DescribeMaintenanceWindowTargets_603739;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists the targets registered with the maintenance window.
  ## 
  let valid = call_603751.validator(path, query, header, formData, body)
  let scheme = call_603751.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603751.url(scheme.get, call_603751.host, call_603751.base,
                         call_603751.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603751, url, valid)

proc call*(call_603752: Call_DescribeMaintenanceWindowTargets_603739;
          body: JsonNode): Recallable =
  ## describeMaintenanceWindowTargets
  ## Lists the targets registered with the maintenance window.
  ##   body: JObject (required)
  var body_603753 = newJObject()
  if body != nil:
    body_603753 = body
  result = call_603752.call(nil, nil, nil, nil, body_603753)

var describeMaintenanceWindowTargets* = Call_DescribeMaintenanceWindowTargets_603739(
    name: "describeMaintenanceWindowTargets", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeMaintenanceWindowTargets",
    validator: validate_DescribeMaintenanceWindowTargets_603740, base: "/",
    url: url_DescribeMaintenanceWindowTargets_603741,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeMaintenanceWindowTasks_603754 = ref object of OpenApiRestCall_602466
proc url_DescribeMaintenanceWindowTasks_603756(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeMaintenanceWindowTasks_603755(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists the tasks in a maintenance window.
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
  var valid_603757 = header.getOrDefault("X-Amz-Date")
  valid_603757 = validateParameter(valid_603757, JString, required = false,
                                 default = nil)
  if valid_603757 != nil:
    section.add "X-Amz-Date", valid_603757
  var valid_603758 = header.getOrDefault("X-Amz-Security-Token")
  valid_603758 = validateParameter(valid_603758, JString, required = false,
                                 default = nil)
  if valid_603758 != nil:
    section.add "X-Amz-Security-Token", valid_603758
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603759 = header.getOrDefault("X-Amz-Target")
  valid_603759 = validateParameter(valid_603759, JString, required = true, default = newJString(
      "AmazonSSM.DescribeMaintenanceWindowTasks"))
  if valid_603759 != nil:
    section.add "X-Amz-Target", valid_603759
  var valid_603760 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603760 = validateParameter(valid_603760, JString, required = false,
                                 default = nil)
  if valid_603760 != nil:
    section.add "X-Amz-Content-Sha256", valid_603760
  var valid_603761 = header.getOrDefault("X-Amz-Algorithm")
  valid_603761 = validateParameter(valid_603761, JString, required = false,
                                 default = nil)
  if valid_603761 != nil:
    section.add "X-Amz-Algorithm", valid_603761
  var valid_603762 = header.getOrDefault("X-Amz-Signature")
  valid_603762 = validateParameter(valid_603762, JString, required = false,
                                 default = nil)
  if valid_603762 != nil:
    section.add "X-Amz-Signature", valid_603762
  var valid_603763 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603763 = validateParameter(valid_603763, JString, required = false,
                                 default = nil)
  if valid_603763 != nil:
    section.add "X-Amz-SignedHeaders", valid_603763
  var valid_603764 = header.getOrDefault("X-Amz-Credential")
  valid_603764 = validateParameter(valid_603764, JString, required = false,
                                 default = nil)
  if valid_603764 != nil:
    section.add "X-Amz-Credential", valid_603764
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603766: Call_DescribeMaintenanceWindowTasks_603754; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the tasks in a maintenance window.
  ## 
  let valid = call_603766.validator(path, query, header, formData, body)
  let scheme = call_603766.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603766.url(scheme.get, call_603766.host, call_603766.base,
                         call_603766.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603766, url, valid)

proc call*(call_603767: Call_DescribeMaintenanceWindowTasks_603754; body: JsonNode): Recallable =
  ## describeMaintenanceWindowTasks
  ## Lists the tasks in a maintenance window.
  ##   body: JObject (required)
  var body_603768 = newJObject()
  if body != nil:
    body_603768 = body
  result = call_603767.call(nil, nil, nil, nil, body_603768)

var describeMaintenanceWindowTasks* = Call_DescribeMaintenanceWindowTasks_603754(
    name: "describeMaintenanceWindowTasks", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeMaintenanceWindowTasks",
    validator: validate_DescribeMaintenanceWindowTasks_603755, base: "/",
    url: url_DescribeMaintenanceWindowTasks_603756,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeMaintenanceWindows_603769 = ref object of OpenApiRestCall_602466
proc url_DescribeMaintenanceWindows_603771(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeMaintenanceWindows_603770(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves the maintenance windows in an AWS account.
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
  var valid_603772 = header.getOrDefault("X-Amz-Date")
  valid_603772 = validateParameter(valid_603772, JString, required = false,
                                 default = nil)
  if valid_603772 != nil:
    section.add "X-Amz-Date", valid_603772
  var valid_603773 = header.getOrDefault("X-Amz-Security-Token")
  valid_603773 = validateParameter(valid_603773, JString, required = false,
                                 default = nil)
  if valid_603773 != nil:
    section.add "X-Amz-Security-Token", valid_603773
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603774 = header.getOrDefault("X-Amz-Target")
  valid_603774 = validateParameter(valid_603774, JString, required = true, default = newJString(
      "AmazonSSM.DescribeMaintenanceWindows"))
  if valid_603774 != nil:
    section.add "X-Amz-Target", valid_603774
  var valid_603775 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603775 = validateParameter(valid_603775, JString, required = false,
                                 default = nil)
  if valid_603775 != nil:
    section.add "X-Amz-Content-Sha256", valid_603775
  var valid_603776 = header.getOrDefault("X-Amz-Algorithm")
  valid_603776 = validateParameter(valid_603776, JString, required = false,
                                 default = nil)
  if valid_603776 != nil:
    section.add "X-Amz-Algorithm", valid_603776
  var valid_603777 = header.getOrDefault("X-Amz-Signature")
  valid_603777 = validateParameter(valid_603777, JString, required = false,
                                 default = nil)
  if valid_603777 != nil:
    section.add "X-Amz-Signature", valid_603777
  var valid_603778 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603778 = validateParameter(valid_603778, JString, required = false,
                                 default = nil)
  if valid_603778 != nil:
    section.add "X-Amz-SignedHeaders", valid_603778
  var valid_603779 = header.getOrDefault("X-Amz-Credential")
  valid_603779 = validateParameter(valid_603779, JString, required = false,
                                 default = nil)
  if valid_603779 != nil:
    section.add "X-Amz-Credential", valid_603779
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603781: Call_DescribeMaintenanceWindows_603769; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the maintenance windows in an AWS account.
  ## 
  let valid = call_603781.validator(path, query, header, formData, body)
  let scheme = call_603781.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603781.url(scheme.get, call_603781.host, call_603781.base,
                         call_603781.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603781, url, valid)

proc call*(call_603782: Call_DescribeMaintenanceWindows_603769; body: JsonNode): Recallable =
  ## describeMaintenanceWindows
  ## Retrieves the maintenance windows in an AWS account.
  ##   body: JObject (required)
  var body_603783 = newJObject()
  if body != nil:
    body_603783 = body
  result = call_603782.call(nil, nil, nil, nil, body_603783)

var describeMaintenanceWindows* = Call_DescribeMaintenanceWindows_603769(
    name: "describeMaintenanceWindows", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeMaintenanceWindows",
    validator: validate_DescribeMaintenanceWindows_603770, base: "/",
    url: url_DescribeMaintenanceWindows_603771,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeMaintenanceWindowsForTarget_603784 = ref object of OpenApiRestCall_602466
proc url_DescribeMaintenanceWindowsForTarget_603786(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeMaintenanceWindowsForTarget_603785(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves information about the maintenance window targets or tasks that an instance is associated with.
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
  var valid_603787 = header.getOrDefault("X-Amz-Date")
  valid_603787 = validateParameter(valid_603787, JString, required = false,
                                 default = nil)
  if valid_603787 != nil:
    section.add "X-Amz-Date", valid_603787
  var valid_603788 = header.getOrDefault("X-Amz-Security-Token")
  valid_603788 = validateParameter(valid_603788, JString, required = false,
                                 default = nil)
  if valid_603788 != nil:
    section.add "X-Amz-Security-Token", valid_603788
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603789 = header.getOrDefault("X-Amz-Target")
  valid_603789 = validateParameter(valid_603789, JString, required = true, default = newJString(
      "AmazonSSM.DescribeMaintenanceWindowsForTarget"))
  if valid_603789 != nil:
    section.add "X-Amz-Target", valid_603789
  var valid_603790 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603790 = validateParameter(valid_603790, JString, required = false,
                                 default = nil)
  if valid_603790 != nil:
    section.add "X-Amz-Content-Sha256", valid_603790
  var valid_603791 = header.getOrDefault("X-Amz-Algorithm")
  valid_603791 = validateParameter(valid_603791, JString, required = false,
                                 default = nil)
  if valid_603791 != nil:
    section.add "X-Amz-Algorithm", valid_603791
  var valid_603792 = header.getOrDefault("X-Amz-Signature")
  valid_603792 = validateParameter(valid_603792, JString, required = false,
                                 default = nil)
  if valid_603792 != nil:
    section.add "X-Amz-Signature", valid_603792
  var valid_603793 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603793 = validateParameter(valid_603793, JString, required = false,
                                 default = nil)
  if valid_603793 != nil:
    section.add "X-Amz-SignedHeaders", valid_603793
  var valid_603794 = header.getOrDefault("X-Amz-Credential")
  valid_603794 = validateParameter(valid_603794, JString, required = false,
                                 default = nil)
  if valid_603794 != nil:
    section.add "X-Amz-Credential", valid_603794
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603796: Call_DescribeMaintenanceWindowsForTarget_603784;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves information about the maintenance window targets or tasks that an instance is associated with.
  ## 
  let valid = call_603796.validator(path, query, header, formData, body)
  let scheme = call_603796.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603796.url(scheme.get, call_603796.host, call_603796.base,
                         call_603796.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603796, url, valid)

proc call*(call_603797: Call_DescribeMaintenanceWindowsForTarget_603784;
          body: JsonNode): Recallable =
  ## describeMaintenanceWindowsForTarget
  ## Retrieves information about the maintenance window targets or tasks that an instance is associated with.
  ##   body: JObject (required)
  var body_603798 = newJObject()
  if body != nil:
    body_603798 = body
  result = call_603797.call(nil, nil, nil, nil, body_603798)

var describeMaintenanceWindowsForTarget* = Call_DescribeMaintenanceWindowsForTarget_603784(
    name: "describeMaintenanceWindowsForTarget", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeMaintenanceWindowsForTarget",
    validator: validate_DescribeMaintenanceWindowsForTarget_603785, base: "/",
    url: url_DescribeMaintenanceWindowsForTarget_603786,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeOpsItems_603799 = ref object of OpenApiRestCall_602466
proc url_DescribeOpsItems_603801(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeOpsItems_603800(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <p>Query a set of OpsItems. You must have permission in AWS Identity and Access Management (IAM) to query a list of OpsItems. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter-getting-started.html">Getting Started with OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>.</p> <p>Operations engineers and IT professionals use OpsCenter to view, investigate, and remediate operational issues impacting the performance and health of their AWS resources. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter.html">AWS Systems Manager OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>. </p>
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
  var valid_603802 = header.getOrDefault("X-Amz-Date")
  valid_603802 = validateParameter(valid_603802, JString, required = false,
                                 default = nil)
  if valid_603802 != nil:
    section.add "X-Amz-Date", valid_603802
  var valid_603803 = header.getOrDefault("X-Amz-Security-Token")
  valid_603803 = validateParameter(valid_603803, JString, required = false,
                                 default = nil)
  if valid_603803 != nil:
    section.add "X-Amz-Security-Token", valid_603803
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603804 = header.getOrDefault("X-Amz-Target")
  valid_603804 = validateParameter(valid_603804, JString, required = true, default = newJString(
      "AmazonSSM.DescribeOpsItems"))
  if valid_603804 != nil:
    section.add "X-Amz-Target", valid_603804
  var valid_603805 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603805 = validateParameter(valid_603805, JString, required = false,
                                 default = nil)
  if valid_603805 != nil:
    section.add "X-Amz-Content-Sha256", valid_603805
  var valid_603806 = header.getOrDefault("X-Amz-Algorithm")
  valid_603806 = validateParameter(valid_603806, JString, required = false,
                                 default = nil)
  if valid_603806 != nil:
    section.add "X-Amz-Algorithm", valid_603806
  var valid_603807 = header.getOrDefault("X-Amz-Signature")
  valid_603807 = validateParameter(valid_603807, JString, required = false,
                                 default = nil)
  if valid_603807 != nil:
    section.add "X-Amz-Signature", valid_603807
  var valid_603808 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603808 = validateParameter(valid_603808, JString, required = false,
                                 default = nil)
  if valid_603808 != nil:
    section.add "X-Amz-SignedHeaders", valid_603808
  var valid_603809 = header.getOrDefault("X-Amz-Credential")
  valid_603809 = validateParameter(valid_603809, JString, required = false,
                                 default = nil)
  if valid_603809 != nil:
    section.add "X-Amz-Credential", valid_603809
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603811: Call_DescribeOpsItems_603799; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Query a set of OpsItems. You must have permission in AWS Identity and Access Management (IAM) to query a list of OpsItems. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter-getting-started.html">Getting Started with OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>.</p> <p>Operations engineers and IT professionals use OpsCenter to view, investigate, and remediate operational issues impacting the performance and health of their AWS resources. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter.html">AWS Systems Manager OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>. </p>
  ## 
  let valid = call_603811.validator(path, query, header, formData, body)
  let scheme = call_603811.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603811.url(scheme.get, call_603811.host, call_603811.base,
                         call_603811.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603811, url, valid)

proc call*(call_603812: Call_DescribeOpsItems_603799; body: JsonNode): Recallable =
  ## describeOpsItems
  ## <p>Query a set of OpsItems. You must have permission in AWS Identity and Access Management (IAM) to query a list of OpsItems. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter-getting-started.html">Getting Started with OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>.</p> <p>Operations engineers and IT professionals use OpsCenter to view, investigate, and remediate operational issues impacting the performance and health of their AWS resources. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter.html">AWS Systems Manager OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>. </p>
  ##   body: JObject (required)
  var body_603813 = newJObject()
  if body != nil:
    body_603813 = body
  result = call_603812.call(nil, nil, nil, nil, body_603813)

var describeOpsItems* = Call_DescribeOpsItems_603799(name: "describeOpsItems",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeOpsItems",
    validator: validate_DescribeOpsItems_603800, base: "/",
    url: url_DescribeOpsItems_603801, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeParameters_603814 = ref object of OpenApiRestCall_602466
proc url_DescribeParameters_603816(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeParameters_603815(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## <p>Get information about a parameter.</p> <p>Request results are returned on a best-effort basis. If you specify <code>MaxResults</code> in the request, the response includes information up to the limit specified. The number of items returned, however, can be between zero and the value of <code>MaxResults</code>. If the service reaches an internal limit while processing the results, it stops the operation and returns the matching values up to that point and a <code>NextToken</code>. You can specify the <code>NextToken</code> in a subsequent call to get the next set of results.</p>
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
  var valid_603817 = query.getOrDefault("NextToken")
  valid_603817 = validateParameter(valid_603817, JString, required = false,
                                 default = nil)
  if valid_603817 != nil:
    section.add "NextToken", valid_603817
  var valid_603818 = query.getOrDefault("MaxResults")
  valid_603818 = validateParameter(valid_603818, JString, required = false,
                                 default = nil)
  if valid_603818 != nil:
    section.add "MaxResults", valid_603818
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
  var valid_603819 = header.getOrDefault("X-Amz-Date")
  valid_603819 = validateParameter(valid_603819, JString, required = false,
                                 default = nil)
  if valid_603819 != nil:
    section.add "X-Amz-Date", valid_603819
  var valid_603820 = header.getOrDefault("X-Amz-Security-Token")
  valid_603820 = validateParameter(valid_603820, JString, required = false,
                                 default = nil)
  if valid_603820 != nil:
    section.add "X-Amz-Security-Token", valid_603820
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603821 = header.getOrDefault("X-Amz-Target")
  valid_603821 = validateParameter(valid_603821, JString, required = true, default = newJString(
      "AmazonSSM.DescribeParameters"))
  if valid_603821 != nil:
    section.add "X-Amz-Target", valid_603821
  var valid_603822 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603822 = validateParameter(valid_603822, JString, required = false,
                                 default = nil)
  if valid_603822 != nil:
    section.add "X-Amz-Content-Sha256", valid_603822
  var valid_603823 = header.getOrDefault("X-Amz-Algorithm")
  valid_603823 = validateParameter(valid_603823, JString, required = false,
                                 default = nil)
  if valid_603823 != nil:
    section.add "X-Amz-Algorithm", valid_603823
  var valid_603824 = header.getOrDefault("X-Amz-Signature")
  valid_603824 = validateParameter(valid_603824, JString, required = false,
                                 default = nil)
  if valid_603824 != nil:
    section.add "X-Amz-Signature", valid_603824
  var valid_603825 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603825 = validateParameter(valid_603825, JString, required = false,
                                 default = nil)
  if valid_603825 != nil:
    section.add "X-Amz-SignedHeaders", valid_603825
  var valid_603826 = header.getOrDefault("X-Amz-Credential")
  valid_603826 = validateParameter(valid_603826, JString, required = false,
                                 default = nil)
  if valid_603826 != nil:
    section.add "X-Amz-Credential", valid_603826
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603828: Call_DescribeParameters_603814; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Get information about a parameter.</p> <p>Request results are returned on a best-effort basis. If you specify <code>MaxResults</code> in the request, the response includes information up to the limit specified. The number of items returned, however, can be between zero and the value of <code>MaxResults</code>. If the service reaches an internal limit while processing the results, it stops the operation and returns the matching values up to that point and a <code>NextToken</code>. You can specify the <code>NextToken</code> in a subsequent call to get the next set of results.</p>
  ## 
  let valid = call_603828.validator(path, query, header, formData, body)
  let scheme = call_603828.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603828.url(scheme.get, call_603828.host, call_603828.base,
                         call_603828.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603828, url, valid)

proc call*(call_603829: Call_DescribeParameters_603814; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## describeParameters
  ## <p>Get information about a parameter.</p> <p>Request results are returned on a best-effort basis. If you specify <code>MaxResults</code> in the request, the response includes information up to the limit specified. The number of items returned, however, can be between zero and the value of <code>MaxResults</code>. If the service reaches an internal limit while processing the results, it stops the operation and returns the matching values up to that point and a <code>NextToken</code>. You can specify the <code>NextToken</code> in a subsequent call to get the next set of results.</p>
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_603830 = newJObject()
  var body_603831 = newJObject()
  add(query_603830, "NextToken", newJString(NextToken))
  if body != nil:
    body_603831 = body
  add(query_603830, "MaxResults", newJString(MaxResults))
  result = call_603829.call(nil, query_603830, nil, nil, body_603831)

var describeParameters* = Call_DescribeParameters_603814(
    name: "describeParameters", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeParameters",
    validator: validate_DescribeParameters_603815, base: "/",
    url: url_DescribeParameters_603816, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribePatchBaselines_603832 = ref object of OpenApiRestCall_602466
proc url_DescribePatchBaselines_603834(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribePatchBaselines_603833(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists the patch baselines in your AWS account.
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
  var valid_603835 = header.getOrDefault("X-Amz-Date")
  valid_603835 = validateParameter(valid_603835, JString, required = false,
                                 default = nil)
  if valid_603835 != nil:
    section.add "X-Amz-Date", valid_603835
  var valid_603836 = header.getOrDefault("X-Amz-Security-Token")
  valid_603836 = validateParameter(valid_603836, JString, required = false,
                                 default = nil)
  if valid_603836 != nil:
    section.add "X-Amz-Security-Token", valid_603836
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603837 = header.getOrDefault("X-Amz-Target")
  valid_603837 = validateParameter(valid_603837, JString, required = true, default = newJString(
      "AmazonSSM.DescribePatchBaselines"))
  if valid_603837 != nil:
    section.add "X-Amz-Target", valid_603837
  var valid_603838 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603838 = validateParameter(valid_603838, JString, required = false,
                                 default = nil)
  if valid_603838 != nil:
    section.add "X-Amz-Content-Sha256", valid_603838
  var valid_603839 = header.getOrDefault("X-Amz-Algorithm")
  valid_603839 = validateParameter(valid_603839, JString, required = false,
                                 default = nil)
  if valid_603839 != nil:
    section.add "X-Amz-Algorithm", valid_603839
  var valid_603840 = header.getOrDefault("X-Amz-Signature")
  valid_603840 = validateParameter(valid_603840, JString, required = false,
                                 default = nil)
  if valid_603840 != nil:
    section.add "X-Amz-Signature", valid_603840
  var valid_603841 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603841 = validateParameter(valid_603841, JString, required = false,
                                 default = nil)
  if valid_603841 != nil:
    section.add "X-Amz-SignedHeaders", valid_603841
  var valid_603842 = header.getOrDefault("X-Amz-Credential")
  valid_603842 = validateParameter(valid_603842, JString, required = false,
                                 default = nil)
  if valid_603842 != nil:
    section.add "X-Amz-Credential", valid_603842
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603844: Call_DescribePatchBaselines_603832; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the patch baselines in your AWS account.
  ## 
  let valid = call_603844.validator(path, query, header, formData, body)
  let scheme = call_603844.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603844.url(scheme.get, call_603844.host, call_603844.base,
                         call_603844.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603844, url, valid)

proc call*(call_603845: Call_DescribePatchBaselines_603832; body: JsonNode): Recallable =
  ## describePatchBaselines
  ## Lists the patch baselines in your AWS account.
  ##   body: JObject (required)
  var body_603846 = newJObject()
  if body != nil:
    body_603846 = body
  result = call_603845.call(nil, nil, nil, nil, body_603846)

var describePatchBaselines* = Call_DescribePatchBaselines_603832(
    name: "describePatchBaselines", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribePatchBaselines",
    validator: validate_DescribePatchBaselines_603833, base: "/",
    url: url_DescribePatchBaselines_603834, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribePatchGroupState_603847 = ref object of OpenApiRestCall_602466
proc url_DescribePatchGroupState_603849(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribePatchGroupState_603848(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns high-level aggregated patch compliance state for a patch group.
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
  var valid_603850 = header.getOrDefault("X-Amz-Date")
  valid_603850 = validateParameter(valid_603850, JString, required = false,
                                 default = nil)
  if valid_603850 != nil:
    section.add "X-Amz-Date", valid_603850
  var valid_603851 = header.getOrDefault("X-Amz-Security-Token")
  valid_603851 = validateParameter(valid_603851, JString, required = false,
                                 default = nil)
  if valid_603851 != nil:
    section.add "X-Amz-Security-Token", valid_603851
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603852 = header.getOrDefault("X-Amz-Target")
  valid_603852 = validateParameter(valid_603852, JString, required = true, default = newJString(
      "AmazonSSM.DescribePatchGroupState"))
  if valid_603852 != nil:
    section.add "X-Amz-Target", valid_603852
  var valid_603853 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603853 = validateParameter(valid_603853, JString, required = false,
                                 default = nil)
  if valid_603853 != nil:
    section.add "X-Amz-Content-Sha256", valid_603853
  var valid_603854 = header.getOrDefault("X-Amz-Algorithm")
  valid_603854 = validateParameter(valid_603854, JString, required = false,
                                 default = nil)
  if valid_603854 != nil:
    section.add "X-Amz-Algorithm", valid_603854
  var valid_603855 = header.getOrDefault("X-Amz-Signature")
  valid_603855 = validateParameter(valid_603855, JString, required = false,
                                 default = nil)
  if valid_603855 != nil:
    section.add "X-Amz-Signature", valid_603855
  var valid_603856 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603856 = validateParameter(valid_603856, JString, required = false,
                                 default = nil)
  if valid_603856 != nil:
    section.add "X-Amz-SignedHeaders", valid_603856
  var valid_603857 = header.getOrDefault("X-Amz-Credential")
  valid_603857 = validateParameter(valid_603857, JString, required = false,
                                 default = nil)
  if valid_603857 != nil:
    section.add "X-Amz-Credential", valid_603857
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603859: Call_DescribePatchGroupState_603847; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns high-level aggregated patch compliance state for a patch group.
  ## 
  let valid = call_603859.validator(path, query, header, formData, body)
  let scheme = call_603859.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603859.url(scheme.get, call_603859.host, call_603859.base,
                         call_603859.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603859, url, valid)

proc call*(call_603860: Call_DescribePatchGroupState_603847; body: JsonNode): Recallable =
  ## describePatchGroupState
  ## Returns high-level aggregated patch compliance state for a patch group.
  ##   body: JObject (required)
  var body_603861 = newJObject()
  if body != nil:
    body_603861 = body
  result = call_603860.call(nil, nil, nil, nil, body_603861)

var describePatchGroupState* = Call_DescribePatchGroupState_603847(
    name: "describePatchGroupState", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribePatchGroupState",
    validator: validate_DescribePatchGroupState_603848, base: "/",
    url: url_DescribePatchGroupState_603849, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribePatchGroups_603862 = ref object of OpenApiRestCall_602466
proc url_DescribePatchGroups_603864(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribePatchGroups_603863(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Lists all patch groups that have been registered with patch baselines.
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
  var valid_603865 = header.getOrDefault("X-Amz-Date")
  valid_603865 = validateParameter(valid_603865, JString, required = false,
                                 default = nil)
  if valid_603865 != nil:
    section.add "X-Amz-Date", valid_603865
  var valid_603866 = header.getOrDefault("X-Amz-Security-Token")
  valid_603866 = validateParameter(valid_603866, JString, required = false,
                                 default = nil)
  if valid_603866 != nil:
    section.add "X-Amz-Security-Token", valid_603866
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603867 = header.getOrDefault("X-Amz-Target")
  valid_603867 = validateParameter(valid_603867, JString, required = true, default = newJString(
      "AmazonSSM.DescribePatchGroups"))
  if valid_603867 != nil:
    section.add "X-Amz-Target", valid_603867
  var valid_603868 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603868 = validateParameter(valid_603868, JString, required = false,
                                 default = nil)
  if valid_603868 != nil:
    section.add "X-Amz-Content-Sha256", valid_603868
  var valid_603869 = header.getOrDefault("X-Amz-Algorithm")
  valid_603869 = validateParameter(valid_603869, JString, required = false,
                                 default = nil)
  if valid_603869 != nil:
    section.add "X-Amz-Algorithm", valid_603869
  var valid_603870 = header.getOrDefault("X-Amz-Signature")
  valid_603870 = validateParameter(valid_603870, JString, required = false,
                                 default = nil)
  if valid_603870 != nil:
    section.add "X-Amz-Signature", valid_603870
  var valid_603871 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603871 = validateParameter(valid_603871, JString, required = false,
                                 default = nil)
  if valid_603871 != nil:
    section.add "X-Amz-SignedHeaders", valid_603871
  var valid_603872 = header.getOrDefault("X-Amz-Credential")
  valid_603872 = validateParameter(valid_603872, JString, required = false,
                                 default = nil)
  if valid_603872 != nil:
    section.add "X-Amz-Credential", valid_603872
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603874: Call_DescribePatchGroups_603862; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all patch groups that have been registered with patch baselines.
  ## 
  let valid = call_603874.validator(path, query, header, formData, body)
  let scheme = call_603874.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603874.url(scheme.get, call_603874.host, call_603874.base,
                         call_603874.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603874, url, valid)

proc call*(call_603875: Call_DescribePatchGroups_603862; body: JsonNode): Recallable =
  ## describePatchGroups
  ## Lists all patch groups that have been registered with patch baselines.
  ##   body: JObject (required)
  var body_603876 = newJObject()
  if body != nil:
    body_603876 = body
  result = call_603875.call(nil, nil, nil, nil, body_603876)

var describePatchGroups* = Call_DescribePatchGroups_603862(
    name: "describePatchGroups", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribePatchGroups",
    validator: validate_DescribePatchGroups_603863, base: "/",
    url: url_DescribePatchGroups_603864, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribePatchProperties_603877 = ref object of OpenApiRestCall_602466
proc url_DescribePatchProperties_603879(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribePatchProperties_603878(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Lists the properties of available patches organized by product, product family, classification, severity, and other properties of available patches. You can use the reported properties in the filters you specify in requests for actions such as <a>CreatePatchBaseline</a>, <a>UpdatePatchBaseline</a>, <a>DescribeAvailablePatches</a>, and <a>DescribePatchBaselines</a>.</p> <p>The following section lists the properties that can be used in filters for each major operating system type:</p> <dl> <dt>WINDOWS</dt> <dd> <p>Valid properties: PRODUCT, PRODUCT_FAMILY, CLASSIFICATION, MSRC_SEVERITY</p> </dd> <dt>AMAZON_LINUX</dt> <dd> <p>Valid properties: PRODUCT, CLASSIFICATION, SEVERITY</p> </dd> <dt>AMAZON_LINUX_2</dt> <dd> <p>Valid properties: PRODUCT, CLASSIFICATION, SEVERITY</p> </dd> <dt>UBUNTU </dt> <dd> <p>Valid properties: PRODUCT, PRIORITY</p> </dd> <dt>REDHAT_ENTERPRISE_LINUX</dt> <dd> <p>Valid properties: PRODUCT, CLASSIFICATION, SEVERITY</p> </dd> <dt>SUSE</dt> <dd> <p>Valid properties: PRODUCT, CLASSIFICATION, SEVERITY</p> </dd> <dt>CENTOS</dt> <dd> <p>Valid properties: PRODUCT, CLASSIFICATION, SEVERITY</p> </dd> </dl>
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
  var valid_603880 = header.getOrDefault("X-Amz-Date")
  valid_603880 = validateParameter(valid_603880, JString, required = false,
                                 default = nil)
  if valid_603880 != nil:
    section.add "X-Amz-Date", valid_603880
  var valid_603881 = header.getOrDefault("X-Amz-Security-Token")
  valid_603881 = validateParameter(valid_603881, JString, required = false,
                                 default = nil)
  if valid_603881 != nil:
    section.add "X-Amz-Security-Token", valid_603881
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603882 = header.getOrDefault("X-Amz-Target")
  valid_603882 = validateParameter(valid_603882, JString, required = true, default = newJString(
      "AmazonSSM.DescribePatchProperties"))
  if valid_603882 != nil:
    section.add "X-Amz-Target", valid_603882
  var valid_603883 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603883 = validateParameter(valid_603883, JString, required = false,
                                 default = nil)
  if valid_603883 != nil:
    section.add "X-Amz-Content-Sha256", valid_603883
  var valid_603884 = header.getOrDefault("X-Amz-Algorithm")
  valid_603884 = validateParameter(valid_603884, JString, required = false,
                                 default = nil)
  if valid_603884 != nil:
    section.add "X-Amz-Algorithm", valid_603884
  var valid_603885 = header.getOrDefault("X-Amz-Signature")
  valid_603885 = validateParameter(valid_603885, JString, required = false,
                                 default = nil)
  if valid_603885 != nil:
    section.add "X-Amz-Signature", valid_603885
  var valid_603886 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603886 = validateParameter(valid_603886, JString, required = false,
                                 default = nil)
  if valid_603886 != nil:
    section.add "X-Amz-SignedHeaders", valid_603886
  var valid_603887 = header.getOrDefault("X-Amz-Credential")
  valid_603887 = validateParameter(valid_603887, JString, required = false,
                                 default = nil)
  if valid_603887 != nil:
    section.add "X-Amz-Credential", valid_603887
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603889: Call_DescribePatchProperties_603877; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists the properties of available patches organized by product, product family, classification, severity, and other properties of available patches. You can use the reported properties in the filters you specify in requests for actions such as <a>CreatePatchBaseline</a>, <a>UpdatePatchBaseline</a>, <a>DescribeAvailablePatches</a>, and <a>DescribePatchBaselines</a>.</p> <p>The following section lists the properties that can be used in filters for each major operating system type:</p> <dl> <dt>WINDOWS</dt> <dd> <p>Valid properties: PRODUCT, PRODUCT_FAMILY, CLASSIFICATION, MSRC_SEVERITY</p> </dd> <dt>AMAZON_LINUX</dt> <dd> <p>Valid properties: PRODUCT, CLASSIFICATION, SEVERITY</p> </dd> <dt>AMAZON_LINUX_2</dt> <dd> <p>Valid properties: PRODUCT, CLASSIFICATION, SEVERITY</p> </dd> <dt>UBUNTU </dt> <dd> <p>Valid properties: PRODUCT, PRIORITY</p> </dd> <dt>REDHAT_ENTERPRISE_LINUX</dt> <dd> <p>Valid properties: PRODUCT, CLASSIFICATION, SEVERITY</p> </dd> <dt>SUSE</dt> <dd> <p>Valid properties: PRODUCT, CLASSIFICATION, SEVERITY</p> </dd> <dt>CENTOS</dt> <dd> <p>Valid properties: PRODUCT, CLASSIFICATION, SEVERITY</p> </dd> </dl>
  ## 
  let valid = call_603889.validator(path, query, header, formData, body)
  let scheme = call_603889.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603889.url(scheme.get, call_603889.host, call_603889.base,
                         call_603889.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603889, url, valid)

proc call*(call_603890: Call_DescribePatchProperties_603877; body: JsonNode): Recallable =
  ## describePatchProperties
  ## <p>Lists the properties of available patches organized by product, product family, classification, severity, and other properties of available patches. You can use the reported properties in the filters you specify in requests for actions such as <a>CreatePatchBaseline</a>, <a>UpdatePatchBaseline</a>, <a>DescribeAvailablePatches</a>, and <a>DescribePatchBaselines</a>.</p> <p>The following section lists the properties that can be used in filters for each major operating system type:</p> <dl> <dt>WINDOWS</dt> <dd> <p>Valid properties: PRODUCT, PRODUCT_FAMILY, CLASSIFICATION, MSRC_SEVERITY</p> </dd> <dt>AMAZON_LINUX</dt> <dd> <p>Valid properties: PRODUCT, CLASSIFICATION, SEVERITY</p> </dd> <dt>AMAZON_LINUX_2</dt> <dd> <p>Valid properties: PRODUCT, CLASSIFICATION, SEVERITY</p> </dd> <dt>UBUNTU </dt> <dd> <p>Valid properties: PRODUCT, PRIORITY</p> </dd> <dt>REDHAT_ENTERPRISE_LINUX</dt> <dd> <p>Valid properties: PRODUCT, CLASSIFICATION, SEVERITY</p> </dd> <dt>SUSE</dt> <dd> <p>Valid properties: PRODUCT, CLASSIFICATION, SEVERITY</p> </dd> <dt>CENTOS</dt> <dd> <p>Valid properties: PRODUCT, CLASSIFICATION, SEVERITY</p> </dd> </dl>
  ##   body: JObject (required)
  var body_603891 = newJObject()
  if body != nil:
    body_603891 = body
  result = call_603890.call(nil, nil, nil, nil, body_603891)

var describePatchProperties* = Call_DescribePatchProperties_603877(
    name: "describePatchProperties", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribePatchProperties",
    validator: validate_DescribePatchProperties_603878, base: "/",
    url: url_DescribePatchProperties_603879, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeSessions_603892 = ref object of OpenApiRestCall_602466
proc url_DescribeSessions_603894(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeSessions_603893(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Retrieves a list of all active sessions (both connected and disconnected) or terminated sessions from the past 30 days.
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
  var valid_603895 = header.getOrDefault("X-Amz-Date")
  valid_603895 = validateParameter(valid_603895, JString, required = false,
                                 default = nil)
  if valid_603895 != nil:
    section.add "X-Amz-Date", valid_603895
  var valid_603896 = header.getOrDefault("X-Amz-Security-Token")
  valid_603896 = validateParameter(valid_603896, JString, required = false,
                                 default = nil)
  if valid_603896 != nil:
    section.add "X-Amz-Security-Token", valid_603896
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603897 = header.getOrDefault("X-Amz-Target")
  valid_603897 = validateParameter(valid_603897, JString, required = true, default = newJString(
      "AmazonSSM.DescribeSessions"))
  if valid_603897 != nil:
    section.add "X-Amz-Target", valid_603897
  var valid_603898 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603898 = validateParameter(valid_603898, JString, required = false,
                                 default = nil)
  if valid_603898 != nil:
    section.add "X-Amz-Content-Sha256", valid_603898
  var valid_603899 = header.getOrDefault("X-Amz-Algorithm")
  valid_603899 = validateParameter(valid_603899, JString, required = false,
                                 default = nil)
  if valid_603899 != nil:
    section.add "X-Amz-Algorithm", valid_603899
  var valid_603900 = header.getOrDefault("X-Amz-Signature")
  valid_603900 = validateParameter(valid_603900, JString, required = false,
                                 default = nil)
  if valid_603900 != nil:
    section.add "X-Amz-Signature", valid_603900
  var valid_603901 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603901 = validateParameter(valid_603901, JString, required = false,
                                 default = nil)
  if valid_603901 != nil:
    section.add "X-Amz-SignedHeaders", valid_603901
  var valid_603902 = header.getOrDefault("X-Amz-Credential")
  valid_603902 = validateParameter(valid_603902, JString, required = false,
                                 default = nil)
  if valid_603902 != nil:
    section.add "X-Amz-Credential", valid_603902
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603904: Call_DescribeSessions_603892; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of all active sessions (both connected and disconnected) or terminated sessions from the past 30 days.
  ## 
  let valid = call_603904.validator(path, query, header, formData, body)
  let scheme = call_603904.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603904.url(scheme.get, call_603904.host, call_603904.base,
                         call_603904.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603904, url, valid)

proc call*(call_603905: Call_DescribeSessions_603892; body: JsonNode): Recallable =
  ## describeSessions
  ## Retrieves a list of all active sessions (both connected and disconnected) or terminated sessions from the past 30 days.
  ##   body: JObject (required)
  var body_603906 = newJObject()
  if body != nil:
    body_603906 = body
  result = call_603905.call(nil, nil, nil, nil, body_603906)

var describeSessions* = Call_DescribeSessions_603892(name: "describeSessions",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeSessions",
    validator: validate_DescribeSessions_603893, base: "/",
    url: url_DescribeSessions_603894, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAutomationExecution_603907 = ref object of OpenApiRestCall_602466
proc url_GetAutomationExecution_603909(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetAutomationExecution_603908(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Get detailed information about a particular Automation execution.
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
  var valid_603910 = header.getOrDefault("X-Amz-Date")
  valid_603910 = validateParameter(valid_603910, JString, required = false,
                                 default = nil)
  if valid_603910 != nil:
    section.add "X-Amz-Date", valid_603910
  var valid_603911 = header.getOrDefault("X-Amz-Security-Token")
  valid_603911 = validateParameter(valid_603911, JString, required = false,
                                 default = nil)
  if valid_603911 != nil:
    section.add "X-Amz-Security-Token", valid_603911
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603912 = header.getOrDefault("X-Amz-Target")
  valid_603912 = validateParameter(valid_603912, JString, required = true, default = newJString(
      "AmazonSSM.GetAutomationExecution"))
  if valid_603912 != nil:
    section.add "X-Amz-Target", valid_603912
  var valid_603913 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603913 = validateParameter(valid_603913, JString, required = false,
                                 default = nil)
  if valid_603913 != nil:
    section.add "X-Amz-Content-Sha256", valid_603913
  var valid_603914 = header.getOrDefault("X-Amz-Algorithm")
  valid_603914 = validateParameter(valid_603914, JString, required = false,
                                 default = nil)
  if valid_603914 != nil:
    section.add "X-Amz-Algorithm", valid_603914
  var valid_603915 = header.getOrDefault("X-Amz-Signature")
  valid_603915 = validateParameter(valid_603915, JString, required = false,
                                 default = nil)
  if valid_603915 != nil:
    section.add "X-Amz-Signature", valid_603915
  var valid_603916 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603916 = validateParameter(valid_603916, JString, required = false,
                                 default = nil)
  if valid_603916 != nil:
    section.add "X-Amz-SignedHeaders", valid_603916
  var valid_603917 = header.getOrDefault("X-Amz-Credential")
  valid_603917 = validateParameter(valid_603917, JString, required = false,
                                 default = nil)
  if valid_603917 != nil:
    section.add "X-Amz-Credential", valid_603917
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603919: Call_GetAutomationExecution_603907; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Get detailed information about a particular Automation execution.
  ## 
  let valid = call_603919.validator(path, query, header, formData, body)
  let scheme = call_603919.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603919.url(scheme.get, call_603919.host, call_603919.base,
                         call_603919.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603919, url, valid)

proc call*(call_603920: Call_GetAutomationExecution_603907; body: JsonNode): Recallable =
  ## getAutomationExecution
  ## Get detailed information about a particular Automation execution.
  ##   body: JObject (required)
  var body_603921 = newJObject()
  if body != nil:
    body_603921 = body
  result = call_603920.call(nil, nil, nil, nil, body_603921)

var getAutomationExecution* = Call_GetAutomationExecution_603907(
    name: "getAutomationExecution", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetAutomationExecution",
    validator: validate_GetAutomationExecution_603908, base: "/",
    url: url_GetAutomationExecution_603909, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCommandInvocation_603922 = ref object of OpenApiRestCall_602466
proc url_GetCommandInvocation_603924(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCommandInvocation_603923(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns detailed information about command execution for an invocation or plugin. 
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
  var valid_603925 = header.getOrDefault("X-Amz-Date")
  valid_603925 = validateParameter(valid_603925, JString, required = false,
                                 default = nil)
  if valid_603925 != nil:
    section.add "X-Amz-Date", valid_603925
  var valid_603926 = header.getOrDefault("X-Amz-Security-Token")
  valid_603926 = validateParameter(valid_603926, JString, required = false,
                                 default = nil)
  if valid_603926 != nil:
    section.add "X-Amz-Security-Token", valid_603926
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603927 = header.getOrDefault("X-Amz-Target")
  valid_603927 = validateParameter(valid_603927, JString, required = true, default = newJString(
      "AmazonSSM.GetCommandInvocation"))
  if valid_603927 != nil:
    section.add "X-Amz-Target", valid_603927
  var valid_603928 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603928 = validateParameter(valid_603928, JString, required = false,
                                 default = nil)
  if valid_603928 != nil:
    section.add "X-Amz-Content-Sha256", valid_603928
  var valid_603929 = header.getOrDefault("X-Amz-Algorithm")
  valid_603929 = validateParameter(valid_603929, JString, required = false,
                                 default = nil)
  if valid_603929 != nil:
    section.add "X-Amz-Algorithm", valid_603929
  var valid_603930 = header.getOrDefault("X-Amz-Signature")
  valid_603930 = validateParameter(valid_603930, JString, required = false,
                                 default = nil)
  if valid_603930 != nil:
    section.add "X-Amz-Signature", valid_603930
  var valid_603931 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603931 = validateParameter(valid_603931, JString, required = false,
                                 default = nil)
  if valid_603931 != nil:
    section.add "X-Amz-SignedHeaders", valid_603931
  var valid_603932 = header.getOrDefault("X-Amz-Credential")
  valid_603932 = validateParameter(valid_603932, JString, required = false,
                                 default = nil)
  if valid_603932 != nil:
    section.add "X-Amz-Credential", valid_603932
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603934: Call_GetCommandInvocation_603922; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns detailed information about command execution for an invocation or plugin. 
  ## 
  let valid = call_603934.validator(path, query, header, formData, body)
  let scheme = call_603934.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603934.url(scheme.get, call_603934.host, call_603934.base,
                         call_603934.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603934, url, valid)

proc call*(call_603935: Call_GetCommandInvocation_603922; body: JsonNode): Recallable =
  ## getCommandInvocation
  ## Returns detailed information about command execution for an invocation or plugin. 
  ##   body: JObject (required)
  var body_603936 = newJObject()
  if body != nil:
    body_603936 = body
  result = call_603935.call(nil, nil, nil, nil, body_603936)

var getCommandInvocation* = Call_GetCommandInvocation_603922(
    name: "getCommandInvocation", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetCommandInvocation",
    validator: validate_GetCommandInvocation_603923, base: "/",
    url: url_GetCommandInvocation_603924, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetConnectionStatus_603937 = ref object of OpenApiRestCall_602466
proc url_GetConnectionStatus_603939(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetConnectionStatus_603938(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Retrieves the Session Manager connection status for an instance to determine whether it is connected and ready to receive Session Manager connections.
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
  var valid_603940 = header.getOrDefault("X-Amz-Date")
  valid_603940 = validateParameter(valid_603940, JString, required = false,
                                 default = nil)
  if valid_603940 != nil:
    section.add "X-Amz-Date", valid_603940
  var valid_603941 = header.getOrDefault("X-Amz-Security-Token")
  valid_603941 = validateParameter(valid_603941, JString, required = false,
                                 default = nil)
  if valid_603941 != nil:
    section.add "X-Amz-Security-Token", valid_603941
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603942 = header.getOrDefault("X-Amz-Target")
  valid_603942 = validateParameter(valid_603942, JString, required = true, default = newJString(
      "AmazonSSM.GetConnectionStatus"))
  if valid_603942 != nil:
    section.add "X-Amz-Target", valid_603942
  var valid_603943 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603943 = validateParameter(valid_603943, JString, required = false,
                                 default = nil)
  if valid_603943 != nil:
    section.add "X-Amz-Content-Sha256", valid_603943
  var valid_603944 = header.getOrDefault("X-Amz-Algorithm")
  valid_603944 = validateParameter(valid_603944, JString, required = false,
                                 default = nil)
  if valid_603944 != nil:
    section.add "X-Amz-Algorithm", valid_603944
  var valid_603945 = header.getOrDefault("X-Amz-Signature")
  valid_603945 = validateParameter(valid_603945, JString, required = false,
                                 default = nil)
  if valid_603945 != nil:
    section.add "X-Amz-Signature", valid_603945
  var valid_603946 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603946 = validateParameter(valid_603946, JString, required = false,
                                 default = nil)
  if valid_603946 != nil:
    section.add "X-Amz-SignedHeaders", valid_603946
  var valid_603947 = header.getOrDefault("X-Amz-Credential")
  valid_603947 = validateParameter(valid_603947, JString, required = false,
                                 default = nil)
  if valid_603947 != nil:
    section.add "X-Amz-Credential", valid_603947
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603949: Call_GetConnectionStatus_603937; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the Session Manager connection status for an instance to determine whether it is connected and ready to receive Session Manager connections.
  ## 
  let valid = call_603949.validator(path, query, header, formData, body)
  let scheme = call_603949.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603949.url(scheme.get, call_603949.host, call_603949.base,
                         call_603949.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603949, url, valid)

proc call*(call_603950: Call_GetConnectionStatus_603937; body: JsonNode): Recallable =
  ## getConnectionStatus
  ## Retrieves the Session Manager connection status for an instance to determine whether it is connected and ready to receive Session Manager connections.
  ##   body: JObject (required)
  var body_603951 = newJObject()
  if body != nil:
    body_603951 = body
  result = call_603950.call(nil, nil, nil, nil, body_603951)

var getConnectionStatus* = Call_GetConnectionStatus_603937(
    name: "getConnectionStatus", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetConnectionStatus",
    validator: validate_GetConnectionStatus_603938, base: "/",
    url: url_GetConnectionStatus_603939, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDefaultPatchBaseline_603952 = ref object of OpenApiRestCall_602466
proc url_GetDefaultPatchBaseline_603954(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDefaultPatchBaseline_603953(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Retrieves the default patch baseline. Note that Systems Manager supports creating multiple default patch baselines. For example, you can create a default patch baseline for each operating system.</p> <p>If you do not specify an operating system value, the default patch baseline for Windows is returned.</p>
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
  var valid_603955 = header.getOrDefault("X-Amz-Date")
  valid_603955 = validateParameter(valid_603955, JString, required = false,
                                 default = nil)
  if valid_603955 != nil:
    section.add "X-Amz-Date", valid_603955
  var valid_603956 = header.getOrDefault("X-Amz-Security-Token")
  valid_603956 = validateParameter(valid_603956, JString, required = false,
                                 default = nil)
  if valid_603956 != nil:
    section.add "X-Amz-Security-Token", valid_603956
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603957 = header.getOrDefault("X-Amz-Target")
  valid_603957 = validateParameter(valid_603957, JString, required = true, default = newJString(
      "AmazonSSM.GetDefaultPatchBaseline"))
  if valid_603957 != nil:
    section.add "X-Amz-Target", valid_603957
  var valid_603958 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603958 = validateParameter(valid_603958, JString, required = false,
                                 default = nil)
  if valid_603958 != nil:
    section.add "X-Amz-Content-Sha256", valid_603958
  var valid_603959 = header.getOrDefault("X-Amz-Algorithm")
  valid_603959 = validateParameter(valid_603959, JString, required = false,
                                 default = nil)
  if valid_603959 != nil:
    section.add "X-Amz-Algorithm", valid_603959
  var valid_603960 = header.getOrDefault("X-Amz-Signature")
  valid_603960 = validateParameter(valid_603960, JString, required = false,
                                 default = nil)
  if valid_603960 != nil:
    section.add "X-Amz-Signature", valid_603960
  var valid_603961 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603961 = validateParameter(valid_603961, JString, required = false,
                                 default = nil)
  if valid_603961 != nil:
    section.add "X-Amz-SignedHeaders", valid_603961
  var valid_603962 = header.getOrDefault("X-Amz-Credential")
  valid_603962 = validateParameter(valid_603962, JString, required = false,
                                 default = nil)
  if valid_603962 != nil:
    section.add "X-Amz-Credential", valid_603962
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603964: Call_GetDefaultPatchBaseline_603952; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves the default patch baseline. Note that Systems Manager supports creating multiple default patch baselines. For example, you can create a default patch baseline for each operating system.</p> <p>If you do not specify an operating system value, the default patch baseline for Windows is returned.</p>
  ## 
  let valid = call_603964.validator(path, query, header, formData, body)
  let scheme = call_603964.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603964.url(scheme.get, call_603964.host, call_603964.base,
                         call_603964.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603964, url, valid)

proc call*(call_603965: Call_GetDefaultPatchBaseline_603952; body: JsonNode): Recallable =
  ## getDefaultPatchBaseline
  ## <p>Retrieves the default patch baseline. Note that Systems Manager supports creating multiple default patch baselines. For example, you can create a default patch baseline for each operating system.</p> <p>If you do not specify an operating system value, the default patch baseline for Windows is returned.</p>
  ##   body: JObject (required)
  var body_603966 = newJObject()
  if body != nil:
    body_603966 = body
  result = call_603965.call(nil, nil, nil, nil, body_603966)

var getDefaultPatchBaseline* = Call_GetDefaultPatchBaseline_603952(
    name: "getDefaultPatchBaseline", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetDefaultPatchBaseline",
    validator: validate_GetDefaultPatchBaseline_603953, base: "/",
    url: url_GetDefaultPatchBaseline_603954, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeployablePatchSnapshotForInstance_603967 = ref object of OpenApiRestCall_602466
proc url_GetDeployablePatchSnapshotForInstance_603969(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeployablePatchSnapshotForInstance_603968(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves the current snapshot for the patch baseline the instance uses. This API is primarily used by the AWS-RunPatchBaseline Systems Manager document. 
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
  var valid_603970 = header.getOrDefault("X-Amz-Date")
  valid_603970 = validateParameter(valid_603970, JString, required = false,
                                 default = nil)
  if valid_603970 != nil:
    section.add "X-Amz-Date", valid_603970
  var valid_603971 = header.getOrDefault("X-Amz-Security-Token")
  valid_603971 = validateParameter(valid_603971, JString, required = false,
                                 default = nil)
  if valid_603971 != nil:
    section.add "X-Amz-Security-Token", valid_603971
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603972 = header.getOrDefault("X-Amz-Target")
  valid_603972 = validateParameter(valid_603972, JString, required = true, default = newJString(
      "AmazonSSM.GetDeployablePatchSnapshotForInstance"))
  if valid_603972 != nil:
    section.add "X-Amz-Target", valid_603972
  var valid_603973 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603973 = validateParameter(valid_603973, JString, required = false,
                                 default = nil)
  if valid_603973 != nil:
    section.add "X-Amz-Content-Sha256", valid_603973
  var valid_603974 = header.getOrDefault("X-Amz-Algorithm")
  valid_603974 = validateParameter(valid_603974, JString, required = false,
                                 default = nil)
  if valid_603974 != nil:
    section.add "X-Amz-Algorithm", valid_603974
  var valid_603975 = header.getOrDefault("X-Amz-Signature")
  valid_603975 = validateParameter(valid_603975, JString, required = false,
                                 default = nil)
  if valid_603975 != nil:
    section.add "X-Amz-Signature", valid_603975
  var valid_603976 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603976 = validateParameter(valid_603976, JString, required = false,
                                 default = nil)
  if valid_603976 != nil:
    section.add "X-Amz-SignedHeaders", valid_603976
  var valid_603977 = header.getOrDefault("X-Amz-Credential")
  valid_603977 = validateParameter(valid_603977, JString, required = false,
                                 default = nil)
  if valid_603977 != nil:
    section.add "X-Amz-Credential", valid_603977
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603979: Call_GetDeployablePatchSnapshotForInstance_603967;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves the current snapshot for the patch baseline the instance uses. This API is primarily used by the AWS-RunPatchBaseline Systems Manager document. 
  ## 
  let valid = call_603979.validator(path, query, header, formData, body)
  let scheme = call_603979.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603979.url(scheme.get, call_603979.host, call_603979.base,
                         call_603979.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603979, url, valid)

proc call*(call_603980: Call_GetDeployablePatchSnapshotForInstance_603967;
          body: JsonNode): Recallable =
  ## getDeployablePatchSnapshotForInstance
  ## Retrieves the current snapshot for the patch baseline the instance uses. This API is primarily used by the AWS-RunPatchBaseline Systems Manager document. 
  ##   body: JObject (required)
  var body_603981 = newJObject()
  if body != nil:
    body_603981 = body
  result = call_603980.call(nil, nil, nil, nil, body_603981)

var getDeployablePatchSnapshotForInstance* = Call_GetDeployablePatchSnapshotForInstance_603967(
    name: "getDeployablePatchSnapshotForInstance", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetDeployablePatchSnapshotForInstance",
    validator: validate_GetDeployablePatchSnapshotForInstance_603968, base: "/",
    url: url_GetDeployablePatchSnapshotForInstance_603969,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDocument_603982 = ref object of OpenApiRestCall_602466
proc url_GetDocument_603984(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDocument_603983(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the contents of the specified Systems Manager document.
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
  var valid_603985 = header.getOrDefault("X-Amz-Date")
  valid_603985 = validateParameter(valid_603985, JString, required = false,
                                 default = nil)
  if valid_603985 != nil:
    section.add "X-Amz-Date", valid_603985
  var valid_603986 = header.getOrDefault("X-Amz-Security-Token")
  valid_603986 = validateParameter(valid_603986, JString, required = false,
                                 default = nil)
  if valid_603986 != nil:
    section.add "X-Amz-Security-Token", valid_603986
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603987 = header.getOrDefault("X-Amz-Target")
  valid_603987 = validateParameter(valid_603987, JString, required = true,
                                 default = newJString("AmazonSSM.GetDocument"))
  if valid_603987 != nil:
    section.add "X-Amz-Target", valid_603987
  var valid_603988 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603988 = validateParameter(valid_603988, JString, required = false,
                                 default = nil)
  if valid_603988 != nil:
    section.add "X-Amz-Content-Sha256", valid_603988
  var valid_603989 = header.getOrDefault("X-Amz-Algorithm")
  valid_603989 = validateParameter(valid_603989, JString, required = false,
                                 default = nil)
  if valid_603989 != nil:
    section.add "X-Amz-Algorithm", valid_603989
  var valid_603990 = header.getOrDefault("X-Amz-Signature")
  valid_603990 = validateParameter(valid_603990, JString, required = false,
                                 default = nil)
  if valid_603990 != nil:
    section.add "X-Amz-Signature", valid_603990
  var valid_603991 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603991 = validateParameter(valid_603991, JString, required = false,
                                 default = nil)
  if valid_603991 != nil:
    section.add "X-Amz-SignedHeaders", valid_603991
  var valid_603992 = header.getOrDefault("X-Amz-Credential")
  valid_603992 = validateParameter(valid_603992, JString, required = false,
                                 default = nil)
  if valid_603992 != nil:
    section.add "X-Amz-Credential", valid_603992
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603994: Call_GetDocument_603982; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the contents of the specified Systems Manager document.
  ## 
  let valid = call_603994.validator(path, query, header, formData, body)
  let scheme = call_603994.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603994.url(scheme.get, call_603994.host, call_603994.base,
                         call_603994.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603994, url, valid)

proc call*(call_603995: Call_GetDocument_603982; body: JsonNode): Recallable =
  ## getDocument
  ## Gets the contents of the specified Systems Manager document.
  ##   body: JObject (required)
  var body_603996 = newJObject()
  if body != nil:
    body_603996 = body
  result = call_603995.call(nil, nil, nil, nil, body_603996)

var getDocument* = Call_GetDocument_603982(name: "getDocument",
                                        meth: HttpMethod.HttpPost,
                                        host: "ssm.amazonaws.com", route: "/#X-Amz-Target=AmazonSSM.GetDocument",
                                        validator: validate_GetDocument_603983,
                                        base: "/", url: url_GetDocument_603984,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetInventory_603997 = ref object of OpenApiRestCall_602466
proc url_GetInventory_603999(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetInventory_603998(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Query inventory information.
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
  var valid_604000 = header.getOrDefault("X-Amz-Date")
  valid_604000 = validateParameter(valid_604000, JString, required = false,
                                 default = nil)
  if valid_604000 != nil:
    section.add "X-Amz-Date", valid_604000
  var valid_604001 = header.getOrDefault("X-Amz-Security-Token")
  valid_604001 = validateParameter(valid_604001, JString, required = false,
                                 default = nil)
  if valid_604001 != nil:
    section.add "X-Amz-Security-Token", valid_604001
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604002 = header.getOrDefault("X-Amz-Target")
  valid_604002 = validateParameter(valid_604002, JString, required = true,
                                 default = newJString("AmazonSSM.GetInventory"))
  if valid_604002 != nil:
    section.add "X-Amz-Target", valid_604002
  var valid_604003 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604003 = validateParameter(valid_604003, JString, required = false,
                                 default = nil)
  if valid_604003 != nil:
    section.add "X-Amz-Content-Sha256", valid_604003
  var valid_604004 = header.getOrDefault("X-Amz-Algorithm")
  valid_604004 = validateParameter(valid_604004, JString, required = false,
                                 default = nil)
  if valid_604004 != nil:
    section.add "X-Amz-Algorithm", valid_604004
  var valid_604005 = header.getOrDefault("X-Amz-Signature")
  valid_604005 = validateParameter(valid_604005, JString, required = false,
                                 default = nil)
  if valid_604005 != nil:
    section.add "X-Amz-Signature", valid_604005
  var valid_604006 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604006 = validateParameter(valid_604006, JString, required = false,
                                 default = nil)
  if valid_604006 != nil:
    section.add "X-Amz-SignedHeaders", valid_604006
  var valid_604007 = header.getOrDefault("X-Amz-Credential")
  valid_604007 = validateParameter(valid_604007, JString, required = false,
                                 default = nil)
  if valid_604007 != nil:
    section.add "X-Amz-Credential", valid_604007
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604009: Call_GetInventory_603997; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Query inventory information.
  ## 
  let valid = call_604009.validator(path, query, header, formData, body)
  let scheme = call_604009.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604009.url(scheme.get, call_604009.host, call_604009.base,
                         call_604009.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604009, url, valid)

proc call*(call_604010: Call_GetInventory_603997; body: JsonNode): Recallable =
  ## getInventory
  ## Query inventory information.
  ##   body: JObject (required)
  var body_604011 = newJObject()
  if body != nil:
    body_604011 = body
  result = call_604010.call(nil, nil, nil, nil, body_604011)

var getInventory* = Call_GetInventory_603997(name: "getInventory",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetInventory",
    validator: validate_GetInventory_603998, base: "/", url: url_GetInventory_603999,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetInventorySchema_604012 = ref object of OpenApiRestCall_602466
proc url_GetInventorySchema_604014(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetInventorySchema_604013(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Return a list of inventory type names for the account, or return a list of attribute names for a specific Inventory item type. 
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
  var valid_604015 = header.getOrDefault("X-Amz-Date")
  valid_604015 = validateParameter(valid_604015, JString, required = false,
                                 default = nil)
  if valid_604015 != nil:
    section.add "X-Amz-Date", valid_604015
  var valid_604016 = header.getOrDefault("X-Amz-Security-Token")
  valid_604016 = validateParameter(valid_604016, JString, required = false,
                                 default = nil)
  if valid_604016 != nil:
    section.add "X-Amz-Security-Token", valid_604016
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604017 = header.getOrDefault("X-Amz-Target")
  valid_604017 = validateParameter(valid_604017, JString, required = true, default = newJString(
      "AmazonSSM.GetInventorySchema"))
  if valid_604017 != nil:
    section.add "X-Amz-Target", valid_604017
  var valid_604018 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604018 = validateParameter(valid_604018, JString, required = false,
                                 default = nil)
  if valid_604018 != nil:
    section.add "X-Amz-Content-Sha256", valid_604018
  var valid_604019 = header.getOrDefault("X-Amz-Algorithm")
  valid_604019 = validateParameter(valid_604019, JString, required = false,
                                 default = nil)
  if valid_604019 != nil:
    section.add "X-Amz-Algorithm", valid_604019
  var valid_604020 = header.getOrDefault("X-Amz-Signature")
  valid_604020 = validateParameter(valid_604020, JString, required = false,
                                 default = nil)
  if valid_604020 != nil:
    section.add "X-Amz-Signature", valid_604020
  var valid_604021 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604021 = validateParameter(valid_604021, JString, required = false,
                                 default = nil)
  if valid_604021 != nil:
    section.add "X-Amz-SignedHeaders", valid_604021
  var valid_604022 = header.getOrDefault("X-Amz-Credential")
  valid_604022 = validateParameter(valid_604022, JString, required = false,
                                 default = nil)
  if valid_604022 != nil:
    section.add "X-Amz-Credential", valid_604022
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604024: Call_GetInventorySchema_604012; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Return a list of inventory type names for the account, or return a list of attribute names for a specific Inventory item type. 
  ## 
  let valid = call_604024.validator(path, query, header, formData, body)
  let scheme = call_604024.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604024.url(scheme.get, call_604024.host, call_604024.base,
                         call_604024.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604024, url, valid)

proc call*(call_604025: Call_GetInventorySchema_604012; body: JsonNode): Recallable =
  ## getInventorySchema
  ## Return a list of inventory type names for the account, or return a list of attribute names for a specific Inventory item type. 
  ##   body: JObject (required)
  var body_604026 = newJObject()
  if body != nil:
    body_604026 = body
  result = call_604025.call(nil, nil, nil, nil, body_604026)

var getInventorySchema* = Call_GetInventorySchema_604012(
    name: "getInventorySchema", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetInventorySchema",
    validator: validate_GetInventorySchema_604013, base: "/",
    url: url_GetInventorySchema_604014, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMaintenanceWindow_604027 = ref object of OpenApiRestCall_602466
proc url_GetMaintenanceWindow_604029(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetMaintenanceWindow_604028(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves a maintenance window.
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
  var valid_604030 = header.getOrDefault("X-Amz-Date")
  valid_604030 = validateParameter(valid_604030, JString, required = false,
                                 default = nil)
  if valid_604030 != nil:
    section.add "X-Amz-Date", valid_604030
  var valid_604031 = header.getOrDefault("X-Amz-Security-Token")
  valid_604031 = validateParameter(valid_604031, JString, required = false,
                                 default = nil)
  if valid_604031 != nil:
    section.add "X-Amz-Security-Token", valid_604031
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604032 = header.getOrDefault("X-Amz-Target")
  valid_604032 = validateParameter(valid_604032, JString, required = true, default = newJString(
      "AmazonSSM.GetMaintenanceWindow"))
  if valid_604032 != nil:
    section.add "X-Amz-Target", valid_604032
  var valid_604033 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604033 = validateParameter(valid_604033, JString, required = false,
                                 default = nil)
  if valid_604033 != nil:
    section.add "X-Amz-Content-Sha256", valid_604033
  var valid_604034 = header.getOrDefault("X-Amz-Algorithm")
  valid_604034 = validateParameter(valid_604034, JString, required = false,
                                 default = nil)
  if valid_604034 != nil:
    section.add "X-Amz-Algorithm", valid_604034
  var valid_604035 = header.getOrDefault("X-Amz-Signature")
  valid_604035 = validateParameter(valid_604035, JString, required = false,
                                 default = nil)
  if valid_604035 != nil:
    section.add "X-Amz-Signature", valid_604035
  var valid_604036 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604036 = validateParameter(valid_604036, JString, required = false,
                                 default = nil)
  if valid_604036 != nil:
    section.add "X-Amz-SignedHeaders", valid_604036
  var valid_604037 = header.getOrDefault("X-Amz-Credential")
  valid_604037 = validateParameter(valid_604037, JString, required = false,
                                 default = nil)
  if valid_604037 != nil:
    section.add "X-Amz-Credential", valid_604037
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604039: Call_GetMaintenanceWindow_604027; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a maintenance window.
  ## 
  let valid = call_604039.validator(path, query, header, formData, body)
  let scheme = call_604039.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604039.url(scheme.get, call_604039.host, call_604039.base,
                         call_604039.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604039, url, valid)

proc call*(call_604040: Call_GetMaintenanceWindow_604027; body: JsonNode): Recallable =
  ## getMaintenanceWindow
  ## Retrieves a maintenance window.
  ##   body: JObject (required)
  var body_604041 = newJObject()
  if body != nil:
    body_604041 = body
  result = call_604040.call(nil, nil, nil, nil, body_604041)

var getMaintenanceWindow* = Call_GetMaintenanceWindow_604027(
    name: "getMaintenanceWindow", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetMaintenanceWindow",
    validator: validate_GetMaintenanceWindow_604028, base: "/",
    url: url_GetMaintenanceWindow_604029, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMaintenanceWindowExecution_604042 = ref object of OpenApiRestCall_602466
proc url_GetMaintenanceWindowExecution_604044(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetMaintenanceWindowExecution_604043(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves details about a specific a maintenance window execution.
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
  var valid_604045 = header.getOrDefault("X-Amz-Date")
  valid_604045 = validateParameter(valid_604045, JString, required = false,
                                 default = nil)
  if valid_604045 != nil:
    section.add "X-Amz-Date", valid_604045
  var valid_604046 = header.getOrDefault("X-Amz-Security-Token")
  valid_604046 = validateParameter(valid_604046, JString, required = false,
                                 default = nil)
  if valid_604046 != nil:
    section.add "X-Amz-Security-Token", valid_604046
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604047 = header.getOrDefault("X-Amz-Target")
  valid_604047 = validateParameter(valid_604047, JString, required = true, default = newJString(
      "AmazonSSM.GetMaintenanceWindowExecution"))
  if valid_604047 != nil:
    section.add "X-Amz-Target", valid_604047
  var valid_604048 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604048 = validateParameter(valid_604048, JString, required = false,
                                 default = nil)
  if valid_604048 != nil:
    section.add "X-Amz-Content-Sha256", valid_604048
  var valid_604049 = header.getOrDefault("X-Amz-Algorithm")
  valid_604049 = validateParameter(valid_604049, JString, required = false,
                                 default = nil)
  if valid_604049 != nil:
    section.add "X-Amz-Algorithm", valid_604049
  var valid_604050 = header.getOrDefault("X-Amz-Signature")
  valid_604050 = validateParameter(valid_604050, JString, required = false,
                                 default = nil)
  if valid_604050 != nil:
    section.add "X-Amz-Signature", valid_604050
  var valid_604051 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604051 = validateParameter(valid_604051, JString, required = false,
                                 default = nil)
  if valid_604051 != nil:
    section.add "X-Amz-SignedHeaders", valid_604051
  var valid_604052 = header.getOrDefault("X-Amz-Credential")
  valid_604052 = validateParameter(valid_604052, JString, required = false,
                                 default = nil)
  if valid_604052 != nil:
    section.add "X-Amz-Credential", valid_604052
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604054: Call_GetMaintenanceWindowExecution_604042; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves details about a specific a maintenance window execution.
  ## 
  let valid = call_604054.validator(path, query, header, formData, body)
  let scheme = call_604054.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604054.url(scheme.get, call_604054.host, call_604054.base,
                         call_604054.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604054, url, valid)

proc call*(call_604055: Call_GetMaintenanceWindowExecution_604042; body: JsonNode): Recallable =
  ## getMaintenanceWindowExecution
  ## Retrieves details about a specific a maintenance window execution.
  ##   body: JObject (required)
  var body_604056 = newJObject()
  if body != nil:
    body_604056 = body
  result = call_604055.call(nil, nil, nil, nil, body_604056)

var getMaintenanceWindowExecution* = Call_GetMaintenanceWindowExecution_604042(
    name: "getMaintenanceWindowExecution", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetMaintenanceWindowExecution",
    validator: validate_GetMaintenanceWindowExecution_604043, base: "/",
    url: url_GetMaintenanceWindowExecution_604044,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMaintenanceWindowExecutionTask_604057 = ref object of OpenApiRestCall_602466
proc url_GetMaintenanceWindowExecutionTask_604059(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetMaintenanceWindowExecutionTask_604058(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves the details about a specific task run as part of a maintenance window execution.
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
  var valid_604060 = header.getOrDefault("X-Amz-Date")
  valid_604060 = validateParameter(valid_604060, JString, required = false,
                                 default = nil)
  if valid_604060 != nil:
    section.add "X-Amz-Date", valid_604060
  var valid_604061 = header.getOrDefault("X-Amz-Security-Token")
  valid_604061 = validateParameter(valid_604061, JString, required = false,
                                 default = nil)
  if valid_604061 != nil:
    section.add "X-Amz-Security-Token", valid_604061
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604062 = header.getOrDefault("X-Amz-Target")
  valid_604062 = validateParameter(valid_604062, JString, required = true, default = newJString(
      "AmazonSSM.GetMaintenanceWindowExecutionTask"))
  if valid_604062 != nil:
    section.add "X-Amz-Target", valid_604062
  var valid_604063 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604063 = validateParameter(valid_604063, JString, required = false,
                                 default = nil)
  if valid_604063 != nil:
    section.add "X-Amz-Content-Sha256", valid_604063
  var valid_604064 = header.getOrDefault("X-Amz-Algorithm")
  valid_604064 = validateParameter(valid_604064, JString, required = false,
                                 default = nil)
  if valid_604064 != nil:
    section.add "X-Amz-Algorithm", valid_604064
  var valid_604065 = header.getOrDefault("X-Amz-Signature")
  valid_604065 = validateParameter(valid_604065, JString, required = false,
                                 default = nil)
  if valid_604065 != nil:
    section.add "X-Amz-Signature", valid_604065
  var valid_604066 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604066 = validateParameter(valid_604066, JString, required = false,
                                 default = nil)
  if valid_604066 != nil:
    section.add "X-Amz-SignedHeaders", valid_604066
  var valid_604067 = header.getOrDefault("X-Amz-Credential")
  valid_604067 = validateParameter(valid_604067, JString, required = false,
                                 default = nil)
  if valid_604067 != nil:
    section.add "X-Amz-Credential", valid_604067
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604069: Call_GetMaintenanceWindowExecutionTask_604057;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves the details about a specific task run as part of a maintenance window execution.
  ## 
  let valid = call_604069.validator(path, query, header, formData, body)
  let scheme = call_604069.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604069.url(scheme.get, call_604069.host, call_604069.base,
                         call_604069.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604069, url, valid)

proc call*(call_604070: Call_GetMaintenanceWindowExecutionTask_604057;
          body: JsonNode): Recallable =
  ## getMaintenanceWindowExecutionTask
  ## Retrieves the details about a specific task run as part of a maintenance window execution.
  ##   body: JObject (required)
  var body_604071 = newJObject()
  if body != nil:
    body_604071 = body
  result = call_604070.call(nil, nil, nil, nil, body_604071)

var getMaintenanceWindowExecutionTask* = Call_GetMaintenanceWindowExecutionTask_604057(
    name: "getMaintenanceWindowExecutionTask", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetMaintenanceWindowExecutionTask",
    validator: validate_GetMaintenanceWindowExecutionTask_604058, base: "/",
    url: url_GetMaintenanceWindowExecutionTask_604059,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMaintenanceWindowExecutionTaskInvocation_604072 = ref object of OpenApiRestCall_602466
proc url_GetMaintenanceWindowExecutionTaskInvocation_604074(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetMaintenanceWindowExecutionTaskInvocation_604073(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves information about a specific task running on a specific target.
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
  var valid_604075 = header.getOrDefault("X-Amz-Date")
  valid_604075 = validateParameter(valid_604075, JString, required = false,
                                 default = nil)
  if valid_604075 != nil:
    section.add "X-Amz-Date", valid_604075
  var valid_604076 = header.getOrDefault("X-Amz-Security-Token")
  valid_604076 = validateParameter(valid_604076, JString, required = false,
                                 default = nil)
  if valid_604076 != nil:
    section.add "X-Amz-Security-Token", valid_604076
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604077 = header.getOrDefault("X-Amz-Target")
  valid_604077 = validateParameter(valid_604077, JString, required = true, default = newJString(
      "AmazonSSM.GetMaintenanceWindowExecutionTaskInvocation"))
  if valid_604077 != nil:
    section.add "X-Amz-Target", valid_604077
  var valid_604078 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604078 = validateParameter(valid_604078, JString, required = false,
                                 default = nil)
  if valid_604078 != nil:
    section.add "X-Amz-Content-Sha256", valid_604078
  var valid_604079 = header.getOrDefault("X-Amz-Algorithm")
  valid_604079 = validateParameter(valid_604079, JString, required = false,
                                 default = nil)
  if valid_604079 != nil:
    section.add "X-Amz-Algorithm", valid_604079
  var valid_604080 = header.getOrDefault("X-Amz-Signature")
  valid_604080 = validateParameter(valid_604080, JString, required = false,
                                 default = nil)
  if valid_604080 != nil:
    section.add "X-Amz-Signature", valid_604080
  var valid_604081 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604081 = validateParameter(valid_604081, JString, required = false,
                                 default = nil)
  if valid_604081 != nil:
    section.add "X-Amz-SignedHeaders", valid_604081
  var valid_604082 = header.getOrDefault("X-Amz-Credential")
  valid_604082 = validateParameter(valid_604082, JString, required = false,
                                 default = nil)
  if valid_604082 != nil:
    section.add "X-Amz-Credential", valid_604082
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604084: Call_GetMaintenanceWindowExecutionTaskInvocation_604072;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves information about a specific task running on a specific target.
  ## 
  let valid = call_604084.validator(path, query, header, formData, body)
  let scheme = call_604084.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604084.url(scheme.get, call_604084.host, call_604084.base,
                         call_604084.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604084, url, valid)

proc call*(call_604085: Call_GetMaintenanceWindowExecutionTaskInvocation_604072;
          body: JsonNode): Recallable =
  ## getMaintenanceWindowExecutionTaskInvocation
  ## Retrieves information about a specific task running on a specific target.
  ##   body: JObject (required)
  var body_604086 = newJObject()
  if body != nil:
    body_604086 = body
  result = call_604085.call(nil, nil, nil, nil, body_604086)

var getMaintenanceWindowExecutionTaskInvocation* = Call_GetMaintenanceWindowExecutionTaskInvocation_604072(
    name: "getMaintenanceWindowExecutionTaskInvocation",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com", route: "/#X-Amz-Target=AmazonSSM.GetMaintenanceWindowExecutionTaskInvocation",
    validator: validate_GetMaintenanceWindowExecutionTaskInvocation_604073,
    base: "/", url: url_GetMaintenanceWindowExecutionTaskInvocation_604074,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMaintenanceWindowTask_604087 = ref object of OpenApiRestCall_602466
proc url_GetMaintenanceWindowTask_604089(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetMaintenanceWindowTask_604088(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists the tasks in a maintenance window.
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
  var valid_604090 = header.getOrDefault("X-Amz-Date")
  valid_604090 = validateParameter(valid_604090, JString, required = false,
                                 default = nil)
  if valid_604090 != nil:
    section.add "X-Amz-Date", valid_604090
  var valid_604091 = header.getOrDefault("X-Amz-Security-Token")
  valid_604091 = validateParameter(valid_604091, JString, required = false,
                                 default = nil)
  if valid_604091 != nil:
    section.add "X-Amz-Security-Token", valid_604091
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604092 = header.getOrDefault("X-Amz-Target")
  valid_604092 = validateParameter(valid_604092, JString, required = true, default = newJString(
      "AmazonSSM.GetMaintenanceWindowTask"))
  if valid_604092 != nil:
    section.add "X-Amz-Target", valid_604092
  var valid_604093 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604093 = validateParameter(valid_604093, JString, required = false,
                                 default = nil)
  if valid_604093 != nil:
    section.add "X-Amz-Content-Sha256", valid_604093
  var valid_604094 = header.getOrDefault("X-Amz-Algorithm")
  valid_604094 = validateParameter(valid_604094, JString, required = false,
                                 default = nil)
  if valid_604094 != nil:
    section.add "X-Amz-Algorithm", valid_604094
  var valid_604095 = header.getOrDefault("X-Amz-Signature")
  valid_604095 = validateParameter(valid_604095, JString, required = false,
                                 default = nil)
  if valid_604095 != nil:
    section.add "X-Amz-Signature", valid_604095
  var valid_604096 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604096 = validateParameter(valid_604096, JString, required = false,
                                 default = nil)
  if valid_604096 != nil:
    section.add "X-Amz-SignedHeaders", valid_604096
  var valid_604097 = header.getOrDefault("X-Amz-Credential")
  valid_604097 = validateParameter(valid_604097, JString, required = false,
                                 default = nil)
  if valid_604097 != nil:
    section.add "X-Amz-Credential", valid_604097
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604099: Call_GetMaintenanceWindowTask_604087; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the tasks in a maintenance window.
  ## 
  let valid = call_604099.validator(path, query, header, formData, body)
  let scheme = call_604099.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604099.url(scheme.get, call_604099.host, call_604099.base,
                         call_604099.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604099, url, valid)

proc call*(call_604100: Call_GetMaintenanceWindowTask_604087; body: JsonNode): Recallable =
  ## getMaintenanceWindowTask
  ## Lists the tasks in a maintenance window.
  ##   body: JObject (required)
  var body_604101 = newJObject()
  if body != nil:
    body_604101 = body
  result = call_604100.call(nil, nil, nil, nil, body_604101)

var getMaintenanceWindowTask* = Call_GetMaintenanceWindowTask_604087(
    name: "getMaintenanceWindowTask", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetMaintenanceWindowTask",
    validator: validate_GetMaintenanceWindowTask_604088, base: "/",
    url: url_GetMaintenanceWindowTask_604089, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetOpsItem_604102 = ref object of OpenApiRestCall_602466
proc url_GetOpsItem_604104(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetOpsItem_604103(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Get information about an OpsItem by using the ID. You must have permission in AWS Identity and Access Management (IAM) to view information about an OpsItem. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter-getting-started.html">Getting Started with OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>.</p> <p>Operations engineers and IT professionals use OpsCenter to view, investigate, and remediate operational issues impacting the performance and health of their AWS resources. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter.html">AWS Systems Manager OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>. </p>
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
  var valid_604105 = header.getOrDefault("X-Amz-Date")
  valid_604105 = validateParameter(valid_604105, JString, required = false,
                                 default = nil)
  if valid_604105 != nil:
    section.add "X-Amz-Date", valid_604105
  var valid_604106 = header.getOrDefault("X-Amz-Security-Token")
  valid_604106 = validateParameter(valid_604106, JString, required = false,
                                 default = nil)
  if valid_604106 != nil:
    section.add "X-Amz-Security-Token", valid_604106
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604107 = header.getOrDefault("X-Amz-Target")
  valid_604107 = validateParameter(valid_604107, JString, required = true,
                                 default = newJString("AmazonSSM.GetOpsItem"))
  if valid_604107 != nil:
    section.add "X-Amz-Target", valid_604107
  var valid_604108 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604108 = validateParameter(valid_604108, JString, required = false,
                                 default = nil)
  if valid_604108 != nil:
    section.add "X-Amz-Content-Sha256", valid_604108
  var valid_604109 = header.getOrDefault("X-Amz-Algorithm")
  valid_604109 = validateParameter(valid_604109, JString, required = false,
                                 default = nil)
  if valid_604109 != nil:
    section.add "X-Amz-Algorithm", valid_604109
  var valid_604110 = header.getOrDefault("X-Amz-Signature")
  valid_604110 = validateParameter(valid_604110, JString, required = false,
                                 default = nil)
  if valid_604110 != nil:
    section.add "X-Amz-Signature", valid_604110
  var valid_604111 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604111 = validateParameter(valid_604111, JString, required = false,
                                 default = nil)
  if valid_604111 != nil:
    section.add "X-Amz-SignedHeaders", valid_604111
  var valid_604112 = header.getOrDefault("X-Amz-Credential")
  valid_604112 = validateParameter(valid_604112, JString, required = false,
                                 default = nil)
  if valid_604112 != nil:
    section.add "X-Amz-Credential", valid_604112
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604114: Call_GetOpsItem_604102; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Get information about an OpsItem by using the ID. You must have permission in AWS Identity and Access Management (IAM) to view information about an OpsItem. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter-getting-started.html">Getting Started with OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>.</p> <p>Operations engineers and IT professionals use OpsCenter to view, investigate, and remediate operational issues impacting the performance and health of their AWS resources. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter.html">AWS Systems Manager OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>. </p>
  ## 
  let valid = call_604114.validator(path, query, header, formData, body)
  let scheme = call_604114.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604114.url(scheme.get, call_604114.host, call_604114.base,
                         call_604114.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604114, url, valid)

proc call*(call_604115: Call_GetOpsItem_604102; body: JsonNode): Recallable =
  ## getOpsItem
  ## <p>Get information about an OpsItem by using the ID. You must have permission in AWS Identity and Access Management (IAM) to view information about an OpsItem. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter-getting-started.html">Getting Started with OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>.</p> <p>Operations engineers and IT professionals use OpsCenter to view, investigate, and remediate operational issues impacting the performance and health of their AWS resources. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter.html">AWS Systems Manager OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>. </p>
  ##   body: JObject (required)
  var body_604116 = newJObject()
  if body != nil:
    body_604116 = body
  result = call_604115.call(nil, nil, nil, nil, body_604116)

var getOpsItem* = Call_GetOpsItem_604102(name: "getOpsItem",
                                      meth: HttpMethod.HttpPost,
                                      host: "ssm.amazonaws.com", route: "/#X-Amz-Target=AmazonSSM.GetOpsItem",
                                      validator: validate_GetOpsItem_604103,
                                      base: "/", url: url_GetOpsItem_604104,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetOpsSummary_604117 = ref object of OpenApiRestCall_602466
proc url_GetOpsSummary_604119(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetOpsSummary_604118(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## View a summary of OpsItems based on specified filters and aggregators.
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
  var valid_604120 = header.getOrDefault("X-Amz-Date")
  valid_604120 = validateParameter(valid_604120, JString, required = false,
                                 default = nil)
  if valid_604120 != nil:
    section.add "X-Amz-Date", valid_604120
  var valid_604121 = header.getOrDefault("X-Amz-Security-Token")
  valid_604121 = validateParameter(valid_604121, JString, required = false,
                                 default = nil)
  if valid_604121 != nil:
    section.add "X-Amz-Security-Token", valid_604121
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604122 = header.getOrDefault("X-Amz-Target")
  valid_604122 = validateParameter(valid_604122, JString, required = true, default = newJString(
      "AmazonSSM.GetOpsSummary"))
  if valid_604122 != nil:
    section.add "X-Amz-Target", valid_604122
  var valid_604123 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604123 = validateParameter(valid_604123, JString, required = false,
                                 default = nil)
  if valid_604123 != nil:
    section.add "X-Amz-Content-Sha256", valid_604123
  var valid_604124 = header.getOrDefault("X-Amz-Algorithm")
  valid_604124 = validateParameter(valid_604124, JString, required = false,
                                 default = nil)
  if valid_604124 != nil:
    section.add "X-Amz-Algorithm", valid_604124
  var valid_604125 = header.getOrDefault("X-Amz-Signature")
  valid_604125 = validateParameter(valid_604125, JString, required = false,
                                 default = nil)
  if valid_604125 != nil:
    section.add "X-Amz-Signature", valid_604125
  var valid_604126 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604126 = validateParameter(valid_604126, JString, required = false,
                                 default = nil)
  if valid_604126 != nil:
    section.add "X-Amz-SignedHeaders", valid_604126
  var valid_604127 = header.getOrDefault("X-Amz-Credential")
  valid_604127 = validateParameter(valid_604127, JString, required = false,
                                 default = nil)
  if valid_604127 != nil:
    section.add "X-Amz-Credential", valid_604127
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604129: Call_GetOpsSummary_604117; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## View a summary of OpsItems based on specified filters and aggregators.
  ## 
  let valid = call_604129.validator(path, query, header, formData, body)
  let scheme = call_604129.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604129.url(scheme.get, call_604129.host, call_604129.base,
                         call_604129.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604129, url, valid)

proc call*(call_604130: Call_GetOpsSummary_604117; body: JsonNode): Recallable =
  ## getOpsSummary
  ## View a summary of OpsItems based on specified filters and aggregators.
  ##   body: JObject (required)
  var body_604131 = newJObject()
  if body != nil:
    body_604131 = body
  result = call_604130.call(nil, nil, nil, nil, body_604131)

var getOpsSummary* = Call_GetOpsSummary_604117(name: "getOpsSummary",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetOpsSummary",
    validator: validate_GetOpsSummary_604118, base: "/", url: url_GetOpsSummary_604119,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetParameter_604132 = ref object of OpenApiRestCall_602466
proc url_GetParameter_604134(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetParameter_604133(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Get information about a parameter by using the parameter name. Don't confuse this API action with the <a>GetParameters</a> API action.
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
  var valid_604135 = header.getOrDefault("X-Amz-Date")
  valid_604135 = validateParameter(valid_604135, JString, required = false,
                                 default = nil)
  if valid_604135 != nil:
    section.add "X-Amz-Date", valid_604135
  var valid_604136 = header.getOrDefault("X-Amz-Security-Token")
  valid_604136 = validateParameter(valid_604136, JString, required = false,
                                 default = nil)
  if valid_604136 != nil:
    section.add "X-Amz-Security-Token", valid_604136
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604137 = header.getOrDefault("X-Amz-Target")
  valid_604137 = validateParameter(valid_604137, JString, required = true,
                                 default = newJString("AmazonSSM.GetParameter"))
  if valid_604137 != nil:
    section.add "X-Amz-Target", valid_604137
  var valid_604138 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604138 = validateParameter(valid_604138, JString, required = false,
                                 default = nil)
  if valid_604138 != nil:
    section.add "X-Amz-Content-Sha256", valid_604138
  var valid_604139 = header.getOrDefault("X-Amz-Algorithm")
  valid_604139 = validateParameter(valid_604139, JString, required = false,
                                 default = nil)
  if valid_604139 != nil:
    section.add "X-Amz-Algorithm", valid_604139
  var valid_604140 = header.getOrDefault("X-Amz-Signature")
  valid_604140 = validateParameter(valid_604140, JString, required = false,
                                 default = nil)
  if valid_604140 != nil:
    section.add "X-Amz-Signature", valid_604140
  var valid_604141 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604141 = validateParameter(valid_604141, JString, required = false,
                                 default = nil)
  if valid_604141 != nil:
    section.add "X-Amz-SignedHeaders", valid_604141
  var valid_604142 = header.getOrDefault("X-Amz-Credential")
  valid_604142 = validateParameter(valid_604142, JString, required = false,
                                 default = nil)
  if valid_604142 != nil:
    section.add "X-Amz-Credential", valid_604142
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604144: Call_GetParameter_604132; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Get information about a parameter by using the parameter name. Don't confuse this API action with the <a>GetParameters</a> API action.
  ## 
  let valid = call_604144.validator(path, query, header, formData, body)
  let scheme = call_604144.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604144.url(scheme.get, call_604144.host, call_604144.base,
                         call_604144.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604144, url, valid)

proc call*(call_604145: Call_GetParameter_604132; body: JsonNode): Recallable =
  ## getParameter
  ## Get information about a parameter by using the parameter name. Don't confuse this API action with the <a>GetParameters</a> API action.
  ##   body: JObject (required)
  var body_604146 = newJObject()
  if body != nil:
    body_604146 = body
  result = call_604145.call(nil, nil, nil, nil, body_604146)

var getParameter* = Call_GetParameter_604132(name: "getParameter",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetParameter",
    validator: validate_GetParameter_604133, base: "/", url: url_GetParameter_604134,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetParameterHistory_604147 = ref object of OpenApiRestCall_602466
proc url_GetParameterHistory_604149(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetParameterHistory_604148(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Query a list of all parameters used by the AWS account.
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
  var valid_604150 = query.getOrDefault("NextToken")
  valid_604150 = validateParameter(valid_604150, JString, required = false,
                                 default = nil)
  if valid_604150 != nil:
    section.add "NextToken", valid_604150
  var valid_604151 = query.getOrDefault("MaxResults")
  valid_604151 = validateParameter(valid_604151, JString, required = false,
                                 default = nil)
  if valid_604151 != nil:
    section.add "MaxResults", valid_604151
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
  var valid_604152 = header.getOrDefault("X-Amz-Date")
  valid_604152 = validateParameter(valid_604152, JString, required = false,
                                 default = nil)
  if valid_604152 != nil:
    section.add "X-Amz-Date", valid_604152
  var valid_604153 = header.getOrDefault("X-Amz-Security-Token")
  valid_604153 = validateParameter(valid_604153, JString, required = false,
                                 default = nil)
  if valid_604153 != nil:
    section.add "X-Amz-Security-Token", valid_604153
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604154 = header.getOrDefault("X-Amz-Target")
  valid_604154 = validateParameter(valid_604154, JString, required = true, default = newJString(
      "AmazonSSM.GetParameterHistory"))
  if valid_604154 != nil:
    section.add "X-Amz-Target", valid_604154
  var valid_604155 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604155 = validateParameter(valid_604155, JString, required = false,
                                 default = nil)
  if valid_604155 != nil:
    section.add "X-Amz-Content-Sha256", valid_604155
  var valid_604156 = header.getOrDefault("X-Amz-Algorithm")
  valid_604156 = validateParameter(valid_604156, JString, required = false,
                                 default = nil)
  if valid_604156 != nil:
    section.add "X-Amz-Algorithm", valid_604156
  var valid_604157 = header.getOrDefault("X-Amz-Signature")
  valid_604157 = validateParameter(valid_604157, JString, required = false,
                                 default = nil)
  if valid_604157 != nil:
    section.add "X-Amz-Signature", valid_604157
  var valid_604158 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604158 = validateParameter(valid_604158, JString, required = false,
                                 default = nil)
  if valid_604158 != nil:
    section.add "X-Amz-SignedHeaders", valid_604158
  var valid_604159 = header.getOrDefault("X-Amz-Credential")
  valid_604159 = validateParameter(valid_604159, JString, required = false,
                                 default = nil)
  if valid_604159 != nil:
    section.add "X-Amz-Credential", valid_604159
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604161: Call_GetParameterHistory_604147; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Query a list of all parameters used by the AWS account.
  ## 
  let valid = call_604161.validator(path, query, header, formData, body)
  let scheme = call_604161.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604161.url(scheme.get, call_604161.host, call_604161.base,
                         call_604161.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604161, url, valid)

proc call*(call_604162: Call_GetParameterHistory_604147; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## getParameterHistory
  ## Query a list of all parameters used by the AWS account.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_604163 = newJObject()
  var body_604164 = newJObject()
  add(query_604163, "NextToken", newJString(NextToken))
  if body != nil:
    body_604164 = body
  add(query_604163, "MaxResults", newJString(MaxResults))
  result = call_604162.call(nil, query_604163, nil, nil, body_604164)

var getParameterHistory* = Call_GetParameterHistory_604147(
    name: "getParameterHistory", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetParameterHistory",
    validator: validate_GetParameterHistory_604148, base: "/",
    url: url_GetParameterHistory_604149, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetParameters_604165 = ref object of OpenApiRestCall_602466
proc url_GetParameters_604167(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetParameters_604166(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Get details of a parameter. Don't confuse this API action with the <a>GetParameter</a> API action.
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
  var valid_604168 = header.getOrDefault("X-Amz-Date")
  valid_604168 = validateParameter(valid_604168, JString, required = false,
                                 default = nil)
  if valid_604168 != nil:
    section.add "X-Amz-Date", valid_604168
  var valid_604169 = header.getOrDefault("X-Amz-Security-Token")
  valid_604169 = validateParameter(valid_604169, JString, required = false,
                                 default = nil)
  if valid_604169 != nil:
    section.add "X-Amz-Security-Token", valid_604169
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604170 = header.getOrDefault("X-Amz-Target")
  valid_604170 = validateParameter(valid_604170, JString, required = true, default = newJString(
      "AmazonSSM.GetParameters"))
  if valid_604170 != nil:
    section.add "X-Amz-Target", valid_604170
  var valid_604171 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604171 = validateParameter(valid_604171, JString, required = false,
                                 default = nil)
  if valid_604171 != nil:
    section.add "X-Amz-Content-Sha256", valid_604171
  var valid_604172 = header.getOrDefault("X-Amz-Algorithm")
  valid_604172 = validateParameter(valid_604172, JString, required = false,
                                 default = nil)
  if valid_604172 != nil:
    section.add "X-Amz-Algorithm", valid_604172
  var valid_604173 = header.getOrDefault("X-Amz-Signature")
  valid_604173 = validateParameter(valid_604173, JString, required = false,
                                 default = nil)
  if valid_604173 != nil:
    section.add "X-Amz-Signature", valid_604173
  var valid_604174 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604174 = validateParameter(valid_604174, JString, required = false,
                                 default = nil)
  if valid_604174 != nil:
    section.add "X-Amz-SignedHeaders", valid_604174
  var valid_604175 = header.getOrDefault("X-Amz-Credential")
  valid_604175 = validateParameter(valid_604175, JString, required = false,
                                 default = nil)
  if valid_604175 != nil:
    section.add "X-Amz-Credential", valid_604175
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604177: Call_GetParameters_604165; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Get details of a parameter. Don't confuse this API action with the <a>GetParameter</a> API action.
  ## 
  let valid = call_604177.validator(path, query, header, formData, body)
  let scheme = call_604177.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604177.url(scheme.get, call_604177.host, call_604177.base,
                         call_604177.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604177, url, valid)

proc call*(call_604178: Call_GetParameters_604165; body: JsonNode): Recallable =
  ## getParameters
  ## Get details of a parameter. Don't confuse this API action with the <a>GetParameter</a> API action.
  ##   body: JObject (required)
  var body_604179 = newJObject()
  if body != nil:
    body_604179 = body
  result = call_604178.call(nil, nil, nil, nil, body_604179)

var getParameters* = Call_GetParameters_604165(name: "getParameters",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetParameters",
    validator: validate_GetParameters_604166, base: "/", url: url_GetParameters_604167,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetParametersByPath_604180 = ref object of OpenApiRestCall_602466
proc url_GetParametersByPath_604182(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetParametersByPath_604181(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p>Retrieve parameters in a specific hierarchy. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/sysman-paramstore-working.html">Working with Systems Manager Parameters</a> in the <i>AWS Systems Manager User Guide</i>. </p> <p>Request results are returned on a best-effort basis. If you specify <code>MaxResults</code> in the request, the response includes information up to the limit specified. The number of items returned, however, can be between zero and the value of <code>MaxResults</code>. If the service reaches an internal limit while processing the results, it stops the operation and returns the matching values up to that point and a <code>NextToken</code>. You can specify the <code>NextToken</code> in a subsequent call to get the next set of results.</p> <note> <p>This API action doesn't support filtering by tags. </p> </note>
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
  var valid_604183 = query.getOrDefault("NextToken")
  valid_604183 = validateParameter(valid_604183, JString, required = false,
                                 default = nil)
  if valid_604183 != nil:
    section.add "NextToken", valid_604183
  var valid_604184 = query.getOrDefault("MaxResults")
  valid_604184 = validateParameter(valid_604184, JString, required = false,
                                 default = nil)
  if valid_604184 != nil:
    section.add "MaxResults", valid_604184
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
  var valid_604185 = header.getOrDefault("X-Amz-Date")
  valid_604185 = validateParameter(valid_604185, JString, required = false,
                                 default = nil)
  if valid_604185 != nil:
    section.add "X-Amz-Date", valid_604185
  var valid_604186 = header.getOrDefault("X-Amz-Security-Token")
  valid_604186 = validateParameter(valid_604186, JString, required = false,
                                 default = nil)
  if valid_604186 != nil:
    section.add "X-Amz-Security-Token", valid_604186
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604187 = header.getOrDefault("X-Amz-Target")
  valid_604187 = validateParameter(valid_604187, JString, required = true, default = newJString(
      "AmazonSSM.GetParametersByPath"))
  if valid_604187 != nil:
    section.add "X-Amz-Target", valid_604187
  var valid_604188 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604188 = validateParameter(valid_604188, JString, required = false,
                                 default = nil)
  if valid_604188 != nil:
    section.add "X-Amz-Content-Sha256", valid_604188
  var valid_604189 = header.getOrDefault("X-Amz-Algorithm")
  valid_604189 = validateParameter(valid_604189, JString, required = false,
                                 default = nil)
  if valid_604189 != nil:
    section.add "X-Amz-Algorithm", valid_604189
  var valid_604190 = header.getOrDefault("X-Amz-Signature")
  valid_604190 = validateParameter(valid_604190, JString, required = false,
                                 default = nil)
  if valid_604190 != nil:
    section.add "X-Amz-Signature", valid_604190
  var valid_604191 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604191 = validateParameter(valid_604191, JString, required = false,
                                 default = nil)
  if valid_604191 != nil:
    section.add "X-Amz-SignedHeaders", valid_604191
  var valid_604192 = header.getOrDefault("X-Amz-Credential")
  valid_604192 = validateParameter(valid_604192, JString, required = false,
                                 default = nil)
  if valid_604192 != nil:
    section.add "X-Amz-Credential", valid_604192
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604194: Call_GetParametersByPath_604180; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieve parameters in a specific hierarchy. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/sysman-paramstore-working.html">Working with Systems Manager Parameters</a> in the <i>AWS Systems Manager User Guide</i>. </p> <p>Request results are returned on a best-effort basis. If you specify <code>MaxResults</code> in the request, the response includes information up to the limit specified. The number of items returned, however, can be between zero and the value of <code>MaxResults</code>. If the service reaches an internal limit while processing the results, it stops the operation and returns the matching values up to that point and a <code>NextToken</code>. You can specify the <code>NextToken</code> in a subsequent call to get the next set of results.</p> <note> <p>This API action doesn't support filtering by tags. </p> </note>
  ## 
  let valid = call_604194.validator(path, query, header, formData, body)
  let scheme = call_604194.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604194.url(scheme.get, call_604194.host, call_604194.base,
                         call_604194.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604194, url, valid)

proc call*(call_604195: Call_GetParametersByPath_604180; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## getParametersByPath
  ## <p>Retrieve parameters in a specific hierarchy. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/sysman-paramstore-working.html">Working with Systems Manager Parameters</a> in the <i>AWS Systems Manager User Guide</i>. </p> <p>Request results are returned on a best-effort basis. If you specify <code>MaxResults</code> in the request, the response includes information up to the limit specified. The number of items returned, however, can be between zero and the value of <code>MaxResults</code>. If the service reaches an internal limit while processing the results, it stops the operation and returns the matching values up to that point and a <code>NextToken</code>. You can specify the <code>NextToken</code> in a subsequent call to get the next set of results.</p> <note> <p>This API action doesn't support filtering by tags. </p> </note>
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_604196 = newJObject()
  var body_604197 = newJObject()
  add(query_604196, "NextToken", newJString(NextToken))
  if body != nil:
    body_604197 = body
  add(query_604196, "MaxResults", newJString(MaxResults))
  result = call_604195.call(nil, query_604196, nil, nil, body_604197)

var getParametersByPath* = Call_GetParametersByPath_604180(
    name: "getParametersByPath", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetParametersByPath",
    validator: validate_GetParametersByPath_604181, base: "/",
    url: url_GetParametersByPath_604182, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPatchBaseline_604198 = ref object of OpenApiRestCall_602466
proc url_GetPatchBaseline_604200(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetPatchBaseline_604199(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Retrieves information about a patch baseline.
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
  var valid_604201 = header.getOrDefault("X-Amz-Date")
  valid_604201 = validateParameter(valid_604201, JString, required = false,
                                 default = nil)
  if valid_604201 != nil:
    section.add "X-Amz-Date", valid_604201
  var valid_604202 = header.getOrDefault("X-Amz-Security-Token")
  valid_604202 = validateParameter(valid_604202, JString, required = false,
                                 default = nil)
  if valid_604202 != nil:
    section.add "X-Amz-Security-Token", valid_604202
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604203 = header.getOrDefault("X-Amz-Target")
  valid_604203 = validateParameter(valid_604203, JString, required = true, default = newJString(
      "AmazonSSM.GetPatchBaseline"))
  if valid_604203 != nil:
    section.add "X-Amz-Target", valid_604203
  var valid_604204 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604204 = validateParameter(valid_604204, JString, required = false,
                                 default = nil)
  if valid_604204 != nil:
    section.add "X-Amz-Content-Sha256", valid_604204
  var valid_604205 = header.getOrDefault("X-Amz-Algorithm")
  valid_604205 = validateParameter(valid_604205, JString, required = false,
                                 default = nil)
  if valid_604205 != nil:
    section.add "X-Amz-Algorithm", valid_604205
  var valid_604206 = header.getOrDefault("X-Amz-Signature")
  valid_604206 = validateParameter(valid_604206, JString, required = false,
                                 default = nil)
  if valid_604206 != nil:
    section.add "X-Amz-Signature", valid_604206
  var valid_604207 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604207 = validateParameter(valid_604207, JString, required = false,
                                 default = nil)
  if valid_604207 != nil:
    section.add "X-Amz-SignedHeaders", valid_604207
  var valid_604208 = header.getOrDefault("X-Amz-Credential")
  valid_604208 = validateParameter(valid_604208, JString, required = false,
                                 default = nil)
  if valid_604208 != nil:
    section.add "X-Amz-Credential", valid_604208
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604210: Call_GetPatchBaseline_604198; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a patch baseline.
  ## 
  let valid = call_604210.validator(path, query, header, formData, body)
  let scheme = call_604210.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604210.url(scheme.get, call_604210.host, call_604210.base,
                         call_604210.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604210, url, valid)

proc call*(call_604211: Call_GetPatchBaseline_604198; body: JsonNode): Recallable =
  ## getPatchBaseline
  ## Retrieves information about a patch baseline.
  ##   body: JObject (required)
  var body_604212 = newJObject()
  if body != nil:
    body_604212 = body
  result = call_604211.call(nil, nil, nil, nil, body_604212)

var getPatchBaseline* = Call_GetPatchBaseline_604198(name: "getPatchBaseline",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetPatchBaseline",
    validator: validate_GetPatchBaseline_604199, base: "/",
    url: url_GetPatchBaseline_604200, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPatchBaselineForPatchGroup_604213 = ref object of OpenApiRestCall_602466
proc url_GetPatchBaselineForPatchGroup_604215(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetPatchBaselineForPatchGroup_604214(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves the patch baseline that should be used for the specified patch group.
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
  var valid_604216 = header.getOrDefault("X-Amz-Date")
  valid_604216 = validateParameter(valid_604216, JString, required = false,
                                 default = nil)
  if valid_604216 != nil:
    section.add "X-Amz-Date", valid_604216
  var valid_604217 = header.getOrDefault("X-Amz-Security-Token")
  valid_604217 = validateParameter(valid_604217, JString, required = false,
                                 default = nil)
  if valid_604217 != nil:
    section.add "X-Amz-Security-Token", valid_604217
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604218 = header.getOrDefault("X-Amz-Target")
  valid_604218 = validateParameter(valid_604218, JString, required = true, default = newJString(
      "AmazonSSM.GetPatchBaselineForPatchGroup"))
  if valid_604218 != nil:
    section.add "X-Amz-Target", valid_604218
  var valid_604219 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604219 = validateParameter(valid_604219, JString, required = false,
                                 default = nil)
  if valid_604219 != nil:
    section.add "X-Amz-Content-Sha256", valid_604219
  var valid_604220 = header.getOrDefault("X-Amz-Algorithm")
  valid_604220 = validateParameter(valid_604220, JString, required = false,
                                 default = nil)
  if valid_604220 != nil:
    section.add "X-Amz-Algorithm", valid_604220
  var valid_604221 = header.getOrDefault("X-Amz-Signature")
  valid_604221 = validateParameter(valid_604221, JString, required = false,
                                 default = nil)
  if valid_604221 != nil:
    section.add "X-Amz-Signature", valid_604221
  var valid_604222 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604222 = validateParameter(valid_604222, JString, required = false,
                                 default = nil)
  if valid_604222 != nil:
    section.add "X-Amz-SignedHeaders", valid_604222
  var valid_604223 = header.getOrDefault("X-Amz-Credential")
  valid_604223 = validateParameter(valid_604223, JString, required = false,
                                 default = nil)
  if valid_604223 != nil:
    section.add "X-Amz-Credential", valid_604223
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604225: Call_GetPatchBaselineForPatchGroup_604213; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the patch baseline that should be used for the specified patch group.
  ## 
  let valid = call_604225.validator(path, query, header, formData, body)
  let scheme = call_604225.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604225.url(scheme.get, call_604225.host, call_604225.base,
                         call_604225.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604225, url, valid)

proc call*(call_604226: Call_GetPatchBaselineForPatchGroup_604213; body: JsonNode): Recallable =
  ## getPatchBaselineForPatchGroup
  ## Retrieves the patch baseline that should be used for the specified patch group.
  ##   body: JObject (required)
  var body_604227 = newJObject()
  if body != nil:
    body_604227 = body
  result = call_604226.call(nil, nil, nil, nil, body_604227)

var getPatchBaselineForPatchGroup* = Call_GetPatchBaselineForPatchGroup_604213(
    name: "getPatchBaselineForPatchGroup", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetPatchBaselineForPatchGroup",
    validator: validate_GetPatchBaselineForPatchGroup_604214, base: "/",
    url: url_GetPatchBaselineForPatchGroup_604215,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetServiceSetting_604228 = ref object of OpenApiRestCall_602466
proc url_GetServiceSetting_604230(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetServiceSetting_604229(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p> <code>ServiceSetting</code> is an account-level setting for an AWS service. This setting defines how a user interacts with or uses a service or a feature of a service. For example, if an AWS service charges money to the account based on feature or service usage, then the AWS service team might create a default setting of "false". This means the user can't use this feature unless they change the setting to "true" and intentionally opt in for a paid feature.</p> <p>Services map a <code>SettingId</code> object to a setting value. AWS services teams define the default value for a <code>SettingId</code>. You can't create a new <code>SettingId</code>, but you can overwrite the default value if you have the <code>ssm:UpdateServiceSetting</code> permission for the setting. Use the <a>UpdateServiceSetting</a> API action to change the default setting. Or use the <a>ResetServiceSetting</a> to change the value back to the original value defined by the AWS service team.</p> <p>Query the current service setting for the account. </p>
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
  var valid_604231 = header.getOrDefault("X-Amz-Date")
  valid_604231 = validateParameter(valid_604231, JString, required = false,
                                 default = nil)
  if valid_604231 != nil:
    section.add "X-Amz-Date", valid_604231
  var valid_604232 = header.getOrDefault("X-Amz-Security-Token")
  valid_604232 = validateParameter(valid_604232, JString, required = false,
                                 default = nil)
  if valid_604232 != nil:
    section.add "X-Amz-Security-Token", valid_604232
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604233 = header.getOrDefault("X-Amz-Target")
  valid_604233 = validateParameter(valid_604233, JString, required = true, default = newJString(
      "AmazonSSM.GetServiceSetting"))
  if valid_604233 != nil:
    section.add "X-Amz-Target", valid_604233
  var valid_604234 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604234 = validateParameter(valid_604234, JString, required = false,
                                 default = nil)
  if valid_604234 != nil:
    section.add "X-Amz-Content-Sha256", valid_604234
  var valid_604235 = header.getOrDefault("X-Amz-Algorithm")
  valid_604235 = validateParameter(valid_604235, JString, required = false,
                                 default = nil)
  if valid_604235 != nil:
    section.add "X-Amz-Algorithm", valid_604235
  var valid_604236 = header.getOrDefault("X-Amz-Signature")
  valid_604236 = validateParameter(valid_604236, JString, required = false,
                                 default = nil)
  if valid_604236 != nil:
    section.add "X-Amz-Signature", valid_604236
  var valid_604237 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604237 = validateParameter(valid_604237, JString, required = false,
                                 default = nil)
  if valid_604237 != nil:
    section.add "X-Amz-SignedHeaders", valid_604237
  var valid_604238 = header.getOrDefault("X-Amz-Credential")
  valid_604238 = validateParameter(valid_604238, JString, required = false,
                                 default = nil)
  if valid_604238 != nil:
    section.add "X-Amz-Credential", valid_604238
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604240: Call_GetServiceSetting_604228; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> <code>ServiceSetting</code> is an account-level setting for an AWS service. This setting defines how a user interacts with or uses a service or a feature of a service. For example, if an AWS service charges money to the account based on feature or service usage, then the AWS service team might create a default setting of "false". This means the user can't use this feature unless they change the setting to "true" and intentionally opt in for a paid feature.</p> <p>Services map a <code>SettingId</code> object to a setting value. AWS services teams define the default value for a <code>SettingId</code>. You can't create a new <code>SettingId</code>, but you can overwrite the default value if you have the <code>ssm:UpdateServiceSetting</code> permission for the setting. Use the <a>UpdateServiceSetting</a> API action to change the default setting. Or use the <a>ResetServiceSetting</a> to change the value back to the original value defined by the AWS service team.</p> <p>Query the current service setting for the account. </p>
  ## 
  let valid = call_604240.validator(path, query, header, formData, body)
  let scheme = call_604240.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604240.url(scheme.get, call_604240.host, call_604240.base,
                         call_604240.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604240, url, valid)

proc call*(call_604241: Call_GetServiceSetting_604228; body: JsonNode): Recallable =
  ## getServiceSetting
  ## <p> <code>ServiceSetting</code> is an account-level setting for an AWS service. This setting defines how a user interacts with or uses a service or a feature of a service. For example, if an AWS service charges money to the account based on feature or service usage, then the AWS service team might create a default setting of "false". This means the user can't use this feature unless they change the setting to "true" and intentionally opt in for a paid feature.</p> <p>Services map a <code>SettingId</code> object to a setting value. AWS services teams define the default value for a <code>SettingId</code>. You can't create a new <code>SettingId</code>, but you can overwrite the default value if you have the <code>ssm:UpdateServiceSetting</code> permission for the setting. Use the <a>UpdateServiceSetting</a> API action to change the default setting. Or use the <a>ResetServiceSetting</a> to change the value back to the original value defined by the AWS service team.</p> <p>Query the current service setting for the account. </p>
  ##   body: JObject (required)
  var body_604242 = newJObject()
  if body != nil:
    body_604242 = body
  result = call_604241.call(nil, nil, nil, nil, body_604242)

var getServiceSetting* = Call_GetServiceSetting_604228(name: "getServiceSetting",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetServiceSetting",
    validator: validate_GetServiceSetting_604229, base: "/",
    url: url_GetServiceSetting_604230, schemes: {Scheme.Https, Scheme.Http})
type
  Call_LabelParameterVersion_604243 = ref object of OpenApiRestCall_602466
proc url_LabelParameterVersion_604245(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_LabelParameterVersion_604244(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>A parameter label is a user-defined alias to help you manage different versions of a parameter. When you modify a parameter, Systems Manager automatically saves a new version and increments the version number by one. A label can help you remember the purpose of a parameter when there are multiple versions. </p> <p>Parameter labels have the following requirements and restrictions.</p> <ul> <li> <p>A version of a parameter can have a maximum of 10 labels.</p> </li> <li> <p>You can't attach the same label to different versions of the same parameter. For example, if version 1 has the label Production, then you can't attach Production to version 2.</p> </li> <li> <p>You can move a label from one version of a parameter to another.</p> </li> <li> <p>You can't create a label when you create a new parameter. You must attach a label to a specific version of a parameter.</p> </li> <li> <p>You can't delete a parameter label. If you no longer want to use a parameter label, then you must move it to a different version of a parameter.</p> </li> <li> <p>A label can have a maximum of 100 characters.</p> </li> <li> <p>Labels can contain letters (case sensitive), numbers, periods (.), hyphens (-), or underscores (_).</p> </li> <li> <p>Labels can't begin with a number, "aws," or "ssm" (not case sensitive). If a label fails to meet these requirements, then the label is not associated with a parameter and the system displays it in the list of InvalidLabels.</p> </li> </ul>
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
  var valid_604246 = header.getOrDefault("X-Amz-Date")
  valid_604246 = validateParameter(valid_604246, JString, required = false,
                                 default = nil)
  if valid_604246 != nil:
    section.add "X-Amz-Date", valid_604246
  var valid_604247 = header.getOrDefault("X-Amz-Security-Token")
  valid_604247 = validateParameter(valid_604247, JString, required = false,
                                 default = nil)
  if valid_604247 != nil:
    section.add "X-Amz-Security-Token", valid_604247
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604248 = header.getOrDefault("X-Amz-Target")
  valid_604248 = validateParameter(valid_604248, JString, required = true, default = newJString(
      "AmazonSSM.LabelParameterVersion"))
  if valid_604248 != nil:
    section.add "X-Amz-Target", valid_604248
  var valid_604249 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604249 = validateParameter(valid_604249, JString, required = false,
                                 default = nil)
  if valid_604249 != nil:
    section.add "X-Amz-Content-Sha256", valid_604249
  var valid_604250 = header.getOrDefault("X-Amz-Algorithm")
  valid_604250 = validateParameter(valid_604250, JString, required = false,
                                 default = nil)
  if valid_604250 != nil:
    section.add "X-Amz-Algorithm", valid_604250
  var valid_604251 = header.getOrDefault("X-Amz-Signature")
  valid_604251 = validateParameter(valid_604251, JString, required = false,
                                 default = nil)
  if valid_604251 != nil:
    section.add "X-Amz-Signature", valid_604251
  var valid_604252 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604252 = validateParameter(valid_604252, JString, required = false,
                                 default = nil)
  if valid_604252 != nil:
    section.add "X-Amz-SignedHeaders", valid_604252
  var valid_604253 = header.getOrDefault("X-Amz-Credential")
  valid_604253 = validateParameter(valid_604253, JString, required = false,
                                 default = nil)
  if valid_604253 != nil:
    section.add "X-Amz-Credential", valid_604253
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604255: Call_LabelParameterVersion_604243; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>A parameter label is a user-defined alias to help you manage different versions of a parameter. When you modify a parameter, Systems Manager automatically saves a new version and increments the version number by one. A label can help you remember the purpose of a parameter when there are multiple versions. </p> <p>Parameter labels have the following requirements and restrictions.</p> <ul> <li> <p>A version of a parameter can have a maximum of 10 labels.</p> </li> <li> <p>You can't attach the same label to different versions of the same parameter. For example, if version 1 has the label Production, then you can't attach Production to version 2.</p> </li> <li> <p>You can move a label from one version of a parameter to another.</p> </li> <li> <p>You can't create a label when you create a new parameter. You must attach a label to a specific version of a parameter.</p> </li> <li> <p>You can't delete a parameter label. If you no longer want to use a parameter label, then you must move it to a different version of a parameter.</p> </li> <li> <p>A label can have a maximum of 100 characters.</p> </li> <li> <p>Labels can contain letters (case sensitive), numbers, periods (.), hyphens (-), or underscores (_).</p> </li> <li> <p>Labels can't begin with a number, "aws," or "ssm" (not case sensitive). If a label fails to meet these requirements, then the label is not associated with a parameter and the system displays it in the list of InvalidLabels.</p> </li> </ul>
  ## 
  let valid = call_604255.validator(path, query, header, formData, body)
  let scheme = call_604255.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604255.url(scheme.get, call_604255.host, call_604255.base,
                         call_604255.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604255, url, valid)

proc call*(call_604256: Call_LabelParameterVersion_604243; body: JsonNode): Recallable =
  ## labelParameterVersion
  ## <p>A parameter label is a user-defined alias to help you manage different versions of a parameter. When you modify a parameter, Systems Manager automatically saves a new version and increments the version number by one. A label can help you remember the purpose of a parameter when there are multiple versions. </p> <p>Parameter labels have the following requirements and restrictions.</p> <ul> <li> <p>A version of a parameter can have a maximum of 10 labels.</p> </li> <li> <p>You can't attach the same label to different versions of the same parameter. For example, if version 1 has the label Production, then you can't attach Production to version 2.</p> </li> <li> <p>You can move a label from one version of a parameter to another.</p> </li> <li> <p>You can't create a label when you create a new parameter. You must attach a label to a specific version of a parameter.</p> </li> <li> <p>You can't delete a parameter label. If you no longer want to use a parameter label, then you must move it to a different version of a parameter.</p> </li> <li> <p>A label can have a maximum of 100 characters.</p> </li> <li> <p>Labels can contain letters (case sensitive), numbers, periods (.), hyphens (-), or underscores (_).</p> </li> <li> <p>Labels can't begin with a number, "aws," or "ssm" (not case sensitive). If a label fails to meet these requirements, then the label is not associated with a parameter and the system displays it in the list of InvalidLabels.</p> </li> </ul>
  ##   body: JObject (required)
  var body_604257 = newJObject()
  if body != nil:
    body_604257 = body
  result = call_604256.call(nil, nil, nil, nil, body_604257)

var labelParameterVersion* = Call_LabelParameterVersion_604243(
    name: "labelParameterVersion", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.LabelParameterVersion",
    validator: validate_LabelParameterVersion_604244, base: "/",
    url: url_LabelParameterVersion_604245, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAssociationVersions_604258 = ref object of OpenApiRestCall_602466
proc url_ListAssociationVersions_604260(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListAssociationVersions_604259(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves all versions of an association for a specific association ID.
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
  var valid_604261 = header.getOrDefault("X-Amz-Date")
  valid_604261 = validateParameter(valid_604261, JString, required = false,
                                 default = nil)
  if valid_604261 != nil:
    section.add "X-Amz-Date", valid_604261
  var valid_604262 = header.getOrDefault("X-Amz-Security-Token")
  valid_604262 = validateParameter(valid_604262, JString, required = false,
                                 default = nil)
  if valid_604262 != nil:
    section.add "X-Amz-Security-Token", valid_604262
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604263 = header.getOrDefault("X-Amz-Target")
  valid_604263 = validateParameter(valid_604263, JString, required = true, default = newJString(
      "AmazonSSM.ListAssociationVersions"))
  if valid_604263 != nil:
    section.add "X-Amz-Target", valid_604263
  var valid_604264 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604264 = validateParameter(valid_604264, JString, required = false,
                                 default = nil)
  if valid_604264 != nil:
    section.add "X-Amz-Content-Sha256", valid_604264
  var valid_604265 = header.getOrDefault("X-Amz-Algorithm")
  valid_604265 = validateParameter(valid_604265, JString, required = false,
                                 default = nil)
  if valid_604265 != nil:
    section.add "X-Amz-Algorithm", valid_604265
  var valid_604266 = header.getOrDefault("X-Amz-Signature")
  valid_604266 = validateParameter(valid_604266, JString, required = false,
                                 default = nil)
  if valid_604266 != nil:
    section.add "X-Amz-Signature", valid_604266
  var valid_604267 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604267 = validateParameter(valid_604267, JString, required = false,
                                 default = nil)
  if valid_604267 != nil:
    section.add "X-Amz-SignedHeaders", valid_604267
  var valid_604268 = header.getOrDefault("X-Amz-Credential")
  valid_604268 = validateParameter(valid_604268, JString, required = false,
                                 default = nil)
  if valid_604268 != nil:
    section.add "X-Amz-Credential", valid_604268
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604270: Call_ListAssociationVersions_604258; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves all versions of an association for a specific association ID.
  ## 
  let valid = call_604270.validator(path, query, header, formData, body)
  let scheme = call_604270.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604270.url(scheme.get, call_604270.host, call_604270.base,
                         call_604270.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604270, url, valid)

proc call*(call_604271: Call_ListAssociationVersions_604258; body: JsonNode): Recallable =
  ## listAssociationVersions
  ## Retrieves all versions of an association for a specific association ID.
  ##   body: JObject (required)
  var body_604272 = newJObject()
  if body != nil:
    body_604272 = body
  result = call_604271.call(nil, nil, nil, nil, body_604272)

var listAssociationVersions* = Call_ListAssociationVersions_604258(
    name: "listAssociationVersions", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.ListAssociationVersions",
    validator: validate_ListAssociationVersions_604259, base: "/",
    url: url_ListAssociationVersions_604260, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAssociations_604273 = ref object of OpenApiRestCall_602466
proc url_ListAssociations_604275(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListAssociations_604274(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Lists the associations for the specified Systems Manager document or instance.
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
  var valid_604276 = query.getOrDefault("NextToken")
  valid_604276 = validateParameter(valid_604276, JString, required = false,
                                 default = nil)
  if valid_604276 != nil:
    section.add "NextToken", valid_604276
  var valid_604277 = query.getOrDefault("MaxResults")
  valid_604277 = validateParameter(valid_604277, JString, required = false,
                                 default = nil)
  if valid_604277 != nil:
    section.add "MaxResults", valid_604277
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
  var valid_604278 = header.getOrDefault("X-Amz-Date")
  valid_604278 = validateParameter(valid_604278, JString, required = false,
                                 default = nil)
  if valid_604278 != nil:
    section.add "X-Amz-Date", valid_604278
  var valid_604279 = header.getOrDefault("X-Amz-Security-Token")
  valid_604279 = validateParameter(valid_604279, JString, required = false,
                                 default = nil)
  if valid_604279 != nil:
    section.add "X-Amz-Security-Token", valid_604279
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604280 = header.getOrDefault("X-Amz-Target")
  valid_604280 = validateParameter(valid_604280, JString, required = true, default = newJString(
      "AmazonSSM.ListAssociations"))
  if valid_604280 != nil:
    section.add "X-Amz-Target", valid_604280
  var valid_604281 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604281 = validateParameter(valid_604281, JString, required = false,
                                 default = nil)
  if valid_604281 != nil:
    section.add "X-Amz-Content-Sha256", valid_604281
  var valid_604282 = header.getOrDefault("X-Amz-Algorithm")
  valid_604282 = validateParameter(valid_604282, JString, required = false,
                                 default = nil)
  if valid_604282 != nil:
    section.add "X-Amz-Algorithm", valid_604282
  var valid_604283 = header.getOrDefault("X-Amz-Signature")
  valid_604283 = validateParameter(valid_604283, JString, required = false,
                                 default = nil)
  if valid_604283 != nil:
    section.add "X-Amz-Signature", valid_604283
  var valid_604284 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604284 = validateParameter(valid_604284, JString, required = false,
                                 default = nil)
  if valid_604284 != nil:
    section.add "X-Amz-SignedHeaders", valid_604284
  var valid_604285 = header.getOrDefault("X-Amz-Credential")
  valid_604285 = validateParameter(valid_604285, JString, required = false,
                                 default = nil)
  if valid_604285 != nil:
    section.add "X-Amz-Credential", valid_604285
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604287: Call_ListAssociations_604273; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the associations for the specified Systems Manager document or instance.
  ## 
  let valid = call_604287.validator(path, query, header, formData, body)
  let scheme = call_604287.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604287.url(scheme.get, call_604287.host, call_604287.base,
                         call_604287.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604287, url, valid)

proc call*(call_604288: Call_ListAssociations_604273; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listAssociations
  ## Lists the associations for the specified Systems Manager document or instance.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_604289 = newJObject()
  var body_604290 = newJObject()
  add(query_604289, "NextToken", newJString(NextToken))
  if body != nil:
    body_604290 = body
  add(query_604289, "MaxResults", newJString(MaxResults))
  result = call_604288.call(nil, query_604289, nil, nil, body_604290)

var listAssociations* = Call_ListAssociations_604273(name: "listAssociations",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.ListAssociations",
    validator: validate_ListAssociations_604274, base: "/",
    url: url_ListAssociations_604275, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListCommandInvocations_604291 = ref object of OpenApiRestCall_602466
proc url_ListCommandInvocations_604293(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListCommandInvocations_604292(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## An invocation is copy of a command sent to a specific instance. A command can apply to one or more instances. A command invocation applies to one instance. For example, if a user runs SendCommand against three instances, then a command invocation is created for each requested instance ID. ListCommandInvocations provide status about command execution.
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
  var valid_604294 = query.getOrDefault("NextToken")
  valid_604294 = validateParameter(valid_604294, JString, required = false,
                                 default = nil)
  if valid_604294 != nil:
    section.add "NextToken", valid_604294
  var valid_604295 = query.getOrDefault("MaxResults")
  valid_604295 = validateParameter(valid_604295, JString, required = false,
                                 default = nil)
  if valid_604295 != nil:
    section.add "MaxResults", valid_604295
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
  var valid_604296 = header.getOrDefault("X-Amz-Date")
  valid_604296 = validateParameter(valid_604296, JString, required = false,
                                 default = nil)
  if valid_604296 != nil:
    section.add "X-Amz-Date", valid_604296
  var valid_604297 = header.getOrDefault("X-Amz-Security-Token")
  valid_604297 = validateParameter(valid_604297, JString, required = false,
                                 default = nil)
  if valid_604297 != nil:
    section.add "X-Amz-Security-Token", valid_604297
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604298 = header.getOrDefault("X-Amz-Target")
  valid_604298 = validateParameter(valid_604298, JString, required = true, default = newJString(
      "AmazonSSM.ListCommandInvocations"))
  if valid_604298 != nil:
    section.add "X-Amz-Target", valid_604298
  var valid_604299 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604299 = validateParameter(valid_604299, JString, required = false,
                                 default = nil)
  if valid_604299 != nil:
    section.add "X-Amz-Content-Sha256", valid_604299
  var valid_604300 = header.getOrDefault("X-Amz-Algorithm")
  valid_604300 = validateParameter(valid_604300, JString, required = false,
                                 default = nil)
  if valid_604300 != nil:
    section.add "X-Amz-Algorithm", valid_604300
  var valid_604301 = header.getOrDefault("X-Amz-Signature")
  valid_604301 = validateParameter(valid_604301, JString, required = false,
                                 default = nil)
  if valid_604301 != nil:
    section.add "X-Amz-Signature", valid_604301
  var valid_604302 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604302 = validateParameter(valid_604302, JString, required = false,
                                 default = nil)
  if valid_604302 != nil:
    section.add "X-Amz-SignedHeaders", valid_604302
  var valid_604303 = header.getOrDefault("X-Amz-Credential")
  valid_604303 = validateParameter(valid_604303, JString, required = false,
                                 default = nil)
  if valid_604303 != nil:
    section.add "X-Amz-Credential", valid_604303
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604305: Call_ListCommandInvocations_604291; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## An invocation is copy of a command sent to a specific instance. A command can apply to one or more instances. A command invocation applies to one instance. For example, if a user runs SendCommand against three instances, then a command invocation is created for each requested instance ID. ListCommandInvocations provide status about command execution.
  ## 
  let valid = call_604305.validator(path, query, header, formData, body)
  let scheme = call_604305.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604305.url(scheme.get, call_604305.host, call_604305.base,
                         call_604305.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604305, url, valid)

proc call*(call_604306: Call_ListCommandInvocations_604291; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listCommandInvocations
  ## An invocation is copy of a command sent to a specific instance. A command can apply to one or more instances. A command invocation applies to one instance. For example, if a user runs SendCommand against three instances, then a command invocation is created for each requested instance ID. ListCommandInvocations provide status about command execution.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_604307 = newJObject()
  var body_604308 = newJObject()
  add(query_604307, "NextToken", newJString(NextToken))
  if body != nil:
    body_604308 = body
  add(query_604307, "MaxResults", newJString(MaxResults))
  result = call_604306.call(nil, query_604307, nil, nil, body_604308)

var listCommandInvocations* = Call_ListCommandInvocations_604291(
    name: "listCommandInvocations", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.ListCommandInvocations",
    validator: validate_ListCommandInvocations_604292, base: "/",
    url: url_ListCommandInvocations_604293, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListCommands_604309 = ref object of OpenApiRestCall_602466
proc url_ListCommands_604311(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListCommands_604310(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists the commands requested by users of the AWS account.
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
  var valid_604312 = query.getOrDefault("NextToken")
  valid_604312 = validateParameter(valid_604312, JString, required = false,
                                 default = nil)
  if valid_604312 != nil:
    section.add "NextToken", valid_604312
  var valid_604313 = query.getOrDefault("MaxResults")
  valid_604313 = validateParameter(valid_604313, JString, required = false,
                                 default = nil)
  if valid_604313 != nil:
    section.add "MaxResults", valid_604313
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
  var valid_604314 = header.getOrDefault("X-Amz-Date")
  valid_604314 = validateParameter(valid_604314, JString, required = false,
                                 default = nil)
  if valid_604314 != nil:
    section.add "X-Amz-Date", valid_604314
  var valid_604315 = header.getOrDefault("X-Amz-Security-Token")
  valid_604315 = validateParameter(valid_604315, JString, required = false,
                                 default = nil)
  if valid_604315 != nil:
    section.add "X-Amz-Security-Token", valid_604315
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604316 = header.getOrDefault("X-Amz-Target")
  valid_604316 = validateParameter(valid_604316, JString, required = true,
                                 default = newJString("AmazonSSM.ListCommands"))
  if valid_604316 != nil:
    section.add "X-Amz-Target", valid_604316
  var valid_604317 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604317 = validateParameter(valid_604317, JString, required = false,
                                 default = nil)
  if valid_604317 != nil:
    section.add "X-Amz-Content-Sha256", valid_604317
  var valid_604318 = header.getOrDefault("X-Amz-Algorithm")
  valid_604318 = validateParameter(valid_604318, JString, required = false,
                                 default = nil)
  if valid_604318 != nil:
    section.add "X-Amz-Algorithm", valid_604318
  var valid_604319 = header.getOrDefault("X-Amz-Signature")
  valid_604319 = validateParameter(valid_604319, JString, required = false,
                                 default = nil)
  if valid_604319 != nil:
    section.add "X-Amz-Signature", valid_604319
  var valid_604320 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604320 = validateParameter(valid_604320, JString, required = false,
                                 default = nil)
  if valid_604320 != nil:
    section.add "X-Amz-SignedHeaders", valid_604320
  var valid_604321 = header.getOrDefault("X-Amz-Credential")
  valid_604321 = validateParameter(valid_604321, JString, required = false,
                                 default = nil)
  if valid_604321 != nil:
    section.add "X-Amz-Credential", valid_604321
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604323: Call_ListCommands_604309; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the commands requested by users of the AWS account.
  ## 
  let valid = call_604323.validator(path, query, header, formData, body)
  let scheme = call_604323.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604323.url(scheme.get, call_604323.host, call_604323.base,
                         call_604323.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604323, url, valid)

proc call*(call_604324: Call_ListCommands_604309; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listCommands
  ## Lists the commands requested by users of the AWS account.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_604325 = newJObject()
  var body_604326 = newJObject()
  add(query_604325, "NextToken", newJString(NextToken))
  if body != nil:
    body_604326 = body
  add(query_604325, "MaxResults", newJString(MaxResults))
  result = call_604324.call(nil, query_604325, nil, nil, body_604326)

var listCommands* = Call_ListCommands_604309(name: "listCommands",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.ListCommands",
    validator: validate_ListCommands_604310, base: "/", url: url_ListCommands_604311,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListComplianceItems_604327 = ref object of OpenApiRestCall_602466
proc url_ListComplianceItems_604329(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListComplianceItems_604328(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## For a specified resource ID, this API action returns a list of compliance statuses for different resource types. Currently, you can only specify one resource ID per call. List results depend on the criteria specified in the filter. 
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
  var valid_604330 = header.getOrDefault("X-Amz-Date")
  valid_604330 = validateParameter(valid_604330, JString, required = false,
                                 default = nil)
  if valid_604330 != nil:
    section.add "X-Amz-Date", valid_604330
  var valid_604331 = header.getOrDefault("X-Amz-Security-Token")
  valid_604331 = validateParameter(valid_604331, JString, required = false,
                                 default = nil)
  if valid_604331 != nil:
    section.add "X-Amz-Security-Token", valid_604331
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604332 = header.getOrDefault("X-Amz-Target")
  valid_604332 = validateParameter(valid_604332, JString, required = true, default = newJString(
      "AmazonSSM.ListComplianceItems"))
  if valid_604332 != nil:
    section.add "X-Amz-Target", valid_604332
  var valid_604333 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604333 = validateParameter(valid_604333, JString, required = false,
                                 default = nil)
  if valid_604333 != nil:
    section.add "X-Amz-Content-Sha256", valid_604333
  var valid_604334 = header.getOrDefault("X-Amz-Algorithm")
  valid_604334 = validateParameter(valid_604334, JString, required = false,
                                 default = nil)
  if valid_604334 != nil:
    section.add "X-Amz-Algorithm", valid_604334
  var valid_604335 = header.getOrDefault("X-Amz-Signature")
  valid_604335 = validateParameter(valid_604335, JString, required = false,
                                 default = nil)
  if valid_604335 != nil:
    section.add "X-Amz-Signature", valid_604335
  var valid_604336 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604336 = validateParameter(valid_604336, JString, required = false,
                                 default = nil)
  if valid_604336 != nil:
    section.add "X-Amz-SignedHeaders", valid_604336
  var valid_604337 = header.getOrDefault("X-Amz-Credential")
  valid_604337 = validateParameter(valid_604337, JString, required = false,
                                 default = nil)
  if valid_604337 != nil:
    section.add "X-Amz-Credential", valid_604337
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604339: Call_ListComplianceItems_604327; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## For a specified resource ID, this API action returns a list of compliance statuses for different resource types. Currently, you can only specify one resource ID per call. List results depend on the criteria specified in the filter. 
  ## 
  let valid = call_604339.validator(path, query, header, formData, body)
  let scheme = call_604339.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604339.url(scheme.get, call_604339.host, call_604339.base,
                         call_604339.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604339, url, valid)

proc call*(call_604340: Call_ListComplianceItems_604327; body: JsonNode): Recallable =
  ## listComplianceItems
  ## For a specified resource ID, this API action returns a list of compliance statuses for different resource types. Currently, you can only specify one resource ID per call. List results depend on the criteria specified in the filter. 
  ##   body: JObject (required)
  var body_604341 = newJObject()
  if body != nil:
    body_604341 = body
  result = call_604340.call(nil, nil, nil, nil, body_604341)

var listComplianceItems* = Call_ListComplianceItems_604327(
    name: "listComplianceItems", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.ListComplianceItems",
    validator: validate_ListComplianceItems_604328, base: "/",
    url: url_ListComplianceItems_604329, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListComplianceSummaries_604342 = ref object of OpenApiRestCall_602466
proc url_ListComplianceSummaries_604344(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListComplianceSummaries_604343(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a summary count of compliant and non-compliant resources for a compliance type. For example, this call can return State Manager associations, patches, or custom compliance types according to the filter criteria that you specify. 
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
  var valid_604345 = header.getOrDefault("X-Amz-Date")
  valid_604345 = validateParameter(valid_604345, JString, required = false,
                                 default = nil)
  if valid_604345 != nil:
    section.add "X-Amz-Date", valid_604345
  var valid_604346 = header.getOrDefault("X-Amz-Security-Token")
  valid_604346 = validateParameter(valid_604346, JString, required = false,
                                 default = nil)
  if valid_604346 != nil:
    section.add "X-Amz-Security-Token", valid_604346
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604347 = header.getOrDefault("X-Amz-Target")
  valid_604347 = validateParameter(valid_604347, JString, required = true, default = newJString(
      "AmazonSSM.ListComplianceSummaries"))
  if valid_604347 != nil:
    section.add "X-Amz-Target", valid_604347
  var valid_604348 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604348 = validateParameter(valid_604348, JString, required = false,
                                 default = nil)
  if valid_604348 != nil:
    section.add "X-Amz-Content-Sha256", valid_604348
  var valid_604349 = header.getOrDefault("X-Amz-Algorithm")
  valid_604349 = validateParameter(valid_604349, JString, required = false,
                                 default = nil)
  if valid_604349 != nil:
    section.add "X-Amz-Algorithm", valid_604349
  var valid_604350 = header.getOrDefault("X-Amz-Signature")
  valid_604350 = validateParameter(valid_604350, JString, required = false,
                                 default = nil)
  if valid_604350 != nil:
    section.add "X-Amz-Signature", valid_604350
  var valid_604351 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604351 = validateParameter(valid_604351, JString, required = false,
                                 default = nil)
  if valid_604351 != nil:
    section.add "X-Amz-SignedHeaders", valid_604351
  var valid_604352 = header.getOrDefault("X-Amz-Credential")
  valid_604352 = validateParameter(valid_604352, JString, required = false,
                                 default = nil)
  if valid_604352 != nil:
    section.add "X-Amz-Credential", valid_604352
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604354: Call_ListComplianceSummaries_604342; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a summary count of compliant and non-compliant resources for a compliance type. For example, this call can return State Manager associations, patches, or custom compliance types according to the filter criteria that you specify. 
  ## 
  let valid = call_604354.validator(path, query, header, formData, body)
  let scheme = call_604354.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604354.url(scheme.get, call_604354.host, call_604354.base,
                         call_604354.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604354, url, valid)

proc call*(call_604355: Call_ListComplianceSummaries_604342; body: JsonNode): Recallable =
  ## listComplianceSummaries
  ## Returns a summary count of compliant and non-compliant resources for a compliance type. For example, this call can return State Manager associations, patches, or custom compliance types according to the filter criteria that you specify. 
  ##   body: JObject (required)
  var body_604356 = newJObject()
  if body != nil:
    body_604356 = body
  result = call_604355.call(nil, nil, nil, nil, body_604356)

var listComplianceSummaries* = Call_ListComplianceSummaries_604342(
    name: "listComplianceSummaries", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.ListComplianceSummaries",
    validator: validate_ListComplianceSummaries_604343, base: "/",
    url: url_ListComplianceSummaries_604344, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDocumentVersions_604357 = ref object of OpenApiRestCall_602466
proc url_ListDocumentVersions_604359(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListDocumentVersions_604358(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## List all versions for a document.
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
  var valid_604360 = header.getOrDefault("X-Amz-Date")
  valid_604360 = validateParameter(valid_604360, JString, required = false,
                                 default = nil)
  if valid_604360 != nil:
    section.add "X-Amz-Date", valid_604360
  var valid_604361 = header.getOrDefault("X-Amz-Security-Token")
  valid_604361 = validateParameter(valid_604361, JString, required = false,
                                 default = nil)
  if valid_604361 != nil:
    section.add "X-Amz-Security-Token", valid_604361
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604362 = header.getOrDefault("X-Amz-Target")
  valid_604362 = validateParameter(valid_604362, JString, required = true, default = newJString(
      "AmazonSSM.ListDocumentVersions"))
  if valid_604362 != nil:
    section.add "X-Amz-Target", valid_604362
  var valid_604363 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604363 = validateParameter(valid_604363, JString, required = false,
                                 default = nil)
  if valid_604363 != nil:
    section.add "X-Amz-Content-Sha256", valid_604363
  var valid_604364 = header.getOrDefault("X-Amz-Algorithm")
  valid_604364 = validateParameter(valid_604364, JString, required = false,
                                 default = nil)
  if valid_604364 != nil:
    section.add "X-Amz-Algorithm", valid_604364
  var valid_604365 = header.getOrDefault("X-Amz-Signature")
  valid_604365 = validateParameter(valid_604365, JString, required = false,
                                 default = nil)
  if valid_604365 != nil:
    section.add "X-Amz-Signature", valid_604365
  var valid_604366 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604366 = validateParameter(valid_604366, JString, required = false,
                                 default = nil)
  if valid_604366 != nil:
    section.add "X-Amz-SignedHeaders", valid_604366
  var valid_604367 = header.getOrDefault("X-Amz-Credential")
  valid_604367 = validateParameter(valid_604367, JString, required = false,
                                 default = nil)
  if valid_604367 != nil:
    section.add "X-Amz-Credential", valid_604367
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604369: Call_ListDocumentVersions_604357; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List all versions for a document.
  ## 
  let valid = call_604369.validator(path, query, header, formData, body)
  let scheme = call_604369.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604369.url(scheme.get, call_604369.host, call_604369.base,
                         call_604369.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604369, url, valid)

proc call*(call_604370: Call_ListDocumentVersions_604357; body: JsonNode): Recallable =
  ## listDocumentVersions
  ## List all versions for a document.
  ##   body: JObject (required)
  var body_604371 = newJObject()
  if body != nil:
    body_604371 = body
  result = call_604370.call(nil, nil, nil, nil, body_604371)

var listDocumentVersions* = Call_ListDocumentVersions_604357(
    name: "listDocumentVersions", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.ListDocumentVersions",
    validator: validate_ListDocumentVersions_604358, base: "/",
    url: url_ListDocumentVersions_604359, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDocuments_604372 = ref object of OpenApiRestCall_602466
proc url_ListDocuments_604374(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListDocuments_604373(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Describes one or more of your Systems Manager documents.
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
  var valid_604375 = query.getOrDefault("NextToken")
  valid_604375 = validateParameter(valid_604375, JString, required = false,
                                 default = nil)
  if valid_604375 != nil:
    section.add "NextToken", valid_604375
  var valid_604376 = query.getOrDefault("MaxResults")
  valid_604376 = validateParameter(valid_604376, JString, required = false,
                                 default = nil)
  if valid_604376 != nil:
    section.add "MaxResults", valid_604376
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
  var valid_604377 = header.getOrDefault("X-Amz-Date")
  valid_604377 = validateParameter(valid_604377, JString, required = false,
                                 default = nil)
  if valid_604377 != nil:
    section.add "X-Amz-Date", valid_604377
  var valid_604378 = header.getOrDefault("X-Amz-Security-Token")
  valid_604378 = validateParameter(valid_604378, JString, required = false,
                                 default = nil)
  if valid_604378 != nil:
    section.add "X-Amz-Security-Token", valid_604378
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604379 = header.getOrDefault("X-Amz-Target")
  valid_604379 = validateParameter(valid_604379, JString, required = true, default = newJString(
      "AmazonSSM.ListDocuments"))
  if valid_604379 != nil:
    section.add "X-Amz-Target", valid_604379
  var valid_604380 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604380 = validateParameter(valid_604380, JString, required = false,
                                 default = nil)
  if valid_604380 != nil:
    section.add "X-Amz-Content-Sha256", valid_604380
  var valid_604381 = header.getOrDefault("X-Amz-Algorithm")
  valid_604381 = validateParameter(valid_604381, JString, required = false,
                                 default = nil)
  if valid_604381 != nil:
    section.add "X-Amz-Algorithm", valid_604381
  var valid_604382 = header.getOrDefault("X-Amz-Signature")
  valid_604382 = validateParameter(valid_604382, JString, required = false,
                                 default = nil)
  if valid_604382 != nil:
    section.add "X-Amz-Signature", valid_604382
  var valid_604383 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604383 = validateParameter(valid_604383, JString, required = false,
                                 default = nil)
  if valid_604383 != nil:
    section.add "X-Amz-SignedHeaders", valid_604383
  var valid_604384 = header.getOrDefault("X-Amz-Credential")
  valid_604384 = validateParameter(valid_604384, JString, required = false,
                                 default = nil)
  if valid_604384 != nil:
    section.add "X-Amz-Credential", valid_604384
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604386: Call_ListDocuments_604372; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes one or more of your Systems Manager documents.
  ## 
  let valid = call_604386.validator(path, query, header, formData, body)
  let scheme = call_604386.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604386.url(scheme.get, call_604386.host, call_604386.base,
                         call_604386.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604386, url, valid)

proc call*(call_604387: Call_ListDocuments_604372; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listDocuments
  ## Describes one or more of your Systems Manager documents.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_604388 = newJObject()
  var body_604389 = newJObject()
  add(query_604388, "NextToken", newJString(NextToken))
  if body != nil:
    body_604389 = body
  add(query_604388, "MaxResults", newJString(MaxResults))
  result = call_604387.call(nil, query_604388, nil, nil, body_604389)

var listDocuments* = Call_ListDocuments_604372(name: "listDocuments",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.ListDocuments",
    validator: validate_ListDocuments_604373, base: "/", url: url_ListDocuments_604374,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListInventoryEntries_604390 = ref object of OpenApiRestCall_602466
proc url_ListInventoryEntries_604392(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListInventoryEntries_604391(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## A list of inventory items returned by the request.
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
  var valid_604393 = header.getOrDefault("X-Amz-Date")
  valid_604393 = validateParameter(valid_604393, JString, required = false,
                                 default = nil)
  if valid_604393 != nil:
    section.add "X-Amz-Date", valid_604393
  var valid_604394 = header.getOrDefault("X-Amz-Security-Token")
  valid_604394 = validateParameter(valid_604394, JString, required = false,
                                 default = nil)
  if valid_604394 != nil:
    section.add "X-Amz-Security-Token", valid_604394
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604395 = header.getOrDefault("X-Amz-Target")
  valid_604395 = validateParameter(valid_604395, JString, required = true, default = newJString(
      "AmazonSSM.ListInventoryEntries"))
  if valid_604395 != nil:
    section.add "X-Amz-Target", valid_604395
  var valid_604396 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604396 = validateParameter(valid_604396, JString, required = false,
                                 default = nil)
  if valid_604396 != nil:
    section.add "X-Amz-Content-Sha256", valid_604396
  var valid_604397 = header.getOrDefault("X-Amz-Algorithm")
  valid_604397 = validateParameter(valid_604397, JString, required = false,
                                 default = nil)
  if valid_604397 != nil:
    section.add "X-Amz-Algorithm", valid_604397
  var valid_604398 = header.getOrDefault("X-Amz-Signature")
  valid_604398 = validateParameter(valid_604398, JString, required = false,
                                 default = nil)
  if valid_604398 != nil:
    section.add "X-Amz-Signature", valid_604398
  var valid_604399 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604399 = validateParameter(valid_604399, JString, required = false,
                                 default = nil)
  if valid_604399 != nil:
    section.add "X-Amz-SignedHeaders", valid_604399
  var valid_604400 = header.getOrDefault("X-Amz-Credential")
  valid_604400 = validateParameter(valid_604400, JString, required = false,
                                 default = nil)
  if valid_604400 != nil:
    section.add "X-Amz-Credential", valid_604400
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604402: Call_ListInventoryEntries_604390; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## A list of inventory items returned by the request.
  ## 
  let valid = call_604402.validator(path, query, header, formData, body)
  let scheme = call_604402.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604402.url(scheme.get, call_604402.host, call_604402.base,
                         call_604402.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604402, url, valid)

proc call*(call_604403: Call_ListInventoryEntries_604390; body: JsonNode): Recallable =
  ## listInventoryEntries
  ## A list of inventory items returned by the request.
  ##   body: JObject (required)
  var body_604404 = newJObject()
  if body != nil:
    body_604404 = body
  result = call_604403.call(nil, nil, nil, nil, body_604404)

var listInventoryEntries* = Call_ListInventoryEntries_604390(
    name: "listInventoryEntries", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.ListInventoryEntries",
    validator: validate_ListInventoryEntries_604391, base: "/",
    url: url_ListInventoryEntries_604392, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListResourceComplianceSummaries_604405 = ref object of OpenApiRestCall_602466
proc url_ListResourceComplianceSummaries_604407(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListResourceComplianceSummaries_604406(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a resource-level summary count. The summary includes information about compliant and non-compliant statuses and detailed compliance-item severity counts, according to the filter criteria you specify.
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
  var valid_604408 = header.getOrDefault("X-Amz-Date")
  valid_604408 = validateParameter(valid_604408, JString, required = false,
                                 default = nil)
  if valid_604408 != nil:
    section.add "X-Amz-Date", valid_604408
  var valid_604409 = header.getOrDefault("X-Amz-Security-Token")
  valid_604409 = validateParameter(valid_604409, JString, required = false,
                                 default = nil)
  if valid_604409 != nil:
    section.add "X-Amz-Security-Token", valid_604409
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604410 = header.getOrDefault("X-Amz-Target")
  valid_604410 = validateParameter(valid_604410, JString, required = true, default = newJString(
      "AmazonSSM.ListResourceComplianceSummaries"))
  if valid_604410 != nil:
    section.add "X-Amz-Target", valid_604410
  var valid_604411 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604411 = validateParameter(valid_604411, JString, required = false,
                                 default = nil)
  if valid_604411 != nil:
    section.add "X-Amz-Content-Sha256", valid_604411
  var valid_604412 = header.getOrDefault("X-Amz-Algorithm")
  valid_604412 = validateParameter(valid_604412, JString, required = false,
                                 default = nil)
  if valid_604412 != nil:
    section.add "X-Amz-Algorithm", valid_604412
  var valid_604413 = header.getOrDefault("X-Amz-Signature")
  valid_604413 = validateParameter(valid_604413, JString, required = false,
                                 default = nil)
  if valid_604413 != nil:
    section.add "X-Amz-Signature", valid_604413
  var valid_604414 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604414 = validateParameter(valid_604414, JString, required = false,
                                 default = nil)
  if valid_604414 != nil:
    section.add "X-Amz-SignedHeaders", valid_604414
  var valid_604415 = header.getOrDefault("X-Amz-Credential")
  valid_604415 = validateParameter(valid_604415, JString, required = false,
                                 default = nil)
  if valid_604415 != nil:
    section.add "X-Amz-Credential", valid_604415
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604417: Call_ListResourceComplianceSummaries_604405;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns a resource-level summary count. The summary includes information about compliant and non-compliant statuses and detailed compliance-item severity counts, according to the filter criteria you specify.
  ## 
  let valid = call_604417.validator(path, query, header, formData, body)
  let scheme = call_604417.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604417.url(scheme.get, call_604417.host, call_604417.base,
                         call_604417.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604417, url, valid)

proc call*(call_604418: Call_ListResourceComplianceSummaries_604405; body: JsonNode): Recallable =
  ## listResourceComplianceSummaries
  ## Returns a resource-level summary count. The summary includes information about compliant and non-compliant statuses and detailed compliance-item severity counts, according to the filter criteria you specify.
  ##   body: JObject (required)
  var body_604419 = newJObject()
  if body != nil:
    body_604419 = body
  result = call_604418.call(nil, nil, nil, nil, body_604419)

var listResourceComplianceSummaries* = Call_ListResourceComplianceSummaries_604405(
    name: "listResourceComplianceSummaries", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.ListResourceComplianceSummaries",
    validator: validate_ListResourceComplianceSummaries_604406, base: "/",
    url: url_ListResourceComplianceSummaries_604407,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListResourceDataSync_604420 = ref object of OpenApiRestCall_602466
proc url_ListResourceDataSync_604422(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListResourceDataSync_604421(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Lists your resource data sync configurations. Includes information about the last time a sync attempted to start, the last sync status, and the last time a sync successfully completed.</p> <p>The number of sync configurations might be too large to return using a single call to <code>ListResourceDataSync</code>. You can limit the number of sync configurations returned by using the <code>MaxResults</code> parameter. To determine whether there are more sync configurations to list, check the value of <code>NextToken</code> in the output. If there are more sync configurations to list, you can request them by specifying the <code>NextToken</code> returned in the call to the parameter of a subsequent call. </p>
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
  var valid_604423 = header.getOrDefault("X-Amz-Date")
  valid_604423 = validateParameter(valid_604423, JString, required = false,
                                 default = nil)
  if valid_604423 != nil:
    section.add "X-Amz-Date", valid_604423
  var valid_604424 = header.getOrDefault("X-Amz-Security-Token")
  valid_604424 = validateParameter(valid_604424, JString, required = false,
                                 default = nil)
  if valid_604424 != nil:
    section.add "X-Amz-Security-Token", valid_604424
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604425 = header.getOrDefault("X-Amz-Target")
  valid_604425 = validateParameter(valid_604425, JString, required = true, default = newJString(
      "AmazonSSM.ListResourceDataSync"))
  if valid_604425 != nil:
    section.add "X-Amz-Target", valid_604425
  var valid_604426 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604426 = validateParameter(valid_604426, JString, required = false,
                                 default = nil)
  if valid_604426 != nil:
    section.add "X-Amz-Content-Sha256", valid_604426
  var valid_604427 = header.getOrDefault("X-Amz-Algorithm")
  valid_604427 = validateParameter(valid_604427, JString, required = false,
                                 default = nil)
  if valid_604427 != nil:
    section.add "X-Amz-Algorithm", valid_604427
  var valid_604428 = header.getOrDefault("X-Amz-Signature")
  valid_604428 = validateParameter(valid_604428, JString, required = false,
                                 default = nil)
  if valid_604428 != nil:
    section.add "X-Amz-Signature", valid_604428
  var valid_604429 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604429 = validateParameter(valid_604429, JString, required = false,
                                 default = nil)
  if valid_604429 != nil:
    section.add "X-Amz-SignedHeaders", valid_604429
  var valid_604430 = header.getOrDefault("X-Amz-Credential")
  valid_604430 = validateParameter(valid_604430, JString, required = false,
                                 default = nil)
  if valid_604430 != nil:
    section.add "X-Amz-Credential", valid_604430
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604432: Call_ListResourceDataSync_604420; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists your resource data sync configurations. Includes information about the last time a sync attempted to start, the last sync status, and the last time a sync successfully completed.</p> <p>The number of sync configurations might be too large to return using a single call to <code>ListResourceDataSync</code>. You can limit the number of sync configurations returned by using the <code>MaxResults</code> parameter. To determine whether there are more sync configurations to list, check the value of <code>NextToken</code> in the output. If there are more sync configurations to list, you can request them by specifying the <code>NextToken</code> returned in the call to the parameter of a subsequent call. </p>
  ## 
  let valid = call_604432.validator(path, query, header, formData, body)
  let scheme = call_604432.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604432.url(scheme.get, call_604432.host, call_604432.base,
                         call_604432.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604432, url, valid)

proc call*(call_604433: Call_ListResourceDataSync_604420; body: JsonNode): Recallable =
  ## listResourceDataSync
  ## <p>Lists your resource data sync configurations. Includes information about the last time a sync attempted to start, the last sync status, and the last time a sync successfully completed.</p> <p>The number of sync configurations might be too large to return using a single call to <code>ListResourceDataSync</code>. You can limit the number of sync configurations returned by using the <code>MaxResults</code> parameter. To determine whether there are more sync configurations to list, check the value of <code>NextToken</code> in the output. If there are more sync configurations to list, you can request them by specifying the <code>NextToken</code> returned in the call to the parameter of a subsequent call. </p>
  ##   body: JObject (required)
  var body_604434 = newJObject()
  if body != nil:
    body_604434 = body
  result = call_604433.call(nil, nil, nil, nil, body_604434)

var listResourceDataSync* = Call_ListResourceDataSync_604420(
    name: "listResourceDataSync", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.ListResourceDataSync",
    validator: validate_ListResourceDataSync_604421, base: "/",
    url: url_ListResourceDataSync_604422, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_604435 = ref object of OpenApiRestCall_602466
proc url_ListTagsForResource_604437(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListTagsForResource_604436(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Returns a list of the tags assigned to the specified resource.
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
  var valid_604438 = header.getOrDefault("X-Amz-Date")
  valid_604438 = validateParameter(valid_604438, JString, required = false,
                                 default = nil)
  if valid_604438 != nil:
    section.add "X-Amz-Date", valid_604438
  var valid_604439 = header.getOrDefault("X-Amz-Security-Token")
  valid_604439 = validateParameter(valid_604439, JString, required = false,
                                 default = nil)
  if valid_604439 != nil:
    section.add "X-Amz-Security-Token", valid_604439
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604440 = header.getOrDefault("X-Amz-Target")
  valid_604440 = validateParameter(valid_604440, JString, required = true, default = newJString(
      "AmazonSSM.ListTagsForResource"))
  if valid_604440 != nil:
    section.add "X-Amz-Target", valid_604440
  var valid_604441 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604441 = validateParameter(valid_604441, JString, required = false,
                                 default = nil)
  if valid_604441 != nil:
    section.add "X-Amz-Content-Sha256", valid_604441
  var valid_604442 = header.getOrDefault("X-Amz-Algorithm")
  valid_604442 = validateParameter(valid_604442, JString, required = false,
                                 default = nil)
  if valid_604442 != nil:
    section.add "X-Amz-Algorithm", valid_604442
  var valid_604443 = header.getOrDefault("X-Amz-Signature")
  valid_604443 = validateParameter(valid_604443, JString, required = false,
                                 default = nil)
  if valid_604443 != nil:
    section.add "X-Amz-Signature", valid_604443
  var valid_604444 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604444 = validateParameter(valid_604444, JString, required = false,
                                 default = nil)
  if valid_604444 != nil:
    section.add "X-Amz-SignedHeaders", valid_604444
  var valid_604445 = header.getOrDefault("X-Amz-Credential")
  valid_604445 = validateParameter(valid_604445, JString, required = false,
                                 default = nil)
  if valid_604445 != nil:
    section.add "X-Amz-Credential", valid_604445
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604447: Call_ListTagsForResource_604435; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of the tags assigned to the specified resource.
  ## 
  let valid = call_604447.validator(path, query, header, formData, body)
  let scheme = call_604447.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604447.url(scheme.get, call_604447.host, call_604447.base,
                         call_604447.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604447, url, valid)

proc call*(call_604448: Call_ListTagsForResource_604435; body: JsonNode): Recallable =
  ## listTagsForResource
  ## Returns a list of the tags assigned to the specified resource.
  ##   body: JObject (required)
  var body_604449 = newJObject()
  if body != nil:
    body_604449 = body
  result = call_604448.call(nil, nil, nil, nil, body_604449)

var listTagsForResource* = Call_ListTagsForResource_604435(
    name: "listTagsForResource", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.ListTagsForResource",
    validator: validate_ListTagsForResource_604436, base: "/",
    url: url_ListTagsForResource_604437, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ModifyDocumentPermission_604450 = ref object of OpenApiRestCall_602466
proc url_ModifyDocumentPermission_604452(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ModifyDocumentPermission_604451(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Shares a Systems Manager document publicly or privately. If you share a document privately, you must specify the AWS user account IDs for those people who can use the document. If you share a document publicly, you must specify <i>All</i> as the account ID.
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
  var valid_604453 = header.getOrDefault("X-Amz-Date")
  valid_604453 = validateParameter(valid_604453, JString, required = false,
                                 default = nil)
  if valid_604453 != nil:
    section.add "X-Amz-Date", valid_604453
  var valid_604454 = header.getOrDefault("X-Amz-Security-Token")
  valid_604454 = validateParameter(valid_604454, JString, required = false,
                                 default = nil)
  if valid_604454 != nil:
    section.add "X-Amz-Security-Token", valid_604454
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604455 = header.getOrDefault("X-Amz-Target")
  valid_604455 = validateParameter(valid_604455, JString, required = true, default = newJString(
      "AmazonSSM.ModifyDocumentPermission"))
  if valid_604455 != nil:
    section.add "X-Amz-Target", valid_604455
  var valid_604456 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604456 = validateParameter(valid_604456, JString, required = false,
                                 default = nil)
  if valid_604456 != nil:
    section.add "X-Amz-Content-Sha256", valid_604456
  var valid_604457 = header.getOrDefault("X-Amz-Algorithm")
  valid_604457 = validateParameter(valid_604457, JString, required = false,
                                 default = nil)
  if valid_604457 != nil:
    section.add "X-Amz-Algorithm", valid_604457
  var valid_604458 = header.getOrDefault("X-Amz-Signature")
  valid_604458 = validateParameter(valid_604458, JString, required = false,
                                 default = nil)
  if valid_604458 != nil:
    section.add "X-Amz-Signature", valid_604458
  var valid_604459 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604459 = validateParameter(valid_604459, JString, required = false,
                                 default = nil)
  if valid_604459 != nil:
    section.add "X-Amz-SignedHeaders", valid_604459
  var valid_604460 = header.getOrDefault("X-Amz-Credential")
  valid_604460 = validateParameter(valid_604460, JString, required = false,
                                 default = nil)
  if valid_604460 != nil:
    section.add "X-Amz-Credential", valid_604460
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604462: Call_ModifyDocumentPermission_604450; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Shares a Systems Manager document publicly or privately. If you share a document privately, you must specify the AWS user account IDs for those people who can use the document. If you share a document publicly, you must specify <i>All</i> as the account ID.
  ## 
  let valid = call_604462.validator(path, query, header, formData, body)
  let scheme = call_604462.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604462.url(scheme.get, call_604462.host, call_604462.base,
                         call_604462.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604462, url, valid)

proc call*(call_604463: Call_ModifyDocumentPermission_604450; body: JsonNode): Recallable =
  ## modifyDocumentPermission
  ## Shares a Systems Manager document publicly or privately. If you share a document privately, you must specify the AWS user account IDs for those people who can use the document. If you share a document publicly, you must specify <i>All</i> as the account ID.
  ##   body: JObject (required)
  var body_604464 = newJObject()
  if body != nil:
    body_604464 = body
  result = call_604463.call(nil, nil, nil, nil, body_604464)

var modifyDocumentPermission* = Call_ModifyDocumentPermission_604450(
    name: "modifyDocumentPermission", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.ModifyDocumentPermission",
    validator: validate_ModifyDocumentPermission_604451, base: "/",
    url: url_ModifyDocumentPermission_604452, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutComplianceItems_604465 = ref object of OpenApiRestCall_602466
proc url_PutComplianceItems_604467(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PutComplianceItems_604466(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## <p>Registers a compliance type and other compliance details on a designated resource. This action lets you register custom compliance details with a resource. This call overwrites existing compliance information on the resource, so you must provide a full list of compliance items each time that you send the request.</p> <p>ComplianceType can be one of the following:</p> <ul> <li> <p>ExecutionId: The execution ID when the patch, association, or custom compliance item was applied.</p> </li> <li> <p>ExecutionType: Specify patch, association, or Custom:<code>string</code>.</p> </li> <li> <p>ExecutionTime. The time the patch, association, or custom compliance item was applied to the instance.</p> </li> <li> <p>Id: The patch, association, or custom compliance ID.</p> </li> <li> <p>Title: A title.</p> </li> <li> <p>Status: The status of the compliance item. For example, <code>approved</code> for patches, or <code>Failed</code> for associations.</p> </li> <li> <p>Severity: A patch severity. For example, <code>critical</code>.</p> </li> <li> <p>DocumentName: A SSM document name. For example, AWS-RunPatchBaseline.</p> </li> <li> <p>DocumentVersion: An SSM document version number. For example, 4.</p> </li> <li> <p>Classification: A patch classification. For example, <code>security updates</code>.</p> </li> <li> <p>PatchBaselineId: A patch baseline ID.</p> </li> <li> <p>PatchSeverity: A patch severity. For example, <code>Critical</code>.</p> </li> <li> <p>PatchState: A patch state. For example, <code>InstancesWithFailedPatches</code>.</p> </li> <li> <p>PatchGroup: The name of a patch group.</p> </li> <li> <p>InstalledTime: The time the association, patch, or custom compliance item was applied to the resource. Specify the time by using the following format: yyyy-MM-dd'T'HH:mm:ss'Z'</p> </li> </ul>
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
  var valid_604468 = header.getOrDefault("X-Amz-Date")
  valid_604468 = validateParameter(valid_604468, JString, required = false,
                                 default = nil)
  if valid_604468 != nil:
    section.add "X-Amz-Date", valid_604468
  var valid_604469 = header.getOrDefault("X-Amz-Security-Token")
  valid_604469 = validateParameter(valid_604469, JString, required = false,
                                 default = nil)
  if valid_604469 != nil:
    section.add "X-Amz-Security-Token", valid_604469
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604470 = header.getOrDefault("X-Amz-Target")
  valid_604470 = validateParameter(valid_604470, JString, required = true, default = newJString(
      "AmazonSSM.PutComplianceItems"))
  if valid_604470 != nil:
    section.add "X-Amz-Target", valid_604470
  var valid_604471 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604471 = validateParameter(valid_604471, JString, required = false,
                                 default = nil)
  if valid_604471 != nil:
    section.add "X-Amz-Content-Sha256", valid_604471
  var valid_604472 = header.getOrDefault("X-Amz-Algorithm")
  valid_604472 = validateParameter(valid_604472, JString, required = false,
                                 default = nil)
  if valid_604472 != nil:
    section.add "X-Amz-Algorithm", valid_604472
  var valid_604473 = header.getOrDefault("X-Amz-Signature")
  valid_604473 = validateParameter(valid_604473, JString, required = false,
                                 default = nil)
  if valid_604473 != nil:
    section.add "X-Amz-Signature", valid_604473
  var valid_604474 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604474 = validateParameter(valid_604474, JString, required = false,
                                 default = nil)
  if valid_604474 != nil:
    section.add "X-Amz-SignedHeaders", valid_604474
  var valid_604475 = header.getOrDefault("X-Amz-Credential")
  valid_604475 = validateParameter(valid_604475, JString, required = false,
                                 default = nil)
  if valid_604475 != nil:
    section.add "X-Amz-Credential", valid_604475
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604477: Call_PutComplianceItems_604465; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Registers a compliance type and other compliance details on a designated resource. This action lets you register custom compliance details with a resource. This call overwrites existing compliance information on the resource, so you must provide a full list of compliance items each time that you send the request.</p> <p>ComplianceType can be one of the following:</p> <ul> <li> <p>ExecutionId: The execution ID when the patch, association, or custom compliance item was applied.</p> </li> <li> <p>ExecutionType: Specify patch, association, or Custom:<code>string</code>.</p> </li> <li> <p>ExecutionTime. The time the patch, association, or custom compliance item was applied to the instance.</p> </li> <li> <p>Id: The patch, association, or custom compliance ID.</p> </li> <li> <p>Title: A title.</p> </li> <li> <p>Status: The status of the compliance item. For example, <code>approved</code> for patches, or <code>Failed</code> for associations.</p> </li> <li> <p>Severity: A patch severity. For example, <code>critical</code>.</p> </li> <li> <p>DocumentName: A SSM document name. For example, AWS-RunPatchBaseline.</p> </li> <li> <p>DocumentVersion: An SSM document version number. For example, 4.</p> </li> <li> <p>Classification: A patch classification. For example, <code>security updates</code>.</p> </li> <li> <p>PatchBaselineId: A patch baseline ID.</p> </li> <li> <p>PatchSeverity: A patch severity. For example, <code>Critical</code>.</p> </li> <li> <p>PatchState: A patch state. For example, <code>InstancesWithFailedPatches</code>.</p> </li> <li> <p>PatchGroup: The name of a patch group.</p> </li> <li> <p>InstalledTime: The time the association, patch, or custom compliance item was applied to the resource. Specify the time by using the following format: yyyy-MM-dd'T'HH:mm:ss'Z'</p> </li> </ul>
  ## 
  let valid = call_604477.validator(path, query, header, formData, body)
  let scheme = call_604477.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604477.url(scheme.get, call_604477.host, call_604477.base,
                         call_604477.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604477, url, valid)

proc call*(call_604478: Call_PutComplianceItems_604465; body: JsonNode): Recallable =
  ## putComplianceItems
  ## <p>Registers a compliance type and other compliance details on a designated resource. This action lets you register custom compliance details with a resource. This call overwrites existing compliance information on the resource, so you must provide a full list of compliance items each time that you send the request.</p> <p>ComplianceType can be one of the following:</p> <ul> <li> <p>ExecutionId: The execution ID when the patch, association, or custom compliance item was applied.</p> </li> <li> <p>ExecutionType: Specify patch, association, or Custom:<code>string</code>.</p> </li> <li> <p>ExecutionTime. The time the patch, association, or custom compliance item was applied to the instance.</p> </li> <li> <p>Id: The patch, association, or custom compliance ID.</p> </li> <li> <p>Title: A title.</p> </li> <li> <p>Status: The status of the compliance item. For example, <code>approved</code> for patches, or <code>Failed</code> for associations.</p> </li> <li> <p>Severity: A patch severity. For example, <code>critical</code>.</p> </li> <li> <p>DocumentName: A SSM document name. For example, AWS-RunPatchBaseline.</p> </li> <li> <p>DocumentVersion: An SSM document version number. For example, 4.</p> </li> <li> <p>Classification: A patch classification. For example, <code>security updates</code>.</p> </li> <li> <p>PatchBaselineId: A patch baseline ID.</p> </li> <li> <p>PatchSeverity: A patch severity. For example, <code>Critical</code>.</p> </li> <li> <p>PatchState: A patch state. For example, <code>InstancesWithFailedPatches</code>.</p> </li> <li> <p>PatchGroup: The name of a patch group.</p> </li> <li> <p>InstalledTime: The time the association, patch, or custom compliance item was applied to the resource. Specify the time by using the following format: yyyy-MM-dd'T'HH:mm:ss'Z'</p> </li> </ul>
  ##   body: JObject (required)
  var body_604479 = newJObject()
  if body != nil:
    body_604479 = body
  result = call_604478.call(nil, nil, nil, nil, body_604479)

var putComplianceItems* = Call_PutComplianceItems_604465(
    name: "putComplianceItems", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.PutComplianceItems",
    validator: validate_PutComplianceItems_604466, base: "/",
    url: url_PutComplianceItems_604467, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutInventory_604480 = ref object of OpenApiRestCall_602466
proc url_PutInventory_604482(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PutInventory_604481(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Bulk update custom inventory items on one more instance. The request adds an inventory item, if it doesn't already exist, or updates an inventory item, if it does exist.
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
  var valid_604483 = header.getOrDefault("X-Amz-Date")
  valid_604483 = validateParameter(valid_604483, JString, required = false,
                                 default = nil)
  if valid_604483 != nil:
    section.add "X-Amz-Date", valid_604483
  var valid_604484 = header.getOrDefault("X-Amz-Security-Token")
  valid_604484 = validateParameter(valid_604484, JString, required = false,
                                 default = nil)
  if valid_604484 != nil:
    section.add "X-Amz-Security-Token", valid_604484
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604485 = header.getOrDefault("X-Amz-Target")
  valid_604485 = validateParameter(valid_604485, JString, required = true,
                                 default = newJString("AmazonSSM.PutInventory"))
  if valid_604485 != nil:
    section.add "X-Amz-Target", valid_604485
  var valid_604486 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604486 = validateParameter(valid_604486, JString, required = false,
                                 default = nil)
  if valid_604486 != nil:
    section.add "X-Amz-Content-Sha256", valid_604486
  var valid_604487 = header.getOrDefault("X-Amz-Algorithm")
  valid_604487 = validateParameter(valid_604487, JString, required = false,
                                 default = nil)
  if valid_604487 != nil:
    section.add "X-Amz-Algorithm", valid_604487
  var valid_604488 = header.getOrDefault("X-Amz-Signature")
  valid_604488 = validateParameter(valid_604488, JString, required = false,
                                 default = nil)
  if valid_604488 != nil:
    section.add "X-Amz-Signature", valid_604488
  var valid_604489 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604489 = validateParameter(valid_604489, JString, required = false,
                                 default = nil)
  if valid_604489 != nil:
    section.add "X-Amz-SignedHeaders", valid_604489
  var valid_604490 = header.getOrDefault("X-Amz-Credential")
  valid_604490 = validateParameter(valid_604490, JString, required = false,
                                 default = nil)
  if valid_604490 != nil:
    section.add "X-Amz-Credential", valid_604490
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604492: Call_PutInventory_604480; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Bulk update custom inventory items on one more instance. The request adds an inventory item, if it doesn't already exist, or updates an inventory item, if it does exist.
  ## 
  let valid = call_604492.validator(path, query, header, formData, body)
  let scheme = call_604492.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604492.url(scheme.get, call_604492.host, call_604492.base,
                         call_604492.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604492, url, valid)

proc call*(call_604493: Call_PutInventory_604480; body: JsonNode): Recallable =
  ## putInventory
  ## Bulk update custom inventory items on one more instance. The request adds an inventory item, if it doesn't already exist, or updates an inventory item, if it does exist.
  ##   body: JObject (required)
  var body_604494 = newJObject()
  if body != nil:
    body_604494 = body
  result = call_604493.call(nil, nil, nil, nil, body_604494)

var putInventory* = Call_PutInventory_604480(name: "putInventory",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.PutInventory",
    validator: validate_PutInventory_604481, base: "/", url: url_PutInventory_604482,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutParameter_604495 = ref object of OpenApiRestCall_602466
proc url_PutParameter_604497(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PutParameter_604496(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Add a parameter to the system.
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
  var valid_604498 = header.getOrDefault("X-Amz-Date")
  valid_604498 = validateParameter(valid_604498, JString, required = false,
                                 default = nil)
  if valid_604498 != nil:
    section.add "X-Amz-Date", valid_604498
  var valid_604499 = header.getOrDefault("X-Amz-Security-Token")
  valid_604499 = validateParameter(valid_604499, JString, required = false,
                                 default = nil)
  if valid_604499 != nil:
    section.add "X-Amz-Security-Token", valid_604499
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604500 = header.getOrDefault("X-Amz-Target")
  valid_604500 = validateParameter(valid_604500, JString, required = true,
                                 default = newJString("AmazonSSM.PutParameter"))
  if valid_604500 != nil:
    section.add "X-Amz-Target", valid_604500
  var valid_604501 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604501 = validateParameter(valid_604501, JString, required = false,
                                 default = nil)
  if valid_604501 != nil:
    section.add "X-Amz-Content-Sha256", valid_604501
  var valid_604502 = header.getOrDefault("X-Amz-Algorithm")
  valid_604502 = validateParameter(valid_604502, JString, required = false,
                                 default = nil)
  if valid_604502 != nil:
    section.add "X-Amz-Algorithm", valid_604502
  var valid_604503 = header.getOrDefault("X-Amz-Signature")
  valid_604503 = validateParameter(valid_604503, JString, required = false,
                                 default = nil)
  if valid_604503 != nil:
    section.add "X-Amz-Signature", valid_604503
  var valid_604504 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604504 = validateParameter(valid_604504, JString, required = false,
                                 default = nil)
  if valid_604504 != nil:
    section.add "X-Amz-SignedHeaders", valid_604504
  var valid_604505 = header.getOrDefault("X-Amz-Credential")
  valid_604505 = validateParameter(valid_604505, JString, required = false,
                                 default = nil)
  if valid_604505 != nil:
    section.add "X-Amz-Credential", valid_604505
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604507: Call_PutParameter_604495; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Add a parameter to the system.
  ## 
  let valid = call_604507.validator(path, query, header, formData, body)
  let scheme = call_604507.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604507.url(scheme.get, call_604507.host, call_604507.base,
                         call_604507.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604507, url, valid)

proc call*(call_604508: Call_PutParameter_604495; body: JsonNode): Recallable =
  ## putParameter
  ## Add a parameter to the system.
  ##   body: JObject (required)
  var body_604509 = newJObject()
  if body != nil:
    body_604509 = body
  result = call_604508.call(nil, nil, nil, nil, body_604509)

var putParameter* = Call_PutParameter_604495(name: "putParameter",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.PutParameter",
    validator: validate_PutParameter_604496, base: "/", url: url_PutParameter_604497,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RegisterDefaultPatchBaseline_604510 = ref object of OpenApiRestCall_602466
proc url_RegisterDefaultPatchBaseline_604512(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_RegisterDefaultPatchBaseline_604511(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Defines the default patch baseline for the relevant operating system.</p> <p>To reset the AWS predefined patch baseline as the default, specify the full patch baseline ARN as the baseline ID value. For example, for CentOS, specify <code>arn:aws:ssm:us-east-2:733109147000:patchbaseline/pb-0574b43a65ea646ed</code> instead of <code>pb-0574b43a65ea646ed</code>.</p>
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
  var valid_604513 = header.getOrDefault("X-Amz-Date")
  valid_604513 = validateParameter(valid_604513, JString, required = false,
                                 default = nil)
  if valid_604513 != nil:
    section.add "X-Amz-Date", valid_604513
  var valid_604514 = header.getOrDefault("X-Amz-Security-Token")
  valid_604514 = validateParameter(valid_604514, JString, required = false,
                                 default = nil)
  if valid_604514 != nil:
    section.add "X-Amz-Security-Token", valid_604514
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604515 = header.getOrDefault("X-Amz-Target")
  valid_604515 = validateParameter(valid_604515, JString, required = true, default = newJString(
      "AmazonSSM.RegisterDefaultPatchBaseline"))
  if valid_604515 != nil:
    section.add "X-Amz-Target", valid_604515
  var valid_604516 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604516 = validateParameter(valid_604516, JString, required = false,
                                 default = nil)
  if valid_604516 != nil:
    section.add "X-Amz-Content-Sha256", valid_604516
  var valid_604517 = header.getOrDefault("X-Amz-Algorithm")
  valid_604517 = validateParameter(valid_604517, JString, required = false,
                                 default = nil)
  if valid_604517 != nil:
    section.add "X-Amz-Algorithm", valid_604517
  var valid_604518 = header.getOrDefault("X-Amz-Signature")
  valid_604518 = validateParameter(valid_604518, JString, required = false,
                                 default = nil)
  if valid_604518 != nil:
    section.add "X-Amz-Signature", valid_604518
  var valid_604519 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604519 = validateParameter(valid_604519, JString, required = false,
                                 default = nil)
  if valid_604519 != nil:
    section.add "X-Amz-SignedHeaders", valid_604519
  var valid_604520 = header.getOrDefault("X-Amz-Credential")
  valid_604520 = validateParameter(valid_604520, JString, required = false,
                                 default = nil)
  if valid_604520 != nil:
    section.add "X-Amz-Credential", valid_604520
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604522: Call_RegisterDefaultPatchBaseline_604510; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Defines the default patch baseline for the relevant operating system.</p> <p>To reset the AWS predefined patch baseline as the default, specify the full patch baseline ARN as the baseline ID value. For example, for CentOS, specify <code>arn:aws:ssm:us-east-2:733109147000:patchbaseline/pb-0574b43a65ea646ed</code> instead of <code>pb-0574b43a65ea646ed</code>.</p>
  ## 
  let valid = call_604522.validator(path, query, header, formData, body)
  let scheme = call_604522.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604522.url(scheme.get, call_604522.host, call_604522.base,
                         call_604522.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604522, url, valid)

proc call*(call_604523: Call_RegisterDefaultPatchBaseline_604510; body: JsonNode): Recallable =
  ## registerDefaultPatchBaseline
  ## <p>Defines the default patch baseline for the relevant operating system.</p> <p>To reset the AWS predefined patch baseline as the default, specify the full patch baseline ARN as the baseline ID value. For example, for CentOS, specify <code>arn:aws:ssm:us-east-2:733109147000:patchbaseline/pb-0574b43a65ea646ed</code> instead of <code>pb-0574b43a65ea646ed</code>.</p>
  ##   body: JObject (required)
  var body_604524 = newJObject()
  if body != nil:
    body_604524 = body
  result = call_604523.call(nil, nil, nil, nil, body_604524)

var registerDefaultPatchBaseline* = Call_RegisterDefaultPatchBaseline_604510(
    name: "registerDefaultPatchBaseline", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.RegisterDefaultPatchBaseline",
    validator: validate_RegisterDefaultPatchBaseline_604511, base: "/",
    url: url_RegisterDefaultPatchBaseline_604512,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RegisterPatchBaselineForPatchGroup_604525 = ref object of OpenApiRestCall_602466
proc url_RegisterPatchBaselineForPatchGroup_604527(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_RegisterPatchBaselineForPatchGroup_604526(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Registers a patch baseline for a patch group.
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
  var valid_604528 = header.getOrDefault("X-Amz-Date")
  valid_604528 = validateParameter(valid_604528, JString, required = false,
                                 default = nil)
  if valid_604528 != nil:
    section.add "X-Amz-Date", valid_604528
  var valid_604529 = header.getOrDefault("X-Amz-Security-Token")
  valid_604529 = validateParameter(valid_604529, JString, required = false,
                                 default = nil)
  if valid_604529 != nil:
    section.add "X-Amz-Security-Token", valid_604529
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604530 = header.getOrDefault("X-Amz-Target")
  valid_604530 = validateParameter(valid_604530, JString, required = true, default = newJString(
      "AmazonSSM.RegisterPatchBaselineForPatchGroup"))
  if valid_604530 != nil:
    section.add "X-Amz-Target", valid_604530
  var valid_604531 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604531 = validateParameter(valid_604531, JString, required = false,
                                 default = nil)
  if valid_604531 != nil:
    section.add "X-Amz-Content-Sha256", valid_604531
  var valid_604532 = header.getOrDefault("X-Amz-Algorithm")
  valid_604532 = validateParameter(valid_604532, JString, required = false,
                                 default = nil)
  if valid_604532 != nil:
    section.add "X-Amz-Algorithm", valid_604532
  var valid_604533 = header.getOrDefault("X-Amz-Signature")
  valid_604533 = validateParameter(valid_604533, JString, required = false,
                                 default = nil)
  if valid_604533 != nil:
    section.add "X-Amz-Signature", valid_604533
  var valid_604534 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604534 = validateParameter(valid_604534, JString, required = false,
                                 default = nil)
  if valid_604534 != nil:
    section.add "X-Amz-SignedHeaders", valid_604534
  var valid_604535 = header.getOrDefault("X-Amz-Credential")
  valid_604535 = validateParameter(valid_604535, JString, required = false,
                                 default = nil)
  if valid_604535 != nil:
    section.add "X-Amz-Credential", valid_604535
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604537: Call_RegisterPatchBaselineForPatchGroup_604525;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Registers a patch baseline for a patch group.
  ## 
  let valid = call_604537.validator(path, query, header, formData, body)
  let scheme = call_604537.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604537.url(scheme.get, call_604537.host, call_604537.base,
                         call_604537.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604537, url, valid)

proc call*(call_604538: Call_RegisterPatchBaselineForPatchGroup_604525;
          body: JsonNode): Recallable =
  ## registerPatchBaselineForPatchGroup
  ## Registers a patch baseline for a patch group.
  ##   body: JObject (required)
  var body_604539 = newJObject()
  if body != nil:
    body_604539 = body
  result = call_604538.call(nil, nil, nil, nil, body_604539)

var registerPatchBaselineForPatchGroup* = Call_RegisterPatchBaselineForPatchGroup_604525(
    name: "registerPatchBaselineForPatchGroup", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.RegisterPatchBaselineForPatchGroup",
    validator: validate_RegisterPatchBaselineForPatchGroup_604526, base: "/",
    url: url_RegisterPatchBaselineForPatchGroup_604527,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RegisterTargetWithMaintenanceWindow_604540 = ref object of OpenApiRestCall_602466
proc url_RegisterTargetWithMaintenanceWindow_604542(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_RegisterTargetWithMaintenanceWindow_604541(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Registers a target with a maintenance window.
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
  var valid_604543 = header.getOrDefault("X-Amz-Date")
  valid_604543 = validateParameter(valid_604543, JString, required = false,
                                 default = nil)
  if valid_604543 != nil:
    section.add "X-Amz-Date", valid_604543
  var valid_604544 = header.getOrDefault("X-Amz-Security-Token")
  valid_604544 = validateParameter(valid_604544, JString, required = false,
                                 default = nil)
  if valid_604544 != nil:
    section.add "X-Amz-Security-Token", valid_604544
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604545 = header.getOrDefault("X-Amz-Target")
  valid_604545 = validateParameter(valid_604545, JString, required = true, default = newJString(
      "AmazonSSM.RegisterTargetWithMaintenanceWindow"))
  if valid_604545 != nil:
    section.add "X-Amz-Target", valid_604545
  var valid_604546 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604546 = validateParameter(valid_604546, JString, required = false,
                                 default = nil)
  if valid_604546 != nil:
    section.add "X-Amz-Content-Sha256", valid_604546
  var valid_604547 = header.getOrDefault("X-Amz-Algorithm")
  valid_604547 = validateParameter(valid_604547, JString, required = false,
                                 default = nil)
  if valid_604547 != nil:
    section.add "X-Amz-Algorithm", valid_604547
  var valid_604548 = header.getOrDefault("X-Amz-Signature")
  valid_604548 = validateParameter(valid_604548, JString, required = false,
                                 default = nil)
  if valid_604548 != nil:
    section.add "X-Amz-Signature", valid_604548
  var valid_604549 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604549 = validateParameter(valid_604549, JString, required = false,
                                 default = nil)
  if valid_604549 != nil:
    section.add "X-Amz-SignedHeaders", valid_604549
  var valid_604550 = header.getOrDefault("X-Amz-Credential")
  valid_604550 = validateParameter(valid_604550, JString, required = false,
                                 default = nil)
  if valid_604550 != nil:
    section.add "X-Amz-Credential", valid_604550
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604552: Call_RegisterTargetWithMaintenanceWindow_604540;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Registers a target with a maintenance window.
  ## 
  let valid = call_604552.validator(path, query, header, formData, body)
  let scheme = call_604552.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604552.url(scheme.get, call_604552.host, call_604552.base,
                         call_604552.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604552, url, valid)

proc call*(call_604553: Call_RegisterTargetWithMaintenanceWindow_604540;
          body: JsonNode): Recallable =
  ## registerTargetWithMaintenanceWindow
  ## Registers a target with a maintenance window.
  ##   body: JObject (required)
  var body_604554 = newJObject()
  if body != nil:
    body_604554 = body
  result = call_604553.call(nil, nil, nil, nil, body_604554)

var registerTargetWithMaintenanceWindow* = Call_RegisterTargetWithMaintenanceWindow_604540(
    name: "registerTargetWithMaintenanceWindow", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.RegisterTargetWithMaintenanceWindow",
    validator: validate_RegisterTargetWithMaintenanceWindow_604541, base: "/",
    url: url_RegisterTargetWithMaintenanceWindow_604542,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RegisterTaskWithMaintenanceWindow_604555 = ref object of OpenApiRestCall_602466
proc url_RegisterTaskWithMaintenanceWindow_604557(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_RegisterTaskWithMaintenanceWindow_604556(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Adds a new task to a maintenance window.
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
  var valid_604558 = header.getOrDefault("X-Amz-Date")
  valid_604558 = validateParameter(valid_604558, JString, required = false,
                                 default = nil)
  if valid_604558 != nil:
    section.add "X-Amz-Date", valid_604558
  var valid_604559 = header.getOrDefault("X-Amz-Security-Token")
  valid_604559 = validateParameter(valid_604559, JString, required = false,
                                 default = nil)
  if valid_604559 != nil:
    section.add "X-Amz-Security-Token", valid_604559
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604560 = header.getOrDefault("X-Amz-Target")
  valid_604560 = validateParameter(valid_604560, JString, required = true, default = newJString(
      "AmazonSSM.RegisterTaskWithMaintenanceWindow"))
  if valid_604560 != nil:
    section.add "X-Amz-Target", valid_604560
  var valid_604561 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604561 = validateParameter(valid_604561, JString, required = false,
                                 default = nil)
  if valid_604561 != nil:
    section.add "X-Amz-Content-Sha256", valid_604561
  var valid_604562 = header.getOrDefault("X-Amz-Algorithm")
  valid_604562 = validateParameter(valid_604562, JString, required = false,
                                 default = nil)
  if valid_604562 != nil:
    section.add "X-Amz-Algorithm", valid_604562
  var valid_604563 = header.getOrDefault("X-Amz-Signature")
  valid_604563 = validateParameter(valid_604563, JString, required = false,
                                 default = nil)
  if valid_604563 != nil:
    section.add "X-Amz-Signature", valid_604563
  var valid_604564 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604564 = validateParameter(valid_604564, JString, required = false,
                                 default = nil)
  if valid_604564 != nil:
    section.add "X-Amz-SignedHeaders", valid_604564
  var valid_604565 = header.getOrDefault("X-Amz-Credential")
  valid_604565 = validateParameter(valid_604565, JString, required = false,
                                 default = nil)
  if valid_604565 != nil:
    section.add "X-Amz-Credential", valid_604565
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604567: Call_RegisterTaskWithMaintenanceWindow_604555;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Adds a new task to a maintenance window.
  ## 
  let valid = call_604567.validator(path, query, header, formData, body)
  let scheme = call_604567.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604567.url(scheme.get, call_604567.host, call_604567.base,
                         call_604567.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604567, url, valid)

proc call*(call_604568: Call_RegisterTaskWithMaintenanceWindow_604555;
          body: JsonNode): Recallable =
  ## registerTaskWithMaintenanceWindow
  ## Adds a new task to a maintenance window.
  ##   body: JObject (required)
  var body_604569 = newJObject()
  if body != nil:
    body_604569 = body
  result = call_604568.call(nil, nil, nil, nil, body_604569)

var registerTaskWithMaintenanceWindow* = Call_RegisterTaskWithMaintenanceWindow_604555(
    name: "registerTaskWithMaintenanceWindow", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.RegisterTaskWithMaintenanceWindow",
    validator: validate_RegisterTaskWithMaintenanceWindow_604556, base: "/",
    url: url_RegisterTaskWithMaintenanceWindow_604557,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RemoveTagsFromResource_604570 = ref object of OpenApiRestCall_602466
proc url_RemoveTagsFromResource_604572(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_RemoveTagsFromResource_604571(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Removes tag keys from the specified resource.
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
  var valid_604573 = header.getOrDefault("X-Amz-Date")
  valid_604573 = validateParameter(valid_604573, JString, required = false,
                                 default = nil)
  if valid_604573 != nil:
    section.add "X-Amz-Date", valid_604573
  var valid_604574 = header.getOrDefault("X-Amz-Security-Token")
  valid_604574 = validateParameter(valid_604574, JString, required = false,
                                 default = nil)
  if valid_604574 != nil:
    section.add "X-Amz-Security-Token", valid_604574
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604575 = header.getOrDefault("X-Amz-Target")
  valid_604575 = validateParameter(valid_604575, JString, required = true, default = newJString(
      "AmazonSSM.RemoveTagsFromResource"))
  if valid_604575 != nil:
    section.add "X-Amz-Target", valid_604575
  var valid_604576 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604576 = validateParameter(valid_604576, JString, required = false,
                                 default = nil)
  if valid_604576 != nil:
    section.add "X-Amz-Content-Sha256", valid_604576
  var valid_604577 = header.getOrDefault("X-Amz-Algorithm")
  valid_604577 = validateParameter(valid_604577, JString, required = false,
                                 default = nil)
  if valid_604577 != nil:
    section.add "X-Amz-Algorithm", valid_604577
  var valid_604578 = header.getOrDefault("X-Amz-Signature")
  valid_604578 = validateParameter(valid_604578, JString, required = false,
                                 default = nil)
  if valid_604578 != nil:
    section.add "X-Amz-Signature", valid_604578
  var valid_604579 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604579 = validateParameter(valid_604579, JString, required = false,
                                 default = nil)
  if valid_604579 != nil:
    section.add "X-Amz-SignedHeaders", valid_604579
  var valid_604580 = header.getOrDefault("X-Amz-Credential")
  valid_604580 = validateParameter(valid_604580, JString, required = false,
                                 default = nil)
  if valid_604580 != nil:
    section.add "X-Amz-Credential", valid_604580
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604582: Call_RemoveTagsFromResource_604570; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes tag keys from the specified resource.
  ## 
  let valid = call_604582.validator(path, query, header, formData, body)
  let scheme = call_604582.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604582.url(scheme.get, call_604582.host, call_604582.base,
                         call_604582.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604582, url, valid)

proc call*(call_604583: Call_RemoveTagsFromResource_604570; body: JsonNode): Recallable =
  ## removeTagsFromResource
  ## Removes tag keys from the specified resource.
  ##   body: JObject (required)
  var body_604584 = newJObject()
  if body != nil:
    body_604584 = body
  result = call_604583.call(nil, nil, nil, nil, body_604584)

var removeTagsFromResource* = Call_RemoveTagsFromResource_604570(
    name: "removeTagsFromResource", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.RemoveTagsFromResource",
    validator: validate_RemoveTagsFromResource_604571, base: "/",
    url: url_RemoveTagsFromResource_604572, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ResetServiceSetting_604585 = ref object of OpenApiRestCall_602466
proc url_ResetServiceSetting_604587(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ResetServiceSetting_604586(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p> <code>ServiceSetting</code> is an account-level setting for an AWS service. This setting defines how a user interacts with or uses a service or a feature of a service. For example, if an AWS service charges money to the account based on feature or service usage, then the AWS service team might create a default setting of "false". This means the user can't use this feature unless they change the setting to "true" and intentionally opt in for a paid feature.</p> <p>Services map a <code>SettingId</code> object to a setting value. AWS services teams define the default value for a <code>SettingId</code>. You can't create a new <code>SettingId</code>, but you can overwrite the default value if you have the <code>ssm:UpdateServiceSetting</code> permission for the setting. Use the <a>GetServiceSetting</a> API action to view the current value. Use the <a>UpdateServiceSetting</a> API action to change the default setting. </p> <p>Reset the service setting for the account to the default value as provisioned by the AWS service team. </p>
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
  var valid_604588 = header.getOrDefault("X-Amz-Date")
  valid_604588 = validateParameter(valid_604588, JString, required = false,
                                 default = nil)
  if valid_604588 != nil:
    section.add "X-Amz-Date", valid_604588
  var valid_604589 = header.getOrDefault("X-Amz-Security-Token")
  valid_604589 = validateParameter(valid_604589, JString, required = false,
                                 default = nil)
  if valid_604589 != nil:
    section.add "X-Amz-Security-Token", valid_604589
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604590 = header.getOrDefault("X-Amz-Target")
  valid_604590 = validateParameter(valid_604590, JString, required = true, default = newJString(
      "AmazonSSM.ResetServiceSetting"))
  if valid_604590 != nil:
    section.add "X-Amz-Target", valid_604590
  var valid_604591 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604591 = validateParameter(valid_604591, JString, required = false,
                                 default = nil)
  if valid_604591 != nil:
    section.add "X-Amz-Content-Sha256", valid_604591
  var valid_604592 = header.getOrDefault("X-Amz-Algorithm")
  valid_604592 = validateParameter(valid_604592, JString, required = false,
                                 default = nil)
  if valid_604592 != nil:
    section.add "X-Amz-Algorithm", valid_604592
  var valid_604593 = header.getOrDefault("X-Amz-Signature")
  valid_604593 = validateParameter(valid_604593, JString, required = false,
                                 default = nil)
  if valid_604593 != nil:
    section.add "X-Amz-Signature", valid_604593
  var valid_604594 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604594 = validateParameter(valid_604594, JString, required = false,
                                 default = nil)
  if valid_604594 != nil:
    section.add "X-Amz-SignedHeaders", valid_604594
  var valid_604595 = header.getOrDefault("X-Amz-Credential")
  valid_604595 = validateParameter(valid_604595, JString, required = false,
                                 default = nil)
  if valid_604595 != nil:
    section.add "X-Amz-Credential", valid_604595
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604597: Call_ResetServiceSetting_604585; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> <code>ServiceSetting</code> is an account-level setting for an AWS service. This setting defines how a user interacts with or uses a service or a feature of a service. For example, if an AWS service charges money to the account based on feature or service usage, then the AWS service team might create a default setting of "false". This means the user can't use this feature unless they change the setting to "true" and intentionally opt in for a paid feature.</p> <p>Services map a <code>SettingId</code> object to a setting value. AWS services teams define the default value for a <code>SettingId</code>. You can't create a new <code>SettingId</code>, but you can overwrite the default value if you have the <code>ssm:UpdateServiceSetting</code> permission for the setting. Use the <a>GetServiceSetting</a> API action to view the current value. Use the <a>UpdateServiceSetting</a> API action to change the default setting. </p> <p>Reset the service setting for the account to the default value as provisioned by the AWS service team. </p>
  ## 
  let valid = call_604597.validator(path, query, header, formData, body)
  let scheme = call_604597.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604597.url(scheme.get, call_604597.host, call_604597.base,
                         call_604597.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604597, url, valid)

proc call*(call_604598: Call_ResetServiceSetting_604585; body: JsonNode): Recallable =
  ## resetServiceSetting
  ## <p> <code>ServiceSetting</code> is an account-level setting for an AWS service. This setting defines how a user interacts with or uses a service or a feature of a service. For example, if an AWS service charges money to the account based on feature or service usage, then the AWS service team might create a default setting of "false". This means the user can't use this feature unless they change the setting to "true" and intentionally opt in for a paid feature.</p> <p>Services map a <code>SettingId</code> object to a setting value. AWS services teams define the default value for a <code>SettingId</code>. You can't create a new <code>SettingId</code>, but you can overwrite the default value if you have the <code>ssm:UpdateServiceSetting</code> permission for the setting. Use the <a>GetServiceSetting</a> API action to view the current value. Use the <a>UpdateServiceSetting</a> API action to change the default setting. </p> <p>Reset the service setting for the account to the default value as provisioned by the AWS service team. </p>
  ##   body: JObject (required)
  var body_604599 = newJObject()
  if body != nil:
    body_604599 = body
  result = call_604598.call(nil, nil, nil, nil, body_604599)

var resetServiceSetting* = Call_ResetServiceSetting_604585(
    name: "resetServiceSetting", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.ResetServiceSetting",
    validator: validate_ResetServiceSetting_604586, base: "/",
    url: url_ResetServiceSetting_604587, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ResumeSession_604600 = ref object of OpenApiRestCall_602466
proc url_ResumeSession_604602(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ResumeSession_604601(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Reconnects a session to an instance after it has been disconnected. Connections can be resumed for disconnected sessions, but not terminated sessions.</p> <note> <p>This command is primarily for use by client machines to automatically reconnect during intermittent network issues. It is not intended for any other use.</p> </note>
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
  var valid_604603 = header.getOrDefault("X-Amz-Date")
  valid_604603 = validateParameter(valid_604603, JString, required = false,
                                 default = nil)
  if valid_604603 != nil:
    section.add "X-Amz-Date", valid_604603
  var valid_604604 = header.getOrDefault("X-Amz-Security-Token")
  valid_604604 = validateParameter(valid_604604, JString, required = false,
                                 default = nil)
  if valid_604604 != nil:
    section.add "X-Amz-Security-Token", valid_604604
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604605 = header.getOrDefault("X-Amz-Target")
  valid_604605 = validateParameter(valid_604605, JString, required = true, default = newJString(
      "AmazonSSM.ResumeSession"))
  if valid_604605 != nil:
    section.add "X-Amz-Target", valid_604605
  var valid_604606 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604606 = validateParameter(valid_604606, JString, required = false,
                                 default = nil)
  if valid_604606 != nil:
    section.add "X-Amz-Content-Sha256", valid_604606
  var valid_604607 = header.getOrDefault("X-Amz-Algorithm")
  valid_604607 = validateParameter(valid_604607, JString, required = false,
                                 default = nil)
  if valid_604607 != nil:
    section.add "X-Amz-Algorithm", valid_604607
  var valid_604608 = header.getOrDefault("X-Amz-Signature")
  valid_604608 = validateParameter(valid_604608, JString, required = false,
                                 default = nil)
  if valid_604608 != nil:
    section.add "X-Amz-Signature", valid_604608
  var valid_604609 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604609 = validateParameter(valid_604609, JString, required = false,
                                 default = nil)
  if valid_604609 != nil:
    section.add "X-Amz-SignedHeaders", valid_604609
  var valid_604610 = header.getOrDefault("X-Amz-Credential")
  valid_604610 = validateParameter(valid_604610, JString, required = false,
                                 default = nil)
  if valid_604610 != nil:
    section.add "X-Amz-Credential", valid_604610
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604612: Call_ResumeSession_604600; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Reconnects a session to an instance after it has been disconnected. Connections can be resumed for disconnected sessions, but not terminated sessions.</p> <note> <p>This command is primarily for use by client machines to automatically reconnect during intermittent network issues. It is not intended for any other use.</p> </note>
  ## 
  let valid = call_604612.validator(path, query, header, formData, body)
  let scheme = call_604612.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604612.url(scheme.get, call_604612.host, call_604612.base,
                         call_604612.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604612, url, valid)

proc call*(call_604613: Call_ResumeSession_604600; body: JsonNode): Recallable =
  ## resumeSession
  ## <p>Reconnects a session to an instance after it has been disconnected. Connections can be resumed for disconnected sessions, but not terminated sessions.</p> <note> <p>This command is primarily for use by client machines to automatically reconnect during intermittent network issues. It is not intended for any other use.</p> </note>
  ##   body: JObject (required)
  var body_604614 = newJObject()
  if body != nil:
    body_604614 = body
  result = call_604613.call(nil, nil, nil, nil, body_604614)

var resumeSession* = Call_ResumeSession_604600(name: "resumeSession",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.ResumeSession",
    validator: validate_ResumeSession_604601, base: "/", url: url_ResumeSession_604602,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_SendAutomationSignal_604615 = ref object of OpenApiRestCall_602466
proc url_SendAutomationSignal_604617(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_SendAutomationSignal_604616(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Sends a signal to an Automation execution to change the current behavior or status of the execution. 
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
  var valid_604618 = header.getOrDefault("X-Amz-Date")
  valid_604618 = validateParameter(valid_604618, JString, required = false,
                                 default = nil)
  if valid_604618 != nil:
    section.add "X-Amz-Date", valid_604618
  var valid_604619 = header.getOrDefault("X-Amz-Security-Token")
  valid_604619 = validateParameter(valid_604619, JString, required = false,
                                 default = nil)
  if valid_604619 != nil:
    section.add "X-Amz-Security-Token", valid_604619
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604620 = header.getOrDefault("X-Amz-Target")
  valid_604620 = validateParameter(valid_604620, JString, required = true, default = newJString(
      "AmazonSSM.SendAutomationSignal"))
  if valid_604620 != nil:
    section.add "X-Amz-Target", valid_604620
  var valid_604621 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604621 = validateParameter(valid_604621, JString, required = false,
                                 default = nil)
  if valid_604621 != nil:
    section.add "X-Amz-Content-Sha256", valid_604621
  var valid_604622 = header.getOrDefault("X-Amz-Algorithm")
  valid_604622 = validateParameter(valid_604622, JString, required = false,
                                 default = nil)
  if valid_604622 != nil:
    section.add "X-Amz-Algorithm", valid_604622
  var valid_604623 = header.getOrDefault("X-Amz-Signature")
  valid_604623 = validateParameter(valid_604623, JString, required = false,
                                 default = nil)
  if valid_604623 != nil:
    section.add "X-Amz-Signature", valid_604623
  var valid_604624 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604624 = validateParameter(valid_604624, JString, required = false,
                                 default = nil)
  if valid_604624 != nil:
    section.add "X-Amz-SignedHeaders", valid_604624
  var valid_604625 = header.getOrDefault("X-Amz-Credential")
  valid_604625 = validateParameter(valid_604625, JString, required = false,
                                 default = nil)
  if valid_604625 != nil:
    section.add "X-Amz-Credential", valid_604625
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604627: Call_SendAutomationSignal_604615; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sends a signal to an Automation execution to change the current behavior or status of the execution. 
  ## 
  let valid = call_604627.validator(path, query, header, formData, body)
  let scheme = call_604627.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604627.url(scheme.get, call_604627.host, call_604627.base,
                         call_604627.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604627, url, valid)

proc call*(call_604628: Call_SendAutomationSignal_604615; body: JsonNode): Recallable =
  ## sendAutomationSignal
  ## Sends a signal to an Automation execution to change the current behavior or status of the execution. 
  ##   body: JObject (required)
  var body_604629 = newJObject()
  if body != nil:
    body_604629 = body
  result = call_604628.call(nil, nil, nil, nil, body_604629)

var sendAutomationSignal* = Call_SendAutomationSignal_604615(
    name: "sendAutomationSignal", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.SendAutomationSignal",
    validator: validate_SendAutomationSignal_604616, base: "/",
    url: url_SendAutomationSignal_604617, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SendCommand_604630 = ref object of OpenApiRestCall_602466
proc url_SendCommand_604632(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_SendCommand_604631(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Runs commands on one or more managed instances.
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
  var valid_604633 = header.getOrDefault("X-Amz-Date")
  valid_604633 = validateParameter(valid_604633, JString, required = false,
                                 default = nil)
  if valid_604633 != nil:
    section.add "X-Amz-Date", valid_604633
  var valid_604634 = header.getOrDefault("X-Amz-Security-Token")
  valid_604634 = validateParameter(valid_604634, JString, required = false,
                                 default = nil)
  if valid_604634 != nil:
    section.add "X-Amz-Security-Token", valid_604634
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604635 = header.getOrDefault("X-Amz-Target")
  valid_604635 = validateParameter(valid_604635, JString, required = true,
                                 default = newJString("AmazonSSM.SendCommand"))
  if valid_604635 != nil:
    section.add "X-Amz-Target", valid_604635
  var valid_604636 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604636 = validateParameter(valid_604636, JString, required = false,
                                 default = nil)
  if valid_604636 != nil:
    section.add "X-Amz-Content-Sha256", valid_604636
  var valid_604637 = header.getOrDefault("X-Amz-Algorithm")
  valid_604637 = validateParameter(valid_604637, JString, required = false,
                                 default = nil)
  if valid_604637 != nil:
    section.add "X-Amz-Algorithm", valid_604637
  var valid_604638 = header.getOrDefault("X-Amz-Signature")
  valid_604638 = validateParameter(valid_604638, JString, required = false,
                                 default = nil)
  if valid_604638 != nil:
    section.add "X-Amz-Signature", valid_604638
  var valid_604639 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604639 = validateParameter(valid_604639, JString, required = false,
                                 default = nil)
  if valid_604639 != nil:
    section.add "X-Amz-SignedHeaders", valid_604639
  var valid_604640 = header.getOrDefault("X-Amz-Credential")
  valid_604640 = validateParameter(valid_604640, JString, required = false,
                                 default = nil)
  if valid_604640 != nil:
    section.add "X-Amz-Credential", valid_604640
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604642: Call_SendCommand_604630; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Runs commands on one or more managed instances.
  ## 
  let valid = call_604642.validator(path, query, header, formData, body)
  let scheme = call_604642.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604642.url(scheme.get, call_604642.host, call_604642.base,
                         call_604642.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604642, url, valid)

proc call*(call_604643: Call_SendCommand_604630; body: JsonNode): Recallable =
  ## sendCommand
  ## Runs commands on one or more managed instances.
  ##   body: JObject (required)
  var body_604644 = newJObject()
  if body != nil:
    body_604644 = body
  result = call_604643.call(nil, nil, nil, nil, body_604644)

var sendCommand* = Call_SendCommand_604630(name: "sendCommand",
                                        meth: HttpMethod.HttpPost,
                                        host: "ssm.amazonaws.com", route: "/#X-Amz-Target=AmazonSSM.SendCommand",
                                        validator: validate_SendCommand_604631,
                                        base: "/", url: url_SendCommand_604632,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartAssociationsOnce_604645 = ref object of OpenApiRestCall_602466
proc url_StartAssociationsOnce_604647(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StartAssociationsOnce_604646(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Use this API action to run an association immediately and only one time. This action can be helpful when troubleshooting associations.
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
  var valid_604648 = header.getOrDefault("X-Amz-Date")
  valid_604648 = validateParameter(valid_604648, JString, required = false,
                                 default = nil)
  if valid_604648 != nil:
    section.add "X-Amz-Date", valid_604648
  var valid_604649 = header.getOrDefault("X-Amz-Security-Token")
  valid_604649 = validateParameter(valid_604649, JString, required = false,
                                 default = nil)
  if valid_604649 != nil:
    section.add "X-Amz-Security-Token", valid_604649
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604650 = header.getOrDefault("X-Amz-Target")
  valid_604650 = validateParameter(valid_604650, JString, required = true, default = newJString(
      "AmazonSSM.StartAssociationsOnce"))
  if valid_604650 != nil:
    section.add "X-Amz-Target", valid_604650
  var valid_604651 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604651 = validateParameter(valid_604651, JString, required = false,
                                 default = nil)
  if valid_604651 != nil:
    section.add "X-Amz-Content-Sha256", valid_604651
  var valid_604652 = header.getOrDefault("X-Amz-Algorithm")
  valid_604652 = validateParameter(valid_604652, JString, required = false,
                                 default = nil)
  if valid_604652 != nil:
    section.add "X-Amz-Algorithm", valid_604652
  var valid_604653 = header.getOrDefault("X-Amz-Signature")
  valid_604653 = validateParameter(valid_604653, JString, required = false,
                                 default = nil)
  if valid_604653 != nil:
    section.add "X-Amz-Signature", valid_604653
  var valid_604654 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604654 = validateParameter(valid_604654, JString, required = false,
                                 default = nil)
  if valid_604654 != nil:
    section.add "X-Amz-SignedHeaders", valid_604654
  var valid_604655 = header.getOrDefault("X-Amz-Credential")
  valid_604655 = validateParameter(valid_604655, JString, required = false,
                                 default = nil)
  if valid_604655 != nil:
    section.add "X-Amz-Credential", valid_604655
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604657: Call_StartAssociationsOnce_604645; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Use this API action to run an association immediately and only one time. This action can be helpful when troubleshooting associations.
  ## 
  let valid = call_604657.validator(path, query, header, formData, body)
  let scheme = call_604657.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604657.url(scheme.get, call_604657.host, call_604657.base,
                         call_604657.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604657, url, valid)

proc call*(call_604658: Call_StartAssociationsOnce_604645; body: JsonNode): Recallable =
  ## startAssociationsOnce
  ## Use this API action to run an association immediately and only one time. This action can be helpful when troubleshooting associations.
  ##   body: JObject (required)
  var body_604659 = newJObject()
  if body != nil:
    body_604659 = body
  result = call_604658.call(nil, nil, nil, nil, body_604659)

var startAssociationsOnce* = Call_StartAssociationsOnce_604645(
    name: "startAssociationsOnce", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.StartAssociationsOnce",
    validator: validate_StartAssociationsOnce_604646, base: "/",
    url: url_StartAssociationsOnce_604647, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartAutomationExecution_604660 = ref object of OpenApiRestCall_602466
proc url_StartAutomationExecution_604662(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StartAutomationExecution_604661(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Initiates execution of an Automation document.
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
  var valid_604663 = header.getOrDefault("X-Amz-Date")
  valid_604663 = validateParameter(valid_604663, JString, required = false,
                                 default = nil)
  if valid_604663 != nil:
    section.add "X-Amz-Date", valid_604663
  var valid_604664 = header.getOrDefault("X-Amz-Security-Token")
  valid_604664 = validateParameter(valid_604664, JString, required = false,
                                 default = nil)
  if valid_604664 != nil:
    section.add "X-Amz-Security-Token", valid_604664
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604665 = header.getOrDefault("X-Amz-Target")
  valid_604665 = validateParameter(valid_604665, JString, required = true, default = newJString(
      "AmazonSSM.StartAutomationExecution"))
  if valid_604665 != nil:
    section.add "X-Amz-Target", valid_604665
  var valid_604666 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604666 = validateParameter(valid_604666, JString, required = false,
                                 default = nil)
  if valid_604666 != nil:
    section.add "X-Amz-Content-Sha256", valid_604666
  var valid_604667 = header.getOrDefault("X-Amz-Algorithm")
  valid_604667 = validateParameter(valid_604667, JString, required = false,
                                 default = nil)
  if valid_604667 != nil:
    section.add "X-Amz-Algorithm", valid_604667
  var valid_604668 = header.getOrDefault("X-Amz-Signature")
  valid_604668 = validateParameter(valid_604668, JString, required = false,
                                 default = nil)
  if valid_604668 != nil:
    section.add "X-Amz-Signature", valid_604668
  var valid_604669 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604669 = validateParameter(valid_604669, JString, required = false,
                                 default = nil)
  if valid_604669 != nil:
    section.add "X-Amz-SignedHeaders", valid_604669
  var valid_604670 = header.getOrDefault("X-Amz-Credential")
  valid_604670 = validateParameter(valid_604670, JString, required = false,
                                 default = nil)
  if valid_604670 != nil:
    section.add "X-Amz-Credential", valid_604670
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604672: Call_StartAutomationExecution_604660; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Initiates execution of an Automation document.
  ## 
  let valid = call_604672.validator(path, query, header, formData, body)
  let scheme = call_604672.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604672.url(scheme.get, call_604672.host, call_604672.base,
                         call_604672.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604672, url, valid)

proc call*(call_604673: Call_StartAutomationExecution_604660; body: JsonNode): Recallable =
  ## startAutomationExecution
  ## Initiates execution of an Automation document.
  ##   body: JObject (required)
  var body_604674 = newJObject()
  if body != nil:
    body_604674 = body
  result = call_604673.call(nil, nil, nil, nil, body_604674)

var startAutomationExecution* = Call_StartAutomationExecution_604660(
    name: "startAutomationExecution", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.StartAutomationExecution",
    validator: validate_StartAutomationExecution_604661, base: "/",
    url: url_StartAutomationExecution_604662, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartSession_604675 = ref object of OpenApiRestCall_602466
proc url_StartSession_604677(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StartSession_604676(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Initiates a connection to a target (for example, an instance) for a Session Manager session. Returns a URL and token that can be used to open a WebSocket connection for sending input and receiving outputs.</p> <note> <p>AWS CLI usage: <code>start-session</code> is an interactive command that requires the Session Manager plugin to be installed on the client machine making the call. For information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html"> Install the Session Manager Plugin for the AWS CLI</a> in the <i>AWS Systems Manager User Guide</i>.</p> <p>AWS Tools for PowerShell usage: Start-SSMSession is not currently supported by AWS Tools for PowerShell on Windows local machines.</p> </note>
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
  var valid_604678 = header.getOrDefault("X-Amz-Date")
  valid_604678 = validateParameter(valid_604678, JString, required = false,
                                 default = nil)
  if valid_604678 != nil:
    section.add "X-Amz-Date", valid_604678
  var valid_604679 = header.getOrDefault("X-Amz-Security-Token")
  valid_604679 = validateParameter(valid_604679, JString, required = false,
                                 default = nil)
  if valid_604679 != nil:
    section.add "X-Amz-Security-Token", valid_604679
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604680 = header.getOrDefault("X-Amz-Target")
  valid_604680 = validateParameter(valid_604680, JString, required = true,
                                 default = newJString("AmazonSSM.StartSession"))
  if valid_604680 != nil:
    section.add "X-Amz-Target", valid_604680
  var valid_604681 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604681 = validateParameter(valid_604681, JString, required = false,
                                 default = nil)
  if valid_604681 != nil:
    section.add "X-Amz-Content-Sha256", valid_604681
  var valid_604682 = header.getOrDefault("X-Amz-Algorithm")
  valid_604682 = validateParameter(valid_604682, JString, required = false,
                                 default = nil)
  if valid_604682 != nil:
    section.add "X-Amz-Algorithm", valid_604682
  var valid_604683 = header.getOrDefault("X-Amz-Signature")
  valid_604683 = validateParameter(valid_604683, JString, required = false,
                                 default = nil)
  if valid_604683 != nil:
    section.add "X-Amz-Signature", valid_604683
  var valid_604684 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604684 = validateParameter(valid_604684, JString, required = false,
                                 default = nil)
  if valid_604684 != nil:
    section.add "X-Amz-SignedHeaders", valid_604684
  var valid_604685 = header.getOrDefault("X-Amz-Credential")
  valid_604685 = validateParameter(valid_604685, JString, required = false,
                                 default = nil)
  if valid_604685 != nil:
    section.add "X-Amz-Credential", valid_604685
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604687: Call_StartSession_604675; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Initiates a connection to a target (for example, an instance) for a Session Manager session. Returns a URL and token that can be used to open a WebSocket connection for sending input and receiving outputs.</p> <note> <p>AWS CLI usage: <code>start-session</code> is an interactive command that requires the Session Manager plugin to be installed on the client machine making the call. For information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html"> Install the Session Manager Plugin for the AWS CLI</a> in the <i>AWS Systems Manager User Guide</i>.</p> <p>AWS Tools for PowerShell usage: Start-SSMSession is not currently supported by AWS Tools for PowerShell on Windows local machines.</p> </note>
  ## 
  let valid = call_604687.validator(path, query, header, formData, body)
  let scheme = call_604687.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604687.url(scheme.get, call_604687.host, call_604687.base,
                         call_604687.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604687, url, valid)

proc call*(call_604688: Call_StartSession_604675; body: JsonNode): Recallable =
  ## startSession
  ## <p>Initiates a connection to a target (for example, an instance) for a Session Manager session. Returns a URL and token that can be used to open a WebSocket connection for sending input and receiving outputs.</p> <note> <p>AWS CLI usage: <code>start-session</code> is an interactive command that requires the Session Manager plugin to be installed on the client machine making the call. For information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html"> Install the Session Manager Plugin for the AWS CLI</a> in the <i>AWS Systems Manager User Guide</i>.</p> <p>AWS Tools for PowerShell usage: Start-SSMSession is not currently supported by AWS Tools for PowerShell on Windows local machines.</p> </note>
  ##   body: JObject (required)
  var body_604689 = newJObject()
  if body != nil:
    body_604689 = body
  result = call_604688.call(nil, nil, nil, nil, body_604689)

var startSession* = Call_StartSession_604675(name: "startSession",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.StartSession",
    validator: validate_StartSession_604676, base: "/", url: url_StartSession_604677,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopAutomationExecution_604690 = ref object of OpenApiRestCall_602466
proc url_StopAutomationExecution_604692(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StopAutomationExecution_604691(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Stop an Automation that is currently running.
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
  var valid_604693 = header.getOrDefault("X-Amz-Date")
  valid_604693 = validateParameter(valid_604693, JString, required = false,
                                 default = nil)
  if valid_604693 != nil:
    section.add "X-Amz-Date", valid_604693
  var valid_604694 = header.getOrDefault("X-Amz-Security-Token")
  valid_604694 = validateParameter(valid_604694, JString, required = false,
                                 default = nil)
  if valid_604694 != nil:
    section.add "X-Amz-Security-Token", valid_604694
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604695 = header.getOrDefault("X-Amz-Target")
  valid_604695 = validateParameter(valid_604695, JString, required = true, default = newJString(
      "AmazonSSM.StopAutomationExecution"))
  if valid_604695 != nil:
    section.add "X-Amz-Target", valid_604695
  var valid_604696 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604696 = validateParameter(valid_604696, JString, required = false,
                                 default = nil)
  if valid_604696 != nil:
    section.add "X-Amz-Content-Sha256", valid_604696
  var valid_604697 = header.getOrDefault("X-Amz-Algorithm")
  valid_604697 = validateParameter(valid_604697, JString, required = false,
                                 default = nil)
  if valid_604697 != nil:
    section.add "X-Amz-Algorithm", valid_604697
  var valid_604698 = header.getOrDefault("X-Amz-Signature")
  valid_604698 = validateParameter(valid_604698, JString, required = false,
                                 default = nil)
  if valid_604698 != nil:
    section.add "X-Amz-Signature", valid_604698
  var valid_604699 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604699 = validateParameter(valid_604699, JString, required = false,
                                 default = nil)
  if valid_604699 != nil:
    section.add "X-Amz-SignedHeaders", valid_604699
  var valid_604700 = header.getOrDefault("X-Amz-Credential")
  valid_604700 = validateParameter(valid_604700, JString, required = false,
                                 default = nil)
  if valid_604700 != nil:
    section.add "X-Amz-Credential", valid_604700
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604702: Call_StopAutomationExecution_604690; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Stop an Automation that is currently running.
  ## 
  let valid = call_604702.validator(path, query, header, formData, body)
  let scheme = call_604702.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604702.url(scheme.get, call_604702.host, call_604702.base,
                         call_604702.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604702, url, valid)

proc call*(call_604703: Call_StopAutomationExecution_604690; body: JsonNode): Recallable =
  ## stopAutomationExecution
  ## Stop an Automation that is currently running.
  ##   body: JObject (required)
  var body_604704 = newJObject()
  if body != nil:
    body_604704 = body
  result = call_604703.call(nil, nil, nil, nil, body_604704)

var stopAutomationExecution* = Call_StopAutomationExecution_604690(
    name: "stopAutomationExecution", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.StopAutomationExecution",
    validator: validate_StopAutomationExecution_604691, base: "/",
    url: url_StopAutomationExecution_604692, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TerminateSession_604705 = ref object of OpenApiRestCall_602466
proc url_TerminateSession_604707(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_TerminateSession_604706(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Permanently ends a session and closes the data connection between the Session Manager client and SSM Agent on the instance. A terminated session cannot be resumed.
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
  var valid_604708 = header.getOrDefault("X-Amz-Date")
  valid_604708 = validateParameter(valid_604708, JString, required = false,
                                 default = nil)
  if valid_604708 != nil:
    section.add "X-Amz-Date", valid_604708
  var valid_604709 = header.getOrDefault("X-Amz-Security-Token")
  valid_604709 = validateParameter(valid_604709, JString, required = false,
                                 default = nil)
  if valid_604709 != nil:
    section.add "X-Amz-Security-Token", valid_604709
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604710 = header.getOrDefault("X-Amz-Target")
  valid_604710 = validateParameter(valid_604710, JString, required = true, default = newJString(
      "AmazonSSM.TerminateSession"))
  if valid_604710 != nil:
    section.add "X-Amz-Target", valid_604710
  var valid_604711 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604711 = validateParameter(valid_604711, JString, required = false,
                                 default = nil)
  if valid_604711 != nil:
    section.add "X-Amz-Content-Sha256", valid_604711
  var valid_604712 = header.getOrDefault("X-Amz-Algorithm")
  valid_604712 = validateParameter(valid_604712, JString, required = false,
                                 default = nil)
  if valid_604712 != nil:
    section.add "X-Amz-Algorithm", valid_604712
  var valid_604713 = header.getOrDefault("X-Amz-Signature")
  valid_604713 = validateParameter(valid_604713, JString, required = false,
                                 default = nil)
  if valid_604713 != nil:
    section.add "X-Amz-Signature", valid_604713
  var valid_604714 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604714 = validateParameter(valid_604714, JString, required = false,
                                 default = nil)
  if valid_604714 != nil:
    section.add "X-Amz-SignedHeaders", valid_604714
  var valid_604715 = header.getOrDefault("X-Amz-Credential")
  valid_604715 = validateParameter(valid_604715, JString, required = false,
                                 default = nil)
  if valid_604715 != nil:
    section.add "X-Amz-Credential", valid_604715
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604717: Call_TerminateSession_604705; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Permanently ends a session and closes the data connection between the Session Manager client and SSM Agent on the instance. A terminated session cannot be resumed.
  ## 
  let valid = call_604717.validator(path, query, header, formData, body)
  let scheme = call_604717.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604717.url(scheme.get, call_604717.host, call_604717.base,
                         call_604717.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604717, url, valid)

proc call*(call_604718: Call_TerminateSession_604705; body: JsonNode): Recallable =
  ## terminateSession
  ## Permanently ends a session and closes the data connection between the Session Manager client and SSM Agent on the instance. A terminated session cannot be resumed.
  ##   body: JObject (required)
  var body_604719 = newJObject()
  if body != nil:
    body_604719 = body
  result = call_604718.call(nil, nil, nil, nil, body_604719)

var terminateSession* = Call_TerminateSession_604705(name: "terminateSession",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.TerminateSession",
    validator: validate_TerminateSession_604706, base: "/",
    url: url_TerminateSession_604707, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateAssociation_604720 = ref object of OpenApiRestCall_602466
proc url_UpdateAssociation_604722(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateAssociation_604721(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p>Updates an association. You can update the association name and version, the document version, schedule, parameters, and Amazon S3 output. </p> <p>In order to call this API action, your IAM user account, group, or role must be configured with permission to call the <a>DescribeAssociation</a> API action. If you don't have permission to call DescribeAssociation, then you receive the following error: <code>An error occurred (AccessDeniedException) when calling the UpdateAssociation operation: User: &lt;user_arn&gt; is not authorized to perform: ssm:DescribeAssociation on resource: &lt;resource_arn&gt;</code> </p> <important> <p>When you update an association, the association immediately runs against the specified targets.</p> </important>
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
  var valid_604723 = header.getOrDefault("X-Amz-Date")
  valid_604723 = validateParameter(valid_604723, JString, required = false,
                                 default = nil)
  if valid_604723 != nil:
    section.add "X-Amz-Date", valid_604723
  var valid_604724 = header.getOrDefault("X-Amz-Security-Token")
  valid_604724 = validateParameter(valid_604724, JString, required = false,
                                 default = nil)
  if valid_604724 != nil:
    section.add "X-Amz-Security-Token", valid_604724
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604725 = header.getOrDefault("X-Amz-Target")
  valid_604725 = validateParameter(valid_604725, JString, required = true, default = newJString(
      "AmazonSSM.UpdateAssociation"))
  if valid_604725 != nil:
    section.add "X-Amz-Target", valid_604725
  var valid_604726 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604726 = validateParameter(valid_604726, JString, required = false,
                                 default = nil)
  if valid_604726 != nil:
    section.add "X-Amz-Content-Sha256", valid_604726
  var valid_604727 = header.getOrDefault("X-Amz-Algorithm")
  valid_604727 = validateParameter(valid_604727, JString, required = false,
                                 default = nil)
  if valid_604727 != nil:
    section.add "X-Amz-Algorithm", valid_604727
  var valid_604728 = header.getOrDefault("X-Amz-Signature")
  valid_604728 = validateParameter(valid_604728, JString, required = false,
                                 default = nil)
  if valid_604728 != nil:
    section.add "X-Amz-Signature", valid_604728
  var valid_604729 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604729 = validateParameter(valid_604729, JString, required = false,
                                 default = nil)
  if valid_604729 != nil:
    section.add "X-Amz-SignedHeaders", valid_604729
  var valid_604730 = header.getOrDefault("X-Amz-Credential")
  valid_604730 = validateParameter(valid_604730, JString, required = false,
                                 default = nil)
  if valid_604730 != nil:
    section.add "X-Amz-Credential", valid_604730
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604732: Call_UpdateAssociation_604720; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates an association. You can update the association name and version, the document version, schedule, parameters, and Amazon S3 output. </p> <p>In order to call this API action, your IAM user account, group, or role must be configured with permission to call the <a>DescribeAssociation</a> API action. If you don't have permission to call DescribeAssociation, then you receive the following error: <code>An error occurred (AccessDeniedException) when calling the UpdateAssociation operation: User: &lt;user_arn&gt; is not authorized to perform: ssm:DescribeAssociation on resource: &lt;resource_arn&gt;</code> </p> <important> <p>When you update an association, the association immediately runs against the specified targets.</p> </important>
  ## 
  let valid = call_604732.validator(path, query, header, formData, body)
  let scheme = call_604732.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604732.url(scheme.get, call_604732.host, call_604732.base,
                         call_604732.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604732, url, valid)

proc call*(call_604733: Call_UpdateAssociation_604720; body: JsonNode): Recallable =
  ## updateAssociation
  ## <p>Updates an association. You can update the association name and version, the document version, schedule, parameters, and Amazon S3 output. </p> <p>In order to call this API action, your IAM user account, group, or role must be configured with permission to call the <a>DescribeAssociation</a> API action. If you don't have permission to call DescribeAssociation, then you receive the following error: <code>An error occurred (AccessDeniedException) when calling the UpdateAssociation operation: User: &lt;user_arn&gt; is not authorized to perform: ssm:DescribeAssociation on resource: &lt;resource_arn&gt;</code> </p> <important> <p>When you update an association, the association immediately runs against the specified targets.</p> </important>
  ##   body: JObject (required)
  var body_604734 = newJObject()
  if body != nil:
    body_604734 = body
  result = call_604733.call(nil, nil, nil, nil, body_604734)

var updateAssociation* = Call_UpdateAssociation_604720(name: "updateAssociation",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.UpdateAssociation",
    validator: validate_UpdateAssociation_604721, base: "/",
    url: url_UpdateAssociation_604722, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateAssociationStatus_604735 = ref object of OpenApiRestCall_602466
proc url_UpdateAssociationStatus_604737(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateAssociationStatus_604736(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates the status of the Systems Manager document associated with the specified instance.
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
  var valid_604738 = header.getOrDefault("X-Amz-Date")
  valid_604738 = validateParameter(valid_604738, JString, required = false,
                                 default = nil)
  if valid_604738 != nil:
    section.add "X-Amz-Date", valid_604738
  var valid_604739 = header.getOrDefault("X-Amz-Security-Token")
  valid_604739 = validateParameter(valid_604739, JString, required = false,
                                 default = nil)
  if valid_604739 != nil:
    section.add "X-Amz-Security-Token", valid_604739
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604740 = header.getOrDefault("X-Amz-Target")
  valid_604740 = validateParameter(valid_604740, JString, required = true, default = newJString(
      "AmazonSSM.UpdateAssociationStatus"))
  if valid_604740 != nil:
    section.add "X-Amz-Target", valid_604740
  var valid_604741 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604741 = validateParameter(valid_604741, JString, required = false,
                                 default = nil)
  if valid_604741 != nil:
    section.add "X-Amz-Content-Sha256", valid_604741
  var valid_604742 = header.getOrDefault("X-Amz-Algorithm")
  valid_604742 = validateParameter(valid_604742, JString, required = false,
                                 default = nil)
  if valid_604742 != nil:
    section.add "X-Amz-Algorithm", valid_604742
  var valid_604743 = header.getOrDefault("X-Amz-Signature")
  valid_604743 = validateParameter(valid_604743, JString, required = false,
                                 default = nil)
  if valid_604743 != nil:
    section.add "X-Amz-Signature", valid_604743
  var valid_604744 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604744 = validateParameter(valid_604744, JString, required = false,
                                 default = nil)
  if valid_604744 != nil:
    section.add "X-Amz-SignedHeaders", valid_604744
  var valid_604745 = header.getOrDefault("X-Amz-Credential")
  valid_604745 = validateParameter(valid_604745, JString, required = false,
                                 default = nil)
  if valid_604745 != nil:
    section.add "X-Amz-Credential", valid_604745
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604747: Call_UpdateAssociationStatus_604735; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the status of the Systems Manager document associated with the specified instance.
  ## 
  let valid = call_604747.validator(path, query, header, formData, body)
  let scheme = call_604747.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604747.url(scheme.get, call_604747.host, call_604747.base,
                         call_604747.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604747, url, valid)

proc call*(call_604748: Call_UpdateAssociationStatus_604735; body: JsonNode): Recallable =
  ## updateAssociationStatus
  ## Updates the status of the Systems Manager document associated with the specified instance.
  ##   body: JObject (required)
  var body_604749 = newJObject()
  if body != nil:
    body_604749 = body
  result = call_604748.call(nil, nil, nil, nil, body_604749)

var updateAssociationStatus* = Call_UpdateAssociationStatus_604735(
    name: "updateAssociationStatus", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.UpdateAssociationStatus",
    validator: validate_UpdateAssociationStatus_604736, base: "/",
    url: url_UpdateAssociationStatus_604737, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDocument_604750 = ref object of OpenApiRestCall_602466
proc url_UpdateDocument_604752(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateDocument_604751(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Updates one or more values for an SSM document.
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
  var valid_604753 = header.getOrDefault("X-Amz-Date")
  valid_604753 = validateParameter(valid_604753, JString, required = false,
                                 default = nil)
  if valid_604753 != nil:
    section.add "X-Amz-Date", valid_604753
  var valid_604754 = header.getOrDefault("X-Amz-Security-Token")
  valid_604754 = validateParameter(valid_604754, JString, required = false,
                                 default = nil)
  if valid_604754 != nil:
    section.add "X-Amz-Security-Token", valid_604754
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604755 = header.getOrDefault("X-Amz-Target")
  valid_604755 = validateParameter(valid_604755, JString, required = true, default = newJString(
      "AmazonSSM.UpdateDocument"))
  if valid_604755 != nil:
    section.add "X-Amz-Target", valid_604755
  var valid_604756 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604756 = validateParameter(valid_604756, JString, required = false,
                                 default = nil)
  if valid_604756 != nil:
    section.add "X-Amz-Content-Sha256", valid_604756
  var valid_604757 = header.getOrDefault("X-Amz-Algorithm")
  valid_604757 = validateParameter(valid_604757, JString, required = false,
                                 default = nil)
  if valid_604757 != nil:
    section.add "X-Amz-Algorithm", valid_604757
  var valid_604758 = header.getOrDefault("X-Amz-Signature")
  valid_604758 = validateParameter(valid_604758, JString, required = false,
                                 default = nil)
  if valid_604758 != nil:
    section.add "X-Amz-Signature", valid_604758
  var valid_604759 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604759 = validateParameter(valid_604759, JString, required = false,
                                 default = nil)
  if valid_604759 != nil:
    section.add "X-Amz-SignedHeaders", valid_604759
  var valid_604760 = header.getOrDefault("X-Amz-Credential")
  valid_604760 = validateParameter(valid_604760, JString, required = false,
                                 default = nil)
  if valid_604760 != nil:
    section.add "X-Amz-Credential", valid_604760
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604762: Call_UpdateDocument_604750; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates one or more values for an SSM document.
  ## 
  let valid = call_604762.validator(path, query, header, formData, body)
  let scheme = call_604762.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604762.url(scheme.get, call_604762.host, call_604762.base,
                         call_604762.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604762, url, valid)

proc call*(call_604763: Call_UpdateDocument_604750; body: JsonNode): Recallable =
  ## updateDocument
  ## Updates one or more values for an SSM document.
  ##   body: JObject (required)
  var body_604764 = newJObject()
  if body != nil:
    body_604764 = body
  result = call_604763.call(nil, nil, nil, nil, body_604764)

var updateDocument* = Call_UpdateDocument_604750(name: "updateDocument",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.UpdateDocument",
    validator: validate_UpdateDocument_604751, base: "/", url: url_UpdateDocument_604752,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDocumentDefaultVersion_604765 = ref object of OpenApiRestCall_602466
proc url_UpdateDocumentDefaultVersion_604767(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateDocumentDefaultVersion_604766(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Set the default version of a document. 
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
  var valid_604768 = header.getOrDefault("X-Amz-Date")
  valid_604768 = validateParameter(valid_604768, JString, required = false,
                                 default = nil)
  if valid_604768 != nil:
    section.add "X-Amz-Date", valid_604768
  var valid_604769 = header.getOrDefault("X-Amz-Security-Token")
  valid_604769 = validateParameter(valid_604769, JString, required = false,
                                 default = nil)
  if valid_604769 != nil:
    section.add "X-Amz-Security-Token", valid_604769
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604770 = header.getOrDefault("X-Amz-Target")
  valid_604770 = validateParameter(valid_604770, JString, required = true, default = newJString(
      "AmazonSSM.UpdateDocumentDefaultVersion"))
  if valid_604770 != nil:
    section.add "X-Amz-Target", valid_604770
  var valid_604771 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604771 = validateParameter(valid_604771, JString, required = false,
                                 default = nil)
  if valid_604771 != nil:
    section.add "X-Amz-Content-Sha256", valid_604771
  var valid_604772 = header.getOrDefault("X-Amz-Algorithm")
  valid_604772 = validateParameter(valid_604772, JString, required = false,
                                 default = nil)
  if valid_604772 != nil:
    section.add "X-Amz-Algorithm", valid_604772
  var valid_604773 = header.getOrDefault("X-Amz-Signature")
  valid_604773 = validateParameter(valid_604773, JString, required = false,
                                 default = nil)
  if valid_604773 != nil:
    section.add "X-Amz-Signature", valid_604773
  var valid_604774 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604774 = validateParameter(valid_604774, JString, required = false,
                                 default = nil)
  if valid_604774 != nil:
    section.add "X-Amz-SignedHeaders", valid_604774
  var valid_604775 = header.getOrDefault("X-Amz-Credential")
  valid_604775 = validateParameter(valid_604775, JString, required = false,
                                 default = nil)
  if valid_604775 != nil:
    section.add "X-Amz-Credential", valid_604775
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604777: Call_UpdateDocumentDefaultVersion_604765; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Set the default version of a document. 
  ## 
  let valid = call_604777.validator(path, query, header, formData, body)
  let scheme = call_604777.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604777.url(scheme.get, call_604777.host, call_604777.base,
                         call_604777.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604777, url, valid)

proc call*(call_604778: Call_UpdateDocumentDefaultVersion_604765; body: JsonNode): Recallable =
  ## updateDocumentDefaultVersion
  ## Set the default version of a document. 
  ##   body: JObject (required)
  var body_604779 = newJObject()
  if body != nil:
    body_604779 = body
  result = call_604778.call(nil, nil, nil, nil, body_604779)

var updateDocumentDefaultVersion* = Call_UpdateDocumentDefaultVersion_604765(
    name: "updateDocumentDefaultVersion", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.UpdateDocumentDefaultVersion",
    validator: validate_UpdateDocumentDefaultVersion_604766, base: "/",
    url: url_UpdateDocumentDefaultVersion_604767,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateMaintenanceWindow_604780 = ref object of OpenApiRestCall_602466
proc url_UpdateMaintenanceWindow_604782(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateMaintenanceWindow_604781(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Updates an existing maintenance window. Only specified parameters are modified.</p> <note> <p>The value you specify for <code>Duration</code> determines the specific end time for the maintenance window based on the time it begins. No maintenance window tasks are permitted to start after the resulting endtime minus the number of hours you specify for <code>Cutoff</code>. For example, if the maintenance window starts at 3 PM, the duration is three hours, and the value you specify for <code>Cutoff</code> is one hour, no maintenance window tasks can start after 5 PM.</p> </note>
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
  var valid_604783 = header.getOrDefault("X-Amz-Date")
  valid_604783 = validateParameter(valid_604783, JString, required = false,
                                 default = nil)
  if valid_604783 != nil:
    section.add "X-Amz-Date", valid_604783
  var valid_604784 = header.getOrDefault("X-Amz-Security-Token")
  valid_604784 = validateParameter(valid_604784, JString, required = false,
                                 default = nil)
  if valid_604784 != nil:
    section.add "X-Amz-Security-Token", valid_604784
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604785 = header.getOrDefault("X-Amz-Target")
  valid_604785 = validateParameter(valid_604785, JString, required = true, default = newJString(
      "AmazonSSM.UpdateMaintenanceWindow"))
  if valid_604785 != nil:
    section.add "X-Amz-Target", valid_604785
  var valid_604786 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604786 = validateParameter(valid_604786, JString, required = false,
                                 default = nil)
  if valid_604786 != nil:
    section.add "X-Amz-Content-Sha256", valid_604786
  var valid_604787 = header.getOrDefault("X-Amz-Algorithm")
  valid_604787 = validateParameter(valid_604787, JString, required = false,
                                 default = nil)
  if valid_604787 != nil:
    section.add "X-Amz-Algorithm", valid_604787
  var valid_604788 = header.getOrDefault("X-Amz-Signature")
  valid_604788 = validateParameter(valid_604788, JString, required = false,
                                 default = nil)
  if valid_604788 != nil:
    section.add "X-Amz-Signature", valid_604788
  var valid_604789 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604789 = validateParameter(valid_604789, JString, required = false,
                                 default = nil)
  if valid_604789 != nil:
    section.add "X-Amz-SignedHeaders", valid_604789
  var valid_604790 = header.getOrDefault("X-Amz-Credential")
  valid_604790 = validateParameter(valid_604790, JString, required = false,
                                 default = nil)
  if valid_604790 != nil:
    section.add "X-Amz-Credential", valid_604790
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604792: Call_UpdateMaintenanceWindow_604780; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates an existing maintenance window. Only specified parameters are modified.</p> <note> <p>The value you specify for <code>Duration</code> determines the specific end time for the maintenance window based on the time it begins. No maintenance window tasks are permitted to start after the resulting endtime minus the number of hours you specify for <code>Cutoff</code>. For example, if the maintenance window starts at 3 PM, the duration is three hours, and the value you specify for <code>Cutoff</code> is one hour, no maintenance window tasks can start after 5 PM.</p> </note>
  ## 
  let valid = call_604792.validator(path, query, header, formData, body)
  let scheme = call_604792.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604792.url(scheme.get, call_604792.host, call_604792.base,
                         call_604792.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604792, url, valid)

proc call*(call_604793: Call_UpdateMaintenanceWindow_604780; body: JsonNode): Recallable =
  ## updateMaintenanceWindow
  ## <p>Updates an existing maintenance window. Only specified parameters are modified.</p> <note> <p>The value you specify for <code>Duration</code> determines the specific end time for the maintenance window based on the time it begins. No maintenance window tasks are permitted to start after the resulting endtime minus the number of hours you specify for <code>Cutoff</code>. For example, if the maintenance window starts at 3 PM, the duration is three hours, and the value you specify for <code>Cutoff</code> is one hour, no maintenance window tasks can start after 5 PM.</p> </note>
  ##   body: JObject (required)
  var body_604794 = newJObject()
  if body != nil:
    body_604794 = body
  result = call_604793.call(nil, nil, nil, nil, body_604794)

var updateMaintenanceWindow* = Call_UpdateMaintenanceWindow_604780(
    name: "updateMaintenanceWindow", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.UpdateMaintenanceWindow",
    validator: validate_UpdateMaintenanceWindow_604781, base: "/",
    url: url_UpdateMaintenanceWindow_604782, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateMaintenanceWindowTarget_604795 = ref object of OpenApiRestCall_602466
proc url_UpdateMaintenanceWindowTarget_604797(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateMaintenanceWindowTarget_604796(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Modifies the target of an existing maintenance window. You can change the following:</p> <ul> <li> <p>Name</p> </li> <li> <p>Description</p> </li> <li> <p>Owner</p> </li> <li> <p>IDs for an ID target</p> </li> <li> <p>Tags for a Tag target</p> </li> <li> <p>From any supported tag type to another. The three supported tag types are ID target, Tag target, and resource group. For more information, see <a>Target</a>.</p> </li> </ul> <note> <p>If a parameter is null, then the corresponding field is not modified.</p> </note>
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
  var valid_604798 = header.getOrDefault("X-Amz-Date")
  valid_604798 = validateParameter(valid_604798, JString, required = false,
                                 default = nil)
  if valid_604798 != nil:
    section.add "X-Amz-Date", valid_604798
  var valid_604799 = header.getOrDefault("X-Amz-Security-Token")
  valid_604799 = validateParameter(valid_604799, JString, required = false,
                                 default = nil)
  if valid_604799 != nil:
    section.add "X-Amz-Security-Token", valid_604799
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604800 = header.getOrDefault("X-Amz-Target")
  valid_604800 = validateParameter(valid_604800, JString, required = true, default = newJString(
      "AmazonSSM.UpdateMaintenanceWindowTarget"))
  if valid_604800 != nil:
    section.add "X-Amz-Target", valid_604800
  var valid_604801 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604801 = validateParameter(valid_604801, JString, required = false,
                                 default = nil)
  if valid_604801 != nil:
    section.add "X-Amz-Content-Sha256", valid_604801
  var valid_604802 = header.getOrDefault("X-Amz-Algorithm")
  valid_604802 = validateParameter(valid_604802, JString, required = false,
                                 default = nil)
  if valid_604802 != nil:
    section.add "X-Amz-Algorithm", valid_604802
  var valid_604803 = header.getOrDefault("X-Amz-Signature")
  valid_604803 = validateParameter(valid_604803, JString, required = false,
                                 default = nil)
  if valid_604803 != nil:
    section.add "X-Amz-Signature", valid_604803
  var valid_604804 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604804 = validateParameter(valid_604804, JString, required = false,
                                 default = nil)
  if valid_604804 != nil:
    section.add "X-Amz-SignedHeaders", valid_604804
  var valid_604805 = header.getOrDefault("X-Amz-Credential")
  valid_604805 = validateParameter(valid_604805, JString, required = false,
                                 default = nil)
  if valid_604805 != nil:
    section.add "X-Amz-Credential", valid_604805
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604807: Call_UpdateMaintenanceWindowTarget_604795; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Modifies the target of an existing maintenance window. You can change the following:</p> <ul> <li> <p>Name</p> </li> <li> <p>Description</p> </li> <li> <p>Owner</p> </li> <li> <p>IDs for an ID target</p> </li> <li> <p>Tags for a Tag target</p> </li> <li> <p>From any supported tag type to another. The three supported tag types are ID target, Tag target, and resource group. For more information, see <a>Target</a>.</p> </li> </ul> <note> <p>If a parameter is null, then the corresponding field is not modified.</p> </note>
  ## 
  let valid = call_604807.validator(path, query, header, formData, body)
  let scheme = call_604807.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604807.url(scheme.get, call_604807.host, call_604807.base,
                         call_604807.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604807, url, valid)

proc call*(call_604808: Call_UpdateMaintenanceWindowTarget_604795; body: JsonNode): Recallable =
  ## updateMaintenanceWindowTarget
  ## <p>Modifies the target of an existing maintenance window. You can change the following:</p> <ul> <li> <p>Name</p> </li> <li> <p>Description</p> </li> <li> <p>Owner</p> </li> <li> <p>IDs for an ID target</p> </li> <li> <p>Tags for a Tag target</p> </li> <li> <p>From any supported tag type to another. The three supported tag types are ID target, Tag target, and resource group. For more information, see <a>Target</a>.</p> </li> </ul> <note> <p>If a parameter is null, then the corresponding field is not modified.</p> </note>
  ##   body: JObject (required)
  var body_604809 = newJObject()
  if body != nil:
    body_604809 = body
  result = call_604808.call(nil, nil, nil, nil, body_604809)

var updateMaintenanceWindowTarget* = Call_UpdateMaintenanceWindowTarget_604795(
    name: "updateMaintenanceWindowTarget", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.UpdateMaintenanceWindowTarget",
    validator: validate_UpdateMaintenanceWindowTarget_604796, base: "/",
    url: url_UpdateMaintenanceWindowTarget_604797,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateMaintenanceWindowTask_604810 = ref object of OpenApiRestCall_602466
proc url_UpdateMaintenanceWindowTask_604812(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateMaintenanceWindowTask_604811(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Modifies a task assigned to a maintenance window. You can't change the task type, but you can change the following values:</p> <ul> <li> <p>TaskARN. For example, you can change a RUN_COMMAND task from AWS-RunPowerShellScript to AWS-RunShellScript.</p> </li> <li> <p>ServiceRoleArn</p> </li> <li> <p>TaskInvocationParameters</p> </li> <li> <p>Priority</p> </li> <li> <p>MaxConcurrency</p> </li> <li> <p>MaxErrors</p> </li> </ul> <p>If a parameter is null, then the corresponding field is not modified. Also, if you set Replace to true, then all fields required by the <a>RegisterTaskWithMaintenanceWindow</a> action are required for this request. Optional fields that aren't specified are set to null.</p>
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
  var valid_604813 = header.getOrDefault("X-Amz-Date")
  valid_604813 = validateParameter(valid_604813, JString, required = false,
                                 default = nil)
  if valid_604813 != nil:
    section.add "X-Amz-Date", valid_604813
  var valid_604814 = header.getOrDefault("X-Amz-Security-Token")
  valid_604814 = validateParameter(valid_604814, JString, required = false,
                                 default = nil)
  if valid_604814 != nil:
    section.add "X-Amz-Security-Token", valid_604814
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604815 = header.getOrDefault("X-Amz-Target")
  valid_604815 = validateParameter(valid_604815, JString, required = true, default = newJString(
      "AmazonSSM.UpdateMaintenanceWindowTask"))
  if valid_604815 != nil:
    section.add "X-Amz-Target", valid_604815
  var valid_604816 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604816 = validateParameter(valid_604816, JString, required = false,
                                 default = nil)
  if valid_604816 != nil:
    section.add "X-Amz-Content-Sha256", valid_604816
  var valid_604817 = header.getOrDefault("X-Amz-Algorithm")
  valid_604817 = validateParameter(valid_604817, JString, required = false,
                                 default = nil)
  if valid_604817 != nil:
    section.add "X-Amz-Algorithm", valid_604817
  var valid_604818 = header.getOrDefault("X-Amz-Signature")
  valid_604818 = validateParameter(valid_604818, JString, required = false,
                                 default = nil)
  if valid_604818 != nil:
    section.add "X-Amz-Signature", valid_604818
  var valid_604819 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604819 = validateParameter(valid_604819, JString, required = false,
                                 default = nil)
  if valid_604819 != nil:
    section.add "X-Amz-SignedHeaders", valid_604819
  var valid_604820 = header.getOrDefault("X-Amz-Credential")
  valid_604820 = validateParameter(valid_604820, JString, required = false,
                                 default = nil)
  if valid_604820 != nil:
    section.add "X-Amz-Credential", valid_604820
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604822: Call_UpdateMaintenanceWindowTask_604810; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Modifies a task assigned to a maintenance window. You can't change the task type, but you can change the following values:</p> <ul> <li> <p>TaskARN. For example, you can change a RUN_COMMAND task from AWS-RunPowerShellScript to AWS-RunShellScript.</p> </li> <li> <p>ServiceRoleArn</p> </li> <li> <p>TaskInvocationParameters</p> </li> <li> <p>Priority</p> </li> <li> <p>MaxConcurrency</p> </li> <li> <p>MaxErrors</p> </li> </ul> <p>If a parameter is null, then the corresponding field is not modified. Also, if you set Replace to true, then all fields required by the <a>RegisterTaskWithMaintenanceWindow</a> action are required for this request. Optional fields that aren't specified are set to null.</p>
  ## 
  let valid = call_604822.validator(path, query, header, formData, body)
  let scheme = call_604822.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604822.url(scheme.get, call_604822.host, call_604822.base,
                         call_604822.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604822, url, valid)

proc call*(call_604823: Call_UpdateMaintenanceWindowTask_604810; body: JsonNode): Recallable =
  ## updateMaintenanceWindowTask
  ## <p>Modifies a task assigned to a maintenance window. You can't change the task type, but you can change the following values:</p> <ul> <li> <p>TaskARN. For example, you can change a RUN_COMMAND task from AWS-RunPowerShellScript to AWS-RunShellScript.</p> </li> <li> <p>ServiceRoleArn</p> </li> <li> <p>TaskInvocationParameters</p> </li> <li> <p>Priority</p> </li> <li> <p>MaxConcurrency</p> </li> <li> <p>MaxErrors</p> </li> </ul> <p>If a parameter is null, then the corresponding field is not modified. Also, if you set Replace to true, then all fields required by the <a>RegisterTaskWithMaintenanceWindow</a> action are required for this request. Optional fields that aren't specified are set to null.</p>
  ##   body: JObject (required)
  var body_604824 = newJObject()
  if body != nil:
    body_604824 = body
  result = call_604823.call(nil, nil, nil, nil, body_604824)

var updateMaintenanceWindowTask* = Call_UpdateMaintenanceWindowTask_604810(
    name: "updateMaintenanceWindowTask", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.UpdateMaintenanceWindowTask",
    validator: validate_UpdateMaintenanceWindowTask_604811, base: "/",
    url: url_UpdateMaintenanceWindowTask_604812,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateManagedInstanceRole_604825 = ref object of OpenApiRestCall_602466
proc url_UpdateManagedInstanceRole_604827(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateManagedInstanceRole_604826(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Assigns or changes an Amazon Identity and Access Management (IAM) role for the managed instance.
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
  var valid_604828 = header.getOrDefault("X-Amz-Date")
  valid_604828 = validateParameter(valid_604828, JString, required = false,
                                 default = nil)
  if valid_604828 != nil:
    section.add "X-Amz-Date", valid_604828
  var valid_604829 = header.getOrDefault("X-Amz-Security-Token")
  valid_604829 = validateParameter(valid_604829, JString, required = false,
                                 default = nil)
  if valid_604829 != nil:
    section.add "X-Amz-Security-Token", valid_604829
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604830 = header.getOrDefault("X-Amz-Target")
  valid_604830 = validateParameter(valid_604830, JString, required = true, default = newJString(
      "AmazonSSM.UpdateManagedInstanceRole"))
  if valid_604830 != nil:
    section.add "X-Amz-Target", valid_604830
  var valid_604831 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604831 = validateParameter(valid_604831, JString, required = false,
                                 default = nil)
  if valid_604831 != nil:
    section.add "X-Amz-Content-Sha256", valid_604831
  var valid_604832 = header.getOrDefault("X-Amz-Algorithm")
  valid_604832 = validateParameter(valid_604832, JString, required = false,
                                 default = nil)
  if valid_604832 != nil:
    section.add "X-Amz-Algorithm", valid_604832
  var valid_604833 = header.getOrDefault("X-Amz-Signature")
  valid_604833 = validateParameter(valid_604833, JString, required = false,
                                 default = nil)
  if valid_604833 != nil:
    section.add "X-Amz-Signature", valid_604833
  var valid_604834 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604834 = validateParameter(valid_604834, JString, required = false,
                                 default = nil)
  if valid_604834 != nil:
    section.add "X-Amz-SignedHeaders", valid_604834
  var valid_604835 = header.getOrDefault("X-Amz-Credential")
  valid_604835 = validateParameter(valid_604835, JString, required = false,
                                 default = nil)
  if valid_604835 != nil:
    section.add "X-Amz-Credential", valid_604835
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604837: Call_UpdateManagedInstanceRole_604825; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Assigns or changes an Amazon Identity and Access Management (IAM) role for the managed instance.
  ## 
  let valid = call_604837.validator(path, query, header, formData, body)
  let scheme = call_604837.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604837.url(scheme.get, call_604837.host, call_604837.base,
                         call_604837.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604837, url, valid)

proc call*(call_604838: Call_UpdateManagedInstanceRole_604825; body: JsonNode): Recallable =
  ## updateManagedInstanceRole
  ## Assigns or changes an Amazon Identity and Access Management (IAM) role for the managed instance.
  ##   body: JObject (required)
  var body_604839 = newJObject()
  if body != nil:
    body_604839 = body
  result = call_604838.call(nil, nil, nil, nil, body_604839)

var updateManagedInstanceRole* = Call_UpdateManagedInstanceRole_604825(
    name: "updateManagedInstanceRole", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.UpdateManagedInstanceRole",
    validator: validate_UpdateManagedInstanceRole_604826, base: "/",
    url: url_UpdateManagedInstanceRole_604827,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateOpsItem_604840 = ref object of OpenApiRestCall_602466
proc url_UpdateOpsItem_604842(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateOpsItem_604841(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Edit or change an OpsItem. You must have permission in AWS Identity and Access Management (IAM) to update an OpsItem. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter-getting-started.html">Getting Started with OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>.</p> <p>Operations engineers and IT professionals use OpsCenter to view, investigate, and remediate operational issues impacting the performance and health of their AWS resources. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter.html">AWS Systems Manager OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>. </p>
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
  var valid_604843 = header.getOrDefault("X-Amz-Date")
  valid_604843 = validateParameter(valid_604843, JString, required = false,
                                 default = nil)
  if valid_604843 != nil:
    section.add "X-Amz-Date", valid_604843
  var valid_604844 = header.getOrDefault("X-Amz-Security-Token")
  valid_604844 = validateParameter(valid_604844, JString, required = false,
                                 default = nil)
  if valid_604844 != nil:
    section.add "X-Amz-Security-Token", valid_604844
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604845 = header.getOrDefault("X-Amz-Target")
  valid_604845 = validateParameter(valid_604845, JString, required = true, default = newJString(
      "AmazonSSM.UpdateOpsItem"))
  if valid_604845 != nil:
    section.add "X-Amz-Target", valid_604845
  var valid_604846 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604846 = validateParameter(valid_604846, JString, required = false,
                                 default = nil)
  if valid_604846 != nil:
    section.add "X-Amz-Content-Sha256", valid_604846
  var valid_604847 = header.getOrDefault("X-Amz-Algorithm")
  valid_604847 = validateParameter(valid_604847, JString, required = false,
                                 default = nil)
  if valid_604847 != nil:
    section.add "X-Amz-Algorithm", valid_604847
  var valid_604848 = header.getOrDefault("X-Amz-Signature")
  valid_604848 = validateParameter(valid_604848, JString, required = false,
                                 default = nil)
  if valid_604848 != nil:
    section.add "X-Amz-Signature", valid_604848
  var valid_604849 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604849 = validateParameter(valid_604849, JString, required = false,
                                 default = nil)
  if valid_604849 != nil:
    section.add "X-Amz-SignedHeaders", valid_604849
  var valid_604850 = header.getOrDefault("X-Amz-Credential")
  valid_604850 = validateParameter(valid_604850, JString, required = false,
                                 default = nil)
  if valid_604850 != nil:
    section.add "X-Amz-Credential", valid_604850
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604852: Call_UpdateOpsItem_604840; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Edit or change an OpsItem. You must have permission in AWS Identity and Access Management (IAM) to update an OpsItem. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter-getting-started.html">Getting Started with OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>.</p> <p>Operations engineers and IT professionals use OpsCenter to view, investigate, and remediate operational issues impacting the performance and health of their AWS resources. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter.html">AWS Systems Manager OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>. </p>
  ## 
  let valid = call_604852.validator(path, query, header, formData, body)
  let scheme = call_604852.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604852.url(scheme.get, call_604852.host, call_604852.base,
                         call_604852.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604852, url, valid)

proc call*(call_604853: Call_UpdateOpsItem_604840; body: JsonNode): Recallable =
  ## updateOpsItem
  ## <p>Edit or change an OpsItem. You must have permission in AWS Identity and Access Management (IAM) to update an OpsItem. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter-getting-started.html">Getting Started with OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>.</p> <p>Operations engineers and IT professionals use OpsCenter to view, investigate, and remediate operational issues impacting the performance and health of their AWS resources. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter.html">AWS Systems Manager OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>. </p>
  ##   body: JObject (required)
  var body_604854 = newJObject()
  if body != nil:
    body_604854 = body
  result = call_604853.call(nil, nil, nil, nil, body_604854)

var updateOpsItem* = Call_UpdateOpsItem_604840(name: "updateOpsItem",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.UpdateOpsItem",
    validator: validate_UpdateOpsItem_604841, base: "/", url: url_UpdateOpsItem_604842,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdatePatchBaseline_604855 = ref object of OpenApiRestCall_602466
proc url_UpdatePatchBaseline_604857(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdatePatchBaseline_604856(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p>Modifies an existing patch baseline. Fields not specified in the request are left unchanged.</p> <note> <p>For information about valid key and value pairs in <code>PatchFilters</code> for each supported operating system type, see <a href="http://docs.aws.amazon.com/systems-manager/latest/APIReference/API_PatchFilter.html">PatchFilter</a>.</p> </note>
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
  var valid_604858 = header.getOrDefault("X-Amz-Date")
  valid_604858 = validateParameter(valid_604858, JString, required = false,
                                 default = nil)
  if valid_604858 != nil:
    section.add "X-Amz-Date", valid_604858
  var valid_604859 = header.getOrDefault("X-Amz-Security-Token")
  valid_604859 = validateParameter(valid_604859, JString, required = false,
                                 default = nil)
  if valid_604859 != nil:
    section.add "X-Amz-Security-Token", valid_604859
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604860 = header.getOrDefault("X-Amz-Target")
  valid_604860 = validateParameter(valid_604860, JString, required = true, default = newJString(
      "AmazonSSM.UpdatePatchBaseline"))
  if valid_604860 != nil:
    section.add "X-Amz-Target", valid_604860
  var valid_604861 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604861 = validateParameter(valid_604861, JString, required = false,
                                 default = nil)
  if valid_604861 != nil:
    section.add "X-Amz-Content-Sha256", valid_604861
  var valid_604862 = header.getOrDefault("X-Amz-Algorithm")
  valid_604862 = validateParameter(valid_604862, JString, required = false,
                                 default = nil)
  if valid_604862 != nil:
    section.add "X-Amz-Algorithm", valid_604862
  var valid_604863 = header.getOrDefault("X-Amz-Signature")
  valid_604863 = validateParameter(valid_604863, JString, required = false,
                                 default = nil)
  if valid_604863 != nil:
    section.add "X-Amz-Signature", valid_604863
  var valid_604864 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604864 = validateParameter(valid_604864, JString, required = false,
                                 default = nil)
  if valid_604864 != nil:
    section.add "X-Amz-SignedHeaders", valid_604864
  var valid_604865 = header.getOrDefault("X-Amz-Credential")
  valid_604865 = validateParameter(valid_604865, JString, required = false,
                                 default = nil)
  if valid_604865 != nil:
    section.add "X-Amz-Credential", valid_604865
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604867: Call_UpdatePatchBaseline_604855; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Modifies an existing patch baseline. Fields not specified in the request are left unchanged.</p> <note> <p>For information about valid key and value pairs in <code>PatchFilters</code> for each supported operating system type, see <a href="http://docs.aws.amazon.com/systems-manager/latest/APIReference/API_PatchFilter.html">PatchFilter</a>.</p> </note>
  ## 
  let valid = call_604867.validator(path, query, header, formData, body)
  let scheme = call_604867.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604867.url(scheme.get, call_604867.host, call_604867.base,
                         call_604867.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604867, url, valid)

proc call*(call_604868: Call_UpdatePatchBaseline_604855; body: JsonNode): Recallable =
  ## updatePatchBaseline
  ## <p>Modifies an existing patch baseline. Fields not specified in the request are left unchanged.</p> <note> <p>For information about valid key and value pairs in <code>PatchFilters</code> for each supported operating system type, see <a href="http://docs.aws.amazon.com/systems-manager/latest/APIReference/API_PatchFilter.html">PatchFilter</a>.</p> </note>
  ##   body: JObject (required)
  var body_604869 = newJObject()
  if body != nil:
    body_604869 = body
  result = call_604868.call(nil, nil, nil, nil, body_604869)

var updatePatchBaseline* = Call_UpdatePatchBaseline_604855(
    name: "updatePatchBaseline", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.UpdatePatchBaseline",
    validator: validate_UpdatePatchBaseline_604856, base: "/",
    url: url_UpdatePatchBaseline_604857, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateServiceSetting_604870 = ref object of OpenApiRestCall_602466
proc url_UpdateServiceSetting_604872(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateServiceSetting_604871(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p> <code>ServiceSetting</code> is an account-level setting for an AWS service. This setting defines how a user interacts with or uses a service or a feature of a service. For example, if an AWS service charges money to the account based on feature or service usage, then the AWS service team might create a default setting of "false". This means the user can't use this feature unless they change the setting to "true" and intentionally opt in for a paid feature.</p> <p>Services map a <code>SettingId</code> object to a setting value. AWS services teams define the default value for a <code>SettingId</code>. You can't create a new <code>SettingId</code>, but you can overwrite the default value if you have the <code>ssm:UpdateServiceSetting</code> permission for the setting. Use the <a>GetServiceSetting</a> API action to view the current value. Or, use the <a>ResetServiceSetting</a> to change the value back to the original value defined by the AWS service team.</p> <p>Update the service setting for the account. </p>
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
  var valid_604873 = header.getOrDefault("X-Amz-Date")
  valid_604873 = validateParameter(valid_604873, JString, required = false,
                                 default = nil)
  if valid_604873 != nil:
    section.add "X-Amz-Date", valid_604873
  var valid_604874 = header.getOrDefault("X-Amz-Security-Token")
  valid_604874 = validateParameter(valid_604874, JString, required = false,
                                 default = nil)
  if valid_604874 != nil:
    section.add "X-Amz-Security-Token", valid_604874
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604875 = header.getOrDefault("X-Amz-Target")
  valid_604875 = validateParameter(valid_604875, JString, required = true, default = newJString(
      "AmazonSSM.UpdateServiceSetting"))
  if valid_604875 != nil:
    section.add "X-Amz-Target", valid_604875
  var valid_604876 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604876 = validateParameter(valid_604876, JString, required = false,
                                 default = nil)
  if valid_604876 != nil:
    section.add "X-Amz-Content-Sha256", valid_604876
  var valid_604877 = header.getOrDefault("X-Amz-Algorithm")
  valid_604877 = validateParameter(valid_604877, JString, required = false,
                                 default = nil)
  if valid_604877 != nil:
    section.add "X-Amz-Algorithm", valid_604877
  var valid_604878 = header.getOrDefault("X-Amz-Signature")
  valid_604878 = validateParameter(valid_604878, JString, required = false,
                                 default = nil)
  if valid_604878 != nil:
    section.add "X-Amz-Signature", valid_604878
  var valid_604879 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604879 = validateParameter(valid_604879, JString, required = false,
                                 default = nil)
  if valid_604879 != nil:
    section.add "X-Amz-SignedHeaders", valid_604879
  var valid_604880 = header.getOrDefault("X-Amz-Credential")
  valid_604880 = validateParameter(valid_604880, JString, required = false,
                                 default = nil)
  if valid_604880 != nil:
    section.add "X-Amz-Credential", valid_604880
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604882: Call_UpdateServiceSetting_604870; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> <code>ServiceSetting</code> is an account-level setting for an AWS service. This setting defines how a user interacts with or uses a service or a feature of a service. For example, if an AWS service charges money to the account based on feature or service usage, then the AWS service team might create a default setting of "false". This means the user can't use this feature unless they change the setting to "true" and intentionally opt in for a paid feature.</p> <p>Services map a <code>SettingId</code> object to a setting value. AWS services teams define the default value for a <code>SettingId</code>. You can't create a new <code>SettingId</code>, but you can overwrite the default value if you have the <code>ssm:UpdateServiceSetting</code> permission for the setting. Use the <a>GetServiceSetting</a> API action to view the current value. Or, use the <a>ResetServiceSetting</a> to change the value back to the original value defined by the AWS service team.</p> <p>Update the service setting for the account. </p>
  ## 
  let valid = call_604882.validator(path, query, header, formData, body)
  let scheme = call_604882.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604882.url(scheme.get, call_604882.host, call_604882.base,
                         call_604882.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604882, url, valid)

proc call*(call_604883: Call_UpdateServiceSetting_604870; body: JsonNode): Recallable =
  ## updateServiceSetting
  ## <p> <code>ServiceSetting</code> is an account-level setting for an AWS service. This setting defines how a user interacts with or uses a service or a feature of a service. For example, if an AWS service charges money to the account based on feature or service usage, then the AWS service team might create a default setting of "false". This means the user can't use this feature unless they change the setting to "true" and intentionally opt in for a paid feature.</p> <p>Services map a <code>SettingId</code> object to a setting value. AWS services teams define the default value for a <code>SettingId</code>. You can't create a new <code>SettingId</code>, but you can overwrite the default value if you have the <code>ssm:UpdateServiceSetting</code> permission for the setting. Use the <a>GetServiceSetting</a> API action to view the current value. Or, use the <a>ResetServiceSetting</a> to change the value back to the original value defined by the AWS service team.</p> <p>Update the service setting for the account. </p>
  ##   body: JObject (required)
  var body_604884 = newJObject()
  if body != nil:
    body_604884 = body
  result = call_604883.call(nil, nil, nil, nil, body_604884)

var updateServiceSetting* = Call_UpdateServiceSetting_604870(
    name: "updateServiceSetting", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.UpdateServiceSetting",
    validator: validate_UpdateServiceSetting_604871, base: "/",
    url: url_UpdateServiceSetting_604872, schemes: {Scheme.Https, Scheme.Http})
export
  rest

proc sign(recall: var Recallable; query: JsonNode; algo: SigningAlgo = SHA256) =
  let
    date = makeDateTime()
    access = os.getEnv("AWS_ACCESS_KEY_ID", "")
    secret = os.getEnv("AWS_SECRET_ACCESS_KEY", "")
    region = os.getEnv("AWS_REGION", "")
  assert secret != "", "need secret key in env"
  assert access != "", "need access key in env"
  assert region != "", "need region in env"
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
  let
    algo = SHA256
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

method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, input.getOrDefault("body").getStr)
  result.sign(input.getOrDefault("query"), SHA256)
