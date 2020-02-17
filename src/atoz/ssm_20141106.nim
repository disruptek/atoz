
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

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

  OpenApiRestCall_610658 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_610658](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_610658): Option[Scheme] {.used.} =
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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_AddTagsToResource_610996 = ref object of OpenApiRestCall_610658
proc url_AddTagsToResource_610998(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AddTagsToResource_610997(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611123 = header.getOrDefault("X-Amz-Target")
  valid_611123 = validateParameter(valid_611123, JString, required = true, default = newJString(
      "AmazonSSM.AddTagsToResource"))
  if valid_611123 != nil:
    section.add "X-Amz-Target", valid_611123
  var valid_611124 = header.getOrDefault("X-Amz-Signature")
  valid_611124 = validateParameter(valid_611124, JString, required = false,
                                 default = nil)
  if valid_611124 != nil:
    section.add "X-Amz-Signature", valid_611124
  var valid_611125 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611125 = validateParameter(valid_611125, JString, required = false,
                                 default = nil)
  if valid_611125 != nil:
    section.add "X-Amz-Content-Sha256", valid_611125
  var valid_611126 = header.getOrDefault("X-Amz-Date")
  valid_611126 = validateParameter(valid_611126, JString, required = false,
                                 default = nil)
  if valid_611126 != nil:
    section.add "X-Amz-Date", valid_611126
  var valid_611127 = header.getOrDefault("X-Amz-Credential")
  valid_611127 = validateParameter(valid_611127, JString, required = false,
                                 default = nil)
  if valid_611127 != nil:
    section.add "X-Amz-Credential", valid_611127
  var valid_611128 = header.getOrDefault("X-Amz-Security-Token")
  valid_611128 = validateParameter(valid_611128, JString, required = false,
                                 default = nil)
  if valid_611128 != nil:
    section.add "X-Amz-Security-Token", valid_611128
  var valid_611129 = header.getOrDefault("X-Amz-Algorithm")
  valid_611129 = validateParameter(valid_611129, JString, required = false,
                                 default = nil)
  if valid_611129 != nil:
    section.add "X-Amz-Algorithm", valid_611129
  var valid_611130 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611130 = validateParameter(valid_611130, JString, required = false,
                                 default = nil)
  if valid_611130 != nil:
    section.add "X-Amz-SignedHeaders", valid_611130
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611154: Call_AddTagsToResource_610996; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds or overwrites one or more tags for the specified resource. Tags are metadata that you can assign to your documents, managed instances, maintenance windows, Parameter Store parameters, and patch baselines. Tags enable you to categorize your resources in different ways, for example, by purpose, owner, or environment. Each tag consists of a key and an optional value, both of which you define. For example, you could define a set of tags for your account's managed instances that helps you track each instance's owner and stack level. For example: Key=Owner and Value=DbAdmin, SysAdmin, or Dev. Or Key=Stack and Value=Production, Pre-Production, or Test.</p> <p>Each resource can have a maximum of 50 tags. </p> <p>We recommend that you devise a set of tag keys that meets your needs for each resource type. Using a consistent set of tag keys makes it easier for you to manage your resources. You can search and filter the resources based on the tags you add. Tags don't have any semantic meaning to Amazon EC2 and are interpreted strictly as a string of characters. </p> <p>For more information about tags, see <a href="http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/Using_Tags.html">Tagging Your Amazon EC2 Resources</a> in the <i>Amazon EC2 User Guide</i>.</p>
  ## 
  let valid = call_611154.validator(path, query, header, formData, body)
  let scheme = call_611154.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611154.url(scheme.get, call_611154.host, call_611154.base,
                         call_611154.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611154, url, valid)

proc call*(call_611225: Call_AddTagsToResource_610996; body: JsonNode): Recallable =
  ## addTagsToResource
  ## <p>Adds or overwrites one or more tags for the specified resource. Tags are metadata that you can assign to your documents, managed instances, maintenance windows, Parameter Store parameters, and patch baselines. Tags enable you to categorize your resources in different ways, for example, by purpose, owner, or environment. Each tag consists of a key and an optional value, both of which you define. For example, you could define a set of tags for your account's managed instances that helps you track each instance's owner and stack level. For example: Key=Owner and Value=DbAdmin, SysAdmin, or Dev. Or Key=Stack and Value=Production, Pre-Production, or Test.</p> <p>Each resource can have a maximum of 50 tags. </p> <p>We recommend that you devise a set of tag keys that meets your needs for each resource type. Using a consistent set of tag keys makes it easier for you to manage your resources. You can search and filter the resources based on the tags you add. Tags don't have any semantic meaning to Amazon EC2 and are interpreted strictly as a string of characters. </p> <p>For more information about tags, see <a href="http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/Using_Tags.html">Tagging Your Amazon EC2 Resources</a> in the <i>Amazon EC2 User Guide</i>.</p>
  ##   body: JObject (required)
  var body_611226 = newJObject()
  if body != nil:
    body_611226 = body
  result = call_611225.call(nil, nil, nil, nil, body_611226)

var addTagsToResource* = Call_AddTagsToResource_610996(name: "addTagsToResource",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.AddTagsToResource",
    validator: validate_AddTagsToResource_610997, base: "/",
    url: url_AddTagsToResource_610998, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CancelCommand_611265 = ref object of OpenApiRestCall_610658
proc url_CancelCommand_611267(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CancelCommand_611266(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611268 = header.getOrDefault("X-Amz-Target")
  valid_611268 = validateParameter(valid_611268, JString, required = true, default = newJString(
      "AmazonSSM.CancelCommand"))
  if valid_611268 != nil:
    section.add "X-Amz-Target", valid_611268
  var valid_611269 = header.getOrDefault("X-Amz-Signature")
  valid_611269 = validateParameter(valid_611269, JString, required = false,
                                 default = nil)
  if valid_611269 != nil:
    section.add "X-Amz-Signature", valid_611269
  var valid_611270 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611270 = validateParameter(valid_611270, JString, required = false,
                                 default = nil)
  if valid_611270 != nil:
    section.add "X-Amz-Content-Sha256", valid_611270
  var valid_611271 = header.getOrDefault("X-Amz-Date")
  valid_611271 = validateParameter(valid_611271, JString, required = false,
                                 default = nil)
  if valid_611271 != nil:
    section.add "X-Amz-Date", valid_611271
  var valid_611272 = header.getOrDefault("X-Amz-Credential")
  valid_611272 = validateParameter(valid_611272, JString, required = false,
                                 default = nil)
  if valid_611272 != nil:
    section.add "X-Amz-Credential", valid_611272
  var valid_611273 = header.getOrDefault("X-Amz-Security-Token")
  valid_611273 = validateParameter(valid_611273, JString, required = false,
                                 default = nil)
  if valid_611273 != nil:
    section.add "X-Amz-Security-Token", valid_611273
  var valid_611274 = header.getOrDefault("X-Amz-Algorithm")
  valid_611274 = validateParameter(valid_611274, JString, required = false,
                                 default = nil)
  if valid_611274 != nil:
    section.add "X-Amz-Algorithm", valid_611274
  var valid_611275 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611275 = validateParameter(valid_611275, JString, required = false,
                                 default = nil)
  if valid_611275 != nil:
    section.add "X-Amz-SignedHeaders", valid_611275
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611277: Call_CancelCommand_611265; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Attempts to cancel the command specified by the Command ID. There is no guarantee that the command will be terminated and the underlying process stopped.
  ## 
  let valid = call_611277.validator(path, query, header, formData, body)
  let scheme = call_611277.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611277.url(scheme.get, call_611277.host, call_611277.base,
                         call_611277.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611277, url, valid)

proc call*(call_611278: Call_CancelCommand_611265; body: JsonNode): Recallable =
  ## cancelCommand
  ## Attempts to cancel the command specified by the Command ID. There is no guarantee that the command will be terminated and the underlying process stopped.
  ##   body: JObject (required)
  var body_611279 = newJObject()
  if body != nil:
    body_611279 = body
  result = call_611278.call(nil, nil, nil, nil, body_611279)

var cancelCommand* = Call_CancelCommand_611265(name: "cancelCommand",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.CancelCommand",
    validator: validate_CancelCommand_611266, base: "/", url: url_CancelCommand_611267,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CancelMaintenanceWindowExecution_611280 = ref object of OpenApiRestCall_610658
proc url_CancelMaintenanceWindowExecution_611282(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CancelMaintenanceWindowExecution_611281(path: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611283 = header.getOrDefault("X-Amz-Target")
  valid_611283 = validateParameter(valid_611283, JString, required = true, default = newJString(
      "AmazonSSM.CancelMaintenanceWindowExecution"))
  if valid_611283 != nil:
    section.add "X-Amz-Target", valid_611283
  var valid_611284 = header.getOrDefault("X-Amz-Signature")
  valid_611284 = validateParameter(valid_611284, JString, required = false,
                                 default = nil)
  if valid_611284 != nil:
    section.add "X-Amz-Signature", valid_611284
  var valid_611285 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611285 = validateParameter(valid_611285, JString, required = false,
                                 default = nil)
  if valid_611285 != nil:
    section.add "X-Amz-Content-Sha256", valid_611285
  var valid_611286 = header.getOrDefault("X-Amz-Date")
  valid_611286 = validateParameter(valid_611286, JString, required = false,
                                 default = nil)
  if valid_611286 != nil:
    section.add "X-Amz-Date", valid_611286
  var valid_611287 = header.getOrDefault("X-Amz-Credential")
  valid_611287 = validateParameter(valid_611287, JString, required = false,
                                 default = nil)
  if valid_611287 != nil:
    section.add "X-Amz-Credential", valid_611287
  var valid_611288 = header.getOrDefault("X-Amz-Security-Token")
  valid_611288 = validateParameter(valid_611288, JString, required = false,
                                 default = nil)
  if valid_611288 != nil:
    section.add "X-Amz-Security-Token", valid_611288
  var valid_611289 = header.getOrDefault("X-Amz-Algorithm")
  valid_611289 = validateParameter(valid_611289, JString, required = false,
                                 default = nil)
  if valid_611289 != nil:
    section.add "X-Amz-Algorithm", valid_611289
  var valid_611290 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611290 = validateParameter(valid_611290, JString, required = false,
                                 default = nil)
  if valid_611290 != nil:
    section.add "X-Amz-SignedHeaders", valid_611290
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611292: Call_CancelMaintenanceWindowExecution_611280;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Stops a maintenance window execution that is already in progress and cancels any tasks in the window that have not already starting running. (Tasks already in progress will continue to completion.)
  ## 
  let valid = call_611292.validator(path, query, header, formData, body)
  let scheme = call_611292.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611292.url(scheme.get, call_611292.host, call_611292.base,
                         call_611292.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611292, url, valid)

proc call*(call_611293: Call_CancelMaintenanceWindowExecution_611280;
          body: JsonNode): Recallable =
  ## cancelMaintenanceWindowExecution
  ## Stops a maintenance window execution that is already in progress and cancels any tasks in the window that have not already starting running. (Tasks already in progress will continue to completion.)
  ##   body: JObject (required)
  var body_611294 = newJObject()
  if body != nil:
    body_611294 = body
  result = call_611293.call(nil, nil, nil, nil, body_611294)

var cancelMaintenanceWindowExecution* = Call_CancelMaintenanceWindowExecution_611280(
    name: "cancelMaintenanceWindowExecution", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.CancelMaintenanceWindowExecution",
    validator: validate_CancelMaintenanceWindowExecution_611281, base: "/",
    url: url_CancelMaintenanceWindowExecution_611282,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateActivation_611295 = ref object of OpenApiRestCall_610658
proc url_CreateActivation_611297(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateActivation_611296(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <p>Generates an activation code and activation ID you can use to register your on-premises server or virtual machine (VM) with Systems Manager. Registering these machines with Systems Manager makes it possible to manage them using Systems Manager capabilities. You use the activation code and ID when installing SSM Agent on machines in your hybrid environment. For more information about requirements for managing on-premises instances and VMs using Systems Manager, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-managedinstances.html">Setting Up AWS Systems Manager for Hybrid Environments</a> in the <i>AWS Systems Manager User Guide</i>. </p> <note> <p>On-premises servers or VMs that are registered with Systems Manager and Amazon EC2 instances that you manage with Systems Manager are all called <i>managed instances</i>.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611298 = header.getOrDefault("X-Amz-Target")
  valid_611298 = validateParameter(valid_611298, JString, required = true, default = newJString(
      "AmazonSSM.CreateActivation"))
  if valid_611298 != nil:
    section.add "X-Amz-Target", valid_611298
  var valid_611299 = header.getOrDefault("X-Amz-Signature")
  valid_611299 = validateParameter(valid_611299, JString, required = false,
                                 default = nil)
  if valid_611299 != nil:
    section.add "X-Amz-Signature", valid_611299
  var valid_611300 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611300 = validateParameter(valid_611300, JString, required = false,
                                 default = nil)
  if valid_611300 != nil:
    section.add "X-Amz-Content-Sha256", valid_611300
  var valid_611301 = header.getOrDefault("X-Amz-Date")
  valid_611301 = validateParameter(valid_611301, JString, required = false,
                                 default = nil)
  if valid_611301 != nil:
    section.add "X-Amz-Date", valid_611301
  var valid_611302 = header.getOrDefault("X-Amz-Credential")
  valid_611302 = validateParameter(valid_611302, JString, required = false,
                                 default = nil)
  if valid_611302 != nil:
    section.add "X-Amz-Credential", valid_611302
  var valid_611303 = header.getOrDefault("X-Amz-Security-Token")
  valid_611303 = validateParameter(valid_611303, JString, required = false,
                                 default = nil)
  if valid_611303 != nil:
    section.add "X-Amz-Security-Token", valid_611303
  var valid_611304 = header.getOrDefault("X-Amz-Algorithm")
  valid_611304 = validateParameter(valid_611304, JString, required = false,
                                 default = nil)
  if valid_611304 != nil:
    section.add "X-Amz-Algorithm", valid_611304
  var valid_611305 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611305 = validateParameter(valid_611305, JString, required = false,
                                 default = nil)
  if valid_611305 != nil:
    section.add "X-Amz-SignedHeaders", valid_611305
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611307: Call_CreateActivation_611295; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Generates an activation code and activation ID you can use to register your on-premises server or virtual machine (VM) with Systems Manager. Registering these machines with Systems Manager makes it possible to manage them using Systems Manager capabilities. You use the activation code and ID when installing SSM Agent on machines in your hybrid environment. For more information about requirements for managing on-premises instances and VMs using Systems Manager, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-managedinstances.html">Setting Up AWS Systems Manager for Hybrid Environments</a> in the <i>AWS Systems Manager User Guide</i>. </p> <note> <p>On-premises servers or VMs that are registered with Systems Manager and Amazon EC2 instances that you manage with Systems Manager are all called <i>managed instances</i>.</p> </note>
  ## 
  let valid = call_611307.validator(path, query, header, formData, body)
  let scheme = call_611307.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611307.url(scheme.get, call_611307.host, call_611307.base,
                         call_611307.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611307, url, valid)

proc call*(call_611308: Call_CreateActivation_611295; body: JsonNode): Recallable =
  ## createActivation
  ## <p>Generates an activation code and activation ID you can use to register your on-premises server or virtual machine (VM) with Systems Manager. Registering these machines with Systems Manager makes it possible to manage them using Systems Manager capabilities. You use the activation code and ID when installing SSM Agent on machines in your hybrid environment. For more information about requirements for managing on-premises instances and VMs using Systems Manager, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-managedinstances.html">Setting Up AWS Systems Manager for Hybrid Environments</a> in the <i>AWS Systems Manager User Guide</i>. </p> <note> <p>On-premises servers or VMs that are registered with Systems Manager and Amazon EC2 instances that you manage with Systems Manager are all called <i>managed instances</i>.</p> </note>
  ##   body: JObject (required)
  var body_611309 = newJObject()
  if body != nil:
    body_611309 = body
  result = call_611308.call(nil, nil, nil, nil, body_611309)

var createActivation* = Call_CreateActivation_611295(name: "createActivation",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.CreateActivation",
    validator: validate_CreateActivation_611296, base: "/",
    url: url_CreateActivation_611297, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateAssociation_611310 = ref object of OpenApiRestCall_610658
proc url_CreateAssociation_611312(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateAssociation_611311(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611313 = header.getOrDefault("X-Amz-Target")
  valid_611313 = validateParameter(valid_611313, JString, required = true, default = newJString(
      "AmazonSSM.CreateAssociation"))
  if valid_611313 != nil:
    section.add "X-Amz-Target", valid_611313
  var valid_611314 = header.getOrDefault("X-Amz-Signature")
  valid_611314 = validateParameter(valid_611314, JString, required = false,
                                 default = nil)
  if valid_611314 != nil:
    section.add "X-Amz-Signature", valid_611314
  var valid_611315 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611315 = validateParameter(valid_611315, JString, required = false,
                                 default = nil)
  if valid_611315 != nil:
    section.add "X-Amz-Content-Sha256", valid_611315
  var valid_611316 = header.getOrDefault("X-Amz-Date")
  valid_611316 = validateParameter(valid_611316, JString, required = false,
                                 default = nil)
  if valid_611316 != nil:
    section.add "X-Amz-Date", valid_611316
  var valid_611317 = header.getOrDefault("X-Amz-Credential")
  valid_611317 = validateParameter(valid_611317, JString, required = false,
                                 default = nil)
  if valid_611317 != nil:
    section.add "X-Amz-Credential", valid_611317
  var valid_611318 = header.getOrDefault("X-Amz-Security-Token")
  valid_611318 = validateParameter(valid_611318, JString, required = false,
                                 default = nil)
  if valid_611318 != nil:
    section.add "X-Amz-Security-Token", valid_611318
  var valid_611319 = header.getOrDefault("X-Amz-Algorithm")
  valid_611319 = validateParameter(valid_611319, JString, required = false,
                                 default = nil)
  if valid_611319 != nil:
    section.add "X-Amz-Algorithm", valid_611319
  var valid_611320 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611320 = validateParameter(valid_611320, JString, required = false,
                                 default = nil)
  if valid_611320 != nil:
    section.add "X-Amz-SignedHeaders", valid_611320
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611322: Call_CreateAssociation_611310; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Associates the specified Systems Manager document with the specified instances or targets.</p> <p>When you associate a document with one or more instances using instance IDs or tags, SSM Agent running on the instance processes the document and configures the instance as specified.</p> <p>If you associate a document with an instance that already has an associated document, the system returns the AssociationAlreadyExists exception.</p>
  ## 
  let valid = call_611322.validator(path, query, header, formData, body)
  let scheme = call_611322.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611322.url(scheme.get, call_611322.host, call_611322.base,
                         call_611322.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611322, url, valid)

proc call*(call_611323: Call_CreateAssociation_611310; body: JsonNode): Recallable =
  ## createAssociation
  ## <p>Associates the specified Systems Manager document with the specified instances or targets.</p> <p>When you associate a document with one or more instances using instance IDs or tags, SSM Agent running on the instance processes the document and configures the instance as specified.</p> <p>If you associate a document with an instance that already has an associated document, the system returns the AssociationAlreadyExists exception.</p>
  ##   body: JObject (required)
  var body_611324 = newJObject()
  if body != nil:
    body_611324 = body
  result = call_611323.call(nil, nil, nil, nil, body_611324)

var createAssociation* = Call_CreateAssociation_611310(name: "createAssociation",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.CreateAssociation",
    validator: validate_CreateAssociation_611311, base: "/",
    url: url_CreateAssociation_611312, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateAssociationBatch_611325 = ref object of OpenApiRestCall_610658
proc url_CreateAssociationBatch_611327(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateAssociationBatch_611326(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611328 = header.getOrDefault("X-Amz-Target")
  valid_611328 = validateParameter(valid_611328, JString, required = true, default = newJString(
      "AmazonSSM.CreateAssociationBatch"))
  if valid_611328 != nil:
    section.add "X-Amz-Target", valid_611328
  var valid_611329 = header.getOrDefault("X-Amz-Signature")
  valid_611329 = validateParameter(valid_611329, JString, required = false,
                                 default = nil)
  if valid_611329 != nil:
    section.add "X-Amz-Signature", valid_611329
  var valid_611330 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611330 = validateParameter(valid_611330, JString, required = false,
                                 default = nil)
  if valid_611330 != nil:
    section.add "X-Amz-Content-Sha256", valid_611330
  var valid_611331 = header.getOrDefault("X-Amz-Date")
  valid_611331 = validateParameter(valid_611331, JString, required = false,
                                 default = nil)
  if valid_611331 != nil:
    section.add "X-Amz-Date", valid_611331
  var valid_611332 = header.getOrDefault("X-Amz-Credential")
  valid_611332 = validateParameter(valid_611332, JString, required = false,
                                 default = nil)
  if valid_611332 != nil:
    section.add "X-Amz-Credential", valid_611332
  var valid_611333 = header.getOrDefault("X-Amz-Security-Token")
  valid_611333 = validateParameter(valid_611333, JString, required = false,
                                 default = nil)
  if valid_611333 != nil:
    section.add "X-Amz-Security-Token", valid_611333
  var valid_611334 = header.getOrDefault("X-Amz-Algorithm")
  valid_611334 = validateParameter(valid_611334, JString, required = false,
                                 default = nil)
  if valid_611334 != nil:
    section.add "X-Amz-Algorithm", valid_611334
  var valid_611335 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611335 = validateParameter(valid_611335, JString, required = false,
                                 default = nil)
  if valid_611335 != nil:
    section.add "X-Amz-SignedHeaders", valid_611335
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611337: Call_CreateAssociationBatch_611325; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Associates the specified Systems Manager document with the specified instances or targets.</p> <p>When you associate a document with one or more instances using instance IDs or tags, SSM Agent running on the instance processes the document and configures the instance as specified.</p> <p>If you associate a document with an instance that already has an associated document, the system returns the AssociationAlreadyExists exception.</p>
  ## 
  let valid = call_611337.validator(path, query, header, formData, body)
  let scheme = call_611337.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611337.url(scheme.get, call_611337.host, call_611337.base,
                         call_611337.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611337, url, valid)

proc call*(call_611338: Call_CreateAssociationBatch_611325; body: JsonNode): Recallable =
  ## createAssociationBatch
  ## <p>Associates the specified Systems Manager document with the specified instances or targets.</p> <p>When you associate a document with one or more instances using instance IDs or tags, SSM Agent running on the instance processes the document and configures the instance as specified.</p> <p>If you associate a document with an instance that already has an associated document, the system returns the AssociationAlreadyExists exception.</p>
  ##   body: JObject (required)
  var body_611339 = newJObject()
  if body != nil:
    body_611339 = body
  result = call_611338.call(nil, nil, nil, nil, body_611339)

var createAssociationBatch* = Call_CreateAssociationBatch_611325(
    name: "createAssociationBatch", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.CreateAssociationBatch",
    validator: validate_CreateAssociationBatch_611326, base: "/",
    url: url_CreateAssociationBatch_611327, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDocument_611340 = ref object of OpenApiRestCall_610658
proc url_CreateDocument_611342(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateDocument_611341(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611343 = header.getOrDefault("X-Amz-Target")
  valid_611343 = validateParameter(valid_611343, JString, required = true, default = newJString(
      "AmazonSSM.CreateDocument"))
  if valid_611343 != nil:
    section.add "X-Amz-Target", valid_611343
  var valid_611344 = header.getOrDefault("X-Amz-Signature")
  valid_611344 = validateParameter(valid_611344, JString, required = false,
                                 default = nil)
  if valid_611344 != nil:
    section.add "X-Amz-Signature", valid_611344
  var valid_611345 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611345 = validateParameter(valid_611345, JString, required = false,
                                 default = nil)
  if valid_611345 != nil:
    section.add "X-Amz-Content-Sha256", valid_611345
  var valid_611346 = header.getOrDefault("X-Amz-Date")
  valid_611346 = validateParameter(valid_611346, JString, required = false,
                                 default = nil)
  if valid_611346 != nil:
    section.add "X-Amz-Date", valid_611346
  var valid_611347 = header.getOrDefault("X-Amz-Credential")
  valid_611347 = validateParameter(valid_611347, JString, required = false,
                                 default = nil)
  if valid_611347 != nil:
    section.add "X-Amz-Credential", valid_611347
  var valid_611348 = header.getOrDefault("X-Amz-Security-Token")
  valid_611348 = validateParameter(valid_611348, JString, required = false,
                                 default = nil)
  if valid_611348 != nil:
    section.add "X-Amz-Security-Token", valid_611348
  var valid_611349 = header.getOrDefault("X-Amz-Algorithm")
  valid_611349 = validateParameter(valid_611349, JString, required = false,
                                 default = nil)
  if valid_611349 != nil:
    section.add "X-Amz-Algorithm", valid_611349
  var valid_611350 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611350 = validateParameter(valid_611350, JString, required = false,
                                 default = nil)
  if valid_611350 != nil:
    section.add "X-Amz-SignedHeaders", valid_611350
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611352: Call_CreateDocument_611340; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a Systems Manager document.</p> <p>After you create a document, you can use CreateAssociation to associate it with one or more running instances.</p>
  ## 
  let valid = call_611352.validator(path, query, header, formData, body)
  let scheme = call_611352.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611352.url(scheme.get, call_611352.host, call_611352.base,
                         call_611352.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611352, url, valid)

proc call*(call_611353: Call_CreateDocument_611340; body: JsonNode): Recallable =
  ## createDocument
  ## <p>Creates a Systems Manager document.</p> <p>After you create a document, you can use CreateAssociation to associate it with one or more running instances.</p>
  ##   body: JObject (required)
  var body_611354 = newJObject()
  if body != nil:
    body_611354 = body
  result = call_611353.call(nil, nil, nil, nil, body_611354)

var createDocument* = Call_CreateDocument_611340(name: "createDocument",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.CreateDocument",
    validator: validate_CreateDocument_611341, base: "/", url: url_CreateDocument_611342,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateMaintenanceWindow_611355 = ref object of OpenApiRestCall_610658
proc url_CreateMaintenanceWindow_611357(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateMaintenanceWindow_611356(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611358 = header.getOrDefault("X-Amz-Target")
  valid_611358 = validateParameter(valid_611358, JString, required = true, default = newJString(
      "AmazonSSM.CreateMaintenanceWindow"))
  if valid_611358 != nil:
    section.add "X-Amz-Target", valid_611358
  var valid_611359 = header.getOrDefault("X-Amz-Signature")
  valid_611359 = validateParameter(valid_611359, JString, required = false,
                                 default = nil)
  if valid_611359 != nil:
    section.add "X-Amz-Signature", valid_611359
  var valid_611360 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611360 = validateParameter(valid_611360, JString, required = false,
                                 default = nil)
  if valid_611360 != nil:
    section.add "X-Amz-Content-Sha256", valid_611360
  var valid_611361 = header.getOrDefault("X-Amz-Date")
  valid_611361 = validateParameter(valid_611361, JString, required = false,
                                 default = nil)
  if valid_611361 != nil:
    section.add "X-Amz-Date", valid_611361
  var valid_611362 = header.getOrDefault("X-Amz-Credential")
  valid_611362 = validateParameter(valid_611362, JString, required = false,
                                 default = nil)
  if valid_611362 != nil:
    section.add "X-Amz-Credential", valid_611362
  var valid_611363 = header.getOrDefault("X-Amz-Security-Token")
  valid_611363 = validateParameter(valid_611363, JString, required = false,
                                 default = nil)
  if valid_611363 != nil:
    section.add "X-Amz-Security-Token", valid_611363
  var valid_611364 = header.getOrDefault("X-Amz-Algorithm")
  valid_611364 = validateParameter(valid_611364, JString, required = false,
                                 default = nil)
  if valid_611364 != nil:
    section.add "X-Amz-Algorithm", valid_611364
  var valid_611365 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611365 = validateParameter(valid_611365, JString, required = false,
                                 default = nil)
  if valid_611365 != nil:
    section.add "X-Amz-SignedHeaders", valid_611365
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611367: Call_CreateMaintenanceWindow_611355; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a new maintenance window.</p> <note> <p>The value you specify for <code>Duration</code> determines the specific end time for the maintenance window based on the time it begins. No maintenance window tasks are permitted to start after the resulting endtime minus the number of hours you specify for <code>Cutoff</code>. For example, if the maintenance window starts at 3 PM, the duration is three hours, and the value you specify for <code>Cutoff</code> is one hour, no maintenance window tasks can start after 5 PM.</p> </note>
  ## 
  let valid = call_611367.validator(path, query, header, formData, body)
  let scheme = call_611367.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611367.url(scheme.get, call_611367.host, call_611367.base,
                         call_611367.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611367, url, valid)

proc call*(call_611368: Call_CreateMaintenanceWindow_611355; body: JsonNode): Recallable =
  ## createMaintenanceWindow
  ## <p>Creates a new maintenance window.</p> <note> <p>The value you specify for <code>Duration</code> determines the specific end time for the maintenance window based on the time it begins. No maintenance window tasks are permitted to start after the resulting endtime minus the number of hours you specify for <code>Cutoff</code>. For example, if the maintenance window starts at 3 PM, the duration is three hours, and the value you specify for <code>Cutoff</code> is one hour, no maintenance window tasks can start after 5 PM.</p> </note>
  ##   body: JObject (required)
  var body_611369 = newJObject()
  if body != nil:
    body_611369 = body
  result = call_611368.call(nil, nil, nil, nil, body_611369)

var createMaintenanceWindow* = Call_CreateMaintenanceWindow_611355(
    name: "createMaintenanceWindow", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.CreateMaintenanceWindow",
    validator: validate_CreateMaintenanceWindow_611356, base: "/",
    url: url_CreateMaintenanceWindow_611357, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateOpsItem_611370 = ref object of OpenApiRestCall_610658
proc url_CreateOpsItem_611372(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateOpsItem_611371(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611373 = header.getOrDefault("X-Amz-Target")
  valid_611373 = validateParameter(valid_611373, JString, required = true, default = newJString(
      "AmazonSSM.CreateOpsItem"))
  if valid_611373 != nil:
    section.add "X-Amz-Target", valid_611373
  var valid_611374 = header.getOrDefault("X-Amz-Signature")
  valid_611374 = validateParameter(valid_611374, JString, required = false,
                                 default = nil)
  if valid_611374 != nil:
    section.add "X-Amz-Signature", valid_611374
  var valid_611375 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611375 = validateParameter(valid_611375, JString, required = false,
                                 default = nil)
  if valid_611375 != nil:
    section.add "X-Amz-Content-Sha256", valid_611375
  var valid_611376 = header.getOrDefault("X-Amz-Date")
  valid_611376 = validateParameter(valid_611376, JString, required = false,
                                 default = nil)
  if valid_611376 != nil:
    section.add "X-Amz-Date", valid_611376
  var valid_611377 = header.getOrDefault("X-Amz-Credential")
  valid_611377 = validateParameter(valid_611377, JString, required = false,
                                 default = nil)
  if valid_611377 != nil:
    section.add "X-Amz-Credential", valid_611377
  var valid_611378 = header.getOrDefault("X-Amz-Security-Token")
  valid_611378 = validateParameter(valid_611378, JString, required = false,
                                 default = nil)
  if valid_611378 != nil:
    section.add "X-Amz-Security-Token", valid_611378
  var valid_611379 = header.getOrDefault("X-Amz-Algorithm")
  valid_611379 = validateParameter(valid_611379, JString, required = false,
                                 default = nil)
  if valid_611379 != nil:
    section.add "X-Amz-Algorithm", valid_611379
  var valid_611380 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611380 = validateParameter(valid_611380, JString, required = false,
                                 default = nil)
  if valid_611380 != nil:
    section.add "X-Amz-SignedHeaders", valid_611380
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611382: Call_CreateOpsItem_611370; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a new OpsItem. You must have permission in AWS Identity and Access Management (IAM) to create a new OpsItem. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter-getting-started.html">Getting Started with OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>.</p> <p>Operations engineers and IT professionals use OpsCenter to view, investigate, and remediate operational issues impacting the performance and health of their AWS resources. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter.html">AWS Systems Manager OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>. </p>
  ## 
  let valid = call_611382.validator(path, query, header, formData, body)
  let scheme = call_611382.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611382.url(scheme.get, call_611382.host, call_611382.base,
                         call_611382.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611382, url, valid)

proc call*(call_611383: Call_CreateOpsItem_611370; body: JsonNode): Recallable =
  ## createOpsItem
  ## <p>Creates a new OpsItem. You must have permission in AWS Identity and Access Management (IAM) to create a new OpsItem. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter-getting-started.html">Getting Started with OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>.</p> <p>Operations engineers and IT professionals use OpsCenter to view, investigate, and remediate operational issues impacting the performance and health of their AWS resources. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter.html">AWS Systems Manager OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>. </p>
  ##   body: JObject (required)
  var body_611384 = newJObject()
  if body != nil:
    body_611384 = body
  result = call_611383.call(nil, nil, nil, nil, body_611384)

var createOpsItem* = Call_CreateOpsItem_611370(name: "createOpsItem",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.CreateOpsItem",
    validator: validate_CreateOpsItem_611371, base: "/", url: url_CreateOpsItem_611372,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePatchBaseline_611385 = ref object of OpenApiRestCall_610658
proc url_CreatePatchBaseline_611387(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreatePatchBaseline_611386(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611388 = header.getOrDefault("X-Amz-Target")
  valid_611388 = validateParameter(valid_611388, JString, required = true, default = newJString(
      "AmazonSSM.CreatePatchBaseline"))
  if valid_611388 != nil:
    section.add "X-Amz-Target", valid_611388
  var valid_611389 = header.getOrDefault("X-Amz-Signature")
  valid_611389 = validateParameter(valid_611389, JString, required = false,
                                 default = nil)
  if valid_611389 != nil:
    section.add "X-Amz-Signature", valid_611389
  var valid_611390 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611390 = validateParameter(valid_611390, JString, required = false,
                                 default = nil)
  if valid_611390 != nil:
    section.add "X-Amz-Content-Sha256", valid_611390
  var valid_611391 = header.getOrDefault("X-Amz-Date")
  valid_611391 = validateParameter(valid_611391, JString, required = false,
                                 default = nil)
  if valid_611391 != nil:
    section.add "X-Amz-Date", valid_611391
  var valid_611392 = header.getOrDefault("X-Amz-Credential")
  valid_611392 = validateParameter(valid_611392, JString, required = false,
                                 default = nil)
  if valid_611392 != nil:
    section.add "X-Amz-Credential", valid_611392
  var valid_611393 = header.getOrDefault("X-Amz-Security-Token")
  valid_611393 = validateParameter(valid_611393, JString, required = false,
                                 default = nil)
  if valid_611393 != nil:
    section.add "X-Amz-Security-Token", valid_611393
  var valid_611394 = header.getOrDefault("X-Amz-Algorithm")
  valid_611394 = validateParameter(valid_611394, JString, required = false,
                                 default = nil)
  if valid_611394 != nil:
    section.add "X-Amz-Algorithm", valid_611394
  var valid_611395 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611395 = validateParameter(valid_611395, JString, required = false,
                                 default = nil)
  if valid_611395 != nil:
    section.add "X-Amz-SignedHeaders", valid_611395
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611397: Call_CreatePatchBaseline_611385; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a patch baseline.</p> <note> <p>For information about valid key and value pairs in <code>PatchFilters</code> for each supported operating system type, see <a href="http://docs.aws.amazon.com/systems-manager/latest/APIReference/API_PatchFilter.html">PatchFilter</a>.</p> </note>
  ## 
  let valid = call_611397.validator(path, query, header, formData, body)
  let scheme = call_611397.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611397.url(scheme.get, call_611397.host, call_611397.base,
                         call_611397.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611397, url, valid)

proc call*(call_611398: Call_CreatePatchBaseline_611385; body: JsonNode): Recallable =
  ## createPatchBaseline
  ## <p>Creates a patch baseline.</p> <note> <p>For information about valid key and value pairs in <code>PatchFilters</code> for each supported operating system type, see <a href="http://docs.aws.amazon.com/systems-manager/latest/APIReference/API_PatchFilter.html">PatchFilter</a>.</p> </note>
  ##   body: JObject (required)
  var body_611399 = newJObject()
  if body != nil:
    body_611399 = body
  result = call_611398.call(nil, nil, nil, nil, body_611399)

var createPatchBaseline* = Call_CreatePatchBaseline_611385(
    name: "createPatchBaseline", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.CreatePatchBaseline",
    validator: validate_CreatePatchBaseline_611386, base: "/",
    url: url_CreatePatchBaseline_611387, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateResourceDataSync_611400 = ref object of OpenApiRestCall_610658
proc url_CreateResourceDataSync_611402(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateResourceDataSync_611401(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>A resource data sync helps you view data from multiple sources in a single location. Systems Manager offers two types of resource data sync: <code>SyncToDestination</code> and <code>SyncFromSource</code>.</p> <p>You can configure Systems Manager Inventory to use the <code>SyncToDestination</code> type to synchronize Inventory data from multiple AWS Regions to a single Amazon S3 bucket. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/sysman-inventory-datasync.html">Configuring Resource Data Sync for Inventory</a> in the <i>AWS Systems Manager User Guide</i>.</p> <p>You can configure Systems Manager Explorer to use the <code>SyncFromSource</code> type to synchronize operational work items (OpsItems) and operational data (OpsData) from multiple AWS Regions to a single Amazon S3 bucket. This type can synchronize OpsItems and OpsData from multiple AWS accounts and Regions or <code>EntireOrganization</code> by using AWS Organizations. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/Explorer-resource-data-sync.html">Setting Up Explorer to Display Data from Multiple Accounts and Regions</a> in the <i>AWS Systems Manager User Guide</i>.</p> <p>A resource data sync is an asynchronous operation that returns immediately. After a successful initial sync is completed, the system continuously syncs data. To check the status of a sync, use the <a>ListResourceDataSync</a>.</p> <note> <p>By default, data is not encrypted in Amazon S3. We strongly recommend that you enable encryption in Amazon S3 to ensure secure data storage. We also recommend that you secure access to the Amazon S3 bucket by creating a restrictive bucket policy. </p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611403 = header.getOrDefault("X-Amz-Target")
  valid_611403 = validateParameter(valid_611403, JString, required = true, default = newJString(
      "AmazonSSM.CreateResourceDataSync"))
  if valid_611403 != nil:
    section.add "X-Amz-Target", valid_611403
  var valid_611404 = header.getOrDefault("X-Amz-Signature")
  valid_611404 = validateParameter(valid_611404, JString, required = false,
                                 default = nil)
  if valid_611404 != nil:
    section.add "X-Amz-Signature", valid_611404
  var valid_611405 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611405 = validateParameter(valid_611405, JString, required = false,
                                 default = nil)
  if valid_611405 != nil:
    section.add "X-Amz-Content-Sha256", valid_611405
  var valid_611406 = header.getOrDefault("X-Amz-Date")
  valid_611406 = validateParameter(valid_611406, JString, required = false,
                                 default = nil)
  if valid_611406 != nil:
    section.add "X-Amz-Date", valid_611406
  var valid_611407 = header.getOrDefault("X-Amz-Credential")
  valid_611407 = validateParameter(valid_611407, JString, required = false,
                                 default = nil)
  if valid_611407 != nil:
    section.add "X-Amz-Credential", valid_611407
  var valid_611408 = header.getOrDefault("X-Amz-Security-Token")
  valid_611408 = validateParameter(valid_611408, JString, required = false,
                                 default = nil)
  if valid_611408 != nil:
    section.add "X-Amz-Security-Token", valid_611408
  var valid_611409 = header.getOrDefault("X-Amz-Algorithm")
  valid_611409 = validateParameter(valid_611409, JString, required = false,
                                 default = nil)
  if valid_611409 != nil:
    section.add "X-Amz-Algorithm", valid_611409
  var valid_611410 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611410 = validateParameter(valid_611410, JString, required = false,
                                 default = nil)
  if valid_611410 != nil:
    section.add "X-Amz-SignedHeaders", valid_611410
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611412: Call_CreateResourceDataSync_611400; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>A resource data sync helps you view data from multiple sources in a single location. Systems Manager offers two types of resource data sync: <code>SyncToDestination</code> and <code>SyncFromSource</code>.</p> <p>You can configure Systems Manager Inventory to use the <code>SyncToDestination</code> type to synchronize Inventory data from multiple AWS Regions to a single Amazon S3 bucket. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/sysman-inventory-datasync.html">Configuring Resource Data Sync for Inventory</a> in the <i>AWS Systems Manager User Guide</i>.</p> <p>You can configure Systems Manager Explorer to use the <code>SyncFromSource</code> type to synchronize operational work items (OpsItems) and operational data (OpsData) from multiple AWS Regions to a single Amazon S3 bucket. This type can synchronize OpsItems and OpsData from multiple AWS accounts and Regions or <code>EntireOrganization</code> by using AWS Organizations. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/Explorer-resource-data-sync.html">Setting Up Explorer to Display Data from Multiple Accounts and Regions</a> in the <i>AWS Systems Manager User Guide</i>.</p> <p>A resource data sync is an asynchronous operation that returns immediately. After a successful initial sync is completed, the system continuously syncs data. To check the status of a sync, use the <a>ListResourceDataSync</a>.</p> <note> <p>By default, data is not encrypted in Amazon S3. We strongly recommend that you enable encryption in Amazon S3 to ensure secure data storage. We also recommend that you secure access to the Amazon S3 bucket by creating a restrictive bucket policy. </p> </note>
  ## 
  let valid = call_611412.validator(path, query, header, formData, body)
  let scheme = call_611412.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611412.url(scheme.get, call_611412.host, call_611412.base,
                         call_611412.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611412, url, valid)

proc call*(call_611413: Call_CreateResourceDataSync_611400; body: JsonNode): Recallable =
  ## createResourceDataSync
  ## <p>A resource data sync helps you view data from multiple sources in a single location. Systems Manager offers two types of resource data sync: <code>SyncToDestination</code> and <code>SyncFromSource</code>.</p> <p>You can configure Systems Manager Inventory to use the <code>SyncToDestination</code> type to synchronize Inventory data from multiple AWS Regions to a single Amazon S3 bucket. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/sysman-inventory-datasync.html">Configuring Resource Data Sync for Inventory</a> in the <i>AWS Systems Manager User Guide</i>.</p> <p>You can configure Systems Manager Explorer to use the <code>SyncFromSource</code> type to synchronize operational work items (OpsItems) and operational data (OpsData) from multiple AWS Regions to a single Amazon S3 bucket. This type can synchronize OpsItems and OpsData from multiple AWS accounts and Regions or <code>EntireOrganization</code> by using AWS Organizations. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/Explorer-resource-data-sync.html">Setting Up Explorer to Display Data from Multiple Accounts and Regions</a> in the <i>AWS Systems Manager User Guide</i>.</p> <p>A resource data sync is an asynchronous operation that returns immediately. After a successful initial sync is completed, the system continuously syncs data. To check the status of a sync, use the <a>ListResourceDataSync</a>.</p> <note> <p>By default, data is not encrypted in Amazon S3. We strongly recommend that you enable encryption in Amazon S3 to ensure secure data storage. We also recommend that you secure access to the Amazon S3 bucket by creating a restrictive bucket policy. </p> </note>
  ##   body: JObject (required)
  var body_611414 = newJObject()
  if body != nil:
    body_611414 = body
  result = call_611413.call(nil, nil, nil, nil, body_611414)

var createResourceDataSync* = Call_CreateResourceDataSync_611400(
    name: "createResourceDataSync", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.CreateResourceDataSync",
    validator: validate_CreateResourceDataSync_611401, base: "/",
    url: url_CreateResourceDataSync_611402, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteActivation_611415 = ref object of OpenApiRestCall_610658
proc url_DeleteActivation_611417(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteActivation_611416(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611418 = header.getOrDefault("X-Amz-Target")
  valid_611418 = validateParameter(valid_611418, JString, required = true, default = newJString(
      "AmazonSSM.DeleteActivation"))
  if valid_611418 != nil:
    section.add "X-Amz-Target", valid_611418
  var valid_611419 = header.getOrDefault("X-Amz-Signature")
  valid_611419 = validateParameter(valid_611419, JString, required = false,
                                 default = nil)
  if valid_611419 != nil:
    section.add "X-Amz-Signature", valid_611419
  var valid_611420 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611420 = validateParameter(valid_611420, JString, required = false,
                                 default = nil)
  if valid_611420 != nil:
    section.add "X-Amz-Content-Sha256", valid_611420
  var valid_611421 = header.getOrDefault("X-Amz-Date")
  valid_611421 = validateParameter(valid_611421, JString, required = false,
                                 default = nil)
  if valid_611421 != nil:
    section.add "X-Amz-Date", valid_611421
  var valid_611422 = header.getOrDefault("X-Amz-Credential")
  valid_611422 = validateParameter(valid_611422, JString, required = false,
                                 default = nil)
  if valid_611422 != nil:
    section.add "X-Amz-Credential", valid_611422
  var valid_611423 = header.getOrDefault("X-Amz-Security-Token")
  valid_611423 = validateParameter(valid_611423, JString, required = false,
                                 default = nil)
  if valid_611423 != nil:
    section.add "X-Amz-Security-Token", valid_611423
  var valid_611424 = header.getOrDefault("X-Amz-Algorithm")
  valid_611424 = validateParameter(valid_611424, JString, required = false,
                                 default = nil)
  if valid_611424 != nil:
    section.add "X-Amz-Algorithm", valid_611424
  var valid_611425 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611425 = validateParameter(valid_611425, JString, required = false,
                                 default = nil)
  if valid_611425 != nil:
    section.add "X-Amz-SignedHeaders", valid_611425
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611427: Call_DeleteActivation_611415; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an activation. You are not required to delete an activation. If you delete an activation, you can no longer use it to register additional managed instances. Deleting an activation does not de-register managed instances. You must manually de-register managed instances.
  ## 
  let valid = call_611427.validator(path, query, header, formData, body)
  let scheme = call_611427.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611427.url(scheme.get, call_611427.host, call_611427.base,
                         call_611427.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611427, url, valid)

proc call*(call_611428: Call_DeleteActivation_611415; body: JsonNode): Recallable =
  ## deleteActivation
  ## Deletes an activation. You are not required to delete an activation. If you delete an activation, you can no longer use it to register additional managed instances. Deleting an activation does not de-register managed instances. You must manually de-register managed instances.
  ##   body: JObject (required)
  var body_611429 = newJObject()
  if body != nil:
    body_611429 = body
  result = call_611428.call(nil, nil, nil, nil, body_611429)

var deleteActivation* = Call_DeleteActivation_611415(name: "deleteActivation",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DeleteActivation",
    validator: validate_DeleteActivation_611416, base: "/",
    url: url_DeleteActivation_611417, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAssociation_611430 = ref object of OpenApiRestCall_610658
proc url_DeleteAssociation_611432(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteAssociation_611431(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611433 = header.getOrDefault("X-Amz-Target")
  valid_611433 = validateParameter(valid_611433, JString, required = true, default = newJString(
      "AmazonSSM.DeleteAssociation"))
  if valid_611433 != nil:
    section.add "X-Amz-Target", valid_611433
  var valid_611434 = header.getOrDefault("X-Amz-Signature")
  valid_611434 = validateParameter(valid_611434, JString, required = false,
                                 default = nil)
  if valid_611434 != nil:
    section.add "X-Amz-Signature", valid_611434
  var valid_611435 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611435 = validateParameter(valid_611435, JString, required = false,
                                 default = nil)
  if valid_611435 != nil:
    section.add "X-Amz-Content-Sha256", valid_611435
  var valid_611436 = header.getOrDefault("X-Amz-Date")
  valid_611436 = validateParameter(valid_611436, JString, required = false,
                                 default = nil)
  if valid_611436 != nil:
    section.add "X-Amz-Date", valid_611436
  var valid_611437 = header.getOrDefault("X-Amz-Credential")
  valid_611437 = validateParameter(valid_611437, JString, required = false,
                                 default = nil)
  if valid_611437 != nil:
    section.add "X-Amz-Credential", valid_611437
  var valid_611438 = header.getOrDefault("X-Amz-Security-Token")
  valid_611438 = validateParameter(valid_611438, JString, required = false,
                                 default = nil)
  if valid_611438 != nil:
    section.add "X-Amz-Security-Token", valid_611438
  var valid_611439 = header.getOrDefault("X-Amz-Algorithm")
  valid_611439 = validateParameter(valid_611439, JString, required = false,
                                 default = nil)
  if valid_611439 != nil:
    section.add "X-Amz-Algorithm", valid_611439
  var valid_611440 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611440 = validateParameter(valid_611440, JString, required = false,
                                 default = nil)
  if valid_611440 != nil:
    section.add "X-Amz-SignedHeaders", valid_611440
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611442: Call_DeleteAssociation_611430; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Disassociates the specified Systems Manager document from the specified instance.</p> <p>When you disassociate a document from an instance, it does not change the configuration of the instance. To change the configuration state of an instance after you disassociate a document, you must create a new document with the desired configuration and associate it with the instance.</p>
  ## 
  let valid = call_611442.validator(path, query, header, formData, body)
  let scheme = call_611442.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611442.url(scheme.get, call_611442.host, call_611442.base,
                         call_611442.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611442, url, valid)

proc call*(call_611443: Call_DeleteAssociation_611430; body: JsonNode): Recallable =
  ## deleteAssociation
  ## <p>Disassociates the specified Systems Manager document from the specified instance.</p> <p>When you disassociate a document from an instance, it does not change the configuration of the instance. To change the configuration state of an instance after you disassociate a document, you must create a new document with the desired configuration and associate it with the instance.</p>
  ##   body: JObject (required)
  var body_611444 = newJObject()
  if body != nil:
    body_611444 = body
  result = call_611443.call(nil, nil, nil, nil, body_611444)

var deleteAssociation* = Call_DeleteAssociation_611430(name: "deleteAssociation",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DeleteAssociation",
    validator: validate_DeleteAssociation_611431, base: "/",
    url: url_DeleteAssociation_611432, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDocument_611445 = ref object of OpenApiRestCall_610658
proc url_DeleteDocument_611447(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteDocument_611446(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611448 = header.getOrDefault("X-Amz-Target")
  valid_611448 = validateParameter(valid_611448, JString, required = true, default = newJString(
      "AmazonSSM.DeleteDocument"))
  if valid_611448 != nil:
    section.add "X-Amz-Target", valid_611448
  var valid_611449 = header.getOrDefault("X-Amz-Signature")
  valid_611449 = validateParameter(valid_611449, JString, required = false,
                                 default = nil)
  if valid_611449 != nil:
    section.add "X-Amz-Signature", valid_611449
  var valid_611450 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611450 = validateParameter(valid_611450, JString, required = false,
                                 default = nil)
  if valid_611450 != nil:
    section.add "X-Amz-Content-Sha256", valid_611450
  var valid_611451 = header.getOrDefault("X-Amz-Date")
  valid_611451 = validateParameter(valid_611451, JString, required = false,
                                 default = nil)
  if valid_611451 != nil:
    section.add "X-Amz-Date", valid_611451
  var valid_611452 = header.getOrDefault("X-Amz-Credential")
  valid_611452 = validateParameter(valid_611452, JString, required = false,
                                 default = nil)
  if valid_611452 != nil:
    section.add "X-Amz-Credential", valid_611452
  var valid_611453 = header.getOrDefault("X-Amz-Security-Token")
  valid_611453 = validateParameter(valid_611453, JString, required = false,
                                 default = nil)
  if valid_611453 != nil:
    section.add "X-Amz-Security-Token", valid_611453
  var valid_611454 = header.getOrDefault("X-Amz-Algorithm")
  valid_611454 = validateParameter(valid_611454, JString, required = false,
                                 default = nil)
  if valid_611454 != nil:
    section.add "X-Amz-Algorithm", valid_611454
  var valid_611455 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611455 = validateParameter(valid_611455, JString, required = false,
                                 default = nil)
  if valid_611455 != nil:
    section.add "X-Amz-SignedHeaders", valid_611455
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611457: Call_DeleteDocument_611445; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the Systems Manager document and all instance associations to the document.</p> <p>Before you delete the document, we recommend that you use <a>DeleteAssociation</a> to disassociate all instances that are associated with the document.</p>
  ## 
  let valid = call_611457.validator(path, query, header, formData, body)
  let scheme = call_611457.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611457.url(scheme.get, call_611457.host, call_611457.base,
                         call_611457.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611457, url, valid)

proc call*(call_611458: Call_DeleteDocument_611445; body: JsonNode): Recallable =
  ## deleteDocument
  ## <p>Deletes the Systems Manager document and all instance associations to the document.</p> <p>Before you delete the document, we recommend that you use <a>DeleteAssociation</a> to disassociate all instances that are associated with the document.</p>
  ##   body: JObject (required)
  var body_611459 = newJObject()
  if body != nil:
    body_611459 = body
  result = call_611458.call(nil, nil, nil, nil, body_611459)

var deleteDocument* = Call_DeleteDocument_611445(name: "deleteDocument",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DeleteDocument",
    validator: validate_DeleteDocument_611446, base: "/", url: url_DeleteDocument_611447,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteInventory_611460 = ref object of OpenApiRestCall_610658
proc url_DeleteInventory_611462(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteInventory_611461(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611463 = header.getOrDefault("X-Amz-Target")
  valid_611463 = validateParameter(valid_611463, JString, required = true, default = newJString(
      "AmazonSSM.DeleteInventory"))
  if valid_611463 != nil:
    section.add "X-Amz-Target", valid_611463
  var valid_611464 = header.getOrDefault("X-Amz-Signature")
  valid_611464 = validateParameter(valid_611464, JString, required = false,
                                 default = nil)
  if valid_611464 != nil:
    section.add "X-Amz-Signature", valid_611464
  var valid_611465 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611465 = validateParameter(valid_611465, JString, required = false,
                                 default = nil)
  if valid_611465 != nil:
    section.add "X-Amz-Content-Sha256", valid_611465
  var valid_611466 = header.getOrDefault("X-Amz-Date")
  valid_611466 = validateParameter(valid_611466, JString, required = false,
                                 default = nil)
  if valid_611466 != nil:
    section.add "X-Amz-Date", valid_611466
  var valid_611467 = header.getOrDefault("X-Amz-Credential")
  valid_611467 = validateParameter(valid_611467, JString, required = false,
                                 default = nil)
  if valid_611467 != nil:
    section.add "X-Amz-Credential", valid_611467
  var valid_611468 = header.getOrDefault("X-Amz-Security-Token")
  valid_611468 = validateParameter(valid_611468, JString, required = false,
                                 default = nil)
  if valid_611468 != nil:
    section.add "X-Amz-Security-Token", valid_611468
  var valid_611469 = header.getOrDefault("X-Amz-Algorithm")
  valid_611469 = validateParameter(valid_611469, JString, required = false,
                                 default = nil)
  if valid_611469 != nil:
    section.add "X-Amz-Algorithm", valid_611469
  var valid_611470 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611470 = validateParameter(valid_611470, JString, required = false,
                                 default = nil)
  if valid_611470 != nil:
    section.add "X-Amz-SignedHeaders", valid_611470
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611472: Call_DeleteInventory_611460; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Delete a custom inventory type, or the data associated with a custom Inventory type. Deleting a custom inventory type is also referred to as deleting a custom inventory schema.
  ## 
  let valid = call_611472.validator(path, query, header, formData, body)
  let scheme = call_611472.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611472.url(scheme.get, call_611472.host, call_611472.base,
                         call_611472.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611472, url, valid)

proc call*(call_611473: Call_DeleteInventory_611460; body: JsonNode): Recallable =
  ## deleteInventory
  ## Delete a custom inventory type, or the data associated with a custom Inventory type. Deleting a custom inventory type is also referred to as deleting a custom inventory schema.
  ##   body: JObject (required)
  var body_611474 = newJObject()
  if body != nil:
    body_611474 = body
  result = call_611473.call(nil, nil, nil, nil, body_611474)

var deleteInventory* = Call_DeleteInventory_611460(name: "deleteInventory",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DeleteInventory",
    validator: validate_DeleteInventory_611461, base: "/", url: url_DeleteInventory_611462,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteMaintenanceWindow_611475 = ref object of OpenApiRestCall_610658
proc url_DeleteMaintenanceWindow_611477(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteMaintenanceWindow_611476(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611478 = header.getOrDefault("X-Amz-Target")
  valid_611478 = validateParameter(valid_611478, JString, required = true, default = newJString(
      "AmazonSSM.DeleteMaintenanceWindow"))
  if valid_611478 != nil:
    section.add "X-Amz-Target", valid_611478
  var valid_611479 = header.getOrDefault("X-Amz-Signature")
  valid_611479 = validateParameter(valid_611479, JString, required = false,
                                 default = nil)
  if valid_611479 != nil:
    section.add "X-Amz-Signature", valid_611479
  var valid_611480 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611480 = validateParameter(valid_611480, JString, required = false,
                                 default = nil)
  if valid_611480 != nil:
    section.add "X-Amz-Content-Sha256", valid_611480
  var valid_611481 = header.getOrDefault("X-Amz-Date")
  valid_611481 = validateParameter(valid_611481, JString, required = false,
                                 default = nil)
  if valid_611481 != nil:
    section.add "X-Amz-Date", valid_611481
  var valid_611482 = header.getOrDefault("X-Amz-Credential")
  valid_611482 = validateParameter(valid_611482, JString, required = false,
                                 default = nil)
  if valid_611482 != nil:
    section.add "X-Amz-Credential", valid_611482
  var valid_611483 = header.getOrDefault("X-Amz-Security-Token")
  valid_611483 = validateParameter(valid_611483, JString, required = false,
                                 default = nil)
  if valid_611483 != nil:
    section.add "X-Amz-Security-Token", valid_611483
  var valid_611484 = header.getOrDefault("X-Amz-Algorithm")
  valid_611484 = validateParameter(valid_611484, JString, required = false,
                                 default = nil)
  if valid_611484 != nil:
    section.add "X-Amz-Algorithm", valid_611484
  var valid_611485 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611485 = validateParameter(valid_611485, JString, required = false,
                                 default = nil)
  if valid_611485 != nil:
    section.add "X-Amz-SignedHeaders", valid_611485
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611487: Call_DeleteMaintenanceWindow_611475; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a maintenance window.
  ## 
  let valid = call_611487.validator(path, query, header, formData, body)
  let scheme = call_611487.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611487.url(scheme.get, call_611487.host, call_611487.base,
                         call_611487.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611487, url, valid)

proc call*(call_611488: Call_DeleteMaintenanceWindow_611475; body: JsonNode): Recallable =
  ## deleteMaintenanceWindow
  ## Deletes a maintenance window.
  ##   body: JObject (required)
  var body_611489 = newJObject()
  if body != nil:
    body_611489 = body
  result = call_611488.call(nil, nil, nil, nil, body_611489)

var deleteMaintenanceWindow* = Call_DeleteMaintenanceWindow_611475(
    name: "deleteMaintenanceWindow", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DeleteMaintenanceWindow",
    validator: validate_DeleteMaintenanceWindow_611476, base: "/",
    url: url_DeleteMaintenanceWindow_611477, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteParameter_611490 = ref object of OpenApiRestCall_610658
proc url_DeleteParameter_611492(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteParameter_611491(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611493 = header.getOrDefault("X-Amz-Target")
  valid_611493 = validateParameter(valid_611493, JString, required = true, default = newJString(
      "AmazonSSM.DeleteParameter"))
  if valid_611493 != nil:
    section.add "X-Amz-Target", valid_611493
  var valid_611494 = header.getOrDefault("X-Amz-Signature")
  valid_611494 = validateParameter(valid_611494, JString, required = false,
                                 default = nil)
  if valid_611494 != nil:
    section.add "X-Amz-Signature", valid_611494
  var valid_611495 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611495 = validateParameter(valid_611495, JString, required = false,
                                 default = nil)
  if valid_611495 != nil:
    section.add "X-Amz-Content-Sha256", valid_611495
  var valid_611496 = header.getOrDefault("X-Amz-Date")
  valid_611496 = validateParameter(valid_611496, JString, required = false,
                                 default = nil)
  if valid_611496 != nil:
    section.add "X-Amz-Date", valid_611496
  var valid_611497 = header.getOrDefault("X-Amz-Credential")
  valid_611497 = validateParameter(valid_611497, JString, required = false,
                                 default = nil)
  if valid_611497 != nil:
    section.add "X-Amz-Credential", valid_611497
  var valid_611498 = header.getOrDefault("X-Amz-Security-Token")
  valid_611498 = validateParameter(valid_611498, JString, required = false,
                                 default = nil)
  if valid_611498 != nil:
    section.add "X-Amz-Security-Token", valid_611498
  var valid_611499 = header.getOrDefault("X-Amz-Algorithm")
  valid_611499 = validateParameter(valid_611499, JString, required = false,
                                 default = nil)
  if valid_611499 != nil:
    section.add "X-Amz-Algorithm", valid_611499
  var valid_611500 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611500 = validateParameter(valid_611500, JString, required = false,
                                 default = nil)
  if valid_611500 != nil:
    section.add "X-Amz-SignedHeaders", valid_611500
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611502: Call_DeleteParameter_611490; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Delete a parameter from the system.
  ## 
  let valid = call_611502.validator(path, query, header, formData, body)
  let scheme = call_611502.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611502.url(scheme.get, call_611502.host, call_611502.base,
                         call_611502.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611502, url, valid)

proc call*(call_611503: Call_DeleteParameter_611490; body: JsonNode): Recallable =
  ## deleteParameter
  ## Delete a parameter from the system.
  ##   body: JObject (required)
  var body_611504 = newJObject()
  if body != nil:
    body_611504 = body
  result = call_611503.call(nil, nil, nil, nil, body_611504)

var deleteParameter* = Call_DeleteParameter_611490(name: "deleteParameter",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DeleteParameter",
    validator: validate_DeleteParameter_611491, base: "/", url: url_DeleteParameter_611492,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteParameters_611505 = ref object of OpenApiRestCall_610658
proc url_DeleteParameters_611507(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteParameters_611506(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611508 = header.getOrDefault("X-Amz-Target")
  valid_611508 = validateParameter(valid_611508, JString, required = true, default = newJString(
      "AmazonSSM.DeleteParameters"))
  if valid_611508 != nil:
    section.add "X-Amz-Target", valid_611508
  var valid_611509 = header.getOrDefault("X-Amz-Signature")
  valid_611509 = validateParameter(valid_611509, JString, required = false,
                                 default = nil)
  if valid_611509 != nil:
    section.add "X-Amz-Signature", valid_611509
  var valid_611510 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611510 = validateParameter(valid_611510, JString, required = false,
                                 default = nil)
  if valid_611510 != nil:
    section.add "X-Amz-Content-Sha256", valid_611510
  var valid_611511 = header.getOrDefault("X-Amz-Date")
  valid_611511 = validateParameter(valid_611511, JString, required = false,
                                 default = nil)
  if valid_611511 != nil:
    section.add "X-Amz-Date", valid_611511
  var valid_611512 = header.getOrDefault("X-Amz-Credential")
  valid_611512 = validateParameter(valid_611512, JString, required = false,
                                 default = nil)
  if valid_611512 != nil:
    section.add "X-Amz-Credential", valid_611512
  var valid_611513 = header.getOrDefault("X-Amz-Security-Token")
  valid_611513 = validateParameter(valid_611513, JString, required = false,
                                 default = nil)
  if valid_611513 != nil:
    section.add "X-Amz-Security-Token", valid_611513
  var valid_611514 = header.getOrDefault("X-Amz-Algorithm")
  valid_611514 = validateParameter(valid_611514, JString, required = false,
                                 default = nil)
  if valid_611514 != nil:
    section.add "X-Amz-Algorithm", valid_611514
  var valid_611515 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611515 = validateParameter(valid_611515, JString, required = false,
                                 default = nil)
  if valid_611515 != nil:
    section.add "X-Amz-SignedHeaders", valid_611515
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611517: Call_DeleteParameters_611505; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Delete a list of parameters.
  ## 
  let valid = call_611517.validator(path, query, header, formData, body)
  let scheme = call_611517.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611517.url(scheme.get, call_611517.host, call_611517.base,
                         call_611517.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611517, url, valid)

proc call*(call_611518: Call_DeleteParameters_611505; body: JsonNode): Recallable =
  ## deleteParameters
  ## Delete a list of parameters.
  ##   body: JObject (required)
  var body_611519 = newJObject()
  if body != nil:
    body_611519 = body
  result = call_611518.call(nil, nil, nil, nil, body_611519)

var deleteParameters* = Call_DeleteParameters_611505(name: "deleteParameters",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DeleteParameters",
    validator: validate_DeleteParameters_611506, base: "/",
    url: url_DeleteParameters_611507, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeletePatchBaseline_611520 = ref object of OpenApiRestCall_610658
proc url_DeletePatchBaseline_611522(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeletePatchBaseline_611521(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611523 = header.getOrDefault("X-Amz-Target")
  valid_611523 = validateParameter(valid_611523, JString, required = true, default = newJString(
      "AmazonSSM.DeletePatchBaseline"))
  if valid_611523 != nil:
    section.add "X-Amz-Target", valid_611523
  var valid_611524 = header.getOrDefault("X-Amz-Signature")
  valid_611524 = validateParameter(valid_611524, JString, required = false,
                                 default = nil)
  if valid_611524 != nil:
    section.add "X-Amz-Signature", valid_611524
  var valid_611525 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611525 = validateParameter(valid_611525, JString, required = false,
                                 default = nil)
  if valid_611525 != nil:
    section.add "X-Amz-Content-Sha256", valid_611525
  var valid_611526 = header.getOrDefault("X-Amz-Date")
  valid_611526 = validateParameter(valid_611526, JString, required = false,
                                 default = nil)
  if valid_611526 != nil:
    section.add "X-Amz-Date", valid_611526
  var valid_611527 = header.getOrDefault("X-Amz-Credential")
  valid_611527 = validateParameter(valid_611527, JString, required = false,
                                 default = nil)
  if valid_611527 != nil:
    section.add "X-Amz-Credential", valid_611527
  var valid_611528 = header.getOrDefault("X-Amz-Security-Token")
  valid_611528 = validateParameter(valid_611528, JString, required = false,
                                 default = nil)
  if valid_611528 != nil:
    section.add "X-Amz-Security-Token", valid_611528
  var valid_611529 = header.getOrDefault("X-Amz-Algorithm")
  valid_611529 = validateParameter(valid_611529, JString, required = false,
                                 default = nil)
  if valid_611529 != nil:
    section.add "X-Amz-Algorithm", valid_611529
  var valid_611530 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611530 = validateParameter(valid_611530, JString, required = false,
                                 default = nil)
  if valid_611530 != nil:
    section.add "X-Amz-SignedHeaders", valid_611530
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611532: Call_DeletePatchBaseline_611520; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a patch baseline.
  ## 
  let valid = call_611532.validator(path, query, header, formData, body)
  let scheme = call_611532.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611532.url(scheme.get, call_611532.host, call_611532.base,
                         call_611532.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611532, url, valid)

proc call*(call_611533: Call_DeletePatchBaseline_611520; body: JsonNode): Recallable =
  ## deletePatchBaseline
  ## Deletes a patch baseline.
  ##   body: JObject (required)
  var body_611534 = newJObject()
  if body != nil:
    body_611534 = body
  result = call_611533.call(nil, nil, nil, nil, body_611534)

var deletePatchBaseline* = Call_DeletePatchBaseline_611520(
    name: "deletePatchBaseline", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DeletePatchBaseline",
    validator: validate_DeletePatchBaseline_611521, base: "/",
    url: url_DeletePatchBaseline_611522, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteResourceDataSync_611535 = ref object of OpenApiRestCall_610658
proc url_DeleteResourceDataSync_611537(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteResourceDataSync_611536(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes a Resource Data Sync configuration. After the configuration is deleted, changes to data on managed instances are no longer synced to or from the target. Deleting a sync configuration does not delete data.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611538 = header.getOrDefault("X-Amz-Target")
  valid_611538 = validateParameter(valid_611538, JString, required = true, default = newJString(
      "AmazonSSM.DeleteResourceDataSync"))
  if valid_611538 != nil:
    section.add "X-Amz-Target", valid_611538
  var valid_611539 = header.getOrDefault("X-Amz-Signature")
  valid_611539 = validateParameter(valid_611539, JString, required = false,
                                 default = nil)
  if valid_611539 != nil:
    section.add "X-Amz-Signature", valid_611539
  var valid_611540 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611540 = validateParameter(valid_611540, JString, required = false,
                                 default = nil)
  if valid_611540 != nil:
    section.add "X-Amz-Content-Sha256", valid_611540
  var valid_611541 = header.getOrDefault("X-Amz-Date")
  valid_611541 = validateParameter(valid_611541, JString, required = false,
                                 default = nil)
  if valid_611541 != nil:
    section.add "X-Amz-Date", valid_611541
  var valid_611542 = header.getOrDefault("X-Amz-Credential")
  valid_611542 = validateParameter(valid_611542, JString, required = false,
                                 default = nil)
  if valid_611542 != nil:
    section.add "X-Amz-Credential", valid_611542
  var valid_611543 = header.getOrDefault("X-Amz-Security-Token")
  valid_611543 = validateParameter(valid_611543, JString, required = false,
                                 default = nil)
  if valid_611543 != nil:
    section.add "X-Amz-Security-Token", valid_611543
  var valid_611544 = header.getOrDefault("X-Amz-Algorithm")
  valid_611544 = validateParameter(valid_611544, JString, required = false,
                                 default = nil)
  if valid_611544 != nil:
    section.add "X-Amz-Algorithm", valid_611544
  var valid_611545 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611545 = validateParameter(valid_611545, JString, required = false,
                                 default = nil)
  if valid_611545 != nil:
    section.add "X-Amz-SignedHeaders", valid_611545
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611547: Call_DeleteResourceDataSync_611535; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a Resource Data Sync configuration. After the configuration is deleted, changes to data on managed instances are no longer synced to or from the target. Deleting a sync configuration does not delete data.
  ## 
  let valid = call_611547.validator(path, query, header, formData, body)
  let scheme = call_611547.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611547.url(scheme.get, call_611547.host, call_611547.base,
                         call_611547.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611547, url, valid)

proc call*(call_611548: Call_DeleteResourceDataSync_611535; body: JsonNode): Recallable =
  ## deleteResourceDataSync
  ## Deletes a Resource Data Sync configuration. After the configuration is deleted, changes to data on managed instances are no longer synced to or from the target. Deleting a sync configuration does not delete data.
  ##   body: JObject (required)
  var body_611549 = newJObject()
  if body != nil:
    body_611549 = body
  result = call_611548.call(nil, nil, nil, nil, body_611549)

var deleteResourceDataSync* = Call_DeleteResourceDataSync_611535(
    name: "deleteResourceDataSync", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DeleteResourceDataSync",
    validator: validate_DeleteResourceDataSync_611536, base: "/",
    url: url_DeleteResourceDataSync_611537, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeregisterManagedInstance_611550 = ref object of OpenApiRestCall_610658
proc url_DeregisterManagedInstance_611552(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeregisterManagedInstance_611551(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611553 = header.getOrDefault("X-Amz-Target")
  valid_611553 = validateParameter(valid_611553, JString, required = true, default = newJString(
      "AmazonSSM.DeregisterManagedInstance"))
  if valid_611553 != nil:
    section.add "X-Amz-Target", valid_611553
  var valid_611554 = header.getOrDefault("X-Amz-Signature")
  valid_611554 = validateParameter(valid_611554, JString, required = false,
                                 default = nil)
  if valid_611554 != nil:
    section.add "X-Amz-Signature", valid_611554
  var valid_611555 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611555 = validateParameter(valid_611555, JString, required = false,
                                 default = nil)
  if valid_611555 != nil:
    section.add "X-Amz-Content-Sha256", valid_611555
  var valid_611556 = header.getOrDefault("X-Amz-Date")
  valid_611556 = validateParameter(valid_611556, JString, required = false,
                                 default = nil)
  if valid_611556 != nil:
    section.add "X-Amz-Date", valid_611556
  var valid_611557 = header.getOrDefault("X-Amz-Credential")
  valid_611557 = validateParameter(valid_611557, JString, required = false,
                                 default = nil)
  if valid_611557 != nil:
    section.add "X-Amz-Credential", valid_611557
  var valid_611558 = header.getOrDefault("X-Amz-Security-Token")
  valid_611558 = validateParameter(valid_611558, JString, required = false,
                                 default = nil)
  if valid_611558 != nil:
    section.add "X-Amz-Security-Token", valid_611558
  var valid_611559 = header.getOrDefault("X-Amz-Algorithm")
  valid_611559 = validateParameter(valid_611559, JString, required = false,
                                 default = nil)
  if valid_611559 != nil:
    section.add "X-Amz-Algorithm", valid_611559
  var valid_611560 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611560 = validateParameter(valid_611560, JString, required = false,
                                 default = nil)
  if valid_611560 != nil:
    section.add "X-Amz-SignedHeaders", valid_611560
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611562: Call_DeregisterManagedInstance_611550; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes the server or virtual machine from the list of registered servers. You can reregister the instance again at any time. If you don't plan to use Run Command on the server, we suggest uninstalling SSM Agent first.
  ## 
  let valid = call_611562.validator(path, query, header, formData, body)
  let scheme = call_611562.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611562.url(scheme.get, call_611562.host, call_611562.base,
                         call_611562.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611562, url, valid)

proc call*(call_611563: Call_DeregisterManagedInstance_611550; body: JsonNode): Recallable =
  ## deregisterManagedInstance
  ## Removes the server or virtual machine from the list of registered servers. You can reregister the instance again at any time. If you don't plan to use Run Command on the server, we suggest uninstalling SSM Agent first.
  ##   body: JObject (required)
  var body_611564 = newJObject()
  if body != nil:
    body_611564 = body
  result = call_611563.call(nil, nil, nil, nil, body_611564)

var deregisterManagedInstance* = Call_DeregisterManagedInstance_611550(
    name: "deregisterManagedInstance", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DeregisterManagedInstance",
    validator: validate_DeregisterManagedInstance_611551, base: "/",
    url: url_DeregisterManagedInstance_611552,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeregisterPatchBaselineForPatchGroup_611565 = ref object of OpenApiRestCall_610658
proc url_DeregisterPatchBaselineForPatchGroup_611567(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeregisterPatchBaselineForPatchGroup_611566(path: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611568 = header.getOrDefault("X-Amz-Target")
  valid_611568 = validateParameter(valid_611568, JString, required = true, default = newJString(
      "AmazonSSM.DeregisterPatchBaselineForPatchGroup"))
  if valid_611568 != nil:
    section.add "X-Amz-Target", valid_611568
  var valid_611569 = header.getOrDefault("X-Amz-Signature")
  valid_611569 = validateParameter(valid_611569, JString, required = false,
                                 default = nil)
  if valid_611569 != nil:
    section.add "X-Amz-Signature", valid_611569
  var valid_611570 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611570 = validateParameter(valid_611570, JString, required = false,
                                 default = nil)
  if valid_611570 != nil:
    section.add "X-Amz-Content-Sha256", valid_611570
  var valid_611571 = header.getOrDefault("X-Amz-Date")
  valid_611571 = validateParameter(valid_611571, JString, required = false,
                                 default = nil)
  if valid_611571 != nil:
    section.add "X-Amz-Date", valid_611571
  var valid_611572 = header.getOrDefault("X-Amz-Credential")
  valid_611572 = validateParameter(valid_611572, JString, required = false,
                                 default = nil)
  if valid_611572 != nil:
    section.add "X-Amz-Credential", valid_611572
  var valid_611573 = header.getOrDefault("X-Amz-Security-Token")
  valid_611573 = validateParameter(valid_611573, JString, required = false,
                                 default = nil)
  if valid_611573 != nil:
    section.add "X-Amz-Security-Token", valid_611573
  var valid_611574 = header.getOrDefault("X-Amz-Algorithm")
  valid_611574 = validateParameter(valid_611574, JString, required = false,
                                 default = nil)
  if valid_611574 != nil:
    section.add "X-Amz-Algorithm", valid_611574
  var valid_611575 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611575 = validateParameter(valid_611575, JString, required = false,
                                 default = nil)
  if valid_611575 != nil:
    section.add "X-Amz-SignedHeaders", valid_611575
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611577: Call_DeregisterPatchBaselineForPatchGroup_611565;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Removes a patch group from a patch baseline.
  ## 
  let valid = call_611577.validator(path, query, header, formData, body)
  let scheme = call_611577.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611577.url(scheme.get, call_611577.host, call_611577.base,
                         call_611577.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611577, url, valid)

proc call*(call_611578: Call_DeregisterPatchBaselineForPatchGroup_611565;
          body: JsonNode): Recallable =
  ## deregisterPatchBaselineForPatchGroup
  ## Removes a patch group from a patch baseline.
  ##   body: JObject (required)
  var body_611579 = newJObject()
  if body != nil:
    body_611579 = body
  result = call_611578.call(nil, nil, nil, nil, body_611579)

var deregisterPatchBaselineForPatchGroup* = Call_DeregisterPatchBaselineForPatchGroup_611565(
    name: "deregisterPatchBaselineForPatchGroup", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DeregisterPatchBaselineForPatchGroup",
    validator: validate_DeregisterPatchBaselineForPatchGroup_611566, base: "/",
    url: url_DeregisterPatchBaselineForPatchGroup_611567,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeregisterTargetFromMaintenanceWindow_611580 = ref object of OpenApiRestCall_610658
proc url_DeregisterTargetFromMaintenanceWindow_611582(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeregisterTargetFromMaintenanceWindow_611581(path: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611583 = header.getOrDefault("X-Amz-Target")
  valid_611583 = validateParameter(valid_611583, JString, required = true, default = newJString(
      "AmazonSSM.DeregisterTargetFromMaintenanceWindow"))
  if valid_611583 != nil:
    section.add "X-Amz-Target", valid_611583
  var valid_611584 = header.getOrDefault("X-Amz-Signature")
  valid_611584 = validateParameter(valid_611584, JString, required = false,
                                 default = nil)
  if valid_611584 != nil:
    section.add "X-Amz-Signature", valid_611584
  var valid_611585 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611585 = validateParameter(valid_611585, JString, required = false,
                                 default = nil)
  if valid_611585 != nil:
    section.add "X-Amz-Content-Sha256", valid_611585
  var valid_611586 = header.getOrDefault("X-Amz-Date")
  valid_611586 = validateParameter(valid_611586, JString, required = false,
                                 default = nil)
  if valid_611586 != nil:
    section.add "X-Amz-Date", valid_611586
  var valid_611587 = header.getOrDefault("X-Amz-Credential")
  valid_611587 = validateParameter(valid_611587, JString, required = false,
                                 default = nil)
  if valid_611587 != nil:
    section.add "X-Amz-Credential", valid_611587
  var valid_611588 = header.getOrDefault("X-Amz-Security-Token")
  valid_611588 = validateParameter(valid_611588, JString, required = false,
                                 default = nil)
  if valid_611588 != nil:
    section.add "X-Amz-Security-Token", valid_611588
  var valid_611589 = header.getOrDefault("X-Amz-Algorithm")
  valid_611589 = validateParameter(valid_611589, JString, required = false,
                                 default = nil)
  if valid_611589 != nil:
    section.add "X-Amz-Algorithm", valid_611589
  var valid_611590 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611590 = validateParameter(valid_611590, JString, required = false,
                                 default = nil)
  if valid_611590 != nil:
    section.add "X-Amz-SignedHeaders", valid_611590
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611592: Call_DeregisterTargetFromMaintenanceWindow_611580;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Removes a target from a maintenance window.
  ## 
  let valid = call_611592.validator(path, query, header, formData, body)
  let scheme = call_611592.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611592.url(scheme.get, call_611592.host, call_611592.base,
                         call_611592.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611592, url, valid)

proc call*(call_611593: Call_DeregisterTargetFromMaintenanceWindow_611580;
          body: JsonNode): Recallable =
  ## deregisterTargetFromMaintenanceWindow
  ## Removes a target from a maintenance window.
  ##   body: JObject (required)
  var body_611594 = newJObject()
  if body != nil:
    body_611594 = body
  result = call_611593.call(nil, nil, nil, nil, body_611594)

var deregisterTargetFromMaintenanceWindow* = Call_DeregisterTargetFromMaintenanceWindow_611580(
    name: "deregisterTargetFromMaintenanceWindow", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DeregisterTargetFromMaintenanceWindow",
    validator: validate_DeregisterTargetFromMaintenanceWindow_611581, base: "/",
    url: url_DeregisterTargetFromMaintenanceWindow_611582,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeregisterTaskFromMaintenanceWindow_611595 = ref object of OpenApiRestCall_610658
proc url_DeregisterTaskFromMaintenanceWindow_611597(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeregisterTaskFromMaintenanceWindow_611596(path: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611598 = header.getOrDefault("X-Amz-Target")
  valid_611598 = validateParameter(valid_611598, JString, required = true, default = newJString(
      "AmazonSSM.DeregisterTaskFromMaintenanceWindow"))
  if valid_611598 != nil:
    section.add "X-Amz-Target", valid_611598
  var valid_611599 = header.getOrDefault("X-Amz-Signature")
  valid_611599 = validateParameter(valid_611599, JString, required = false,
                                 default = nil)
  if valid_611599 != nil:
    section.add "X-Amz-Signature", valid_611599
  var valid_611600 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611600 = validateParameter(valid_611600, JString, required = false,
                                 default = nil)
  if valid_611600 != nil:
    section.add "X-Amz-Content-Sha256", valid_611600
  var valid_611601 = header.getOrDefault("X-Amz-Date")
  valid_611601 = validateParameter(valid_611601, JString, required = false,
                                 default = nil)
  if valid_611601 != nil:
    section.add "X-Amz-Date", valid_611601
  var valid_611602 = header.getOrDefault("X-Amz-Credential")
  valid_611602 = validateParameter(valid_611602, JString, required = false,
                                 default = nil)
  if valid_611602 != nil:
    section.add "X-Amz-Credential", valid_611602
  var valid_611603 = header.getOrDefault("X-Amz-Security-Token")
  valid_611603 = validateParameter(valid_611603, JString, required = false,
                                 default = nil)
  if valid_611603 != nil:
    section.add "X-Amz-Security-Token", valid_611603
  var valid_611604 = header.getOrDefault("X-Amz-Algorithm")
  valid_611604 = validateParameter(valid_611604, JString, required = false,
                                 default = nil)
  if valid_611604 != nil:
    section.add "X-Amz-Algorithm", valid_611604
  var valid_611605 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611605 = validateParameter(valid_611605, JString, required = false,
                                 default = nil)
  if valid_611605 != nil:
    section.add "X-Amz-SignedHeaders", valid_611605
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611607: Call_DeregisterTaskFromMaintenanceWindow_611595;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Removes a task from a maintenance window.
  ## 
  let valid = call_611607.validator(path, query, header, formData, body)
  let scheme = call_611607.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611607.url(scheme.get, call_611607.host, call_611607.base,
                         call_611607.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611607, url, valid)

proc call*(call_611608: Call_DeregisterTaskFromMaintenanceWindow_611595;
          body: JsonNode): Recallable =
  ## deregisterTaskFromMaintenanceWindow
  ## Removes a task from a maintenance window.
  ##   body: JObject (required)
  var body_611609 = newJObject()
  if body != nil:
    body_611609 = body
  result = call_611608.call(nil, nil, nil, nil, body_611609)

var deregisterTaskFromMaintenanceWindow* = Call_DeregisterTaskFromMaintenanceWindow_611595(
    name: "deregisterTaskFromMaintenanceWindow", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DeregisterTaskFromMaintenanceWindow",
    validator: validate_DeregisterTaskFromMaintenanceWindow_611596, base: "/",
    url: url_DeregisterTaskFromMaintenanceWindow_611597,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeActivations_611610 = ref object of OpenApiRestCall_610658
proc url_DescribeActivations_611612(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeActivations_611611(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Describes details about the activation, such as the date and time the activation was created, its expiration date, the IAM role assigned to the instances in the activation, and the number of instances registered by using this activation.
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
  var valid_611613 = query.getOrDefault("MaxResults")
  valid_611613 = validateParameter(valid_611613, JString, required = false,
                                 default = nil)
  if valid_611613 != nil:
    section.add "MaxResults", valid_611613
  var valid_611614 = query.getOrDefault("NextToken")
  valid_611614 = validateParameter(valid_611614, JString, required = false,
                                 default = nil)
  if valid_611614 != nil:
    section.add "NextToken", valid_611614
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611615 = header.getOrDefault("X-Amz-Target")
  valid_611615 = validateParameter(valid_611615, JString, required = true, default = newJString(
      "AmazonSSM.DescribeActivations"))
  if valid_611615 != nil:
    section.add "X-Amz-Target", valid_611615
  var valid_611616 = header.getOrDefault("X-Amz-Signature")
  valid_611616 = validateParameter(valid_611616, JString, required = false,
                                 default = nil)
  if valid_611616 != nil:
    section.add "X-Amz-Signature", valid_611616
  var valid_611617 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611617 = validateParameter(valid_611617, JString, required = false,
                                 default = nil)
  if valid_611617 != nil:
    section.add "X-Amz-Content-Sha256", valid_611617
  var valid_611618 = header.getOrDefault("X-Amz-Date")
  valid_611618 = validateParameter(valid_611618, JString, required = false,
                                 default = nil)
  if valid_611618 != nil:
    section.add "X-Amz-Date", valid_611618
  var valid_611619 = header.getOrDefault("X-Amz-Credential")
  valid_611619 = validateParameter(valid_611619, JString, required = false,
                                 default = nil)
  if valid_611619 != nil:
    section.add "X-Amz-Credential", valid_611619
  var valid_611620 = header.getOrDefault("X-Amz-Security-Token")
  valid_611620 = validateParameter(valid_611620, JString, required = false,
                                 default = nil)
  if valid_611620 != nil:
    section.add "X-Amz-Security-Token", valid_611620
  var valid_611621 = header.getOrDefault("X-Amz-Algorithm")
  valid_611621 = validateParameter(valid_611621, JString, required = false,
                                 default = nil)
  if valid_611621 != nil:
    section.add "X-Amz-Algorithm", valid_611621
  var valid_611622 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611622 = validateParameter(valid_611622, JString, required = false,
                                 default = nil)
  if valid_611622 != nil:
    section.add "X-Amz-SignedHeaders", valid_611622
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611624: Call_DescribeActivations_611610; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes details about the activation, such as the date and time the activation was created, its expiration date, the IAM role assigned to the instances in the activation, and the number of instances registered by using this activation.
  ## 
  let valid = call_611624.validator(path, query, header, formData, body)
  let scheme = call_611624.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611624.url(scheme.get, call_611624.host, call_611624.base,
                         call_611624.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611624, url, valid)

proc call*(call_611625: Call_DescribeActivations_611610; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## describeActivations
  ## Describes details about the activation, such as the date and time the activation was created, its expiration date, the IAM role assigned to the instances in the activation, and the number of instances registered by using this activation.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_611626 = newJObject()
  var body_611627 = newJObject()
  add(query_611626, "MaxResults", newJString(MaxResults))
  add(query_611626, "NextToken", newJString(NextToken))
  if body != nil:
    body_611627 = body
  result = call_611625.call(nil, query_611626, nil, nil, body_611627)

var describeActivations* = Call_DescribeActivations_611610(
    name: "describeActivations", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeActivations",
    validator: validate_DescribeActivations_611611, base: "/",
    url: url_DescribeActivations_611612, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAssociation_611629 = ref object of OpenApiRestCall_610658
proc url_DescribeAssociation_611631(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeAssociation_611630(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611632 = header.getOrDefault("X-Amz-Target")
  valid_611632 = validateParameter(valid_611632, JString, required = true, default = newJString(
      "AmazonSSM.DescribeAssociation"))
  if valid_611632 != nil:
    section.add "X-Amz-Target", valid_611632
  var valid_611633 = header.getOrDefault("X-Amz-Signature")
  valid_611633 = validateParameter(valid_611633, JString, required = false,
                                 default = nil)
  if valid_611633 != nil:
    section.add "X-Amz-Signature", valid_611633
  var valid_611634 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611634 = validateParameter(valid_611634, JString, required = false,
                                 default = nil)
  if valid_611634 != nil:
    section.add "X-Amz-Content-Sha256", valid_611634
  var valid_611635 = header.getOrDefault("X-Amz-Date")
  valid_611635 = validateParameter(valid_611635, JString, required = false,
                                 default = nil)
  if valid_611635 != nil:
    section.add "X-Amz-Date", valid_611635
  var valid_611636 = header.getOrDefault("X-Amz-Credential")
  valid_611636 = validateParameter(valid_611636, JString, required = false,
                                 default = nil)
  if valid_611636 != nil:
    section.add "X-Amz-Credential", valid_611636
  var valid_611637 = header.getOrDefault("X-Amz-Security-Token")
  valid_611637 = validateParameter(valid_611637, JString, required = false,
                                 default = nil)
  if valid_611637 != nil:
    section.add "X-Amz-Security-Token", valid_611637
  var valid_611638 = header.getOrDefault("X-Amz-Algorithm")
  valid_611638 = validateParameter(valid_611638, JString, required = false,
                                 default = nil)
  if valid_611638 != nil:
    section.add "X-Amz-Algorithm", valid_611638
  var valid_611639 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611639 = validateParameter(valid_611639, JString, required = false,
                                 default = nil)
  if valid_611639 != nil:
    section.add "X-Amz-SignedHeaders", valid_611639
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611641: Call_DescribeAssociation_611629; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the association for the specified target or instance. If you created the association by using the <code>Targets</code> parameter, then you must retrieve the association by using the association ID. If you created the association by specifying an instance ID and a Systems Manager document, then you retrieve the association by specifying the document name and the instance ID. 
  ## 
  let valid = call_611641.validator(path, query, header, formData, body)
  let scheme = call_611641.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611641.url(scheme.get, call_611641.host, call_611641.base,
                         call_611641.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611641, url, valid)

proc call*(call_611642: Call_DescribeAssociation_611629; body: JsonNode): Recallable =
  ## describeAssociation
  ## Describes the association for the specified target or instance. If you created the association by using the <code>Targets</code> parameter, then you must retrieve the association by using the association ID. If you created the association by specifying an instance ID and a Systems Manager document, then you retrieve the association by specifying the document name and the instance ID. 
  ##   body: JObject (required)
  var body_611643 = newJObject()
  if body != nil:
    body_611643 = body
  result = call_611642.call(nil, nil, nil, nil, body_611643)

var describeAssociation* = Call_DescribeAssociation_611629(
    name: "describeAssociation", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeAssociation",
    validator: validate_DescribeAssociation_611630, base: "/",
    url: url_DescribeAssociation_611631, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAssociationExecutionTargets_611644 = ref object of OpenApiRestCall_610658
proc url_DescribeAssociationExecutionTargets_611646(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeAssociationExecutionTargets_611645(path: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611647 = header.getOrDefault("X-Amz-Target")
  valid_611647 = validateParameter(valid_611647, JString, required = true, default = newJString(
      "AmazonSSM.DescribeAssociationExecutionTargets"))
  if valid_611647 != nil:
    section.add "X-Amz-Target", valid_611647
  var valid_611648 = header.getOrDefault("X-Amz-Signature")
  valid_611648 = validateParameter(valid_611648, JString, required = false,
                                 default = nil)
  if valid_611648 != nil:
    section.add "X-Amz-Signature", valid_611648
  var valid_611649 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611649 = validateParameter(valid_611649, JString, required = false,
                                 default = nil)
  if valid_611649 != nil:
    section.add "X-Amz-Content-Sha256", valid_611649
  var valid_611650 = header.getOrDefault("X-Amz-Date")
  valid_611650 = validateParameter(valid_611650, JString, required = false,
                                 default = nil)
  if valid_611650 != nil:
    section.add "X-Amz-Date", valid_611650
  var valid_611651 = header.getOrDefault("X-Amz-Credential")
  valid_611651 = validateParameter(valid_611651, JString, required = false,
                                 default = nil)
  if valid_611651 != nil:
    section.add "X-Amz-Credential", valid_611651
  var valid_611652 = header.getOrDefault("X-Amz-Security-Token")
  valid_611652 = validateParameter(valid_611652, JString, required = false,
                                 default = nil)
  if valid_611652 != nil:
    section.add "X-Amz-Security-Token", valid_611652
  var valid_611653 = header.getOrDefault("X-Amz-Algorithm")
  valid_611653 = validateParameter(valid_611653, JString, required = false,
                                 default = nil)
  if valid_611653 != nil:
    section.add "X-Amz-Algorithm", valid_611653
  var valid_611654 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611654 = validateParameter(valid_611654, JString, required = false,
                                 default = nil)
  if valid_611654 != nil:
    section.add "X-Amz-SignedHeaders", valid_611654
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611656: Call_DescribeAssociationExecutionTargets_611644;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Use this API action to view information about a specific execution of a specific association.
  ## 
  let valid = call_611656.validator(path, query, header, formData, body)
  let scheme = call_611656.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611656.url(scheme.get, call_611656.host, call_611656.base,
                         call_611656.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611656, url, valid)

proc call*(call_611657: Call_DescribeAssociationExecutionTargets_611644;
          body: JsonNode): Recallable =
  ## describeAssociationExecutionTargets
  ## Use this API action to view information about a specific execution of a specific association.
  ##   body: JObject (required)
  var body_611658 = newJObject()
  if body != nil:
    body_611658 = body
  result = call_611657.call(nil, nil, nil, nil, body_611658)

var describeAssociationExecutionTargets* = Call_DescribeAssociationExecutionTargets_611644(
    name: "describeAssociationExecutionTargets", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeAssociationExecutionTargets",
    validator: validate_DescribeAssociationExecutionTargets_611645, base: "/",
    url: url_DescribeAssociationExecutionTargets_611646,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAssociationExecutions_611659 = ref object of OpenApiRestCall_610658
proc url_DescribeAssociationExecutions_611661(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeAssociationExecutions_611660(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611662 = header.getOrDefault("X-Amz-Target")
  valid_611662 = validateParameter(valid_611662, JString, required = true, default = newJString(
      "AmazonSSM.DescribeAssociationExecutions"))
  if valid_611662 != nil:
    section.add "X-Amz-Target", valid_611662
  var valid_611663 = header.getOrDefault("X-Amz-Signature")
  valid_611663 = validateParameter(valid_611663, JString, required = false,
                                 default = nil)
  if valid_611663 != nil:
    section.add "X-Amz-Signature", valid_611663
  var valid_611664 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611664 = validateParameter(valid_611664, JString, required = false,
                                 default = nil)
  if valid_611664 != nil:
    section.add "X-Amz-Content-Sha256", valid_611664
  var valid_611665 = header.getOrDefault("X-Amz-Date")
  valid_611665 = validateParameter(valid_611665, JString, required = false,
                                 default = nil)
  if valid_611665 != nil:
    section.add "X-Amz-Date", valid_611665
  var valid_611666 = header.getOrDefault("X-Amz-Credential")
  valid_611666 = validateParameter(valid_611666, JString, required = false,
                                 default = nil)
  if valid_611666 != nil:
    section.add "X-Amz-Credential", valid_611666
  var valid_611667 = header.getOrDefault("X-Amz-Security-Token")
  valid_611667 = validateParameter(valid_611667, JString, required = false,
                                 default = nil)
  if valid_611667 != nil:
    section.add "X-Amz-Security-Token", valid_611667
  var valid_611668 = header.getOrDefault("X-Amz-Algorithm")
  valid_611668 = validateParameter(valid_611668, JString, required = false,
                                 default = nil)
  if valid_611668 != nil:
    section.add "X-Amz-Algorithm", valid_611668
  var valid_611669 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611669 = validateParameter(valid_611669, JString, required = false,
                                 default = nil)
  if valid_611669 != nil:
    section.add "X-Amz-SignedHeaders", valid_611669
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611671: Call_DescribeAssociationExecutions_611659; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Use this API action to view all executions for a specific association ID. 
  ## 
  let valid = call_611671.validator(path, query, header, formData, body)
  let scheme = call_611671.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611671.url(scheme.get, call_611671.host, call_611671.base,
                         call_611671.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611671, url, valid)

proc call*(call_611672: Call_DescribeAssociationExecutions_611659; body: JsonNode): Recallable =
  ## describeAssociationExecutions
  ## Use this API action to view all executions for a specific association ID. 
  ##   body: JObject (required)
  var body_611673 = newJObject()
  if body != nil:
    body_611673 = body
  result = call_611672.call(nil, nil, nil, nil, body_611673)

var describeAssociationExecutions* = Call_DescribeAssociationExecutions_611659(
    name: "describeAssociationExecutions", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeAssociationExecutions",
    validator: validate_DescribeAssociationExecutions_611660, base: "/",
    url: url_DescribeAssociationExecutions_611661,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAutomationExecutions_611674 = ref object of OpenApiRestCall_610658
proc url_DescribeAutomationExecutions_611676(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeAutomationExecutions_611675(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611677 = header.getOrDefault("X-Amz-Target")
  valid_611677 = validateParameter(valid_611677, JString, required = true, default = newJString(
      "AmazonSSM.DescribeAutomationExecutions"))
  if valid_611677 != nil:
    section.add "X-Amz-Target", valid_611677
  var valid_611678 = header.getOrDefault("X-Amz-Signature")
  valid_611678 = validateParameter(valid_611678, JString, required = false,
                                 default = nil)
  if valid_611678 != nil:
    section.add "X-Amz-Signature", valid_611678
  var valid_611679 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611679 = validateParameter(valid_611679, JString, required = false,
                                 default = nil)
  if valid_611679 != nil:
    section.add "X-Amz-Content-Sha256", valid_611679
  var valid_611680 = header.getOrDefault("X-Amz-Date")
  valid_611680 = validateParameter(valid_611680, JString, required = false,
                                 default = nil)
  if valid_611680 != nil:
    section.add "X-Amz-Date", valid_611680
  var valid_611681 = header.getOrDefault("X-Amz-Credential")
  valid_611681 = validateParameter(valid_611681, JString, required = false,
                                 default = nil)
  if valid_611681 != nil:
    section.add "X-Amz-Credential", valid_611681
  var valid_611682 = header.getOrDefault("X-Amz-Security-Token")
  valid_611682 = validateParameter(valid_611682, JString, required = false,
                                 default = nil)
  if valid_611682 != nil:
    section.add "X-Amz-Security-Token", valid_611682
  var valid_611683 = header.getOrDefault("X-Amz-Algorithm")
  valid_611683 = validateParameter(valid_611683, JString, required = false,
                                 default = nil)
  if valid_611683 != nil:
    section.add "X-Amz-Algorithm", valid_611683
  var valid_611684 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611684 = validateParameter(valid_611684, JString, required = false,
                                 default = nil)
  if valid_611684 != nil:
    section.add "X-Amz-SignedHeaders", valid_611684
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611686: Call_DescribeAutomationExecutions_611674; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provides details about all active and terminated Automation executions.
  ## 
  let valid = call_611686.validator(path, query, header, formData, body)
  let scheme = call_611686.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611686.url(scheme.get, call_611686.host, call_611686.base,
                         call_611686.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611686, url, valid)

proc call*(call_611687: Call_DescribeAutomationExecutions_611674; body: JsonNode): Recallable =
  ## describeAutomationExecutions
  ## Provides details about all active and terminated Automation executions.
  ##   body: JObject (required)
  var body_611688 = newJObject()
  if body != nil:
    body_611688 = body
  result = call_611687.call(nil, nil, nil, nil, body_611688)

var describeAutomationExecutions* = Call_DescribeAutomationExecutions_611674(
    name: "describeAutomationExecutions", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeAutomationExecutions",
    validator: validate_DescribeAutomationExecutions_611675, base: "/",
    url: url_DescribeAutomationExecutions_611676,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAutomationStepExecutions_611689 = ref object of OpenApiRestCall_610658
proc url_DescribeAutomationStepExecutions_611691(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeAutomationStepExecutions_611690(path: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611692 = header.getOrDefault("X-Amz-Target")
  valid_611692 = validateParameter(valid_611692, JString, required = true, default = newJString(
      "AmazonSSM.DescribeAutomationStepExecutions"))
  if valid_611692 != nil:
    section.add "X-Amz-Target", valid_611692
  var valid_611693 = header.getOrDefault("X-Amz-Signature")
  valid_611693 = validateParameter(valid_611693, JString, required = false,
                                 default = nil)
  if valid_611693 != nil:
    section.add "X-Amz-Signature", valid_611693
  var valid_611694 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611694 = validateParameter(valid_611694, JString, required = false,
                                 default = nil)
  if valid_611694 != nil:
    section.add "X-Amz-Content-Sha256", valid_611694
  var valid_611695 = header.getOrDefault("X-Amz-Date")
  valid_611695 = validateParameter(valid_611695, JString, required = false,
                                 default = nil)
  if valid_611695 != nil:
    section.add "X-Amz-Date", valid_611695
  var valid_611696 = header.getOrDefault("X-Amz-Credential")
  valid_611696 = validateParameter(valid_611696, JString, required = false,
                                 default = nil)
  if valid_611696 != nil:
    section.add "X-Amz-Credential", valid_611696
  var valid_611697 = header.getOrDefault("X-Amz-Security-Token")
  valid_611697 = validateParameter(valid_611697, JString, required = false,
                                 default = nil)
  if valid_611697 != nil:
    section.add "X-Amz-Security-Token", valid_611697
  var valid_611698 = header.getOrDefault("X-Amz-Algorithm")
  valid_611698 = validateParameter(valid_611698, JString, required = false,
                                 default = nil)
  if valid_611698 != nil:
    section.add "X-Amz-Algorithm", valid_611698
  var valid_611699 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611699 = validateParameter(valid_611699, JString, required = false,
                                 default = nil)
  if valid_611699 != nil:
    section.add "X-Amz-SignedHeaders", valid_611699
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611701: Call_DescribeAutomationStepExecutions_611689;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Information about all active and terminated step executions in an Automation workflow.
  ## 
  let valid = call_611701.validator(path, query, header, formData, body)
  let scheme = call_611701.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611701.url(scheme.get, call_611701.host, call_611701.base,
                         call_611701.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611701, url, valid)

proc call*(call_611702: Call_DescribeAutomationStepExecutions_611689;
          body: JsonNode): Recallable =
  ## describeAutomationStepExecutions
  ## Information about all active and terminated step executions in an Automation workflow.
  ##   body: JObject (required)
  var body_611703 = newJObject()
  if body != nil:
    body_611703 = body
  result = call_611702.call(nil, nil, nil, nil, body_611703)

var describeAutomationStepExecutions* = Call_DescribeAutomationStepExecutions_611689(
    name: "describeAutomationStepExecutions", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeAutomationStepExecutions",
    validator: validate_DescribeAutomationStepExecutions_611690, base: "/",
    url: url_DescribeAutomationStepExecutions_611691,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAvailablePatches_611704 = ref object of OpenApiRestCall_610658
proc url_DescribeAvailablePatches_611706(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeAvailablePatches_611705(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611707 = header.getOrDefault("X-Amz-Target")
  valid_611707 = validateParameter(valid_611707, JString, required = true, default = newJString(
      "AmazonSSM.DescribeAvailablePatches"))
  if valid_611707 != nil:
    section.add "X-Amz-Target", valid_611707
  var valid_611708 = header.getOrDefault("X-Amz-Signature")
  valid_611708 = validateParameter(valid_611708, JString, required = false,
                                 default = nil)
  if valid_611708 != nil:
    section.add "X-Amz-Signature", valid_611708
  var valid_611709 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611709 = validateParameter(valid_611709, JString, required = false,
                                 default = nil)
  if valid_611709 != nil:
    section.add "X-Amz-Content-Sha256", valid_611709
  var valid_611710 = header.getOrDefault("X-Amz-Date")
  valid_611710 = validateParameter(valid_611710, JString, required = false,
                                 default = nil)
  if valid_611710 != nil:
    section.add "X-Amz-Date", valid_611710
  var valid_611711 = header.getOrDefault("X-Amz-Credential")
  valid_611711 = validateParameter(valid_611711, JString, required = false,
                                 default = nil)
  if valid_611711 != nil:
    section.add "X-Amz-Credential", valid_611711
  var valid_611712 = header.getOrDefault("X-Amz-Security-Token")
  valid_611712 = validateParameter(valid_611712, JString, required = false,
                                 default = nil)
  if valid_611712 != nil:
    section.add "X-Amz-Security-Token", valid_611712
  var valid_611713 = header.getOrDefault("X-Amz-Algorithm")
  valid_611713 = validateParameter(valid_611713, JString, required = false,
                                 default = nil)
  if valid_611713 != nil:
    section.add "X-Amz-Algorithm", valid_611713
  var valid_611714 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611714 = validateParameter(valid_611714, JString, required = false,
                                 default = nil)
  if valid_611714 != nil:
    section.add "X-Amz-SignedHeaders", valid_611714
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611716: Call_DescribeAvailablePatches_611704; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all patches eligible to be included in a patch baseline.
  ## 
  let valid = call_611716.validator(path, query, header, formData, body)
  let scheme = call_611716.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611716.url(scheme.get, call_611716.host, call_611716.base,
                         call_611716.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611716, url, valid)

proc call*(call_611717: Call_DescribeAvailablePatches_611704; body: JsonNode): Recallable =
  ## describeAvailablePatches
  ## Lists all patches eligible to be included in a patch baseline.
  ##   body: JObject (required)
  var body_611718 = newJObject()
  if body != nil:
    body_611718 = body
  result = call_611717.call(nil, nil, nil, nil, body_611718)

var describeAvailablePatches* = Call_DescribeAvailablePatches_611704(
    name: "describeAvailablePatches", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeAvailablePatches",
    validator: validate_DescribeAvailablePatches_611705, base: "/",
    url: url_DescribeAvailablePatches_611706, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDocument_611719 = ref object of OpenApiRestCall_610658
proc url_DescribeDocument_611721(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeDocument_611720(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611722 = header.getOrDefault("X-Amz-Target")
  valid_611722 = validateParameter(valid_611722, JString, required = true, default = newJString(
      "AmazonSSM.DescribeDocument"))
  if valid_611722 != nil:
    section.add "X-Amz-Target", valid_611722
  var valid_611723 = header.getOrDefault("X-Amz-Signature")
  valid_611723 = validateParameter(valid_611723, JString, required = false,
                                 default = nil)
  if valid_611723 != nil:
    section.add "X-Amz-Signature", valid_611723
  var valid_611724 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611724 = validateParameter(valid_611724, JString, required = false,
                                 default = nil)
  if valid_611724 != nil:
    section.add "X-Amz-Content-Sha256", valid_611724
  var valid_611725 = header.getOrDefault("X-Amz-Date")
  valid_611725 = validateParameter(valid_611725, JString, required = false,
                                 default = nil)
  if valid_611725 != nil:
    section.add "X-Amz-Date", valid_611725
  var valid_611726 = header.getOrDefault("X-Amz-Credential")
  valid_611726 = validateParameter(valid_611726, JString, required = false,
                                 default = nil)
  if valid_611726 != nil:
    section.add "X-Amz-Credential", valid_611726
  var valid_611727 = header.getOrDefault("X-Amz-Security-Token")
  valid_611727 = validateParameter(valid_611727, JString, required = false,
                                 default = nil)
  if valid_611727 != nil:
    section.add "X-Amz-Security-Token", valid_611727
  var valid_611728 = header.getOrDefault("X-Amz-Algorithm")
  valid_611728 = validateParameter(valid_611728, JString, required = false,
                                 default = nil)
  if valid_611728 != nil:
    section.add "X-Amz-Algorithm", valid_611728
  var valid_611729 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611729 = validateParameter(valid_611729, JString, required = false,
                                 default = nil)
  if valid_611729 != nil:
    section.add "X-Amz-SignedHeaders", valid_611729
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611731: Call_DescribeDocument_611719; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the specified Systems Manager document.
  ## 
  let valid = call_611731.validator(path, query, header, formData, body)
  let scheme = call_611731.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611731.url(scheme.get, call_611731.host, call_611731.base,
                         call_611731.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611731, url, valid)

proc call*(call_611732: Call_DescribeDocument_611719; body: JsonNode): Recallable =
  ## describeDocument
  ## Describes the specified Systems Manager document.
  ##   body: JObject (required)
  var body_611733 = newJObject()
  if body != nil:
    body_611733 = body
  result = call_611732.call(nil, nil, nil, nil, body_611733)

var describeDocument* = Call_DescribeDocument_611719(name: "describeDocument",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeDocument",
    validator: validate_DescribeDocument_611720, base: "/",
    url: url_DescribeDocument_611721, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDocumentPermission_611734 = ref object of OpenApiRestCall_610658
proc url_DescribeDocumentPermission_611736(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeDocumentPermission_611735(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611737 = header.getOrDefault("X-Amz-Target")
  valid_611737 = validateParameter(valid_611737, JString, required = true, default = newJString(
      "AmazonSSM.DescribeDocumentPermission"))
  if valid_611737 != nil:
    section.add "X-Amz-Target", valid_611737
  var valid_611738 = header.getOrDefault("X-Amz-Signature")
  valid_611738 = validateParameter(valid_611738, JString, required = false,
                                 default = nil)
  if valid_611738 != nil:
    section.add "X-Amz-Signature", valid_611738
  var valid_611739 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611739 = validateParameter(valid_611739, JString, required = false,
                                 default = nil)
  if valid_611739 != nil:
    section.add "X-Amz-Content-Sha256", valid_611739
  var valid_611740 = header.getOrDefault("X-Amz-Date")
  valid_611740 = validateParameter(valid_611740, JString, required = false,
                                 default = nil)
  if valid_611740 != nil:
    section.add "X-Amz-Date", valid_611740
  var valid_611741 = header.getOrDefault("X-Amz-Credential")
  valid_611741 = validateParameter(valid_611741, JString, required = false,
                                 default = nil)
  if valid_611741 != nil:
    section.add "X-Amz-Credential", valid_611741
  var valid_611742 = header.getOrDefault("X-Amz-Security-Token")
  valid_611742 = validateParameter(valid_611742, JString, required = false,
                                 default = nil)
  if valid_611742 != nil:
    section.add "X-Amz-Security-Token", valid_611742
  var valid_611743 = header.getOrDefault("X-Amz-Algorithm")
  valid_611743 = validateParameter(valid_611743, JString, required = false,
                                 default = nil)
  if valid_611743 != nil:
    section.add "X-Amz-Algorithm", valid_611743
  var valid_611744 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611744 = validateParameter(valid_611744, JString, required = false,
                                 default = nil)
  if valid_611744 != nil:
    section.add "X-Amz-SignedHeaders", valid_611744
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611746: Call_DescribeDocumentPermission_611734; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the permissions for a Systems Manager document. If you created the document, you are the owner. If a document is shared, it can either be shared privately (by specifying a user's AWS account ID) or publicly (<i>All</i>). 
  ## 
  let valid = call_611746.validator(path, query, header, formData, body)
  let scheme = call_611746.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611746.url(scheme.get, call_611746.host, call_611746.base,
                         call_611746.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611746, url, valid)

proc call*(call_611747: Call_DescribeDocumentPermission_611734; body: JsonNode): Recallable =
  ## describeDocumentPermission
  ## Describes the permissions for a Systems Manager document. If you created the document, you are the owner. If a document is shared, it can either be shared privately (by specifying a user's AWS account ID) or publicly (<i>All</i>). 
  ##   body: JObject (required)
  var body_611748 = newJObject()
  if body != nil:
    body_611748 = body
  result = call_611747.call(nil, nil, nil, nil, body_611748)

var describeDocumentPermission* = Call_DescribeDocumentPermission_611734(
    name: "describeDocumentPermission", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeDocumentPermission",
    validator: validate_DescribeDocumentPermission_611735, base: "/",
    url: url_DescribeDocumentPermission_611736,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEffectiveInstanceAssociations_611749 = ref object of OpenApiRestCall_610658
proc url_DescribeEffectiveInstanceAssociations_611751(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeEffectiveInstanceAssociations_611750(path: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611752 = header.getOrDefault("X-Amz-Target")
  valid_611752 = validateParameter(valid_611752, JString, required = true, default = newJString(
      "AmazonSSM.DescribeEffectiveInstanceAssociations"))
  if valid_611752 != nil:
    section.add "X-Amz-Target", valid_611752
  var valid_611753 = header.getOrDefault("X-Amz-Signature")
  valid_611753 = validateParameter(valid_611753, JString, required = false,
                                 default = nil)
  if valid_611753 != nil:
    section.add "X-Amz-Signature", valid_611753
  var valid_611754 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611754 = validateParameter(valid_611754, JString, required = false,
                                 default = nil)
  if valid_611754 != nil:
    section.add "X-Amz-Content-Sha256", valid_611754
  var valid_611755 = header.getOrDefault("X-Amz-Date")
  valid_611755 = validateParameter(valid_611755, JString, required = false,
                                 default = nil)
  if valid_611755 != nil:
    section.add "X-Amz-Date", valid_611755
  var valid_611756 = header.getOrDefault("X-Amz-Credential")
  valid_611756 = validateParameter(valid_611756, JString, required = false,
                                 default = nil)
  if valid_611756 != nil:
    section.add "X-Amz-Credential", valid_611756
  var valid_611757 = header.getOrDefault("X-Amz-Security-Token")
  valid_611757 = validateParameter(valid_611757, JString, required = false,
                                 default = nil)
  if valid_611757 != nil:
    section.add "X-Amz-Security-Token", valid_611757
  var valid_611758 = header.getOrDefault("X-Amz-Algorithm")
  valid_611758 = validateParameter(valid_611758, JString, required = false,
                                 default = nil)
  if valid_611758 != nil:
    section.add "X-Amz-Algorithm", valid_611758
  var valid_611759 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611759 = validateParameter(valid_611759, JString, required = false,
                                 default = nil)
  if valid_611759 != nil:
    section.add "X-Amz-SignedHeaders", valid_611759
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611761: Call_DescribeEffectiveInstanceAssociations_611749;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## All associations for the instance(s).
  ## 
  let valid = call_611761.validator(path, query, header, formData, body)
  let scheme = call_611761.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611761.url(scheme.get, call_611761.host, call_611761.base,
                         call_611761.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611761, url, valid)

proc call*(call_611762: Call_DescribeEffectiveInstanceAssociations_611749;
          body: JsonNode): Recallable =
  ## describeEffectiveInstanceAssociations
  ## All associations for the instance(s).
  ##   body: JObject (required)
  var body_611763 = newJObject()
  if body != nil:
    body_611763 = body
  result = call_611762.call(nil, nil, nil, nil, body_611763)

var describeEffectiveInstanceAssociations* = Call_DescribeEffectiveInstanceAssociations_611749(
    name: "describeEffectiveInstanceAssociations", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeEffectiveInstanceAssociations",
    validator: validate_DescribeEffectiveInstanceAssociations_611750, base: "/",
    url: url_DescribeEffectiveInstanceAssociations_611751,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEffectivePatchesForPatchBaseline_611764 = ref object of OpenApiRestCall_610658
proc url_DescribeEffectivePatchesForPatchBaseline_611766(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeEffectivePatchesForPatchBaseline_611765(path: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611767 = header.getOrDefault("X-Amz-Target")
  valid_611767 = validateParameter(valid_611767, JString, required = true, default = newJString(
      "AmazonSSM.DescribeEffectivePatchesForPatchBaseline"))
  if valid_611767 != nil:
    section.add "X-Amz-Target", valid_611767
  var valid_611768 = header.getOrDefault("X-Amz-Signature")
  valid_611768 = validateParameter(valid_611768, JString, required = false,
                                 default = nil)
  if valid_611768 != nil:
    section.add "X-Amz-Signature", valid_611768
  var valid_611769 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611769 = validateParameter(valid_611769, JString, required = false,
                                 default = nil)
  if valid_611769 != nil:
    section.add "X-Amz-Content-Sha256", valid_611769
  var valid_611770 = header.getOrDefault("X-Amz-Date")
  valid_611770 = validateParameter(valid_611770, JString, required = false,
                                 default = nil)
  if valid_611770 != nil:
    section.add "X-Amz-Date", valid_611770
  var valid_611771 = header.getOrDefault("X-Amz-Credential")
  valid_611771 = validateParameter(valid_611771, JString, required = false,
                                 default = nil)
  if valid_611771 != nil:
    section.add "X-Amz-Credential", valid_611771
  var valid_611772 = header.getOrDefault("X-Amz-Security-Token")
  valid_611772 = validateParameter(valid_611772, JString, required = false,
                                 default = nil)
  if valid_611772 != nil:
    section.add "X-Amz-Security-Token", valid_611772
  var valid_611773 = header.getOrDefault("X-Amz-Algorithm")
  valid_611773 = validateParameter(valid_611773, JString, required = false,
                                 default = nil)
  if valid_611773 != nil:
    section.add "X-Amz-Algorithm", valid_611773
  var valid_611774 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611774 = validateParameter(valid_611774, JString, required = false,
                                 default = nil)
  if valid_611774 != nil:
    section.add "X-Amz-SignedHeaders", valid_611774
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611776: Call_DescribeEffectivePatchesForPatchBaseline_611764;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves the current effective patches (the patch and the approval state) for the specified patch baseline. Note that this API applies only to Windows patch baselines.
  ## 
  let valid = call_611776.validator(path, query, header, formData, body)
  let scheme = call_611776.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611776.url(scheme.get, call_611776.host, call_611776.base,
                         call_611776.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611776, url, valid)

proc call*(call_611777: Call_DescribeEffectivePatchesForPatchBaseline_611764;
          body: JsonNode): Recallable =
  ## describeEffectivePatchesForPatchBaseline
  ## Retrieves the current effective patches (the patch and the approval state) for the specified patch baseline. Note that this API applies only to Windows patch baselines.
  ##   body: JObject (required)
  var body_611778 = newJObject()
  if body != nil:
    body_611778 = body
  result = call_611777.call(nil, nil, nil, nil, body_611778)

var describeEffectivePatchesForPatchBaseline* = Call_DescribeEffectivePatchesForPatchBaseline_611764(
    name: "describeEffectivePatchesForPatchBaseline", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeEffectivePatchesForPatchBaseline",
    validator: validate_DescribeEffectivePatchesForPatchBaseline_611765,
    base: "/", url: url_DescribeEffectivePatchesForPatchBaseline_611766,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeInstanceAssociationsStatus_611779 = ref object of OpenApiRestCall_610658
proc url_DescribeInstanceAssociationsStatus_611781(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeInstanceAssociationsStatus_611780(path: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611782 = header.getOrDefault("X-Amz-Target")
  valid_611782 = validateParameter(valid_611782, JString, required = true, default = newJString(
      "AmazonSSM.DescribeInstanceAssociationsStatus"))
  if valid_611782 != nil:
    section.add "X-Amz-Target", valid_611782
  var valid_611783 = header.getOrDefault("X-Amz-Signature")
  valid_611783 = validateParameter(valid_611783, JString, required = false,
                                 default = nil)
  if valid_611783 != nil:
    section.add "X-Amz-Signature", valid_611783
  var valid_611784 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611784 = validateParameter(valid_611784, JString, required = false,
                                 default = nil)
  if valid_611784 != nil:
    section.add "X-Amz-Content-Sha256", valid_611784
  var valid_611785 = header.getOrDefault("X-Amz-Date")
  valid_611785 = validateParameter(valid_611785, JString, required = false,
                                 default = nil)
  if valid_611785 != nil:
    section.add "X-Amz-Date", valid_611785
  var valid_611786 = header.getOrDefault("X-Amz-Credential")
  valid_611786 = validateParameter(valid_611786, JString, required = false,
                                 default = nil)
  if valid_611786 != nil:
    section.add "X-Amz-Credential", valid_611786
  var valid_611787 = header.getOrDefault("X-Amz-Security-Token")
  valid_611787 = validateParameter(valid_611787, JString, required = false,
                                 default = nil)
  if valid_611787 != nil:
    section.add "X-Amz-Security-Token", valid_611787
  var valid_611788 = header.getOrDefault("X-Amz-Algorithm")
  valid_611788 = validateParameter(valid_611788, JString, required = false,
                                 default = nil)
  if valid_611788 != nil:
    section.add "X-Amz-Algorithm", valid_611788
  var valid_611789 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611789 = validateParameter(valid_611789, JString, required = false,
                                 default = nil)
  if valid_611789 != nil:
    section.add "X-Amz-SignedHeaders", valid_611789
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611791: Call_DescribeInstanceAssociationsStatus_611779;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## The status of the associations for the instance(s).
  ## 
  let valid = call_611791.validator(path, query, header, formData, body)
  let scheme = call_611791.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611791.url(scheme.get, call_611791.host, call_611791.base,
                         call_611791.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611791, url, valid)

proc call*(call_611792: Call_DescribeInstanceAssociationsStatus_611779;
          body: JsonNode): Recallable =
  ## describeInstanceAssociationsStatus
  ## The status of the associations for the instance(s).
  ##   body: JObject (required)
  var body_611793 = newJObject()
  if body != nil:
    body_611793 = body
  result = call_611792.call(nil, nil, nil, nil, body_611793)

var describeInstanceAssociationsStatus* = Call_DescribeInstanceAssociationsStatus_611779(
    name: "describeInstanceAssociationsStatus", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeInstanceAssociationsStatus",
    validator: validate_DescribeInstanceAssociationsStatus_611780, base: "/",
    url: url_DescribeInstanceAssociationsStatus_611781,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeInstanceInformation_611794 = ref object of OpenApiRestCall_610658
proc url_DescribeInstanceInformation_611796(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeInstanceInformation_611795(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Describes one or more of your instances. You can use this to get information about instances like the operating system platform, the SSM Agent version (Linux), status etc. If you specify one or more instance IDs, it returns information for those instances. If you do not specify instance IDs, it returns information for all your instances. If you specify an instance ID that is not valid or an instance that you do not own, you receive an error. </p> <note> <p>The IamRole field for this API action is the Amazon Identity and Access Management (IAM) role assigned to on-premises instances. This call does not return the IAM role for Amazon EC2 instances.</p> </note>
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
  var valid_611797 = query.getOrDefault("MaxResults")
  valid_611797 = validateParameter(valid_611797, JString, required = false,
                                 default = nil)
  if valid_611797 != nil:
    section.add "MaxResults", valid_611797
  var valid_611798 = query.getOrDefault("NextToken")
  valid_611798 = validateParameter(valid_611798, JString, required = false,
                                 default = nil)
  if valid_611798 != nil:
    section.add "NextToken", valid_611798
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611799 = header.getOrDefault("X-Amz-Target")
  valid_611799 = validateParameter(valid_611799, JString, required = true, default = newJString(
      "AmazonSSM.DescribeInstanceInformation"))
  if valid_611799 != nil:
    section.add "X-Amz-Target", valid_611799
  var valid_611800 = header.getOrDefault("X-Amz-Signature")
  valid_611800 = validateParameter(valid_611800, JString, required = false,
                                 default = nil)
  if valid_611800 != nil:
    section.add "X-Amz-Signature", valid_611800
  var valid_611801 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611801 = validateParameter(valid_611801, JString, required = false,
                                 default = nil)
  if valid_611801 != nil:
    section.add "X-Amz-Content-Sha256", valid_611801
  var valid_611802 = header.getOrDefault("X-Amz-Date")
  valid_611802 = validateParameter(valid_611802, JString, required = false,
                                 default = nil)
  if valid_611802 != nil:
    section.add "X-Amz-Date", valid_611802
  var valid_611803 = header.getOrDefault("X-Amz-Credential")
  valid_611803 = validateParameter(valid_611803, JString, required = false,
                                 default = nil)
  if valid_611803 != nil:
    section.add "X-Amz-Credential", valid_611803
  var valid_611804 = header.getOrDefault("X-Amz-Security-Token")
  valid_611804 = validateParameter(valid_611804, JString, required = false,
                                 default = nil)
  if valid_611804 != nil:
    section.add "X-Amz-Security-Token", valid_611804
  var valid_611805 = header.getOrDefault("X-Amz-Algorithm")
  valid_611805 = validateParameter(valid_611805, JString, required = false,
                                 default = nil)
  if valid_611805 != nil:
    section.add "X-Amz-Algorithm", valid_611805
  var valid_611806 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611806 = validateParameter(valid_611806, JString, required = false,
                                 default = nil)
  if valid_611806 != nil:
    section.add "X-Amz-SignedHeaders", valid_611806
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611808: Call_DescribeInstanceInformation_611794; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes one or more of your instances. You can use this to get information about instances like the operating system platform, the SSM Agent version (Linux), status etc. If you specify one or more instance IDs, it returns information for those instances. If you do not specify instance IDs, it returns information for all your instances. If you specify an instance ID that is not valid or an instance that you do not own, you receive an error. </p> <note> <p>The IamRole field for this API action is the Amazon Identity and Access Management (IAM) role assigned to on-premises instances. This call does not return the IAM role for Amazon EC2 instances.</p> </note>
  ## 
  let valid = call_611808.validator(path, query, header, formData, body)
  let scheme = call_611808.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611808.url(scheme.get, call_611808.host, call_611808.base,
                         call_611808.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611808, url, valid)

proc call*(call_611809: Call_DescribeInstanceInformation_611794; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## describeInstanceInformation
  ## <p>Describes one or more of your instances. You can use this to get information about instances like the operating system platform, the SSM Agent version (Linux), status etc. If you specify one or more instance IDs, it returns information for those instances. If you do not specify instance IDs, it returns information for all your instances. If you specify an instance ID that is not valid or an instance that you do not own, you receive an error. </p> <note> <p>The IamRole field for this API action is the Amazon Identity and Access Management (IAM) role assigned to on-premises instances. This call does not return the IAM role for Amazon EC2 instances.</p> </note>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_611810 = newJObject()
  var body_611811 = newJObject()
  add(query_611810, "MaxResults", newJString(MaxResults))
  add(query_611810, "NextToken", newJString(NextToken))
  if body != nil:
    body_611811 = body
  result = call_611809.call(nil, query_611810, nil, nil, body_611811)

var describeInstanceInformation* = Call_DescribeInstanceInformation_611794(
    name: "describeInstanceInformation", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeInstanceInformation",
    validator: validate_DescribeInstanceInformation_611795, base: "/",
    url: url_DescribeInstanceInformation_611796,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeInstancePatchStates_611812 = ref object of OpenApiRestCall_610658
proc url_DescribeInstancePatchStates_611814(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeInstancePatchStates_611813(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611815 = header.getOrDefault("X-Amz-Target")
  valid_611815 = validateParameter(valid_611815, JString, required = true, default = newJString(
      "AmazonSSM.DescribeInstancePatchStates"))
  if valid_611815 != nil:
    section.add "X-Amz-Target", valid_611815
  var valid_611816 = header.getOrDefault("X-Amz-Signature")
  valid_611816 = validateParameter(valid_611816, JString, required = false,
                                 default = nil)
  if valid_611816 != nil:
    section.add "X-Amz-Signature", valid_611816
  var valid_611817 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611817 = validateParameter(valid_611817, JString, required = false,
                                 default = nil)
  if valid_611817 != nil:
    section.add "X-Amz-Content-Sha256", valid_611817
  var valid_611818 = header.getOrDefault("X-Amz-Date")
  valid_611818 = validateParameter(valid_611818, JString, required = false,
                                 default = nil)
  if valid_611818 != nil:
    section.add "X-Amz-Date", valid_611818
  var valid_611819 = header.getOrDefault("X-Amz-Credential")
  valid_611819 = validateParameter(valid_611819, JString, required = false,
                                 default = nil)
  if valid_611819 != nil:
    section.add "X-Amz-Credential", valid_611819
  var valid_611820 = header.getOrDefault("X-Amz-Security-Token")
  valid_611820 = validateParameter(valid_611820, JString, required = false,
                                 default = nil)
  if valid_611820 != nil:
    section.add "X-Amz-Security-Token", valid_611820
  var valid_611821 = header.getOrDefault("X-Amz-Algorithm")
  valid_611821 = validateParameter(valid_611821, JString, required = false,
                                 default = nil)
  if valid_611821 != nil:
    section.add "X-Amz-Algorithm", valid_611821
  var valid_611822 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611822 = validateParameter(valid_611822, JString, required = false,
                                 default = nil)
  if valid_611822 != nil:
    section.add "X-Amz-SignedHeaders", valid_611822
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611824: Call_DescribeInstancePatchStates_611812; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the high-level patch state of one or more instances.
  ## 
  let valid = call_611824.validator(path, query, header, formData, body)
  let scheme = call_611824.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611824.url(scheme.get, call_611824.host, call_611824.base,
                         call_611824.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611824, url, valid)

proc call*(call_611825: Call_DescribeInstancePatchStates_611812; body: JsonNode): Recallable =
  ## describeInstancePatchStates
  ## Retrieves the high-level patch state of one or more instances.
  ##   body: JObject (required)
  var body_611826 = newJObject()
  if body != nil:
    body_611826 = body
  result = call_611825.call(nil, nil, nil, nil, body_611826)

var describeInstancePatchStates* = Call_DescribeInstancePatchStates_611812(
    name: "describeInstancePatchStates", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeInstancePatchStates",
    validator: validate_DescribeInstancePatchStates_611813, base: "/",
    url: url_DescribeInstancePatchStates_611814,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeInstancePatchStatesForPatchGroup_611827 = ref object of OpenApiRestCall_610658
proc url_DescribeInstancePatchStatesForPatchGroup_611829(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeInstancePatchStatesForPatchGroup_611828(path: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611830 = header.getOrDefault("X-Amz-Target")
  valid_611830 = validateParameter(valid_611830, JString, required = true, default = newJString(
      "AmazonSSM.DescribeInstancePatchStatesForPatchGroup"))
  if valid_611830 != nil:
    section.add "X-Amz-Target", valid_611830
  var valid_611831 = header.getOrDefault("X-Amz-Signature")
  valid_611831 = validateParameter(valid_611831, JString, required = false,
                                 default = nil)
  if valid_611831 != nil:
    section.add "X-Amz-Signature", valid_611831
  var valid_611832 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611832 = validateParameter(valid_611832, JString, required = false,
                                 default = nil)
  if valid_611832 != nil:
    section.add "X-Amz-Content-Sha256", valid_611832
  var valid_611833 = header.getOrDefault("X-Amz-Date")
  valid_611833 = validateParameter(valid_611833, JString, required = false,
                                 default = nil)
  if valid_611833 != nil:
    section.add "X-Amz-Date", valid_611833
  var valid_611834 = header.getOrDefault("X-Amz-Credential")
  valid_611834 = validateParameter(valid_611834, JString, required = false,
                                 default = nil)
  if valid_611834 != nil:
    section.add "X-Amz-Credential", valid_611834
  var valid_611835 = header.getOrDefault("X-Amz-Security-Token")
  valid_611835 = validateParameter(valid_611835, JString, required = false,
                                 default = nil)
  if valid_611835 != nil:
    section.add "X-Amz-Security-Token", valid_611835
  var valid_611836 = header.getOrDefault("X-Amz-Algorithm")
  valid_611836 = validateParameter(valid_611836, JString, required = false,
                                 default = nil)
  if valid_611836 != nil:
    section.add "X-Amz-Algorithm", valid_611836
  var valid_611837 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611837 = validateParameter(valid_611837, JString, required = false,
                                 default = nil)
  if valid_611837 != nil:
    section.add "X-Amz-SignedHeaders", valid_611837
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611839: Call_DescribeInstancePatchStatesForPatchGroup_611827;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves the high-level patch state for the instances in the specified patch group.
  ## 
  let valid = call_611839.validator(path, query, header, formData, body)
  let scheme = call_611839.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611839.url(scheme.get, call_611839.host, call_611839.base,
                         call_611839.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611839, url, valid)

proc call*(call_611840: Call_DescribeInstancePatchStatesForPatchGroup_611827;
          body: JsonNode): Recallable =
  ## describeInstancePatchStatesForPatchGroup
  ## Retrieves the high-level patch state for the instances in the specified patch group.
  ##   body: JObject (required)
  var body_611841 = newJObject()
  if body != nil:
    body_611841 = body
  result = call_611840.call(nil, nil, nil, nil, body_611841)

var describeInstancePatchStatesForPatchGroup* = Call_DescribeInstancePatchStatesForPatchGroup_611827(
    name: "describeInstancePatchStatesForPatchGroup", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeInstancePatchStatesForPatchGroup",
    validator: validate_DescribeInstancePatchStatesForPatchGroup_611828,
    base: "/", url: url_DescribeInstancePatchStatesForPatchGroup_611829,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeInstancePatches_611842 = ref object of OpenApiRestCall_610658
proc url_DescribeInstancePatches_611844(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeInstancePatches_611843(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611845 = header.getOrDefault("X-Amz-Target")
  valid_611845 = validateParameter(valid_611845, JString, required = true, default = newJString(
      "AmazonSSM.DescribeInstancePatches"))
  if valid_611845 != nil:
    section.add "X-Amz-Target", valid_611845
  var valid_611846 = header.getOrDefault("X-Amz-Signature")
  valid_611846 = validateParameter(valid_611846, JString, required = false,
                                 default = nil)
  if valid_611846 != nil:
    section.add "X-Amz-Signature", valid_611846
  var valid_611847 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611847 = validateParameter(valid_611847, JString, required = false,
                                 default = nil)
  if valid_611847 != nil:
    section.add "X-Amz-Content-Sha256", valid_611847
  var valid_611848 = header.getOrDefault("X-Amz-Date")
  valid_611848 = validateParameter(valid_611848, JString, required = false,
                                 default = nil)
  if valid_611848 != nil:
    section.add "X-Amz-Date", valid_611848
  var valid_611849 = header.getOrDefault("X-Amz-Credential")
  valid_611849 = validateParameter(valid_611849, JString, required = false,
                                 default = nil)
  if valid_611849 != nil:
    section.add "X-Amz-Credential", valid_611849
  var valid_611850 = header.getOrDefault("X-Amz-Security-Token")
  valid_611850 = validateParameter(valid_611850, JString, required = false,
                                 default = nil)
  if valid_611850 != nil:
    section.add "X-Amz-Security-Token", valid_611850
  var valid_611851 = header.getOrDefault("X-Amz-Algorithm")
  valid_611851 = validateParameter(valid_611851, JString, required = false,
                                 default = nil)
  if valid_611851 != nil:
    section.add "X-Amz-Algorithm", valid_611851
  var valid_611852 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611852 = validateParameter(valid_611852, JString, required = false,
                                 default = nil)
  if valid_611852 != nil:
    section.add "X-Amz-SignedHeaders", valid_611852
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611854: Call_DescribeInstancePatches_611842; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the patches on the specified instance and their state relative to the patch baseline being used for the instance.
  ## 
  let valid = call_611854.validator(path, query, header, formData, body)
  let scheme = call_611854.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611854.url(scheme.get, call_611854.host, call_611854.base,
                         call_611854.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611854, url, valid)

proc call*(call_611855: Call_DescribeInstancePatches_611842; body: JsonNode): Recallable =
  ## describeInstancePatches
  ## Retrieves information about the patches on the specified instance and their state relative to the patch baseline being used for the instance.
  ##   body: JObject (required)
  var body_611856 = newJObject()
  if body != nil:
    body_611856 = body
  result = call_611855.call(nil, nil, nil, nil, body_611856)

var describeInstancePatches* = Call_DescribeInstancePatches_611842(
    name: "describeInstancePatches", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeInstancePatches",
    validator: validate_DescribeInstancePatches_611843, base: "/",
    url: url_DescribeInstancePatches_611844, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeInventoryDeletions_611857 = ref object of OpenApiRestCall_610658
proc url_DescribeInventoryDeletions_611859(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeInventoryDeletions_611858(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611860 = header.getOrDefault("X-Amz-Target")
  valid_611860 = validateParameter(valid_611860, JString, required = true, default = newJString(
      "AmazonSSM.DescribeInventoryDeletions"))
  if valid_611860 != nil:
    section.add "X-Amz-Target", valid_611860
  var valid_611861 = header.getOrDefault("X-Amz-Signature")
  valid_611861 = validateParameter(valid_611861, JString, required = false,
                                 default = nil)
  if valid_611861 != nil:
    section.add "X-Amz-Signature", valid_611861
  var valid_611862 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611862 = validateParameter(valid_611862, JString, required = false,
                                 default = nil)
  if valid_611862 != nil:
    section.add "X-Amz-Content-Sha256", valid_611862
  var valid_611863 = header.getOrDefault("X-Amz-Date")
  valid_611863 = validateParameter(valid_611863, JString, required = false,
                                 default = nil)
  if valid_611863 != nil:
    section.add "X-Amz-Date", valid_611863
  var valid_611864 = header.getOrDefault("X-Amz-Credential")
  valid_611864 = validateParameter(valid_611864, JString, required = false,
                                 default = nil)
  if valid_611864 != nil:
    section.add "X-Amz-Credential", valid_611864
  var valid_611865 = header.getOrDefault("X-Amz-Security-Token")
  valid_611865 = validateParameter(valid_611865, JString, required = false,
                                 default = nil)
  if valid_611865 != nil:
    section.add "X-Amz-Security-Token", valid_611865
  var valid_611866 = header.getOrDefault("X-Amz-Algorithm")
  valid_611866 = validateParameter(valid_611866, JString, required = false,
                                 default = nil)
  if valid_611866 != nil:
    section.add "X-Amz-Algorithm", valid_611866
  var valid_611867 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611867 = validateParameter(valid_611867, JString, required = false,
                                 default = nil)
  if valid_611867 != nil:
    section.add "X-Amz-SignedHeaders", valid_611867
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611869: Call_DescribeInventoryDeletions_611857; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes a specific delete inventory operation.
  ## 
  let valid = call_611869.validator(path, query, header, formData, body)
  let scheme = call_611869.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611869.url(scheme.get, call_611869.host, call_611869.base,
                         call_611869.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611869, url, valid)

proc call*(call_611870: Call_DescribeInventoryDeletions_611857; body: JsonNode): Recallable =
  ## describeInventoryDeletions
  ## Describes a specific delete inventory operation.
  ##   body: JObject (required)
  var body_611871 = newJObject()
  if body != nil:
    body_611871 = body
  result = call_611870.call(nil, nil, nil, nil, body_611871)

var describeInventoryDeletions* = Call_DescribeInventoryDeletions_611857(
    name: "describeInventoryDeletions", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeInventoryDeletions",
    validator: validate_DescribeInventoryDeletions_611858, base: "/",
    url: url_DescribeInventoryDeletions_611859,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeMaintenanceWindowExecutionTaskInvocations_611872 = ref object of OpenApiRestCall_610658
proc url_DescribeMaintenanceWindowExecutionTaskInvocations_611874(
    protocol: Scheme; host: string; base: string; route: string; path: JsonNode;
    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeMaintenanceWindowExecutionTaskInvocations_611873(
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611875 = header.getOrDefault("X-Amz-Target")
  valid_611875 = validateParameter(valid_611875, JString, required = true, default = newJString(
      "AmazonSSM.DescribeMaintenanceWindowExecutionTaskInvocations"))
  if valid_611875 != nil:
    section.add "X-Amz-Target", valid_611875
  var valid_611876 = header.getOrDefault("X-Amz-Signature")
  valid_611876 = validateParameter(valid_611876, JString, required = false,
                                 default = nil)
  if valid_611876 != nil:
    section.add "X-Amz-Signature", valid_611876
  var valid_611877 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611877 = validateParameter(valid_611877, JString, required = false,
                                 default = nil)
  if valid_611877 != nil:
    section.add "X-Amz-Content-Sha256", valid_611877
  var valid_611878 = header.getOrDefault("X-Amz-Date")
  valid_611878 = validateParameter(valid_611878, JString, required = false,
                                 default = nil)
  if valid_611878 != nil:
    section.add "X-Amz-Date", valid_611878
  var valid_611879 = header.getOrDefault("X-Amz-Credential")
  valid_611879 = validateParameter(valid_611879, JString, required = false,
                                 default = nil)
  if valid_611879 != nil:
    section.add "X-Amz-Credential", valid_611879
  var valid_611880 = header.getOrDefault("X-Amz-Security-Token")
  valid_611880 = validateParameter(valid_611880, JString, required = false,
                                 default = nil)
  if valid_611880 != nil:
    section.add "X-Amz-Security-Token", valid_611880
  var valid_611881 = header.getOrDefault("X-Amz-Algorithm")
  valid_611881 = validateParameter(valid_611881, JString, required = false,
                                 default = nil)
  if valid_611881 != nil:
    section.add "X-Amz-Algorithm", valid_611881
  var valid_611882 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611882 = validateParameter(valid_611882, JString, required = false,
                                 default = nil)
  if valid_611882 != nil:
    section.add "X-Amz-SignedHeaders", valid_611882
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611884: Call_DescribeMaintenanceWindowExecutionTaskInvocations_611872;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves the individual task executions (one per target) for a particular task run as part of a maintenance window execution.
  ## 
  let valid = call_611884.validator(path, query, header, formData, body)
  let scheme = call_611884.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611884.url(scheme.get, call_611884.host, call_611884.base,
                         call_611884.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611884, url, valid)

proc call*(call_611885: Call_DescribeMaintenanceWindowExecutionTaskInvocations_611872;
          body: JsonNode): Recallable =
  ## describeMaintenanceWindowExecutionTaskInvocations
  ## Retrieves the individual task executions (one per target) for a particular task run as part of a maintenance window execution.
  ##   body: JObject (required)
  var body_611886 = newJObject()
  if body != nil:
    body_611886 = body
  result = call_611885.call(nil, nil, nil, nil, body_611886)

var describeMaintenanceWindowExecutionTaskInvocations* = Call_DescribeMaintenanceWindowExecutionTaskInvocations_611872(
    name: "describeMaintenanceWindowExecutionTaskInvocations",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com", route: "/#X-Amz-Target=AmazonSSM.DescribeMaintenanceWindowExecutionTaskInvocations",
    validator: validate_DescribeMaintenanceWindowExecutionTaskInvocations_611873,
    base: "/", url: url_DescribeMaintenanceWindowExecutionTaskInvocations_611874,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeMaintenanceWindowExecutionTasks_611887 = ref object of OpenApiRestCall_610658
proc url_DescribeMaintenanceWindowExecutionTasks_611889(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeMaintenanceWindowExecutionTasks_611888(path: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611890 = header.getOrDefault("X-Amz-Target")
  valid_611890 = validateParameter(valid_611890, JString, required = true, default = newJString(
      "AmazonSSM.DescribeMaintenanceWindowExecutionTasks"))
  if valid_611890 != nil:
    section.add "X-Amz-Target", valid_611890
  var valid_611891 = header.getOrDefault("X-Amz-Signature")
  valid_611891 = validateParameter(valid_611891, JString, required = false,
                                 default = nil)
  if valid_611891 != nil:
    section.add "X-Amz-Signature", valid_611891
  var valid_611892 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611892 = validateParameter(valid_611892, JString, required = false,
                                 default = nil)
  if valid_611892 != nil:
    section.add "X-Amz-Content-Sha256", valid_611892
  var valid_611893 = header.getOrDefault("X-Amz-Date")
  valid_611893 = validateParameter(valid_611893, JString, required = false,
                                 default = nil)
  if valid_611893 != nil:
    section.add "X-Amz-Date", valid_611893
  var valid_611894 = header.getOrDefault("X-Amz-Credential")
  valid_611894 = validateParameter(valid_611894, JString, required = false,
                                 default = nil)
  if valid_611894 != nil:
    section.add "X-Amz-Credential", valid_611894
  var valid_611895 = header.getOrDefault("X-Amz-Security-Token")
  valid_611895 = validateParameter(valid_611895, JString, required = false,
                                 default = nil)
  if valid_611895 != nil:
    section.add "X-Amz-Security-Token", valid_611895
  var valid_611896 = header.getOrDefault("X-Amz-Algorithm")
  valid_611896 = validateParameter(valid_611896, JString, required = false,
                                 default = nil)
  if valid_611896 != nil:
    section.add "X-Amz-Algorithm", valid_611896
  var valid_611897 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611897 = validateParameter(valid_611897, JString, required = false,
                                 default = nil)
  if valid_611897 != nil:
    section.add "X-Amz-SignedHeaders", valid_611897
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611899: Call_DescribeMaintenanceWindowExecutionTasks_611887;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## For a given maintenance window execution, lists the tasks that were run.
  ## 
  let valid = call_611899.validator(path, query, header, formData, body)
  let scheme = call_611899.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611899.url(scheme.get, call_611899.host, call_611899.base,
                         call_611899.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611899, url, valid)

proc call*(call_611900: Call_DescribeMaintenanceWindowExecutionTasks_611887;
          body: JsonNode): Recallable =
  ## describeMaintenanceWindowExecutionTasks
  ## For a given maintenance window execution, lists the tasks that were run.
  ##   body: JObject (required)
  var body_611901 = newJObject()
  if body != nil:
    body_611901 = body
  result = call_611900.call(nil, nil, nil, nil, body_611901)

var describeMaintenanceWindowExecutionTasks* = Call_DescribeMaintenanceWindowExecutionTasks_611887(
    name: "describeMaintenanceWindowExecutionTasks", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeMaintenanceWindowExecutionTasks",
    validator: validate_DescribeMaintenanceWindowExecutionTasks_611888, base: "/",
    url: url_DescribeMaintenanceWindowExecutionTasks_611889,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeMaintenanceWindowExecutions_611902 = ref object of OpenApiRestCall_610658
proc url_DescribeMaintenanceWindowExecutions_611904(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeMaintenanceWindowExecutions_611903(path: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611905 = header.getOrDefault("X-Amz-Target")
  valid_611905 = validateParameter(valid_611905, JString, required = true, default = newJString(
      "AmazonSSM.DescribeMaintenanceWindowExecutions"))
  if valid_611905 != nil:
    section.add "X-Amz-Target", valid_611905
  var valid_611906 = header.getOrDefault("X-Amz-Signature")
  valid_611906 = validateParameter(valid_611906, JString, required = false,
                                 default = nil)
  if valid_611906 != nil:
    section.add "X-Amz-Signature", valid_611906
  var valid_611907 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611907 = validateParameter(valid_611907, JString, required = false,
                                 default = nil)
  if valid_611907 != nil:
    section.add "X-Amz-Content-Sha256", valid_611907
  var valid_611908 = header.getOrDefault("X-Amz-Date")
  valid_611908 = validateParameter(valid_611908, JString, required = false,
                                 default = nil)
  if valid_611908 != nil:
    section.add "X-Amz-Date", valid_611908
  var valid_611909 = header.getOrDefault("X-Amz-Credential")
  valid_611909 = validateParameter(valid_611909, JString, required = false,
                                 default = nil)
  if valid_611909 != nil:
    section.add "X-Amz-Credential", valid_611909
  var valid_611910 = header.getOrDefault("X-Amz-Security-Token")
  valid_611910 = validateParameter(valid_611910, JString, required = false,
                                 default = nil)
  if valid_611910 != nil:
    section.add "X-Amz-Security-Token", valid_611910
  var valid_611911 = header.getOrDefault("X-Amz-Algorithm")
  valid_611911 = validateParameter(valid_611911, JString, required = false,
                                 default = nil)
  if valid_611911 != nil:
    section.add "X-Amz-Algorithm", valid_611911
  var valid_611912 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611912 = validateParameter(valid_611912, JString, required = false,
                                 default = nil)
  if valid_611912 != nil:
    section.add "X-Amz-SignedHeaders", valid_611912
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611914: Call_DescribeMaintenanceWindowExecutions_611902;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists the executions of a maintenance window. This includes information about when the maintenance window was scheduled to be active, and information about tasks registered and run with the maintenance window.
  ## 
  let valid = call_611914.validator(path, query, header, formData, body)
  let scheme = call_611914.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611914.url(scheme.get, call_611914.host, call_611914.base,
                         call_611914.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611914, url, valid)

proc call*(call_611915: Call_DescribeMaintenanceWindowExecutions_611902;
          body: JsonNode): Recallable =
  ## describeMaintenanceWindowExecutions
  ## Lists the executions of a maintenance window. This includes information about when the maintenance window was scheduled to be active, and information about tasks registered and run with the maintenance window.
  ##   body: JObject (required)
  var body_611916 = newJObject()
  if body != nil:
    body_611916 = body
  result = call_611915.call(nil, nil, nil, nil, body_611916)

var describeMaintenanceWindowExecutions* = Call_DescribeMaintenanceWindowExecutions_611902(
    name: "describeMaintenanceWindowExecutions", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeMaintenanceWindowExecutions",
    validator: validate_DescribeMaintenanceWindowExecutions_611903, base: "/",
    url: url_DescribeMaintenanceWindowExecutions_611904,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeMaintenanceWindowSchedule_611917 = ref object of OpenApiRestCall_610658
proc url_DescribeMaintenanceWindowSchedule_611919(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeMaintenanceWindowSchedule_611918(path: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611920 = header.getOrDefault("X-Amz-Target")
  valid_611920 = validateParameter(valid_611920, JString, required = true, default = newJString(
      "AmazonSSM.DescribeMaintenanceWindowSchedule"))
  if valid_611920 != nil:
    section.add "X-Amz-Target", valid_611920
  var valid_611921 = header.getOrDefault("X-Amz-Signature")
  valid_611921 = validateParameter(valid_611921, JString, required = false,
                                 default = nil)
  if valid_611921 != nil:
    section.add "X-Amz-Signature", valid_611921
  var valid_611922 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611922 = validateParameter(valid_611922, JString, required = false,
                                 default = nil)
  if valid_611922 != nil:
    section.add "X-Amz-Content-Sha256", valid_611922
  var valid_611923 = header.getOrDefault("X-Amz-Date")
  valid_611923 = validateParameter(valid_611923, JString, required = false,
                                 default = nil)
  if valid_611923 != nil:
    section.add "X-Amz-Date", valid_611923
  var valid_611924 = header.getOrDefault("X-Amz-Credential")
  valid_611924 = validateParameter(valid_611924, JString, required = false,
                                 default = nil)
  if valid_611924 != nil:
    section.add "X-Amz-Credential", valid_611924
  var valid_611925 = header.getOrDefault("X-Amz-Security-Token")
  valid_611925 = validateParameter(valid_611925, JString, required = false,
                                 default = nil)
  if valid_611925 != nil:
    section.add "X-Amz-Security-Token", valid_611925
  var valid_611926 = header.getOrDefault("X-Amz-Algorithm")
  valid_611926 = validateParameter(valid_611926, JString, required = false,
                                 default = nil)
  if valid_611926 != nil:
    section.add "X-Amz-Algorithm", valid_611926
  var valid_611927 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611927 = validateParameter(valid_611927, JString, required = false,
                                 default = nil)
  if valid_611927 != nil:
    section.add "X-Amz-SignedHeaders", valid_611927
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611929: Call_DescribeMaintenanceWindowSchedule_611917;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves information about upcoming executions of a maintenance window.
  ## 
  let valid = call_611929.validator(path, query, header, formData, body)
  let scheme = call_611929.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611929.url(scheme.get, call_611929.host, call_611929.base,
                         call_611929.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611929, url, valid)

proc call*(call_611930: Call_DescribeMaintenanceWindowSchedule_611917;
          body: JsonNode): Recallable =
  ## describeMaintenanceWindowSchedule
  ## Retrieves information about upcoming executions of a maintenance window.
  ##   body: JObject (required)
  var body_611931 = newJObject()
  if body != nil:
    body_611931 = body
  result = call_611930.call(nil, nil, nil, nil, body_611931)

var describeMaintenanceWindowSchedule* = Call_DescribeMaintenanceWindowSchedule_611917(
    name: "describeMaintenanceWindowSchedule", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeMaintenanceWindowSchedule",
    validator: validate_DescribeMaintenanceWindowSchedule_611918, base: "/",
    url: url_DescribeMaintenanceWindowSchedule_611919,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeMaintenanceWindowTargets_611932 = ref object of OpenApiRestCall_610658
proc url_DescribeMaintenanceWindowTargets_611934(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeMaintenanceWindowTargets_611933(path: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611935 = header.getOrDefault("X-Amz-Target")
  valid_611935 = validateParameter(valid_611935, JString, required = true, default = newJString(
      "AmazonSSM.DescribeMaintenanceWindowTargets"))
  if valid_611935 != nil:
    section.add "X-Amz-Target", valid_611935
  var valid_611936 = header.getOrDefault("X-Amz-Signature")
  valid_611936 = validateParameter(valid_611936, JString, required = false,
                                 default = nil)
  if valid_611936 != nil:
    section.add "X-Amz-Signature", valid_611936
  var valid_611937 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611937 = validateParameter(valid_611937, JString, required = false,
                                 default = nil)
  if valid_611937 != nil:
    section.add "X-Amz-Content-Sha256", valid_611937
  var valid_611938 = header.getOrDefault("X-Amz-Date")
  valid_611938 = validateParameter(valid_611938, JString, required = false,
                                 default = nil)
  if valid_611938 != nil:
    section.add "X-Amz-Date", valid_611938
  var valid_611939 = header.getOrDefault("X-Amz-Credential")
  valid_611939 = validateParameter(valid_611939, JString, required = false,
                                 default = nil)
  if valid_611939 != nil:
    section.add "X-Amz-Credential", valid_611939
  var valid_611940 = header.getOrDefault("X-Amz-Security-Token")
  valid_611940 = validateParameter(valid_611940, JString, required = false,
                                 default = nil)
  if valid_611940 != nil:
    section.add "X-Amz-Security-Token", valid_611940
  var valid_611941 = header.getOrDefault("X-Amz-Algorithm")
  valid_611941 = validateParameter(valid_611941, JString, required = false,
                                 default = nil)
  if valid_611941 != nil:
    section.add "X-Amz-Algorithm", valid_611941
  var valid_611942 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611942 = validateParameter(valid_611942, JString, required = false,
                                 default = nil)
  if valid_611942 != nil:
    section.add "X-Amz-SignedHeaders", valid_611942
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611944: Call_DescribeMaintenanceWindowTargets_611932;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists the targets registered with the maintenance window.
  ## 
  let valid = call_611944.validator(path, query, header, formData, body)
  let scheme = call_611944.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611944.url(scheme.get, call_611944.host, call_611944.base,
                         call_611944.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611944, url, valid)

proc call*(call_611945: Call_DescribeMaintenanceWindowTargets_611932;
          body: JsonNode): Recallable =
  ## describeMaintenanceWindowTargets
  ## Lists the targets registered with the maintenance window.
  ##   body: JObject (required)
  var body_611946 = newJObject()
  if body != nil:
    body_611946 = body
  result = call_611945.call(nil, nil, nil, nil, body_611946)

var describeMaintenanceWindowTargets* = Call_DescribeMaintenanceWindowTargets_611932(
    name: "describeMaintenanceWindowTargets", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeMaintenanceWindowTargets",
    validator: validate_DescribeMaintenanceWindowTargets_611933, base: "/",
    url: url_DescribeMaintenanceWindowTargets_611934,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeMaintenanceWindowTasks_611947 = ref object of OpenApiRestCall_610658
proc url_DescribeMaintenanceWindowTasks_611949(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeMaintenanceWindowTasks_611948(path: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611950 = header.getOrDefault("X-Amz-Target")
  valid_611950 = validateParameter(valid_611950, JString, required = true, default = newJString(
      "AmazonSSM.DescribeMaintenanceWindowTasks"))
  if valid_611950 != nil:
    section.add "X-Amz-Target", valid_611950
  var valid_611951 = header.getOrDefault("X-Amz-Signature")
  valid_611951 = validateParameter(valid_611951, JString, required = false,
                                 default = nil)
  if valid_611951 != nil:
    section.add "X-Amz-Signature", valid_611951
  var valid_611952 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611952 = validateParameter(valid_611952, JString, required = false,
                                 default = nil)
  if valid_611952 != nil:
    section.add "X-Amz-Content-Sha256", valid_611952
  var valid_611953 = header.getOrDefault("X-Amz-Date")
  valid_611953 = validateParameter(valid_611953, JString, required = false,
                                 default = nil)
  if valid_611953 != nil:
    section.add "X-Amz-Date", valid_611953
  var valid_611954 = header.getOrDefault("X-Amz-Credential")
  valid_611954 = validateParameter(valid_611954, JString, required = false,
                                 default = nil)
  if valid_611954 != nil:
    section.add "X-Amz-Credential", valid_611954
  var valid_611955 = header.getOrDefault("X-Amz-Security-Token")
  valid_611955 = validateParameter(valid_611955, JString, required = false,
                                 default = nil)
  if valid_611955 != nil:
    section.add "X-Amz-Security-Token", valid_611955
  var valid_611956 = header.getOrDefault("X-Amz-Algorithm")
  valid_611956 = validateParameter(valid_611956, JString, required = false,
                                 default = nil)
  if valid_611956 != nil:
    section.add "X-Amz-Algorithm", valid_611956
  var valid_611957 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611957 = validateParameter(valid_611957, JString, required = false,
                                 default = nil)
  if valid_611957 != nil:
    section.add "X-Amz-SignedHeaders", valid_611957
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611959: Call_DescribeMaintenanceWindowTasks_611947; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the tasks in a maintenance window.
  ## 
  let valid = call_611959.validator(path, query, header, formData, body)
  let scheme = call_611959.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611959.url(scheme.get, call_611959.host, call_611959.base,
                         call_611959.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611959, url, valid)

proc call*(call_611960: Call_DescribeMaintenanceWindowTasks_611947; body: JsonNode): Recallable =
  ## describeMaintenanceWindowTasks
  ## Lists the tasks in a maintenance window.
  ##   body: JObject (required)
  var body_611961 = newJObject()
  if body != nil:
    body_611961 = body
  result = call_611960.call(nil, nil, nil, nil, body_611961)

var describeMaintenanceWindowTasks* = Call_DescribeMaintenanceWindowTasks_611947(
    name: "describeMaintenanceWindowTasks", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeMaintenanceWindowTasks",
    validator: validate_DescribeMaintenanceWindowTasks_611948, base: "/",
    url: url_DescribeMaintenanceWindowTasks_611949,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeMaintenanceWindows_611962 = ref object of OpenApiRestCall_610658
proc url_DescribeMaintenanceWindows_611964(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeMaintenanceWindows_611963(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611965 = header.getOrDefault("X-Amz-Target")
  valid_611965 = validateParameter(valid_611965, JString, required = true, default = newJString(
      "AmazonSSM.DescribeMaintenanceWindows"))
  if valid_611965 != nil:
    section.add "X-Amz-Target", valid_611965
  var valid_611966 = header.getOrDefault("X-Amz-Signature")
  valid_611966 = validateParameter(valid_611966, JString, required = false,
                                 default = nil)
  if valid_611966 != nil:
    section.add "X-Amz-Signature", valid_611966
  var valid_611967 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611967 = validateParameter(valid_611967, JString, required = false,
                                 default = nil)
  if valid_611967 != nil:
    section.add "X-Amz-Content-Sha256", valid_611967
  var valid_611968 = header.getOrDefault("X-Amz-Date")
  valid_611968 = validateParameter(valid_611968, JString, required = false,
                                 default = nil)
  if valid_611968 != nil:
    section.add "X-Amz-Date", valid_611968
  var valid_611969 = header.getOrDefault("X-Amz-Credential")
  valid_611969 = validateParameter(valid_611969, JString, required = false,
                                 default = nil)
  if valid_611969 != nil:
    section.add "X-Amz-Credential", valid_611969
  var valid_611970 = header.getOrDefault("X-Amz-Security-Token")
  valid_611970 = validateParameter(valid_611970, JString, required = false,
                                 default = nil)
  if valid_611970 != nil:
    section.add "X-Amz-Security-Token", valid_611970
  var valid_611971 = header.getOrDefault("X-Amz-Algorithm")
  valid_611971 = validateParameter(valid_611971, JString, required = false,
                                 default = nil)
  if valid_611971 != nil:
    section.add "X-Amz-Algorithm", valid_611971
  var valid_611972 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611972 = validateParameter(valid_611972, JString, required = false,
                                 default = nil)
  if valid_611972 != nil:
    section.add "X-Amz-SignedHeaders", valid_611972
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611974: Call_DescribeMaintenanceWindows_611962; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the maintenance windows in an AWS account.
  ## 
  let valid = call_611974.validator(path, query, header, formData, body)
  let scheme = call_611974.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611974.url(scheme.get, call_611974.host, call_611974.base,
                         call_611974.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611974, url, valid)

proc call*(call_611975: Call_DescribeMaintenanceWindows_611962; body: JsonNode): Recallable =
  ## describeMaintenanceWindows
  ## Retrieves the maintenance windows in an AWS account.
  ##   body: JObject (required)
  var body_611976 = newJObject()
  if body != nil:
    body_611976 = body
  result = call_611975.call(nil, nil, nil, nil, body_611976)

var describeMaintenanceWindows* = Call_DescribeMaintenanceWindows_611962(
    name: "describeMaintenanceWindows", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeMaintenanceWindows",
    validator: validate_DescribeMaintenanceWindows_611963, base: "/",
    url: url_DescribeMaintenanceWindows_611964,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeMaintenanceWindowsForTarget_611977 = ref object of OpenApiRestCall_610658
proc url_DescribeMaintenanceWindowsForTarget_611979(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeMaintenanceWindowsForTarget_611978(path: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611980 = header.getOrDefault("X-Amz-Target")
  valid_611980 = validateParameter(valid_611980, JString, required = true, default = newJString(
      "AmazonSSM.DescribeMaintenanceWindowsForTarget"))
  if valid_611980 != nil:
    section.add "X-Amz-Target", valid_611980
  var valid_611981 = header.getOrDefault("X-Amz-Signature")
  valid_611981 = validateParameter(valid_611981, JString, required = false,
                                 default = nil)
  if valid_611981 != nil:
    section.add "X-Amz-Signature", valid_611981
  var valid_611982 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611982 = validateParameter(valid_611982, JString, required = false,
                                 default = nil)
  if valid_611982 != nil:
    section.add "X-Amz-Content-Sha256", valid_611982
  var valid_611983 = header.getOrDefault("X-Amz-Date")
  valid_611983 = validateParameter(valid_611983, JString, required = false,
                                 default = nil)
  if valid_611983 != nil:
    section.add "X-Amz-Date", valid_611983
  var valid_611984 = header.getOrDefault("X-Amz-Credential")
  valid_611984 = validateParameter(valid_611984, JString, required = false,
                                 default = nil)
  if valid_611984 != nil:
    section.add "X-Amz-Credential", valid_611984
  var valid_611985 = header.getOrDefault("X-Amz-Security-Token")
  valid_611985 = validateParameter(valid_611985, JString, required = false,
                                 default = nil)
  if valid_611985 != nil:
    section.add "X-Amz-Security-Token", valid_611985
  var valid_611986 = header.getOrDefault("X-Amz-Algorithm")
  valid_611986 = validateParameter(valid_611986, JString, required = false,
                                 default = nil)
  if valid_611986 != nil:
    section.add "X-Amz-Algorithm", valid_611986
  var valid_611987 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611987 = validateParameter(valid_611987, JString, required = false,
                                 default = nil)
  if valid_611987 != nil:
    section.add "X-Amz-SignedHeaders", valid_611987
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611989: Call_DescribeMaintenanceWindowsForTarget_611977;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves information about the maintenance window targets or tasks that an instance is associated with.
  ## 
  let valid = call_611989.validator(path, query, header, formData, body)
  let scheme = call_611989.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611989.url(scheme.get, call_611989.host, call_611989.base,
                         call_611989.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611989, url, valid)

proc call*(call_611990: Call_DescribeMaintenanceWindowsForTarget_611977;
          body: JsonNode): Recallable =
  ## describeMaintenanceWindowsForTarget
  ## Retrieves information about the maintenance window targets or tasks that an instance is associated with.
  ##   body: JObject (required)
  var body_611991 = newJObject()
  if body != nil:
    body_611991 = body
  result = call_611990.call(nil, nil, nil, nil, body_611991)

var describeMaintenanceWindowsForTarget* = Call_DescribeMaintenanceWindowsForTarget_611977(
    name: "describeMaintenanceWindowsForTarget", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeMaintenanceWindowsForTarget",
    validator: validate_DescribeMaintenanceWindowsForTarget_611978, base: "/",
    url: url_DescribeMaintenanceWindowsForTarget_611979,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeOpsItems_611992 = ref object of OpenApiRestCall_610658
proc url_DescribeOpsItems_611994(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeOpsItems_611993(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611995 = header.getOrDefault("X-Amz-Target")
  valid_611995 = validateParameter(valid_611995, JString, required = true, default = newJString(
      "AmazonSSM.DescribeOpsItems"))
  if valid_611995 != nil:
    section.add "X-Amz-Target", valid_611995
  var valid_611996 = header.getOrDefault("X-Amz-Signature")
  valid_611996 = validateParameter(valid_611996, JString, required = false,
                                 default = nil)
  if valid_611996 != nil:
    section.add "X-Amz-Signature", valid_611996
  var valid_611997 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611997 = validateParameter(valid_611997, JString, required = false,
                                 default = nil)
  if valid_611997 != nil:
    section.add "X-Amz-Content-Sha256", valid_611997
  var valid_611998 = header.getOrDefault("X-Amz-Date")
  valid_611998 = validateParameter(valid_611998, JString, required = false,
                                 default = nil)
  if valid_611998 != nil:
    section.add "X-Amz-Date", valid_611998
  var valid_611999 = header.getOrDefault("X-Amz-Credential")
  valid_611999 = validateParameter(valid_611999, JString, required = false,
                                 default = nil)
  if valid_611999 != nil:
    section.add "X-Amz-Credential", valid_611999
  var valid_612000 = header.getOrDefault("X-Amz-Security-Token")
  valid_612000 = validateParameter(valid_612000, JString, required = false,
                                 default = nil)
  if valid_612000 != nil:
    section.add "X-Amz-Security-Token", valid_612000
  var valid_612001 = header.getOrDefault("X-Amz-Algorithm")
  valid_612001 = validateParameter(valid_612001, JString, required = false,
                                 default = nil)
  if valid_612001 != nil:
    section.add "X-Amz-Algorithm", valid_612001
  var valid_612002 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612002 = validateParameter(valid_612002, JString, required = false,
                                 default = nil)
  if valid_612002 != nil:
    section.add "X-Amz-SignedHeaders", valid_612002
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612004: Call_DescribeOpsItems_611992; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Query a set of OpsItems. You must have permission in AWS Identity and Access Management (IAM) to query a list of OpsItems. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter-getting-started.html">Getting Started with OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>.</p> <p>Operations engineers and IT professionals use OpsCenter to view, investigate, and remediate operational issues impacting the performance and health of their AWS resources. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter.html">AWS Systems Manager OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>. </p>
  ## 
  let valid = call_612004.validator(path, query, header, formData, body)
  let scheme = call_612004.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612004.url(scheme.get, call_612004.host, call_612004.base,
                         call_612004.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612004, url, valid)

proc call*(call_612005: Call_DescribeOpsItems_611992; body: JsonNode): Recallable =
  ## describeOpsItems
  ## <p>Query a set of OpsItems. You must have permission in AWS Identity and Access Management (IAM) to query a list of OpsItems. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter-getting-started.html">Getting Started with OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>.</p> <p>Operations engineers and IT professionals use OpsCenter to view, investigate, and remediate operational issues impacting the performance and health of their AWS resources. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter.html">AWS Systems Manager OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>. </p>
  ##   body: JObject (required)
  var body_612006 = newJObject()
  if body != nil:
    body_612006 = body
  result = call_612005.call(nil, nil, nil, nil, body_612006)

var describeOpsItems* = Call_DescribeOpsItems_611992(name: "describeOpsItems",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeOpsItems",
    validator: validate_DescribeOpsItems_611993, base: "/",
    url: url_DescribeOpsItems_611994, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeParameters_612007 = ref object of OpenApiRestCall_610658
proc url_DescribeParameters_612009(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeParameters_612008(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## <p>Get information about a parameter.</p> <note> <p>Request results are returned on a best-effort basis. If you specify <code>MaxResults</code> in the request, the response includes information up to the limit specified. The number of items returned, however, can be between zero and the value of <code>MaxResults</code>. If the service reaches an internal limit while processing the results, it stops the operation and returns the matching values up to that point and a <code>NextToken</code>. You can specify the <code>NextToken</code> in a subsequent call to get the next set of results.</p> </note>
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
  var valid_612010 = query.getOrDefault("MaxResults")
  valid_612010 = validateParameter(valid_612010, JString, required = false,
                                 default = nil)
  if valid_612010 != nil:
    section.add "MaxResults", valid_612010
  var valid_612011 = query.getOrDefault("NextToken")
  valid_612011 = validateParameter(valid_612011, JString, required = false,
                                 default = nil)
  if valid_612011 != nil:
    section.add "NextToken", valid_612011
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612012 = header.getOrDefault("X-Amz-Target")
  valid_612012 = validateParameter(valid_612012, JString, required = true, default = newJString(
      "AmazonSSM.DescribeParameters"))
  if valid_612012 != nil:
    section.add "X-Amz-Target", valid_612012
  var valid_612013 = header.getOrDefault("X-Amz-Signature")
  valid_612013 = validateParameter(valid_612013, JString, required = false,
                                 default = nil)
  if valid_612013 != nil:
    section.add "X-Amz-Signature", valid_612013
  var valid_612014 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612014 = validateParameter(valid_612014, JString, required = false,
                                 default = nil)
  if valid_612014 != nil:
    section.add "X-Amz-Content-Sha256", valid_612014
  var valid_612015 = header.getOrDefault("X-Amz-Date")
  valid_612015 = validateParameter(valid_612015, JString, required = false,
                                 default = nil)
  if valid_612015 != nil:
    section.add "X-Amz-Date", valid_612015
  var valid_612016 = header.getOrDefault("X-Amz-Credential")
  valid_612016 = validateParameter(valid_612016, JString, required = false,
                                 default = nil)
  if valid_612016 != nil:
    section.add "X-Amz-Credential", valid_612016
  var valid_612017 = header.getOrDefault("X-Amz-Security-Token")
  valid_612017 = validateParameter(valid_612017, JString, required = false,
                                 default = nil)
  if valid_612017 != nil:
    section.add "X-Amz-Security-Token", valid_612017
  var valid_612018 = header.getOrDefault("X-Amz-Algorithm")
  valid_612018 = validateParameter(valid_612018, JString, required = false,
                                 default = nil)
  if valid_612018 != nil:
    section.add "X-Amz-Algorithm", valid_612018
  var valid_612019 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612019 = validateParameter(valid_612019, JString, required = false,
                                 default = nil)
  if valid_612019 != nil:
    section.add "X-Amz-SignedHeaders", valid_612019
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612021: Call_DescribeParameters_612007; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Get information about a parameter.</p> <note> <p>Request results are returned on a best-effort basis. If you specify <code>MaxResults</code> in the request, the response includes information up to the limit specified. The number of items returned, however, can be between zero and the value of <code>MaxResults</code>. If the service reaches an internal limit while processing the results, it stops the operation and returns the matching values up to that point and a <code>NextToken</code>. You can specify the <code>NextToken</code> in a subsequent call to get the next set of results.</p> </note>
  ## 
  let valid = call_612021.validator(path, query, header, formData, body)
  let scheme = call_612021.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612021.url(scheme.get, call_612021.host, call_612021.base,
                         call_612021.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612021, url, valid)

proc call*(call_612022: Call_DescribeParameters_612007; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## describeParameters
  ## <p>Get information about a parameter.</p> <note> <p>Request results are returned on a best-effort basis. If you specify <code>MaxResults</code> in the request, the response includes information up to the limit specified. The number of items returned, however, can be between zero and the value of <code>MaxResults</code>. If the service reaches an internal limit while processing the results, it stops the operation and returns the matching values up to that point and a <code>NextToken</code>. You can specify the <code>NextToken</code> in a subsequent call to get the next set of results.</p> </note>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_612023 = newJObject()
  var body_612024 = newJObject()
  add(query_612023, "MaxResults", newJString(MaxResults))
  add(query_612023, "NextToken", newJString(NextToken))
  if body != nil:
    body_612024 = body
  result = call_612022.call(nil, query_612023, nil, nil, body_612024)

var describeParameters* = Call_DescribeParameters_612007(
    name: "describeParameters", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeParameters",
    validator: validate_DescribeParameters_612008, base: "/",
    url: url_DescribeParameters_612009, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribePatchBaselines_612025 = ref object of OpenApiRestCall_610658
proc url_DescribePatchBaselines_612027(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribePatchBaselines_612026(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612028 = header.getOrDefault("X-Amz-Target")
  valid_612028 = validateParameter(valid_612028, JString, required = true, default = newJString(
      "AmazonSSM.DescribePatchBaselines"))
  if valid_612028 != nil:
    section.add "X-Amz-Target", valid_612028
  var valid_612029 = header.getOrDefault("X-Amz-Signature")
  valid_612029 = validateParameter(valid_612029, JString, required = false,
                                 default = nil)
  if valid_612029 != nil:
    section.add "X-Amz-Signature", valid_612029
  var valid_612030 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612030 = validateParameter(valid_612030, JString, required = false,
                                 default = nil)
  if valid_612030 != nil:
    section.add "X-Amz-Content-Sha256", valid_612030
  var valid_612031 = header.getOrDefault("X-Amz-Date")
  valid_612031 = validateParameter(valid_612031, JString, required = false,
                                 default = nil)
  if valid_612031 != nil:
    section.add "X-Amz-Date", valid_612031
  var valid_612032 = header.getOrDefault("X-Amz-Credential")
  valid_612032 = validateParameter(valid_612032, JString, required = false,
                                 default = nil)
  if valid_612032 != nil:
    section.add "X-Amz-Credential", valid_612032
  var valid_612033 = header.getOrDefault("X-Amz-Security-Token")
  valid_612033 = validateParameter(valid_612033, JString, required = false,
                                 default = nil)
  if valid_612033 != nil:
    section.add "X-Amz-Security-Token", valid_612033
  var valid_612034 = header.getOrDefault("X-Amz-Algorithm")
  valid_612034 = validateParameter(valid_612034, JString, required = false,
                                 default = nil)
  if valid_612034 != nil:
    section.add "X-Amz-Algorithm", valid_612034
  var valid_612035 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612035 = validateParameter(valid_612035, JString, required = false,
                                 default = nil)
  if valid_612035 != nil:
    section.add "X-Amz-SignedHeaders", valid_612035
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612037: Call_DescribePatchBaselines_612025; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the patch baselines in your AWS account.
  ## 
  let valid = call_612037.validator(path, query, header, formData, body)
  let scheme = call_612037.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612037.url(scheme.get, call_612037.host, call_612037.base,
                         call_612037.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612037, url, valid)

proc call*(call_612038: Call_DescribePatchBaselines_612025; body: JsonNode): Recallable =
  ## describePatchBaselines
  ## Lists the patch baselines in your AWS account.
  ##   body: JObject (required)
  var body_612039 = newJObject()
  if body != nil:
    body_612039 = body
  result = call_612038.call(nil, nil, nil, nil, body_612039)

var describePatchBaselines* = Call_DescribePatchBaselines_612025(
    name: "describePatchBaselines", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribePatchBaselines",
    validator: validate_DescribePatchBaselines_612026, base: "/",
    url: url_DescribePatchBaselines_612027, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribePatchGroupState_612040 = ref object of OpenApiRestCall_610658
proc url_DescribePatchGroupState_612042(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribePatchGroupState_612041(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612043 = header.getOrDefault("X-Amz-Target")
  valid_612043 = validateParameter(valid_612043, JString, required = true, default = newJString(
      "AmazonSSM.DescribePatchGroupState"))
  if valid_612043 != nil:
    section.add "X-Amz-Target", valid_612043
  var valid_612044 = header.getOrDefault("X-Amz-Signature")
  valid_612044 = validateParameter(valid_612044, JString, required = false,
                                 default = nil)
  if valid_612044 != nil:
    section.add "X-Amz-Signature", valid_612044
  var valid_612045 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612045 = validateParameter(valid_612045, JString, required = false,
                                 default = nil)
  if valid_612045 != nil:
    section.add "X-Amz-Content-Sha256", valid_612045
  var valid_612046 = header.getOrDefault("X-Amz-Date")
  valid_612046 = validateParameter(valid_612046, JString, required = false,
                                 default = nil)
  if valid_612046 != nil:
    section.add "X-Amz-Date", valid_612046
  var valid_612047 = header.getOrDefault("X-Amz-Credential")
  valid_612047 = validateParameter(valid_612047, JString, required = false,
                                 default = nil)
  if valid_612047 != nil:
    section.add "X-Amz-Credential", valid_612047
  var valid_612048 = header.getOrDefault("X-Amz-Security-Token")
  valid_612048 = validateParameter(valid_612048, JString, required = false,
                                 default = nil)
  if valid_612048 != nil:
    section.add "X-Amz-Security-Token", valid_612048
  var valid_612049 = header.getOrDefault("X-Amz-Algorithm")
  valid_612049 = validateParameter(valid_612049, JString, required = false,
                                 default = nil)
  if valid_612049 != nil:
    section.add "X-Amz-Algorithm", valid_612049
  var valid_612050 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612050 = validateParameter(valid_612050, JString, required = false,
                                 default = nil)
  if valid_612050 != nil:
    section.add "X-Amz-SignedHeaders", valid_612050
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612052: Call_DescribePatchGroupState_612040; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns high-level aggregated patch compliance state for a patch group.
  ## 
  let valid = call_612052.validator(path, query, header, formData, body)
  let scheme = call_612052.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612052.url(scheme.get, call_612052.host, call_612052.base,
                         call_612052.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612052, url, valid)

proc call*(call_612053: Call_DescribePatchGroupState_612040; body: JsonNode): Recallable =
  ## describePatchGroupState
  ## Returns high-level aggregated patch compliance state for a patch group.
  ##   body: JObject (required)
  var body_612054 = newJObject()
  if body != nil:
    body_612054 = body
  result = call_612053.call(nil, nil, nil, nil, body_612054)

var describePatchGroupState* = Call_DescribePatchGroupState_612040(
    name: "describePatchGroupState", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribePatchGroupState",
    validator: validate_DescribePatchGroupState_612041, base: "/",
    url: url_DescribePatchGroupState_612042, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribePatchGroups_612055 = ref object of OpenApiRestCall_610658
proc url_DescribePatchGroups_612057(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribePatchGroups_612056(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612058 = header.getOrDefault("X-Amz-Target")
  valid_612058 = validateParameter(valid_612058, JString, required = true, default = newJString(
      "AmazonSSM.DescribePatchGroups"))
  if valid_612058 != nil:
    section.add "X-Amz-Target", valid_612058
  var valid_612059 = header.getOrDefault("X-Amz-Signature")
  valid_612059 = validateParameter(valid_612059, JString, required = false,
                                 default = nil)
  if valid_612059 != nil:
    section.add "X-Amz-Signature", valid_612059
  var valid_612060 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612060 = validateParameter(valid_612060, JString, required = false,
                                 default = nil)
  if valid_612060 != nil:
    section.add "X-Amz-Content-Sha256", valid_612060
  var valid_612061 = header.getOrDefault("X-Amz-Date")
  valid_612061 = validateParameter(valid_612061, JString, required = false,
                                 default = nil)
  if valid_612061 != nil:
    section.add "X-Amz-Date", valid_612061
  var valid_612062 = header.getOrDefault("X-Amz-Credential")
  valid_612062 = validateParameter(valid_612062, JString, required = false,
                                 default = nil)
  if valid_612062 != nil:
    section.add "X-Amz-Credential", valid_612062
  var valid_612063 = header.getOrDefault("X-Amz-Security-Token")
  valid_612063 = validateParameter(valid_612063, JString, required = false,
                                 default = nil)
  if valid_612063 != nil:
    section.add "X-Amz-Security-Token", valid_612063
  var valid_612064 = header.getOrDefault("X-Amz-Algorithm")
  valid_612064 = validateParameter(valid_612064, JString, required = false,
                                 default = nil)
  if valid_612064 != nil:
    section.add "X-Amz-Algorithm", valid_612064
  var valid_612065 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612065 = validateParameter(valid_612065, JString, required = false,
                                 default = nil)
  if valid_612065 != nil:
    section.add "X-Amz-SignedHeaders", valid_612065
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612067: Call_DescribePatchGroups_612055; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all patch groups that have been registered with patch baselines.
  ## 
  let valid = call_612067.validator(path, query, header, formData, body)
  let scheme = call_612067.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612067.url(scheme.get, call_612067.host, call_612067.base,
                         call_612067.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612067, url, valid)

proc call*(call_612068: Call_DescribePatchGroups_612055; body: JsonNode): Recallable =
  ## describePatchGroups
  ## Lists all patch groups that have been registered with patch baselines.
  ##   body: JObject (required)
  var body_612069 = newJObject()
  if body != nil:
    body_612069 = body
  result = call_612068.call(nil, nil, nil, nil, body_612069)

var describePatchGroups* = Call_DescribePatchGroups_612055(
    name: "describePatchGroups", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribePatchGroups",
    validator: validate_DescribePatchGroups_612056, base: "/",
    url: url_DescribePatchGroups_612057, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribePatchProperties_612070 = ref object of OpenApiRestCall_610658
proc url_DescribePatchProperties_612072(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribePatchProperties_612071(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612073 = header.getOrDefault("X-Amz-Target")
  valid_612073 = validateParameter(valid_612073, JString, required = true, default = newJString(
      "AmazonSSM.DescribePatchProperties"))
  if valid_612073 != nil:
    section.add "X-Amz-Target", valid_612073
  var valid_612074 = header.getOrDefault("X-Amz-Signature")
  valid_612074 = validateParameter(valid_612074, JString, required = false,
                                 default = nil)
  if valid_612074 != nil:
    section.add "X-Amz-Signature", valid_612074
  var valid_612075 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612075 = validateParameter(valid_612075, JString, required = false,
                                 default = nil)
  if valid_612075 != nil:
    section.add "X-Amz-Content-Sha256", valid_612075
  var valid_612076 = header.getOrDefault("X-Amz-Date")
  valid_612076 = validateParameter(valid_612076, JString, required = false,
                                 default = nil)
  if valid_612076 != nil:
    section.add "X-Amz-Date", valid_612076
  var valid_612077 = header.getOrDefault("X-Amz-Credential")
  valid_612077 = validateParameter(valid_612077, JString, required = false,
                                 default = nil)
  if valid_612077 != nil:
    section.add "X-Amz-Credential", valid_612077
  var valid_612078 = header.getOrDefault("X-Amz-Security-Token")
  valid_612078 = validateParameter(valid_612078, JString, required = false,
                                 default = nil)
  if valid_612078 != nil:
    section.add "X-Amz-Security-Token", valid_612078
  var valid_612079 = header.getOrDefault("X-Amz-Algorithm")
  valid_612079 = validateParameter(valid_612079, JString, required = false,
                                 default = nil)
  if valid_612079 != nil:
    section.add "X-Amz-Algorithm", valid_612079
  var valid_612080 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612080 = validateParameter(valid_612080, JString, required = false,
                                 default = nil)
  if valid_612080 != nil:
    section.add "X-Amz-SignedHeaders", valid_612080
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612082: Call_DescribePatchProperties_612070; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists the properties of available patches organized by product, product family, classification, severity, and other properties of available patches. You can use the reported properties in the filters you specify in requests for actions such as <a>CreatePatchBaseline</a>, <a>UpdatePatchBaseline</a>, <a>DescribeAvailablePatches</a>, and <a>DescribePatchBaselines</a>.</p> <p>The following section lists the properties that can be used in filters for each major operating system type:</p> <dl> <dt>WINDOWS</dt> <dd> <p>Valid properties: PRODUCT, PRODUCT_FAMILY, CLASSIFICATION, MSRC_SEVERITY</p> </dd> <dt>AMAZON_LINUX</dt> <dd> <p>Valid properties: PRODUCT, CLASSIFICATION, SEVERITY</p> </dd> <dt>AMAZON_LINUX_2</dt> <dd> <p>Valid properties: PRODUCT, CLASSIFICATION, SEVERITY</p> </dd> <dt>UBUNTU </dt> <dd> <p>Valid properties: PRODUCT, PRIORITY</p> </dd> <dt>REDHAT_ENTERPRISE_LINUX</dt> <dd> <p>Valid properties: PRODUCT, CLASSIFICATION, SEVERITY</p> </dd> <dt>SUSE</dt> <dd> <p>Valid properties: PRODUCT, CLASSIFICATION, SEVERITY</p> </dd> <dt>CENTOS</dt> <dd> <p>Valid properties: PRODUCT, CLASSIFICATION, SEVERITY</p> </dd> </dl>
  ## 
  let valid = call_612082.validator(path, query, header, formData, body)
  let scheme = call_612082.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612082.url(scheme.get, call_612082.host, call_612082.base,
                         call_612082.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612082, url, valid)

proc call*(call_612083: Call_DescribePatchProperties_612070; body: JsonNode): Recallable =
  ## describePatchProperties
  ## <p>Lists the properties of available patches organized by product, product family, classification, severity, and other properties of available patches. You can use the reported properties in the filters you specify in requests for actions such as <a>CreatePatchBaseline</a>, <a>UpdatePatchBaseline</a>, <a>DescribeAvailablePatches</a>, and <a>DescribePatchBaselines</a>.</p> <p>The following section lists the properties that can be used in filters for each major operating system type:</p> <dl> <dt>WINDOWS</dt> <dd> <p>Valid properties: PRODUCT, PRODUCT_FAMILY, CLASSIFICATION, MSRC_SEVERITY</p> </dd> <dt>AMAZON_LINUX</dt> <dd> <p>Valid properties: PRODUCT, CLASSIFICATION, SEVERITY</p> </dd> <dt>AMAZON_LINUX_2</dt> <dd> <p>Valid properties: PRODUCT, CLASSIFICATION, SEVERITY</p> </dd> <dt>UBUNTU </dt> <dd> <p>Valid properties: PRODUCT, PRIORITY</p> </dd> <dt>REDHAT_ENTERPRISE_LINUX</dt> <dd> <p>Valid properties: PRODUCT, CLASSIFICATION, SEVERITY</p> </dd> <dt>SUSE</dt> <dd> <p>Valid properties: PRODUCT, CLASSIFICATION, SEVERITY</p> </dd> <dt>CENTOS</dt> <dd> <p>Valid properties: PRODUCT, CLASSIFICATION, SEVERITY</p> </dd> </dl>
  ##   body: JObject (required)
  var body_612084 = newJObject()
  if body != nil:
    body_612084 = body
  result = call_612083.call(nil, nil, nil, nil, body_612084)

var describePatchProperties* = Call_DescribePatchProperties_612070(
    name: "describePatchProperties", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribePatchProperties",
    validator: validate_DescribePatchProperties_612071, base: "/",
    url: url_DescribePatchProperties_612072, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeSessions_612085 = ref object of OpenApiRestCall_610658
proc url_DescribeSessions_612087(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeSessions_612086(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612088 = header.getOrDefault("X-Amz-Target")
  valid_612088 = validateParameter(valid_612088, JString, required = true, default = newJString(
      "AmazonSSM.DescribeSessions"))
  if valid_612088 != nil:
    section.add "X-Amz-Target", valid_612088
  var valid_612089 = header.getOrDefault("X-Amz-Signature")
  valid_612089 = validateParameter(valid_612089, JString, required = false,
                                 default = nil)
  if valid_612089 != nil:
    section.add "X-Amz-Signature", valid_612089
  var valid_612090 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612090 = validateParameter(valid_612090, JString, required = false,
                                 default = nil)
  if valid_612090 != nil:
    section.add "X-Amz-Content-Sha256", valid_612090
  var valid_612091 = header.getOrDefault("X-Amz-Date")
  valid_612091 = validateParameter(valid_612091, JString, required = false,
                                 default = nil)
  if valid_612091 != nil:
    section.add "X-Amz-Date", valid_612091
  var valid_612092 = header.getOrDefault("X-Amz-Credential")
  valid_612092 = validateParameter(valid_612092, JString, required = false,
                                 default = nil)
  if valid_612092 != nil:
    section.add "X-Amz-Credential", valid_612092
  var valid_612093 = header.getOrDefault("X-Amz-Security-Token")
  valid_612093 = validateParameter(valid_612093, JString, required = false,
                                 default = nil)
  if valid_612093 != nil:
    section.add "X-Amz-Security-Token", valid_612093
  var valid_612094 = header.getOrDefault("X-Amz-Algorithm")
  valid_612094 = validateParameter(valid_612094, JString, required = false,
                                 default = nil)
  if valid_612094 != nil:
    section.add "X-Amz-Algorithm", valid_612094
  var valid_612095 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612095 = validateParameter(valid_612095, JString, required = false,
                                 default = nil)
  if valid_612095 != nil:
    section.add "X-Amz-SignedHeaders", valid_612095
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612097: Call_DescribeSessions_612085; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of all active sessions (both connected and disconnected) or terminated sessions from the past 30 days.
  ## 
  let valid = call_612097.validator(path, query, header, formData, body)
  let scheme = call_612097.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612097.url(scheme.get, call_612097.host, call_612097.base,
                         call_612097.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612097, url, valid)

proc call*(call_612098: Call_DescribeSessions_612085; body: JsonNode): Recallable =
  ## describeSessions
  ## Retrieves a list of all active sessions (both connected and disconnected) or terminated sessions from the past 30 days.
  ##   body: JObject (required)
  var body_612099 = newJObject()
  if body != nil:
    body_612099 = body
  result = call_612098.call(nil, nil, nil, nil, body_612099)

var describeSessions* = Call_DescribeSessions_612085(name: "describeSessions",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeSessions",
    validator: validate_DescribeSessions_612086, base: "/",
    url: url_DescribeSessions_612087, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAutomationExecution_612100 = ref object of OpenApiRestCall_610658
proc url_GetAutomationExecution_612102(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetAutomationExecution_612101(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612103 = header.getOrDefault("X-Amz-Target")
  valid_612103 = validateParameter(valid_612103, JString, required = true, default = newJString(
      "AmazonSSM.GetAutomationExecution"))
  if valid_612103 != nil:
    section.add "X-Amz-Target", valid_612103
  var valid_612104 = header.getOrDefault("X-Amz-Signature")
  valid_612104 = validateParameter(valid_612104, JString, required = false,
                                 default = nil)
  if valid_612104 != nil:
    section.add "X-Amz-Signature", valid_612104
  var valid_612105 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612105 = validateParameter(valid_612105, JString, required = false,
                                 default = nil)
  if valid_612105 != nil:
    section.add "X-Amz-Content-Sha256", valid_612105
  var valid_612106 = header.getOrDefault("X-Amz-Date")
  valid_612106 = validateParameter(valid_612106, JString, required = false,
                                 default = nil)
  if valid_612106 != nil:
    section.add "X-Amz-Date", valid_612106
  var valid_612107 = header.getOrDefault("X-Amz-Credential")
  valid_612107 = validateParameter(valid_612107, JString, required = false,
                                 default = nil)
  if valid_612107 != nil:
    section.add "X-Amz-Credential", valid_612107
  var valid_612108 = header.getOrDefault("X-Amz-Security-Token")
  valid_612108 = validateParameter(valid_612108, JString, required = false,
                                 default = nil)
  if valid_612108 != nil:
    section.add "X-Amz-Security-Token", valid_612108
  var valid_612109 = header.getOrDefault("X-Amz-Algorithm")
  valid_612109 = validateParameter(valid_612109, JString, required = false,
                                 default = nil)
  if valid_612109 != nil:
    section.add "X-Amz-Algorithm", valid_612109
  var valid_612110 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612110 = validateParameter(valid_612110, JString, required = false,
                                 default = nil)
  if valid_612110 != nil:
    section.add "X-Amz-SignedHeaders", valid_612110
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612112: Call_GetAutomationExecution_612100; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Get detailed information about a particular Automation execution.
  ## 
  let valid = call_612112.validator(path, query, header, formData, body)
  let scheme = call_612112.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612112.url(scheme.get, call_612112.host, call_612112.base,
                         call_612112.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612112, url, valid)

proc call*(call_612113: Call_GetAutomationExecution_612100; body: JsonNode): Recallable =
  ## getAutomationExecution
  ## Get detailed information about a particular Automation execution.
  ##   body: JObject (required)
  var body_612114 = newJObject()
  if body != nil:
    body_612114 = body
  result = call_612113.call(nil, nil, nil, nil, body_612114)

var getAutomationExecution* = Call_GetAutomationExecution_612100(
    name: "getAutomationExecution", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetAutomationExecution",
    validator: validate_GetAutomationExecution_612101, base: "/",
    url: url_GetAutomationExecution_612102, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCalendarState_612115 = ref object of OpenApiRestCall_610658
proc url_GetCalendarState_612117(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCalendarState_612116(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Gets the state of the AWS Systems Manager Change Calendar at an optional, specified time. If you specify a time, <code>GetCalendarState</code> returns the state of the calendar at a specific time, and returns the next time that the Change Calendar state will transition. If you do not specify a time, <code>GetCalendarState</code> assumes the current time. Change Calendar entries have two possible states: <code>OPEN</code> or <code>CLOSED</code>. For more information about Systems Manager Change Calendar, see <a href="https://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-change-calendar.html">AWS Systems Manager Change Calendar</a> in the <i>AWS Systems Manager User Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612118 = header.getOrDefault("X-Amz-Target")
  valid_612118 = validateParameter(valid_612118, JString, required = true, default = newJString(
      "AmazonSSM.GetCalendarState"))
  if valid_612118 != nil:
    section.add "X-Amz-Target", valid_612118
  var valid_612119 = header.getOrDefault("X-Amz-Signature")
  valid_612119 = validateParameter(valid_612119, JString, required = false,
                                 default = nil)
  if valid_612119 != nil:
    section.add "X-Amz-Signature", valid_612119
  var valid_612120 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612120 = validateParameter(valid_612120, JString, required = false,
                                 default = nil)
  if valid_612120 != nil:
    section.add "X-Amz-Content-Sha256", valid_612120
  var valid_612121 = header.getOrDefault("X-Amz-Date")
  valid_612121 = validateParameter(valid_612121, JString, required = false,
                                 default = nil)
  if valid_612121 != nil:
    section.add "X-Amz-Date", valid_612121
  var valid_612122 = header.getOrDefault("X-Amz-Credential")
  valid_612122 = validateParameter(valid_612122, JString, required = false,
                                 default = nil)
  if valid_612122 != nil:
    section.add "X-Amz-Credential", valid_612122
  var valid_612123 = header.getOrDefault("X-Amz-Security-Token")
  valid_612123 = validateParameter(valid_612123, JString, required = false,
                                 default = nil)
  if valid_612123 != nil:
    section.add "X-Amz-Security-Token", valid_612123
  var valid_612124 = header.getOrDefault("X-Amz-Algorithm")
  valid_612124 = validateParameter(valid_612124, JString, required = false,
                                 default = nil)
  if valid_612124 != nil:
    section.add "X-Amz-Algorithm", valid_612124
  var valid_612125 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612125 = validateParameter(valid_612125, JString, required = false,
                                 default = nil)
  if valid_612125 != nil:
    section.add "X-Amz-SignedHeaders", valid_612125
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612127: Call_GetCalendarState_612115; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the state of the AWS Systems Manager Change Calendar at an optional, specified time. If you specify a time, <code>GetCalendarState</code> returns the state of the calendar at a specific time, and returns the next time that the Change Calendar state will transition. If you do not specify a time, <code>GetCalendarState</code> assumes the current time. Change Calendar entries have two possible states: <code>OPEN</code> or <code>CLOSED</code>. For more information about Systems Manager Change Calendar, see <a href="https://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-change-calendar.html">AWS Systems Manager Change Calendar</a> in the <i>AWS Systems Manager User Guide</i>.
  ## 
  let valid = call_612127.validator(path, query, header, formData, body)
  let scheme = call_612127.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612127.url(scheme.get, call_612127.host, call_612127.base,
                         call_612127.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612127, url, valid)

proc call*(call_612128: Call_GetCalendarState_612115; body: JsonNode): Recallable =
  ## getCalendarState
  ## Gets the state of the AWS Systems Manager Change Calendar at an optional, specified time. If you specify a time, <code>GetCalendarState</code> returns the state of the calendar at a specific time, and returns the next time that the Change Calendar state will transition. If you do not specify a time, <code>GetCalendarState</code> assumes the current time. Change Calendar entries have two possible states: <code>OPEN</code> or <code>CLOSED</code>. For more information about Systems Manager Change Calendar, see <a href="https://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-change-calendar.html">AWS Systems Manager Change Calendar</a> in the <i>AWS Systems Manager User Guide</i>.
  ##   body: JObject (required)
  var body_612129 = newJObject()
  if body != nil:
    body_612129 = body
  result = call_612128.call(nil, nil, nil, nil, body_612129)

var getCalendarState* = Call_GetCalendarState_612115(name: "getCalendarState",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetCalendarState",
    validator: validate_GetCalendarState_612116, base: "/",
    url: url_GetCalendarState_612117, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCommandInvocation_612130 = ref object of OpenApiRestCall_610658
proc url_GetCommandInvocation_612132(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCommandInvocation_612131(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612133 = header.getOrDefault("X-Amz-Target")
  valid_612133 = validateParameter(valid_612133, JString, required = true, default = newJString(
      "AmazonSSM.GetCommandInvocation"))
  if valid_612133 != nil:
    section.add "X-Amz-Target", valid_612133
  var valid_612134 = header.getOrDefault("X-Amz-Signature")
  valid_612134 = validateParameter(valid_612134, JString, required = false,
                                 default = nil)
  if valid_612134 != nil:
    section.add "X-Amz-Signature", valid_612134
  var valid_612135 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612135 = validateParameter(valid_612135, JString, required = false,
                                 default = nil)
  if valid_612135 != nil:
    section.add "X-Amz-Content-Sha256", valid_612135
  var valid_612136 = header.getOrDefault("X-Amz-Date")
  valid_612136 = validateParameter(valid_612136, JString, required = false,
                                 default = nil)
  if valid_612136 != nil:
    section.add "X-Amz-Date", valid_612136
  var valid_612137 = header.getOrDefault("X-Amz-Credential")
  valid_612137 = validateParameter(valid_612137, JString, required = false,
                                 default = nil)
  if valid_612137 != nil:
    section.add "X-Amz-Credential", valid_612137
  var valid_612138 = header.getOrDefault("X-Amz-Security-Token")
  valid_612138 = validateParameter(valid_612138, JString, required = false,
                                 default = nil)
  if valid_612138 != nil:
    section.add "X-Amz-Security-Token", valid_612138
  var valid_612139 = header.getOrDefault("X-Amz-Algorithm")
  valid_612139 = validateParameter(valid_612139, JString, required = false,
                                 default = nil)
  if valid_612139 != nil:
    section.add "X-Amz-Algorithm", valid_612139
  var valid_612140 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612140 = validateParameter(valid_612140, JString, required = false,
                                 default = nil)
  if valid_612140 != nil:
    section.add "X-Amz-SignedHeaders", valid_612140
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612142: Call_GetCommandInvocation_612130; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns detailed information about command execution for an invocation or plugin. 
  ## 
  let valid = call_612142.validator(path, query, header, formData, body)
  let scheme = call_612142.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612142.url(scheme.get, call_612142.host, call_612142.base,
                         call_612142.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612142, url, valid)

proc call*(call_612143: Call_GetCommandInvocation_612130; body: JsonNode): Recallable =
  ## getCommandInvocation
  ## Returns detailed information about command execution for an invocation or plugin. 
  ##   body: JObject (required)
  var body_612144 = newJObject()
  if body != nil:
    body_612144 = body
  result = call_612143.call(nil, nil, nil, nil, body_612144)

var getCommandInvocation* = Call_GetCommandInvocation_612130(
    name: "getCommandInvocation", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetCommandInvocation",
    validator: validate_GetCommandInvocation_612131, base: "/",
    url: url_GetCommandInvocation_612132, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetConnectionStatus_612145 = ref object of OpenApiRestCall_610658
proc url_GetConnectionStatus_612147(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetConnectionStatus_612146(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612148 = header.getOrDefault("X-Amz-Target")
  valid_612148 = validateParameter(valid_612148, JString, required = true, default = newJString(
      "AmazonSSM.GetConnectionStatus"))
  if valid_612148 != nil:
    section.add "X-Amz-Target", valid_612148
  var valid_612149 = header.getOrDefault("X-Amz-Signature")
  valid_612149 = validateParameter(valid_612149, JString, required = false,
                                 default = nil)
  if valid_612149 != nil:
    section.add "X-Amz-Signature", valid_612149
  var valid_612150 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612150 = validateParameter(valid_612150, JString, required = false,
                                 default = nil)
  if valid_612150 != nil:
    section.add "X-Amz-Content-Sha256", valid_612150
  var valid_612151 = header.getOrDefault("X-Amz-Date")
  valid_612151 = validateParameter(valid_612151, JString, required = false,
                                 default = nil)
  if valid_612151 != nil:
    section.add "X-Amz-Date", valid_612151
  var valid_612152 = header.getOrDefault("X-Amz-Credential")
  valid_612152 = validateParameter(valid_612152, JString, required = false,
                                 default = nil)
  if valid_612152 != nil:
    section.add "X-Amz-Credential", valid_612152
  var valid_612153 = header.getOrDefault("X-Amz-Security-Token")
  valid_612153 = validateParameter(valid_612153, JString, required = false,
                                 default = nil)
  if valid_612153 != nil:
    section.add "X-Amz-Security-Token", valid_612153
  var valid_612154 = header.getOrDefault("X-Amz-Algorithm")
  valid_612154 = validateParameter(valid_612154, JString, required = false,
                                 default = nil)
  if valid_612154 != nil:
    section.add "X-Amz-Algorithm", valid_612154
  var valid_612155 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612155 = validateParameter(valid_612155, JString, required = false,
                                 default = nil)
  if valid_612155 != nil:
    section.add "X-Amz-SignedHeaders", valid_612155
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612157: Call_GetConnectionStatus_612145; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the Session Manager connection status for an instance to determine whether it is connected and ready to receive Session Manager connections.
  ## 
  let valid = call_612157.validator(path, query, header, formData, body)
  let scheme = call_612157.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612157.url(scheme.get, call_612157.host, call_612157.base,
                         call_612157.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612157, url, valid)

proc call*(call_612158: Call_GetConnectionStatus_612145; body: JsonNode): Recallable =
  ## getConnectionStatus
  ## Retrieves the Session Manager connection status for an instance to determine whether it is connected and ready to receive Session Manager connections.
  ##   body: JObject (required)
  var body_612159 = newJObject()
  if body != nil:
    body_612159 = body
  result = call_612158.call(nil, nil, nil, nil, body_612159)

var getConnectionStatus* = Call_GetConnectionStatus_612145(
    name: "getConnectionStatus", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetConnectionStatus",
    validator: validate_GetConnectionStatus_612146, base: "/",
    url: url_GetConnectionStatus_612147, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDefaultPatchBaseline_612160 = ref object of OpenApiRestCall_610658
proc url_GetDefaultPatchBaseline_612162(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDefaultPatchBaseline_612161(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612163 = header.getOrDefault("X-Amz-Target")
  valid_612163 = validateParameter(valid_612163, JString, required = true, default = newJString(
      "AmazonSSM.GetDefaultPatchBaseline"))
  if valid_612163 != nil:
    section.add "X-Amz-Target", valid_612163
  var valid_612164 = header.getOrDefault("X-Amz-Signature")
  valid_612164 = validateParameter(valid_612164, JString, required = false,
                                 default = nil)
  if valid_612164 != nil:
    section.add "X-Amz-Signature", valid_612164
  var valid_612165 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612165 = validateParameter(valid_612165, JString, required = false,
                                 default = nil)
  if valid_612165 != nil:
    section.add "X-Amz-Content-Sha256", valid_612165
  var valid_612166 = header.getOrDefault("X-Amz-Date")
  valid_612166 = validateParameter(valid_612166, JString, required = false,
                                 default = nil)
  if valid_612166 != nil:
    section.add "X-Amz-Date", valid_612166
  var valid_612167 = header.getOrDefault("X-Amz-Credential")
  valid_612167 = validateParameter(valid_612167, JString, required = false,
                                 default = nil)
  if valid_612167 != nil:
    section.add "X-Amz-Credential", valid_612167
  var valid_612168 = header.getOrDefault("X-Amz-Security-Token")
  valid_612168 = validateParameter(valid_612168, JString, required = false,
                                 default = nil)
  if valid_612168 != nil:
    section.add "X-Amz-Security-Token", valid_612168
  var valid_612169 = header.getOrDefault("X-Amz-Algorithm")
  valid_612169 = validateParameter(valid_612169, JString, required = false,
                                 default = nil)
  if valid_612169 != nil:
    section.add "X-Amz-Algorithm", valid_612169
  var valid_612170 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612170 = validateParameter(valid_612170, JString, required = false,
                                 default = nil)
  if valid_612170 != nil:
    section.add "X-Amz-SignedHeaders", valid_612170
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612172: Call_GetDefaultPatchBaseline_612160; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves the default patch baseline. Note that Systems Manager supports creating multiple default patch baselines. For example, you can create a default patch baseline for each operating system.</p> <p>If you do not specify an operating system value, the default patch baseline for Windows is returned.</p>
  ## 
  let valid = call_612172.validator(path, query, header, formData, body)
  let scheme = call_612172.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612172.url(scheme.get, call_612172.host, call_612172.base,
                         call_612172.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612172, url, valid)

proc call*(call_612173: Call_GetDefaultPatchBaseline_612160; body: JsonNode): Recallable =
  ## getDefaultPatchBaseline
  ## <p>Retrieves the default patch baseline. Note that Systems Manager supports creating multiple default patch baselines. For example, you can create a default patch baseline for each operating system.</p> <p>If you do not specify an operating system value, the default patch baseline for Windows is returned.</p>
  ##   body: JObject (required)
  var body_612174 = newJObject()
  if body != nil:
    body_612174 = body
  result = call_612173.call(nil, nil, nil, nil, body_612174)

var getDefaultPatchBaseline* = Call_GetDefaultPatchBaseline_612160(
    name: "getDefaultPatchBaseline", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetDefaultPatchBaseline",
    validator: validate_GetDefaultPatchBaseline_612161, base: "/",
    url: url_GetDefaultPatchBaseline_612162, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeployablePatchSnapshotForInstance_612175 = ref object of OpenApiRestCall_610658
proc url_GetDeployablePatchSnapshotForInstance_612177(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeployablePatchSnapshotForInstance_612176(path: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612178 = header.getOrDefault("X-Amz-Target")
  valid_612178 = validateParameter(valid_612178, JString, required = true, default = newJString(
      "AmazonSSM.GetDeployablePatchSnapshotForInstance"))
  if valid_612178 != nil:
    section.add "X-Amz-Target", valid_612178
  var valid_612179 = header.getOrDefault("X-Amz-Signature")
  valid_612179 = validateParameter(valid_612179, JString, required = false,
                                 default = nil)
  if valid_612179 != nil:
    section.add "X-Amz-Signature", valid_612179
  var valid_612180 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612180 = validateParameter(valid_612180, JString, required = false,
                                 default = nil)
  if valid_612180 != nil:
    section.add "X-Amz-Content-Sha256", valid_612180
  var valid_612181 = header.getOrDefault("X-Amz-Date")
  valid_612181 = validateParameter(valid_612181, JString, required = false,
                                 default = nil)
  if valid_612181 != nil:
    section.add "X-Amz-Date", valid_612181
  var valid_612182 = header.getOrDefault("X-Amz-Credential")
  valid_612182 = validateParameter(valid_612182, JString, required = false,
                                 default = nil)
  if valid_612182 != nil:
    section.add "X-Amz-Credential", valid_612182
  var valid_612183 = header.getOrDefault("X-Amz-Security-Token")
  valid_612183 = validateParameter(valid_612183, JString, required = false,
                                 default = nil)
  if valid_612183 != nil:
    section.add "X-Amz-Security-Token", valid_612183
  var valid_612184 = header.getOrDefault("X-Amz-Algorithm")
  valid_612184 = validateParameter(valid_612184, JString, required = false,
                                 default = nil)
  if valid_612184 != nil:
    section.add "X-Amz-Algorithm", valid_612184
  var valid_612185 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612185 = validateParameter(valid_612185, JString, required = false,
                                 default = nil)
  if valid_612185 != nil:
    section.add "X-Amz-SignedHeaders", valid_612185
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612187: Call_GetDeployablePatchSnapshotForInstance_612175;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves the current snapshot for the patch baseline the instance uses. This API is primarily used by the AWS-RunPatchBaseline Systems Manager document. 
  ## 
  let valid = call_612187.validator(path, query, header, formData, body)
  let scheme = call_612187.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612187.url(scheme.get, call_612187.host, call_612187.base,
                         call_612187.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612187, url, valid)

proc call*(call_612188: Call_GetDeployablePatchSnapshotForInstance_612175;
          body: JsonNode): Recallable =
  ## getDeployablePatchSnapshotForInstance
  ## Retrieves the current snapshot for the patch baseline the instance uses. This API is primarily used by the AWS-RunPatchBaseline Systems Manager document. 
  ##   body: JObject (required)
  var body_612189 = newJObject()
  if body != nil:
    body_612189 = body
  result = call_612188.call(nil, nil, nil, nil, body_612189)

var getDeployablePatchSnapshotForInstance* = Call_GetDeployablePatchSnapshotForInstance_612175(
    name: "getDeployablePatchSnapshotForInstance", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetDeployablePatchSnapshotForInstance",
    validator: validate_GetDeployablePatchSnapshotForInstance_612176, base: "/",
    url: url_GetDeployablePatchSnapshotForInstance_612177,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDocument_612190 = ref object of OpenApiRestCall_610658
proc url_GetDocument_612192(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDocument_612191(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612193 = header.getOrDefault("X-Amz-Target")
  valid_612193 = validateParameter(valid_612193, JString, required = true,
                                 default = newJString("AmazonSSM.GetDocument"))
  if valid_612193 != nil:
    section.add "X-Amz-Target", valid_612193
  var valid_612194 = header.getOrDefault("X-Amz-Signature")
  valid_612194 = validateParameter(valid_612194, JString, required = false,
                                 default = nil)
  if valid_612194 != nil:
    section.add "X-Amz-Signature", valid_612194
  var valid_612195 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612195 = validateParameter(valid_612195, JString, required = false,
                                 default = nil)
  if valid_612195 != nil:
    section.add "X-Amz-Content-Sha256", valid_612195
  var valid_612196 = header.getOrDefault("X-Amz-Date")
  valid_612196 = validateParameter(valid_612196, JString, required = false,
                                 default = nil)
  if valid_612196 != nil:
    section.add "X-Amz-Date", valid_612196
  var valid_612197 = header.getOrDefault("X-Amz-Credential")
  valid_612197 = validateParameter(valid_612197, JString, required = false,
                                 default = nil)
  if valid_612197 != nil:
    section.add "X-Amz-Credential", valid_612197
  var valid_612198 = header.getOrDefault("X-Amz-Security-Token")
  valid_612198 = validateParameter(valid_612198, JString, required = false,
                                 default = nil)
  if valid_612198 != nil:
    section.add "X-Amz-Security-Token", valid_612198
  var valid_612199 = header.getOrDefault("X-Amz-Algorithm")
  valid_612199 = validateParameter(valid_612199, JString, required = false,
                                 default = nil)
  if valid_612199 != nil:
    section.add "X-Amz-Algorithm", valid_612199
  var valid_612200 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612200 = validateParameter(valid_612200, JString, required = false,
                                 default = nil)
  if valid_612200 != nil:
    section.add "X-Amz-SignedHeaders", valid_612200
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612202: Call_GetDocument_612190; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the contents of the specified Systems Manager document.
  ## 
  let valid = call_612202.validator(path, query, header, formData, body)
  let scheme = call_612202.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612202.url(scheme.get, call_612202.host, call_612202.base,
                         call_612202.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612202, url, valid)

proc call*(call_612203: Call_GetDocument_612190; body: JsonNode): Recallable =
  ## getDocument
  ## Gets the contents of the specified Systems Manager document.
  ##   body: JObject (required)
  var body_612204 = newJObject()
  if body != nil:
    body_612204 = body
  result = call_612203.call(nil, nil, nil, nil, body_612204)

var getDocument* = Call_GetDocument_612190(name: "getDocument",
                                        meth: HttpMethod.HttpPost,
                                        host: "ssm.amazonaws.com", route: "/#X-Amz-Target=AmazonSSM.GetDocument",
                                        validator: validate_GetDocument_612191,
                                        base: "/", url: url_GetDocument_612192,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetInventory_612205 = ref object of OpenApiRestCall_610658
proc url_GetInventory_612207(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetInventory_612206(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612208 = header.getOrDefault("X-Amz-Target")
  valid_612208 = validateParameter(valid_612208, JString, required = true,
                                 default = newJString("AmazonSSM.GetInventory"))
  if valid_612208 != nil:
    section.add "X-Amz-Target", valid_612208
  var valid_612209 = header.getOrDefault("X-Amz-Signature")
  valid_612209 = validateParameter(valid_612209, JString, required = false,
                                 default = nil)
  if valid_612209 != nil:
    section.add "X-Amz-Signature", valid_612209
  var valid_612210 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612210 = validateParameter(valid_612210, JString, required = false,
                                 default = nil)
  if valid_612210 != nil:
    section.add "X-Amz-Content-Sha256", valid_612210
  var valid_612211 = header.getOrDefault("X-Amz-Date")
  valid_612211 = validateParameter(valid_612211, JString, required = false,
                                 default = nil)
  if valid_612211 != nil:
    section.add "X-Amz-Date", valid_612211
  var valid_612212 = header.getOrDefault("X-Amz-Credential")
  valid_612212 = validateParameter(valid_612212, JString, required = false,
                                 default = nil)
  if valid_612212 != nil:
    section.add "X-Amz-Credential", valid_612212
  var valid_612213 = header.getOrDefault("X-Amz-Security-Token")
  valid_612213 = validateParameter(valid_612213, JString, required = false,
                                 default = nil)
  if valid_612213 != nil:
    section.add "X-Amz-Security-Token", valid_612213
  var valid_612214 = header.getOrDefault("X-Amz-Algorithm")
  valid_612214 = validateParameter(valid_612214, JString, required = false,
                                 default = nil)
  if valid_612214 != nil:
    section.add "X-Amz-Algorithm", valid_612214
  var valid_612215 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612215 = validateParameter(valid_612215, JString, required = false,
                                 default = nil)
  if valid_612215 != nil:
    section.add "X-Amz-SignedHeaders", valid_612215
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612217: Call_GetInventory_612205; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Query inventory information.
  ## 
  let valid = call_612217.validator(path, query, header, formData, body)
  let scheme = call_612217.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612217.url(scheme.get, call_612217.host, call_612217.base,
                         call_612217.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612217, url, valid)

proc call*(call_612218: Call_GetInventory_612205; body: JsonNode): Recallable =
  ## getInventory
  ## Query inventory information.
  ##   body: JObject (required)
  var body_612219 = newJObject()
  if body != nil:
    body_612219 = body
  result = call_612218.call(nil, nil, nil, nil, body_612219)

var getInventory* = Call_GetInventory_612205(name: "getInventory",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetInventory",
    validator: validate_GetInventory_612206, base: "/", url: url_GetInventory_612207,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetInventorySchema_612220 = ref object of OpenApiRestCall_610658
proc url_GetInventorySchema_612222(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetInventorySchema_612221(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612223 = header.getOrDefault("X-Amz-Target")
  valid_612223 = validateParameter(valid_612223, JString, required = true, default = newJString(
      "AmazonSSM.GetInventorySchema"))
  if valid_612223 != nil:
    section.add "X-Amz-Target", valid_612223
  var valid_612224 = header.getOrDefault("X-Amz-Signature")
  valid_612224 = validateParameter(valid_612224, JString, required = false,
                                 default = nil)
  if valid_612224 != nil:
    section.add "X-Amz-Signature", valid_612224
  var valid_612225 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612225 = validateParameter(valid_612225, JString, required = false,
                                 default = nil)
  if valid_612225 != nil:
    section.add "X-Amz-Content-Sha256", valid_612225
  var valid_612226 = header.getOrDefault("X-Amz-Date")
  valid_612226 = validateParameter(valid_612226, JString, required = false,
                                 default = nil)
  if valid_612226 != nil:
    section.add "X-Amz-Date", valid_612226
  var valid_612227 = header.getOrDefault("X-Amz-Credential")
  valid_612227 = validateParameter(valid_612227, JString, required = false,
                                 default = nil)
  if valid_612227 != nil:
    section.add "X-Amz-Credential", valid_612227
  var valid_612228 = header.getOrDefault("X-Amz-Security-Token")
  valid_612228 = validateParameter(valid_612228, JString, required = false,
                                 default = nil)
  if valid_612228 != nil:
    section.add "X-Amz-Security-Token", valid_612228
  var valid_612229 = header.getOrDefault("X-Amz-Algorithm")
  valid_612229 = validateParameter(valid_612229, JString, required = false,
                                 default = nil)
  if valid_612229 != nil:
    section.add "X-Amz-Algorithm", valid_612229
  var valid_612230 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612230 = validateParameter(valid_612230, JString, required = false,
                                 default = nil)
  if valid_612230 != nil:
    section.add "X-Amz-SignedHeaders", valid_612230
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612232: Call_GetInventorySchema_612220; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Return a list of inventory type names for the account, or return a list of attribute names for a specific Inventory item type. 
  ## 
  let valid = call_612232.validator(path, query, header, formData, body)
  let scheme = call_612232.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612232.url(scheme.get, call_612232.host, call_612232.base,
                         call_612232.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612232, url, valid)

proc call*(call_612233: Call_GetInventorySchema_612220; body: JsonNode): Recallable =
  ## getInventorySchema
  ## Return a list of inventory type names for the account, or return a list of attribute names for a specific Inventory item type. 
  ##   body: JObject (required)
  var body_612234 = newJObject()
  if body != nil:
    body_612234 = body
  result = call_612233.call(nil, nil, nil, nil, body_612234)

var getInventorySchema* = Call_GetInventorySchema_612220(
    name: "getInventorySchema", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetInventorySchema",
    validator: validate_GetInventorySchema_612221, base: "/",
    url: url_GetInventorySchema_612222, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMaintenanceWindow_612235 = ref object of OpenApiRestCall_610658
proc url_GetMaintenanceWindow_612237(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetMaintenanceWindow_612236(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612238 = header.getOrDefault("X-Amz-Target")
  valid_612238 = validateParameter(valid_612238, JString, required = true, default = newJString(
      "AmazonSSM.GetMaintenanceWindow"))
  if valid_612238 != nil:
    section.add "X-Amz-Target", valid_612238
  var valid_612239 = header.getOrDefault("X-Amz-Signature")
  valid_612239 = validateParameter(valid_612239, JString, required = false,
                                 default = nil)
  if valid_612239 != nil:
    section.add "X-Amz-Signature", valid_612239
  var valid_612240 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612240 = validateParameter(valid_612240, JString, required = false,
                                 default = nil)
  if valid_612240 != nil:
    section.add "X-Amz-Content-Sha256", valid_612240
  var valid_612241 = header.getOrDefault("X-Amz-Date")
  valid_612241 = validateParameter(valid_612241, JString, required = false,
                                 default = nil)
  if valid_612241 != nil:
    section.add "X-Amz-Date", valid_612241
  var valid_612242 = header.getOrDefault("X-Amz-Credential")
  valid_612242 = validateParameter(valid_612242, JString, required = false,
                                 default = nil)
  if valid_612242 != nil:
    section.add "X-Amz-Credential", valid_612242
  var valid_612243 = header.getOrDefault("X-Amz-Security-Token")
  valid_612243 = validateParameter(valid_612243, JString, required = false,
                                 default = nil)
  if valid_612243 != nil:
    section.add "X-Amz-Security-Token", valid_612243
  var valid_612244 = header.getOrDefault("X-Amz-Algorithm")
  valid_612244 = validateParameter(valid_612244, JString, required = false,
                                 default = nil)
  if valid_612244 != nil:
    section.add "X-Amz-Algorithm", valid_612244
  var valid_612245 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612245 = validateParameter(valid_612245, JString, required = false,
                                 default = nil)
  if valid_612245 != nil:
    section.add "X-Amz-SignedHeaders", valid_612245
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612247: Call_GetMaintenanceWindow_612235; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a maintenance window.
  ## 
  let valid = call_612247.validator(path, query, header, formData, body)
  let scheme = call_612247.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612247.url(scheme.get, call_612247.host, call_612247.base,
                         call_612247.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612247, url, valid)

proc call*(call_612248: Call_GetMaintenanceWindow_612235; body: JsonNode): Recallable =
  ## getMaintenanceWindow
  ## Retrieves a maintenance window.
  ##   body: JObject (required)
  var body_612249 = newJObject()
  if body != nil:
    body_612249 = body
  result = call_612248.call(nil, nil, nil, nil, body_612249)

var getMaintenanceWindow* = Call_GetMaintenanceWindow_612235(
    name: "getMaintenanceWindow", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetMaintenanceWindow",
    validator: validate_GetMaintenanceWindow_612236, base: "/",
    url: url_GetMaintenanceWindow_612237, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMaintenanceWindowExecution_612250 = ref object of OpenApiRestCall_610658
proc url_GetMaintenanceWindowExecution_612252(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetMaintenanceWindowExecution_612251(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612253 = header.getOrDefault("X-Amz-Target")
  valid_612253 = validateParameter(valid_612253, JString, required = true, default = newJString(
      "AmazonSSM.GetMaintenanceWindowExecution"))
  if valid_612253 != nil:
    section.add "X-Amz-Target", valid_612253
  var valid_612254 = header.getOrDefault("X-Amz-Signature")
  valid_612254 = validateParameter(valid_612254, JString, required = false,
                                 default = nil)
  if valid_612254 != nil:
    section.add "X-Amz-Signature", valid_612254
  var valid_612255 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612255 = validateParameter(valid_612255, JString, required = false,
                                 default = nil)
  if valid_612255 != nil:
    section.add "X-Amz-Content-Sha256", valid_612255
  var valid_612256 = header.getOrDefault("X-Amz-Date")
  valid_612256 = validateParameter(valid_612256, JString, required = false,
                                 default = nil)
  if valid_612256 != nil:
    section.add "X-Amz-Date", valid_612256
  var valid_612257 = header.getOrDefault("X-Amz-Credential")
  valid_612257 = validateParameter(valid_612257, JString, required = false,
                                 default = nil)
  if valid_612257 != nil:
    section.add "X-Amz-Credential", valid_612257
  var valid_612258 = header.getOrDefault("X-Amz-Security-Token")
  valid_612258 = validateParameter(valid_612258, JString, required = false,
                                 default = nil)
  if valid_612258 != nil:
    section.add "X-Amz-Security-Token", valid_612258
  var valid_612259 = header.getOrDefault("X-Amz-Algorithm")
  valid_612259 = validateParameter(valid_612259, JString, required = false,
                                 default = nil)
  if valid_612259 != nil:
    section.add "X-Amz-Algorithm", valid_612259
  var valid_612260 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612260 = validateParameter(valid_612260, JString, required = false,
                                 default = nil)
  if valid_612260 != nil:
    section.add "X-Amz-SignedHeaders", valid_612260
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612262: Call_GetMaintenanceWindowExecution_612250; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves details about a specific a maintenance window execution.
  ## 
  let valid = call_612262.validator(path, query, header, formData, body)
  let scheme = call_612262.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612262.url(scheme.get, call_612262.host, call_612262.base,
                         call_612262.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612262, url, valid)

proc call*(call_612263: Call_GetMaintenanceWindowExecution_612250; body: JsonNode): Recallable =
  ## getMaintenanceWindowExecution
  ## Retrieves details about a specific a maintenance window execution.
  ##   body: JObject (required)
  var body_612264 = newJObject()
  if body != nil:
    body_612264 = body
  result = call_612263.call(nil, nil, nil, nil, body_612264)

var getMaintenanceWindowExecution* = Call_GetMaintenanceWindowExecution_612250(
    name: "getMaintenanceWindowExecution", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetMaintenanceWindowExecution",
    validator: validate_GetMaintenanceWindowExecution_612251, base: "/",
    url: url_GetMaintenanceWindowExecution_612252,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMaintenanceWindowExecutionTask_612265 = ref object of OpenApiRestCall_610658
proc url_GetMaintenanceWindowExecutionTask_612267(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetMaintenanceWindowExecutionTask_612266(path: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612268 = header.getOrDefault("X-Amz-Target")
  valid_612268 = validateParameter(valid_612268, JString, required = true, default = newJString(
      "AmazonSSM.GetMaintenanceWindowExecutionTask"))
  if valid_612268 != nil:
    section.add "X-Amz-Target", valid_612268
  var valid_612269 = header.getOrDefault("X-Amz-Signature")
  valid_612269 = validateParameter(valid_612269, JString, required = false,
                                 default = nil)
  if valid_612269 != nil:
    section.add "X-Amz-Signature", valid_612269
  var valid_612270 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612270 = validateParameter(valid_612270, JString, required = false,
                                 default = nil)
  if valid_612270 != nil:
    section.add "X-Amz-Content-Sha256", valid_612270
  var valid_612271 = header.getOrDefault("X-Amz-Date")
  valid_612271 = validateParameter(valid_612271, JString, required = false,
                                 default = nil)
  if valid_612271 != nil:
    section.add "X-Amz-Date", valid_612271
  var valid_612272 = header.getOrDefault("X-Amz-Credential")
  valid_612272 = validateParameter(valid_612272, JString, required = false,
                                 default = nil)
  if valid_612272 != nil:
    section.add "X-Amz-Credential", valid_612272
  var valid_612273 = header.getOrDefault("X-Amz-Security-Token")
  valid_612273 = validateParameter(valid_612273, JString, required = false,
                                 default = nil)
  if valid_612273 != nil:
    section.add "X-Amz-Security-Token", valid_612273
  var valid_612274 = header.getOrDefault("X-Amz-Algorithm")
  valid_612274 = validateParameter(valid_612274, JString, required = false,
                                 default = nil)
  if valid_612274 != nil:
    section.add "X-Amz-Algorithm", valid_612274
  var valid_612275 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612275 = validateParameter(valid_612275, JString, required = false,
                                 default = nil)
  if valid_612275 != nil:
    section.add "X-Amz-SignedHeaders", valid_612275
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612277: Call_GetMaintenanceWindowExecutionTask_612265;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves the details about a specific task run as part of a maintenance window execution.
  ## 
  let valid = call_612277.validator(path, query, header, formData, body)
  let scheme = call_612277.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612277.url(scheme.get, call_612277.host, call_612277.base,
                         call_612277.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612277, url, valid)

proc call*(call_612278: Call_GetMaintenanceWindowExecutionTask_612265;
          body: JsonNode): Recallable =
  ## getMaintenanceWindowExecutionTask
  ## Retrieves the details about a specific task run as part of a maintenance window execution.
  ##   body: JObject (required)
  var body_612279 = newJObject()
  if body != nil:
    body_612279 = body
  result = call_612278.call(nil, nil, nil, nil, body_612279)

var getMaintenanceWindowExecutionTask* = Call_GetMaintenanceWindowExecutionTask_612265(
    name: "getMaintenanceWindowExecutionTask", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetMaintenanceWindowExecutionTask",
    validator: validate_GetMaintenanceWindowExecutionTask_612266, base: "/",
    url: url_GetMaintenanceWindowExecutionTask_612267,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMaintenanceWindowExecutionTaskInvocation_612280 = ref object of OpenApiRestCall_610658
proc url_GetMaintenanceWindowExecutionTaskInvocation_612282(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetMaintenanceWindowExecutionTaskInvocation_612281(path: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612283 = header.getOrDefault("X-Amz-Target")
  valid_612283 = validateParameter(valid_612283, JString, required = true, default = newJString(
      "AmazonSSM.GetMaintenanceWindowExecutionTaskInvocation"))
  if valid_612283 != nil:
    section.add "X-Amz-Target", valid_612283
  var valid_612284 = header.getOrDefault("X-Amz-Signature")
  valid_612284 = validateParameter(valid_612284, JString, required = false,
                                 default = nil)
  if valid_612284 != nil:
    section.add "X-Amz-Signature", valid_612284
  var valid_612285 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612285 = validateParameter(valid_612285, JString, required = false,
                                 default = nil)
  if valid_612285 != nil:
    section.add "X-Amz-Content-Sha256", valid_612285
  var valid_612286 = header.getOrDefault("X-Amz-Date")
  valid_612286 = validateParameter(valid_612286, JString, required = false,
                                 default = nil)
  if valid_612286 != nil:
    section.add "X-Amz-Date", valid_612286
  var valid_612287 = header.getOrDefault("X-Amz-Credential")
  valid_612287 = validateParameter(valid_612287, JString, required = false,
                                 default = nil)
  if valid_612287 != nil:
    section.add "X-Amz-Credential", valid_612287
  var valid_612288 = header.getOrDefault("X-Amz-Security-Token")
  valid_612288 = validateParameter(valid_612288, JString, required = false,
                                 default = nil)
  if valid_612288 != nil:
    section.add "X-Amz-Security-Token", valid_612288
  var valid_612289 = header.getOrDefault("X-Amz-Algorithm")
  valid_612289 = validateParameter(valid_612289, JString, required = false,
                                 default = nil)
  if valid_612289 != nil:
    section.add "X-Amz-Algorithm", valid_612289
  var valid_612290 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612290 = validateParameter(valid_612290, JString, required = false,
                                 default = nil)
  if valid_612290 != nil:
    section.add "X-Amz-SignedHeaders", valid_612290
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612292: Call_GetMaintenanceWindowExecutionTaskInvocation_612280;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves information about a specific task running on a specific target.
  ## 
  let valid = call_612292.validator(path, query, header, formData, body)
  let scheme = call_612292.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612292.url(scheme.get, call_612292.host, call_612292.base,
                         call_612292.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612292, url, valid)

proc call*(call_612293: Call_GetMaintenanceWindowExecutionTaskInvocation_612280;
          body: JsonNode): Recallable =
  ## getMaintenanceWindowExecutionTaskInvocation
  ## Retrieves information about a specific task running on a specific target.
  ##   body: JObject (required)
  var body_612294 = newJObject()
  if body != nil:
    body_612294 = body
  result = call_612293.call(nil, nil, nil, nil, body_612294)

var getMaintenanceWindowExecutionTaskInvocation* = Call_GetMaintenanceWindowExecutionTaskInvocation_612280(
    name: "getMaintenanceWindowExecutionTaskInvocation",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com", route: "/#X-Amz-Target=AmazonSSM.GetMaintenanceWindowExecutionTaskInvocation",
    validator: validate_GetMaintenanceWindowExecutionTaskInvocation_612281,
    base: "/", url: url_GetMaintenanceWindowExecutionTaskInvocation_612282,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMaintenanceWindowTask_612295 = ref object of OpenApiRestCall_610658
proc url_GetMaintenanceWindowTask_612297(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetMaintenanceWindowTask_612296(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612298 = header.getOrDefault("X-Amz-Target")
  valid_612298 = validateParameter(valid_612298, JString, required = true, default = newJString(
      "AmazonSSM.GetMaintenanceWindowTask"))
  if valid_612298 != nil:
    section.add "X-Amz-Target", valid_612298
  var valid_612299 = header.getOrDefault("X-Amz-Signature")
  valid_612299 = validateParameter(valid_612299, JString, required = false,
                                 default = nil)
  if valid_612299 != nil:
    section.add "X-Amz-Signature", valid_612299
  var valid_612300 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612300 = validateParameter(valid_612300, JString, required = false,
                                 default = nil)
  if valid_612300 != nil:
    section.add "X-Amz-Content-Sha256", valid_612300
  var valid_612301 = header.getOrDefault("X-Amz-Date")
  valid_612301 = validateParameter(valid_612301, JString, required = false,
                                 default = nil)
  if valid_612301 != nil:
    section.add "X-Amz-Date", valid_612301
  var valid_612302 = header.getOrDefault("X-Amz-Credential")
  valid_612302 = validateParameter(valid_612302, JString, required = false,
                                 default = nil)
  if valid_612302 != nil:
    section.add "X-Amz-Credential", valid_612302
  var valid_612303 = header.getOrDefault("X-Amz-Security-Token")
  valid_612303 = validateParameter(valid_612303, JString, required = false,
                                 default = nil)
  if valid_612303 != nil:
    section.add "X-Amz-Security-Token", valid_612303
  var valid_612304 = header.getOrDefault("X-Amz-Algorithm")
  valid_612304 = validateParameter(valid_612304, JString, required = false,
                                 default = nil)
  if valid_612304 != nil:
    section.add "X-Amz-Algorithm", valid_612304
  var valid_612305 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612305 = validateParameter(valid_612305, JString, required = false,
                                 default = nil)
  if valid_612305 != nil:
    section.add "X-Amz-SignedHeaders", valid_612305
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612307: Call_GetMaintenanceWindowTask_612295; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the tasks in a maintenance window.
  ## 
  let valid = call_612307.validator(path, query, header, formData, body)
  let scheme = call_612307.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612307.url(scheme.get, call_612307.host, call_612307.base,
                         call_612307.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612307, url, valid)

proc call*(call_612308: Call_GetMaintenanceWindowTask_612295; body: JsonNode): Recallable =
  ## getMaintenanceWindowTask
  ## Lists the tasks in a maintenance window.
  ##   body: JObject (required)
  var body_612309 = newJObject()
  if body != nil:
    body_612309 = body
  result = call_612308.call(nil, nil, nil, nil, body_612309)

var getMaintenanceWindowTask* = Call_GetMaintenanceWindowTask_612295(
    name: "getMaintenanceWindowTask", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetMaintenanceWindowTask",
    validator: validate_GetMaintenanceWindowTask_612296, base: "/",
    url: url_GetMaintenanceWindowTask_612297, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetOpsItem_612310 = ref object of OpenApiRestCall_610658
proc url_GetOpsItem_612312(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetOpsItem_612311(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612313 = header.getOrDefault("X-Amz-Target")
  valid_612313 = validateParameter(valid_612313, JString, required = true,
                                 default = newJString("AmazonSSM.GetOpsItem"))
  if valid_612313 != nil:
    section.add "X-Amz-Target", valid_612313
  var valid_612314 = header.getOrDefault("X-Amz-Signature")
  valid_612314 = validateParameter(valid_612314, JString, required = false,
                                 default = nil)
  if valid_612314 != nil:
    section.add "X-Amz-Signature", valid_612314
  var valid_612315 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612315 = validateParameter(valid_612315, JString, required = false,
                                 default = nil)
  if valid_612315 != nil:
    section.add "X-Amz-Content-Sha256", valid_612315
  var valid_612316 = header.getOrDefault("X-Amz-Date")
  valid_612316 = validateParameter(valid_612316, JString, required = false,
                                 default = nil)
  if valid_612316 != nil:
    section.add "X-Amz-Date", valid_612316
  var valid_612317 = header.getOrDefault("X-Amz-Credential")
  valid_612317 = validateParameter(valid_612317, JString, required = false,
                                 default = nil)
  if valid_612317 != nil:
    section.add "X-Amz-Credential", valid_612317
  var valid_612318 = header.getOrDefault("X-Amz-Security-Token")
  valid_612318 = validateParameter(valid_612318, JString, required = false,
                                 default = nil)
  if valid_612318 != nil:
    section.add "X-Amz-Security-Token", valid_612318
  var valid_612319 = header.getOrDefault("X-Amz-Algorithm")
  valid_612319 = validateParameter(valid_612319, JString, required = false,
                                 default = nil)
  if valid_612319 != nil:
    section.add "X-Amz-Algorithm", valid_612319
  var valid_612320 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612320 = validateParameter(valid_612320, JString, required = false,
                                 default = nil)
  if valid_612320 != nil:
    section.add "X-Amz-SignedHeaders", valid_612320
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612322: Call_GetOpsItem_612310; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Get information about an OpsItem by using the ID. You must have permission in AWS Identity and Access Management (IAM) to view information about an OpsItem. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter-getting-started.html">Getting Started with OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>.</p> <p>Operations engineers and IT professionals use OpsCenter to view, investigate, and remediate operational issues impacting the performance and health of their AWS resources. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter.html">AWS Systems Manager OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>. </p>
  ## 
  let valid = call_612322.validator(path, query, header, formData, body)
  let scheme = call_612322.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612322.url(scheme.get, call_612322.host, call_612322.base,
                         call_612322.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612322, url, valid)

proc call*(call_612323: Call_GetOpsItem_612310; body: JsonNode): Recallable =
  ## getOpsItem
  ## <p>Get information about an OpsItem by using the ID. You must have permission in AWS Identity and Access Management (IAM) to view information about an OpsItem. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter-getting-started.html">Getting Started with OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>.</p> <p>Operations engineers and IT professionals use OpsCenter to view, investigate, and remediate operational issues impacting the performance and health of their AWS resources. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter.html">AWS Systems Manager OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>. </p>
  ##   body: JObject (required)
  var body_612324 = newJObject()
  if body != nil:
    body_612324 = body
  result = call_612323.call(nil, nil, nil, nil, body_612324)

var getOpsItem* = Call_GetOpsItem_612310(name: "getOpsItem",
                                      meth: HttpMethod.HttpPost,
                                      host: "ssm.amazonaws.com", route: "/#X-Amz-Target=AmazonSSM.GetOpsItem",
                                      validator: validate_GetOpsItem_612311,
                                      base: "/", url: url_GetOpsItem_612312,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetOpsSummary_612325 = ref object of OpenApiRestCall_610658
proc url_GetOpsSummary_612327(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetOpsSummary_612326(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612328 = header.getOrDefault("X-Amz-Target")
  valid_612328 = validateParameter(valid_612328, JString, required = true, default = newJString(
      "AmazonSSM.GetOpsSummary"))
  if valid_612328 != nil:
    section.add "X-Amz-Target", valid_612328
  var valid_612329 = header.getOrDefault("X-Amz-Signature")
  valid_612329 = validateParameter(valid_612329, JString, required = false,
                                 default = nil)
  if valid_612329 != nil:
    section.add "X-Amz-Signature", valid_612329
  var valid_612330 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612330 = validateParameter(valid_612330, JString, required = false,
                                 default = nil)
  if valid_612330 != nil:
    section.add "X-Amz-Content-Sha256", valid_612330
  var valid_612331 = header.getOrDefault("X-Amz-Date")
  valid_612331 = validateParameter(valid_612331, JString, required = false,
                                 default = nil)
  if valid_612331 != nil:
    section.add "X-Amz-Date", valid_612331
  var valid_612332 = header.getOrDefault("X-Amz-Credential")
  valid_612332 = validateParameter(valid_612332, JString, required = false,
                                 default = nil)
  if valid_612332 != nil:
    section.add "X-Amz-Credential", valid_612332
  var valid_612333 = header.getOrDefault("X-Amz-Security-Token")
  valid_612333 = validateParameter(valid_612333, JString, required = false,
                                 default = nil)
  if valid_612333 != nil:
    section.add "X-Amz-Security-Token", valid_612333
  var valid_612334 = header.getOrDefault("X-Amz-Algorithm")
  valid_612334 = validateParameter(valid_612334, JString, required = false,
                                 default = nil)
  if valid_612334 != nil:
    section.add "X-Amz-Algorithm", valid_612334
  var valid_612335 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612335 = validateParameter(valid_612335, JString, required = false,
                                 default = nil)
  if valid_612335 != nil:
    section.add "X-Amz-SignedHeaders", valid_612335
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612337: Call_GetOpsSummary_612325; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## View a summary of OpsItems based on specified filters and aggregators.
  ## 
  let valid = call_612337.validator(path, query, header, formData, body)
  let scheme = call_612337.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612337.url(scheme.get, call_612337.host, call_612337.base,
                         call_612337.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612337, url, valid)

proc call*(call_612338: Call_GetOpsSummary_612325; body: JsonNode): Recallable =
  ## getOpsSummary
  ## View a summary of OpsItems based on specified filters and aggregators.
  ##   body: JObject (required)
  var body_612339 = newJObject()
  if body != nil:
    body_612339 = body
  result = call_612338.call(nil, nil, nil, nil, body_612339)

var getOpsSummary* = Call_GetOpsSummary_612325(name: "getOpsSummary",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetOpsSummary",
    validator: validate_GetOpsSummary_612326, base: "/", url: url_GetOpsSummary_612327,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetParameter_612340 = ref object of OpenApiRestCall_610658
proc url_GetParameter_612342(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetParameter_612341(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612343 = header.getOrDefault("X-Amz-Target")
  valid_612343 = validateParameter(valid_612343, JString, required = true,
                                 default = newJString("AmazonSSM.GetParameter"))
  if valid_612343 != nil:
    section.add "X-Amz-Target", valid_612343
  var valid_612344 = header.getOrDefault("X-Amz-Signature")
  valid_612344 = validateParameter(valid_612344, JString, required = false,
                                 default = nil)
  if valid_612344 != nil:
    section.add "X-Amz-Signature", valid_612344
  var valid_612345 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612345 = validateParameter(valid_612345, JString, required = false,
                                 default = nil)
  if valid_612345 != nil:
    section.add "X-Amz-Content-Sha256", valid_612345
  var valid_612346 = header.getOrDefault("X-Amz-Date")
  valid_612346 = validateParameter(valid_612346, JString, required = false,
                                 default = nil)
  if valid_612346 != nil:
    section.add "X-Amz-Date", valid_612346
  var valid_612347 = header.getOrDefault("X-Amz-Credential")
  valid_612347 = validateParameter(valid_612347, JString, required = false,
                                 default = nil)
  if valid_612347 != nil:
    section.add "X-Amz-Credential", valid_612347
  var valid_612348 = header.getOrDefault("X-Amz-Security-Token")
  valid_612348 = validateParameter(valid_612348, JString, required = false,
                                 default = nil)
  if valid_612348 != nil:
    section.add "X-Amz-Security-Token", valid_612348
  var valid_612349 = header.getOrDefault("X-Amz-Algorithm")
  valid_612349 = validateParameter(valid_612349, JString, required = false,
                                 default = nil)
  if valid_612349 != nil:
    section.add "X-Amz-Algorithm", valid_612349
  var valid_612350 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612350 = validateParameter(valid_612350, JString, required = false,
                                 default = nil)
  if valid_612350 != nil:
    section.add "X-Amz-SignedHeaders", valid_612350
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612352: Call_GetParameter_612340; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Get information about a parameter by using the parameter name. Don't confuse this API action with the <a>GetParameters</a> API action.
  ## 
  let valid = call_612352.validator(path, query, header, formData, body)
  let scheme = call_612352.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612352.url(scheme.get, call_612352.host, call_612352.base,
                         call_612352.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612352, url, valid)

proc call*(call_612353: Call_GetParameter_612340; body: JsonNode): Recallable =
  ## getParameter
  ## Get information about a parameter by using the parameter name. Don't confuse this API action with the <a>GetParameters</a> API action.
  ##   body: JObject (required)
  var body_612354 = newJObject()
  if body != nil:
    body_612354 = body
  result = call_612353.call(nil, nil, nil, nil, body_612354)

var getParameter* = Call_GetParameter_612340(name: "getParameter",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetParameter",
    validator: validate_GetParameter_612341, base: "/", url: url_GetParameter_612342,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetParameterHistory_612355 = ref object of OpenApiRestCall_610658
proc url_GetParameterHistory_612357(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetParameterHistory_612356(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Query a list of all parameters used by the AWS account.
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
  var valid_612358 = query.getOrDefault("MaxResults")
  valid_612358 = validateParameter(valid_612358, JString, required = false,
                                 default = nil)
  if valid_612358 != nil:
    section.add "MaxResults", valid_612358
  var valid_612359 = query.getOrDefault("NextToken")
  valid_612359 = validateParameter(valid_612359, JString, required = false,
                                 default = nil)
  if valid_612359 != nil:
    section.add "NextToken", valid_612359
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612360 = header.getOrDefault("X-Amz-Target")
  valid_612360 = validateParameter(valid_612360, JString, required = true, default = newJString(
      "AmazonSSM.GetParameterHistory"))
  if valid_612360 != nil:
    section.add "X-Amz-Target", valid_612360
  var valid_612361 = header.getOrDefault("X-Amz-Signature")
  valid_612361 = validateParameter(valid_612361, JString, required = false,
                                 default = nil)
  if valid_612361 != nil:
    section.add "X-Amz-Signature", valid_612361
  var valid_612362 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612362 = validateParameter(valid_612362, JString, required = false,
                                 default = nil)
  if valid_612362 != nil:
    section.add "X-Amz-Content-Sha256", valid_612362
  var valid_612363 = header.getOrDefault("X-Amz-Date")
  valid_612363 = validateParameter(valid_612363, JString, required = false,
                                 default = nil)
  if valid_612363 != nil:
    section.add "X-Amz-Date", valid_612363
  var valid_612364 = header.getOrDefault("X-Amz-Credential")
  valid_612364 = validateParameter(valid_612364, JString, required = false,
                                 default = nil)
  if valid_612364 != nil:
    section.add "X-Amz-Credential", valid_612364
  var valid_612365 = header.getOrDefault("X-Amz-Security-Token")
  valid_612365 = validateParameter(valid_612365, JString, required = false,
                                 default = nil)
  if valid_612365 != nil:
    section.add "X-Amz-Security-Token", valid_612365
  var valid_612366 = header.getOrDefault("X-Amz-Algorithm")
  valid_612366 = validateParameter(valid_612366, JString, required = false,
                                 default = nil)
  if valid_612366 != nil:
    section.add "X-Amz-Algorithm", valid_612366
  var valid_612367 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612367 = validateParameter(valid_612367, JString, required = false,
                                 default = nil)
  if valid_612367 != nil:
    section.add "X-Amz-SignedHeaders", valid_612367
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612369: Call_GetParameterHistory_612355; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Query a list of all parameters used by the AWS account.
  ## 
  let valid = call_612369.validator(path, query, header, formData, body)
  let scheme = call_612369.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612369.url(scheme.get, call_612369.host, call_612369.base,
                         call_612369.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612369, url, valid)

proc call*(call_612370: Call_GetParameterHistory_612355; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getParameterHistory
  ## Query a list of all parameters used by the AWS account.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_612371 = newJObject()
  var body_612372 = newJObject()
  add(query_612371, "MaxResults", newJString(MaxResults))
  add(query_612371, "NextToken", newJString(NextToken))
  if body != nil:
    body_612372 = body
  result = call_612370.call(nil, query_612371, nil, nil, body_612372)

var getParameterHistory* = Call_GetParameterHistory_612355(
    name: "getParameterHistory", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetParameterHistory",
    validator: validate_GetParameterHistory_612356, base: "/",
    url: url_GetParameterHistory_612357, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetParameters_612373 = ref object of OpenApiRestCall_610658
proc url_GetParameters_612375(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetParameters_612374(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612376 = header.getOrDefault("X-Amz-Target")
  valid_612376 = validateParameter(valid_612376, JString, required = true, default = newJString(
      "AmazonSSM.GetParameters"))
  if valid_612376 != nil:
    section.add "X-Amz-Target", valid_612376
  var valid_612377 = header.getOrDefault("X-Amz-Signature")
  valid_612377 = validateParameter(valid_612377, JString, required = false,
                                 default = nil)
  if valid_612377 != nil:
    section.add "X-Amz-Signature", valid_612377
  var valid_612378 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612378 = validateParameter(valid_612378, JString, required = false,
                                 default = nil)
  if valid_612378 != nil:
    section.add "X-Amz-Content-Sha256", valid_612378
  var valid_612379 = header.getOrDefault("X-Amz-Date")
  valid_612379 = validateParameter(valid_612379, JString, required = false,
                                 default = nil)
  if valid_612379 != nil:
    section.add "X-Amz-Date", valid_612379
  var valid_612380 = header.getOrDefault("X-Amz-Credential")
  valid_612380 = validateParameter(valid_612380, JString, required = false,
                                 default = nil)
  if valid_612380 != nil:
    section.add "X-Amz-Credential", valid_612380
  var valid_612381 = header.getOrDefault("X-Amz-Security-Token")
  valid_612381 = validateParameter(valid_612381, JString, required = false,
                                 default = nil)
  if valid_612381 != nil:
    section.add "X-Amz-Security-Token", valid_612381
  var valid_612382 = header.getOrDefault("X-Amz-Algorithm")
  valid_612382 = validateParameter(valid_612382, JString, required = false,
                                 default = nil)
  if valid_612382 != nil:
    section.add "X-Amz-Algorithm", valid_612382
  var valid_612383 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612383 = validateParameter(valid_612383, JString, required = false,
                                 default = nil)
  if valid_612383 != nil:
    section.add "X-Amz-SignedHeaders", valid_612383
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612385: Call_GetParameters_612373; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Get details of a parameter. Don't confuse this API action with the <a>GetParameter</a> API action.
  ## 
  let valid = call_612385.validator(path, query, header, formData, body)
  let scheme = call_612385.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612385.url(scheme.get, call_612385.host, call_612385.base,
                         call_612385.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612385, url, valid)

proc call*(call_612386: Call_GetParameters_612373; body: JsonNode): Recallable =
  ## getParameters
  ## Get details of a parameter. Don't confuse this API action with the <a>GetParameter</a> API action.
  ##   body: JObject (required)
  var body_612387 = newJObject()
  if body != nil:
    body_612387 = body
  result = call_612386.call(nil, nil, nil, nil, body_612387)

var getParameters* = Call_GetParameters_612373(name: "getParameters",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetParameters",
    validator: validate_GetParameters_612374, base: "/", url: url_GetParameters_612375,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetParametersByPath_612388 = ref object of OpenApiRestCall_610658
proc url_GetParametersByPath_612390(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetParametersByPath_612389(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p>Retrieve information about one or more parameters in a specific hierarchy. </p> <note> <p>Request results are returned on a best-effort basis. If you specify <code>MaxResults</code> in the request, the response includes information up to the limit specified. The number of items returned, however, can be between zero and the value of <code>MaxResults</code>. If the service reaches an internal limit while processing the results, it stops the operation and returns the matching values up to that point and a <code>NextToken</code>. You can specify the <code>NextToken</code> in a subsequent call to get the next set of results.</p> </note>
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
  var valid_612391 = query.getOrDefault("MaxResults")
  valid_612391 = validateParameter(valid_612391, JString, required = false,
                                 default = nil)
  if valid_612391 != nil:
    section.add "MaxResults", valid_612391
  var valid_612392 = query.getOrDefault("NextToken")
  valid_612392 = validateParameter(valid_612392, JString, required = false,
                                 default = nil)
  if valid_612392 != nil:
    section.add "NextToken", valid_612392
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612393 = header.getOrDefault("X-Amz-Target")
  valid_612393 = validateParameter(valid_612393, JString, required = true, default = newJString(
      "AmazonSSM.GetParametersByPath"))
  if valid_612393 != nil:
    section.add "X-Amz-Target", valid_612393
  var valid_612394 = header.getOrDefault("X-Amz-Signature")
  valid_612394 = validateParameter(valid_612394, JString, required = false,
                                 default = nil)
  if valid_612394 != nil:
    section.add "X-Amz-Signature", valid_612394
  var valid_612395 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612395 = validateParameter(valid_612395, JString, required = false,
                                 default = nil)
  if valid_612395 != nil:
    section.add "X-Amz-Content-Sha256", valid_612395
  var valid_612396 = header.getOrDefault("X-Amz-Date")
  valid_612396 = validateParameter(valid_612396, JString, required = false,
                                 default = nil)
  if valid_612396 != nil:
    section.add "X-Amz-Date", valid_612396
  var valid_612397 = header.getOrDefault("X-Amz-Credential")
  valid_612397 = validateParameter(valid_612397, JString, required = false,
                                 default = nil)
  if valid_612397 != nil:
    section.add "X-Amz-Credential", valid_612397
  var valid_612398 = header.getOrDefault("X-Amz-Security-Token")
  valid_612398 = validateParameter(valid_612398, JString, required = false,
                                 default = nil)
  if valid_612398 != nil:
    section.add "X-Amz-Security-Token", valid_612398
  var valid_612399 = header.getOrDefault("X-Amz-Algorithm")
  valid_612399 = validateParameter(valid_612399, JString, required = false,
                                 default = nil)
  if valid_612399 != nil:
    section.add "X-Amz-Algorithm", valid_612399
  var valid_612400 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612400 = validateParameter(valid_612400, JString, required = false,
                                 default = nil)
  if valid_612400 != nil:
    section.add "X-Amz-SignedHeaders", valid_612400
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612402: Call_GetParametersByPath_612388; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieve information about one or more parameters in a specific hierarchy. </p> <note> <p>Request results are returned on a best-effort basis. If you specify <code>MaxResults</code> in the request, the response includes information up to the limit specified. The number of items returned, however, can be between zero and the value of <code>MaxResults</code>. If the service reaches an internal limit while processing the results, it stops the operation and returns the matching values up to that point and a <code>NextToken</code>. You can specify the <code>NextToken</code> in a subsequent call to get the next set of results.</p> </note>
  ## 
  let valid = call_612402.validator(path, query, header, formData, body)
  let scheme = call_612402.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612402.url(scheme.get, call_612402.host, call_612402.base,
                         call_612402.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612402, url, valid)

proc call*(call_612403: Call_GetParametersByPath_612388; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getParametersByPath
  ## <p>Retrieve information about one or more parameters in a specific hierarchy. </p> <note> <p>Request results are returned on a best-effort basis. If you specify <code>MaxResults</code> in the request, the response includes information up to the limit specified. The number of items returned, however, can be between zero and the value of <code>MaxResults</code>. If the service reaches an internal limit while processing the results, it stops the operation and returns the matching values up to that point and a <code>NextToken</code>. You can specify the <code>NextToken</code> in a subsequent call to get the next set of results.</p> </note>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_612404 = newJObject()
  var body_612405 = newJObject()
  add(query_612404, "MaxResults", newJString(MaxResults))
  add(query_612404, "NextToken", newJString(NextToken))
  if body != nil:
    body_612405 = body
  result = call_612403.call(nil, query_612404, nil, nil, body_612405)

var getParametersByPath* = Call_GetParametersByPath_612388(
    name: "getParametersByPath", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetParametersByPath",
    validator: validate_GetParametersByPath_612389, base: "/",
    url: url_GetParametersByPath_612390, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPatchBaseline_612406 = ref object of OpenApiRestCall_610658
proc url_GetPatchBaseline_612408(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetPatchBaseline_612407(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612409 = header.getOrDefault("X-Amz-Target")
  valid_612409 = validateParameter(valid_612409, JString, required = true, default = newJString(
      "AmazonSSM.GetPatchBaseline"))
  if valid_612409 != nil:
    section.add "X-Amz-Target", valid_612409
  var valid_612410 = header.getOrDefault("X-Amz-Signature")
  valid_612410 = validateParameter(valid_612410, JString, required = false,
                                 default = nil)
  if valid_612410 != nil:
    section.add "X-Amz-Signature", valid_612410
  var valid_612411 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612411 = validateParameter(valid_612411, JString, required = false,
                                 default = nil)
  if valid_612411 != nil:
    section.add "X-Amz-Content-Sha256", valid_612411
  var valid_612412 = header.getOrDefault("X-Amz-Date")
  valid_612412 = validateParameter(valid_612412, JString, required = false,
                                 default = nil)
  if valid_612412 != nil:
    section.add "X-Amz-Date", valid_612412
  var valid_612413 = header.getOrDefault("X-Amz-Credential")
  valid_612413 = validateParameter(valid_612413, JString, required = false,
                                 default = nil)
  if valid_612413 != nil:
    section.add "X-Amz-Credential", valid_612413
  var valid_612414 = header.getOrDefault("X-Amz-Security-Token")
  valid_612414 = validateParameter(valid_612414, JString, required = false,
                                 default = nil)
  if valid_612414 != nil:
    section.add "X-Amz-Security-Token", valid_612414
  var valid_612415 = header.getOrDefault("X-Amz-Algorithm")
  valid_612415 = validateParameter(valid_612415, JString, required = false,
                                 default = nil)
  if valid_612415 != nil:
    section.add "X-Amz-Algorithm", valid_612415
  var valid_612416 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612416 = validateParameter(valid_612416, JString, required = false,
                                 default = nil)
  if valid_612416 != nil:
    section.add "X-Amz-SignedHeaders", valid_612416
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612418: Call_GetPatchBaseline_612406; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a patch baseline.
  ## 
  let valid = call_612418.validator(path, query, header, formData, body)
  let scheme = call_612418.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612418.url(scheme.get, call_612418.host, call_612418.base,
                         call_612418.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612418, url, valid)

proc call*(call_612419: Call_GetPatchBaseline_612406; body: JsonNode): Recallable =
  ## getPatchBaseline
  ## Retrieves information about a patch baseline.
  ##   body: JObject (required)
  var body_612420 = newJObject()
  if body != nil:
    body_612420 = body
  result = call_612419.call(nil, nil, nil, nil, body_612420)

var getPatchBaseline* = Call_GetPatchBaseline_612406(name: "getPatchBaseline",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetPatchBaseline",
    validator: validate_GetPatchBaseline_612407, base: "/",
    url: url_GetPatchBaseline_612408, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPatchBaselineForPatchGroup_612421 = ref object of OpenApiRestCall_610658
proc url_GetPatchBaselineForPatchGroup_612423(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetPatchBaselineForPatchGroup_612422(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612424 = header.getOrDefault("X-Amz-Target")
  valid_612424 = validateParameter(valid_612424, JString, required = true, default = newJString(
      "AmazonSSM.GetPatchBaselineForPatchGroup"))
  if valid_612424 != nil:
    section.add "X-Amz-Target", valid_612424
  var valid_612425 = header.getOrDefault("X-Amz-Signature")
  valid_612425 = validateParameter(valid_612425, JString, required = false,
                                 default = nil)
  if valid_612425 != nil:
    section.add "X-Amz-Signature", valid_612425
  var valid_612426 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612426 = validateParameter(valid_612426, JString, required = false,
                                 default = nil)
  if valid_612426 != nil:
    section.add "X-Amz-Content-Sha256", valid_612426
  var valid_612427 = header.getOrDefault("X-Amz-Date")
  valid_612427 = validateParameter(valid_612427, JString, required = false,
                                 default = nil)
  if valid_612427 != nil:
    section.add "X-Amz-Date", valid_612427
  var valid_612428 = header.getOrDefault("X-Amz-Credential")
  valid_612428 = validateParameter(valid_612428, JString, required = false,
                                 default = nil)
  if valid_612428 != nil:
    section.add "X-Amz-Credential", valid_612428
  var valid_612429 = header.getOrDefault("X-Amz-Security-Token")
  valid_612429 = validateParameter(valid_612429, JString, required = false,
                                 default = nil)
  if valid_612429 != nil:
    section.add "X-Amz-Security-Token", valid_612429
  var valid_612430 = header.getOrDefault("X-Amz-Algorithm")
  valid_612430 = validateParameter(valid_612430, JString, required = false,
                                 default = nil)
  if valid_612430 != nil:
    section.add "X-Amz-Algorithm", valid_612430
  var valid_612431 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612431 = validateParameter(valid_612431, JString, required = false,
                                 default = nil)
  if valid_612431 != nil:
    section.add "X-Amz-SignedHeaders", valid_612431
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612433: Call_GetPatchBaselineForPatchGroup_612421; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the patch baseline that should be used for the specified patch group.
  ## 
  let valid = call_612433.validator(path, query, header, formData, body)
  let scheme = call_612433.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612433.url(scheme.get, call_612433.host, call_612433.base,
                         call_612433.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612433, url, valid)

proc call*(call_612434: Call_GetPatchBaselineForPatchGroup_612421; body: JsonNode): Recallable =
  ## getPatchBaselineForPatchGroup
  ## Retrieves the patch baseline that should be used for the specified patch group.
  ##   body: JObject (required)
  var body_612435 = newJObject()
  if body != nil:
    body_612435 = body
  result = call_612434.call(nil, nil, nil, nil, body_612435)

var getPatchBaselineForPatchGroup* = Call_GetPatchBaselineForPatchGroup_612421(
    name: "getPatchBaselineForPatchGroup", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetPatchBaselineForPatchGroup",
    validator: validate_GetPatchBaselineForPatchGroup_612422, base: "/",
    url: url_GetPatchBaselineForPatchGroup_612423,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetServiceSetting_612436 = ref object of OpenApiRestCall_610658
proc url_GetServiceSetting_612438(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetServiceSetting_612437(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612439 = header.getOrDefault("X-Amz-Target")
  valid_612439 = validateParameter(valid_612439, JString, required = true, default = newJString(
      "AmazonSSM.GetServiceSetting"))
  if valid_612439 != nil:
    section.add "X-Amz-Target", valid_612439
  var valid_612440 = header.getOrDefault("X-Amz-Signature")
  valid_612440 = validateParameter(valid_612440, JString, required = false,
                                 default = nil)
  if valid_612440 != nil:
    section.add "X-Amz-Signature", valid_612440
  var valid_612441 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612441 = validateParameter(valid_612441, JString, required = false,
                                 default = nil)
  if valid_612441 != nil:
    section.add "X-Amz-Content-Sha256", valid_612441
  var valid_612442 = header.getOrDefault("X-Amz-Date")
  valid_612442 = validateParameter(valid_612442, JString, required = false,
                                 default = nil)
  if valid_612442 != nil:
    section.add "X-Amz-Date", valid_612442
  var valid_612443 = header.getOrDefault("X-Amz-Credential")
  valid_612443 = validateParameter(valid_612443, JString, required = false,
                                 default = nil)
  if valid_612443 != nil:
    section.add "X-Amz-Credential", valid_612443
  var valid_612444 = header.getOrDefault("X-Amz-Security-Token")
  valid_612444 = validateParameter(valid_612444, JString, required = false,
                                 default = nil)
  if valid_612444 != nil:
    section.add "X-Amz-Security-Token", valid_612444
  var valid_612445 = header.getOrDefault("X-Amz-Algorithm")
  valid_612445 = validateParameter(valid_612445, JString, required = false,
                                 default = nil)
  if valid_612445 != nil:
    section.add "X-Amz-Algorithm", valid_612445
  var valid_612446 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612446 = validateParameter(valid_612446, JString, required = false,
                                 default = nil)
  if valid_612446 != nil:
    section.add "X-Amz-SignedHeaders", valid_612446
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612448: Call_GetServiceSetting_612436; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> <code>ServiceSetting</code> is an account-level setting for an AWS service. This setting defines how a user interacts with or uses a service or a feature of a service. For example, if an AWS service charges money to the account based on feature or service usage, then the AWS service team might create a default setting of "false". This means the user can't use this feature unless they change the setting to "true" and intentionally opt in for a paid feature.</p> <p>Services map a <code>SettingId</code> object to a setting value. AWS services teams define the default value for a <code>SettingId</code>. You can't create a new <code>SettingId</code>, but you can overwrite the default value if you have the <code>ssm:UpdateServiceSetting</code> permission for the setting. Use the <a>UpdateServiceSetting</a> API action to change the default setting. Or use the <a>ResetServiceSetting</a> to change the value back to the original value defined by the AWS service team.</p> <p>Query the current service setting for the account. </p>
  ## 
  let valid = call_612448.validator(path, query, header, formData, body)
  let scheme = call_612448.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612448.url(scheme.get, call_612448.host, call_612448.base,
                         call_612448.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612448, url, valid)

proc call*(call_612449: Call_GetServiceSetting_612436; body: JsonNode): Recallable =
  ## getServiceSetting
  ## <p> <code>ServiceSetting</code> is an account-level setting for an AWS service. This setting defines how a user interacts with or uses a service or a feature of a service. For example, if an AWS service charges money to the account based on feature or service usage, then the AWS service team might create a default setting of "false". This means the user can't use this feature unless they change the setting to "true" and intentionally opt in for a paid feature.</p> <p>Services map a <code>SettingId</code> object to a setting value. AWS services teams define the default value for a <code>SettingId</code>. You can't create a new <code>SettingId</code>, but you can overwrite the default value if you have the <code>ssm:UpdateServiceSetting</code> permission for the setting. Use the <a>UpdateServiceSetting</a> API action to change the default setting. Or use the <a>ResetServiceSetting</a> to change the value back to the original value defined by the AWS service team.</p> <p>Query the current service setting for the account. </p>
  ##   body: JObject (required)
  var body_612450 = newJObject()
  if body != nil:
    body_612450 = body
  result = call_612449.call(nil, nil, nil, nil, body_612450)

var getServiceSetting* = Call_GetServiceSetting_612436(name: "getServiceSetting",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetServiceSetting",
    validator: validate_GetServiceSetting_612437, base: "/",
    url: url_GetServiceSetting_612438, schemes: {Scheme.Https, Scheme.Http})
type
  Call_LabelParameterVersion_612451 = ref object of OpenApiRestCall_610658
proc url_LabelParameterVersion_612453(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_LabelParameterVersion_612452(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612454 = header.getOrDefault("X-Amz-Target")
  valid_612454 = validateParameter(valid_612454, JString, required = true, default = newJString(
      "AmazonSSM.LabelParameterVersion"))
  if valid_612454 != nil:
    section.add "X-Amz-Target", valid_612454
  var valid_612455 = header.getOrDefault("X-Amz-Signature")
  valid_612455 = validateParameter(valid_612455, JString, required = false,
                                 default = nil)
  if valid_612455 != nil:
    section.add "X-Amz-Signature", valid_612455
  var valid_612456 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612456 = validateParameter(valid_612456, JString, required = false,
                                 default = nil)
  if valid_612456 != nil:
    section.add "X-Amz-Content-Sha256", valid_612456
  var valid_612457 = header.getOrDefault("X-Amz-Date")
  valid_612457 = validateParameter(valid_612457, JString, required = false,
                                 default = nil)
  if valid_612457 != nil:
    section.add "X-Amz-Date", valid_612457
  var valid_612458 = header.getOrDefault("X-Amz-Credential")
  valid_612458 = validateParameter(valid_612458, JString, required = false,
                                 default = nil)
  if valid_612458 != nil:
    section.add "X-Amz-Credential", valid_612458
  var valid_612459 = header.getOrDefault("X-Amz-Security-Token")
  valid_612459 = validateParameter(valid_612459, JString, required = false,
                                 default = nil)
  if valid_612459 != nil:
    section.add "X-Amz-Security-Token", valid_612459
  var valid_612460 = header.getOrDefault("X-Amz-Algorithm")
  valid_612460 = validateParameter(valid_612460, JString, required = false,
                                 default = nil)
  if valid_612460 != nil:
    section.add "X-Amz-Algorithm", valid_612460
  var valid_612461 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612461 = validateParameter(valid_612461, JString, required = false,
                                 default = nil)
  if valid_612461 != nil:
    section.add "X-Amz-SignedHeaders", valid_612461
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612463: Call_LabelParameterVersion_612451; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>A parameter label is a user-defined alias to help you manage different versions of a parameter. When you modify a parameter, Systems Manager automatically saves a new version and increments the version number by one. A label can help you remember the purpose of a parameter when there are multiple versions. </p> <p>Parameter labels have the following requirements and restrictions.</p> <ul> <li> <p>A version of a parameter can have a maximum of 10 labels.</p> </li> <li> <p>You can't attach the same label to different versions of the same parameter. For example, if version 1 has the label Production, then you can't attach Production to version 2.</p> </li> <li> <p>You can move a label from one version of a parameter to another.</p> </li> <li> <p>You can't create a label when you create a new parameter. You must attach a label to a specific version of a parameter.</p> </li> <li> <p>You can't delete a parameter label. If you no longer want to use a parameter label, then you must move it to a different version of a parameter.</p> </li> <li> <p>A label can have a maximum of 100 characters.</p> </li> <li> <p>Labels can contain letters (case sensitive), numbers, periods (.), hyphens (-), or underscores (_).</p> </li> <li> <p>Labels can't begin with a number, "aws," or "ssm" (not case sensitive). If a label fails to meet these requirements, then the label is not associated with a parameter and the system displays it in the list of InvalidLabels.</p> </li> </ul>
  ## 
  let valid = call_612463.validator(path, query, header, formData, body)
  let scheme = call_612463.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612463.url(scheme.get, call_612463.host, call_612463.base,
                         call_612463.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612463, url, valid)

proc call*(call_612464: Call_LabelParameterVersion_612451; body: JsonNode): Recallable =
  ## labelParameterVersion
  ## <p>A parameter label is a user-defined alias to help you manage different versions of a parameter. When you modify a parameter, Systems Manager automatically saves a new version and increments the version number by one. A label can help you remember the purpose of a parameter when there are multiple versions. </p> <p>Parameter labels have the following requirements and restrictions.</p> <ul> <li> <p>A version of a parameter can have a maximum of 10 labels.</p> </li> <li> <p>You can't attach the same label to different versions of the same parameter. For example, if version 1 has the label Production, then you can't attach Production to version 2.</p> </li> <li> <p>You can move a label from one version of a parameter to another.</p> </li> <li> <p>You can't create a label when you create a new parameter. You must attach a label to a specific version of a parameter.</p> </li> <li> <p>You can't delete a parameter label. If you no longer want to use a parameter label, then you must move it to a different version of a parameter.</p> </li> <li> <p>A label can have a maximum of 100 characters.</p> </li> <li> <p>Labels can contain letters (case sensitive), numbers, periods (.), hyphens (-), or underscores (_).</p> </li> <li> <p>Labels can't begin with a number, "aws," or "ssm" (not case sensitive). If a label fails to meet these requirements, then the label is not associated with a parameter and the system displays it in the list of InvalidLabels.</p> </li> </ul>
  ##   body: JObject (required)
  var body_612465 = newJObject()
  if body != nil:
    body_612465 = body
  result = call_612464.call(nil, nil, nil, nil, body_612465)

var labelParameterVersion* = Call_LabelParameterVersion_612451(
    name: "labelParameterVersion", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.LabelParameterVersion",
    validator: validate_LabelParameterVersion_612452, base: "/",
    url: url_LabelParameterVersion_612453, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAssociationVersions_612466 = ref object of OpenApiRestCall_610658
proc url_ListAssociationVersions_612468(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListAssociationVersions_612467(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612469 = header.getOrDefault("X-Amz-Target")
  valid_612469 = validateParameter(valid_612469, JString, required = true, default = newJString(
      "AmazonSSM.ListAssociationVersions"))
  if valid_612469 != nil:
    section.add "X-Amz-Target", valid_612469
  var valid_612470 = header.getOrDefault("X-Amz-Signature")
  valid_612470 = validateParameter(valid_612470, JString, required = false,
                                 default = nil)
  if valid_612470 != nil:
    section.add "X-Amz-Signature", valid_612470
  var valid_612471 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612471 = validateParameter(valid_612471, JString, required = false,
                                 default = nil)
  if valid_612471 != nil:
    section.add "X-Amz-Content-Sha256", valid_612471
  var valid_612472 = header.getOrDefault("X-Amz-Date")
  valid_612472 = validateParameter(valid_612472, JString, required = false,
                                 default = nil)
  if valid_612472 != nil:
    section.add "X-Amz-Date", valid_612472
  var valid_612473 = header.getOrDefault("X-Amz-Credential")
  valid_612473 = validateParameter(valid_612473, JString, required = false,
                                 default = nil)
  if valid_612473 != nil:
    section.add "X-Amz-Credential", valid_612473
  var valid_612474 = header.getOrDefault("X-Amz-Security-Token")
  valid_612474 = validateParameter(valid_612474, JString, required = false,
                                 default = nil)
  if valid_612474 != nil:
    section.add "X-Amz-Security-Token", valid_612474
  var valid_612475 = header.getOrDefault("X-Amz-Algorithm")
  valid_612475 = validateParameter(valid_612475, JString, required = false,
                                 default = nil)
  if valid_612475 != nil:
    section.add "X-Amz-Algorithm", valid_612475
  var valid_612476 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612476 = validateParameter(valid_612476, JString, required = false,
                                 default = nil)
  if valid_612476 != nil:
    section.add "X-Amz-SignedHeaders", valid_612476
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612478: Call_ListAssociationVersions_612466; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves all versions of an association for a specific association ID.
  ## 
  let valid = call_612478.validator(path, query, header, formData, body)
  let scheme = call_612478.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612478.url(scheme.get, call_612478.host, call_612478.base,
                         call_612478.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612478, url, valid)

proc call*(call_612479: Call_ListAssociationVersions_612466; body: JsonNode): Recallable =
  ## listAssociationVersions
  ## Retrieves all versions of an association for a specific association ID.
  ##   body: JObject (required)
  var body_612480 = newJObject()
  if body != nil:
    body_612480 = body
  result = call_612479.call(nil, nil, nil, nil, body_612480)

var listAssociationVersions* = Call_ListAssociationVersions_612466(
    name: "listAssociationVersions", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.ListAssociationVersions",
    validator: validate_ListAssociationVersions_612467, base: "/",
    url: url_ListAssociationVersions_612468, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAssociations_612481 = ref object of OpenApiRestCall_610658
proc url_ListAssociations_612483(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListAssociations_612482(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Returns all State Manager associations in the current AWS account and Region. You can limit the results to a specific State Manager association document or instance by specifying a filter.
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
  var valid_612484 = query.getOrDefault("MaxResults")
  valid_612484 = validateParameter(valid_612484, JString, required = false,
                                 default = nil)
  if valid_612484 != nil:
    section.add "MaxResults", valid_612484
  var valid_612485 = query.getOrDefault("NextToken")
  valid_612485 = validateParameter(valid_612485, JString, required = false,
                                 default = nil)
  if valid_612485 != nil:
    section.add "NextToken", valid_612485
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612486 = header.getOrDefault("X-Amz-Target")
  valid_612486 = validateParameter(valid_612486, JString, required = true, default = newJString(
      "AmazonSSM.ListAssociations"))
  if valid_612486 != nil:
    section.add "X-Amz-Target", valid_612486
  var valid_612487 = header.getOrDefault("X-Amz-Signature")
  valid_612487 = validateParameter(valid_612487, JString, required = false,
                                 default = nil)
  if valid_612487 != nil:
    section.add "X-Amz-Signature", valid_612487
  var valid_612488 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612488 = validateParameter(valid_612488, JString, required = false,
                                 default = nil)
  if valid_612488 != nil:
    section.add "X-Amz-Content-Sha256", valid_612488
  var valid_612489 = header.getOrDefault("X-Amz-Date")
  valid_612489 = validateParameter(valid_612489, JString, required = false,
                                 default = nil)
  if valid_612489 != nil:
    section.add "X-Amz-Date", valid_612489
  var valid_612490 = header.getOrDefault("X-Amz-Credential")
  valid_612490 = validateParameter(valid_612490, JString, required = false,
                                 default = nil)
  if valid_612490 != nil:
    section.add "X-Amz-Credential", valid_612490
  var valid_612491 = header.getOrDefault("X-Amz-Security-Token")
  valid_612491 = validateParameter(valid_612491, JString, required = false,
                                 default = nil)
  if valid_612491 != nil:
    section.add "X-Amz-Security-Token", valid_612491
  var valid_612492 = header.getOrDefault("X-Amz-Algorithm")
  valid_612492 = validateParameter(valid_612492, JString, required = false,
                                 default = nil)
  if valid_612492 != nil:
    section.add "X-Amz-Algorithm", valid_612492
  var valid_612493 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612493 = validateParameter(valid_612493, JString, required = false,
                                 default = nil)
  if valid_612493 != nil:
    section.add "X-Amz-SignedHeaders", valid_612493
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612495: Call_ListAssociations_612481; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns all State Manager associations in the current AWS account and Region. You can limit the results to a specific State Manager association document or instance by specifying a filter.
  ## 
  let valid = call_612495.validator(path, query, header, formData, body)
  let scheme = call_612495.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612495.url(scheme.get, call_612495.host, call_612495.base,
                         call_612495.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612495, url, valid)

proc call*(call_612496: Call_ListAssociations_612481; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listAssociations
  ## Returns all State Manager associations in the current AWS account and Region. You can limit the results to a specific State Manager association document or instance by specifying a filter.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_612497 = newJObject()
  var body_612498 = newJObject()
  add(query_612497, "MaxResults", newJString(MaxResults))
  add(query_612497, "NextToken", newJString(NextToken))
  if body != nil:
    body_612498 = body
  result = call_612496.call(nil, query_612497, nil, nil, body_612498)

var listAssociations* = Call_ListAssociations_612481(name: "listAssociations",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.ListAssociations",
    validator: validate_ListAssociations_612482, base: "/",
    url: url_ListAssociations_612483, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListCommandInvocations_612499 = ref object of OpenApiRestCall_610658
proc url_ListCommandInvocations_612501(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListCommandInvocations_612500(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## An invocation is copy of a command sent to a specific instance. A command can apply to one or more instances. A command invocation applies to one instance. For example, if a user runs SendCommand against three instances, then a command invocation is created for each requested instance ID. ListCommandInvocations provide status about command execution.
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
  var valid_612502 = query.getOrDefault("MaxResults")
  valid_612502 = validateParameter(valid_612502, JString, required = false,
                                 default = nil)
  if valid_612502 != nil:
    section.add "MaxResults", valid_612502
  var valid_612503 = query.getOrDefault("NextToken")
  valid_612503 = validateParameter(valid_612503, JString, required = false,
                                 default = nil)
  if valid_612503 != nil:
    section.add "NextToken", valid_612503
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612504 = header.getOrDefault("X-Amz-Target")
  valid_612504 = validateParameter(valid_612504, JString, required = true, default = newJString(
      "AmazonSSM.ListCommandInvocations"))
  if valid_612504 != nil:
    section.add "X-Amz-Target", valid_612504
  var valid_612505 = header.getOrDefault("X-Amz-Signature")
  valid_612505 = validateParameter(valid_612505, JString, required = false,
                                 default = nil)
  if valid_612505 != nil:
    section.add "X-Amz-Signature", valid_612505
  var valid_612506 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612506 = validateParameter(valid_612506, JString, required = false,
                                 default = nil)
  if valid_612506 != nil:
    section.add "X-Amz-Content-Sha256", valid_612506
  var valid_612507 = header.getOrDefault("X-Amz-Date")
  valid_612507 = validateParameter(valid_612507, JString, required = false,
                                 default = nil)
  if valid_612507 != nil:
    section.add "X-Amz-Date", valid_612507
  var valid_612508 = header.getOrDefault("X-Amz-Credential")
  valid_612508 = validateParameter(valid_612508, JString, required = false,
                                 default = nil)
  if valid_612508 != nil:
    section.add "X-Amz-Credential", valid_612508
  var valid_612509 = header.getOrDefault("X-Amz-Security-Token")
  valid_612509 = validateParameter(valid_612509, JString, required = false,
                                 default = nil)
  if valid_612509 != nil:
    section.add "X-Amz-Security-Token", valid_612509
  var valid_612510 = header.getOrDefault("X-Amz-Algorithm")
  valid_612510 = validateParameter(valid_612510, JString, required = false,
                                 default = nil)
  if valid_612510 != nil:
    section.add "X-Amz-Algorithm", valid_612510
  var valid_612511 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612511 = validateParameter(valid_612511, JString, required = false,
                                 default = nil)
  if valid_612511 != nil:
    section.add "X-Amz-SignedHeaders", valid_612511
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612513: Call_ListCommandInvocations_612499; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## An invocation is copy of a command sent to a specific instance. A command can apply to one or more instances. A command invocation applies to one instance. For example, if a user runs SendCommand against three instances, then a command invocation is created for each requested instance ID. ListCommandInvocations provide status about command execution.
  ## 
  let valid = call_612513.validator(path, query, header, formData, body)
  let scheme = call_612513.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612513.url(scheme.get, call_612513.host, call_612513.base,
                         call_612513.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612513, url, valid)

proc call*(call_612514: Call_ListCommandInvocations_612499; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listCommandInvocations
  ## An invocation is copy of a command sent to a specific instance. A command can apply to one or more instances. A command invocation applies to one instance. For example, if a user runs SendCommand against three instances, then a command invocation is created for each requested instance ID. ListCommandInvocations provide status about command execution.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_612515 = newJObject()
  var body_612516 = newJObject()
  add(query_612515, "MaxResults", newJString(MaxResults))
  add(query_612515, "NextToken", newJString(NextToken))
  if body != nil:
    body_612516 = body
  result = call_612514.call(nil, query_612515, nil, nil, body_612516)

var listCommandInvocations* = Call_ListCommandInvocations_612499(
    name: "listCommandInvocations", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.ListCommandInvocations",
    validator: validate_ListCommandInvocations_612500, base: "/",
    url: url_ListCommandInvocations_612501, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListCommands_612517 = ref object of OpenApiRestCall_610658
proc url_ListCommands_612519(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListCommands_612518(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists the commands requested by users of the AWS account.
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
  var valid_612520 = query.getOrDefault("MaxResults")
  valid_612520 = validateParameter(valid_612520, JString, required = false,
                                 default = nil)
  if valid_612520 != nil:
    section.add "MaxResults", valid_612520
  var valid_612521 = query.getOrDefault("NextToken")
  valid_612521 = validateParameter(valid_612521, JString, required = false,
                                 default = nil)
  if valid_612521 != nil:
    section.add "NextToken", valid_612521
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612522 = header.getOrDefault("X-Amz-Target")
  valid_612522 = validateParameter(valid_612522, JString, required = true,
                                 default = newJString("AmazonSSM.ListCommands"))
  if valid_612522 != nil:
    section.add "X-Amz-Target", valid_612522
  var valid_612523 = header.getOrDefault("X-Amz-Signature")
  valid_612523 = validateParameter(valid_612523, JString, required = false,
                                 default = nil)
  if valid_612523 != nil:
    section.add "X-Amz-Signature", valid_612523
  var valid_612524 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612524 = validateParameter(valid_612524, JString, required = false,
                                 default = nil)
  if valid_612524 != nil:
    section.add "X-Amz-Content-Sha256", valid_612524
  var valid_612525 = header.getOrDefault("X-Amz-Date")
  valid_612525 = validateParameter(valid_612525, JString, required = false,
                                 default = nil)
  if valid_612525 != nil:
    section.add "X-Amz-Date", valid_612525
  var valid_612526 = header.getOrDefault("X-Amz-Credential")
  valid_612526 = validateParameter(valid_612526, JString, required = false,
                                 default = nil)
  if valid_612526 != nil:
    section.add "X-Amz-Credential", valid_612526
  var valid_612527 = header.getOrDefault("X-Amz-Security-Token")
  valid_612527 = validateParameter(valid_612527, JString, required = false,
                                 default = nil)
  if valid_612527 != nil:
    section.add "X-Amz-Security-Token", valid_612527
  var valid_612528 = header.getOrDefault("X-Amz-Algorithm")
  valid_612528 = validateParameter(valid_612528, JString, required = false,
                                 default = nil)
  if valid_612528 != nil:
    section.add "X-Amz-Algorithm", valid_612528
  var valid_612529 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612529 = validateParameter(valid_612529, JString, required = false,
                                 default = nil)
  if valid_612529 != nil:
    section.add "X-Amz-SignedHeaders", valid_612529
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612531: Call_ListCommands_612517; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the commands requested by users of the AWS account.
  ## 
  let valid = call_612531.validator(path, query, header, formData, body)
  let scheme = call_612531.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612531.url(scheme.get, call_612531.host, call_612531.base,
                         call_612531.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612531, url, valid)

proc call*(call_612532: Call_ListCommands_612517; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listCommands
  ## Lists the commands requested by users of the AWS account.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_612533 = newJObject()
  var body_612534 = newJObject()
  add(query_612533, "MaxResults", newJString(MaxResults))
  add(query_612533, "NextToken", newJString(NextToken))
  if body != nil:
    body_612534 = body
  result = call_612532.call(nil, query_612533, nil, nil, body_612534)

var listCommands* = Call_ListCommands_612517(name: "listCommands",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.ListCommands",
    validator: validate_ListCommands_612518, base: "/", url: url_ListCommands_612519,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListComplianceItems_612535 = ref object of OpenApiRestCall_610658
proc url_ListComplianceItems_612537(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListComplianceItems_612536(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612538 = header.getOrDefault("X-Amz-Target")
  valid_612538 = validateParameter(valid_612538, JString, required = true, default = newJString(
      "AmazonSSM.ListComplianceItems"))
  if valid_612538 != nil:
    section.add "X-Amz-Target", valid_612538
  var valid_612539 = header.getOrDefault("X-Amz-Signature")
  valid_612539 = validateParameter(valid_612539, JString, required = false,
                                 default = nil)
  if valid_612539 != nil:
    section.add "X-Amz-Signature", valid_612539
  var valid_612540 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612540 = validateParameter(valid_612540, JString, required = false,
                                 default = nil)
  if valid_612540 != nil:
    section.add "X-Amz-Content-Sha256", valid_612540
  var valid_612541 = header.getOrDefault("X-Amz-Date")
  valid_612541 = validateParameter(valid_612541, JString, required = false,
                                 default = nil)
  if valid_612541 != nil:
    section.add "X-Amz-Date", valid_612541
  var valid_612542 = header.getOrDefault("X-Amz-Credential")
  valid_612542 = validateParameter(valid_612542, JString, required = false,
                                 default = nil)
  if valid_612542 != nil:
    section.add "X-Amz-Credential", valid_612542
  var valid_612543 = header.getOrDefault("X-Amz-Security-Token")
  valid_612543 = validateParameter(valid_612543, JString, required = false,
                                 default = nil)
  if valid_612543 != nil:
    section.add "X-Amz-Security-Token", valid_612543
  var valid_612544 = header.getOrDefault("X-Amz-Algorithm")
  valid_612544 = validateParameter(valid_612544, JString, required = false,
                                 default = nil)
  if valid_612544 != nil:
    section.add "X-Amz-Algorithm", valid_612544
  var valid_612545 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612545 = validateParameter(valid_612545, JString, required = false,
                                 default = nil)
  if valid_612545 != nil:
    section.add "X-Amz-SignedHeaders", valid_612545
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612547: Call_ListComplianceItems_612535; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## For a specified resource ID, this API action returns a list of compliance statuses for different resource types. Currently, you can only specify one resource ID per call. List results depend on the criteria specified in the filter. 
  ## 
  let valid = call_612547.validator(path, query, header, formData, body)
  let scheme = call_612547.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612547.url(scheme.get, call_612547.host, call_612547.base,
                         call_612547.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612547, url, valid)

proc call*(call_612548: Call_ListComplianceItems_612535; body: JsonNode): Recallable =
  ## listComplianceItems
  ## For a specified resource ID, this API action returns a list of compliance statuses for different resource types. Currently, you can only specify one resource ID per call. List results depend on the criteria specified in the filter. 
  ##   body: JObject (required)
  var body_612549 = newJObject()
  if body != nil:
    body_612549 = body
  result = call_612548.call(nil, nil, nil, nil, body_612549)

var listComplianceItems* = Call_ListComplianceItems_612535(
    name: "listComplianceItems", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.ListComplianceItems",
    validator: validate_ListComplianceItems_612536, base: "/",
    url: url_ListComplianceItems_612537, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListComplianceSummaries_612550 = ref object of OpenApiRestCall_610658
proc url_ListComplianceSummaries_612552(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListComplianceSummaries_612551(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612553 = header.getOrDefault("X-Amz-Target")
  valid_612553 = validateParameter(valid_612553, JString, required = true, default = newJString(
      "AmazonSSM.ListComplianceSummaries"))
  if valid_612553 != nil:
    section.add "X-Amz-Target", valid_612553
  var valid_612554 = header.getOrDefault("X-Amz-Signature")
  valid_612554 = validateParameter(valid_612554, JString, required = false,
                                 default = nil)
  if valid_612554 != nil:
    section.add "X-Amz-Signature", valid_612554
  var valid_612555 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612555 = validateParameter(valid_612555, JString, required = false,
                                 default = nil)
  if valid_612555 != nil:
    section.add "X-Amz-Content-Sha256", valid_612555
  var valid_612556 = header.getOrDefault("X-Amz-Date")
  valid_612556 = validateParameter(valid_612556, JString, required = false,
                                 default = nil)
  if valid_612556 != nil:
    section.add "X-Amz-Date", valid_612556
  var valid_612557 = header.getOrDefault("X-Amz-Credential")
  valid_612557 = validateParameter(valid_612557, JString, required = false,
                                 default = nil)
  if valid_612557 != nil:
    section.add "X-Amz-Credential", valid_612557
  var valid_612558 = header.getOrDefault("X-Amz-Security-Token")
  valid_612558 = validateParameter(valid_612558, JString, required = false,
                                 default = nil)
  if valid_612558 != nil:
    section.add "X-Amz-Security-Token", valid_612558
  var valid_612559 = header.getOrDefault("X-Amz-Algorithm")
  valid_612559 = validateParameter(valid_612559, JString, required = false,
                                 default = nil)
  if valid_612559 != nil:
    section.add "X-Amz-Algorithm", valid_612559
  var valid_612560 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612560 = validateParameter(valid_612560, JString, required = false,
                                 default = nil)
  if valid_612560 != nil:
    section.add "X-Amz-SignedHeaders", valid_612560
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612562: Call_ListComplianceSummaries_612550; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a summary count of compliant and non-compliant resources for a compliance type. For example, this call can return State Manager associations, patches, or custom compliance types according to the filter criteria that you specify. 
  ## 
  let valid = call_612562.validator(path, query, header, formData, body)
  let scheme = call_612562.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612562.url(scheme.get, call_612562.host, call_612562.base,
                         call_612562.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612562, url, valid)

proc call*(call_612563: Call_ListComplianceSummaries_612550; body: JsonNode): Recallable =
  ## listComplianceSummaries
  ## Returns a summary count of compliant and non-compliant resources for a compliance type. For example, this call can return State Manager associations, patches, or custom compliance types according to the filter criteria that you specify. 
  ##   body: JObject (required)
  var body_612564 = newJObject()
  if body != nil:
    body_612564 = body
  result = call_612563.call(nil, nil, nil, nil, body_612564)

var listComplianceSummaries* = Call_ListComplianceSummaries_612550(
    name: "listComplianceSummaries", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.ListComplianceSummaries",
    validator: validate_ListComplianceSummaries_612551, base: "/",
    url: url_ListComplianceSummaries_612552, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDocumentVersions_612565 = ref object of OpenApiRestCall_610658
proc url_ListDocumentVersions_612567(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListDocumentVersions_612566(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612568 = header.getOrDefault("X-Amz-Target")
  valid_612568 = validateParameter(valid_612568, JString, required = true, default = newJString(
      "AmazonSSM.ListDocumentVersions"))
  if valid_612568 != nil:
    section.add "X-Amz-Target", valid_612568
  var valid_612569 = header.getOrDefault("X-Amz-Signature")
  valid_612569 = validateParameter(valid_612569, JString, required = false,
                                 default = nil)
  if valid_612569 != nil:
    section.add "X-Amz-Signature", valid_612569
  var valid_612570 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612570 = validateParameter(valid_612570, JString, required = false,
                                 default = nil)
  if valid_612570 != nil:
    section.add "X-Amz-Content-Sha256", valid_612570
  var valid_612571 = header.getOrDefault("X-Amz-Date")
  valid_612571 = validateParameter(valid_612571, JString, required = false,
                                 default = nil)
  if valid_612571 != nil:
    section.add "X-Amz-Date", valid_612571
  var valid_612572 = header.getOrDefault("X-Amz-Credential")
  valid_612572 = validateParameter(valid_612572, JString, required = false,
                                 default = nil)
  if valid_612572 != nil:
    section.add "X-Amz-Credential", valid_612572
  var valid_612573 = header.getOrDefault("X-Amz-Security-Token")
  valid_612573 = validateParameter(valid_612573, JString, required = false,
                                 default = nil)
  if valid_612573 != nil:
    section.add "X-Amz-Security-Token", valid_612573
  var valid_612574 = header.getOrDefault("X-Amz-Algorithm")
  valid_612574 = validateParameter(valid_612574, JString, required = false,
                                 default = nil)
  if valid_612574 != nil:
    section.add "X-Amz-Algorithm", valid_612574
  var valid_612575 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612575 = validateParameter(valid_612575, JString, required = false,
                                 default = nil)
  if valid_612575 != nil:
    section.add "X-Amz-SignedHeaders", valid_612575
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612577: Call_ListDocumentVersions_612565; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List all versions for a document.
  ## 
  let valid = call_612577.validator(path, query, header, formData, body)
  let scheme = call_612577.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612577.url(scheme.get, call_612577.host, call_612577.base,
                         call_612577.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612577, url, valid)

proc call*(call_612578: Call_ListDocumentVersions_612565; body: JsonNode): Recallable =
  ## listDocumentVersions
  ## List all versions for a document.
  ##   body: JObject (required)
  var body_612579 = newJObject()
  if body != nil:
    body_612579 = body
  result = call_612578.call(nil, nil, nil, nil, body_612579)

var listDocumentVersions* = Call_ListDocumentVersions_612565(
    name: "listDocumentVersions", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.ListDocumentVersions",
    validator: validate_ListDocumentVersions_612566, base: "/",
    url: url_ListDocumentVersions_612567, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDocuments_612580 = ref object of OpenApiRestCall_610658
proc url_ListDocuments_612582(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListDocuments_612581(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns all Systems Manager (SSM) documents in the current AWS account and Region. You can limit the results of this request by using a filter.
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
  var valid_612583 = query.getOrDefault("MaxResults")
  valid_612583 = validateParameter(valid_612583, JString, required = false,
                                 default = nil)
  if valid_612583 != nil:
    section.add "MaxResults", valid_612583
  var valid_612584 = query.getOrDefault("NextToken")
  valid_612584 = validateParameter(valid_612584, JString, required = false,
                                 default = nil)
  if valid_612584 != nil:
    section.add "NextToken", valid_612584
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612585 = header.getOrDefault("X-Amz-Target")
  valid_612585 = validateParameter(valid_612585, JString, required = true, default = newJString(
      "AmazonSSM.ListDocuments"))
  if valid_612585 != nil:
    section.add "X-Amz-Target", valid_612585
  var valid_612586 = header.getOrDefault("X-Amz-Signature")
  valid_612586 = validateParameter(valid_612586, JString, required = false,
                                 default = nil)
  if valid_612586 != nil:
    section.add "X-Amz-Signature", valid_612586
  var valid_612587 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612587 = validateParameter(valid_612587, JString, required = false,
                                 default = nil)
  if valid_612587 != nil:
    section.add "X-Amz-Content-Sha256", valid_612587
  var valid_612588 = header.getOrDefault("X-Amz-Date")
  valid_612588 = validateParameter(valid_612588, JString, required = false,
                                 default = nil)
  if valid_612588 != nil:
    section.add "X-Amz-Date", valid_612588
  var valid_612589 = header.getOrDefault("X-Amz-Credential")
  valid_612589 = validateParameter(valid_612589, JString, required = false,
                                 default = nil)
  if valid_612589 != nil:
    section.add "X-Amz-Credential", valid_612589
  var valid_612590 = header.getOrDefault("X-Amz-Security-Token")
  valid_612590 = validateParameter(valid_612590, JString, required = false,
                                 default = nil)
  if valid_612590 != nil:
    section.add "X-Amz-Security-Token", valid_612590
  var valid_612591 = header.getOrDefault("X-Amz-Algorithm")
  valid_612591 = validateParameter(valid_612591, JString, required = false,
                                 default = nil)
  if valid_612591 != nil:
    section.add "X-Amz-Algorithm", valid_612591
  var valid_612592 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612592 = validateParameter(valid_612592, JString, required = false,
                                 default = nil)
  if valid_612592 != nil:
    section.add "X-Amz-SignedHeaders", valid_612592
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612594: Call_ListDocuments_612580; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns all Systems Manager (SSM) documents in the current AWS account and Region. You can limit the results of this request by using a filter.
  ## 
  let valid = call_612594.validator(path, query, header, formData, body)
  let scheme = call_612594.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612594.url(scheme.get, call_612594.host, call_612594.base,
                         call_612594.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612594, url, valid)

proc call*(call_612595: Call_ListDocuments_612580; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listDocuments
  ## Returns all Systems Manager (SSM) documents in the current AWS account and Region. You can limit the results of this request by using a filter.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_612596 = newJObject()
  var body_612597 = newJObject()
  add(query_612596, "MaxResults", newJString(MaxResults))
  add(query_612596, "NextToken", newJString(NextToken))
  if body != nil:
    body_612597 = body
  result = call_612595.call(nil, query_612596, nil, nil, body_612597)

var listDocuments* = Call_ListDocuments_612580(name: "listDocuments",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.ListDocuments",
    validator: validate_ListDocuments_612581, base: "/", url: url_ListDocuments_612582,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListInventoryEntries_612598 = ref object of OpenApiRestCall_610658
proc url_ListInventoryEntries_612600(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListInventoryEntries_612599(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612601 = header.getOrDefault("X-Amz-Target")
  valid_612601 = validateParameter(valid_612601, JString, required = true, default = newJString(
      "AmazonSSM.ListInventoryEntries"))
  if valid_612601 != nil:
    section.add "X-Amz-Target", valid_612601
  var valid_612602 = header.getOrDefault("X-Amz-Signature")
  valid_612602 = validateParameter(valid_612602, JString, required = false,
                                 default = nil)
  if valid_612602 != nil:
    section.add "X-Amz-Signature", valid_612602
  var valid_612603 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612603 = validateParameter(valid_612603, JString, required = false,
                                 default = nil)
  if valid_612603 != nil:
    section.add "X-Amz-Content-Sha256", valid_612603
  var valid_612604 = header.getOrDefault("X-Amz-Date")
  valid_612604 = validateParameter(valid_612604, JString, required = false,
                                 default = nil)
  if valid_612604 != nil:
    section.add "X-Amz-Date", valid_612604
  var valid_612605 = header.getOrDefault("X-Amz-Credential")
  valid_612605 = validateParameter(valid_612605, JString, required = false,
                                 default = nil)
  if valid_612605 != nil:
    section.add "X-Amz-Credential", valid_612605
  var valid_612606 = header.getOrDefault("X-Amz-Security-Token")
  valid_612606 = validateParameter(valid_612606, JString, required = false,
                                 default = nil)
  if valid_612606 != nil:
    section.add "X-Amz-Security-Token", valid_612606
  var valid_612607 = header.getOrDefault("X-Amz-Algorithm")
  valid_612607 = validateParameter(valid_612607, JString, required = false,
                                 default = nil)
  if valid_612607 != nil:
    section.add "X-Amz-Algorithm", valid_612607
  var valid_612608 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612608 = validateParameter(valid_612608, JString, required = false,
                                 default = nil)
  if valid_612608 != nil:
    section.add "X-Amz-SignedHeaders", valid_612608
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612610: Call_ListInventoryEntries_612598; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## A list of inventory items returned by the request.
  ## 
  let valid = call_612610.validator(path, query, header, formData, body)
  let scheme = call_612610.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612610.url(scheme.get, call_612610.host, call_612610.base,
                         call_612610.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612610, url, valid)

proc call*(call_612611: Call_ListInventoryEntries_612598; body: JsonNode): Recallable =
  ## listInventoryEntries
  ## A list of inventory items returned by the request.
  ##   body: JObject (required)
  var body_612612 = newJObject()
  if body != nil:
    body_612612 = body
  result = call_612611.call(nil, nil, nil, nil, body_612612)

var listInventoryEntries* = Call_ListInventoryEntries_612598(
    name: "listInventoryEntries", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.ListInventoryEntries",
    validator: validate_ListInventoryEntries_612599, base: "/",
    url: url_ListInventoryEntries_612600, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListResourceComplianceSummaries_612613 = ref object of OpenApiRestCall_610658
proc url_ListResourceComplianceSummaries_612615(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListResourceComplianceSummaries_612614(path: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612616 = header.getOrDefault("X-Amz-Target")
  valid_612616 = validateParameter(valid_612616, JString, required = true, default = newJString(
      "AmazonSSM.ListResourceComplianceSummaries"))
  if valid_612616 != nil:
    section.add "X-Amz-Target", valid_612616
  var valid_612617 = header.getOrDefault("X-Amz-Signature")
  valid_612617 = validateParameter(valid_612617, JString, required = false,
                                 default = nil)
  if valid_612617 != nil:
    section.add "X-Amz-Signature", valid_612617
  var valid_612618 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612618 = validateParameter(valid_612618, JString, required = false,
                                 default = nil)
  if valid_612618 != nil:
    section.add "X-Amz-Content-Sha256", valid_612618
  var valid_612619 = header.getOrDefault("X-Amz-Date")
  valid_612619 = validateParameter(valid_612619, JString, required = false,
                                 default = nil)
  if valid_612619 != nil:
    section.add "X-Amz-Date", valid_612619
  var valid_612620 = header.getOrDefault("X-Amz-Credential")
  valid_612620 = validateParameter(valid_612620, JString, required = false,
                                 default = nil)
  if valid_612620 != nil:
    section.add "X-Amz-Credential", valid_612620
  var valid_612621 = header.getOrDefault("X-Amz-Security-Token")
  valid_612621 = validateParameter(valid_612621, JString, required = false,
                                 default = nil)
  if valid_612621 != nil:
    section.add "X-Amz-Security-Token", valid_612621
  var valid_612622 = header.getOrDefault("X-Amz-Algorithm")
  valid_612622 = validateParameter(valid_612622, JString, required = false,
                                 default = nil)
  if valid_612622 != nil:
    section.add "X-Amz-Algorithm", valid_612622
  var valid_612623 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612623 = validateParameter(valid_612623, JString, required = false,
                                 default = nil)
  if valid_612623 != nil:
    section.add "X-Amz-SignedHeaders", valid_612623
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612625: Call_ListResourceComplianceSummaries_612613;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns a resource-level summary count. The summary includes information about compliant and non-compliant statuses and detailed compliance-item severity counts, according to the filter criteria you specify.
  ## 
  let valid = call_612625.validator(path, query, header, formData, body)
  let scheme = call_612625.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612625.url(scheme.get, call_612625.host, call_612625.base,
                         call_612625.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612625, url, valid)

proc call*(call_612626: Call_ListResourceComplianceSummaries_612613; body: JsonNode): Recallable =
  ## listResourceComplianceSummaries
  ## Returns a resource-level summary count. The summary includes information about compliant and non-compliant statuses and detailed compliance-item severity counts, according to the filter criteria you specify.
  ##   body: JObject (required)
  var body_612627 = newJObject()
  if body != nil:
    body_612627 = body
  result = call_612626.call(nil, nil, nil, nil, body_612627)

var listResourceComplianceSummaries* = Call_ListResourceComplianceSummaries_612613(
    name: "listResourceComplianceSummaries", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.ListResourceComplianceSummaries",
    validator: validate_ListResourceComplianceSummaries_612614, base: "/",
    url: url_ListResourceComplianceSummaries_612615,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListResourceDataSync_612628 = ref object of OpenApiRestCall_610658
proc url_ListResourceDataSync_612630(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListResourceDataSync_612629(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612631 = header.getOrDefault("X-Amz-Target")
  valid_612631 = validateParameter(valid_612631, JString, required = true, default = newJString(
      "AmazonSSM.ListResourceDataSync"))
  if valid_612631 != nil:
    section.add "X-Amz-Target", valid_612631
  var valid_612632 = header.getOrDefault("X-Amz-Signature")
  valid_612632 = validateParameter(valid_612632, JString, required = false,
                                 default = nil)
  if valid_612632 != nil:
    section.add "X-Amz-Signature", valid_612632
  var valid_612633 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612633 = validateParameter(valid_612633, JString, required = false,
                                 default = nil)
  if valid_612633 != nil:
    section.add "X-Amz-Content-Sha256", valid_612633
  var valid_612634 = header.getOrDefault("X-Amz-Date")
  valid_612634 = validateParameter(valid_612634, JString, required = false,
                                 default = nil)
  if valid_612634 != nil:
    section.add "X-Amz-Date", valid_612634
  var valid_612635 = header.getOrDefault("X-Amz-Credential")
  valid_612635 = validateParameter(valid_612635, JString, required = false,
                                 default = nil)
  if valid_612635 != nil:
    section.add "X-Amz-Credential", valid_612635
  var valid_612636 = header.getOrDefault("X-Amz-Security-Token")
  valid_612636 = validateParameter(valid_612636, JString, required = false,
                                 default = nil)
  if valid_612636 != nil:
    section.add "X-Amz-Security-Token", valid_612636
  var valid_612637 = header.getOrDefault("X-Amz-Algorithm")
  valid_612637 = validateParameter(valid_612637, JString, required = false,
                                 default = nil)
  if valid_612637 != nil:
    section.add "X-Amz-Algorithm", valid_612637
  var valid_612638 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612638 = validateParameter(valid_612638, JString, required = false,
                                 default = nil)
  if valid_612638 != nil:
    section.add "X-Amz-SignedHeaders", valid_612638
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612640: Call_ListResourceDataSync_612628; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists your resource data sync configurations. Includes information about the last time a sync attempted to start, the last sync status, and the last time a sync successfully completed.</p> <p>The number of sync configurations might be too large to return using a single call to <code>ListResourceDataSync</code>. You can limit the number of sync configurations returned by using the <code>MaxResults</code> parameter. To determine whether there are more sync configurations to list, check the value of <code>NextToken</code> in the output. If there are more sync configurations to list, you can request them by specifying the <code>NextToken</code> returned in the call to the parameter of a subsequent call. </p>
  ## 
  let valid = call_612640.validator(path, query, header, formData, body)
  let scheme = call_612640.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612640.url(scheme.get, call_612640.host, call_612640.base,
                         call_612640.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612640, url, valid)

proc call*(call_612641: Call_ListResourceDataSync_612628; body: JsonNode): Recallable =
  ## listResourceDataSync
  ## <p>Lists your resource data sync configurations. Includes information about the last time a sync attempted to start, the last sync status, and the last time a sync successfully completed.</p> <p>The number of sync configurations might be too large to return using a single call to <code>ListResourceDataSync</code>. You can limit the number of sync configurations returned by using the <code>MaxResults</code> parameter. To determine whether there are more sync configurations to list, check the value of <code>NextToken</code> in the output. If there are more sync configurations to list, you can request them by specifying the <code>NextToken</code> returned in the call to the parameter of a subsequent call. </p>
  ##   body: JObject (required)
  var body_612642 = newJObject()
  if body != nil:
    body_612642 = body
  result = call_612641.call(nil, nil, nil, nil, body_612642)

var listResourceDataSync* = Call_ListResourceDataSync_612628(
    name: "listResourceDataSync", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.ListResourceDataSync",
    validator: validate_ListResourceDataSync_612629, base: "/",
    url: url_ListResourceDataSync_612630, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_612643 = ref object of OpenApiRestCall_610658
proc url_ListTagsForResource_612645(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTagsForResource_612644(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612646 = header.getOrDefault("X-Amz-Target")
  valid_612646 = validateParameter(valid_612646, JString, required = true, default = newJString(
      "AmazonSSM.ListTagsForResource"))
  if valid_612646 != nil:
    section.add "X-Amz-Target", valid_612646
  var valid_612647 = header.getOrDefault("X-Amz-Signature")
  valid_612647 = validateParameter(valid_612647, JString, required = false,
                                 default = nil)
  if valid_612647 != nil:
    section.add "X-Amz-Signature", valid_612647
  var valid_612648 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612648 = validateParameter(valid_612648, JString, required = false,
                                 default = nil)
  if valid_612648 != nil:
    section.add "X-Amz-Content-Sha256", valid_612648
  var valid_612649 = header.getOrDefault("X-Amz-Date")
  valid_612649 = validateParameter(valid_612649, JString, required = false,
                                 default = nil)
  if valid_612649 != nil:
    section.add "X-Amz-Date", valid_612649
  var valid_612650 = header.getOrDefault("X-Amz-Credential")
  valid_612650 = validateParameter(valid_612650, JString, required = false,
                                 default = nil)
  if valid_612650 != nil:
    section.add "X-Amz-Credential", valid_612650
  var valid_612651 = header.getOrDefault("X-Amz-Security-Token")
  valid_612651 = validateParameter(valid_612651, JString, required = false,
                                 default = nil)
  if valid_612651 != nil:
    section.add "X-Amz-Security-Token", valid_612651
  var valid_612652 = header.getOrDefault("X-Amz-Algorithm")
  valid_612652 = validateParameter(valid_612652, JString, required = false,
                                 default = nil)
  if valid_612652 != nil:
    section.add "X-Amz-Algorithm", valid_612652
  var valid_612653 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612653 = validateParameter(valid_612653, JString, required = false,
                                 default = nil)
  if valid_612653 != nil:
    section.add "X-Amz-SignedHeaders", valid_612653
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612655: Call_ListTagsForResource_612643; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of the tags assigned to the specified resource.
  ## 
  let valid = call_612655.validator(path, query, header, formData, body)
  let scheme = call_612655.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612655.url(scheme.get, call_612655.host, call_612655.base,
                         call_612655.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612655, url, valid)

proc call*(call_612656: Call_ListTagsForResource_612643; body: JsonNode): Recallable =
  ## listTagsForResource
  ## Returns a list of the tags assigned to the specified resource.
  ##   body: JObject (required)
  var body_612657 = newJObject()
  if body != nil:
    body_612657 = body
  result = call_612656.call(nil, nil, nil, nil, body_612657)

var listTagsForResource* = Call_ListTagsForResource_612643(
    name: "listTagsForResource", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.ListTagsForResource",
    validator: validate_ListTagsForResource_612644, base: "/",
    url: url_ListTagsForResource_612645, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ModifyDocumentPermission_612658 = ref object of OpenApiRestCall_610658
proc url_ModifyDocumentPermission_612660(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ModifyDocumentPermission_612659(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612661 = header.getOrDefault("X-Amz-Target")
  valid_612661 = validateParameter(valid_612661, JString, required = true, default = newJString(
      "AmazonSSM.ModifyDocumentPermission"))
  if valid_612661 != nil:
    section.add "X-Amz-Target", valid_612661
  var valid_612662 = header.getOrDefault("X-Amz-Signature")
  valid_612662 = validateParameter(valid_612662, JString, required = false,
                                 default = nil)
  if valid_612662 != nil:
    section.add "X-Amz-Signature", valid_612662
  var valid_612663 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612663 = validateParameter(valid_612663, JString, required = false,
                                 default = nil)
  if valid_612663 != nil:
    section.add "X-Amz-Content-Sha256", valid_612663
  var valid_612664 = header.getOrDefault("X-Amz-Date")
  valid_612664 = validateParameter(valid_612664, JString, required = false,
                                 default = nil)
  if valid_612664 != nil:
    section.add "X-Amz-Date", valid_612664
  var valid_612665 = header.getOrDefault("X-Amz-Credential")
  valid_612665 = validateParameter(valid_612665, JString, required = false,
                                 default = nil)
  if valid_612665 != nil:
    section.add "X-Amz-Credential", valid_612665
  var valid_612666 = header.getOrDefault("X-Amz-Security-Token")
  valid_612666 = validateParameter(valid_612666, JString, required = false,
                                 default = nil)
  if valid_612666 != nil:
    section.add "X-Amz-Security-Token", valid_612666
  var valid_612667 = header.getOrDefault("X-Amz-Algorithm")
  valid_612667 = validateParameter(valid_612667, JString, required = false,
                                 default = nil)
  if valid_612667 != nil:
    section.add "X-Amz-Algorithm", valid_612667
  var valid_612668 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612668 = validateParameter(valid_612668, JString, required = false,
                                 default = nil)
  if valid_612668 != nil:
    section.add "X-Amz-SignedHeaders", valid_612668
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612670: Call_ModifyDocumentPermission_612658; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Shares a Systems Manager document publicly or privately. If you share a document privately, you must specify the AWS user account IDs for those people who can use the document. If you share a document publicly, you must specify <i>All</i> as the account ID.
  ## 
  let valid = call_612670.validator(path, query, header, formData, body)
  let scheme = call_612670.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612670.url(scheme.get, call_612670.host, call_612670.base,
                         call_612670.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612670, url, valid)

proc call*(call_612671: Call_ModifyDocumentPermission_612658; body: JsonNode): Recallable =
  ## modifyDocumentPermission
  ## Shares a Systems Manager document publicly or privately. If you share a document privately, you must specify the AWS user account IDs for those people who can use the document. If you share a document publicly, you must specify <i>All</i> as the account ID.
  ##   body: JObject (required)
  var body_612672 = newJObject()
  if body != nil:
    body_612672 = body
  result = call_612671.call(nil, nil, nil, nil, body_612672)

var modifyDocumentPermission* = Call_ModifyDocumentPermission_612658(
    name: "modifyDocumentPermission", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.ModifyDocumentPermission",
    validator: validate_ModifyDocumentPermission_612659, base: "/",
    url: url_ModifyDocumentPermission_612660, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutComplianceItems_612673 = ref object of OpenApiRestCall_610658
proc url_PutComplianceItems_612675(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutComplianceItems_612674(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612676 = header.getOrDefault("X-Amz-Target")
  valid_612676 = validateParameter(valid_612676, JString, required = true, default = newJString(
      "AmazonSSM.PutComplianceItems"))
  if valid_612676 != nil:
    section.add "X-Amz-Target", valid_612676
  var valid_612677 = header.getOrDefault("X-Amz-Signature")
  valid_612677 = validateParameter(valid_612677, JString, required = false,
                                 default = nil)
  if valid_612677 != nil:
    section.add "X-Amz-Signature", valid_612677
  var valid_612678 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612678 = validateParameter(valid_612678, JString, required = false,
                                 default = nil)
  if valid_612678 != nil:
    section.add "X-Amz-Content-Sha256", valid_612678
  var valid_612679 = header.getOrDefault("X-Amz-Date")
  valid_612679 = validateParameter(valid_612679, JString, required = false,
                                 default = nil)
  if valid_612679 != nil:
    section.add "X-Amz-Date", valid_612679
  var valid_612680 = header.getOrDefault("X-Amz-Credential")
  valid_612680 = validateParameter(valid_612680, JString, required = false,
                                 default = nil)
  if valid_612680 != nil:
    section.add "X-Amz-Credential", valid_612680
  var valid_612681 = header.getOrDefault("X-Amz-Security-Token")
  valid_612681 = validateParameter(valid_612681, JString, required = false,
                                 default = nil)
  if valid_612681 != nil:
    section.add "X-Amz-Security-Token", valid_612681
  var valid_612682 = header.getOrDefault("X-Amz-Algorithm")
  valid_612682 = validateParameter(valid_612682, JString, required = false,
                                 default = nil)
  if valid_612682 != nil:
    section.add "X-Amz-Algorithm", valid_612682
  var valid_612683 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612683 = validateParameter(valid_612683, JString, required = false,
                                 default = nil)
  if valid_612683 != nil:
    section.add "X-Amz-SignedHeaders", valid_612683
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612685: Call_PutComplianceItems_612673; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Registers a compliance type and other compliance details on a designated resource. This action lets you register custom compliance details with a resource. This call overwrites existing compliance information on the resource, so you must provide a full list of compliance items each time that you send the request.</p> <p>ComplianceType can be one of the following:</p> <ul> <li> <p>ExecutionId: The execution ID when the patch, association, or custom compliance item was applied.</p> </li> <li> <p>ExecutionType: Specify patch, association, or Custom:<code>string</code>.</p> </li> <li> <p>ExecutionTime. The time the patch, association, or custom compliance item was applied to the instance.</p> </li> <li> <p>Id: The patch, association, or custom compliance ID.</p> </li> <li> <p>Title: A title.</p> </li> <li> <p>Status: The status of the compliance item. For example, <code>approved</code> for patches, or <code>Failed</code> for associations.</p> </li> <li> <p>Severity: A patch severity. For example, <code>critical</code>.</p> </li> <li> <p>DocumentName: A SSM document name. For example, AWS-RunPatchBaseline.</p> </li> <li> <p>DocumentVersion: An SSM document version number. For example, 4.</p> </li> <li> <p>Classification: A patch classification. For example, <code>security updates</code>.</p> </li> <li> <p>PatchBaselineId: A patch baseline ID.</p> </li> <li> <p>PatchSeverity: A patch severity. For example, <code>Critical</code>.</p> </li> <li> <p>PatchState: A patch state. For example, <code>InstancesWithFailedPatches</code>.</p> </li> <li> <p>PatchGroup: The name of a patch group.</p> </li> <li> <p>InstalledTime: The time the association, patch, or custom compliance item was applied to the resource. Specify the time by using the following format: yyyy-MM-dd'T'HH:mm:ss'Z'</p> </li> </ul>
  ## 
  let valid = call_612685.validator(path, query, header, formData, body)
  let scheme = call_612685.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612685.url(scheme.get, call_612685.host, call_612685.base,
                         call_612685.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612685, url, valid)

proc call*(call_612686: Call_PutComplianceItems_612673; body: JsonNode): Recallable =
  ## putComplianceItems
  ## <p>Registers a compliance type and other compliance details on a designated resource. This action lets you register custom compliance details with a resource. This call overwrites existing compliance information on the resource, so you must provide a full list of compliance items each time that you send the request.</p> <p>ComplianceType can be one of the following:</p> <ul> <li> <p>ExecutionId: The execution ID when the patch, association, or custom compliance item was applied.</p> </li> <li> <p>ExecutionType: Specify patch, association, or Custom:<code>string</code>.</p> </li> <li> <p>ExecutionTime. The time the patch, association, or custom compliance item was applied to the instance.</p> </li> <li> <p>Id: The patch, association, or custom compliance ID.</p> </li> <li> <p>Title: A title.</p> </li> <li> <p>Status: The status of the compliance item. For example, <code>approved</code> for patches, or <code>Failed</code> for associations.</p> </li> <li> <p>Severity: A patch severity. For example, <code>critical</code>.</p> </li> <li> <p>DocumentName: A SSM document name. For example, AWS-RunPatchBaseline.</p> </li> <li> <p>DocumentVersion: An SSM document version number. For example, 4.</p> </li> <li> <p>Classification: A patch classification. For example, <code>security updates</code>.</p> </li> <li> <p>PatchBaselineId: A patch baseline ID.</p> </li> <li> <p>PatchSeverity: A patch severity. For example, <code>Critical</code>.</p> </li> <li> <p>PatchState: A patch state. For example, <code>InstancesWithFailedPatches</code>.</p> </li> <li> <p>PatchGroup: The name of a patch group.</p> </li> <li> <p>InstalledTime: The time the association, patch, or custom compliance item was applied to the resource. Specify the time by using the following format: yyyy-MM-dd'T'HH:mm:ss'Z'</p> </li> </ul>
  ##   body: JObject (required)
  var body_612687 = newJObject()
  if body != nil:
    body_612687 = body
  result = call_612686.call(nil, nil, nil, nil, body_612687)

var putComplianceItems* = Call_PutComplianceItems_612673(
    name: "putComplianceItems", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.PutComplianceItems",
    validator: validate_PutComplianceItems_612674, base: "/",
    url: url_PutComplianceItems_612675, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutInventory_612688 = ref object of OpenApiRestCall_610658
proc url_PutInventory_612690(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutInventory_612689(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612691 = header.getOrDefault("X-Amz-Target")
  valid_612691 = validateParameter(valid_612691, JString, required = true,
                                 default = newJString("AmazonSSM.PutInventory"))
  if valid_612691 != nil:
    section.add "X-Amz-Target", valid_612691
  var valid_612692 = header.getOrDefault("X-Amz-Signature")
  valid_612692 = validateParameter(valid_612692, JString, required = false,
                                 default = nil)
  if valid_612692 != nil:
    section.add "X-Amz-Signature", valid_612692
  var valid_612693 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612693 = validateParameter(valid_612693, JString, required = false,
                                 default = nil)
  if valid_612693 != nil:
    section.add "X-Amz-Content-Sha256", valid_612693
  var valid_612694 = header.getOrDefault("X-Amz-Date")
  valid_612694 = validateParameter(valid_612694, JString, required = false,
                                 default = nil)
  if valid_612694 != nil:
    section.add "X-Amz-Date", valid_612694
  var valid_612695 = header.getOrDefault("X-Amz-Credential")
  valid_612695 = validateParameter(valid_612695, JString, required = false,
                                 default = nil)
  if valid_612695 != nil:
    section.add "X-Amz-Credential", valid_612695
  var valid_612696 = header.getOrDefault("X-Amz-Security-Token")
  valid_612696 = validateParameter(valid_612696, JString, required = false,
                                 default = nil)
  if valid_612696 != nil:
    section.add "X-Amz-Security-Token", valid_612696
  var valid_612697 = header.getOrDefault("X-Amz-Algorithm")
  valid_612697 = validateParameter(valid_612697, JString, required = false,
                                 default = nil)
  if valid_612697 != nil:
    section.add "X-Amz-Algorithm", valid_612697
  var valid_612698 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612698 = validateParameter(valid_612698, JString, required = false,
                                 default = nil)
  if valid_612698 != nil:
    section.add "X-Amz-SignedHeaders", valid_612698
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612700: Call_PutInventory_612688; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Bulk update custom inventory items on one more instance. The request adds an inventory item, if it doesn't already exist, or updates an inventory item, if it does exist.
  ## 
  let valid = call_612700.validator(path, query, header, formData, body)
  let scheme = call_612700.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612700.url(scheme.get, call_612700.host, call_612700.base,
                         call_612700.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612700, url, valid)

proc call*(call_612701: Call_PutInventory_612688; body: JsonNode): Recallable =
  ## putInventory
  ## Bulk update custom inventory items on one more instance. The request adds an inventory item, if it doesn't already exist, or updates an inventory item, if it does exist.
  ##   body: JObject (required)
  var body_612702 = newJObject()
  if body != nil:
    body_612702 = body
  result = call_612701.call(nil, nil, nil, nil, body_612702)

var putInventory* = Call_PutInventory_612688(name: "putInventory",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.PutInventory",
    validator: validate_PutInventory_612689, base: "/", url: url_PutInventory_612690,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutParameter_612703 = ref object of OpenApiRestCall_610658
proc url_PutParameter_612705(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutParameter_612704(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612706 = header.getOrDefault("X-Amz-Target")
  valid_612706 = validateParameter(valid_612706, JString, required = true,
                                 default = newJString("AmazonSSM.PutParameter"))
  if valid_612706 != nil:
    section.add "X-Amz-Target", valid_612706
  var valid_612707 = header.getOrDefault("X-Amz-Signature")
  valid_612707 = validateParameter(valid_612707, JString, required = false,
                                 default = nil)
  if valid_612707 != nil:
    section.add "X-Amz-Signature", valid_612707
  var valid_612708 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612708 = validateParameter(valid_612708, JString, required = false,
                                 default = nil)
  if valid_612708 != nil:
    section.add "X-Amz-Content-Sha256", valid_612708
  var valid_612709 = header.getOrDefault("X-Amz-Date")
  valid_612709 = validateParameter(valid_612709, JString, required = false,
                                 default = nil)
  if valid_612709 != nil:
    section.add "X-Amz-Date", valid_612709
  var valid_612710 = header.getOrDefault("X-Amz-Credential")
  valid_612710 = validateParameter(valid_612710, JString, required = false,
                                 default = nil)
  if valid_612710 != nil:
    section.add "X-Amz-Credential", valid_612710
  var valid_612711 = header.getOrDefault("X-Amz-Security-Token")
  valid_612711 = validateParameter(valid_612711, JString, required = false,
                                 default = nil)
  if valid_612711 != nil:
    section.add "X-Amz-Security-Token", valid_612711
  var valid_612712 = header.getOrDefault("X-Amz-Algorithm")
  valid_612712 = validateParameter(valid_612712, JString, required = false,
                                 default = nil)
  if valid_612712 != nil:
    section.add "X-Amz-Algorithm", valid_612712
  var valid_612713 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612713 = validateParameter(valid_612713, JString, required = false,
                                 default = nil)
  if valid_612713 != nil:
    section.add "X-Amz-SignedHeaders", valid_612713
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612715: Call_PutParameter_612703; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Add a parameter to the system.
  ## 
  let valid = call_612715.validator(path, query, header, formData, body)
  let scheme = call_612715.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612715.url(scheme.get, call_612715.host, call_612715.base,
                         call_612715.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612715, url, valid)

proc call*(call_612716: Call_PutParameter_612703; body: JsonNode): Recallable =
  ## putParameter
  ## Add a parameter to the system.
  ##   body: JObject (required)
  var body_612717 = newJObject()
  if body != nil:
    body_612717 = body
  result = call_612716.call(nil, nil, nil, nil, body_612717)

var putParameter* = Call_PutParameter_612703(name: "putParameter",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.PutParameter",
    validator: validate_PutParameter_612704, base: "/", url: url_PutParameter_612705,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RegisterDefaultPatchBaseline_612718 = ref object of OpenApiRestCall_610658
proc url_RegisterDefaultPatchBaseline_612720(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_RegisterDefaultPatchBaseline_612719(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612721 = header.getOrDefault("X-Amz-Target")
  valid_612721 = validateParameter(valid_612721, JString, required = true, default = newJString(
      "AmazonSSM.RegisterDefaultPatchBaseline"))
  if valid_612721 != nil:
    section.add "X-Amz-Target", valid_612721
  var valid_612722 = header.getOrDefault("X-Amz-Signature")
  valid_612722 = validateParameter(valid_612722, JString, required = false,
                                 default = nil)
  if valid_612722 != nil:
    section.add "X-Amz-Signature", valid_612722
  var valid_612723 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612723 = validateParameter(valid_612723, JString, required = false,
                                 default = nil)
  if valid_612723 != nil:
    section.add "X-Amz-Content-Sha256", valid_612723
  var valid_612724 = header.getOrDefault("X-Amz-Date")
  valid_612724 = validateParameter(valid_612724, JString, required = false,
                                 default = nil)
  if valid_612724 != nil:
    section.add "X-Amz-Date", valid_612724
  var valid_612725 = header.getOrDefault("X-Amz-Credential")
  valid_612725 = validateParameter(valid_612725, JString, required = false,
                                 default = nil)
  if valid_612725 != nil:
    section.add "X-Amz-Credential", valid_612725
  var valid_612726 = header.getOrDefault("X-Amz-Security-Token")
  valid_612726 = validateParameter(valid_612726, JString, required = false,
                                 default = nil)
  if valid_612726 != nil:
    section.add "X-Amz-Security-Token", valid_612726
  var valid_612727 = header.getOrDefault("X-Amz-Algorithm")
  valid_612727 = validateParameter(valid_612727, JString, required = false,
                                 default = nil)
  if valid_612727 != nil:
    section.add "X-Amz-Algorithm", valid_612727
  var valid_612728 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612728 = validateParameter(valid_612728, JString, required = false,
                                 default = nil)
  if valid_612728 != nil:
    section.add "X-Amz-SignedHeaders", valid_612728
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612730: Call_RegisterDefaultPatchBaseline_612718; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Defines the default patch baseline for the relevant operating system.</p> <p>To reset the AWS predefined patch baseline as the default, specify the full patch baseline ARN as the baseline ID value. For example, for CentOS, specify <code>arn:aws:ssm:us-east-2:733109147000:patchbaseline/pb-0574b43a65ea646ed</code> instead of <code>pb-0574b43a65ea646ed</code>.</p>
  ## 
  let valid = call_612730.validator(path, query, header, formData, body)
  let scheme = call_612730.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612730.url(scheme.get, call_612730.host, call_612730.base,
                         call_612730.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612730, url, valid)

proc call*(call_612731: Call_RegisterDefaultPatchBaseline_612718; body: JsonNode): Recallable =
  ## registerDefaultPatchBaseline
  ## <p>Defines the default patch baseline for the relevant operating system.</p> <p>To reset the AWS predefined patch baseline as the default, specify the full patch baseline ARN as the baseline ID value. For example, for CentOS, specify <code>arn:aws:ssm:us-east-2:733109147000:patchbaseline/pb-0574b43a65ea646ed</code> instead of <code>pb-0574b43a65ea646ed</code>.</p>
  ##   body: JObject (required)
  var body_612732 = newJObject()
  if body != nil:
    body_612732 = body
  result = call_612731.call(nil, nil, nil, nil, body_612732)

var registerDefaultPatchBaseline* = Call_RegisterDefaultPatchBaseline_612718(
    name: "registerDefaultPatchBaseline", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.RegisterDefaultPatchBaseline",
    validator: validate_RegisterDefaultPatchBaseline_612719, base: "/",
    url: url_RegisterDefaultPatchBaseline_612720,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RegisterPatchBaselineForPatchGroup_612733 = ref object of OpenApiRestCall_610658
proc url_RegisterPatchBaselineForPatchGroup_612735(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_RegisterPatchBaselineForPatchGroup_612734(path: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612736 = header.getOrDefault("X-Amz-Target")
  valid_612736 = validateParameter(valid_612736, JString, required = true, default = newJString(
      "AmazonSSM.RegisterPatchBaselineForPatchGroup"))
  if valid_612736 != nil:
    section.add "X-Amz-Target", valid_612736
  var valid_612737 = header.getOrDefault("X-Amz-Signature")
  valid_612737 = validateParameter(valid_612737, JString, required = false,
                                 default = nil)
  if valid_612737 != nil:
    section.add "X-Amz-Signature", valid_612737
  var valid_612738 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612738 = validateParameter(valid_612738, JString, required = false,
                                 default = nil)
  if valid_612738 != nil:
    section.add "X-Amz-Content-Sha256", valid_612738
  var valid_612739 = header.getOrDefault("X-Amz-Date")
  valid_612739 = validateParameter(valid_612739, JString, required = false,
                                 default = nil)
  if valid_612739 != nil:
    section.add "X-Amz-Date", valid_612739
  var valid_612740 = header.getOrDefault("X-Amz-Credential")
  valid_612740 = validateParameter(valid_612740, JString, required = false,
                                 default = nil)
  if valid_612740 != nil:
    section.add "X-Amz-Credential", valid_612740
  var valid_612741 = header.getOrDefault("X-Amz-Security-Token")
  valid_612741 = validateParameter(valid_612741, JString, required = false,
                                 default = nil)
  if valid_612741 != nil:
    section.add "X-Amz-Security-Token", valid_612741
  var valid_612742 = header.getOrDefault("X-Amz-Algorithm")
  valid_612742 = validateParameter(valid_612742, JString, required = false,
                                 default = nil)
  if valid_612742 != nil:
    section.add "X-Amz-Algorithm", valid_612742
  var valid_612743 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612743 = validateParameter(valid_612743, JString, required = false,
                                 default = nil)
  if valid_612743 != nil:
    section.add "X-Amz-SignedHeaders", valid_612743
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612745: Call_RegisterPatchBaselineForPatchGroup_612733;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Registers a patch baseline for a patch group.
  ## 
  let valid = call_612745.validator(path, query, header, formData, body)
  let scheme = call_612745.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612745.url(scheme.get, call_612745.host, call_612745.base,
                         call_612745.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612745, url, valid)

proc call*(call_612746: Call_RegisterPatchBaselineForPatchGroup_612733;
          body: JsonNode): Recallable =
  ## registerPatchBaselineForPatchGroup
  ## Registers a patch baseline for a patch group.
  ##   body: JObject (required)
  var body_612747 = newJObject()
  if body != nil:
    body_612747 = body
  result = call_612746.call(nil, nil, nil, nil, body_612747)

var registerPatchBaselineForPatchGroup* = Call_RegisterPatchBaselineForPatchGroup_612733(
    name: "registerPatchBaselineForPatchGroup", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.RegisterPatchBaselineForPatchGroup",
    validator: validate_RegisterPatchBaselineForPatchGroup_612734, base: "/",
    url: url_RegisterPatchBaselineForPatchGroup_612735,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RegisterTargetWithMaintenanceWindow_612748 = ref object of OpenApiRestCall_610658
proc url_RegisterTargetWithMaintenanceWindow_612750(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_RegisterTargetWithMaintenanceWindow_612749(path: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612751 = header.getOrDefault("X-Amz-Target")
  valid_612751 = validateParameter(valid_612751, JString, required = true, default = newJString(
      "AmazonSSM.RegisterTargetWithMaintenanceWindow"))
  if valid_612751 != nil:
    section.add "X-Amz-Target", valid_612751
  var valid_612752 = header.getOrDefault("X-Amz-Signature")
  valid_612752 = validateParameter(valid_612752, JString, required = false,
                                 default = nil)
  if valid_612752 != nil:
    section.add "X-Amz-Signature", valid_612752
  var valid_612753 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612753 = validateParameter(valid_612753, JString, required = false,
                                 default = nil)
  if valid_612753 != nil:
    section.add "X-Amz-Content-Sha256", valid_612753
  var valid_612754 = header.getOrDefault("X-Amz-Date")
  valid_612754 = validateParameter(valid_612754, JString, required = false,
                                 default = nil)
  if valid_612754 != nil:
    section.add "X-Amz-Date", valid_612754
  var valid_612755 = header.getOrDefault("X-Amz-Credential")
  valid_612755 = validateParameter(valid_612755, JString, required = false,
                                 default = nil)
  if valid_612755 != nil:
    section.add "X-Amz-Credential", valid_612755
  var valid_612756 = header.getOrDefault("X-Amz-Security-Token")
  valid_612756 = validateParameter(valid_612756, JString, required = false,
                                 default = nil)
  if valid_612756 != nil:
    section.add "X-Amz-Security-Token", valid_612756
  var valid_612757 = header.getOrDefault("X-Amz-Algorithm")
  valid_612757 = validateParameter(valid_612757, JString, required = false,
                                 default = nil)
  if valid_612757 != nil:
    section.add "X-Amz-Algorithm", valid_612757
  var valid_612758 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612758 = validateParameter(valid_612758, JString, required = false,
                                 default = nil)
  if valid_612758 != nil:
    section.add "X-Amz-SignedHeaders", valid_612758
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612760: Call_RegisterTargetWithMaintenanceWindow_612748;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Registers a target with a maintenance window.
  ## 
  let valid = call_612760.validator(path, query, header, formData, body)
  let scheme = call_612760.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612760.url(scheme.get, call_612760.host, call_612760.base,
                         call_612760.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612760, url, valid)

proc call*(call_612761: Call_RegisterTargetWithMaintenanceWindow_612748;
          body: JsonNode): Recallable =
  ## registerTargetWithMaintenanceWindow
  ## Registers a target with a maintenance window.
  ##   body: JObject (required)
  var body_612762 = newJObject()
  if body != nil:
    body_612762 = body
  result = call_612761.call(nil, nil, nil, nil, body_612762)

var registerTargetWithMaintenanceWindow* = Call_RegisterTargetWithMaintenanceWindow_612748(
    name: "registerTargetWithMaintenanceWindow", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.RegisterTargetWithMaintenanceWindow",
    validator: validate_RegisterTargetWithMaintenanceWindow_612749, base: "/",
    url: url_RegisterTargetWithMaintenanceWindow_612750,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RegisterTaskWithMaintenanceWindow_612763 = ref object of OpenApiRestCall_610658
proc url_RegisterTaskWithMaintenanceWindow_612765(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_RegisterTaskWithMaintenanceWindow_612764(path: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612766 = header.getOrDefault("X-Amz-Target")
  valid_612766 = validateParameter(valid_612766, JString, required = true, default = newJString(
      "AmazonSSM.RegisterTaskWithMaintenanceWindow"))
  if valid_612766 != nil:
    section.add "X-Amz-Target", valid_612766
  var valid_612767 = header.getOrDefault("X-Amz-Signature")
  valid_612767 = validateParameter(valid_612767, JString, required = false,
                                 default = nil)
  if valid_612767 != nil:
    section.add "X-Amz-Signature", valid_612767
  var valid_612768 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612768 = validateParameter(valid_612768, JString, required = false,
                                 default = nil)
  if valid_612768 != nil:
    section.add "X-Amz-Content-Sha256", valid_612768
  var valid_612769 = header.getOrDefault("X-Amz-Date")
  valid_612769 = validateParameter(valid_612769, JString, required = false,
                                 default = nil)
  if valid_612769 != nil:
    section.add "X-Amz-Date", valid_612769
  var valid_612770 = header.getOrDefault("X-Amz-Credential")
  valid_612770 = validateParameter(valid_612770, JString, required = false,
                                 default = nil)
  if valid_612770 != nil:
    section.add "X-Amz-Credential", valid_612770
  var valid_612771 = header.getOrDefault("X-Amz-Security-Token")
  valid_612771 = validateParameter(valid_612771, JString, required = false,
                                 default = nil)
  if valid_612771 != nil:
    section.add "X-Amz-Security-Token", valid_612771
  var valid_612772 = header.getOrDefault("X-Amz-Algorithm")
  valid_612772 = validateParameter(valid_612772, JString, required = false,
                                 default = nil)
  if valid_612772 != nil:
    section.add "X-Amz-Algorithm", valid_612772
  var valid_612773 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612773 = validateParameter(valid_612773, JString, required = false,
                                 default = nil)
  if valid_612773 != nil:
    section.add "X-Amz-SignedHeaders", valid_612773
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612775: Call_RegisterTaskWithMaintenanceWindow_612763;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Adds a new task to a maintenance window.
  ## 
  let valid = call_612775.validator(path, query, header, formData, body)
  let scheme = call_612775.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612775.url(scheme.get, call_612775.host, call_612775.base,
                         call_612775.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612775, url, valid)

proc call*(call_612776: Call_RegisterTaskWithMaintenanceWindow_612763;
          body: JsonNode): Recallable =
  ## registerTaskWithMaintenanceWindow
  ## Adds a new task to a maintenance window.
  ##   body: JObject (required)
  var body_612777 = newJObject()
  if body != nil:
    body_612777 = body
  result = call_612776.call(nil, nil, nil, nil, body_612777)

var registerTaskWithMaintenanceWindow* = Call_RegisterTaskWithMaintenanceWindow_612763(
    name: "registerTaskWithMaintenanceWindow", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.RegisterTaskWithMaintenanceWindow",
    validator: validate_RegisterTaskWithMaintenanceWindow_612764, base: "/",
    url: url_RegisterTaskWithMaintenanceWindow_612765,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RemoveTagsFromResource_612778 = ref object of OpenApiRestCall_610658
proc url_RemoveTagsFromResource_612780(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_RemoveTagsFromResource_612779(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612781 = header.getOrDefault("X-Amz-Target")
  valid_612781 = validateParameter(valid_612781, JString, required = true, default = newJString(
      "AmazonSSM.RemoveTagsFromResource"))
  if valid_612781 != nil:
    section.add "X-Amz-Target", valid_612781
  var valid_612782 = header.getOrDefault("X-Amz-Signature")
  valid_612782 = validateParameter(valid_612782, JString, required = false,
                                 default = nil)
  if valid_612782 != nil:
    section.add "X-Amz-Signature", valid_612782
  var valid_612783 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612783 = validateParameter(valid_612783, JString, required = false,
                                 default = nil)
  if valid_612783 != nil:
    section.add "X-Amz-Content-Sha256", valid_612783
  var valid_612784 = header.getOrDefault("X-Amz-Date")
  valid_612784 = validateParameter(valid_612784, JString, required = false,
                                 default = nil)
  if valid_612784 != nil:
    section.add "X-Amz-Date", valid_612784
  var valid_612785 = header.getOrDefault("X-Amz-Credential")
  valid_612785 = validateParameter(valid_612785, JString, required = false,
                                 default = nil)
  if valid_612785 != nil:
    section.add "X-Amz-Credential", valid_612785
  var valid_612786 = header.getOrDefault("X-Amz-Security-Token")
  valid_612786 = validateParameter(valid_612786, JString, required = false,
                                 default = nil)
  if valid_612786 != nil:
    section.add "X-Amz-Security-Token", valid_612786
  var valid_612787 = header.getOrDefault("X-Amz-Algorithm")
  valid_612787 = validateParameter(valid_612787, JString, required = false,
                                 default = nil)
  if valid_612787 != nil:
    section.add "X-Amz-Algorithm", valid_612787
  var valid_612788 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612788 = validateParameter(valid_612788, JString, required = false,
                                 default = nil)
  if valid_612788 != nil:
    section.add "X-Amz-SignedHeaders", valid_612788
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612790: Call_RemoveTagsFromResource_612778; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes tag keys from the specified resource.
  ## 
  let valid = call_612790.validator(path, query, header, formData, body)
  let scheme = call_612790.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612790.url(scheme.get, call_612790.host, call_612790.base,
                         call_612790.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612790, url, valid)

proc call*(call_612791: Call_RemoveTagsFromResource_612778; body: JsonNode): Recallable =
  ## removeTagsFromResource
  ## Removes tag keys from the specified resource.
  ##   body: JObject (required)
  var body_612792 = newJObject()
  if body != nil:
    body_612792 = body
  result = call_612791.call(nil, nil, nil, nil, body_612792)

var removeTagsFromResource* = Call_RemoveTagsFromResource_612778(
    name: "removeTagsFromResource", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.RemoveTagsFromResource",
    validator: validate_RemoveTagsFromResource_612779, base: "/",
    url: url_RemoveTagsFromResource_612780, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ResetServiceSetting_612793 = ref object of OpenApiRestCall_610658
proc url_ResetServiceSetting_612795(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ResetServiceSetting_612794(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612796 = header.getOrDefault("X-Amz-Target")
  valid_612796 = validateParameter(valid_612796, JString, required = true, default = newJString(
      "AmazonSSM.ResetServiceSetting"))
  if valid_612796 != nil:
    section.add "X-Amz-Target", valid_612796
  var valid_612797 = header.getOrDefault("X-Amz-Signature")
  valid_612797 = validateParameter(valid_612797, JString, required = false,
                                 default = nil)
  if valid_612797 != nil:
    section.add "X-Amz-Signature", valid_612797
  var valid_612798 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612798 = validateParameter(valid_612798, JString, required = false,
                                 default = nil)
  if valid_612798 != nil:
    section.add "X-Amz-Content-Sha256", valid_612798
  var valid_612799 = header.getOrDefault("X-Amz-Date")
  valid_612799 = validateParameter(valid_612799, JString, required = false,
                                 default = nil)
  if valid_612799 != nil:
    section.add "X-Amz-Date", valid_612799
  var valid_612800 = header.getOrDefault("X-Amz-Credential")
  valid_612800 = validateParameter(valid_612800, JString, required = false,
                                 default = nil)
  if valid_612800 != nil:
    section.add "X-Amz-Credential", valid_612800
  var valid_612801 = header.getOrDefault("X-Amz-Security-Token")
  valid_612801 = validateParameter(valid_612801, JString, required = false,
                                 default = nil)
  if valid_612801 != nil:
    section.add "X-Amz-Security-Token", valid_612801
  var valid_612802 = header.getOrDefault("X-Amz-Algorithm")
  valid_612802 = validateParameter(valid_612802, JString, required = false,
                                 default = nil)
  if valid_612802 != nil:
    section.add "X-Amz-Algorithm", valid_612802
  var valid_612803 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612803 = validateParameter(valid_612803, JString, required = false,
                                 default = nil)
  if valid_612803 != nil:
    section.add "X-Amz-SignedHeaders", valid_612803
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612805: Call_ResetServiceSetting_612793; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> <code>ServiceSetting</code> is an account-level setting for an AWS service. This setting defines how a user interacts with or uses a service or a feature of a service. For example, if an AWS service charges money to the account based on feature or service usage, then the AWS service team might create a default setting of "false". This means the user can't use this feature unless they change the setting to "true" and intentionally opt in for a paid feature.</p> <p>Services map a <code>SettingId</code> object to a setting value. AWS services teams define the default value for a <code>SettingId</code>. You can't create a new <code>SettingId</code>, but you can overwrite the default value if you have the <code>ssm:UpdateServiceSetting</code> permission for the setting. Use the <a>GetServiceSetting</a> API action to view the current value. Use the <a>UpdateServiceSetting</a> API action to change the default setting. </p> <p>Reset the service setting for the account to the default value as provisioned by the AWS service team. </p>
  ## 
  let valid = call_612805.validator(path, query, header, formData, body)
  let scheme = call_612805.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612805.url(scheme.get, call_612805.host, call_612805.base,
                         call_612805.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612805, url, valid)

proc call*(call_612806: Call_ResetServiceSetting_612793; body: JsonNode): Recallable =
  ## resetServiceSetting
  ## <p> <code>ServiceSetting</code> is an account-level setting for an AWS service. This setting defines how a user interacts with or uses a service or a feature of a service. For example, if an AWS service charges money to the account based on feature or service usage, then the AWS service team might create a default setting of "false". This means the user can't use this feature unless they change the setting to "true" and intentionally opt in for a paid feature.</p> <p>Services map a <code>SettingId</code> object to a setting value. AWS services teams define the default value for a <code>SettingId</code>. You can't create a new <code>SettingId</code>, but you can overwrite the default value if you have the <code>ssm:UpdateServiceSetting</code> permission for the setting. Use the <a>GetServiceSetting</a> API action to view the current value. Use the <a>UpdateServiceSetting</a> API action to change the default setting. </p> <p>Reset the service setting for the account to the default value as provisioned by the AWS service team. </p>
  ##   body: JObject (required)
  var body_612807 = newJObject()
  if body != nil:
    body_612807 = body
  result = call_612806.call(nil, nil, nil, nil, body_612807)

var resetServiceSetting* = Call_ResetServiceSetting_612793(
    name: "resetServiceSetting", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.ResetServiceSetting",
    validator: validate_ResetServiceSetting_612794, base: "/",
    url: url_ResetServiceSetting_612795, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ResumeSession_612808 = ref object of OpenApiRestCall_610658
proc url_ResumeSession_612810(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ResumeSession_612809(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612811 = header.getOrDefault("X-Amz-Target")
  valid_612811 = validateParameter(valid_612811, JString, required = true, default = newJString(
      "AmazonSSM.ResumeSession"))
  if valid_612811 != nil:
    section.add "X-Amz-Target", valid_612811
  var valid_612812 = header.getOrDefault("X-Amz-Signature")
  valid_612812 = validateParameter(valid_612812, JString, required = false,
                                 default = nil)
  if valid_612812 != nil:
    section.add "X-Amz-Signature", valid_612812
  var valid_612813 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612813 = validateParameter(valid_612813, JString, required = false,
                                 default = nil)
  if valid_612813 != nil:
    section.add "X-Amz-Content-Sha256", valid_612813
  var valid_612814 = header.getOrDefault("X-Amz-Date")
  valid_612814 = validateParameter(valid_612814, JString, required = false,
                                 default = nil)
  if valid_612814 != nil:
    section.add "X-Amz-Date", valid_612814
  var valid_612815 = header.getOrDefault("X-Amz-Credential")
  valid_612815 = validateParameter(valid_612815, JString, required = false,
                                 default = nil)
  if valid_612815 != nil:
    section.add "X-Amz-Credential", valid_612815
  var valid_612816 = header.getOrDefault("X-Amz-Security-Token")
  valid_612816 = validateParameter(valid_612816, JString, required = false,
                                 default = nil)
  if valid_612816 != nil:
    section.add "X-Amz-Security-Token", valid_612816
  var valid_612817 = header.getOrDefault("X-Amz-Algorithm")
  valid_612817 = validateParameter(valid_612817, JString, required = false,
                                 default = nil)
  if valid_612817 != nil:
    section.add "X-Amz-Algorithm", valid_612817
  var valid_612818 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612818 = validateParameter(valid_612818, JString, required = false,
                                 default = nil)
  if valid_612818 != nil:
    section.add "X-Amz-SignedHeaders", valid_612818
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612820: Call_ResumeSession_612808; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Reconnects a session to an instance after it has been disconnected. Connections can be resumed for disconnected sessions, but not terminated sessions.</p> <note> <p>This command is primarily for use by client machines to automatically reconnect during intermittent network issues. It is not intended for any other use.</p> </note>
  ## 
  let valid = call_612820.validator(path, query, header, formData, body)
  let scheme = call_612820.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612820.url(scheme.get, call_612820.host, call_612820.base,
                         call_612820.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612820, url, valid)

proc call*(call_612821: Call_ResumeSession_612808; body: JsonNode): Recallable =
  ## resumeSession
  ## <p>Reconnects a session to an instance after it has been disconnected. Connections can be resumed for disconnected sessions, but not terminated sessions.</p> <note> <p>This command is primarily for use by client machines to automatically reconnect during intermittent network issues. It is not intended for any other use.</p> </note>
  ##   body: JObject (required)
  var body_612822 = newJObject()
  if body != nil:
    body_612822 = body
  result = call_612821.call(nil, nil, nil, nil, body_612822)

var resumeSession* = Call_ResumeSession_612808(name: "resumeSession",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.ResumeSession",
    validator: validate_ResumeSession_612809, base: "/", url: url_ResumeSession_612810,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_SendAutomationSignal_612823 = ref object of OpenApiRestCall_610658
proc url_SendAutomationSignal_612825(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_SendAutomationSignal_612824(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612826 = header.getOrDefault("X-Amz-Target")
  valid_612826 = validateParameter(valid_612826, JString, required = true, default = newJString(
      "AmazonSSM.SendAutomationSignal"))
  if valid_612826 != nil:
    section.add "X-Amz-Target", valid_612826
  var valid_612827 = header.getOrDefault("X-Amz-Signature")
  valid_612827 = validateParameter(valid_612827, JString, required = false,
                                 default = nil)
  if valid_612827 != nil:
    section.add "X-Amz-Signature", valid_612827
  var valid_612828 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612828 = validateParameter(valid_612828, JString, required = false,
                                 default = nil)
  if valid_612828 != nil:
    section.add "X-Amz-Content-Sha256", valid_612828
  var valid_612829 = header.getOrDefault("X-Amz-Date")
  valid_612829 = validateParameter(valid_612829, JString, required = false,
                                 default = nil)
  if valid_612829 != nil:
    section.add "X-Amz-Date", valid_612829
  var valid_612830 = header.getOrDefault("X-Amz-Credential")
  valid_612830 = validateParameter(valid_612830, JString, required = false,
                                 default = nil)
  if valid_612830 != nil:
    section.add "X-Amz-Credential", valid_612830
  var valid_612831 = header.getOrDefault("X-Amz-Security-Token")
  valid_612831 = validateParameter(valid_612831, JString, required = false,
                                 default = nil)
  if valid_612831 != nil:
    section.add "X-Amz-Security-Token", valid_612831
  var valid_612832 = header.getOrDefault("X-Amz-Algorithm")
  valid_612832 = validateParameter(valid_612832, JString, required = false,
                                 default = nil)
  if valid_612832 != nil:
    section.add "X-Amz-Algorithm", valid_612832
  var valid_612833 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612833 = validateParameter(valid_612833, JString, required = false,
                                 default = nil)
  if valid_612833 != nil:
    section.add "X-Amz-SignedHeaders", valid_612833
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612835: Call_SendAutomationSignal_612823; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sends a signal to an Automation execution to change the current behavior or status of the execution. 
  ## 
  let valid = call_612835.validator(path, query, header, formData, body)
  let scheme = call_612835.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612835.url(scheme.get, call_612835.host, call_612835.base,
                         call_612835.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612835, url, valid)

proc call*(call_612836: Call_SendAutomationSignal_612823; body: JsonNode): Recallable =
  ## sendAutomationSignal
  ## Sends a signal to an Automation execution to change the current behavior or status of the execution. 
  ##   body: JObject (required)
  var body_612837 = newJObject()
  if body != nil:
    body_612837 = body
  result = call_612836.call(nil, nil, nil, nil, body_612837)

var sendAutomationSignal* = Call_SendAutomationSignal_612823(
    name: "sendAutomationSignal", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.SendAutomationSignal",
    validator: validate_SendAutomationSignal_612824, base: "/",
    url: url_SendAutomationSignal_612825, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SendCommand_612838 = ref object of OpenApiRestCall_610658
proc url_SendCommand_612840(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_SendCommand_612839(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612841 = header.getOrDefault("X-Amz-Target")
  valid_612841 = validateParameter(valid_612841, JString, required = true,
                                 default = newJString("AmazonSSM.SendCommand"))
  if valid_612841 != nil:
    section.add "X-Amz-Target", valid_612841
  var valid_612842 = header.getOrDefault("X-Amz-Signature")
  valid_612842 = validateParameter(valid_612842, JString, required = false,
                                 default = nil)
  if valid_612842 != nil:
    section.add "X-Amz-Signature", valid_612842
  var valid_612843 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612843 = validateParameter(valid_612843, JString, required = false,
                                 default = nil)
  if valid_612843 != nil:
    section.add "X-Amz-Content-Sha256", valid_612843
  var valid_612844 = header.getOrDefault("X-Amz-Date")
  valid_612844 = validateParameter(valid_612844, JString, required = false,
                                 default = nil)
  if valid_612844 != nil:
    section.add "X-Amz-Date", valid_612844
  var valid_612845 = header.getOrDefault("X-Amz-Credential")
  valid_612845 = validateParameter(valid_612845, JString, required = false,
                                 default = nil)
  if valid_612845 != nil:
    section.add "X-Amz-Credential", valid_612845
  var valid_612846 = header.getOrDefault("X-Amz-Security-Token")
  valid_612846 = validateParameter(valid_612846, JString, required = false,
                                 default = nil)
  if valid_612846 != nil:
    section.add "X-Amz-Security-Token", valid_612846
  var valid_612847 = header.getOrDefault("X-Amz-Algorithm")
  valid_612847 = validateParameter(valid_612847, JString, required = false,
                                 default = nil)
  if valid_612847 != nil:
    section.add "X-Amz-Algorithm", valid_612847
  var valid_612848 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612848 = validateParameter(valid_612848, JString, required = false,
                                 default = nil)
  if valid_612848 != nil:
    section.add "X-Amz-SignedHeaders", valid_612848
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612850: Call_SendCommand_612838; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Runs commands on one or more managed instances.
  ## 
  let valid = call_612850.validator(path, query, header, formData, body)
  let scheme = call_612850.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612850.url(scheme.get, call_612850.host, call_612850.base,
                         call_612850.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612850, url, valid)

proc call*(call_612851: Call_SendCommand_612838; body: JsonNode): Recallable =
  ## sendCommand
  ## Runs commands on one or more managed instances.
  ##   body: JObject (required)
  var body_612852 = newJObject()
  if body != nil:
    body_612852 = body
  result = call_612851.call(nil, nil, nil, nil, body_612852)

var sendCommand* = Call_SendCommand_612838(name: "sendCommand",
                                        meth: HttpMethod.HttpPost,
                                        host: "ssm.amazonaws.com", route: "/#X-Amz-Target=AmazonSSM.SendCommand",
                                        validator: validate_SendCommand_612839,
                                        base: "/", url: url_SendCommand_612840,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartAssociationsOnce_612853 = ref object of OpenApiRestCall_610658
proc url_StartAssociationsOnce_612855(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StartAssociationsOnce_612854(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612856 = header.getOrDefault("X-Amz-Target")
  valid_612856 = validateParameter(valid_612856, JString, required = true, default = newJString(
      "AmazonSSM.StartAssociationsOnce"))
  if valid_612856 != nil:
    section.add "X-Amz-Target", valid_612856
  var valid_612857 = header.getOrDefault("X-Amz-Signature")
  valid_612857 = validateParameter(valid_612857, JString, required = false,
                                 default = nil)
  if valid_612857 != nil:
    section.add "X-Amz-Signature", valid_612857
  var valid_612858 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612858 = validateParameter(valid_612858, JString, required = false,
                                 default = nil)
  if valid_612858 != nil:
    section.add "X-Amz-Content-Sha256", valid_612858
  var valid_612859 = header.getOrDefault("X-Amz-Date")
  valid_612859 = validateParameter(valid_612859, JString, required = false,
                                 default = nil)
  if valid_612859 != nil:
    section.add "X-Amz-Date", valid_612859
  var valid_612860 = header.getOrDefault("X-Amz-Credential")
  valid_612860 = validateParameter(valid_612860, JString, required = false,
                                 default = nil)
  if valid_612860 != nil:
    section.add "X-Amz-Credential", valid_612860
  var valid_612861 = header.getOrDefault("X-Amz-Security-Token")
  valid_612861 = validateParameter(valid_612861, JString, required = false,
                                 default = nil)
  if valid_612861 != nil:
    section.add "X-Amz-Security-Token", valid_612861
  var valid_612862 = header.getOrDefault("X-Amz-Algorithm")
  valid_612862 = validateParameter(valid_612862, JString, required = false,
                                 default = nil)
  if valid_612862 != nil:
    section.add "X-Amz-Algorithm", valid_612862
  var valid_612863 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612863 = validateParameter(valid_612863, JString, required = false,
                                 default = nil)
  if valid_612863 != nil:
    section.add "X-Amz-SignedHeaders", valid_612863
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612865: Call_StartAssociationsOnce_612853; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Use this API action to run an association immediately and only one time. This action can be helpful when troubleshooting associations.
  ## 
  let valid = call_612865.validator(path, query, header, formData, body)
  let scheme = call_612865.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612865.url(scheme.get, call_612865.host, call_612865.base,
                         call_612865.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612865, url, valid)

proc call*(call_612866: Call_StartAssociationsOnce_612853; body: JsonNode): Recallable =
  ## startAssociationsOnce
  ## Use this API action to run an association immediately and only one time. This action can be helpful when troubleshooting associations.
  ##   body: JObject (required)
  var body_612867 = newJObject()
  if body != nil:
    body_612867 = body
  result = call_612866.call(nil, nil, nil, nil, body_612867)

var startAssociationsOnce* = Call_StartAssociationsOnce_612853(
    name: "startAssociationsOnce", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.StartAssociationsOnce",
    validator: validate_StartAssociationsOnce_612854, base: "/",
    url: url_StartAssociationsOnce_612855, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartAutomationExecution_612868 = ref object of OpenApiRestCall_610658
proc url_StartAutomationExecution_612870(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StartAutomationExecution_612869(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612871 = header.getOrDefault("X-Amz-Target")
  valid_612871 = validateParameter(valid_612871, JString, required = true, default = newJString(
      "AmazonSSM.StartAutomationExecution"))
  if valid_612871 != nil:
    section.add "X-Amz-Target", valid_612871
  var valid_612872 = header.getOrDefault("X-Amz-Signature")
  valid_612872 = validateParameter(valid_612872, JString, required = false,
                                 default = nil)
  if valid_612872 != nil:
    section.add "X-Amz-Signature", valid_612872
  var valid_612873 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612873 = validateParameter(valid_612873, JString, required = false,
                                 default = nil)
  if valid_612873 != nil:
    section.add "X-Amz-Content-Sha256", valid_612873
  var valid_612874 = header.getOrDefault("X-Amz-Date")
  valid_612874 = validateParameter(valid_612874, JString, required = false,
                                 default = nil)
  if valid_612874 != nil:
    section.add "X-Amz-Date", valid_612874
  var valid_612875 = header.getOrDefault("X-Amz-Credential")
  valid_612875 = validateParameter(valid_612875, JString, required = false,
                                 default = nil)
  if valid_612875 != nil:
    section.add "X-Amz-Credential", valid_612875
  var valid_612876 = header.getOrDefault("X-Amz-Security-Token")
  valid_612876 = validateParameter(valid_612876, JString, required = false,
                                 default = nil)
  if valid_612876 != nil:
    section.add "X-Amz-Security-Token", valid_612876
  var valid_612877 = header.getOrDefault("X-Amz-Algorithm")
  valid_612877 = validateParameter(valid_612877, JString, required = false,
                                 default = nil)
  if valid_612877 != nil:
    section.add "X-Amz-Algorithm", valid_612877
  var valid_612878 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612878 = validateParameter(valid_612878, JString, required = false,
                                 default = nil)
  if valid_612878 != nil:
    section.add "X-Amz-SignedHeaders", valid_612878
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612880: Call_StartAutomationExecution_612868; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Initiates execution of an Automation document.
  ## 
  let valid = call_612880.validator(path, query, header, formData, body)
  let scheme = call_612880.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612880.url(scheme.get, call_612880.host, call_612880.base,
                         call_612880.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612880, url, valid)

proc call*(call_612881: Call_StartAutomationExecution_612868; body: JsonNode): Recallable =
  ## startAutomationExecution
  ## Initiates execution of an Automation document.
  ##   body: JObject (required)
  var body_612882 = newJObject()
  if body != nil:
    body_612882 = body
  result = call_612881.call(nil, nil, nil, nil, body_612882)

var startAutomationExecution* = Call_StartAutomationExecution_612868(
    name: "startAutomationExecution", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.StartAutomationExecution",
    validator: validate_StartAutomationExecution_612869, base: "/",
    url: url_StartAutomationExecution_612870, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartSession_612883 = ref object of OpenApiRestCall_610658
proc url_StartSession_612885(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StartSession_612884(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612886 = header.getOrDefault("X-Amz-Target")
  valid_612886 = validateParameter(valid_612886, JString, required = true,
                                 default = newJString("AmazonSSM.StartSession"))
  if valid_612886 != nil:
    section.add "X-Amz-Target", valid_612886
  var valid_612887 = header.getOrDefault("X-Amz-Signature")
  valid_612887 = validateParameter(valid_612887, JString, required = false,
                                 default = nil)
  if valid_612887 != nil:
    section.add "X-Amz-Signature", valid_612887
  var valid_612888 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612888 = validateParameter(valid_612888, JString, required = false,
                                 default = nil)
  if valid_612888 != nil:
    section.add "X-Amz-Content-Sha256", valid_612888
  var valid_612889 = header.getOrDefault("X-Amz-Date")
  valid_612889 = validateParameter(valid_612889, JString, required = false,
                                 default = nil)
  if valid_612889 != nil:
    section.add "X-Amz-Date", valid_612889
  var valid_612890 = header.getOrDefault("X-Amz-Credential")
  valid_612890 = validateParameter(valid_612890, JString, required = false,
                                 default = nil)
  if valid_612890 != nil:
    section.add "X-Amz-Credential", valid_612890
  var valid_612891 = header.getOrDefault("X-Amz-Security-Token")
  valid_612891 = validateParameter(valid_612891, JString, required = false,
                                 default = nil)
  if valid_612891 != nil:
    section.add "X-Amz-Security-Token", valid_612891
  var valid_612892 = header.getOrDefault("X-Amz-Algorithm")
  valid_612892 = validateParameter(valid_612892, JString, required = false,
                                 default = nil)
  if valid_612892 != nil:
    section.add "X-Amz-Algorithm", valid_612892
  var valid_612893 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612893 = validateParameter(valid_612893, JString, required = false,
                                 default = nil)
  if valid_612893 != nil:
    section.add "X-Amz-SignedHeaders", valid_612893
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612895: Call_StartSession_612883; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Initiates a connection to a target (for example, an instance) for a Session Manager session. Returns a URL and token that can be used to open a WebSocket connection for sending input and receiving outputs.</p> <note> <p>AWS CLI usage: <code>start-session</code> is an interactive command that requires the Session Manager plugin to be installed on the client machine making the call. For information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html"> Install the Session Manager Plugin for the AWS CLI</a> in the <i>AWS Systems Manager User Guide</i>.</p> <p>AWS Tools for PowerShell usage: Start-SSMSession is not currently supported by AWS Tools for PowerShell on Windows local machines.</p> </note>
  ## 
  let valid = call_612895.validator(path, query, header, formData, body)
  let scheme = call_612895.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612895.url(scheme.get, call_612895.host, call_612895.base,
                         call_612895.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612895, url, valid)

proc call*(call_612896: Call_StartSession_612883; body: JsonNode): Recallable =
  ## startSession
  ## <p>Initiates a connection to a target (for example, an instance) for a Session Manager session. Returns a URL and token that can be used to open a WebSocket connection for sending input and receiving outputs.</p> <note> <p>AWS CLI usage: <code>start-session</code> is an interactive command that requires the Session Manager plugin to be installed on the client machine making the call. For information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html"> Install the Session Manager Plugin for the AWS CLI</a> in the <i>AWS Systems Manager User Guide</i>.</p> <p>AWS Tools for PowerShell usage: Start-SSMSession is not currently supported by AWS Tools for PowerShell on Windows local machines.</p> </note>
  ##   body: JObject (required)
  var body_612897 = newJObject()
  if body != nil:
    body_612897 = body
  result = call_612896.call(nil, nil, nil, nil, body_612897)

var startSession* = Call_StartSession_612883(name: "startSession",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.StartSession",
    validator: validate_StartSession_612884, base: "/", url: url_StartSession_612885,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopAutomationExecution_612898 = ref object of OpenApiRestCall_610658
proc url_StopAutomationExecution_612900(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StopAutomationExecution_612899(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612901 = header.getOrDefault("X-Amz-Target")
  valid_612901 = validateParameter(valid_612901, JString, required = true, default = newJString(
      "AmazonSSM.StopAutomationExecution"))
  if valid_612901 != nil:
    section.add "X-Amz-Target", valid_612901
  var valid_612902 = header.getOrDefault("X-Amz-Signature")
  valid_612902 = validateParameter(valid_612902, JString, required = false,
                                 default = nil)
  if valid_612902 != nil:
    section.add "X-Amz-Signature", valid_612902
  var valid_612903 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612903 = validateParameter(valid_612903, JString, required = false,
                                 default = nil)
  if valid_612903 != nil:
    section.add "X-Amz-Content-Sha256", valid_612903
  var valid_612904 = header.getOrDefault("X-Amz-Date")
  valid_612904 = validateParameter(valid_612904, JString, required = false,
                                 default = nil)
  if valid_612904 != nil:
    section.add "X-Amz-Date", valid_612904
  var valid_612905 = header.getOrDefault("X-Amz-Credential")
  valid_612905 = validateParameter(valid_612905, JString, required = false,
                                 default = nil)
  if valid_612905 != nil:
    section.add "X-Amz-Credential", valid_612905
  var valid_612906 = header.getOrDefault("X-Amz-Security-Token")
  valid_612906 = validateParameter(valid_612906, JString, required = false,
                                 default = nil)
  if valid_612906 != nil:
    section.add "X-Amz-Security-Token", valid_612906
  var valid_612907 = header.getOrDefault("X-Amz-Algorithm")
  valid_612907 = validateParameter(valid_612907, JString, required = false,
                                 default = nil)
  if valid_612907 != nil:
    section.add "X-Amz-Algorithm", valid_612907
  var valid_612908 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612908 = validateParameter(valid_612908, JString, required = false,
                                 default = nil)
  if valid_612908 != nil:
    section.add "X-Amz-SignedHeaders", valid_612908
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612910: Call_StopAutomationExecution_612898; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Stop an Automation that is currently running.
  ## 
  let valid = call_612910.validator(path, query, header, formData, body)
  let scheme = call_612910.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612910.url(scheme.get, call_612910.host, call_612910.base,
                         call_612910.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612910, url, valid)

proc call*(call_612911: Call_StopAutomationExecution_612898; body: JsonNode): Recallable =
  ## stopAutomationExecution
  ## Stop an Automation that is currently running.
  ##   body: JObject (required)
  var body_612912 = newJObject()
  if body != nil:
    body_612912 = body
  result = call_612911.call(nil, nil, nil, nil, body_612912)

var stopAutomationExecution* = Call_StopAutomationExecution_612898(
    name: "stopAutomationExecution", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.StopAutomationExecution",
    validator: validate_StopAutomationExecution_612899, base: "/",
    url: url_StopAutomationExecution_612900, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TerminateSession_612913 = ref object of OpenApiRestCall_610658
proc url_TerminateSession_612915(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_TerminateSession_612914(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612916 = header.getOrDefault("X-Amz-Target")
  valid_612916 = validateParameter(valid_612916, JString, required = true, default = newJString(
      "AmazonSSM.TerminateSession"))
  if valid_612916 != nil:
    section.add "X-Amz-Target", valid_612916
  var valid_612917 = header.getOrDefault("X-Amz-Signature")
  valid_612917 = validateParameter(valid_612917, JString, required = false,
                                 default = nil)
  if valid_612917 != nil:
    section.add "X-Amz-Signature", valid_612917
  var valid_612918 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612918 = validateParameter(valid_612918, JString, required = false,
                                 default = nil)
  if valid_612918 != nil:
    section.add "X-Amz-Content-Sha256", valid_612918
  var valid_612919 = header.getOrDefault("X-Amz-Date")
  valid_612919 = validateParameter(valid_612919, JString, required = false,
                                 default = nil)
  if valid_612919 != nil:
    section.add "X-Amz-Date", valid_612919
  var valid_612920 = header.getOrDefault("X-Amz-Credential")
  valid_612920 = validateParameter(valid_612920, JString, required = false,
                                 default = nil)
  if valid_612920 != nil:
    section.add "X-Amz-Credential", valid_612920
  var valid_612921 = header.getOrDefault("X-Amz-Security-Token")
  valid_612921 = validateParameter(valid_612921, JString, required = false,
                                 default = nil)
  if valid_612921 != nil:
    section.add "X-Amz-Security-Token", valid_612921
  var valid_612922 = header.getOrDefault("X-Amz-Algorithm")
  valid_612922 = validateParameter(valid_612922, JString, required = false,
                                 default = nil)
  if valid_612922 != nil:
    section.add "X-Amz-Algorithm", valid_612922
  var valid_612923 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612923 = validateParameter(valid_612923, JString, required = false,
                                 default = nil)
  if valid_612923 != nil:
    section.add "X-Amz-SignedHeaders", valid_612923
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612925: Call_TerminateSession_612913; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Permanently ends a session and closes the data connection between the Session Manager client and SSM Agent on the instance. A terminated session cannot be resumed.
  ## 
  let valid = call_612925.validator(path, query, header, formData, body)
  let scheme = call_612925.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612925.url(scheme.get, call_612925.host, call_612925.base,
                         call_612925.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612925, url, valid)

proc call*(call_612926: Call_TerminateSession_612913; body: JsonNode): Recallable =
  ## terminateSession
  ## Permanently ends a session and closes the data connection between the Session Manager client and SSM Agent on the instance. A terminated session cannot be resumed.
  ##   body: JObject (required)
  var body_612927 = newJObject()
  if body != nil:
    body_612927 = body
  result = call_612926.call(nil, nil, nil, nil, body_612927)

var terminateSession* = Call_TerminateSession_612913(name: "terminateSession",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.TerminateSession",
    validator: validate_TerminateSession_612914, base: "/",
    url: url_TerminateSession_612915, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateAssociation_612928 = ref object of OpenApiRestCall_610658
proc url_UpdateAssociation_612930(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateAssociation_612929(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612931 = header.getOrDefault("X-Amz-Target")
  valid_612931 = validateParameter(valid_612931, JString, required = true, default = newJString(
      "AmazonSSM.UpdateAssociation"))
  if valid_612931 != nil:
    section.add "X-Amz-Target", valid_612931
  var valid_612932 = header.getOrDefault("X-Amz-Signature")
  valid_612932 = validateParameter(valid_612932, JString, required = false,
                                 default = nil)
  if valid_612932 != nil:
    section.add "X-Amz-Signature", valid_612932
  var valid_612933 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612933 = validateParameter(valid_612933, JString, required = false,
                                 default = nil)
  if valid_612933 != nil:
    section.add "X-Amz-Content-Sha256", valid_612933
  var valid_612934 = header.getOrDefault("X-Amz-Date")
  valid_612934 = validateParameter(valid_612934, JString, required = false,
                                 default = nil)
  if valid_612934 != nil:
    section.add "X-Amz-Date", valid_612934
  var valid_612935 = header.getOrDefault("X-Amz-Credential")
  valid_612935 = validateParameter(valid_612935, JString, required = false,
                                 default = nil)
  if valid_612935 != nil:
    section.add "X-Amz-Credential", valid_612935
  var valid_612936 = header.getOrDefault("X-Amz-Security-Token")
  valid_612936 = validateParameter(valid_612936, JString, required = false,
                                 default = nil)
  if valid_612936 != nil:
    section.add "X-Amz-Security-Token", valid_612936
  var valid_612937 = header.getOrDefault("X-Amz-Algorithm")
  valid_612937 = validateParameter(valid_612937, JString, required = false,
                                 default = nil)
  if valid_612937 != nil:
    section.add "X-Amz-Algorithm", valid_612937
  var valid_612938 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612938 = validateParameter(valid_612938, JString, required = false,
                                 default = nil)
  if valid_612938 != nil:
    section.add "X-Amz-SignedHeaders", valid_612938
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612940: Call_UpdateAssociation_612928; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates an association. You can update the association name and version, the document version, schedule, parameters, and Amazon S3 output. </p> <p>In order to call this API action, your IAM user account, group, or role must be configured with permission to call the <a>DescribeAssociation</a> API action. If you don't have permission to call DescribeAssociation, then you receive the following error: <code>An error occurred (AccessDeniedException) when calling the UpdateAssociation operation: User: &lt;user_arn&gt; is not authorized to perform: ssm:DescribeAssociation on resource: &lt;resource_arn&gt;</code> </p> <important> <p>When you update an association, the association immediately runs against the specified targets.</p> </important>
  ## 
  let valid = call_612940.validator(path, query, header, formData, body)
  let scheme = call_612940.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612940.url(scheme.get, call_612940.host, call_612940.base,
                         call_612940.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612940, url, valid)

proc call*(call_612941: Call_UpdateAssociation_612928; body: JsonNode): Recallable =
  ## updateAssociation
  ## <p>Updates an association. You can update the association name and version, the document version, schedule, parameters, and Amazon S3 output. </p> <p>In order to call this API action, your IAM user account, group, or role must be configured with permission to call the <a>DescribeAssociation</a> API action. If you don't have permission to call DescribeAssociation, then you receive the following error: <code>An error occurred (AccessDeniedException) when calling the UpdateAssociation operation: User: &lt;user_arn&gt; is not authorized to perform: ssm:DescribeAssociation on resource: &lt;resource_arn&gt;</code> </p> <important> <p>When you update an association, the association immediately runs against the specified targets.</p> </important>
  ##   body: JObject (required)
  var body_612942 = newJObject()
  if body != nil:
    body_612942 = body
  result = call_612941.call(nil, nil, nil, nil, body_612942)

var updateAssociation* = Call_UpdateAssociation_612928(name: "updateAssociation",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.UpdateAssociation",
    validator: validate_UpdateAssociation_612929, base: "/",
    url: url_UpdateAssociation_612930, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateAssociationStatus_612943 = ref object of OpenApiRestCall_610658
proc url_UpdateAssociationStatus_612945(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateAssociationStatus_612944(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612946 = header.getOrDefault("X-Amz-Target")
  valid_612946 = validateParameter(valid_612946, JString, required = true, default = newJString(
      "AmazonSSM.UpdateAssociationStatus"))
  if valid_612946 != nil:
    section.add "X-Amz-Target", valid_612946
  var valid_612947 = header.getOrDefault("X-Amz-Signature")
  valid_612947 = validateParameter(valid_612947, JString, required = false,
                                 default = nil)
  if valid_612947 != nil:
    section.add "X-Amz-Signature", valid_612947
  var valid_612948 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612948 = validateParameter(valid_612948, JString, required = false,
                                 default = nil)
  if valid_612948 != nil:
    section.add "X-Amz-Content-Sha256", valid_612948
  var valid_612949 = header.getOrDefault("X-Amz-Date")
  valid_612949 = validateParameter(valid_612949, JString, required = false,
                                 default = nil)
  if valid_612949 != nil:
    section.add "X-Amz-Date", valid_612949
  var valid_612950 = header.getOrDefault("X-Amz-Credential")
  valid_612950 = validateParameter(valid_612950, JString, required = false,
                                 default = nil)
  if valid_612950 != nil:
    section.add "X-Amz-Credential", valid_612950
  var valid_612951 = header.getOrDefault("X-Amz-Security-Token")
  valid_612951 = validateParameter(valid_612951, JString, required = false,
                                 default = nil)
  if valid_612951 != nil:
    section.add "X-Amz-Security-Token", valid_612951
  var valid_612952 = header.getOrDefault("X-Amz-Algorithm")
  valid_612952 = validateParameter(valid_612952, JString, required = false,
                                 default = nil)
  if valid_612952 != nil:
    section.add "X-Amz-Algorithm", valid_612952
  var valid_612953 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612953 = validateParameter(valid_612953, JString, required = false,
                                 default = nil)
  if valid_612953 != nil:
    section.add "X-Amz-SignedHeaders", valid_612953
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612955: Call_UpdateAssociationStatus_612943; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the status of the Systems Manager document associated with the specified instance.
  ## 
  let valid = call_612955.validator(path, query, header, formData, body)
  let scheme = call_612955.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612955.url(scheme.get, call_612955.host, call_612955.base,
                         call_612955.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612955, url, valid)

proc call*(call_612956: Call_UpdateAssociationStatus_612943; body: JsonNode): Recallable =
  ## updateAssociationStatus
  ## Updates the status of the Systems Manager document associated with the specified instance.
  ##   body: JObject (required)
  var body_612957 = newJObject()
  if body != nil:
    body_612957 = body
  result = call_612956.call(nil, nil, nil, nil, body_612957)

var updateAssociationStatus* = Call_UpdateAssociationStatus_612943(
    name: "updateAssociationStatus", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.UpdateAssociationStatus",
    validator: validate_UpdateAssociationStatus_612944, base: "/",
    url: url_UpdateAssociationStatus_612945, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDocument_612958 = ref object of OpenApiRestCall_610658
proc url_UpdateDocument_612960(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateDocument_612959(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612961 = header.getOrDefault("X-Amz-Target")
  valid_612961 = validateParameter(valid_612961, JString, required = true, default = newJString(
      "AmazonSSM.UpdateDocument"))
  if valid_612961 != nil:
    section.add "X-Amz-Target", valid_612961
  var valid_612962 = header.getOrDefault("X-Amz-Signature")
  valid_612962 = validateParameter(valid_612962, JString, required = false,
                                 default = nil)
  if valid_612962 != nil:
    section.add "X-Amz-Signature", valid_612962
  var valid_612963 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612963 = validateParameter(valid_612963, JString, required = false,
                                 default = nil)
  if valid_612963 != nil:
    section.add "X-Amz-Content-Sha256", valid_612963
  var valid_612964 = header.getOrDefault("X-Amz-Date")
  valid_612964 = validateParameter(valid_612964, JString, required = false,
                                 default = nil)
  if valid_612964 != nil:
    section.add "X-Amz-Date", valid_612964
  var valid_612965 = header.getOrDefault("X-Amz-Credential")
  valid_612965 = validateParameter(valid_612965, JString, required = false,
                                 default = nil)
  if valid_612965 != nil:
    section.add "X-Amz-Credential", valid_612965
  var valid_612966 = header.getOrDefault("X-Amz-Security-Token")
  valid_612966 = validateParameter(valid_612966, JString, required = false,
                                 default = nil)
  if valid_612966 != nil:
    section.add "X-Amz-Security-Token", valid_612966
  var valid_612967 = header.getOrDefault("X-Amz-Algorithm")
  valid_612967 = validateParameter(valid_612967, JString, required = false,
                                 default = nil)
  if valid_612967 != nil:
    section.add "X-Amz-Algorithm", valid_612967
  var valid_612968 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612968 = validateParameter(valid_612968, JString, required = false,
                                 default = nil)
  if valid_612968 != nil:
    section.add "X-Amz-SignedHeaders", valid_612968
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612970: Call_UpdateDocument_612958; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates one or more values for an SSM document.
  ## 
  let valid = call_612970.validator(path, query, header, formData, body)
  let scheme = call_612970.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612970.url(scheme.get, call_612970.host, call_612970.base,
                         call_612970.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612970, url, valid)

proc call*(call_612971: Call_UpdateDocument_612958; body: JsonNode): Recallable =
  ## updateDocument
  ## Updates one or more values for an SSM document.
  ##   body: JObject (required)
  var body_612972 = newJObject()
  if body != nil:
    body_612972 = body
  result = call_612971.call(nil, nil, nil, nil, body_612972)

var updateDocument* = Call_UpdateDocument_612958(name: "updateDocument",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.UpdateDocument",
    validator: validate_UpdateDocument_612959, base: "/", url: url_UpdateDocument_612960,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDocumentDefaultVersion_612973 = ref object of OpenApiRestCall_610658
proc url_UpdateDocumentDefaultVersion_612975(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateDocumentDefaultVersion_612974(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612976 = header.getOrDefault("X-Amz-Target")
  valid_612976 = validateParameter(valid_612976, JString, required = true, default = newJString(
      "AmazonSSM.UpdateDocumentDefaultVersion"))
  if valid_612976 != nil:
    section.add "X-Amz-Target", valid_612976
  var valid_612977 = header.getOrDefault("X-Amz-Signature")
  valid_612977 = validateParameter(valid_612977, JString, required = false,
                                 default = nil)
  if valid_612977 != nil:
    section.add "X-Amz-Signature", valid_612977
  var valid_612978 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612978 = validateParameter(valid_612978, JString, required = false,
                                 default = nil)
  if valid_612978 != nil:
    section.add "X-Amz-Content-Sha256", valid_612978
  var valid_612979 = header.getOrDefault("X-Amz-Date")
  valid_612979 = validateParameter(valid_612979, JString, required = false,
                                 default = nil)
  if valid_612979 != nil:
    section.add "X-Amz-Date", valid_612979
  var valid_612980 = header.getOrDefault("X-Amz-Credential")
  valid_612980 = validateParameter(valid_612980, JString, required = false,
                                 default = nil)
  if valid_612980 != nil:
    section.add "X-Amz-Credential", valid_612980
  var valid_612981 = header.getOrDefault("X-Amz-Security-Token")
  valid_612981 = validateParameter(valid_612981, JString, required = false,
                                 default = nil)
  if valid_612981 != nil:
    section.add "X-Amz-Security-Token", valid_612981
  var valid_612982 = header.getOrDefault("X-Amz-Algorithm")
  valid_612982 = validateParameter(valid_612982, JString, required = false,
                                 default = nil)
  if valid_612982 != nil:
    section.add "X-Amz-Algorithm", valid_612982
  var valid_612983 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612983 = validateParameter(valid_612983, JString, required = false,
                                 default = nil)
  if valid_612983 != nil:
    section.add "X-Amz-SignedHeaders", valid_612983
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612985: Call_UpdateDocumentDefaultVersion_612973; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Set the default version of a document. 
  ## 
  let valid = call_612985.validator(path, query, header, formData, body)
  let scheme = call_612985.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612985.url(scheme.get, call_612985.host, call_612985.base,
                         call_612985.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612985, url, valid)

proc call*(call_612986: Call_UpdateDocumentDefaultVersion_612973; body: JsonNode): Recallable =
  ## updateDocumentDefaultVersion
  ## Set the default version of a document. 
  ##   body: JObject (required)
  var body_612987 = newJObject()
  if body != nil:
    body_612987 = body
  result = call_612986.call(nil, nil, nil, nil, body_612987)

var updateDocumentDefaultVersion* = Call_UpdateDocumentDefaultVersion_612973(
    name: "updateDocumentDefaultVersion", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.UpdateDocumentDefaultVersion",
    validator: validate_UpdateDocumentDefaultVersion_612974, base: "/",
    url: url_UpdateDocumentDefaultVersion_612975,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateMaintenanceWindow_612988 = ref object of OpenApiRestCall_610658
proc url_UpdateMaintenanceWindow_612990(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateMaintenanceWindow_612989(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612991 = header.getOrDefault("X-Amz-Target")
  valid_612991 = validateParameter(valid_612991, JString, required = true, default = newJString(
      "AmazonSSM.UpdateMaintenanceWindow"))
  if valid_612991 != nil:
    section.add "X-Amz-Target", valid_612991
  var valid_612992 = header.getOrDefault("X-Amz-Signature")
  valid_612992 = validateParameter(valid_612992, JString, required = false,
                                 default = nil)
  if valid_612992 != nil:
    section.add "X-Amz-Signature", valid_612992
  var valid_612993 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612993 = validateParameter(valid_612993, JString, required = false,
                                 default = nil)
  if valid_612993 != nil:
    section.add "X-Amz-Content-Sha256", valid_612993
  var valid_612994 = header.getOrDefault("X-Amz-Date")
  valid_612994 = validateParameter(valid_612994, JString, required = false,
                                 default = nil)
  if valid_612994 != nil:
    section.add "X-Amz-Date", valid_612994
  var valid_612995 = header.getOrDefault("X-Amz-Credential")
  valid_612995 = validateParameter(valid_612995, JString, required = false,
                                 default = nil)
  if valid_612995 != nil:
    section.add "X-Amz-Credential", valid_612995
  var valid_612996 = header.getOrDefault("X-Amz-Security-Token")
  valid_612996 = validateParameter(valid_612996, JString, required = false,
                                 default = nil)
  if valid_612996 != nil:
    section.add "X-Amz-Security-Token", valid_612996
  var valid_612997 = header.getOrDefault("X-Amz-Algorithm")
  valid_612997 = validateParameter(valid_612997, JString, required = false,
                                 default = nil)
  if valid_612997 != nil:
    section.add "X-Amz-Algorithm", valid_612997
  var valid_612998 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612998 = validateParameter(valid_612998, JString, required = false,
                                 default = nil)
  if valid_612998 != nil:
    section.add "X-Amz-SignedHeaders", valid_612998
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613000: Call_UpdateMaintenanceWindow_612988; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates an existing maintenance window. Only specified parameters are modified.</p> <note> <p>The value you specify for <code>Duration</code> determines the specific end time for the maintenance window based on the time it begins. No maintenance window tasks are permitted to start after the resulting endtime minus the number of hours you specify for <code>Cutoff</code>. For example, if the maintenance window starts at 3 PM, the duration is three hours, and the value you specify for <code>Cutoff</code> is one hour, no maintenance window tasks can start after 5 PM.</p> </note>
  ## 
  let valid = call_613000.validator(path, query, header, formData, body)
  let scheme = call_613000.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613000.url(scheme.get, call_613000.host, call_613000.base,
                         call_613000.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613000, url, valid)

proc call*(call_613001: Call_UpdateMaintenanceWindow_612988; body: JsonNode): Recallable =
  ## updateMaintenanceWindow
  ## <p>Updates an existing maintenance window. Only specified parameters are modified.</p> <note> <p>The value you specify for <code>Duration</code> determines the specific end time for the maintenance window based on the time it begins. No maintenance window tasks are permitted to start after the resulting endtime minus the number of hours you specify for <code>Cutoff</code>. For example, if the maintenance window starts at 3 PM, the duration is three hours, and the value you specify for <code>Cutoff</code> is one hour, no maintenance window tasks can start after 5 PM.</p> </note>
  ##   body: JObject (required)
  var body_613002 = newJObject()
  if body != nil:
    body_613002 = body
  result = call_613001.call(nil, nil, nil, nil, body_613002)

var updateMaintenanceWindow* = Call_UpdateMaintenanceWindow_612988(
    name: "updateMaintenanceWindow", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.UpdateMaintenanceWindow",
    validator: validate_UpdateMaintenanceWindow_612989, base: "/",
    url: url_UpdateMaintenanceWindow_612990, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateMaintenanceWindowTarget_613003 = ref object of OpenApiRestCall_610658
proc url_UpdateMaintenanceWindowTarget_613005(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateMaintenanceWindowTarget_613004(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613006 = header.getOrDefault("X-Amz-Target")
  valid_613006 = validateParameter(valid_613006, JString, required = true, default = newJString(
      "AmazonSSM.UpdateMaintenanceWindowTarget"))
  if valid_613006 != nil:
    section.add "X-Amz-Target", valid_613006
  var valid_613007 = header.getOrDefault("X-Amz-Signature")
  valid_613007 = validateParameter(valid_613007, JString, required = false,
                                 default = nil)
  if valid_613007 != nil:
    section.add "X-Amz-Signature", valid_613007
  var valid_613008 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613008 = validateParameter(valid_613008, JString, required = false,
                                 default = nil)
  if valid_613008 != nil:
    section.add "X-Amz-Content-Sha256", valid_613008
  var valid_613009 = header.getOrDefault("X-Amz-Date")
  valid_613009 = validateParameter(valid_613009, JString, required = false,
                                 default = nil)
  if valid_613009 != nil:
    section.add "X-Amz-Date", valid_613009
  var valid_613010 = header.getOrDefault("X-Amz-Credential")
  valid_613010 = validateParameter(valid_613010, JString, required = false,
                                 default = nil)
  if valid_613010 != nil:
    section.add "X-Amz-Credential", valid_613010
  var valid_613011 = header.getOrDefault("X-Amz-Security-Token")
  valid_613011 = validateParameter(valid_613011, JString, required = false,
                                 default = nil)
  if valid_613011 != nil:
    section.add "X-Amz-Security-Token", valid_613011
  var valid_613012 = header.getOrDefault("X-Amz-Algorithm")
  valid_613012 = validateParameter(valid_613012, JString, required = false,
                                 default = nil)
  if valid_613012 != nil:
    section.add "X-Amz-Algorithm", valid_613012
  var valid_613013 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613013 = validateParameter(valid_613013, JString, required = false,
                                 default = nil)
  if valid_613013 != nil:
    section.add "X-Amz-SignedHeaders", valid_613013
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613015: Call_UpdateMaintenanceWindowTarget_613003; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Modifies the target of an existing maintenance window. You can change the following:</p> <ul> <li> <p>Name</p> </li> <li> <p>Description</p> </li> <li> <p>Owner</p> </li> <li> <p>IDs for an ID target</p> </li> <li> <p>Tags for a Tag target</p> </li> <li> <p>From any supported tag type to another. The three supported tag types are ID target, Tag target, and resource group. For more information, see <a>Target</a>.</p> </li> </ul> <note> <p>If a parameter is null, then the corresponding field is not modified.</p> </note>
  ## 
  let valid = call_613015.validator(path, query, header, formData, body)
  let scheme = call_613015.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613015.url(scheme.get, call_613015.host, call_613015.base,
                         call_613015.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613015, url, valid)

proc call*(call_613016: Call_UpdateMaintenanceWindowTarget_613003; body: JsonNode): Recallable =
  ## updateMaintenanceWindowTarget
  ## <p>Modifies the target of an existing maintenance window. You can change the following:</p> <ul> <li> <p>Name</p> </li> <li> <p>Description</p> </li> <li> <p>Owner</p> </li> <li> <p>IDs for an ID target</p> </li> <li> <p>Tags for a Tag target</p> </li> <li> <p>From any supported tag type to another. The three supported tag types are ID target, Tag target, and resource group. For more information, see <a>Target</a>.</p> </li> </ul> <note> <p>If a parameter is null, then the corresponding field is not modified.</p> </note>
  ##   body: JObject (required)
  var body_613017 = newJObject()
  if body != nil:
    body_613017 = body
  result = call_613016.call(nil, nil, nil, nil, body_613017)

var updateMaintenanceWindowTarget* = Call_UpdateMaintenanceWindowTarget_613003(
    name: "updateMaintenanceWindowTarget", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.UpdateMaintenanceWindowTarget",
    validator: validate_UpdateMaintenanceWindowTarget_613004, base: "/",
    url: url_UpdateMaintenanceWindowTarget_613005,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateMaintenanceWindowTask_613018 = ref object of OpenApiRestCall_610658
proc url_UpdateMaintenanceWindowTask_613020(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateMaintenanceWindowTask_613019(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613021 = header.getOrDefault("X-Amz-Target")
  valid_613021 = validateParameter(valid_613021, JString, required = true, default = newJString(
      "AmazonSSM.UpdateMaintenanceWindowTask"))
  if valid_613021 != nil:
    section.add "X-Amz-Target", valid_613021
  var valid_613022 = header.getOrDefault("X-Amz-Signature")
  valid_613022 = validateParameter(valid_613022, JString, required = false,
                                 default = nil)
  if valid_613022 != nil:
    section.add "X-Amz-Signature", valid_613022
  var valid_613023 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613023 = validateParameter(valid_613023, JString, required = false,
                                 default = nil)
  if valid_613023 != nil:
    section.add "X-Amz-Content-Sha256", valid_613023
  var valid_613024 = header.getOrDefault("X-Amz-Date")
  valid_613024 = validateParameter(valid_613024, JString, required = false,
                                 default = nil)
  if valid_613024 != nil:
    section.add "X-Amz-Date", valid_613024
  var valid_613025 = header.getOrDefault("X-Amz-Credential")
  valid_613025 = validateParameter(valid_613025, JString, required = false,
                                 default = nil)
  if valid_613025 != nil:
    section.add "X-Amz-Credential", valid_613025
  var valid_613026 = header.getOrDefault("X-Amz-Security-Token")
  valid_613026 = validateParameter(valid_613026, JString, required = false,
                                 default = nil)
  if valid_613026 != nil:
    section.add "X-Amz-Security-Token", valid_613026
  var valid_613027 = header.getOrDefault("X-Amz-Algorithm")
  valid_613027 = validateParameter(valid_613027, JString, required = false,
                                 default = nil)
  if valid_613027 != nil:
    section.add "X-Amz-Algorithm", valid_613027
  var valid_613028 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613028 = validateParameter(valid_613028, JString, required = false,
                                 default = nil)
  if valid_613028 != nil:
    section.add "X-Amz-SignedHeaders", valid_613028
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613030: Call_UpdateMaintenanceWindowTask_613018; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Modifies a task assigned to a maintenance window. You can't change the task type, but you can change the following values:</p> <ul> <li> <p>TaskARN. For example, you can change a RUN_COMMAND task from AWS-RunPowerShellScript to AWS-RunShellScript.</p> </li> <li> <p>ServiceRoleArn</p> </li> <li> <p>TaskInvocationParameters</p> </li> <li> <p>Priority</p> </li> <li> <p>MaxConcurrency</p> </li> <li> <p>MaxErrors</p> </li> </ul> <p>If a parameter is null, then the corresponding field is not modified. Also, if you set Replace to true, then all fields required by the <a>RegisterTaskWithMaintenanceWindow</a> action are required for this request. Optional fields that aren't specified are set to null.</p>
  ## 
  let valid = call_613030.validator(path, query, header, formData, body)
  let scheme = call_613030.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613030.url(scheme.get, call_613030.host, call_613030.base,
                         call_613030.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613030, url, valid)

proc call*(call_613031: Call_UpdateMaintenanceWindowTask_613018; body: JsonNode): Recallable =
  ## updateMaintenanceWindowTask
  ## <p>Modifies a task assigned to a maintenance window. You can't change the task type, but you can change the following values:</p> <ul> <li> <p>TaskARN. For example, you can change a RUN_COMMAND task from AWS-RunPowerShellScript to AWS-RunShellScript.</p> </li> <li> <p>ServiceRoleArn</p> </li> <li> <p>TaskInvocationParameters</p> </li> <li> <p>Priority</p> </li> <li> <p>MaxConcurrency</p> </li> <li> <p>MaxErrors</p> </li> </ul> <p>If a parameter is null, then the corresponding field is not modified. Also, if you set Replace to true, then all fields required by the <a>RegisterTaskWithMaintenanceWindow</a> action are required for this request. Optional fields that aren't specified are set to null.</p>
  ##   body: JObject (required)
  var body_613032 = newJObject()
  if body != nil:
    body_613032 = body
  result = call_613031.call(nil, nil, nil, nil, body_613032)

var updateMaintenanceWindowTask* = Call_UpdateMaintenanceWindowTask_613018(
    name: "updateMaintenanceWindowTask", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.UpdateMaintenanceWindowTask",
    validator: validate_UpdateMaintenanceWindowTask_613019, base: "/",
    url: url_UpdateMaintenanceWindowTask_613020,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateManagedInstanceRole_613033 = ref object of OpenApiRestCall_610658
proc url_UpdateManagedInstanceRole_613035(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateManagedInstanceRole_613034(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613036 = header.getOrDefault("X-Amz-Target")
  valid_613036 = validateParameter(valid_613036, JString, required = true, default = newJString(
      "AmazonSSM.UpdateManagedInstanceRole"))
  if valid_613036 != nil:
    section.add "X-Amz-Target", valid_613036
  var valid_613037 = header.getOrDefault("X-Amz-Signature")
  valid_613037 = validateParameter(valid_613037, JString, required = false,
                                 default = nil)
  if valid_613037 != nil:
    section.add "X-Amz-Signature", valid_613037
  var valid_613038 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613038 = validateParameter(valid_613038, JString, required = false,
                                 default = nil)
  if valid_613038 != nil:
    section.add "X-Amz-Content-Sha256", valid_613038
  var valid_613039 = header.getOrDefault("X-Amz-Date")
  valid_613039 = validateParameter(valid_613039, JString, required = false,
                                 default = nil)
  if valid_613039 != nil:
    section.add "X-Amz-Date", valid_613039
  var valid_613040 = header.getOrDefault("X-Amz-Credential")
  valid_613040 = validateParameter(valid_613040, JString, required = false,
                                 default = nil)
  if valid_613040 != nil:
    section.add "X-Amz-Credential", valid_613040
  var valid_613041 = header.getOrDefault("X-Amz-Security-Token")
  valid_613041 = validateParameter(valid_613041, JString, required = false,
                                 default = nil)
  if valid_613041 != nil:
    section.add "X-Amz-Security-Token", valid_613041
  var valid_613042 = header.getOrDefault("X-Amz-Algorithm")
  valid_613042 = validateParameter(valid_613042, JString, required = false,
                                 default = nil)
  if valid_613042 != nil:
    section.add "X-Amz-Algorithm", valid_613042
  var valid_613043 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613043 = validateParameter(valid_613043, JString, required = false,
                                 default = nil)
  if valid_613043 != nil:
    section.add "X-Amz-SignedHeaders", valid_613043
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613045: Call_UpdateManagedInstanceRole_613033; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Assigns or changes an Amazon Identity and Access Management (IAM) role for the managed instance.
  ## 
  let valid = call_613045.validator(path, query, header, formData, body)
  let scheme = call_613045.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613045.url(scheme.get, call_613045.host, call_613045.base,
                         call_613045.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613045, url, valid)

proc call*(call_613046: Call_UpdateManagedInstanceRole_613033; body: JsonNode): Recallable =
  ## updateManagedInstanceRole
  ## Assigns or changes an Amazon Identity and Access Management (IAM) role for the managed instance.
  ##   body: JObject (required)
  var body_613047 = newJObject()
  if body != nil:
    body_613047 = body
  result = call_613046.call(nil, nil, nil, nil, body_613047)

var updateManagedInstanceRole* = Call_UpdateManagedInstanceRole_613033(
    name: "updateManagedInstanceRole", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.UpdateManagedInstanceRole",
    validator: validate_UpdateManagedInstanceRole_613034, base: "/",
    url: url_UpdateManagedInstanceRole_613035,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateOpsItem_613048 = ref object of OpenApiRestCall_610658
proc url_UpdateOpsItem_613050(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateOpsItem_613049(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613051 = header.getOrDefault("X-Amz-Target")
  valid_613051 = validateParameter(valid_613051, JString, required = true, default = newJString(
      "AmazonSSM.UpdateOpsItem"))
  if valid_613051 != nil:
    section.add "X-Amz-Target", valid_613051
  var valid_613052 = header.getOrDefault("X-Amz-Signature")
  valid_613052 = validateParameter(valid_613052, JString, required = false,
                                 default = nil)
  if valid_613052 != nil:
    section.add "X-Amz-Signature", valid_613052
  var valid_613053 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613053 = validateParameter(valid_613053, JString, required = false,
                                 default = nil)
  if valid_613053 != nil:
    section.add "X-Amz-Content-Sha256", valid_613053
  var valid_613054 = header.getOrDefault("X-Amz-Date")
  valid_613054 = validateParameter(valid_613054, JString, required = false,
                                 default = nil)
  if valid_613054 != nil:
    section.add "X-Amz-Date", valid_613054
  var valid_613055 = header.getOrDefault("X-Amz-Credential")
  valid_613055 = validateParameter(valid_613055, JString, required = false,
                                 default = nil)
  if valid_613055 != nil:
    section.add "X-Amz-Credential", valid_613055
  var valid_613056 = header.getOrDefault("X-Amz-Security-Token")
  valid_613056 = validateParameter(valid_613056, JString, required = false,
                                 default = nil)
  if valid_613056 != nil:
    section.add "X-Amz-Security-Token", valid_613056
  var valid_613057 = header.getOrDefault("X-Amz-Algorithm")
  valid_613057 = validateParameter(valid_613057, JString, required = false,
                                 default = nil)
  if valid_613057 != nil:
    section.add "X-Amz-Algorithm", valid_613057
  var valid_613058 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613058 = validateParameter(valid_613058, JString, required = false,
                                 default = nil)
  if valid_613058 != nil:
    section.add "X-Amz-SignedHeaders", valid_613058
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613060: Call_UpdateOpsItem_613048; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Edit or change an OpsItem. You must have permission in AWS Identity and Access Management (IAM) to update an OpsItem. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter-getting-started.html">Getting Started with OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>.</p> <p>Operations engineers and IT professionals use OpsCenter to view, investigate, and remediate operational issues impacting the performance and health of their AWS resources. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter.html">AWS Systems Manager OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>. </p>
  ## 
  let valid = call_613060.validator(path, query, header, formData, body)
  let scheme = call_613060.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613060.url(scheme.get, call_613060.host, call_613060.base,
                         call_613060.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613060, url, valid)

proc call*(call_613061: Call_UpdateOpsItem_613048; body: JsonNode): Recallable =
  ## updateOpsItem
  ## <p>Edit or change an OpsItem. You must have permission in AWS Identity and Access Management (IAM) to update an OpsItem. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter-getting-started.html">Getting Started with OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>.</p> <p>Operations engineers and IT professionals use OpsCenter to view, investigate, and remediate operational issues impacting the performance and health of their AWS resources. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter.html">AWS Systems Manager OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>. </p>
  ##   body: JObject (required)
  var body_613062 = newJObject()
  if body != nil:
    body_613062 = body
  result = call_613061.call(nil, nil, nil, nil, body_613062)

var updateOpsItem* = Call_UpdateOpsItem_613048(name: "updateOpsItem",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.UpdateOpsItem",
    validator: validate_UpdateOpsItem_613049, base: "/", url: url_UpdateOpsItem_613050,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdatePatchBaseline_613063 = ref object of OpenApiRestCall_610658
proc url_UpdatePatchBaseline_613065(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdatePatchBaseline_613064(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613066 = header.getOrDefault("X-Amz-Target")
  valid_613066 = validateParameter(valid_613066, JString, required = true, default = newJString(
      "AmazonSSM.UpdatePatchBaseline"))
  if valid_613066 != nil:
    section.add "X-Amz-Target", valid_613066
  var valid_613067 = header.getOrDefault("X-Amz-Signature")
  valid_613067 = validateParameter(valid_613067, JString, required = false,
                                 default = nil)
  if valid_613067 != nil:
    section.add "X-Amz-Signature", valid_613067
  var valid_613068 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613068 = validateParameter(valid_613068, JString, required = false,
                                 default = nil)
  if valid_613068 != nil:
    section.add "X-Amz-Content-Sha256", valid_613068
  var valid_613069 = header.getOrDefault("X-Amz-Date")
  valid_613069 = validateParameter(valid_613069, JString, required = false,
                                 default = nil)
  if valid_613069 != nil:
    section.add "X-Amz-Date", valid_613069
  var valid_613070 = header.getOrDefault("X-Amz-Credential")
  valid_613070 = validateParameter(valid_613070, JString, required = false,
                                 default = nil)
  if valid_613070 != nil:
    section.add "X-Amz-Credential", valid_613070
  var valid_613071 = header.getOrDefault("X-Amz-Security-Token")
  valid_613071 = validateParameter(valid_613071, JString, required = false,
                                 default = nil)
  if valid_613071 != nil:
    section.add "X-Amz-Security-Token", valid_613071
  var valid_613072 = header.getOrDefault("X-Amz-Algorithm")
  valid_613072 = validateParameter(valid_613072, JString, required = false,
                                 default = nil)
  if valid_613072 != nil:
    section.add "X-Amz-Algorithm", valid_613072
  var valid_613073 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613073 = validateParameter(valid_613073, JString, required = false,
                                 default = nil)
  if valid_613073 != nil:
    section.add "X-Amz-SignedHeaders", valid_613073
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613075: Call_UpdatePatchBaseline_613063; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Modifies an existing patch baseline. Fields not specified in the request are left unchanged.</p> <note> <p>For information about valid key and value pairs in <code>PatchFilters</code> for each supported operating system type, see <a href="http://docs.aws.amazon.com/systems-manager/latest/APIReference/API_PatchFilter.html">PatchFilter</a>.</p> </note>
  ## 
  let valid = call_613075.validator(path, query, header, formData, body)
  let scheme = call_613075.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613075.url(scheme.get, call_613075.host, call_613075.base,
                         call_613075.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613075, url, valid)

proc call*(call_613076: Call_UpdatePatchBaseline_613063; body: JsonNode): Recallable =
  ## updatePatchBaseline
  ## <p>Modifies an existing patch baseline. Fields not specified in the request are left unchanged.</p> <note> <p>For information about valid key and value pairs in <code>PatchFilters</code> for each supported operating system type, see <a href="http://docs.aws.amazon.com/systems-manager/latest/APIReference/API_PatchFilter.html">PatchFilter</a>.</p> </note>
  ##   body: JObject (required)
  var body_613077 = newJObject()
  if body != nil:
    body_613077 = body
  result = call_613076.call(nil, nil, nil, nil, body_613077)

var updatePatchBaseline* = Call_UpdatePatchBaseline_613063(
    name: "updatePatchBaseline", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.UpdatePatchBaseline",
    validator: validate_UpdatePatchBaseline_613064, base: "/",
    url: url_UpdatePatchBaseline_613065, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateResourceDataSync_613078 = ref object of OpenApiRestCall_610658
proc url_UpdateResourceDataSync_613080(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateResourceDataSync_613079(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Update a resource data sync. After you create a resource data sync for a Region, you can't change the account options for that sync. For example, if you create a sync in the us-east-2 (Ohio) Region and you choose the Include only the current account option, you can't edit that sync later and choose the Include all accounts from my AWS Organizations configuration option. Instead, you must delete the first resource data sync, and create a new one.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613081 = header.getOrDefault("X-Amz-Target")
  valid_613081 = validateParameter(valid_613081, JString, required = true, default = newJString(
      "AmazonSSM.UpdateResourceDataSync"))
  if valid_613081 != nil:
    section.add "X-Amz-Target", valid_613081
  var valid_613082 = header.getOrDefault("X-Amz-Signature")
  valid_613082 = validateParameter(valid_613082, JString, required = false,
                                 default = nil)
  if valid_613082 != nil:
    section.add "X-Amz-Signature", valid_613082
  var valid_613083 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613083 = validateParameter(valid_613083, JString, required = false,
                                 default = nil)
  if valid_613083 != nil:
    section.add "X-Amz-Content-Sha256", valid_613083
  var valid_613084 = header.getOrDefault("X-Amz-Date")
  valid_613084 = validateParameter(valid_613084, JString, required = false,
                                 default = nil)
  if valid_613084 != nil:
    section.add "X-Amz-Date", valid_613084
  var valid_613085 = header.getOrDefault("X-Amz-Credential")
  valid_613085 = validateParameter(valid_613085, JString, required = false,
                                 default = nil)
  if valid_613085 != nil:
    section.add "X-Amz-Credential", valid_613085
  var valid_613086 = header.getOrDefault("X-Amz-Security-Token")
  valid_613086 = validateParameter(valid_613086, JString, required = false,
                                 default = nil)
  if valid_613086 != nil:
    section.add "X-Amz-Security-Token", valid_613086
  var valid_613087 = header.getOrDefault("X-Amz-Algorithm")
  valid_613087 = validateParameter(valid_613087, JString, required = false,
                                 default = nil)
  if valid_613087 != nil:
    section.add "X-Amz-Algorithm", valid_613087
  var valid_613088 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613088 = validateParameter(valid_613088, JString, required = false,
                                 default = nil)
  if valid_613088 != nil:
    section.add "X-Amz-SignedHeaders", valid_613088
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613090: Call_UpdateResourceDataSync_613078; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Update a resource data sync. After you create a resource data sync for a Region, you can't change the account options for that sync. For example, if you create a sync in the us-east-2 (Ohio) Region and you choose the Include only the current account option, you can't edit that sync later and choose the Include all accounts from my AWS Organizations configuration option. Instead, you must delete the first resource data sync, and create a new one.
  ## 
  let valid = call_613090.validator(path, query, header, formData, body)
  let scheme = call_613090.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613090.url(scheme.get, call_613090.host, call_613090.base,
                         call_613090.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613090, url, valid)

proc call*(call_613091: Call_UpdateResourceDataSync_613078; body: JsonNode): Recallable =
  ## updateResourceDataSync
  ## Update a resource data sync. After you create a resource data sync for a Region, you can't change the account options for that sync. For example, if you create a sync in the us-east-2 (Ohio) Region and you choose the Include only the current account option, you can't edit that sync later and choose the Include all accounts from my AWS Organizations configuration option. Instead, you must delete the first resource data sync, and create a new one.
  ##   body: JObject (required)
  var body_613092 = newJObject()
  if body != nil:
    body_613092 = body
  result = call_613091.call(nil, nil, nil, nil, body_613092)

var updateResourceDataSync* = Call_UpdateResourceDataSync_613078(
    name: "updateResourceDataSync", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.UpdateResourceDataSync",
    validator: validate_UpdateResourceDataSync_613079, base: "/",
    url: url_UpdateResourceDataSync_613080, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateServiceSetting_613093 = ref object of OpenApiRestCall_610658
proc url_UpdateServiceSetting_613095(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateServiceSetting_613094(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613096 = header.getOrDefault("X-Amz-Target")
  valid_613096 = validateParameter(valid_613096, JString, required = true, default = newJString(
      "AmazonSSM.UpdateServiceSetting"))
  if valid_613096 != nil:
    section.add "X-Amz-Target", valid_613096
  var valid_613097 = header.getOrDefault("X-Amz-Signature")
  valid_613097 = validateParameter(valid_613097, JString, required = false,
                                 default = nil)
  if valid_613097 != nil:
    section.add "X-Amz-Signature", valid_613097
  var valid_613098 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613098 = validateParameter(valid_613098, JString, required = false,
                                 default = nil)
  if valid_613098 != nil:
    section.add "X-Amz-Content-Sha256", valid_613098
  var valid_613099 = header.getOrDefault("X-Amz-Date")
  valid_613099 = validateParameter(valid_613099, JString, required = false,
                                 default = nil)
  if valid_613099 != nil:
    section.add "X-Amz-Date", valid_613099
  var valid_613100 = header.getOrDefault("X-Amz-Credential")
  valid_613100 = validateParameter(valid_613100, JString, required = false,
                                 default = nil)
  if valid_613100 != nil:
    section.add "X-Amz-Credential", valid_613100
  var valid_613101 = header.getOrDefault("X-Amz-Security-Token")
  valid_613101 = validateParameter(valid_613101, JString, required = false,
                                 default = nil)
  if valid_613101 != nil:
    section.add "X-Amz-Security-Token", valid_613101
  var valid_613102 = header.getOrDefault("X-Amz-Algorithm")
  valid_613102 = validateParameter(valid_613102, JString, required = false,
                                 default = nil)
  if valid_613102 != nil:
    section.add "X-Amz-Algorithm", valid_613102
  var valid_613103 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613103 = validateParameter(valid_613103, JString, required = false,
                                 default = nil)
  if valid_613103 != nil:
    section.add "X-Amz-SignedHeaders", valid_613103
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613105: Call_UpdateServiceSetting_613093; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> <code>ServiceSetting</code> is an account-level setting for an AWS service. This setting defines how a user interacts with or uses a service or a feature of a service. For example, if an AWS service charges money to the account based on feature or service usage, then the AWS service team might create a default setting of "false". This means the user can't use this feature unless they change the setting to "true" and intentionally opt in for a paid feature.</p> <p>Services map a <code>SettingId</code> object to a setting value. AWS services teams define the default value for a <code>SettingId</code>. You can't create a new <code>SettingId</code>, but you can overwrite the default value if you have the <code>ssm:UpdateServiceSetting</code> permission for the setting. Use the <a>GetServiceSetting</a> API action to view the current value. Or, use the <a>ResetServiceSetting</a> to change the value back to the original value defined by the AWS service team.</p> <p>Update the service setting for the account. </p>
  ## 
  let valid = call_613105.validator(path, query, header, formData, body)
  let scheme = call_613105.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613105.url(scheme.get, call_613105.host, call_613105.base,
                         call_613105.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613105, url, valid)

proc call*(call_613106: Call_UpdateServiceSetting_613093; body: JsonNode): Recallable =
  ## updateServiceSetting
  ## <p> <code>ServiceSetting</code> is an account-level setting for an AWS service. This setting defines how a user interacts with or uses a service or a feature of a service. For example, if an AWS service charges money to the account based on feature or service usage, then the AWS service team might create a default setting of "false". This means the user can't use this feature unless they change the setting to "true" and intentionally opt in for a paid feature.</p> <p>Services map a <code>SettingId</code> object to a setting value. AWS services teams define the default value for a <code>SettingId</code>. You can't create a new <code>SettingId</code>, but you can overwrite the default value if you have the <code>ssm:UpdateServiceSetting</code> permission for the setting. Use the <a>GetServiceSetting</a> API action to view the current value. Or, use the <a>ResetServiceSetting</a> to change the value back to the original value defined by the AWS service team.</p> <p>Update the service setting for the account. </p>
  ##   body: JObject (required)
  var body_613107 = newJObject()
  if body != nil:
    body_613107 = body
  result = call_613106.call(nil, nil, nil, nil, body_613107)

var updateServiceSetting* = Call_UpdateServiceSetting_613093(
    name: "updateServiceSetting", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.UpdateServiceSetting",
    validator: validate_UpdateServiceSetting_613094, base: "/",
    url: url_UpdateServiceSetting_613095, schemes: {Scheme.Https, Scheme.Http})
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

type
  XAmz = enum
    SecurityToken = "X-Amz-Security-Token", ContentSha256 = "X-Amz-Content-Sha256"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.} =
  ## the hook is a terrible earworm
  var headers = newHttpHeaders(massageHeaders(input.getOrDefault("header")))
  let
    body = input.getOrDefault("body")
    text = if body == nil:
      "" elif body.kind == JString:
      body.getStr else:
      $body
  if body != nil and body.kind != JString:
    if not headers.hasKey("content-type"):
      headers["content-type"] = "application/x-amz-json-1.0"
  if not headers.hasKey($SecurityToken):
    let session = getEnv("AWS_SESSION_TOKEN", "")
    if session != "":
      headers[$SecurityToken] = session
  headers[$ContentSha256] = hash(text, SHA256)
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)
