
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

  OpenApiRestCall_593437 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_593437](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_593437): Option[Scheme] {.used.} =
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
  Call_AddTagsToResource_593774 = ref object of OpenApiRestCall_593437
proc url_AddTagsToResource_593776(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_AddTagsToResource_593775(path: JsonNode; query: JsonNode;
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
  var valid_593888 = header.getOrDefault("X-Amz-Date")
  valid_593888 = validateParameter(valid_593888, JString, required = false,
                                 default = nil)
  if valid_593888 != nil:
    section.add "X-Amz-Date", valid_593888
  var valid_593889 = header.getOrDefault("X-Amz-Security-Token")
  valid_593889 = validateParameter(valid_593889, JString, required = false,
                                 default = nil)
  if valid_593889 != nil:
    section.add "X-Amz-Security-Token", valid_593889
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_593903 = header.getOrDefault("X-Amz-Target")
  valid_593903 = validateParameter(valid_593903, JString, required = true, default = newJString(
      "AmazonSSM.AddTagsToResource"))
  if valid_593903 != nil:
    section.add "X-Amz-Target", valid_593903
  var valid_593904 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593904 = validateParameter(valid_593904, JString, required = false,
                                 default = nil)
  if valid_593904 != nil:
    section.add "X-Amz-Content-Sha256", valid_593904
  var valid_593905 = header.getOrDefault("X-Amz-Algorithm")
  valid_593905 = validateParameter(valid_593905, JString, required = false,
                                 default = nil)
  if valid_593905 != nil:
    section.add "X-Amz-Algorithm", valid_593905
  var valid_593906 = header.getOrDefault("X-Amz-Signature")
  valid_593906 = validateParameter(valid_593906, JString, required = false,
                                 default = nil)
  if valid_593906 != nil:
    section.add "X-Amz-Signature", valid_593906
  var valid_593907 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593907 = validateParameter(valid_593907, JString, required = false,
                                 default = nil)
  if valid_593907 != nil:
    section.add "X-Amz-SignedHeaders", valid_593907
  var valid_593908 = header.getOrDefault("X-Amz-Credential")
  valid_593908 = validateParameter(valid_593908, JString, required = false,
                                 default = nil)
  if valid_593908 != nil:
    section.add "X-Amz-Credential", valid_593908
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593932: Call_AddTagsToResource_593774; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds or overwrites one or more tags for the specified resource. Tags are metadata that you can assign to your documents, managed instances, maintenance windows, Parameter Store parameters, and patch baselines. Tags enable you to categorize your resources in different ways, for example, by purpose, owner, or environment. Each tag consists of a key and an optional value, both of which you define. For example, you could define a set of tags for your account's managed instances that helps you track each instance's owner and stack level. For example: Key=Owner and Value=DbAdmin, SysAdmin, or Dev. Or Key=Stack and Value=Production, Pre-Production, or Test.</p> <p>Each resource can have a maximum of 50 tags. </p> <p>We recommend that you devise a set of tag keys that meets your needs for each resource type. Using a consistent set of tag keys makes it easier for you to manage your resources. You can search and filter the resources based on the tags you add. Tags don't have any semantic meaning to Amazon EC2 and are interpreted strictly as a string of characters. </p> <p>For more information about tags, see <a href="http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/Using_Tags.html">Tagging Your Amazon EC2 Resources</a> in the <i>Amazon EC2 User Guide</i>.</p>
  ## 
  let valid = call_593932.validator(path, query, header, formData, body)
  let scheme = call_593932.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593932.url(scheme.get, call_593932.host, call_593932.base,
                         call_593932.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593932, url, valid)

proc call*(call_594003: Call_AddTagsToResource_593774; body: JsonNode): Recallable =
  ## addTagsToResource
  ## <p>Adds or overwrites one or more tags for the specified resource. Tags are metadata that you can assign to your documents, managed instances, maintenance windows, Parameter Store parameters, and patch baselines. Tags enable you to categorize your resources in different ways, for example, by purpose, owner, or environment. Each tag consists of a key and an optional value, both of which you define. For example, you could define a set of tags for your account's managed instances that helps you track each instance's owner and stack level. For example: Key=Owner and Value=DbAdmin, SysAdmin, or Dev. Or Key=Stack and Value=Production, Pre-Production, or Test.</p> <p>Each resource can have a maximum of 50 tags. </p> <p>We recommend that you devise a set of tag keys that meets your needs for each resource type. Using a consistent set of tag keys makes it easier for you to manage your resources. You can search and filter the resources based on the tags you add. Tags don't have any semantic meaning to Amazon EC2 and are interpreted strictly as a string of characters. </p> <p>For more information about tags, see <a href="http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/Using_Tags.html">Tagging Your Amazon EC2 Resources</a> in the <i>Amazon EC2 User Guide</i>.</p>
  ##   body: JObject (required)
  var body_594004 = newJObject()
  if body != nil:
    body_594004 = body
  result = call_594003.call(nil, nil, nil, nil, body_594004)

var addTagsToResource* = Call_AddTagsToResource_593774(name: "addTagsToResource",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.AddTagsToResource",
    validator: validate_AddTagsToResource_593775, base: "/",
    url: url_AddTagsToResource_593776, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CancelCommand_594043 = ref object of OpenApiRestCall_593437
proc url_CancelCommand_594045(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CancelCommand_594044(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594046 = header.getOrDefault("X-Amz-Date")
  valid_594046 = validateParameter(valid_594046, JString, required = false,
                                 default = nil)
  if valid_594046 != nil:
    section.add "X-Amz-Date", valid_594046
  var valid_594047 = header.getOrDefault("X-Amz-Security-Token")
  valid_594047 = validateParameter(valid_594047, JString, required = false,
                                 default = nil)
  if valid_594047 != nil:
    section.add "X-Amz-Security-Token", valid_594047
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594048 = header.getOrDefault("X-Amz-Target")
  valid_594048 = validateParameter(valid_594048, JString, required = true, default = newJString(
      "AmazonSSM.CancelCommand"))
  if valid_594048 != nil:
    section.add "X-Amz-Target", valid_594048
  var valid_594049 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594049 = validateParameter(valid_594049, JString, required = false,
                                 default = nil)
  if valid_594049 != nil:
    section.add "X-Amz-Content-Sha256", valid_594049
  var valid_594050 = header.getOrDefault("X-Amz-Algorithm")
  valid_594050 = validateParameter(valid_594050, JString, required = false,
                                 default = nil)
  if valid_594050 != nil:
    section.add "X-Amz-Algorithm", valid_594050
  var valid_594051 = header.getOrDefault("X-Amz-Signature")
  valid_594051 = validateParameter(valid_594051, JString, required = false,
                                 default = nil)
  if valid_594051 != nil:
    section.add "X-Amz-Signature", valid_594051
  var valid_594052 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594052 = validateParameter(valid_594052, JString, required = false,
                                 default = nil)
  if valid_594052 != nil:
    section.add "X-Amz-SignedHeaders", valid_594052
  var valid_594053 = header.getOrDefault("X-Amz-Credential")
  valid_594053 = validateParameter(valid_594053, JString, required = false,
                                 default = nil)
  if valid_594053 != nil:
    section.add "X-Amz-Credential", valid_594053
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594055: Call_CancelCommand_594043; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Attempts to cancel the command specified by the Command ID. There is no guarantee that the command will be terminated and the underlying process stopped.
  ## 
  let valid = call_594055.validator(path, query, header, formData, body)
  let scheme = call_594055.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594055.url(scheme.get, call_594055.host, call_594055.base,
                         call_594055.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594055, url, valid)

proc call*(call_594056: Call_CancelCommand_594043; body: JsonNode): Recallable =
  ## cancelCommand
  ## Attempts to cancel the command specified by the Command ID. There is no guarantee that the command will be terminated and the underlying process stopped.
  ##   body: JObject (required)
  var body_594057 = newJObject()
  if body != nil:
    body_594057 = body
  result = call_594056.call(nil, nil, nil, nil, body_594057)

var cancelCommand* = Call_CancelCommand_594043(name: "cancelCommand",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.CancelCommand",
    validator: validate_CancelCommand_594044, base: "/", url: url_CancelCommand_594045,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CancelMaintenanceWindowExecution_594058 = ref object of OpenApiRestCall_593437
proc url_CancelMaintenanceWindowExecution_594060(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CancelMaintenanceWindowExecution_594059(path: JsonNode;
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
  var valid_594061 = header.getOrDefault("X-Amz-Date")
  valid_594061 = validateParameter(valid_594061, JString, required = false,
                                 default = nil)
  if valid_594061 != nil:
    section.add "X-Amz-Date", valid_594061
  var valid_594062 = header.getOrDefault("X-Amz-Security-Token")
  valid_594062 = validateParameter(valid_594062, JString, required = false,
                                 default = nil)
  if valid_594062 != nil:
    section.add "X-Amz-Security-Token", valid_594062
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594063 = header.getOrDefault("X-Amz-Target")
  valid_594063 = validateParameter(valid_594063, JString, required = true, default = newJString(
      "AmazonSSM.CancelMaintenanceWindowExecution"))
  if valid_594063 != nil:
    section.add "X-Amz-Target", valid_594063
  var valid_594064 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594064 = validateParameter(valid_594064, JString, required = false,
                                 default = nil)
  if valid_594064 != nil:
    section.add "X-Amz-Content-Sha256", valid_594064
  var valid_594065 = header.getOrDefault("X-Amz-Algorithm")
  valid_594065 = validateParameter(valid_594065, JString, required = false,
                                 default = nil)
  if valid_594065 != nil:
    section.add "X-Amz-Algorithm", valid_594065
  var valid_594066 = header.getOrDefault("X-Amz-Signature")
  valid_594066 = validateParameter(valid_594066, JString, required = false,
                                 default = nil)
  if valid_594066 != nil:
    section.add "X-Amz-Signature", valid_594066
  var valid_594067 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594067 = validateParameter(valid_594067, JString, required = false,
                                 default = nil)
  if valid_594067 != nil:
    section.add "X-Amz-SignedHeaders", valid_594067
  var valid_594068 = header.getOrDefault("X-Amz-Credential")
  valid_594068 = validateParameter(valid_594068, JString, required = false,
                                 default = nil)
  if valid_594068 != nil:
    section.add "X-Amz-Credential", valid_594068
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594070: Call_CancelMaintenanceWindowExecution_594058;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Stops a maintenance window execution that is already in progress and cancels any tasks in the window that have not already starting running. (Tasks already in progress will continue to completion.)
  ## 
  let valid = call_594070.validator(path, query, header, formData, body)
  let scheme = call_594070.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594070.url(scheme.get, call_594070.host, call_594070.base,
                         call_594070.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594070, url, valid)

proc call*(call_594071: Call_CancelMaintenanceWindowExecution_594058;
          body: JsonNode): Recallable =
  ## cancelMaintenanceWindowExecution
  ## Stops a maintenance window execution that is already in progress and cancels any tasks in the window that have not already starting running. (Tasks already in progress will continue to completion.)
  ##   body: JObject (required)
  var body_594072 = newJObject()
  if body != nil:
    body_594072 = body
  result = call_594071.call(nil, nil, nil, nil, body_594072)

var cancelMaintenanceWindowExecution* = Call_CancelMaintenanceWindowExecution_594058(
    name: "cancelMaintenanceWindowExecution", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.CancelMaintenanceWindowExecution",
    validator: validate_CancelMaintenanceWindowExecution_594059, base: "/",
    url: url_CancelMaintenanceWindowExecution_594060,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateActivation_594073 = ref object of OpenApiRestCall_593437
proc url_CreateActivation_594075(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateActivation_594074(path: JsonNode; query: JsonNode;
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
  var valid_594076 = header.getOrDefault("X-Amz-Date")
  valid_594076 = validateParameter(valid_594076, JString, required = false,
                                 default = nil)
  if valid_594076 != nil:
    section.add "X-Amz-Date", valid_594076
  var valid_594077 = header.getOrDefault("X-Amz-Security-Token")
  valid_594077 = validateParameter(valid_594077, JString, required = false,
                                 default = nil)
  if valid_594077 != nil:
    section.add "X-Amz-Security-Token", valid_594077
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594078 = header.getOrDefault("X-Amz-Target")
  valid_594078 = validateParameter(valid_594078, JString, required = true, default = newJString(
      "AmazonSSM.CreateActivation"))
  if valid_594078 != nil:
    section.add "X-Amz-Target", valid_594078
  var valid_594079 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594079 = validateParameter(valid_594079, JString, required = false,
                                 default = nil)
  if valid_594079 != nil:
    section.add "X-Amz-Content-Sha256", valid_594079
  var valid_594080 = header.getOrDefault("X-Amz-Algorithm")
  valid_594080 = validateParameter(valid_594080, JString, required = false,
                                 default = nil)
  if valid_594080 != nil:
    section.add "X-Amz-Algorithm", valid_594080
  var valid_594081 = header.getOrDefault("X-Amz-Signature")
  valid_594081 = validateParameter(valid_594081, JString, required = false,
                                 default = nil)
  if valid_594081 != nil:
    section.add "X-Amz-Signature", valid_594081
  var valid_594082 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594082 = validateParameter(valid_594082, JString, required = false,
                                 default = nil)
  if valid_594082 != nil:
    section.add "X-Amz-SignedHeaders", valid_594082
  var valid_594083 = header.getOrDefault("X-Amz-Credential")
  valid_594083 = validateParameter(valid_594083, JString, required = false,
                                 default = nil)
  if valid_594083 != nil:
    section.add "X-Amz-Credential", valid_594083
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594085: Call_CreateActivation_594073; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Registers your on-premises server or virtual machine with Amazon EC2 so that you can manage these resources using Run Command. An on-premises server or virtual machine that has been registered with EC2 is called a managed instance. For more information about activations, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-managedinstances.html">Setting Up AWS Systems Manager for Hybrid Environments</a>.
  ## 
  let valid = call_594085.validator(path, query, header, formData, body)
  let scheme = call_594085.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594085.url(scheme.get, call_594085.host, call_594085.base,
                         call_594085.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594085, url, valid)

proc call*(call_594086: Call_CreateActivation_594073; body: JsonNode): Recallable =
  ## createActivation
  ## Registers your on-premises server or virtual machine with Amazon EC2 so that you can manage these resources using Run Command. An on-premises server or virtual machine that has been registered with EC2 is called a managed instance. For more information about activations, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-managedinstances.html">Setting Up AWS Systems Manager for Hybrid Environments</a>.
  ##   body: JObject (required)
  var body_594087 = newJObject()
  if body != nil:
    body_594087 = body
  result = call_594086.call(nil, nil, nil, nil, body_594087)

var createActivation* = Call_CreateActivation_594073(name: "createActivation",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.CreateActivation",
    validator: validate_CreateActivation_594074, base: "/",
    url: url_CreateActivation_594075, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateAssociation_594088 = ref object of OpenApiRestCall_593437
proc url_CreateAssociation_594090(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateAssociation_594089(path: JsonNode; query: JsonNode;
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
  var valid_594091 = header.getOrDefault("X-Amz-Date")
  valid_594091 = validateParameter(valid_594091, JString, required = false,
                                 default = nil)
  if valid_594091 != nil:
    section.add "X-Amz-Date", valid_594091
  var valid_594092 = header.getOrDefault("X-Amz-Security-Token")
  valid_594092 = validateParameter(valid_594092, JString, required = false,
                                 default = nil)
  if valid_594092 != nil:
    section.add "X-Amz-Security-Token", valid_594092
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594093 = header.getOrDefault("X-Amz-Target")
  valid_594093 = validateParameter(valid_594093, JString, required = true, default = newJString(
      "AmazonSSM.CreateAssociation"))
  if valid_594093 != nil:
    section.add "X-Amz-Target", valid_594093
  var valid_594094 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594094 = validateParameter(valid_594094, JString, required = false,
                                 default = nil)
  if valid_594094 != nil:
    section.add "X-Amz-Content-Sha256", valid_594094
  var valid_594095 = header.getOrDefault("X-Amz-Algorithm")
  valid_594095 = validateParameter(valid_594095, JString, required = false,
                                 default = nil)
  if valid_594095 != nil:
    section.add "X-Amz-Algorithm", valid_594095
  var valid_594096 = header.getOrDefault("X-Amz-Signature")
  valid_594096 = validateParameter(valid_594096, JString, required = false,
                                 default = nil)
  if valid_594096 != nil:
    section.add "X-Amz-Signature", valid_594096
  var valid_594097 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594097 = validateParameter(valid_594097, JString, required = false,
                                 default = nil)
  if valid_594097 != nil:
    section.add "X-Amz-SignedHeaders", valid_594097
  var valid_594098 = header.getOrDefault("X-Amz-Credential")
  valid_594098 = validateParameter(valid_594098, JString, required = false,
                                 default = nil)
  if valid_594098 != nil:
    section.add "X-Amz-Credential", valid_594098
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594100: Call_CreateAssociation_594088; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Associates the specified Systems Manager document with the specified instances or targets.</p> <p>When you associate a document with one or more instances using instance IDs or tags, SSM Agent running on the instance processes the document and configures the instance as specified.</p> <p>If you associate a document with an instance that already has an associated document, the system returns the AssociationAlreadyExists exception.</p>
  ## 
  let valid = call_594100.validator(path, query, header, formData, body)
  let scheme = call_594100.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594100.url(scheme.get, call_594100.host, call_594100.base,
                         call_594100.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594100, url, valid)

proc call*(call_594101: Call_CreateAssociation_594088; body: JsonNode): Recallable =
  ## createAssociation
  ## <p>Associates the specified Systems Manager document with the specified instances or targets.</p> <p>When you associate a document with one or more instances using instance IDs or tags, SSM Agent running on the instance processes the document and configures the instance as specified.</p> <p>If you associate a document with an instance that already has an associated document, the system returns the AssociationAlreadyExists exception.</p>
  ##   body: JObject (required)
  var body_594102 = newJObject()
  if body != nil:
    body_594102 = body
  result = call_594101.call(nil, nil, nil, nil, body_594102)

var createAssociation* = Call_CreateAssociation_594088(name: "createAssociation",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.CreateAssociation",
    validator: validate_CreateAssociation_594089, base: "/",
    url: url_CreateAssociation_594090, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateAssociationBatch_594103 = ref object of OpenApiRestCall_593437
proc url_CreateAssociationBatch_594105(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateAssociationBatch_594104(path: JsonNode; query: JsonNode;
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
  var valid_594106 = header.getOrDefault("X-Amz-Date")
  valid_594106 = validateParameter(valid_594106, JString, required = false,
                                 default = nil)
  if valid_594106 != nil:
    section.add "X-Amz-Date", valid_594106
  var valid_594107 = header.getOrDefault("X-Amz-Security-Token")
  valid_594107 = validateParameter(valid_594107, JString, required = false,
                                 default = nil)
  if valid_594107 != nil:
    section.add "X-Amz-Security-Token", valid_594107
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594108 = header.getOrDefault("X-Amz-Target")
  valid_594108 = validateParameter(valid_594108, JString, required = true, default = newJString(
      "AmazonSSM.CreateAssociationBatch"))
  if valid_594108 != nil:
    section.add "X-Amz-Target", valid_594108
  var valid_594109 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594109 = validateParameter(valid_594109, JString, required = false,
                                 default = nil)
  if valid_594109 != nil:
    section.add "X-Amz-Content-Sha256", valid_594109
  var valid_594110 = header.getOrDefault("X-Amz-Algorithm")
  valid_594110 = validateParameter(valid_594110, JString, required = false,
                                 default = nil)
  if valid_594110 != nil:
    section.add "X-Amz-Algorithm", valid_594110
  var valid_594111 = header.getOrDefault("X-Amz-Signature")
  valid_594111 = validateParameter(valid_594111, JString, required = false,
                                 default = nil)
  if valid_594111 != nil:
    section.add "X-Amz-Signature", valid_594111
  var valid_594112 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594112 = validateParameter(valid_594112, JString, required = false,
                                 default = nil)
  if valid_594112 != nil:
    section.add "X-Amz-SignedHeaders", valid_594112
  var valid_594113 = header.getOrDefault("X-Amz-Credential")
  valid_594113 = validateParameter(valid_594113, JString, required = false,
                                 default = nil)
  if valid_594113 != nil:
    section.add "X-Amz-Credential", valid_594113
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594115: Call_CreateAssociationBatch_594103; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Associates the specified Systems Manager document with the specified instances or targets.</p> <p>When you associate a document with one or more instances using instance IDs or tags, SSM Agent running on the instance processes the document and configures the instance as specified.</p> <p>If you associate a document with an instance that already has an associated document, the system returns the AssociationAlreadyExists exception.</p>
  ## 
  let valid = call_594115.validator(path, query, header, formData, body)
  let scheme = call_594115.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594115.url(scheme.get, call_594115.host, call_594115.base,
                         call_594115.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594115, url, valid)

proc call*(call_594116: Call_CreateAssociationBatch_594103; body: JsonNode): Recallable =
  ## createAssociationBatch
  ## <p>Associates the specified Systems Manager document with the specified instances or targets.</p> <p>When you associate a document with one or more instances using instance IDs or tags, SSM Agent running on the instance processes the document and configures the instance as specified.</p> <p>If you associate a document with an instance that already has an associated document, the system returns the AssociationAlreadyExists exception.</p>
  ##   body: JObject (required)
  var body_594117 = newJObject()
  if body != nil:
    body_594117 = body
  result = call_594116.call(nil, nil, nil, nil, body_594117)

var createAssociationBatch* = Call_CreateAssociationBatch_594103(
    name: "createAssociationBatch", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.CreateAssociationBatch",
    validator: validate_CreateAssociationBatch_594104, base: "/",
    url: url_CreateAssociationBatch_594105, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDocument_594118 = ref object of OpenApiRestCall_593437
proc url_CreateDocument_594120(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateDocument_594119(path: JsonNode; query: JsonNode;
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
  var valid_594121 = header.getOrDefault("X-Amz-Date")
  valid_594121 = validateParameter(valid_594121, JString, required = false,
                                 default = nil)
  if valid_594121 != nil:
    section.add "X-Amz-Date", valid_594121
  var valid_594122 = header.getOrDefault("X-Amz-Security-Token")
  valid_594122 = validateParameter(valid_594122, JString, required = false,
                                 default = nil)
  if valid_594122 != nil:
    section.add "X-Amz-Security-Token", valid_594122
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594123 = header.getOrDefault("X-Amz-Target")
  valid_594123 = validateParameter(valid_594123, JString, required = true, default = newJString(
      "AmazonSSM.CreateDocument"))
  if valid_594123 != nil:
    section.add "X-Amz-Target", valid_594123
  var valid_594124 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594124 = validateParameter(valid_594124, JString, required = false,
                                 default = nil)
  if valid_594124 != nil:
    section.add "X-Amz-Content-Sha256", valid_594124
  var valid_594125 = header.getOrDefault("X-Amz-Algorithm")
  valid_594125 = validateParameter(valid_594125, JString, required = false,
                                 default = nil)
  if valid_594125 != nil:
    section.add "X-Amz-Algorithm", valid_594125
  var valid_594126 = header.getOrDefault("X-Amz-Signature")
  valid_594126 = validateParameter(valid_594126, JString, required = false,
                                 default = nil)
  if valid_594126 != nil:
    section.add "X-Amz-Signature", valid_594126
  var valid_594127 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594127 = validateParameter(valid_594127, JString, required = false,
                                 default = nil)
  if valid_594127 != nil:
    section.add "X-Amz-SignedHeaders", valid_594127
  var valid_594128 = header.getOrDefault("X-Amz-Credential")
  valid_594128 = validateParameter(valid_594128, JString, required = false,
                                 default = nil)
  if valid_594128 != nil:
    section.add "X-Amz-Credential", valid_594128
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594130: Call_CreateDocument_594118; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a Systems Manager document.</p> <p>After you create a document, you can use CreateAssociation to associate it with one or more running instances.</p>
  ## 
  let valid = call_594130.validator(path, query, header, formData, body)
  let scheme = call_594130.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594130.url(scheme.get, call_594130.host, call_594130.base,
                         call_594130.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594130, url, valid)

proc call*(call_594131: Call_CreateDocument_594118; body: JsonNode): Recallable =
  ## createDocument
  ## <p>Creates a Systems Manager document.</p> <p>After you create a document, you can use CreateAssociation to associate it with one or more running instances.</p>
  ##   body: JObject (required)
  var body_594132 = newJObject()
  if body != nil:
    body_594132 = body
  result = call_594131.call(nil, nil, nil, nil, body_594132)

var createDocument* = Call_CreateDocument_594118(name: "createDocument",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.CreateDocument",
    validator: validate_CreateDocument_594119, base: "/", url: url_CreateDocument_594120,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateMaintenanceWindow_594133 = ref object of OpenApiRestCall_593437
proc url_CreateMaintenanceWindow_594135(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateMaintenanceWindow_594134(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a new maintenance window.
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
  var valid_594136 = header.getOrDefault("X-Amz-Date")
  valid_594136 = validateParameter(valid_594136, JString, required = false,
                                 default = nil)
  if valid_594136 != nil:
    section.add "X-Amz-Date", valid_594136
  var valid_594137 = header.getOrDefault("X-Amz-Security-Token")
  valid_594137 = validateParameter(valid_594137, JString, required = false,
                                 default = nil)
  if valid_594137 != nil:
    section.add "X-Amz-Security-Token", valid_594137
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594138 = header.getOrDefault("X-Amz-Target")
  valid_594138 = validateParameter(valid_594138, JString, required = true, default = newJString(
      "AmazonSSM.CreateMaintenanceWindow"))
  if valid_594138 != nil:
    section.add "X-Amz-Target", valid_594138
  var valid_594139 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594139 = validateParameter(valid_594139, JString, required = false,
                                 default = nil)
  if valid_594139 != nil:
    section.add "X-Amz-Content-Sha256", valid_594139
  var valid_594140 = header.getOrDefault("X-Amz-Algorithm")
  valid_594140 = validateParameter(valid_594140, JString, required = false,
                                 default = nil)
  if valid_594140 != nil:
    section.add "X-Amz-Algorithm", valid_594140
  var valid_594141 = header.getOrDefault("X-Amz-Signature")
  valid_594141 = validateParameter(valid_594141, JString, required = false,
                                 default = nil)
  if valid_594141 != nil:
    section.add "X-Amz-Signature", valid_594141
  var valid_594142 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594142 = validateParameter(valid_594142, JString, required = false,
                                 default = nil)
  if valid_594142 != nil:
    section.add "X-Amz-SignedHeaders", valid_594142
  var valid_594143 = header.getOrDefault("X-Amz-Credential")
  valid_594143 = validateParameter(valid_594143, JString, required = false,
                                 default = nil)
  if valid_594143 != nil:
    section.add "X-Amz-Credential", valid_594143
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594145: Call_CreateMaintenanceWindow_594133; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new maintenance window.
  ## 
  let valid = call_594145.validator(path, query, header, formData, body)
  let scheme = call_594145.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594145.url(scheme.get, call_594145.host, call_594145.base,
                         call_594145.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594145, url, valid)

proc call*(call_594146: Call_CreateMaintenanceWindow_594133; body: JsonNode): Recallable =
  ## createMaintenanceWindow
  ## Creates a new maintenance window.
  ##   body: JObject (required)
  var body_594147 = newJObject()
  if body != nil:
    body_594147 = body
  result = call_594146.call(nil, nil, nil, nil, body_594147)

var createMaintenanceWindow* = Call_CreateMaintenanceWindow_594133(
    name: "createMaintenanceWindow", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.CreateMaintenanceWindow",
    validator: validate_CreateMaintenanceWindow_594134, base: "/",
    url: url_CreateMaintenanceWindow_594135, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateOpsItem_594148 = ref object of OpenApiRestCall_593437
proc url_CreateOpsItem_594150(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateOpsItem_594149(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594151 = header.getOrDefault("X-Amz-Date")
  valid_594151 = validateParameter(valid_594151, JString, required = false,
                                 default = nil)
  if valid_594151 != nil:
    section.add "X-Amz-Date", valid_594151
  var valid_594152 = header.getOrDefault("X-Amz-Security-Token")
  valid_594152 = validateParameter(valid_594152, JString, required = false,
                                 default = nil)
  if valid_594152 != nil:
    section.add "X-Amz-Security-Token", valid_594152
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594153 = header.getOrDefault("X-Amz-Target")
  valid_594153 = validateParameter(valid_594153, JString, required = true, default = newJString(
      "AmazonSSM.CreateOpsItem"))
  if valid_594153 != nil:
    section.add "X-Amz-Target", valid_594153
  var valid_594154 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594154 = validateParameter(valid_594154, JString, required = false,
                                 default = nil)
  if valid_594154 != nil:
    section.add "X-Amz-Content-Sha256", valid_594154
  var valid_594155 = header.getOrDefault("X-Amz-Algorithm")
  valid_594155 = validateParameter(valid_594155, JString, required = false,
                                 default = nil)
  if valid_594155 != nil:
    section.add "X-Amz-Algorithm", valid_594155
  var valid_594156 = header.getOrDefault("X-Amz-Signature")
  valid_594156 = validateParameter(valid_594156, JString, required = false,
                                 default = nil)
  if valid_594156 != nil:
    section.add "X-Amz-Signature", valid_594156
  var valid_594157 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594157 = validateParameter(valid_594157, JString, required = false,
                                 default = nil)
  if valid_594157 != nil:
    section.add "X-Amz-SignedHeaders", valid_594157
  var valid_594158 = header.getOrDefault("X-Amz-Credential")
  valid_594158 = validateParameter(valid_594158, JString, required = false,
                                 default = nil)
  if valid_594158 != nil:
    section.add "X-Amz-Credential", valid_594158
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594160: Call_CreateOpsItem_594148; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a new OpsItem. You must have permission in AWS Identity and Access Management (IAM) to create a new OpsItem. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter-getting-started.html">Getting Started with OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>.</p> <p>Operations engineers and IT professionals use OpsCenter to view, investigate, and remediate operational issues impacting the performance and health of their AWS resources. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter.html">AWS Systems Manager OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>. </p>
  ## 
  let valid = call_594160.validator(path, query, header, formData, body)
  let scheme = call_594160.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594160.url(scheme.get, call_594160.host, call_594160.base,
                         call_594160.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594160, url, valid)

proc call*(call_594161: Call_CreateOpsItem_594148; body: JsonNode): Recallable =
  ## createOpsItem
  ## <p>Creates a new OpsItem. You must have permission in AWS Identity and Access Management (IAM) to create a new OpsItem. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter-getting-started.html">Getting Started with OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>.</p> <p>Operations engineers and IT professionals use OpsCenter to view, investigate, and remediate operational issues impacting the performance and health of their AWS resources. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter.html">AWS Systems Manager OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>. </p>
  ##   body: JObject (required)
  var body_594162 = newJObject()
  if body != nil:
    body_594162 = body
  result = call_594161.call(nil, nil, nil, nil, body_594162)

var createOpsItem* = Call_CreateOpsItem_594148(name: "createOpsItem",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.CreateOpsItem",
    validator: validate_CreateOpsItem_594149, base: "/", url: url_CreateOpsItem_594150,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePatchBaseline_594163 = ref object of OpenApiRestCall_593437
proc url_CreatePatchBaseline_594165(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreatePatchBaseline_594164(path: JsonNode; query: JsonNode;
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
  var valid_594166 = header.getOrDefault("X-Amz-Date")
  valid_594166 = validateParameter(valid_594166, JString, required = false,
                                 default = nil)
  if valid_594166 != nil:
    section.add "X-Amz-Date", valid_594166
  var valid_594167 = header.getOrDefault("X-Amz-Security-Token")
  valid_594167 = validateParameter(valid_594167, JString, required = false,
                                 default = nil)
  if valid_594167 != nil:
    section.add "X-Amz-Security-Token", valid_594167
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594168 = header.getOrDefault("X-Amz-Target")
  valid_594168 = validateParameter(valid_594168, JString, required = true, default = newJString(
      "AmazonSSM.CreatePatchBaseline"))
  if valid_594168 != nil:
    section.add "X-Amz-Target", valid_594168
  var valid_594169 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594169 = validateParameter(valid_594169, JString, required = false,
                                 default = nil)
  if valid_594169 != nil:
    section.add "X-Amz-Content-Sha256", valid_594169
  var valid_594170 = header.getOrDefault("X-Amz-Algorithm")
  valid_594170 = validateParameter(valid_594170, JString, required = false,
                                 default = nil)
  if valid_594170 != nil:
    section.add "X-Amz-Algorithm", valid_594170
  var valid_594171 = header.getOrDefault("X-Amz-Signature")
  valid_594171 = validateParameter(valid_594171, JString, required = false,
                                 default = nil)
  if valid_594171 != nil:
    section.add "X-Amz-Signature", valid_594171
  var valid_594172 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594172 = validateParameter(valid_594172, JString, required = false,
                                 default = nil)
  if valid_594172 != nil:
    section.add "X-Amz-SignedHeaders", valid_594172
  var valid_594173 = header.getOrDefault("X-Amz-Credential")
  valid_594173 = validateParameter(valid_594173, JString, required = false,
                                 default = nil)
  if valid_594173 != nil:
    section.add "X-Amz-Credential", valid_594173
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594175: Call_CreatePatchBaseline_594163; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a patch baseline.</p> <note> <p>For information about valid key and value pairs in <code>PatchFilters</code> for each supported operating system type, see <a href="http://docs.aws.amazon.com/systems-manager/latest/APIReference/API_PatchFilter.html">PatchFilter</a>.</p> </note>
  ## 
  let valid = call_594175.validator(path, query, header, formData, body)
  let scheme = call_594175.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594175.url(scheme.get, call_594175.host, call_594175.base,
                         call_594175.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594175, url, valid)

proc call*(call_594176: Call_CreatePatchBaseline_594163; body: JsonNode): Recallable =
  ## createPatchBaseline
  ## <p>Creates a patch baseline.</p> <note> <p>For information about valid key and value pairs in <code>PatchFilters</code> for each supported operating system type, see <a href="http://docs.aws.amazon.com/systems-manager/latest/APIReference/API_PatchFilter.html">PatchFilter</a>.</p> </note>
  ##   body: JObject (required)
  var body_594177 = newJObject()
  if body != nil:
    body_594177 = body
  result = call_594176.call(nil, nil, nil, nil, body_594177)

var createPatchBaseline* = Call_CreatePatchBaseline_594163(
    name: "createPatchBaseline", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.CreatePatchBaseline",
    validator: validate_CreatePatchBaseline_594164, base: "/",
    url: url_CreatePatchBaseline_594165, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateResourceDataSync_594178 = ref object of OpenApiRestCall_593437
proc url_CreateResourceDataSync_594180(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateResourceDataSync_594179(path: JsonNode; query: JsonNode;
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
  var valid_594181 = header.getOrDefault("X-Amz-Date")
  valid_594181 = validateParameter(valid_594181, JString, required = false,
                                 default = nil)
  if valid_594181 != nil:
    section.add "X-Amz-Date", valid_594181
  var valid_594182 = header.getOrDefault("X-Amz-Security-Token")
  valid_594182 = validateParameter(valid_594182, JString, required = false,
                                 default = nil)
  if valid_594182 != nil:
    section.add "X-Amz-Security-Token", valid_594182
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594183 = header.getOrDefault("X-Amz-Target")
  valid_594183 = validateParameter(valid_594183, JString, required = true, default = newJString(
      "AmazonSSM.CreateResourceDataSync"))
  if valid_594183 != nil:
    section.add "X-Amz-Target", valid_594183
  var valid_594184 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594184 = validateParameter(valid_594184, JString, required = false,
                                 default = nil)
  if valid_594184 != nil:
    section.add "X-Amz-Content-Sha256", valid_594184
  var valid_594185 = header.getOrDefault("X-Amz-Algorithm")
  valid_594185 = validateParameter(valid_594185, JString, required = false,
                                 default = nil)
  if valid_594185 != nil:
    section.add "X-Amz-Algorithm", valid_594185
  var valid_594186 = header.getOrDefault("X-Amz-Signature")
  valid_594186 = validateParameter(valid_594186, JString, required = false,
                                 default = nil)
  if valid_594186 != nil:
    section.add "X-Amz-Signature", valid_594186
  var valid_594187 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594187 = validateParameter(valid_594187, JString, required = false,
                                 default = nil)
  if valid_594187 != nil:
    section.add "X-Amz-SignedHeaders", valid_594187
  var valid_594188 = header.getOrDefault("X-Amz-Credential")
  valid_594188 = validateParameter(valid_594188, JString, required = false,
                                 default = nil)
  if valid_594188 != nil:
    section.add "X-Amz-Credential", valid_594188
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594190: Call_CreateResourceDataSync_594178; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a resource data sync configuration to a single bucket in Amazon S3. This is an asynchronous operation that returns immediately. After a successful initial sync is completed, the system continuously syncs data to the Amazon S3 bucket. To check the status of the sync, use the <a>ListResourceDataSync</a>.</p> <p>By default, data is not encrypted in Amazon S3. We strongly recommend that you enable encryption in Amazon S3 to ensure secure data storage. We also recommend that you secure access to the Amazon S3 bucket by creating a restrictive bucket policy. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/sysman-inventory-datasync.html">Configuring Resource Data Sync for Inventory</a> in the <i>AWS Systems Manager User Guide</i>.</p>
  ## 
  let valid = call_594190.validator(path, query, header, formData, body)
  let scheme = call_594190.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594190.url(scheme.get, call_594190.host, call_594190.base,
                         call_594190.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594190, url, valid)

proc call*(call_594191: Call_CreateResourceDataSync_594178; body: JsonNode): Recallable =
  ## createResourceDataSync
  ## <p>Creates a resource data sync configuration to a single bucket in Amazon S3. This is an asynchronous operation that returns immediately. After a successful initial sync is completed, the system continuously syncs data to the Amazon S3 bucket. To check the status of the sync, use the <a>ListResourceDataSync</a>.</p> <p>By default, data is not encrypted in Amazon S3. We strongly recommend that you enable encryption in Amazon S3 to ensure secure data storage. We also recommend that you secure access to the Amazon S3 bucket by creating a restrictive bucket policy. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/sysman-inventory-datasync.html">Configuring Resource Data Sync for Inventory</a> in the <i>AWS Systems Manager User Guide</i>.</p>
  ##   body: JObject (required)
  var body_594192 = newJObject()
  if body != nil:
    body_594192 = body
  result = call_594191.call(nil, nil, nil, nil, body_594192)

var createResourceDataSync* = Call_CreateResourceDataSync_594178(
    name: "createResourceDataSync", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.CreateResourceDataSync",
    validator: validate_CreateResourceDataSync_594179, base: "/",
    url: url_CreateResourceDataSync_594180, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteActivation_594193 = ref object of OpenApiRestCall_593437
proc url_DeleteActivation_594195(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteActivation_594194(path: JsonNode; query: JsonNode;
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
  var valid_594196 = header.getOrDefault("X-Amz-Date")
  valid_594196 = validateParameter(valid_594196, JString, required = false,
                                 default = nil)
  if valid_594196 != nil:
    section.add "X-Amz-Date", valid_594196
  var valid_594197 = header.getOrDefault("X-Amz-Security-Token")
  valid_594197 = validateParameter(valid_594197, JString, required = false,
                                 default = nil)
  if valid_594197 != nil:
    section.add "X-Amz-Security-Token", valid_594197
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594198 = header.getOrDefault("X-Amz-Target")
  valid_594198 = validateParameter(valid_594198, JString, required = true, default = newJString(
      "AmazonSSM.DeleteActivation"))
  if valid_594198 != nil:
    section.add "X-Amz-Target", valid_594198
  var valid_594199 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594199 = validateParameter(valid_594199, JString, required = false,
                                 default = nil)
  if valid_594199 != nil:
    section.add "X-Amz-Content-Sha256", valid_594199
  var valid_594200 = header.getOrDefault("X-Amz-Algorithm")
  valid_594200 = validateParameter(valid_594200, JString, required = false,
                                 default = nil)
  if valid_594200 != nil:
    section.add "X-Amz-Algorithm", valid_594200
  var valid_594201 = header.getOrDefault("X-Amz-Signature")
  valid_594201 = validateParameter(valid_594201, JString, required = false,
                                 default = nil)
  if valid_594201 != nil:
    section.add "X-Amz-Signature", valid_594201
  var valid_594202 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594202 = validateParameter(valid_594202, JString, required = false,
                                 default = nil)
  if valid_594202 != nil:
    section.add "X-Amz-SignedHeaders", valid_594202
  var valid_594203 = header.getOrDefault("X-Amz-Credential")
  valid_594203 = validateParameter(valid_594203, JString, required = false,
                                 default = nil)
  if valid_594203 != nil:
    section.add "X-Amz-Credential", valid_594203
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594205: Call_DeleteActivation_594193; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an activation. You are not required to delete an activation. If you delete an activation, you can no longer use it to register additional managed instances. Deleting an activation does not de-register managed instances. You must manually de-register managed instances.
  ## 
  let valid = call_594205.validator(path, query, header, formData, body)
  let scheme = call_594205.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594205.url(scheme.get, call_594205.host, call_594205.base,
                         call_594205.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594205, url, valid)

proc call*(call_594206: Call_DeleteActivation_594193; body: JsonNode): Recallable =
  ## deleteActivation
  ## Deletes an activation. You are not required to delete an activation. If you delete an activation, you can no longer use it to register additional managed instances. Deleting an activation does not de-register managed instances. You must manually de-register managed instances.
  ##   body: JObject (required)
  var body_594207 = newJObject()
  if body != nil:
    body_594207 = body
  result = call_594206.call(nil, nil, nil, nil, body_594207)

var deleteActivation* = Call_DeleteActivation_594193(name: "deleteActivation",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DeleteActivation",
    validator: validate_DeleteActivation_594194, base: "/",
    url: url_DeleteActivation_594195, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAssociation_594208 = ref object of OpenApiRestCall_593437
proc url_DeleteAssociation_594210(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteAssociation_594209(path: JsonNode; query: JsonNode;
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
  var valid_594211 = header.getOrDefault("X-Amz-Date")
  valid_594211 = validateParameter(valid_594211, JString, required = false,
                                 default = nil)
  if valid_594211 != nil:
    section.add "X-Amz-Date", valid_594211
  var valid_594212 = header.getOrDefault("X-Amz-Security-Token")
  valid_594212 = validateParameter(valid_594212, JString, required = false,
                                 default = nil)
  if valid_594212 != nil:
    section.add "X-Amz-Security-Token", valid_594212
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594213 = header.getOrDefault("X-Amz-Target")
  valid_594213 = validateParameter(valid_594213, JString, required = true, default = newJString(
      "AmazonSSM.DeleteAssociation"))
  if valid_594213 != nil:
    section.add "X-Amz-Target", valid_594213
  var valid_594214 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594214 = validateParameter(valid_594214, JString, required = false,
                                 default = nil)
  if valid_594214 != nil:
    section.add "X-Amz-Content-Sha256", valid_594214
  var valid_594215 = header.getOrDefault("X-Amz-Algorithm")
  valid_594215 = validateParameter(valid_594215, JString, required = false,
                                 default = nil)
  if valid_594215 != nil:
    section.add "X-Amz-Algorithm", valid_594215
  var valid_594216 = header.getOrDefault("X-Amz-Signature")
  valid_594216 = validateParameter(valid_594216, JString, required = false,
                                 default = nil)
  if valid_594216 != nil:
    section.add "X-Amz-Signature", valid_594216
  var valid_594217 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594217 = validateParameter(valid_594217, JString, required = false,
                                 default = nil)
  if valid_594217 != nil:
    section.add "X-Amz-SignedHeaders", valid_594217
  var valid_594218 = header.getOrDefault("X-Amz-Credential")
  valid_594218 = validateParameter(valid_594218, JString, required = false,
                                 default = nil)
  if valid_594218 != nil:
    section.add "X-Amz-Credential", valid_594218
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594220: Call_DeleteAssociation_594208; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Disassociates the specified Systems Manager document from the specified instance.</p> <p>When you disassociate a document from an instance, it does not change the configuration of the instance. To change the configuration state of an instance after you disassociate a document, you must create a new document with the desired configuration and associate it with the instance.</p>
  ## 
  let valid = call_594220.validator(path, query, header, formData, body)
  let scheme = call_594220.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594220.url(scheme.get, call_594220.host, call_594220.base,
                         call_594220.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594220, url, valid)

proc call*(call_594221: Call_DeleteAssociation_594208; body: JsonNode): Recallable =
  ## deleteAssociation
  ## <p>Disassociates the specified Systems Manager document from the specified instance.</p> <p>When you disassociate a document from an instance, it does not change the configuration of the instance. To change the configuration state of an instance after you disassociate a document, you must create a new document with the desired configuration and associate it with the instance.</p>
  ##   body: JObject (required)
  var body_594222 = newJObject()
  if body != nil:
    body_594222 = body
  result = call_594221.call(nil, nil, nil, nil, body_594222)

var deleteAssociation* = Call_DeleteAssociation_594208(name: "deleteAssociation",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DeleteAssociation",
    validator: validate_DeleteAssociation_594209, base: "/",
    url: url_DeleteAssociation_594210, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDocument_594223 = ref object of OpenApiRestCall_593437
proc url_DeleteDocument_594225(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteDocument_594224(path: JsonNode; query: JsonNode;
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
  var valid_594226 = header.getOrDefault("X-Amz-Date")
  valid_594226 = validateParameter(valid_594226, JString, required = false,
                                 default = nil)
  if valid_594226 != nil:
    section.add "X-Amz-Date", valid_594226
  var valid_594227 = header.getOrDefault("X-Amz-Security-Token")
  valid_594227 = validateParameter(valid_594227, JString, required = false,
                                 default = nil)
  if valid_594227 != nil:
    section.add "X-Amz-Security-Token", valid_594227
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594228 = header.getOrDefault("X-Amz-Target")
  valid_594228 = validateParameter(valid_594228, JString, required = true, default = newJString(
      "AmazonSSM.DeleteDocument"))
  if valid_594228 != nil:
    section.add "X-Amz-Target", valid_594228
  var valid_594229 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594229 = validateParameter(valid_594229, JString, required = false,
                                 default = nil)
  if valid_594229 != nil:
    section.add "X-Amz-Content-Sha256", valid_594229
  var valid_594230 = header.getOrDefault("X-Amz-Algorithm")
  valid_594230 = validateParameter(valid_594230, JString, required = false,
                                 default = nil)
  if valid_594230 != nil:
    section.add "X-Amz-Algorithm", valid_594230
  var valid_594231 = header.getOrDefault("X-Amz-Signature")
  valid_594231 = validateParameter(valid_594231, JString, required = false,
                                 default = nil)
  if valid_594231 != nil:
    section.add "X-Amz-Signature", valid_594231
  var valid_594232 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594232 = validateParameter(valid_594232, JString, required = false,
                                 default = nil)
  if valid_594232 != nil:
    section.add "X-Amz-SignedHeaders", valid_594232
  var valid_594233 = header.getOrDefault("X-Amz-Credential")
  valid_594233 = validateParameter(valid_594233, JString, required = false,
                                 default = nil)
  if valid_594233 != nil:
    section.add "X-Amz-Credential", valid_594233
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594235: Call_DeleteDocument_594223; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the Systems Manager document and all instance associations to the document.</p> <p>Before you delete the document, we recommend that you use <a>DeleteAssociation</a> to disassociate all instances that are associated with the document.</p>
  ## 
  let valid = call_594235.validator(path, query, header, formData, body)
  let scheme = call_594235.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594235.url(scheme.get, call_594235.host, call_594235.base,
                         call_594235.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594235, url, valid)

proc call*(call_594236: Call_DeleteDocument_594223; body: JsonNode): Recallable =
  ## deleteDocument
  ## <p>Deletes the Systems Manager document and all instance associations to the document.</p> <p>Before you delete the document, we recommend that you use <a>DeleteAssociation</a> to disassociate all instances that are associated with the document.</p>
  ##   body: JObject (required)
  var body_594237 = newJObject()
  if body != nil:
    body_594237 = body
  result = call_594236.call(nil, nil, nil, nil, body_594237)

var deleteDocument* = Call_DeleteDocument_594223(name: "deleteDocument",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DeleteDocument",
    validator: validate_DeleteDocument_594224, base: "/", url: url_DeleteDocument_594225,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteInventory_594238 = ref object of OpenApiRestCall_593437
proc url_DeleteInventory_594240(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteInventory_594239(path: JsonNode; query: JsonNode;
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
  var valid_594241 = header.getOrDefault("X-Amz-Date")
  valid_594241 = validateParameter(valid_594241, JString, required = false,
                                 default = nil)
  if valid_594241 != nil:
    section.add "X-Amz-Date", valid_594241
  var valid_594242 = header.getOrDefault("X-Amz-Security-Token")
  valid_594242 = validateParameter(valid_594242, JString, required = false,
                                 default = nil)
  if valid_594242 != nil:
    section.add "X-Amz-Security-Token", valid_594242
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594243 = header.getOrDefault("X-Amz-Target")
  valid_594243 = validateParameter(valid_594243, JString, required = true, default = newJString(
      "AmazonSSM.DeleteInventory"))
  if valid_594243 != nil:
    section.add "X-Amz-Target", valid_594243
  var valid_594244 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594244 = validateParameter(valid_594244, JString, required = false,
                                 default = nil)
  if valid_594244 != nil:
    section.add "X-Amz-Content-Sha256", valid_594244
  var valid_594245 = header.getOrDefault("X-Amz-Algorithm")
  valid_594245 = validateParameter(valid_594245, JString, required = false,
                                 default = nil)
  if valid_594245 != nil:
    section.add "X-Amz-Algorithm", valid_594245
  var valid_594246 = header.getOrDefault("X-Amz-Signature")
  valid_594246 = validateParameter(valid_594246, JString, required = false,
                                 default = nil)
  if valid_594246 != nil:
    section.add "X-Amz-Signature", valid_594246
  var valid_594247 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594247 = validateParameter(valid_594247, JString, required = false,
                                 default = nil)
  if valid_594247 != nil:
    section.add "X-Amz-SignedHeaders", valid_594247
  var valid_594248 = header.getOrDefault("X-Amz-Credential")
  valid_594248 = validateParameter(valid_594248, JString, required = false,
                                 default = nil)
  if valid_594248 != nil:
    section.add "X-Amz-Credential", valid_594248
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594250: Call_DeleteInventory_594238; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Delete a custom inventory type, or the data associated with a custom Inventory type. Deleting a custom inventory type is also referred to as deleting a custom inventory schema.
  ## 
  let valid = call_594250.validator(path, query, header, formData, body)
  let scheme = call_594250.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594250.url(scheme.get, call_594250.host, call_594250.base,
                         call_594250.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594250, url, valid)

proc call*(call_594251: Call_DeleteInventory_594238; body: JsonNode): Recallable =
  ## deleteInventory
  ## Delete a custom inventory type, or the data associated with a custom Inventory type. Deleting a custom inventory type is also referred to as deleting a custom inventory schema.
  ##   body: JObject (required)
  var body_594252 = newJObject()
  if body != nil:
    body_594252 = body
  result = call_594251.call(nil, nil, nil, nil, body_594252)

var deleteInventory* = Call_DeleteInventory_594238(name: "deleteInventory",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DeleteInventory",
    validator: validate_DeleteInventory_594239, base: "/", url: url_DeleteInventory_594240,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteMaintenanceWindow_594253 = ref object of OpenApiRestCall_593437
proc url_DeleteMaintenanceWindow_594255(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteMaintenanceWindow_594254(path: JsonNode; query: JsonNode;
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
  var valid_594256 = header.getOrDefault("X-Amz-Date")
  valid_594256 = validateParameter(valid_594256, JString, required = false,
                                 default = nil)
  if valid_594256 != nil:
    section.add "X-Amz-Date", valid_594256
  var valid_594257 = header.getOrDefault("X-Amz-Security-Token")
  valid_594257 = validateParameter(valid_594257, JString, required = false,
                                 default = nil)
  if valid_594257 != nil:
    section.add "X-Amz-Security-Token", valid_594257
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594258 = header.getOrDefault("X-Amz-Target")
  valid_594258 = validateParameter(valid_594258, JString, required = true, default = newJString(
      "AmazonSSM.DeleteMaintenanceWindow"))
  if valid_594258 != nil:
    section.add "X-Amz-Target", valid_594258
  var valid_594259 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594259 = validateParameter(valid_594259, JString, required = false,
                                 default = nil)
  if valid_594259 != nil:
    section.add "X-Amz-Content-Sha256", valid_594259
  var valid_594260 = header.getOrDefault("X-Amz-Algorithm")
  valid_594260 = validateParameter(valid_594260, JString, required = false,
                                 default = nil)
  if valid_594260 != nil:
    section.add "X-Amz-Algorithm", valid_594260
  var valid_594261 = header.getOrDefault("X-Amz-Signature")
  valid_594261 = validateParameter(valid_594261, JString, required = false,
                                 default = nil)
  if valid_594261 != nil:
    section.add "X-Amz-Signature", valid_594261
  var valid_594262 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594262 = validateParameter(valid_594262, JString, required = false,
                                 default = nil)
  if valid_594262 != nil:
    section.add "X-Amz-SignedHeaders", valid_594262
  var valid_594263 = header.getOrDefault("X-Amz-Credential")
  valid_594263 = validateParameter(valid_594263, JString, required = false,
                                 default = nil)
  if valid_594263 != nil:
    section.add "X-Amz-Credential", valid_594263
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594265: Call_DeleteMaintenanceWindow_594253; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a maintenance window.
  ## 
  let valid = call_594265.validator(path, query, header, formData, body)
  let scheme = call_594265.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594265.url(scheme.get, call_594265.host, call_594265.base,
                         call_594265.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594265, url, valid)

proc call*(call_594266: Call_DeleteMaintenanceWindow_594253; body: JsonNode): Recallable =
  ## deleteMaintenanceWindow
  ## Deletes a maintenance window.
  ##   body: JObject (required)
  var body_594267 = newJObject()
  if body != nil:
    body_594267 = body
  result = call_594266.call(nil, nil, nil, nil, body_594267)

var deleteMaintenanceWindow* = Call_DeleteMaintenanceWindow_594253(
    name: "deleteMaintenanceWindow", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DeleteMaintenanceWindow",
    validator: validate_DeleteMaintenanceWindow_594254, base: "/",
    url: url_DeleteMaintenanceWindow_594255, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteParameter_594268 = ref object of OpenApiRestCall_593437
proc url_DeleteParameter_594270(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteParameter_594269(path: JsonNode; query: JsonNode;
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
  var valid_594271 = header.getOrDefault("X-Amz-Date")
  valid_594271 = validateParameter(valid_594271, JString, required = false,
                                 default = nil)
  if valid_594271 != nil:
    section.add "X-Amz-Date", valid_594271
  var valid_594272 = header.getOrDefault("X-Amz-Security-Token")
  valid_594272 = validateParameter(valid_594272, JString, required = false,
                                 default = nil)
  if valid_594272 != nil:
    section.add "X-Amz-Security-Token", valid_594272
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594273 = header.getOrDefault("X-Amz-Target")
  valid_594273 = validateParameter(valid_594273, JString, required = true, default = newJString(
      "AmazonSSM.DeleteParameter"))
  if valid_594273 != nil:
    section.add "X-Amz-Target", valid_594273
  var valid_594274 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594274 = validateParameter(valid_594274, JString, required = false,
                                 default = nil)
  if valid_594274 != nil:
    section.add "X-Amz-Content-Sha256", valid_594274
  var valid_594275 = header.getOrDefault("X-Amz-Algorithm")
  valid_594275 = validateParameter(valid_594275, JString, required = false,
                                 default = nil)
  if valid_594275 != nil:
    section.add "X-Amz-Algorithm", valid_594275
  var valid_594276 = header.getOrDefault("X-Amz-Signature")
  valid_594276 = validateParameter(valid_594276, JString, required = false,
                                 default = nil)
  if valid_594276 != nil:
    section.add "X-Amz-Signature", valid_594276
  var valid_594277 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594277 = validateParameter(valid_594277, JString, required = false,
                                 default = nil)
  if valid_594277 != nil:
    section.add "X-Amz-SignedHeaders", valid_594277
  var valid_594278 = header.getOrDefault("X-Amz-Credential")
  valid_594278 = validateParameter(valid_594278, JString, required = false,
                                 default = nil)
  if valid_594278 != nil:
    section.add "X-Amz-Credential", valid_594278
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594280: Call_DeleteParameter_594268; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Delete a parameter from the system.
  ## 
  let valid = call_594280.validator(path, query, header, formData, body)
  let scheme = call_594280.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594280.url(scheme.get, call_594280.host, call_594280.base,
                         call_594280.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594280, url, valid)

proc call*(call_594281: Call_DeleteParameter_594268; body: JsonNode): Recallable =
  ## deleteParameter
  ## Delete a parameter from the system.
  ##   body: JObject (required)
  var body_594282 = newJObject()
  if body != nil:
    body_594282 = body
  result = call_594281.call(nil, nil, nil, nil, body_594282)

var deleteParameter* = Call_DeleteParameter_594268(name: "deleteParameter",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DeleteParameter",
    validator: validate_DeleteParameter_594269, base: "/", url: url_DeleteParameter_594270,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteParameters_594283 = ref object of OpenApiRestCall_593437
proc url_DeleteParameters_594285(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteParameters_594284(path: JsonNode; query: JsonNode;
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
  var valid_594286 = header.getOrDefault("X-Amz-Date")
  valid_594286 = validateParameter(valid_594286, JString, required = false,
                                 default = nil)
  if valid_594286 != nil:
    section.add "X-Amz-Date", valid_594286
  var valid_594287 = header.getOrDefault("X-Amz-Security-Token")
  valid_594287 = validateParameter(valid_594287, JString, required = false,
                                 default = nil)
  if valid_594287 != nil:
    section.add "X-Amz-Security-Token", valid_594287
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594288 = header.getOrDefault("X-Amz-Target")
  valid_594288 = validateParameter(valid_594288, JString, required = true, default = newJString(
      "AmazonSSM.DeleteParameters"))
  if valid_594288 != nil:
    section.add "X-Amz-Target", valid_594288
  var valid_594289 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594289 = validateParameter(valid_594289, JString, required = false,
                                 default = nil)
  if valid_594289 != nil:
    section.add "X-Amz-Content-Sha256", valid_594289
  var valid_594290 = header.getOrDefault("X-Amz-Algorithm")
  valid_594290 = validateParameter(valid_594290, JString, required = false,
                                 default = nil)
  if valid_594290 != nil:
    section.add "X-Amz-Algorithm", valid_594290
  var valid_594291 = header.getOrDefault("X-Amz-Signature")
  valid_594291 = validateParameter(valid_594291, JString, required = false,
                                 default = nil)
  if valid_594291 != nil:
    section.add "X-Amz-Signature", valid_594291
  var valid_594292 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594292 = validateParameter(valid_594292, JString, required = false,
                                 default = nil)
  if valid_594292 != nil:
    section.add "X-Amz-SignedHeaders", valid_594292
  var valid_594293 = header.getOrDefault("X-Amz-Credential")
  valid_594293 = validateParameter(valid_594293, JString, required = false,
                                 default = nil)
  if valid_594293 != nil:
    section.add "X-Amz-Credential", valid_594293
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594295: Call_DeleteParameters_594283; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Delete a list of parameters.
  ## 
  let valid = call_594295.validator(path, query, header, formData, body)
  let scheme = call_594295.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594295.url(scheme.get, call_594295.host, call_594295.base,
                         call_594295.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594295, url, valid)

proc call*(call_594296: Call_DeleteParameters_594283; body: JsonNode): Recallable =
  ## deleteParameters
  ## Delete a list of parameters.
  ##   body: JObject (required)
  var body_594297 = newJObject()
  if body != nil:
    body_594297 = body
  result = call_594296.call(nil, nil, nil, nil, body_594297)

var deleteParameters* = Call_DeleteParameters_594283(name: "deleteParameters",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DeleteParameters",
    validator: validate_DeleteParameters_594284, base: "/",
    url: url_DeleteParameters_594285, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeletePatchBaseline_594298 = ref object of OpenApiRestCall_593437
proc url_DeletePatchBaseline_594300(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeletePatchBaseline_594299(path: JsonNode; query: JsonNode;
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
  var valid_594301 = header.getOrDefault("X-Amz-Date")
  valid_594301 = validateParameter(valid_594301, JString, required = false,
                                 default = nil)
  if valid_594301 != nil:
    section.add "X-Amz-Date", valid_594301
  var valid_594302 = header.getOrDefault("X-Amz-Security-Token")
  valid_594302 = validateParameter(valid_594302, JString, required = false,
                                 default = nil)
  if valid_594302 != nil:
    section.add "X-Amz-Security-Token", valid_594302
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594303 = header.getOrDefault("X-Amz-Target")
  valid_594303 = validateParameter(valid_594303, JString, required = true, default = newJString(
      "AmazonSSM.DeletePatchBaseline"))
  if valid_594303 != nil:
    section.add "X-Amz-Target", valid_594303
  var valid_594304 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594304 = validateParameter(valid_594304, JString, required = false,
                                 default = nil)
  if valid_594304 != nil:
    section.add "X-Amz-Content-Sha256", valid_594304
  var valid_594305 = header.getOrDefault("X-Amz-Algorithm")
  valid_594305 = validateParameter(valid_594305, JString, required = false,
                                 default = nil)
  if valid_594305 != nil:
    section.add "X-Amz-Algorithm", valid_594305
  var valid_594306 = header.getOrDefault("X-Amz-Signature")
  valid_594306 = validateParameter(valid_594306, JString, required = false,
                                 default = nil)
  if valid_594306 != nil:
    section.add "X-Amz-Signature", valid_594306
  var valid_594307 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594307 = validateParameter(valid_594307, JString, required = false,
                                 default = nil)
  if valid_594307 != nil:
    section.add "X-Amz-SignedHeaders", valid_594307
  var valid_594308 = header.getOrDefault("X-Amz-Credential")
  valid_594308 = validateParameter(valid_594308, JString, required = false,
                                 default = nil)
  if valid_594308 != nil:
    section.add "X-Amz-Credential", valid_594308
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594310: Call_DeletePatchBaseline_594298; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a patch baseline.
  ## 
  let valid = call_594310.validator(path, query, header, formData, body)
  let scheme = call_594310.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594310.url(scheme.get, call_594310.host, call_594310.base,
                         call_594310.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594310, url, valid)

proc call*(call_594311: Call_DeletePatchBaseline_594298; body: JsonNode): Recallable =
  ## deletePatchBaseline
  ## Deletes a patch baseline.
  ##   body: JObject (required)
  var body_594312 = newJObject()
  if body != nil:
    body_594312 = body
  result = call_594311.call(nil, nil, nil, nil, body_594312)

var deletePatchBaseline* = Call_DeletePatchBaseline_594298(
    name: "deletePatchBaseline", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DeletePatchBaseline",
    validator: validate_DeletePatchBaseline_594299, base: "/",
    url: url_DeletePatchBaseline_594300, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteResourceDataSync_594313 = ref object of OpenApiRestCall_593437
proc url_DeleteResourceDataSync_594315(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteResourceDataSync_594314(path: JsonNode; query: JsonNode;
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
  var valid_594316 = header.getOrDefault("X-Amz-Date")
  valid_594316 = validateParameter(valid_594316, JString, required = false,
                                 default = nil)
  if valid_594316 != nil:
    section.add "X-Amz-Date", valid_594316
  var valid_594317 = header.getOrDefault("X-Amz-Security-Token")
  valid_594317 = validateParameter(valid_594317, JString, required = false,
                                 default = nil)
  if valid_594317 != nil:
    section.add "X-Amz-Security-Token", valid_594317
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594318 = header.getOrDefault("X-Amz-Target")
  valid_594318 = validateParameter(valid_594318, JString, required = true, default = newJString(
      "AmazonSSM.DeleteResourceDataSync"))
  if valid_594318 != nil:
    section.add "X-Amz-Target", valid_594318
  var valid_594319 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594319 = validateParameter(valid_594319, JString, required = false,
                                 default = nil)
  if valid_594319 != nil:
    section.add "X-Amz-Content-Sha256", valid_594319
  var valid_594320 = header.getOrDefault("X-Amz-Algorithm")
  valid_594320 = validateParameter(valid_594320, JString, required = false,
                                 default = nil)
  if valid_594320 != nil:
    section.add "X-Amz-Algorithm", valid_594320
  var valid_594321 = header.getOrDefault("X-Amz-Signature")
  valid_594321 = validateParameter(valid_594321, JString, required = false,
                                 default = nil)
  if valid_594321 != nil:
    section.add "X-Amz-Signature", valid_594321
  var valid_594322 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594322 = validateParameter(valid_594322, JString, required = false,
                                 default = nil)
  if valid_594322 != nil:
    section.add "X-Amz-SignedHeaders", valid_594322
  var valid_594323 = header.getOrDefault("X-Amz-Credential")
  valid_594323 = validateParameter(valid_594323, JString, required = false,
                                 default = nil)
  if valid_594323 != nil:
    section.add "X-Amz-Credential", valid_594323
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594325: Call_DeleteResourceDataSync_594313; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a Resource Data Sync configuration. After the configuration is deleted, changes to inventory data on managed instances are no longer synced with the target Amazon S3 bucket. Deleting a sync configuration does not delete data in the target Amazon S3 bucket.
  ## 
  let valid = call_594325.validator(path, query, header, formData, body)
  let scheme = call_594325.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594325.url(scheme.get, call_594325.host, call_594325.base,
                         call_594325.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594325, url, valid)

proc call*(call_594326: Call_DeleteResourceDataSync_594313; body: JsonNode): Recallable =
  ## deleteResourceDataSync
  ## Deletes a Resource Data Sync configuration. After the configuration is deleted, changes to inventory data on managed instances are no longer synced with the target Amazon S3 bucket. Deleting a sync configuration does not delete data in the target Amazon S3 bucket.
  ##   body: JObject (required)
  var body_594327 = newJObject()
  if body != nil:
    body_594327 = body
  result = call_594326.call(nil, nil, nil, nil, body_594327)

var deleteResourceDataSync* = Call_DeleteResourceDataSync_594313(
    name: "deleteResourceDataSync", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DeleteResourceDataSync",
    validator: validate_DeleteResourceDataSync_594314, base: "/",
    url: url_DeleteResourceDataSync_594315, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeregisterManagedInstance_594328 = ref object of OpenApiRestCall_593437
proc url_DeregisterManagedInstance_594330(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeregisterManagedInstance_594329(path: JsonNode; query: JsonNode;
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
  var valid_594331 = header.getOrDefault("X-Amz-Date")
  valid_594331 = validateParameter(valid_594331, JString, required = false,
                                 default = nil)
  if valid_594331 != nil:
    section.add "X-Amz-Date", valid_594331
  var valid_594332 = header.getOrDefault("X-Amz-Security-Token")
  valid_594332 = validateParameter(valid_594332, JString, required = false,
                                 default = nil)
  if valid_594332 != nil:
    section.add "X-Amz-Security-Token", valid_594332
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594333 = header.getOrDefault("X-Amz-Target")
  valid_594333 = validateParameter(valid_594333, JString, required = true, default = newJString(
      "AmazonSSM.DeregisterManagedInstance"))
  if valid_594333 != nil:
    section.add "X-Amz-Target", valid_594333
  var valid_594334 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594334 = validateParameter(valid_594334, JString, required = false,
                                 default = nil)
  if valid_594334 != nil:
    section.add "X-Amz-Content-Sha256", valid_594334
  var valid_594335 = header.getOrDefault("X-Amz-Algorithm")
  valid_594335 = validateParameter(valid_594335, JString, required = false,
                                 default = nil)
  if valid_594335 != nil:
    section.add "X-Amz-Algorithm", valid_594335
  var valid_594336 = header.getOrDefault("X-Amz-Signature")
  valid_594336 = validateParameter(valid_594336, JString, required = false,
                                 default = nil)
  if valid_594336 != nil:
    section.add "X-Amz-Signature", valid_594336
  var valid_594337 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594337 = validateParameter(valid_594337, JString, required = false,
                                 default = nil)
  if valid_594337 != nil:
    section.add "X-Amz-SignedHeaders", valid_594337
  var valid_594338 = header.getOrDefault("X-Amz-Credential")
  valid_594338 = validateParameter(valid_594338, JString, required = false,
                                 default = nil)
  if valid_594338 != nil:
    section.add "X-Amz-Credential", valid_594338
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594340: Call_DeregisterManagedInstance_594328; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes the server or virtual machine from the list of registered servers. You can reregister the instance again at any time. If you don't plan to use Run Command on the server, we suggest uninstalling SSM Agent first.
  ## 
  let valid = call_594340.validator(path, query, header, formData, body)
  let scheme = call_594340.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594340.url(scheme.get, call_594340.host, call_594340.base,
                         call_594340.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594340, url, valid)

proc call*(call_594341: Call_DeregisterManagedInstance_594328; body: JsonNode): Recallable =
  ## deregisterManagedInstance
  ## Removes the server or virtual machine from the list of registered servers. You can reregister the instance again at any time. If you don't plan to use Run Command on the server, we suggest uninstalling SSM Agent first.
  ##   body: JObject (required)
  var body_594342 = newJObject()
  if body != nil:
    body_594342 = body
  result = call_594341.call(nil, nil, nil, nil, body_594342)

var deregisterManagedInstance* = Call_DeregisterManagedInstance_594328(
    name: "deregisterManagedInstance", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DeregisterManagedInstance",
    validator: validate_DeregisterManagedInstance_594329, base: "/",
    url: url_DeregisterManagedInstance_594330,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeregisterPatchBaselineForPatchGroup_594343 = ref object of OpenApiRestCall_593437
proc url_DeregisterPatchBaselineForPatchGroup_594345(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeregisterPatchBaselineForPatchGroup_594344(path: JsonNode;
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
  var valid_594346 = header.getOrDefault("X-Amz-Date")
  valid_594346 = validateParameter(valid_594346, JString, required = false,
                                 default = nil)
  if valid_594346 != nil:
    section.add "X-Amz-Date", valid_594346
  var valid_594347 = header.getOrDefault("X-Amz-Security-Token")
  valid_594347 = validateParameter(valid_594347, JString, required = false,
                                 default = nil)
  if valid_594347 != nil:
    section.add "X-Amz-Security-Token", valid_594347
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594348 = header.getOrDefault("X-Amz-Target")
  valid_594348 = validateParameter(valid_594348, JString, required = true, default = newJString(
      "AmazonSSM.DeregisterPatchBaselineForPatchGroup"))
  if valid_594348 != nil:
    section.add "X-Amz-Target", valid_594348
  var valid_594349 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594349 = validateParameter(valid_594349, JString, required = false,
                                 default = nil)
  if valid_594349 != nil:
    section.add "X-Amz-Content-Sha256", valid_594349
  var valid_594350 = header.getOrDefault("X-Amz-Algorithm")
  valid_594350 = validateParameter(valid_594350, JString, required = false,
                                 default = nil)
  if valid_594350 != nil:
    section.add "X-Amz-Algorithm", valid_594350
  var valid_594351 = header.getOrDefault("X-Amz-Signature")
  valid_594351 = validateParameter(valid_594351, JString, required = false,
                                 default = nil)
  if valid_594351 != nil:
    section.add "X-Amz-Signature", valid_594351
  var valid_594352 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594352 = validateParameter(valid_594352, JString, required = false,
                                 default = nil)
  if valid_594352 != nil:
    section.add "X-Amz-SignedHeaders", valid_594352
  var valid_594353 = header.getOrDefault("X-Amz-Credential")
  valid_594353 = validateParameter(valid_594353, JString, required = false,
                                 default = nil)
  if valid_594353 != nil:
    section.add "X-Amz-Credential", valid_594353
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594355: Call_DeregisterPatchBaselineForPatchGroup_594343;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Removes a patch group from a patch baseline.
  ## 
  let valid = call_594355.validator(path, query, header, formData, body)
  let scheme = call_594355.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594355.url(scheme.get, call_594355.host, call_594355.base,
                         call_594355.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594355, url, valid)

proc call*(call_594356: Call_DeregisterPatchBaselineForPatchGroup_594343;
          body: JsonNode): Recallable =
  ## deregisterPatchBaselineForPatchGroup
  ## Removes a patch group from a patch baseline.
  ##   body: JObject (required)
  var body_594357 = newJObject()
  if body != nil:
    body_594357 = body
  result = call_594356.call(nil, nil, nil, nil, body_594357)

var deregisterPatchBaselineForPatchGroup* = Call_DeregisterPatchBaselineForPatchGroup_594343(
    name: "deregisterPatchBaselineForPatchGroup", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DeregisterPatchBaselineForPatchGroup",
    validator: validate_DeregisterPatchBaselineForPatchGroup_594344, base: "/",
    url: url_DeregisterPatchBaselineForPatchGroup_594345,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeregisterTargetFromMaintenanceWindow_594358 = ref object of OpenApiRestCall_593437
proc url_DeregisterTargetFromMaintenanceWindow_594360(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeregisterTargetFromMaintenanceWindow_594359(path: JsonNode;
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
  var valid_594361 = header.getOrDefault("X-Amz-Date")
  valid_594361 = validateParameter(valid_594361, JString, required = false,
                                 default = nil)
  if valid_594361 != nil:
    section.add "X-Amz-Date", valid_594361
  var valid_594362 = header.getOrDefault("X-Amz-Security-Token")
  valid_594362 = validateParameter(valid_594362, JString, required = false,
                                 default = nil)
  if valid_594362 != nil:
    section.add "X-Amz-Security-Token", valid_594362
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594363 = header.getOrDefault("X-Amz-Target")
  valid_594363 = validateParameter(valid_594363, JString, required = true, default = newJString(
      "AmazonSSM.DeregisterTargetFromMaintenanceWindow"))
  if valid_594363 != nil:
    section.add "X-Amz-Target", valid_594363
  var valid_594364 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594364 = validateParameter(valid_594364, JString, required = false,
                                 default = nil)
  if valid_594364 != nil:
    section.add "X-Amz-Content-Sha256", valid_594364
  var valid_594365 = header.getOrDefault("X-Amz-Algorithm")
  valid_594365 = validateParameter(valid_594365, JString, required = false,
                                 default = nil)
  if valid_594365 != nil:
    section.add "X-Amz-Algorithm", valid_594365
  var valid_594366 = header.getOrDefault("X-Amz-Signature")
  valid_594366 = validateParameter(valid_594366, JString, required = false,
                                 default = nil)
  if valid_594366 != nil:
    section.add "X-Amz-Signature", valid_594366
  var valid_594367 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594367 = validateParameter(valid_594367, JString, required = false,
                                 default = nil)
  if valid_594367 != nil:
    section.add "X-Amz-SignedHeaders", valid_594367
  var valid_594368 = header.getOrDefault("X-Amz-Credential")
  valid_594368 = validateParameter(valid_594368, JString, required = false,
                                 default = nil)
  if valid_594368 != nil:
    section.add "X-Amz-Credential", valid_594368
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594370: Call_DeregisterTargetFromMaintenanceWindow_594358;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Removes a target from a maintenance window.
  ## 
  let valid = call_594370.validator(path, query, header, formData, body)
  let scheme = call_594370.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594370.url(scheme.get, call_594370.host, call_594370.base,
                         call_594370.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594370, url, valid)

proc call*(call_594371: Call_DeregisterTargetFromMaintenanceWindow_594358;
          body: JsonNode): Recallable =
  ## deregisterTargetFromMaintenanceWindow
  ## Removes a target from a maintenance window.
  ##   body: JObject (required)
  var body_594372 = newJObject()
  if body != nil:
    body_594372 = body
  result = call_594371.call(nil, nil, nil, nil, body_594372)

var deregisterTargetFromMaintenanceWindow* = Call_DeregisterTargetFromMaintenanceWindow_594358(
    name: "deregisterTargetFromMaintenanceWindow", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DeregisterTargetFromMaintenanceWindow",
    validator: validate_DeregisterTargetFromMaintenanceWindow_594359, base: "/",
    url: url_DeregisterTargetFromMaintenanceWindow_594360,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeregisterTaskFromMaintenanceWindow_594373 = ref object of OpenApiRestCall_593437
proc url_DeregisterTaskFromMaintenanceWindow_594375(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeregisterTaskFromMaintenanceWindow_594374(path: JsonNode;
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
  var valid_594376 = header.getOrDefault("X-Amz-Date")
  valid_594376 = validateParameter(valid_594376, JString, required = false,
                                 default = nil)
  if valid_594376 != nil:
    section.add "X-Amz-Date", valid_594376
  var valid_594377 = header.getOrDefault("X-Amz-Security-Token")
  valid_594377 = validateParameter(valid_594377, JString, required = false,
                                 default = nil)
  if valid_594377 != nil:
    section.add "X-Amz-Security-Token", valid_594377
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594378 = header.getOrDefault("X-Amz-Target")
  valid_594378 = validateParameter(valid_594378, JString, required = true, default = newJString(
      "AmazonSSM.DeregisterTaskFromMaintenanceWindow"))
  if valid_594378 != nil:
    section.add "X-Amz-Target", valid_594378
  var valid_594379 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594379 = validateParameter(valid_594379, JString, required = false,
                                 default = nil)
  if valid_594379 != nil:
    section.add "X-Amz-Content-Sha256", valid_594379
  var valid_594380 = header.getOrDefault("X-Amz-Algorithm")
  valid_594380 = validateParameter(valid_594380, JString, required = false,
                                 default = nil)
  if valid_594380 != nil:
    section.add "X-Amz-Algorithm", valid_594380
  var valid_594381 = header.getOrDefault("X-Amz-Signature")
  valid_594381 = validateParameter(valid_594381, JString, required = false,
                                 default = nil)
  if valid_594381 != nil:
    section.add "X-Amz-Signature", valid_594381
  var valid_594382 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594382 = validateParameter(valid_594382, JString, required = false,
                                 default = nil)
  if valid_594382 != nil:
    section.add "X-Amz-SignedHeaders", valid_594382
  var valid_594383 = header.getOrDefault("X-Amz-Credential")
  valid_594383 = validateParameter(valid_594383, JString, required = false,
                                 default = nil)
  if valid_594383 != nil:
    section.add "X-Amz-Credential", valid_594383
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594385: Call_DeregisterTaskFromMaintenanceWindow_594373;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Removes a task from a maintenance window.
  ## 
  let valid = call_594385.validator(path, query, header, formData, body)
  let scheme = call_594385.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594385.url(scheme.get, call_594385.host, call_594385.base,
                         call_594385.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594385, url, valid)

proc call*(call_594386: Call_DeregisterTaskFromMaintenanceWindow_594373;
          body: JsonNode): Recallable =
  ## deregisterTaskFromMaintenanceWindow
  ## Removes a task from a maintenance window.
  ##   body: JObject (required)
  var body_594387 = newJObject()
  if body != nil:
    body_594387 = body
  result = call_594386.call(nil, nil, nil, nil, body_594387)

var deregisterTaskFromMaintenanceWindow* = Call_DeregisterTaskFromMaintenanceWindow_594373(
    name: "deregisterTaskFromMaintenanceWindow", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DeregisterTaskFromMaintenanceWindow",
    validator: validate_DeregisterTaskFromMaintenanceWindow_594374, base: "/",
    url: url_DeregisterTaskFromMaintenanceWindow_594375,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeActivations_594388 = ref object of OpenApiRestCall_593437
proc url_DescribeActivations_594390(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeActivations_594389(path: JsonNode; query: JsonNode;
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
  var valid_594391 = query.getOrDefault("NextToken")
  valid_594391 = validateParameter(valid_594391, JString, required = false,
                                 default = nil)
  if valid_594391 != nil:
    section.add "NextToken", valid_594391
  var valid_594392 = query.getOrDefault("MaxResults")
  valid_594392 = validateParameter(valid_594392, JString, required = false,
                                 default = nil)
  if valid_594392 != nil:
    section.add "MaxResults", valid_594392
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
  var valid_594393 = header.getOrDefault("X-Amz-Date")
  valid_594393 = validateParameter(valid_594393, JString, required = false,
                                 default = nil)
  if valid_594393 != nil:
    section.add "X-Amz-Date", valid_594393
  var valid_594394 = header.getOrDefault("X-Amz-Security-Token")
  valid_594394 = validateParameter(valid_594394, JString, required = false,
                                 default = nil)
  if valid_594394 != nil:
    section.add "X-Amz-Security-Token", valid_594394
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594395 = header.getOrDefault("X-Amz-Target")
  valid_594395 = validateParameter(valid_594395, JString, required = true, default = newJString(
      "AmazonSSM.DescribeActivations"))
  if valid_594395 != nil:
    section.add "X-Amz-Target", valid_594395
  var valid_594396 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594396 = validateParameter(valid_594396, JString, required = false,
                                 default = nil)
  if valid_594396 != nil:
    section.add "X-Amz-Content-Sha256", valid_594396
  var valid_594397 = header.getOrDefault("X-Amz-Algorithm")
  valid_594397 = validateParameter(valid_594397, JString, required = false,
                                 default = nil)
  if valid_594397 != nil:
    section.add "X-Amz-Algorithm", valid_594397
  var valid_594398 = header.getOrDefault("X-Amz-Signature")
  valid_594398 = validateParameter(valid_594398, JString, required = false,
                                 default = nil)
  if valid_594398 != nil:
    section.add "X-Amz-Signature", valid_594398
  var valid_594399 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594399 = validateParameter(valid_594399, JString, required = false,
                                 default = nil)
  if valid_594399 != nil:
    section.add "X-Amz-SignedHeaders", valid_594399
  var valid_594400 = header.getOrDefault("X-Amz-Credential")
  valid_594400 = validateParameter(valid_594400, JString, required = false,
                                 default = nil)
  if valid_594400 != nil:
    section.add "X-Amz-Credential", valid_594400
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594402: Call_DescribeActivations_594388; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes details about the activation, such as the date and time the activation was created, its expiration date, the IAM role assigned to the instances in the activation, and the number of instances registered by using this activation.
  ## 
  let valid = call_594402.validator(path, query, header, formData, body)
  let scheme = call_594402.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594402.url(scheme.get, call_594402.host, call_594402.base,
                         call_594402.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594402, url, valid)

proc call*(call_594403: Call_DescribeActivations_594388; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## describeActivations
  ## Describes details about the activation, such as the date and time the activation was created, its expiration date, the IAM role assigned to the instances in the activation, and the number of instances registered by using this activation.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_594404 = newJObject()
  var body_594405 = newJObject()
  add(query_594404, "NextToken", newJString(NextToken))
  if body != nil:
    body_594405 = body
  add(query_594404, "MaxResults", newJString(MaxResults))
  result = call_594403.call(nil, query_594404, nil, nil, body_594405)

var describeActivations* = Call_DescribeActivations_594388(
    name: "describeActivations", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeActivations",
    validator: validate_DescribeActivations_594389, base: "/",
    url: url_DescribeActivations_594390, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAssociation_594407 = ref object of OpenApiRestCall_593437
proc url_DescribeAssociation_594409(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeAssociation_594408(path: JsonNode; query: JsonNode;
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
  var valid_594410 = header.getOrDefault("X-Amz-Date")
  valid_594410 = validateParameter(valid_594410, JString, required = false,
                                 default = nil)
  if valid_594410 != nil:
    section.add "X-Amz-Date", valid_594410
  var valid_594411 = header.getOrDefault("X-Amz-Security-Token")
  valid_594411 = validateParameter(valid_594411, JString, required = false,
                                 default = nil)
  if valid_594411 != nil:
    section.add "X-Amz-Security-Token", valid_594411
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594412 = header.getOrDefault("X-Amz-Target")
  valid_594412 = validateParameter(valid_594412, JString, required = true, default = newJString(
      "AmazonSSM.DescribeAssociation"))
  if valid_594412 != nil:
    section.add "X-Amz-Target", valid_594412
  var valid_594413 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594413 = validateParameter(valid_594413, JString, required = false,
                                 default = nil)
  if valid_594413 != nil:
    section.add "X-Amz-Content-Sha256", valid_594413
  var valid_594414 = header.getOrDefault("X-Amz-Algorithm")
  valid_594414 = validateParameter(valid_594414, JString, required = false,
                                 default = nil)
  if valid_594414 != nil:
    section.add "X-Amz-Algorithm", valid_594414
  var valid_594415 = header.getOrDefault("X-Amz-Signature")
  valid_594415 = validateParameter(valid_594415, JString, required = false,
                                 default = nil)
  if valid_594415 != nil:
    section.add "X-Amz-Signature", valid_594415
  var valid_594416 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594416 = validateParameter(valid_594416, JString, required = false,
                                 default = nil)
  if valid_594416 != nil:
    section.add "X-Amz-SignedHeaders", valid_594416
  var valid_594417 = header.getOrDefault("X-Amz-Credential")
  valid_594417 = validateParameter(valid_594417, JString, required = false,
                                 default = nil)
  if valid_594417 != nil:
    section.add "X-Amz-Credential", valid_594417
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594419: Call_DescribeAssociation_594407; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the association for the specified target or instance. If you created the association by using the <code>Targets</code> parameter, then you must retrieve the association by using the association ID. If you created the association by specifying an instance ID and a Systems Manager document, then you retrieve the association by specifying the document name and the instance ID. 
  ## 
  let valid = call_594419.validator(path, query, header, formData, body)
  let scheme = call_594419.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594419.url(scheme.get, call_594419.host, call_594419.base,
                         call_594419.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594419, url, valid)

proc call*(call_594420: Call_DescribeAssociation_594407; body: JsonNode): Recallable =
  ## describeAssociation
  ## Describes the association for the specified target or instance. If you created the association by using the <code>Targets</code> parameter, then you must retrieve the association by using the association ID. If you created the association by specifying an instance ID and a Systems Manager document, then you retrieve the association by specifying the document name and the instance ID. 
  ##   body: JObject (required)
  var body_594421 = newJObject()
  if body != nil:
    body_594421 = body
  result = call_594420.call(nil, nil, nil, nil, body_594421)

var describeAssociation* = Call_DescribeAssociation_594407(
    name: "describeAssociation", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeAssociation",
    validator: validate_DescribeAssociation_594408, base: "/",
    url: url_DescribeAssociation_594409, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAssociationExecutionTargets_594422 = ref object of OpenApiRestCall_593437
proc url_DescribeAssociationExecutionTargets_594424(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeAssociationExecutionTargets_594423(path: JsonNode;
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
  var valid_594425 = header.getOrDefault("X-Amz-Date")
  valid_594425 = validateParameter(valid_594425, JString, required = false,
                                 default = nil)
  if valid_594425 != nil:
    section.add "X-Amz-Date", valid_594425
  var valid_594426 = header.getOrDefault("X-Amz-Security-Token")
  valid_594426 = validateParameter(valid_594426, JString, required = false,
                                 default = nil)
  if valid_594426 != nil:
    section.add "X-Amz-Security-Token", valid_594426
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594427 = header.getOrDefault("X-Amz-Target")
  valid_594427 = validateParameter(valid_594427, JString, required = true, default = newJString(
      "AmazonSSM.DescribeAssociationExecutionTargets"))
  if valid_594427 != nil:
    section.add "X-Amz-Target", valid_594427
  var valid_594428 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594428 = validateParameter(valid_594428, JString, required = false,
                                 default = nil)
  if valid_594428 != nil:
    section.add "X-Amz-Content-Sha256", valid_594428
  var valid_594429 = header.getOrDefault("X-Amz-Algorithm")
  valid_594429 = validateParameter(valid_594429, JString, required = false,
                                 default = nil)
  if valid_594429 != nil:
    section.add "X-Amz-Algorithm", valid_594429
  var valid_594430 = header.getOrDefault("X-Amz-Signature")
  valid_594430 = validateParameter(valid_594430, JString, required = false,
                                 default = nil)
  if valid_594430 != nil:
    section.add "X-Amz-Signature", valid_594430
  var valid_594431 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594431 = validateParameter(valid_594431, JString, required = false,
                                 default = nil)
  if valid_594431 != nil:
    section.add "X-Amz-SignedHeaders", valid_594431
  var valid_594432 = header.getOrDefault("X-Amz-Credential")
  valid_594432 = validateParameter(valid_594432, JString, required = false,
                                 default = nil)
  if valid_594432 != nil:
    section.add "X-Amz-Credential", valid_594432
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594434: Call_DescribeAssociationExecutionTargets_594422;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Use this API action to view information about a specific execution of a specific association.
  ## 
  let valid = call_594434.validator(path, query, header, formData, body)
  let scheme = call_594434.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594434.url(scheme.get, call_594434.host, call_594434.base,
                         call_594434.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594434, url, valid)

proc call*(call_594435: Call_DescribeAssociationExecutionTargets_594422;
          body: JsonNode): Recallable =
  ## describeAssociationExecutionTargets
  ## Use this API action to view information about a specific execution of a specific association.
  ##   body: JObject (required)
  var body_594436 = newJObject()
  if body != nil:
    body_594436 = body
  result = call_594435.call(nil, nil, nil, nil, body_594436)

var describeAssociationExecutionTargets* = Call_DescribeAssociationExecutionTargets_594422(
    name: "describeAssociationExecutionTargets", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeAssociationExecutionTargets",
    validator: validate_DescribeAssociationExecutionTargets_594423, base: "/",
    url: url_DescribeAssociationExecutionTargets_594424,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAssociationExecutions_594437 = ref object of OpenApiRestCall_593437
proc url_DescribeAssociationExecutions_594439(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeAssociationExecutions_594438(path: JsonNode; query: JsonNode;
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
  var valid_594440 = header.getOrDefault("X-Amz-Date")
  valid_594440 = validateParameter(valid_594440, JString, required = false,
                                 default = nil)
  if valid_594440 != nil:
    section.add "X-Amz-Date", valid_594440
  var valid_594441 = header.getOrDefault("X-Amz-Security-Token")
  valid_594441 = validateParameter(valid_594441, JString, required = false,
                                 default = nil)
  if valid_594441 != nil:
    section.add "X-Amz-Security-Token", valid_594441
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594442 = header.getOrDefault("X-Amz-Target")
  valid_594442 = validateParameter(valid_594442, JString, required = true, default = newJString(
      "AmazonSSM.DescribeAssociationExecutions"))
  if valid_594442 != nil:
    section.add "X-Amz-Target", valid_594442
  var valid_594443 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594443 = validateParameter(valid_594443, JString, required = false,
                                 default = nil)
  if valid_594443 != nil:
    section.add "X-Amz-Content-Sha256", valid_594443
  var valid_594444 = header.getOrDefault("X-Amz-Algorithm")
  valid_594444 = validateParameter(valid_594444, JString, required = false,
                                 default = nil)
  if valid_594444 != nil:
    section.add "X-Amz-Algorithm", valid_594444
  var valid_594445 = header.getOrDefault("X-Amz-Signature")
  valid_594445 = validateParameter(valid_594445, JString, required = false,
                                 default = nil)
  if valid_594445 != nil:
    section.add "X-Amz-Signature", valid_594445
  var valid_594446 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594446 = validateParameter(valid_594446, JString, required = false,
                                 default = nil)
  if valid_594446 != nil:
    section.add "X-Amz-SignedHeaders", valid_594446
  var valid_594447 = header.getOrDefault("X-Amz-Credential")
  valid_594447 = validateParameter(valid_594447, JString, required = false,
                                 default = nil)
  if valid_594447 != nil:
    section.add "X-Amz-Credential", valid_594447
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594449: Call_DescribeAssociationExecutions_594437; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Use this API action to view all executions for a specific association ID. 
  ## 
  let valid = call_594449.validator(path, query, header, formData, body)
  let scheme = call_594449.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594449.url(scheme.get, call_594449.host, call_594449.base,
                         call_594449.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594449, url, valid)

proc call*(call_594450: Call_DescribeAssociationExecutions_594437; body: JsonNode): Recallable =
  ## describeAssociationExecutions
  ## Use this API action to view all executions for a specific association ID. 
  ##   body: JObject (required)
  var body_594451 = newJObject()
  if body != nil:
    body_594451 = body
  result = call_594450.call(nil, nil, nil, nil, body_594451)

var describeAssociationExecutions* = Call_DescribeAssociationExecutions_594437(
    name: "describeAssociationExecutions", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeAssociationExecutions",
    validator: validate_DescribeAssociationExecutions_594438, base: "/",
    url: url_DescribeAssociationExecutions_594439,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAutomationExecutions_594452 = ref object of OpenApiRestCall_593437
proc url_DescribeAutomationExecutions_594454(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeAutomationExecutions_594453(path: JsonNode; query: JsonNode;
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
  var valid_594455 = header.getOrDefault("X-Amz-Date")
  valid_594455 = validateParameter(valid_594455, JString, required = false,
                                 default = nil)
  if valid_594455 != nil:
    section.add "X-Amz-Date", valid_594455
  var valid_594456 = header.getOrDefault("X-Amz-Security-Token")
  valid_594456 = validateParameter(valid_594456, JString, required = false,
                                 default = nil)
  if valid_594456 != nil:
    section.add "X-Amz-Security-Token", valid_594456
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594457 = header.getOrDefault("X-Amz-Target")
  valid_594457 = validateParameter(valid_594457, JString, required = true, default = newJString(
      "AmazonSSM.DescribeAutomationExecutions"))
  if valid_594457 != nil:
    section.add "X-Amz-Target", valid_594457
  var valid_594458 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594458 = validateParameter(valid_594458, JString, required = false,
                                 default = nil)
  if valid_594458 != nil:
    section.add "X-Amz-Content-Sha256", valid_594458
  var valid_594459 = header.getOrDefault("X-Amz-Algorithm")
  valid_594459 = validateParameter(valid_594459, JString, required = false,
                                 default = nil)
  if valid_594459 != nil:
    section.add "X-Amz-Algorithm", valid_594459
  var valid_594460 = header.getOrDefault("X-Amz-Signature")
  valid_594460 = validateParameter(valid_594460, JString, required = false,
                                 default = nil)
  if valid_594460 != nil:
    section.add "X-Amz-Signature", valid_594460
  var valid_594461 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594461 = validateParameter(valid_594461, JString, required = false,
                                 default = nil)
  if valid_594461 != nil:
    section.add "X-Amz-SignedHeaders", valid_594461
  var valid_594462 = header.getOrDefault("X-Amz-Credential")
  valid_594462 = validateParameter(valid_594462, JString, required = false,
                                 default = nil)
  if valid_594462 != nil:
    section.add "X-Amz-Credential", valid_594462
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594464: Call_DescribeAutomationExecutions_594452; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provides details about all active and terminated Automation executions.
  ## 
  let valid = call_594464.validator(path, query, header, formData, body)
  let scheme = call_594464.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594464.url(scheme.get, call_594464.host, call_594464.base,
                         call_594464.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594464, url, valid)

proc call*(call_594465: Call_DescribeAutomationExecutions_594452; body: JsonNode): Recallable =
  ## describeAutomationExecutions
  ## Provides details about all active and terminated Automation executions.
  ##   body: JObject (required)
  var body_594466 = newJObject()
  if body != nil:
    body_594466 = body
  result = call_594465.call(nil, nil, nil, nil, body_594466)

var describeAutomationExecutions* = Call_DescribeAutomationExecutions_594452(
    name: "describeAutomationExecutions", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeAutomationExecutions",
    validator: validate_DescribeAutomationExecutions_594453, base: "/",
    url: url_DescribeAutomationExecutions_594454,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAutomationStepExecutions_594467 = ref object of OpenApiRestCall_593437
proc url_DescribeAutomationStepExecutions_594469(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeAutomationStepExecutions_594468(path: JsonNode;
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
  var valid_594470 = header.getOrDefault("X-Amz-Date")
  valid_594470 = validateParameter(valid_594470, JString, required = false,
                                 default = nil)
  if valid_594470 != nil:
    section.add "X-Amz-Date", valid_594470
  var valid_594471 = header.getOrDefault("X-Amz-Security-Token")
  valid_594471 = validateParameter(valid_594471, JString, required = false,
                                 default = nil)
  if valid_594471 != nil:
    section.add "X-Amz-Security-Token", valid_594471
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594472 = header.getOrDefault("X-Amz-Target")
  valid_594472 = validateParameter(valid_594472, JString, required = true, default = newJString(
      "AmazonSSM.DescribeAutomationStepExecutions"))
  if valid_594472 != nil:
    section.add "X-Amz-Target", valid_594472
  var valid_594473 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594473 = validateParameter(valid_594473, JString, required = false,
                                 default = nil)
  if valid_594473 != nil:
    section.add "X-Amz-Content-Sha256", valid_594473
  var valid_594474 = header.getOrDefault("X-Amz-Algorithm")
  valid_594474 = validateParameter(valid_594474, JString, required = false,
                                 default = nil)
  if valid_594474 != nil:
    section.add "X-Amz-Algorithm", valid_594474
  var valid_594475 = header.getOrDefault("X-Amz-Signature")
  valid_594475 = validateParameter(valid_594475, JString, required = false,
                                 default = nil)
  if valid_594475 != nil:
    section.add "X-Amz-Signature", valid_594475
  var valid_594476 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594476 = validateParameter(valid_594476, JString, required = false,
                                 default = nil)
  if valid_594476 != nil:
    section.add "X-Amz-SignedHeaders", valid_594476
  var valid_594477 = header.getOrDefault("X-Amz-Credential")
  valid_594477 = validateParameter(valid_594477, JString, required = false,
                                 default = nil)
  if valid_594477 != nil:
    section.add "X-Amz-Credential", valid_594477
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594479: Call_DescribeAutomationStepExecutions_594467;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Information about all active and terminated step executions in an Automation workflow.
  ## 
  let valid = call_594479.validator(path, query, header, formData, body)
  let scheme = call_594479.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594479.url(scheme.get, call_594479.host, call_594479.base,
                         call_594479.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594479, url, valid)

proc call*(call_594480: Call_DescribeAutomationStepExecutions_594467;
          body: JsonNode): Recallable =
  ## describeAutomationStepExecutions
  ## Information about all active and terminated step executions in an Automation workflow.
  ##   body: JObject (required)
  var body_594481 = newJObject()
  if body != nil:
    body_594481 = body
  result = call_594480.call(nil, nil, nil, nil, body_594481)

var describeAutomationStepExecutions* = Call_DescribeAutomationStepExecutions_594467(
    name: "describeAutomationStepExecutions", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeAutomationStepExecutions",
    validator: validate_DescribeAutomationStepExecutions_594468, base: "/",
    url: url_DescribeAutomationStepExecutions_594469,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAvailablePatches_594482 = ref object of OpenApiRestCall_593437
proc url_DescribeAvailablePatches_594484(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeAvailablePatches_594483(path: JsonNode; query: JsonNode;
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
  var valid_594485 = header.getOrDefault("X-Amz-Date")
  valid_594485 = validateParameter(valid_594485, JString, required = false,
                                 default = nil)
  if valid_594485 != nil:
    section.add "X-Amz-Date", valid_594485
  var valid_594486 = header.getOrDefault("X-Amz-Security-Token")
  valid_594486 = validateParameter(valid_594486, JString, required = false,
                                 default = nil)
  if valid_594486 != nil:
    section.add "X-Amz-Security-Token", valid_594486
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594487 = header.getOrDefault("X-Amz-Target")
  valid_594487 = validateParameter(valid_594487, JString, required = true, default = newJString(
      "AmazonSSM.DescribeAvailablePatches"))
  if valid_594487 != nil:
    section.add "X-Amz-Target", valid_594487
  var valid_594488 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594488 = validateParameter(valid_594488, JString, required = false,
                                 default = nil)
  if valid_594488 != nil:
    section.add "X-Amz-Content-Sha256", valid_594488
  var valid_594489 = header.getOrDefault("X-Amz-Algorithm")
  valid_594489 = validateParameter(valid_594489, JString, required = false,
                                 default = nil)
  if valid_594489 != nil:
    section.add "X-Amz-Algorithm", valid_594489
  var valid_594490 = header.getOrDefault("X-Amz-Signature")
  valid_594490 = validateParameter(valid_594490, JString, required = false,
                                 default = nil)
  if valid_594490 != nil:
    section.add "X-Amz-Signature", valid_594490
  var valid_594491 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594491 = validateParameter(valid_594491, JString, required = false,
                                 default = nil)
  if valid_594491 != nil:
    section.add "X-Amz-SignedHeaders", valid_594491
  var valid_594492 = header.getOrDefault("X-Amz-Credential")
  valid_594492 = validateParameter(valid_594492, JString, required = false,
                                 default = nil)
  if valid_594492 != nil:
    section.add "X-Amz-Credential", valid_594492
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594494: Call_DescribeAvailablePatches_594482; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all patches eligible to be included in a patch baseline.
  ## 
  let valid = call_594494.validator(path, query, header, formData, body)
  let scheme = call_594494.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594494.url(scheme.get, call_594494.host, call_594494.base,
                         call_594494.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594494, url, valid)

proc call*(call_594495: Call_DescribeAvailablePatches_594482; body: JsonNode): Recallable =
  ## describeAvailablePatches
  ## Lists all patches eligible to be included in a patch baseline.
  ##   body: JObject (required)
  var body_594496 = newJObject()
  if body != nil:
    body_594496 = body
  result = call_594495.call(nil, nil, nil, nil, body_594496)

var describeAvailablePatches* = Call_DescribeAvailablePatches_594482(
    name: "describeAvailablePatches", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeAvailablePatches",
    validator: validate_DescribeAvailablePatches_594483, base: "/",
    url: url_DescribeAvailablePatches_594484, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDocument_594497 = ref object of OpenApiRestCall_593437
proc url_DescribeDocument_594499(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeDocument_594498(path: JsonNode; query: JsonNode;
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
  var valid_594500 = header.getOrDefault("X-Amz-Date")
  valid_594500 = validateParameter(valid_594500, JString, required = false,
                                 default = nil)
  if valid_594500 != nil:
    section.add "X-Amz-Date", valid_594500
  var valid_594501 = header.getOrDefault("X-Amz-Security-Token")
  valid_594501 = validateParameter(valid_594501, JString, required = false,
                                 default = nil)
  if valid_594501 != nil:
    section.add "X-Amz-Security-Token", valid_594501
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594502 = header.getOrDefault("X-Amz-Target")
  valid_594502 = validateParameter(valid_594502, JString, required = true, default = newJString(
      "AmazonSSM.DescribeDocument"))
  if valid_594502 != nil:
    section.add "X-Amz-Target", valid_594502
  var valid_594503 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594503 = validateParameter(valid_594503, JString, required = false,
                                 default = nil)
  if valid_594503 != nil:
    section.add "X-Amz-Content-Sha256", valid_594503
  var valid_594504 = header.getOrDefault("X-Amz-Algorithm")
  valid_594504 = validateParameter(valid_594504, JString, required = false,
                                 default = nil)
  if valid_594504 != nil:
    section.add "X-Amz-Algorithm", valid_594504
  var valid_594505 = header.getOrDefault("X-Amz-Signature")
  valid_594505 = validateParameter(valid_594505, JString, required = false,
                                 default = nil)
  if valid_594505 != nil:
    section.add "X-Amz-Signature", valid_594505
  var valid_594506 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594506 = validateParameter(valid_594506, JString, required = false,
                                 default = nil)
  if valid_594506 != nil:
    section.add "X-Amz-SignedHeaders", valid_594506
  var valid_594507 = header.getOrDefault("X-Amz-Credential")
  valid_594507 = validateParameter(valid_594507, JString, required = false,
                                 default = nil)
  if valid_594507 != nil:
    section.add "X-Amz-Credential", valid_594507
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594509: Call_DescribeDocument_594497; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the specified Systems Manager document.
  ## 
  let valid = call_594509.validator(path, query, header, formData, body)
  let scheme = call_594509.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594509.url(scheme.get, call_594509.host, call_594509.base,
                         call_594509.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594509, url, valid)

proc call*(call_594510: Call_DescribeDocument_594497; body: JsonNode): Recallable =
  ## describeDocument
  ## Describes the specified Systems Manager document.
  ##   body: JObject (required)
  var body_594511 = newJObject()
  if body != nil:
    body_594511 = body
  result = call_594510.call(nil, nil, nil, nil, body_594511)

var describeDocument* = Call_DescribeDocument_594497(name: "describeDocument",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeDocument",
    validator: validate_DescribeDocument_594498, base: "/",
    url: url_DescribeDocument_594499, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDocumentPermission_594512 = ref object of OpenApiRestCall_593437
proc url_DescribeDocumentPermission_594514(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeDocumentPermission_594513(path: JsonNode; query: JsonNode;
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
  var valid_594515 = header.getOrDefault("X-Amz-Date")
  valid_594515 = validateParameter(valid_594515, JString, required = false,
                                 default = nil)
  if valid_594515 != nil:
    section.add "X-Amz-Date", valid_594515
  var valid_594516 = header.getOrDefault("X-Amz-Security-Token")
  valid_594516 = validateParameter(valid_594516, JString, required = false,
                                 default = nil)
  if valid_594516 != nil:
    section.add "X-Amz-Security-Token", valid_594516
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594517 = header.getOrDefault("X-Amz-Target")
  valid_594517 = validateParameter(valid_594517, JString, required = true, default = newJString(
      "AmazonSSM.DescribeDocumentPermission"))
  if valid_594517 != nil:
    section.add "X-Amz-Target", valid_594517
  var valid_594518 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594518 = validateParameter(valid_594518, JString, required = false,
                                 default = nil)
  if valid_594518 != nil:
    section.add "X-Amz-Content-Sha256", valid_594518
  var valid_594519 = header.getOrDefault("X-Amz-Algorithm")
  valid_594519 = validateParameter(valid_594519, JString, required = false,
                                 default = nil)
  if valid_594519 != nil:
    section.add "X-Amz-Algorithm", valid_594519
  var valid_594520 = header.getOrDefault("X-Amz-Signature")
  valid_594520 = validateParameter(valid_594520, JString, required = false,
                                 default = nil)
  if valid_594520 != nil:
    section.add "X-Amz-Signature", valid_594520
  var valid_594521 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594521 = validateParameter(valid_594521, JString, required = false,
                                 default = nil)
  if valid_594521 != nil:
    section.add "X-Amz-SignedHeaders", valid_594521
  var valid_594522 = header.getOrDefault("X-Amz-Credential")
  valid_594522 = validateParameter(valid_594522, JString, required = false,
                                 default = nil)
  if valid_594522 != nil:
    section.add "X-Amz-Credential", valid_594522
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594524: Call_DescribeDocumentPermission_594512; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the permissions for a Systems Manager document. If you created the document, you are the owner. If a document is shared, it can either be shared privately (by specifying a user's AWS account ID) or publicly (<i>All</i>). 
  ## 
  let valid = call_594524.validator(path, query, header, formData, body)
  let scheme = call_594524.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594524.url(scheme.get, call_594524.host, call_594524.base,
                         call_594524.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594524, url, valid)

proc call*(call_594525: Call_DescribeDocumentPermission_594512; body: JsonNode): Recallable =
  ## describeDocumentPermission
  ## Describes the permissions for a Systems Manager document. If you created the document, you are the owner. If a document is shared, it can either be shared privately (by specifying a user's AWS account ID) or publicly (<i>All</i>). 
  ##   body: JObject (required)
  var body_594526 = newJObject()
  if body != nil:
    body_594526 = body
  result = call_594525.call(nil, nil, nil, nil, body_594526)

var describeDocumentPermission* = Call_DescribeDocumentPermission_594512(
    name: "describeDocumentPermission", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeDocumentPermission",
    validator: validate_DescribeDocumentPermission_594513, base: "/",
    url: url_DescribeDocumentPermission_594514,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEffectiveInstanceAssociations_594527 = ref object of OpenApiRestCall_593437
proc url_DescribeEffectiveInstanceAssociations_594529(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeEffectiveInstanceAssociations_594528(path: JsonNode;
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
  var valid_594530 = header.getOrDefault("X-Amz-Date")
  valid_594530 = validateParameter(valid_594530, JString, required = false,
                                 default = nil)
  if valid_594530 != nil:
    section.add "X-Amz-Date", valid_594530
  var valid_594531 = header.getOrDefault("X-Amz-Security-Token")
  valid_594531 = validateParameter(valid_594531, JString, required = false,
                                 default = nil)
  if valid_594531 != nil:
    section.add "X-Amz-Security-Token", valid_594531
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594532 = header.getOrDefault("X-Amz-Target")
  valid_594532 = validateParameter(valid_594532, JString, required = true, default = newJString(
      "AmazonSSM.DescribeEffectiveInstanceAssociations"))
  if valid_594532 != nil:
    section.add "X-Amz-Target", valid_594532
  var valid_594533 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594533 = validateParameter(valid_594533, JString, required = false,
                                 default = nil)
  if valid_594533 != nil:
    section.add "X-Amz-Content-Sha256", valid_594533
  var valid_594534 = header.getOrDefault("X-Amz-Algorithm")
  valid_594534 = validateParameter(valid_594534, JString, required = false,
                                 default = nil)
  if valid_594534 != nil:
    section.add "X-Amz-Algorithm", valid_594534
  var valid_594535 = header.getOrDefault("X-Amz-Signature")
  valid_594535 = validateParameter(valid_594535, JString, required = false,
                                 default = nil)
  if valid_594535 != nil:
    section.add "X-Amz-Signature", valid_594535
  var valid_594536 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594536 = validateParameter(valid_594536, JString, required = false,
                                 default = nil)
  if valid_594536 != nil:
    section.add "X-Amz-SignedHeaders", valid_594536
  var valid_594537 = header.getOrDefault("X-Amz-Credential")
  valid_594537 = validateParameter(valid_594537, JString, required = false,
                                 default = nil)
  if valid_594537 != nil:
    section.add "X-Amz-Credential", valid_594537
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594539: Call_DescribeEffectiveInstanceAssociations_594527;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## All associations for the instance(s).
  ## 
  let valid = call_594539.validator(path, query, header, formData, body)
  let scheme = call_594539.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594539.url(scheme.get, call_594539.host, call_594539.base,
                         call_594539.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594539, url, valid)

proc call*(call_594540: Call_DescribeEffectiveInstanceAssociations_594527;
          body: JsonNode): Recallable =
  ## describeEffectiveInstanceAssociations
  ## All associations for the instance(s).
  ##   body: JObject (required)
  var body_594541 = newJObject()
  if body != nil:
    body_594541 = body
  result = call_594540.call(nil, nil, nil, nil, body_594541)

var describeEffectiveInstanceAssociations* = Call_DescribeEffectiveInstanceAssociations_594527(
    name: "describeEffectiveInstanceAssociations", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeEffectiveInstanceAssociations",
    validator: validate_DescribeEffectiveInstanceAssociations_594528, base: "/",
    url: url_DescribeEffectiveInstanceAssociations_594529,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEffectivePatchesForPatchBaseline_594542 = ref object of OpenApiRestCall_593437
proc url_DescribeEffectivePatchesForPatchBaseline_594544(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeEffectivePatchesForPatchBaseline_594543(path: JsonNode;
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
  var valid_594545 = header.getOrDefault("X-Amz-Date")
  valid_594545 = validateParameter(valid_594545, JString, required = false,
                                 default = nil)
  if valid_594545 != nil:
    section.add "X-Amz-Date", valid_594545
  var valid_594546 = header.getOrDefault("X-Amz-Security-Token")
  valid_594546 = validateParameter(valid_594546, JString, required = false,
                                 default = nil)
  if valid_594546 != nil:
    section.add "X-Amz-Security-Token", valid_594546
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594547 = header.getOrDefault("X-Amz-Target")
  valid_594547 = validateParameter(valid_594547, JString, required = true, default = newJString(
      "AmazonSSM.DescribeEffectivePatchesForPatchBaseline"))
  if valid_594547 != nil:
    section.add "X-Amz-Target", valid_594547
  var valid_594548 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594548 = validateParameter(valid_594548, JString, required = false,
                                 default = nil)
  if valid_594548 != nil:
    section.add "X-Amz-Content-Sha256", valid_594548
  var valid_594549 = header.getOrDefault("X-Amz-Algorithm")
  valid_594549 = validateParameter(valid_594549, JString, required = false,
                                 default = nil)
  if valid_594549 != nil:
    section.add "X-Amz-Algorithm", valid_594549
  var valid_594550 = header.getOrDefault("X-Amz-Signature")
  valid_594550 = validateParameter(valid_594550, JString, required = false,
                                 default = nil)
  if valid_594550 != nil:
    section.add "X-Amz-Signature", valid_594550
  var valid_594551 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594551 = validateParameter(valid_594551, JString, required = false,
                                 default = nil)
  if valid_594551 != nil:
    section.add "X-Amz-SignedHeaders", valid_594551
  var valid_594552 = header.getOrDefault("X-Amz-Credential")
  valid_594552 = validateParameter(valid_594552, JString, required = false,
                                 default = nil)
  if valid_594552 != nil:
    section.add "X-Amz-Credential", valid_594552
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594554: Call_DescribeEffectivePatchesForPatchBaseline_594542;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves the current effective patches (the patch and the approval state) for the specified patch baseline. Note that this API applies only to Windows patch baselines.
  ## 
  let valid = call_594554.validator(path, query, header, formData, body)
  let scheme = call_594554.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594554.url(scheme.get, call_594554.host, call_594554.base,
                         call_594554.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594554, url, valid)

proc call*(call_594555: Call_DescribeEffectivePatchesForPatchBaseline_594542;
          body: JsonNode): Recallable =
  ## describeEffectivePatchesForPatchBaseline
  ## Retrieves the current effective patches (the patch and the approval state) for the specified patch baseline. Note that this API applies only to Windows patch baselines.
  ##   body: JObject (required)
  var body_594556 = newJObject()
  if body != nil:
    body_594556 = body
  result = call_594555.call(nil, nil, nil, nil, body_594556)

var describeEffectivePatchesForPatchBaseline* = Call_DescribeEffectivePatchesForPatchBaseline_594542(
    name: "describeEffectivePatchesForPatchBaseline", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeEffectivePatchesForPatchBaseline",
    validator: validate_DescribeEffectivePatchesForPatchBaseline_594543,
    base: "/", url: url_DescribeEffectivePatchesForPatchBaseline_594544,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeInstanceAssociationsStatus_594557 = ref object of OpenApiRestCall_593437
proc url_DescribeInstanceAssociationsStatus_594559(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeInstanceAssociationsStatus_594558(path: JsonNode;
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
  var valid_594560 = header.getOrDefault("X-Amz-Date")
  valid_594560 = validateParameter(valid_594560, JString, required = false,
                                 default = nil)
  if valid_594560 != nil:
    section.add "X-Amz-Date", valid_594560
  var valid_594561 = header.getOrDefault("X-Amz-Security-Token")
  valid_594561 = validateParameter(valid_594561, JString, required = false,
                                 default = nil)
  if valid_594561 != nil:
    section.add "X-Amz-Security-Token", valid_594561
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594562 = header.getOrDefault("X-Amz-Target")
  valid_594562 = validateParameter(valid_594562, JString, required = true, default = newJString(
      "AmazonSSM.DescribeInstanceAssociationsStatus"))
  if valid_594562 != nil:
    section.add "X-Amz-Target", valid_594562
  var valid_594563 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594563 = validateParameter(valid_594563, JString, required = false,
                                 default = nil)
  if valid_594563 != nil:
    section.add "X-Amz-Content-Sha256", valid_594563
  var valid_594564 = header.getOrDefault("X-Amz-Algorithm")
  valid_594564 = validateParameter(valid_594564, JString, required = false,
                                 default = nil)
  if valid_594564 != nil:
    section.add "X-Amz-Algorithm", valid_594564
  var valid_594565 = header.getOrDefault("X-Amz-Signature")
  valid_594565 = validateParameter(valid_594565, JString, required = false,
                                 default = nil)
  if valid_594565 != nil:
    section.add "X-Amz-Signature", valid_594565
  var valid_594566 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594566 = validateParameter(valid_594566, JString, required = false,
                                 default = nil)
  if valid_594566 != nil:
    section.add "X-Amz-SignedHeaders", valid_594566
  var valid_594567 = header.getOrDefault("X-Amz-Credential")
  valid_594567 = validateParameter(valid_594567, JString, required = false,
                                 default = nil)
  if valid_594567 != nil:
    section.add "X-Amz-Credential", valid_594567
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594569: Call_DescribeInstanceAssociationsStatus_594557;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## The status of the associations for the instance(s).
  ## 
  let valid = call_594569.validator(path, query, header, formData, body)
  let scheme = call_594569.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594569.url(scheme.get, call_594569.host, call_594569.base,
                         call_594569.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594569, url, valid)

proc call*(call_594570: Call_DescribeInstanceAssociationsStatus_594557;
          body: JsonNode): Recallable =
  ## describeInstanceAssociationsStatus
  ## The status of the associations for the instance(s).
  ##   body: JObject (required)
  var body_594571 = newJObject()
  if body != nil:
    body_594571 = body
  result = call_594570.call(nil, nil, nil, nil, body_594571)

var describeInstanceAssociationsStatus* = Call_DescribeInstanceAssociationsStatus_594557(
    name: "describeInstanceAssociationsStatus", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeInstanceAssociationsStatus",
    validator: validate_DescribeInstanceAssociationsStatus_594558, base: "/",
    url: url_DescribeInstanceAssociationsStatus_594559,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeInstanceInformation_594572 = ref object of OpenApiRestCall_593437
proc url_DescribeInstanceInformation_594574(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeInstanceInformation_594573(path: JsonNode; query: JsonNode;
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
  var valid_594575 = query.getOrDefault("NextToken")
  valid_594575 = validateParameter(valid_594575, JString, required = false,
                                 default = nil)
  if valid_594575 != nil:
    section.add "NextToken", valid_594575
  var valid_594576 = query.getOrDefault("MaxResults")
  valid_594576 = validateParameter(valid_594576, JString, required = false,
                                 default = nil)
  if valid_594576 != nil:
    section.add "MaxResults", valid_594576
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
  var valid_594577 = header.getOrDefault("X-Amz-Date")
  valid_594577 = validateParameter(valid_594577, JString, required = false,
                                 default = nil)
  if valid_594577 != nil:
    section.add "X-Amz-Date", valid_594577
  var valid_594578 = header.getOrDefault("X-Amz-Security-Token")
  valid_594578 = validateParameter(valid_594578, JString, required = false,
                                 default = nil)
  if valid_594578 != nil:
    section.add "X-Amz-Security-Token", valid_594578
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594579 = header.getOrDefault("X-Amz-Target")
  valid_594579 = validateParameter(valid_594579, JString, required = true, default = newJString(
      "AmazonSSM.DescribeInstanceInformation"))
  if valid_594579 != nil:
    section.add "X-Amz-Target", valid_594579
  var valid_594580 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594580 = validateParameter(valid_594580, JString, required = false,
                                 default = nil)
  if valid_594580 != nil:
    section.add "X-Amz-Content-Sha256", valid_594580
  var valid_594581 = header.getOrDefault("X-Amz-Algorithm")
  valid_594581 = validateParameter(valid_594581, JString, required = false,
                                 default = nil)
  if valid_594581 != nil:
    section.add "X-Amz-Algorithm", valid_594581
  var valid_594582 = header.getOrDefault("X-Amz-Signature")
  valid_594582 = validateParameter(valid_594582, JString, required = false,
                                 default = nil)
  if valid_594582 != nil:
    section.add "X-Amz-Signature", valid_594582
  var valid_594583 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594583 = validateParameter(valid_594583, JString, required = false,
                                 default = nil)
  if valid_594583 != nil:
    section.add "X-Amz-SignedHeaders", valid_594583
  var valid_594584 = header.getOrDefault("X-Amz-Credential")
  valid_594584 = validateParameter(valid_594584, JString, required = false,
                                 default = nil)
  if valid_594584 != nil:
    section.add "X-Amz-Credential", valid_594584
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594586: Call_DescribeInstanceInformation_594572; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes one or more of your instances. You can use this to get information about instances like the operating system platform, the SSM Agent version (Linux), status etc. If you specify one or more instance IDs, it returns information for those instances. If you do not specify instance IDs, it returns information for all your instances. If you specify an instance ID that is not valid or an instance that you do not own, you receive an error. </p> <note> <p>The IamRole field for this API action is the Amazon Identity and Access Management (IAM) role assigned to on-premises instances. This call does not return the IAM role for Amazon EC2 instances.</p> </note>
  ## 
  let valid = call_594586.validator(path, query, header, formData, body)
  let scheme = call_594586.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594586.url(scheme.get, call_594586.host, call_594586.base,
                         call_594586.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594586, url, valid)

proc call*(call_594587: Call_DescribeInstanceInformation_594572; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## describeInstanceInformation
  ## <p>Describes one or more of your instances. You can use this to get information about instances like the operating system platform, the SSM Agent version (Linux), status etc. If you specify one or more instance IDs, it returns information for those instances. If you do not specify instance IDs, it returns information for all your instances. If you specify an instance ID that is not valid or an instance that you do not own, you receive an error. </p> <note> <p>The IamRole field for this API action is the Amazon Identity and Access Management (IAM) role assigned to on-premises instances. This call does not return the IAM role for Amazon EC2 instances.</p> </note>
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_594588 = newJObject()
  var body_594589 = newJObject()
  add(query_594588, "NextToken", newJString(NextToken))
  if body != nil:
    body_594589 = body
  add(query_594588, "MaxResults", newJString(MaxResults))
  result = call_594587.call(nil, query_594588, nil, nil, body_594589)

var describeInstanceInformation* = Call_DescribeInstanceInformation_594572(
    name: "describeInstanceInformation", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeInstanceInformation",
    validator: validate_DescribeInstanceInformation_594573, base: "/",
    url: url_DescribeInstanceInformation_594574,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeInstancePatchStates_594590 = ref object of OpenApiRestCall_593437
proc url_DescribeInstancePatchStates_594592(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeInstancePatchStates_594591(path: JsonNode; query: JsonNode;
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
  var valid_594593 = header.getOrDefault("X-Amz-Date")
  valid_594593 = validateParameter(valid_594593, JString, required = false,
                                 default = nil)
  if valid_594593 != nil:
    section.add "X-Amz-Date", valid_594593
  var valid_594594 = header.getOrDefault("X-Amz-Security-Token")
  valid_594594 = validateParameter(valid_594594, JString, required = false,
                                 default = nil)
  if valid_594594 != nil:
    section.add "X-Amz-Security-Token", valid_594594
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594595 = header.getOrDefault("X-Amz-Target")
  valid_594595 = validateParameter(valid_594595, JString, required = true, default = newJString(
      "AmazonSSM.DescribeInstancePatchStates"))
  if valid_594595 != nil:
    section.add "X-Amz-Target", valid_594595
  var valid_594596 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594596 = validateParameter(valid_594596, JString, required = false,
                                 default = nil)
  if valid_594596 != nil:
    section.add "X-Amz-Content-Sha256", valid_594596
  var valid_594597 = header.getOrDefault("X-Amz-Algorithm")
  valid_594597 = validateParameter(valid_594597, JString, required = false,
                                 default = nil)
  if valid_594597 != nil:
    section.add "X-Amz-Algorithm", valid_594597
  var valid_594598 = header.getOrDefault("X-Amz-Signature")
  valid_594598 = validateParameter(valid_594598, JString, required = false,
                                 default = nil)
  if valid_594598 != nil:
    section.add "X-Amz-Signature", valid_594598
  var valid_594599 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594599 = validateParameter(valid_594599, JString, required = false,
                                 default = nil)
  if valid_594599 != nil:
    section.add "X-Amz-SignedHeaders", valid_594599
  var valid_594600 = header.getOrDefault("X-Amz-Credential")
  valid_594600 = validateParameter(valid_594600, JString, required = false,
                                 default = nil)
  if valid_594600 != nil:
    section.add "X-Amz-Credential", valid_594600
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594602: Call_DescribeInstancePatchStates_594590; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the high-level patch state of one or more instances.
  ## 
  let valid = call_594602.validator(path, query, header, formData, body)
  let scheme = call_594602.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594602.url(scheme.get, call_594602.host, call_594602.base,
                         call_594602.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594602, url, valid)

proc call*(call_594603: Call_DescribeInstancePatchStates_594590; body: JsonNode): Recallable =
  ## describeInstancePatchStates
  ## Retrieves the high-level patch state of one or more instances.
  ##   body: JObject (required)
  var body_594604 = newJObject()
  if body != nil:
    body_594604 = body
  result = call_594603.call(nil, nil, nil, nil, body_594604)

var describeInstancePatchStates* = Call_DescribeInstancePatchStates_594590(
    name: "describeInstancePatchStates", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeInstancePatchStates",
    validator: validate_DescribeInstancePatchStates_594591, base: "/",
    url: url_DescribeInstancePatchStates_594592,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeInstancePatchStatesForPatchGroup_594605 = ref object of OpenApiRestCall_593437
proc url_DescribeInstancePatchStatesForPatchGroup_594607(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeInstancePatchStatesForPatchGroup_594606(path: JsonNode;
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
  var valid_594608 = header.getOrDefault("X-Amz-Date")
  valid_594608 = validateParameter(valid_594608, JString, required = false,
                                 default = nil)
  if valid_594608 != nil:
    section.add "X-Amz-Date", valid_594608
  var valid_594609 = header.getOrDefault("X-Amz-Security-Token")
  valid_594609 = validateParameter(valid_594609, JString, required = false,
                                 default = nil)
  if valid_594609 != nil:
    section.add "X-Amz-Security-Token", valid_594609
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594610 = header.getOrDefault("X-Amz-Target")
  valid_594610 = validateParameter(valid_594610, JString, required = true, default = newJString(
      "AmazonSSM.DescribeInstancePatchStatesForPatchGroup"))
  if valid_594610 != nil:
    section.add "X-Amz-Target", valid_594610
  var valid_594611 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594611 = validateParameter(valid_594611, JString, required = false,
                                 default = nil)
  if valid_594611 != nil:
    section.add "X-Amz-Content-Sha256", valid_594611
  var valid_594612 = header.getOrDefault("X-Amz-Algorithm")
  valid_594612 = validateParameter(valid_594612, JString, required = false,
                                 default = nil)
  if valid_594612 != nil:
    section.add "X-Amz-Algorithm", valid_594612
  var valid_594613 = header.getOrDefault("X-Amz-Signature")
  valid_594613 = validateParameter(valid_594613, JString, required = false,
                                 default = nil)
  if valid_594613 != nil:
    section.add "X-Amz-Signature", valid_594613
  var valid_594614 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594614 = validateParameter(valid_594614, JString, required = false,
                                 default = nil)
  if valid_594614 != nil:
    section.add "X-Amz-SignedHeaders", valid_594614
  var valid_594615 = header.getOrDefault("X-Amz-Credential")
  valid_594615 = validateParameter(valid_594615, JString, required = false,
                                 default = nil)
  if valid_594615 != nil:
    section.add "X-Amz-Credential", valid_594615
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594617: Call_DescribeInstancePatchStatesForPatchGroup_594605;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves the high-level patch state for the instances in the specified patch group.
  ## 
  let valid = call_594617.validator(path, query, header, formData, body)
  let scheme = call_594617.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594617.url(scheme.get, call_594617.host, call_594617.base,
                         call_594617.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594617, url, valid)

proc call*(call_594618: Call_DescribeInstancePatchStatesForPatchGroup_594605;
          body: JsonNode): Recallable =
  ## describeInstancePatchStatesForPatchGroup
  ## Retrieves the high-level patch state for the instances in the specified patch group.
  ##   body: JObject (required)
  var body_594619 = newJObject()
  if body != nil:
    body_594619 = body
  result = call_594618.call(nil, nil, nil, nil, body_594619)

var describeInstancePatchStatesForPatchGroup* = Call_DescribeInstancePatchStatesForPatchGroup_594605(
    name: "describeInstancePatchStatesForPatchGroup", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeInstancePatchStatesForPatchGroup",
    validator: validate_DescribeInstancePatchStatesForPatchGroup_594606,
    base: "/", url: url_DescribeInstancePatchStatesForPatchGroup_594607,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeInstancePatches_594620 = ref object of OpenApiRestCall_593437
proc url_DescribeInstancePatches_594622(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeInstancePatches_594621(path: JsonNode; query: JsonNode;
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
  var valid_594623 = header.getOrDefault("X-Amz-Date")
  valid_594623 = validateParameter(valid_594623, JString, required = false,
                                 default = nil)
  if valid_594623 != nil:
    section.add "X-Amz-Date", valid_594623
  var valid_594624 = header.getOrDefault("X-Amz-Security-Token")
  valid_594624 = validateParameter(valid_594624, JString, required = false,
                                 default = nil)
  if valid_594624 != nil:
    section.add "X-Amz-Security-Token", valid_594624
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594625 = header.getOrDefault("X-Amz-Target")
  valid_594625 = validateParameter(valid_594625, JString, required = true, default = newJString(
      "AmazonSSM.DescribeInstancePatches"))
  if valid_594625 != nil:
    section.add "X-Amz-Target", valid_594625
  var valid_594626 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594626 = validateParameter(valid_594626, JString, required = false,
                                 default = nil)
  if valid_594626 != nil:
    section.add "X-Amz-Content-Sha256", valid_594626
  var valid_594627 = header.getOrDefault("X-Amz-Algorithm")
  valid_594627 = validateParameter(valid_594627, JString, required = false,
                                 default = nil)
  if valid_594627 != nil:
    section.add "X-Amz-Algorithm", valid_594627
  var valid_594628 = header.getOrDefault("X-Amz-Signature")
  valid_594628 = validateParameter(valid_594628, JString, required = false,
                                 default = nil)
  if valid_594628 != nil:
    section.add "X-Amz-Signature", valid_594628
  var valid_594629 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594629 = validateParameter(valid_594629, JString, required = false,
                                 default = nil)
  if valid_594629 != nil:
    section.add "X-Amz-SignedHeaders", valid_594629
  var valid_594630 = header.getOrDefault("X-Amz-Credential")
  valid_594630 = validateParameter(valid_594630, JString, required = false,
                                 default = nil)
  if valid_594630 != nil:
    section.add "X-Amz-Credential", valid_594630
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594632: Call_DescribeInstancePatches_594620; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the patches on the specified instance and their state relative to the patch baseline being used for the instance.
  ## 
  let valid = call_594632.validator(path, query, header, formData, body)
  let scheme = call_594632.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594632.url(scheme.get, call_594632.host, call_594632.base,
                         call_594632.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594632, url, valid)

proc call*(call_594633: Call_DescribeInstancePatches_594620; body: JsonNode): Recallable =
  ## describeInstancePatches
  ## Retrieves information about the patches on the specified instance and their state relative to the patch baseline being used for the instance.
  ##   body: JObject (required)
  var body_594634 = newJObject()
  if body != nil:
    body_594634 = body
  result = call_594633.call(nil, nil, nil, nil, body_594634)

var describeInstancePatches* = Call_DescribeInstancePatches_594620(
    name: "describeInstancePatches", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeInstancePatches",
    validator: validate_DescribeInstancePatches_594621, base: "/",
    url: url_DescribeInstancePatches_594622, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeInventoryDeletions_594635 = ref object of OpenApiRestCall_593437
proc url_DescribeInventoryDeletions_594637(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeInventoryDeletions_594636(path: JsonNode; query: JsonNode;
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
  var valid_594638 = header.getOrDefault("X-Amz-Date")
  valid_594638 = validateParameter(valid_594638, JString, required = false,
                                 default = nil)
  if valid_594638 != nil:
    section.add "X-Amz-Date", valid_594638
  var valid_594639 = header.getOrDefault("X-Amz-Security-Token")
  valid_594639 = validateParameter(valid_594639, JString, required = false,
                                 default = nil)
  if valid_594639 != nil:
    section.add "X-Amz-Security-Token", valid_594639
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594640 = header.getOrDefault("X-Amz-Target")
  valid_594640 = validateParameter(valid_594640, JString, required = true, default = newJString(
      "AmazonSSM.DescribeInventoryDeletions"))
  if valid_594640 != nil:
    section.add "X-Amz-Target", valid_594640
  var valid_594641 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594641 = validateParameter(valid_594641, JString, required = false,
                                 default = nil)
  if valid_594641 != nil:
    section.add "X-Amz-Content-Sha256", valid_594641
  var valid_594642 = header.getOrDefault("X-Amz-Algorithm")
  valid_594642 = validateParameter(valid_594642, JString, required = false,
                                 default = nil)
  if valid_594642 != nil:
    section.add "X-Amz-Algorithm", valid_594642
  var valid_594643 = header.getOrDefault("X-Amz-Signature")
  valid_594643 = validateParameter(valid_594643, JString, required = false,
                                 default = nil)
  if valid_594643 != nil:
    section.add "X-Amz-Signature", valid_594643
  var valid_594644 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594644 = validateParameter(valid_594644, JString, required = false,
                                 default = nil)
  if valid_594644 != nil:
    section.add "X-Amz-SignedHeaders", valid_594644
  var valid_594645 = header.getOrDefault("X-Amz-Credential")
  valid_594645 = validateParameter(valid_594645, JString, required = false,
                                 default = nil)
  if valid_594645 != nil:
    section.add "X-Amz-Credential", valid_594645
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594647: Call_DescribeInventoryDeletions_594635; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes a specific delete inventory operation.
  ## 
  let valid = call_594647.validator(path, query, header, formData, body)
  let scheme = call_594647.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594647.url(scheme.get, call_594647.host, call_594647.base,
                         call_594647.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594647, url, valid)

proc call*(call_594648: Call_DescribeInventoryDeletions_594635; body: JsonNode): Recallable =
  ## describeInventoryDeletions
  ## Describes a specific delete inventory operation.
  ##   body: JObject (required)
  var body_594649 = newJObject()
  if body != nil:
    body_594649 = body
  result = call_594648.call(nil, nil, nil, nil, body_594649)

var describeInventoryDeletions* = Call_DescribeInventoryDeletions_594635(
    name: "describeInventoryDeletions", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeInventoryDeletions",
    validator: validate_DescribeInventoryDeletions_594636, base: "/",
    url: url_DescribeInventoryDeletions_594637,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeMaintenanceWindowExecutionTaskInvocations_594650 = ref object of OpenApiRestCall_593437
proc url_DescribeMaintenanceWindowExecutionTaskInvocations_594652(
    protocol: Scheme; host: string; base: string; route: string; path: JsonNode;
    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeMaintenanceWindowExecutionTaskInvocations_594651(
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
  var valid_594653 = header.getOrDefault("X-Amz-Date")
  valid_594653 = validateParameter(valid_594653, JString, required = false,
                                 default = nil)
  if valid_594653 != nil:
    section.add "X-Amz-Date", valid_594653
  var valid_594654 = header.getOrDefault("X-Amz-Security-Token")
  valid_594654 = validateParameter(valid_594654, JString, required = false,
                                 default = nil)
  if valid_594654 != nil:
    section.add "X-Amz-Security-Token", valid_594654
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594655 = header.getOrDefault("X-Amz-Target")
  valid_594655 = validateParameter(valid_594655, JString, required = true, default = newJString(
      "AmazonSSM.DescribeMaintenanceWindowExecutionTaskInvocations"))
  if valid_594655 != nil:
    section.add "X-Amz-Target", valid_594655
  var valid_594656 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594656 = validateParameter(valid_594656, JString, required = false,
                                 default = nil)
  if valid_594656 != nil:
    section.add "X-Amz-Content-Sha256", valid_594656
  var valid_594657 = header.getOrDefault("X-Amz-Algorithm")
  valid_594657 = validateParameter(valid_594657, JString, required = false,
                                 default = nil)
  if valid_594657 != nil:
    section.add "X-Amz-Algorithm", valid_594657
  var valid_594658 = header.getOrDefault("X-Amz-Signature")
  valid_594658 = validateParameter(valid_594658, JString, required = false,
                                 default = nil)
  if valid_594658 != nil:
    section.add "X-Amz-Signature", valid_594658
  var valid_594659 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594659 = validateParameter(valid_594659, JString, required = false,
                                 default = nil)
  if valid_594659 != nil:
    section.add "X-Amz-SignedHeaders", valid_594659
  var valid_594660 = header.getOrDefault("X-Amz-Credential")
  valid_594660 = validateParameter(valid_594660, JString, required = false,
                                 default = nil)
  if valid_594660 != nil:
    section.add "X-Amz-Credential", valid_594660
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594662: Call_DescribeMaintenanceWindowExecutionTaskInvocations_594650;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves the individual task executions (one per target) for a particular task run as part of a maintenance window execution.
  ## 
  let valid = call_594662.validator(path, query, header, formData, body)
  let scheme = call_594662.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594662.url(scheme.get, call_594662.host, call_594662.base,
                         call_594662.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594662, url, valid)

proc call*(call_594663: Call_DescribeMaintenanceWindowExecutionTaskInvocations_594650;
          body: JsonNode): Recallable =
  ## describeMaintenanceWindowExecutionTaskInvocations
  ## Retrieves the individual task executions (one per target) for a particular task run as part of a maintenance window execution.
  ##   body: JObject (required)
  var body_594664 = newJObject()
  if body != nil:
    body_594664 = body
  result = call_594663.call(nil, nil, nil, nil, body_594664)

var describeMaintenanceWindowExecutionTaskInvocations* = Call_DescribeMaintenanceWindowExecutionTaskInvocations_594650(
    name: "describeMaintenanceWindowExecutionTaskInvocations",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com", route: "/#X-Amz-Target=AmazonSSM.DescribeMaintenanceWindowExecutionTaskInvocations",
    validator: validate_DescribeMaintenanceWindowExecutionTaskInvocations_594651,
    base: "/", url: url_DescribeMaintenanceWindowExecutionTaskInvocations_594652,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeMaintenanceWindowExecutionTasks_594665 = ref object of OpenApiRestCall_593437
proc url_DescribeMaintenanceWindowExecutionTasks_594667(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeMaintenanceWindowExecutionTasks_594666(path: JsonNode;
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
  var valid_594668 = header.getOrDefault("X-Amz-Date")
  valid_594668 = validateParameter(valid_594668, JString, required = false,
                                 default = nil)
  if valid_594668 != nil:
    section.add "X-Amz-Date", valid_594668
  var valid_594669 = header.getOrDefault("X-Amz-Security-Token")
  valid_594669 = validateParameter(valid_594669, JString, required = false,
                                 default = nil)
  if valid_594669 != nil:
    section.add "X-Amz-Security-Token", valid_594669
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594670 = header.getOrDefault("X-Amz-Target")
  valid_594670 = validateParameter(valid_594670, JString, required = true, default = newJString(
      "AmazonSSM.DescribeMaintenanceWindowExecutionTasks"))
  if valid_594670 != nil:
    section.add "X-Amz-Target", valid_594670
  var valid_594671 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594671 = validateParameter(valid_594671, JString, required = false,
                                 default = nil)
  if valid_594671 != nil:
    section.add "X-Amz-Content-Sha256", valid_594671
  var valid_594672 = header.getOrDefault("X-Amz-Algorithm")
  valid_594672 = validateParameter(valid_594672, JString, required = false,
                                 default = nil)
  if valid_594672 != nil:
    section.add "X-Amz-Algorithm", valid_594672
  var valid_594673 = header.getOrDefault("X-Amz-Signature")
  valid_594673 = validateParameter(valid_594673, JString, required = false,
                                 default = nil)
  if valid_594673 != nil:
    section.add "X-Amz-Signature", valid_594673
  var valid_594674 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594674 = validateParameter(valid_594674, JString, required = false,
                                 default = nil)
  if valid_594674 != nil:
    section.add "X-Amz-SignedHeaders", valid_594674
  var valid_594675 = header.getOrDefault("X-Amz-Credential")
  valid_594675 = validateParameter(valid_594675, JString, required = false,
                                 default = nil)
  if valid_594675 != nil:
    section.add "X-Amz-Credential", valid_594675
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594677: Call_DescribeMaintenanceWindowExecutionTasks_594665;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## For a given maintenance window execution, lists the tasks that were run.
  ## 
  let valid = call_594677.validator(path, query, header, formData, body)
  let scheme = call_594677.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594677.url(scheme.get, call_594677.host, call_594677.base,
                         call_594677.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594677, url, valid)

proc call*(call_594678: Call_DescribeMaintenanceWindowExecutionTasks_594665;
          body: JsonNode): Recallable =
  ## describeMaintenanceWindowExecutionTasks
  ## For a given maintenance window execution, lists the tasks that were run.
  ##   body: JObject (required)
  var body_594679 = newJObject()
  if body != nil:
    body_594679 = body
  result = call_594678.call(nil, nil, nil, nil, body_594679)

var describeMaintenanceWindowExecutionTasks* = Call_DescribeMaintenanceWindowExecutionTasks_594665(
    name: "describeMaintenanceWindowExecutionTasks", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeMaintenanceWindowExecutionTasks",
    validator: validate_DescribeMaintenanceWindowExecutionTasks_594666, base: "/",
    url: url_DescribeMaintenanceWindowExecutionTasks_594667,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeMaintenanceWindowExecutions_594680 = ref object of OpenApiRestCall_593437
proc url_DescribeMaintenanceWindowExecutions_594682(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeMaintenanceWindowExecutions_594681(path: JsonNode;
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
  var valid_594683 = header.getOrDefault("X-Amz-Date")
  valid_594683 = validateParameter(valid_594683, JString, required = false,
                                 default = nil)
  if valid_594683 != nil:
    section.add "X-Amz-Date", valid_594683
  var valid_594684 = header.getOrDefault("X-Amz-Security-Token")
  valid_594684 = validateParameter(valid_594684, JString, required = false,
                                 default = nil)
  if valid_594684 != nil:
    section.add "X-Amz-Security-Token", valid_594684
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594685 = header.getOrDefault("X-Amz-Target")
  valid_594685 = validateParameter(valid_594685, JString, required = true, default = newJString(
      "AmazonSSM.DescribeMaintenanceWindowExecutions"))
  if valid_594685 != nil:
    section.add "X-Amz-Target", valid_594685
  var valid_594686 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594686 = validateParameter(valid_594686, JString, required = false,
                                 default = nil)
  if valid_594686 != nil:
    section.add "X-Amz-Content-Sha256", valid_594686
  var valid_594687 = header.getOrDefault("X-Amz-Algorithm")
  valid_594687 = validateParameter(valid_594687, JString, required = false,
                                 default = nil)
  if valid_594687 != nil:
    section.add "X-Amz-Algorithm", valid_594687
  var valid_594688 = header.getOrDefault("X-Amz-Signature")
  valid_594688 = validateParameter(valid_594688, JString, required = false,
                                 default = nil)
  if valid_594688 != nil:
    section.add "X-Amz-Signature", valid_594688
  var valid_594689 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594689 = validateParameter(valid_594689, JString, required = false,
                                 default = nil)
  if valid_594689 != nil:
    section.add "X-Amz-SignedHeaders", valid_594689
  var valid_594690 = header.getOrDefault("X-Amz-Credential")
  valid_594690 = validateParameter(valid_594690, JString, required = false,
                                 default = nil)
  if valid_594690 != nil:
    section.add "X-Amz-Credential", valid_594690
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594692: Call_DescribeMaintenanceWindowExecutions_594680;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists the executions of a maintenance window. This includes information about when the maintenance window was scheduled to be active, and information about tasks registered and run with the maintenance window.
  ## 
  let valid = call_594692.validator(path, query, header, formData, body)
  let scheme = call_594692.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594692.url(scheme.get, call_594692.host, call_594692.base,
                         call_594692.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594692, url, valid)

proc call*(call_594693: Call_DescribeMaintenanceWindowExecutions_594680;
          body: JsonNode): Recallable =
  ## describeMaintenanceWindowExecutions
  ## Lists the executions of a maintenance window. This includes information about when the maintenance window was scheduled to be active, and information about tasks registered and run with the maintenance window.
  ##   body: JObject (required)
  var body_594694 = newJObject()
  if body != nil:
    body_594694 = body
  result = call_594693.call(nil, nil, nil, nil, body_594694)

var describeMaintenanceWindowExecutions* = Call_DescribeMaintenanceWindowExecutions_594680(
    name: "describeMaintenanceWindowExecutions", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeMaintenanceWindowExecutions",
    validator: validate_DescribeMaintenanceWindowExecutions_594681, base: "/",
    url: url_DescribeMaintenanceWindowExecutions_594682,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeMaintenanceWindowSchedule_594695 = ref object of OpenApiRestCall_593437
proc url_DescribeMaintenanceWindowSchedule_594697(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeMaintenanceWindowSchedule_594696(path: JsonNode;
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
  var valid_594698 = header.getOrDefault("X-Amz-Date")
  valid_594698 = validateParameter(valid_594698, JString, required = false,
                                 default = nil)
  if valid_594698 != nil:
    section.add "X-Amz-Date", valid_594698
  var valid_594699 = header.getOrDefault("X-Amz-Security-Token")
  valid_594699 = validateParameter(valid_594699, JString, required = false,
                                 default = nil)
  if valid_594699 != nil:
    section.add "X-Amz-Security-Token", valid_594699
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594700 = header.getOrDefault("X-Amz-Target")
  valid_594700 = validateParameter(valid_594700, JString, required = true, default = newJString(
      "AmazonSSM.DescribeMaintenanceWindowSchedule"))
  if valid_594700 != nil:
    section.add "X-Amz-Target", valid_594700
  var valid_594701 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594701 = validateParameter(valid_594701, JString, required = false,
                                 default = nil)
  if valid_594701 != nil:
    section.add "X-Amz-Content-Sha256", valid_594701
  var valid_594702 = header.getOrDefault("X-Amz-Algorithm")
  valid_594702 = validateParameter(valid_594702, JString, required = false,
                                 default = nil)
  if valid_594702 != nil:
    section.add "X-Amz-Algorithm", valid_594702
  var valid_594703 = header.getOrDefault("X-Amz-Signature")
  valid_594703 = validateParameter(valid_594703, JString, required = false,
                                 default = nil)
  if valid_594703 != nil:
    section.add "X-Amz-Signature", valid_594703
  var valid_594704 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594704 = validateParameter(valid_594704, JString, required = false,
                                 default = nil)
  if valid_594704 != nil:
    section.add "X-Amz-SignedHeaders", valid_594704
  var valid_594705 = header.getOrDefault("X-Amz-Credential")
  valid_594705 = validateParameter(valid_594705, JString, required = false,
                                 default = nil)
  if valid_594705 != nil:
    section.add "X-Amz-Credential", valid_594705
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594707: Call_DescribeMaintenanceWindowSchedule_594695;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves information about upcoming executions of a maintenance window.
  ## 
  let valid = call_594707.validator(path, query, header, formData, body)
  let scheme = call_594707.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594707.url(scheme.get, call_594707.host, call_594707.base,
                         call_594707.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594707, url, valid)

proc call*(call_594708: Call_DescribeMaintenanceWindowSchedule_594695;
          body: JsonNode): Recallable =
  ## describeMaintenanceWindowSchedule
  ## Retrieves information about upcoming executions of a maintenance window.
  ##   body: JObject (required)
  var body_594709 = newJObject()
  if body != nil:
    body_594709 = body
  result = call_594708.call(nil, nil, nil, nil, body_594709)

var describeMaintenanceWindowSchedule* = Call_DescribeMaintenanceWindowSchedule_594695(
    name: "describeMaintenanceWindowSchedule", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeMaintenanceWindowSchedule",
    validator: validate_DescribeMaintenanceWindowSchedule_594696, base: "/",
    url: url_DescribeMaintenanceWindowSchedule_594697,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeMaintenanceWindowTargets_594710 = ref object of OpenApiRestCall_593437
proc url_DescribeMaintenanceWindowTargets_594712(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeMaintenanceWindowTargets_594711(path: JsonNode;
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
  var valid_594713 = header.getOrDefault("X-Amz-Date")
  valid_594713 = validateParameter(valid_594713, JString, required = false,
                                 default = nil)
  if valid_594713 != nil:
    section.add "X-Amz-Date", valid_594713
  var valid_594714 = header.getOrDefault("X-Amz-Security-Token")
  valid_594714 = validateParameter(valid_594714, JString, required = false,
                                 default = nil)
  if valid_594714 != nil:
    section.add "X-Amz-Security-Token", valid_594714
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594715 = header.getOrDefault("X-Amz-Target")
  valid_594715 = validateParameter(valid_594715, JString, required = true, default = newJString(
      "AmazonSSM.DescribeMaintenanceWindowTargets"))
  if valid_594715 != nil:
    section.add "X-Amz-Target", valid_594715
  var valid_594716 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594716 = validateParameter(valid_594716, JString, required = false,
                                 default = nil)
  if valid_594716 != nil:
    section.add "X-Amz-Content-Sha256", valid_594716
  var valid_594717 = header.getOrDefault("X-Amz-Algorithm")
  valid_594717 = validateParameter(valid_594717, JString, required = false,
                                 default = nil)
  if valid_594717 != nil:
    section.add "X-Amz-Algorithm", valid_594717
  var valid_594718 = header.getOrDefault("X-Amz-Signature")
  valid_594718 = validateParameter(valid_594718, JString, required = false,
                                 default = nil)
  if valid_594718 != nil:
    section.add "X-Amz-Signature", valid_594718
  var valid_594719 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594719 = validateParameter(valid_594719, JString, required = false,
                                 default = nil)
  if valid_594719 != nil:
    section.add "X-Amz-SignedHeaders", valid_594719
  var valid_594720 = header.getOrDefault("X-Amz-Credential")
  valid_594720 = validateParameter(valid_594720, JString, required = false,
                                 default = nil)
  if valid_594720 != nil:
    section.add "X-Amz-Credential", valid_594720
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594722: Call_DescribeMaintenanceWindowTargets_594710;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists the targets registered with the maintenance window.
  ## 
  let valid = call_594722.validator(path, query, header, formData, body)
  let scheme = call_594722.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594722.url(scheme.get, call_594722.host, call_594722.base,
                         call_594722.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594722, url, valid)

proc call*(call_594723: Call_DescribeMaintenanceWindowTargets_594710;
          body: JsonNode): Recallable =
  ## describeMaintenanceWindowTargets
  ## Lists the targets registered with the maintenance window.
  ##   body: JObject (required)
  var body_594724 = newJObject()
  if body != nil:
    body_594724 = body
  result = call_594723.call(nil, nil, nil, nil, body_594724)

var describeMaintenanceWindowTargets* = Call_DescribeMaintenanceWindowTargets_594710(
    name: "describeMaintenanceWindowTargets", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeMaintenanceWindowTargets",
    validator: validate_DescribeMaintenanceWindowTargets_594711, base: "/",
    url: url_DescribeMaintenanceWindowTargets_594712,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeMaintenanceWindowTasks_594725 = ref object of OpenApiRestCall_593437
proc url_DescribeMaintenanceWindowTasks_594727(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeMaintenanceWindowTasks_594726(path: JsonNode;
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
  var valid_594728 = header.getOrDefault("X-Amz-Date")
  valid_594728 = validateParameter(valid_594728, JString, required = false,
                                 default = nil)
  if valid_594728 != nil:
    section.add "X-Amz-Date", valid_594728
  var valid_594729 = header.getOrDefault("X-Amz-Security-Token")
  valid_594729 = validateParameter(valid_594729, JString, required = false,
                                 default = nil)
  if valid_594729 != nil:
    section.add "X-Amz-Security-Token", valid_594729
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594730 = header.getOrDefault("X-Amz-Target")
  valid_594730 = validateParameter(valid_594730, JString, required = true, default = newJString(
      "AmazonSSM.DescribeMaintenanceWindowTasks"))
  if valid_594730 != nil:
    section.add "X-Amz-Target", valid_594730
  var valid_594731 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594731 = validateParameter(valid_594731, JString, required = false,
                                 default = nil)
  if valid_594731 != nil:
    section.add "X-Amz-Content-Sha256", valid_594731
  var valid_594732 = header.getOrDefault("X-Amz-Algorithm")
  valid_594732 = validateParameter(valid_594732, JString, required = false,
                                 default = nil)
  if valid_594732 != nil:
    section.add "X-Amz-Algorithm", valid_594732
  var valid_594733 = header.getOrDefault("X-Amz-Signature")
  valid_594733 = validateParameter(valid_594733, JString, required = false,
                                 default = nil)
  if valid_594733 != nil:
    section.add "X-Amz-Signature", valid_594733
  var valid_594734 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594734 = validateParameter(valid_594734, JString, required = false,
                                 default = nil)
  if valid_594734 != nil:
    section.add "X-Amz-SignedHeaders", valid_594734
  var valid_594735 = header.getOrDefault("X-Amz-Credential")
  valid_594735 = validateParameter(valid_594735, JString, required = false,
                                 default = nil)
  if valid_594735 != nil:
    section.add "X-Amz-Credential", valid_594735
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594737: Call_DescribeMaintenanceWindowTasks_594725; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the tasks in a maintenance window.
  ## 
  let valid = call_594737.validator(path, query, header, formData, body)
  let scheme = call_594737.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594737.url(scheme.get, call_594737.host, call_594737.base,
                         call_594737.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594737, url, valid)

proc call*(call_594738: Call_DescribeMaintenanceWindowTasks_594725; body: JsonNode): Recallable =
  ## describeMaintenanceWindowTasks
  ## Lists the tasks in a maintenance window.
  ##   body: JObject (required)
  var body_594739 = newJObject()
  if body != nil:
    body_594739 = body
  result = call_594738.call(nil, nil, nil, nil, body_594739)

var describeMaintenanceWindowTasks* = Call_DescribeMaintenanceWindowTasks_594725(
    name: "describeMaintenanceWindowTasks", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeMaintenanceWindowTasks",
    validator: validate_DescribeMaintenanceWindowTasks_594726, base: "/",
    url: url_DescribeMaintenanceWindowTasks_594727,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeMaintenanceWindows_594740 = ref object of OpenApiRestCall_593437
proc url_DescribeMaintenanceWindows_594742(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeMaintenanceWindows_594741(path: JsonNode; query: JsonNode;
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
  var valid_594743 = header.getOrDefault("X-Amz-Date")
  valid_594743 = validateParameter(valid_594743, JString, required = false,
                                 default = nil)
  if valid_594743 != nil:
    section.add "X-Amz-Date", valid_594743
  var valid_594744 = header.getOrDefault("X-Amz-Security-Token")
  valid_594744 = validateParameter(valid_594744, JString, required = false,
                                 default = nil)
  if valid_594744 != nil:
    section.add "X-Amz-Security-Token", valid_594744
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594745 = header.getOrDefault("X-Amz-Target")
  valid_594745 = validateParameter(valid_594745, JString, required = true, default = newJString(
      "AmazonSSM.DescribeMaintenanceWindows"))
  if valid_594745 != nil:
    section.add "X-Amz-Target", valid_594745
  var valid_594746 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594746 = validateParameter(valid_594746, JString, required = false,
                                 default = nil)
  if valid_594746 != nil:
    section.add "X-Amz-Content-Sha256", valid_594746
  var valid_594747 = header.getOrDefault("X-Amz-Algorithm")
  valid_594747 = validateParameter(valid_594747, JString, required = false,
                                 default = nil)
  if valid_594747 != nil:
    section.add "X-Amz-Algorithm", valid_594747
  var valid_594748 = header.getOrDefault("X-Amz-Signature")
  valid_594748 = validateParameter(valid_594748, JString, required = false,
                                 default = nil)
  if valid_594748 != nil:
    section.add "X-Amz-Signature", valid_594748
  var valid_594749 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594749 = validateParameter(valid_594749, JString, required = false,
                                 default = nil)
  if valid_594749 != nil:
    section.add "X-Amz-SignedHeaders", valid_594749
  var valid_594750 = header.getOrDefault("X-Amz-Credential")
  valid_594750 = validateParameter(valid_594750, JString, required = false,
                                 default = nil)
  if valid_594750 != nil:
    section.add "X-Amz-Credential", valid_594750
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594752: Call_DescribeMaintenanceWindows_594740; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the maintenance windows in an AWS account.
  ## 
  let valid = call_594752.validator(path, query, header, formData, body)
  let scheme = call_594752.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594752.url(scheme.get, call_594752.host, call_594752.base,
                         call_594752.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594752, url, valid)

proc call*(call_594753: Call_DescribeMaintenanceWindows_594740; body: JsonNode): Recallable =
  ## describeMaintenanceWindows
  ## Retrieves the maintenance windows in an AWS account.
  ##   body: JObject (required)
  var body_594754 = newJObject()
  if body != nil:
    body_594754 = body
  result = call_594753.call(nil, nil, nil, nil, body_594754)

var describeMaintenanceWindows* = Call_DescribeMaintenanceWindows_594740(
    name: "describeMaintenanceWindows", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeMaintenanceWindows",
    validator: validate_DescribeMaintenanceWindows_594741, base: "/",
    url: url_DescribeMaintenanceWindows_594742,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeMaintenanceWindowsForTarget_594755 = ref object of OpenApiRestCall_593437
proc url_DescribeMaintenanceWindowsForTarget_594757(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeMaintenanceWindowsForTarget_594756(path: JsonNode;
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
  var valid_594758 = header.getOrDefault("X-Amz-Date")
  valid_594758 = validateParameter(valid_594758, JString, required = false,
                                 default = nil)
  if valid_594758 != nil:
    section.add "X-Amz-Date", valid_594758
  var valid_594759 = header.getOrDefault("X-Amz-Security-Token")
  valid_594759 = validateParameter(valid_594759, JString, required = false,
                                 default = nil)
  if valid_594759 != nil:
    section.add "X-Amz-Security-Token", valid_594759
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594760 = header.getOrDefault("X-Amz-Target")
  valid_594760 = validateParameter(valid_594760, JString, required = true, default = newJString(
      "AmazonSSM.DescribeMaintenanceWindowsForTarget"))
  if valid_594760 != nil:
    section.add "X-Amz-Target", valid_594760
  var valid_594761 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594761 = validateParameter(valid_594761, JString, required = false,
                                 default = nil)
  if valid_594761 != nil:
    section.add "X-Amz-Content-Sha256", valid_594761
  var valid_594762 = header.getOrDefault("X-Amz-Algorithm")
  valid_594762 = validateParameter(valid_594762, JString, required = false,
                                 default = nil)
  if valid_594762 != nil:
    section.add "X-Amz-Algorithm", valid_594762
  var valid_594763 = header.getOrDefault("X-Amz-Signature")
  valid_594763 = validateParameter(valid_594763, JString, required = false,
                                 default = nil)
  if valid_594763 != nil:
    section.add "X-Amz-Signature", valid_594763
  var valid_594764 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594764 = validateParameter(valid_594764, JString, required = false,
                                 default = nil)
  if valid_594764 != nil:
    section.add "X-Amz-SignedHeaders", valid_594764
  var valid_594765 = header.getOrDefault("X-Amz-Credential")
  valid_594765 = validateParameter(valid_594765, JString, required = false,
                                 default = nil)
  if valid_594765 != nil:
    section.add "X-Amz-Credential", valid_594765
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594767: Call_DescribeMaintenanceWindowsForTarget_594755;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves information about the maintenance window targets or tasks that an instance is associated with.
  ## 
  let valid = call_594767.validator(path, query, header, formData, body)
  let scheme = call_594767.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594767.url(scheme.get, call_594767.host, call_594767.base,
                         call_594767.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594767, url, valid)

proc call*(call_594768: Call_DescribeMaintenanceWindowsForTarget_594755;
          body: JsonNode): Recallable =
  ## describeMaintenanceWindowsForTarget
  ## Retrieves information about the maintenance window targets or tasks that an instance is associated with.
  ##   body: JObject (required)
  var body_594769 = newJObject()
  if body != nil:
    body_594769 = body
  result = call_594768.call(nil, nil, nil, nil, body_594769)

var describeMaintenanceWindowsForTarget* = Call_DescribeMaintenanceWindowsForTarget_594755(
    name: "describeMaintenanceWindowsForTarget", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeMaintenanceWindowsForTarget",
    validator: validate_DescribeMaintenanceWindowsForTarget_594756, base: "/",
    url: url_DescribeMaintenanceWindowsForTarget_594757,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeOpsItems_594770 = ref object of OpenApiRestCall_593437
proc url_DescribeOpsItems_594772(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeOpsItems_594771(path: JsonNode; query: JsonNode;
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
  var valid_594773 = header.getOrDefault("X-Amz-Date")
  valid_594773 = validateParameter(valid_594773, JString, required = false,
                                 default = nil)
  if valid_594773 != nil:
    section.add "X-Amz-Date", valid_594773
  var valid_594774 = header.getOrDefault("X-Amz-Security-Token")
  valid_594774 = validateParameter(valid_594774, JString, required = false,
                                 default = nil)
  if valid_594774 != nil:
    section.add "X-Amz-Security-Token", valid_594774
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594775 = header.getOrDefault("X-Amz-Target")
  valid_594775 = validateParameter(valid_594775, JString, required = true, default = newJString(
      "AmazonSSM.DescribeOpsItems"))
  if valid_594775 != nil:
    section.add "X-Amz-Target", valid_594775
  var valid_594776 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594776 = validateParameter(valid_594776, JString, required = false,
                                 default = nil)
  if valid_594776 != nil:
    section.add "X-Amz-Content-Sha256", valid_594776
  var valid_594777 = header.getOrDefault("X-Amz-Algorithm")
  valid_594777 = validateParameter(valid_594777, JString, required = false,
                                 default = nil)
  if valid_594777 != nil:
    section.add "X-Amz-Algorithm", valid_594777
  var valid_594778 = header.getOrDefault("X-Amz-Signature")
  valid_594778 = validateParameter(valid_594778, JString, required = false,
                                 default = nil)
  if valid_594778 != nil:
    section.add "X-Amz-Signature", valid_594778
  var valid_594779 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594779 = validateParameter(valid_594779, JString, required = false,
                                 default = nil)
  if valid_594779 != nil:
    section.add "X-Amz-SignedHeaders", valid_594779
  var valid_594780 = header.getOrDefault("X-Amz-Credential")
  valid_594780 = validateParameter(valid_594780, JString, required = false,
                                 default = nil)
  if valid_594780 != nil:
    section.add "X-Amz-Credential", valid_594780
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594782: Call_DescribeOpsItems_594770; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Query a set of OpsItems. You must have permission in AWS Identity and Access Management (IAM) to query a list of OpsItems. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter-getting-started.html">Getting Started with OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>.</p> <p>Operations engineers and IT professionals use OpsCenter to view, investigate, and remediate operational issues impacting the performance and health of their AWS resources. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter.html">AWS Systems Manager OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>. </p>
  ## 
  let valid = call_594782.validator(path, query, header, formData, body)
  let scheme = call_594782.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594782.url(scheme.get, call_594782.host, call_594782.base,
                         call_594782.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594782, url, valid)

proc call*(call_594783: Call_DescribeOpsItems_594770; body: JsonNode): Recallable =
  ## describeOpsItems
  ## <p>Query a set of OpsItems. You must have permission in AWS Identity and Access Management (IAM) to query a list of OpsItems. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter-getting-started.html">Getting Started with OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>.</p> <p>Operations engineers and IT professionals use OpsCenter to view, investigate, and remediate operational issues impacting the performance and health of their AWS resources. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter.html">AWS Systems Manager OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>. </p>
  ##   body: JObject (required)
  var body_594784 = newJObject()
  if body != nil:
    body_594784 = body
  result = call_594783.call(nil, nil, nil, nil, body_594784)

var describeOpsItems* = Call_DescribeOpsItems_594770(name: "describeOpsItems",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeOpsItems",
    validator: validate_DescribeOpsItems_594771, base: "/",
    url: url_DescribeOpsItems_594772, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeParameters_594785 = ref object of OpenApiRestCall_593437
proc url_DescribeParameters_594787(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeParameters_594786(path: JsonNode; query: JsonNode;
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
  var valid_594788 = query.getOrDefault("NextToken")
  valid_594788 = validateParameter(valid_594788, JString, required = false,
                                 default = nil)
  if valid_594788 != nil:
    section.add "NextToken", valid_594788
  var valid_594789 = query.getOrDefault("MaxResults")
  valid_594789 = validateParameter(valid_594789, JString, required = false,
                                 default = nil)
  if valid_594789 != nil:
    section.add "MaxResults", valid_594789
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
  var valid_594790 = header.getOrDefault("X-Amz-Date")
  valid_594790 = validateParameter(valid_594790, JString, required = false,
                                 default = nil)
  if valid_594790 != nil:
    section.add "X-Amz-Date", valid_594790
  var valid_594791 = header.getOrDefault("X-Amz-Security-Token")
  valid_594791 = validateParameter(valid_594791, JString, required = false,
                                 default = nil)
  if valid_594791 != nil:
    section.add "X-Amz-Security-Token", valid_594791
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594792 = header.getOrDefault("X-Amz-Target")
  valid_594792 = validateParameter(valid_594792, JString, required = true, default = newJString(
      "AmazonSSM.DescribeParameters"))
  if valid_594792 != nil:
    section.add "X-Amz-Target", valid_594792
  var valid_594793 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594793 = validateParameter(valid_594793, JString, required = false,
                                 default = nil)
  if valid_594793 != nil:
    section.add "X-Amz-Content-Sha256", valid_594793
  var valid_594794 = header.getOrDefault("X-Amz-Algorithm")
  valid_594794 = validateParameter(valid_594794, JString, required = false,
                                 default = nil)
  if valid_594794 != nil:
    section.add "X-Amz-Algorithm", valid_594794
  var valid_594795 = header.getOrDefault("X-Amz-Signature")
  valid_594795 = validateParameter(valid_594795, JString, required = false,
                                 default = nil)
  if valid_594795 != nil:
    section.add "X-Amz-Signature", valid_594795
  var valid_594796 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594796 = validateParameter(valid_594796, JString, required = false,
                                 default = nil)
  if valid_594796 != nil:
    section.add "X-Amz-SignedHeaders", valid_594796
  var valid_594797 = header.getOrDefault("X-Amz-Credential")
  valid_594797 = validateParameter(valid_594797, JString, required = false,
                                 default = nil)
  if valid_594797 != nil:
    section.add "X-Amz-Credential", valid_594797
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594799: Call_DescribeParameters_594785; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Get information about a parameter.</p> <p>Request results are returned on a best-effort basis. If you specify <code>MaxResults</code> in the request, the response includes information up to the limit specified. The number of items returned, however, can be between zero and the value of <code>MaxResults</code>. If the service reaches an internal limit while processing the results, it stops the operation and returns the matching values up to that point and a <code>NextToken</code>. You can specify the <code>NextToken</code> in a subsequent call to get the next set of results.</p>
  ## 
  let valid = call_594799.validator(path, query, header, formData, body)
  let scheme = call_594799.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594799.url(scheme.get, call_594799.host, call_594799.base,
                         call_594799.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594799, url, valid)

proc call*(call_594800: Call_DescribeParameters_594785; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## describeParameters
  ## <p>Get information about a parameter.</p> <p>Request results are returned on a best-effort basis. If you specify <code>MaxResults</code> in the request, the response includes information up to the limit specified. The number of items returned, however, can be between zero and the value of <code>MaxResults</code>. If the service reaches an internal limit while processing the results, it stops the operation and returns the matching values up to that point and a <code>NextToken</code>. You can specify the <code>NextToken</code> in a subsequent call to get the next set of results.</p>
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_594801 = newJObject()
  var body_594802 = newJObject()
  add(query_594801, "NextToken", newJString(NextToken))
  if body != nil:
    body_594802 = body
  add(query_594801, "MaxResults", newJString(MaxResults))
  result = call_594800.call(nil, query_594801, nil, nil, body_594802)

var describeParameters* = Call_DescribeParameters_594785(
    name: "describeParameters", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeParameters",
    validator: validate_DescribeParameters_594786, base: "/",
    url: url_DescribeParameters_594787, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribePatchBaselines_594803 = ref object of OpenApiRestCall_593437
proc url_DescribePatchBaselines_594805(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribePatchBaselines_594804(path: JsonNode; query: JsonNode;
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
  var valid_594806 = header.getOrDefault("X-Amz-Date")
  valid_594806 = validateParameter(valid_594806, JString, required = false,
                                 default = nil)
  if valid_594806 != nil:
    section.add "X-Amz-Date", valid_594806
  var valid_594807 = header.getOrDefault("X-Amz-Security-Token")
  valid_594807 = validateParameter(valid_594807, JString, required = false,
                                 default = nil)
  if valid_594807 != nil:
    section.add "X-Amz-Security-Token", valid_594807
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594808 = header.getOrDefault("X-Amz-Target")
  valid_594808 = validateParameter(valid_594808, JString, required = true, default = newJString(
      "AmazonSSM.DescribePatchBaselines"))
  if valid_594808 != nil:
    section.add "X-Amz-Target", valid_594808
  var valid_594809 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594809 = validateParameter(valid_594809, JString, required = false,
                                 default = nil)
  if valid_594809 != nil:
    section.add "X-Amz-Content-Sha256", valid_594809
  var valid_594810 = header.getOrDefault("X-Amz-Algorithm")
  valid_594810 = validateParameter(valid_594810, JString, required = false,
                                 default = nil)
  if valid_594810 != nil:
    section.add "X-Amz-Algorithm", valid_594810
  var valid_594811 = header.getOrDefault("X-Amz-Signature")
  valid_594811 = validateParameter(valid_594811, JString, required = false,
                                 default = nil)
  if valid_594811 != nil:
    section.add "X-Amz-Signature", valid_594811
  var valid_594812 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594812 = validateParameter(valid_594812, JString, required = false,
                                 default = nil)
  if valid_594812 != nil:
    section.add "X-Amz-SignedHeaders", valid_594812
  var valid_594813 = header.getOrDefault("X-Amz-Credential")
  valid_594813 = validateParameter(valid_594813, JString, required = false,
                                 default = nil)
  if valid_594813 != nil:
    section.add "X-Amz-Credential", valid_594813
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594815: Call_DescribePatchBaselines_594803; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the patch baselines in your AWS account.
  ## 
  let valid = call_594815.validator(path, query, header, formData, body)
  let scheme = call_594815.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594815.url(scheme.get, call_594815.host, call_594815.base,
                         call_594815.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594815, url, valid)

proc call*(call_594816: Call_DescribePatchBaselines_594803; body: JsonNode): Recallable =
  ## describePatchBaselines
  ## Lists the patch baselines in your AWS account.
  ##   body: JObject (required)
  var body_594817 = newJObject()
  if body != nil:
    body_594817 = body
  result = call_594816.call(nil, nil, nil, nil, body_594817)

var describePatchBaselines* = Call_DescribePatchBaselines_594803(
    name: "describePatchBaselines", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribePatchBaselines",
    validator: validate_DescribePatchBaselines_594804, base: "/",
    url: url_DescribePatchBaselines_594805, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribePatchGroupState_594818 = ref object of OpenApiRestCall_593437
proc url_DescribePatchGroupState_594820(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribePatchGroupState_594819(path: JsonNode; query: JsonNode;
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
  var valid_594821 = header.getOrDefault("X-Amz-Date")
  valid_594821 = validateParameter(valid_594821, JString, required = false,
                                 default = nil)
  if valid_594821 != nil:
    section.add "X-Amz-Date", valid_594821
  var valid_594822 = header.getOrDefault("X-Amz-Security-Token")
  valid_594822 = validateParameter(valid_594822, JString, required = false,
                                 default = nil)
  if valid_594822 != nil:
    section.add "X-Amz-Security-Token", valid_594822
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594823 = header.getOrDefault("X-Amz-Target")
  valid_594823 = validateParameter(valid_594823, JString, required = true, default = newJString(
      "AmazonSSM.DescribePatchGroupState"))
  if valid_594823 != nil:
    section.add "X-Amz-Target", valid_594823
  var valid_594824 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594824 = validateParameter(valid_594824, JString, required = false,
                                 default = nil)
  if valid_594824 != nil:
    section.add "X-Amz-Content-Sha256", valid_594824
  var valid_594825 = header.getOrDefault("X-Amz-Algorithm")
  valid_594825 = validateParameter(valid_594825, JString, required = false,
                                 default = nil)
  if valid_594825 != nil:
    section.add "X-Amz-Algorithm", valid_594825
  var valid_594826 = header.getOrDefault("X-Amz-Signature")
  valid_594826 = validateParameter(valid_594826, JString, required = false,
                                 default = nil)
  if valid_594826 != nil:
    section.add "X-Amz-Signature", valid_594826
  var valid_594827 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594827 = validateParameter(valid_594827, JString, required = false,
                                 default = nil)
  if valid_594827 != nil:
    section.add "X-Amz-SignedHeaders", valid_594827
  var valid_594828 = header.getOrDefault("X-Amz-Credential")
  valid_594828 = validateParameter(valid_594828, JString, required = false,
                                 default = nil)
  if valid_594828 != nil:
    section.add "X-Amz-Credential", valid_594828
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594830: Call_DescribePatchGroupState_594818; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns high-level aggregated patch compliance state for a patch group.
  ## 
  let valid = call_594830.validator(path, query, header, formData, body)
  let scheme = call_594830.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594830.url(scheme.get, call_594830.host, call_594830.base,
                         call_594830.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594830, url, valid)

proc call*(call_594831: Call_DescribePatchGroupState_594818; body: JsonNode): Recallable =
  ## describePatchGroupState
  ## Returns high-level aggregated patch compliance state for a patch group.
  ##   body: JObject (required)
  var body_594832 = newJObject()
  if body != nil:
    body_594832 = body
  result = call_594831.call(nil, nil, nil, nil, body_594832)

var describePatchGroupState* = Call_DescribePatchGroupState_594818(
    name: "describePatchGroupState", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribePatchGroupState",
    validator: validate_DescribePatchGroupState_594819, base: "/",
    url: url_DescribePatchGroupState_594820, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribePatchGroups_594833 = ref object of OpenApiRestCall_593437
proc url_DescribePatchGroups_594835(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribePatchGroups_594834(path: JsonNode; query: JsonNode;
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
  var valid_594836 = header.getOrDefault("X-Amz-Date")
  valid_594836 = validateParameter(valid_594836, JString, required = false,
                                 default = nil)
  if valid_594836 != nil:
    section.add "X-Amz-Date", valid_594836
  var valid_594837 = header.getOrDefault("X-Amz-Security-Token")
  valid_594837 = validateParameter(valid_594837, JString, required = false,
                                 default = nil)
  if valid_594837 != nil:
    section.add "X-Amz-Security-Token", valid_594837
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594838 = header.getOrDefault("X-Amz-Target")
  valid_594838 = validateParameter(valid_594838, JString, required = true, default = newJString(
      "AmazonSSM.DescribePatchGroups"))
  if valid_594838 != nil:
    section.add "X-Amz-Target", valid_594838
  var valid_594839 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594839 = validateParameter(valid_594839, JString, required = false,
                                 default = nil)
  if valid_594839 != nil:
    section.add "X-Amz-Content-Sha256", valid_594839
  var valid_594840 = header.getOrDefault("X-Amz-Algorithm")
  valid_594840 = validateParameter(valid_594840, JString, required = false,
                                 default = nil)
  if valid_594840 != nil:
    section.add "X-Amz-Algorithm", valid_594840
  var valid_594841 = header.getOrDefault("X-Amz-Signature")
  valid_594841 = validateParameter(valid_594841, JString, required = false,
                                 default = nil)
  if valid_594841 != nil:
    section.add "X-Amz-Signature", valid_594841
  var valid_594842 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594842 = validateParameter(valid_594842, JString, required = false,
                                 default = nil)
  if valid_594842 != nil:
    section.add "X-Amz-SignedHeaders", valid_594842
  var valid_594843 = header.getOrDefault("X-Amz-Credential")
  valid_594843 = validateParameter(valid_594843, JString, required = false,
                                 default = nil)
  if valid_594843 != nil:
    section.add "X-Amz-Credential", valid_594843
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594845: Call_DescribePatchGroups_594833; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all patch groups that have been registered with patch baselines.
  ## 
  let valid = call_594845.validator(path, query, header, formData, body)
  let scheme = call_594845.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594845.url(scheme.get, call_594845.host, call_594845.base,
                         call_594845.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594845, url, valid)

proc call*(call_594846: Call_DescribePatchGroups_594833; body: JsonNode): Recallable =
  ## describePatchGroups
  ## Lists all patch groups that have been registered with patch baselines.
  ##   body: JObject (required)
  var body_594847 = newJObject()
  if body != nil:
    body_594847 = body
  result = call_594846.call(nil, nil, nil, nil, body_594847)

var describePatchGroups* = Call_DescribePatchGroups_594833(
    name: "describePatchGroups", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribePatchGroups",
    validator: validate_DescribePatchGroups_594834, base: "/",
    url: url_DescribePatchGroups_594835, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribePatchProperties_594848 = ref object of OpenApiRestCall_593437
proc url_DescribePatchProperties_594850(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribePatchProperties_594849(path: JsonNode; query: JsonNode;
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
  var valid_594851 = header.getOrDefault("X-Amz-Date")
  valid_594851 = validateParameter(valid_594851, JString, required = false,
                                 default = nil)
  if valid_594851 != nil:
    section.add "X-Amz-Date", valid_594851
  var valid_594852 = header.getOrDefault("X-Amz-Security-Token")
  valid_594852 = validateParameter(valid_594852, JString, required = false,
                                 default = nil)
  if valid_594852 != nil:
    section.add "X-Amz-Security-Token", valid_594852
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594853 = header.getOrDefault("X-Amz-Target")
  valid_594853 = validateParameter(valid_594853, JString, required = true, default = newJString(
      "AmazonSSM.DescribePatchProperties"))
  if valid_594853 != nil:
    section.add "X-Amz-Target", valid_594853
  var valid_594854 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594854 = validateParameter(valid_594854, JString, required = false,
                                 default = nil)
  if valid_594854 != nil:
    section.add "X-Amz-Content-Sha256", valid_594854
  var valid_594855 = header.getOrDefault("X-Amz-Algorithm")
  valid_594855 = validateParameter(valid_594855, JString, required = false,
                                 default = nil)
  if valid_594855 != nil:
    section.add "X-Amz-Algorithm", valid_594855
  var valid_594856 = header.getOrDefault("X-Amz-Signature")
  valid_594856 = validateParameter(valid_594856, JString, required = false,
                                 default = nil)
  if valid_594856 != nil:
    section.add "X-Amz-Signature", valid_594856
  var valid_594857 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594857 = validateParameter(valid_594857, JString, required = false,
                                 default = nil)
  if valid_594857 != nil:
    section.add "X-Amz-SignedHeaders", valid_594857
  var valid_594858 = header.getOrDefault("X-Amz-Credential")
  valid_594858 = validateParameter(valid_594858, JString, required = false,
                                 default = nil)
  if valid_594858 != nil:
    section.add "X-Amz-Credential", valid_594858
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594860: Call_DescribePatchProperties_594848; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists the properties of available patches organized by product, product family, classification, severity, and other properties of available patches. You can use the reported properties in the filters you specify in requests for actions such as <a>CreatePatchBaseline</a>, <a>UpdatePatchBaseline</a>, <a>DescribeAvailablePatches</a>, and <a>DescribePatchBaselines</a>.</p> <p>The following section lists the properties that can be used in filters for each major operating system type:</p> <dl> <dt>WINDOWS</dt> <dd> <p>Valid properties: PRODUCT, PRODUCT_FAMILY, CLASSIFICATION, MSRC_SEVERITY</p> </dd> <dt>AMAZON_LINUX</dt> <dd> <p>Valid properties: PRODUCT, CLASSIFICATION, SEVERITY</p> </dd> <dt>AMAZON_LINUX_2</dt> <dd> <p>Valid properties: PRODUCT, CLASSIFICATION, SEVERITY</p> </dd> <dt>UBUNTU </dt> <dd> <p>Valid properties: PRODUCT, PRIORITY</p> </dd> <dt>REDHAT_ENTERPRISE_LINUX</dt> <dd> <p>Valid properties: PRODUCT, CLASSIFICATION, SEVERITY</p> </dd> <dt>SUSE</dt> <dd> <p>Valid properties: PRODUCT, CLASSIFICATION, SEVERITY</p> </dd> <dt>CENTOS</dt> <dd> <p>Valid properties: PRODUCT, CLASSIFICATION, SEVERITY</p> </dd> </dl>
  ## 
  let valid = call_594860.validator(path, query, header, formData, body)
  let scheme = call_594860.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594860.url(scheme.get, call_594860.host, call_594860.base,
                         call_594860.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594860, url, valid)

proc call*(call_594861: Call_DescribePatchProperties_594848; body: JsonNode): Recallable =
  ## describePatchProperties
  ## <p>Lists the properties of available patches organized by product, product family, classification, severity, and other properties of available patches. You can use the reported properties in the filters you specify in requests for actions such as <a>CreatePatchBaseline</a>, <a>UpdatePatchBaseline</a>, <a>DescribeAvailablePatches</a>, and <a>DescribePatchBaselines</a>.</p> <p>The following section lists the properties that can be used in filters for each major operating system type:</p> <dl> <dt>WINDOWS</dt> <dd> <p>Valid properties: PRODUCT, PRODUCT_FAMILY, CLASSIFICATION, MSRC_SEVERITY</p> </dd> <dt>AMAZON_LINUX</dt> <dd> <p>Valid properties: PRODUCT, CLASSIFICATION, SEVERITY</p> </dd> <dt>AMAZON_LINUX_2</dt> <dd> <p>Valid properties: PRODUCT, CLASSIFICATION, SEVERITY</p> </dd> <dt>UBUNTU </dt> <dd> <p>Valid properties: PRODUCT, PRIORITY</p> </dd> <dt>REDHAT_ENTERPRISE_LINUX</dt> <dd> <p>Valid properties: PRODUCT, CLASSIFICATION, SEVERITY</p> </dd> <dt>SUSE</dt> <dd> <p>Valid properties: PRODUCT, CLASSIFICATION, SEVERITY</p> </dd> <dt>CENTOS</dt> <dd> <p>Valid properties: PRODUCT, CLASSIFICATION, SEVERITY</p> </dd> </dl>
  ##   body: JObject (required)
  var body_594862 = newJObject()
  if body != nil:
    body_594862 = body
  result = call_594861.call(nil, nil, nil, nil, body_594862)

var describePatchProperties* = Call_DescribePatchProperties_594848(
    name: "describePatchProperties", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribePatchProperties",
    validator: validate_DescribePatchProperties_594849, base: "/",
    url: url_DescribePatchProperties_594850, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeSessions_594863 = ref object of OpenApiRestCall_593437
proc url_DescribeSessions_594865(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeSessions_594864(path: JsonNode; query: JsonNode;
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
  var valid_594866 = header.getOrDefault("X-Amz-Date")
  valid_594866 = validateParameter(valid_594866, JString, required = false,
                                 default = nil)
  if valid_594866 != nil:
    section.add "X-Amz-Date", valid_594866
  var valid_594867 = header.getOrDefault("X-Amz-Security-Token")
  valid_594867 = validateParameter(valid_594867, JString, required = false,
                                 default = nil)
  if valid_594867 != nil:
    section.add "X-Amz-Security-Token", valid_594867
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594868 = header.getOrDefault("X-Amz-Target")
  valid_594868 = validateParameter(valid_594868, JString, required = true, default = newJString(
      "AmazonSSM.DescribeSessions"))
  if valid_594868 != nil:
    section.add "X-Amz-Target", valid_594868
  var valid_594869 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594869 = validateParameter(valid_594869, JString, required = false,
                                 default = nil)
  if valid_594869 != nil:
    section.add "X-Amz-Content-Sha256", valid_594869
  var valid_594870 = header.getOrDefault("X-Amz-Algorithm")
  valid_594870 = validateParameter(valid_594870, JString, required = false,
                                 default = nil)
  if valid_594870 != nil:
    section.add "X-Amz-Algorithm", valid_594870
  var valid_594871 = header.getOrDefault("X-Amz-Signature")
  valid_594871 = validateParameter(valid_594871, JString, required = false,
                                 default = nil)
  if valid_594871 != nil:
    section.add "X-Amz-Signature", valid_594871
  var valid_594872 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594872 = validateParameter(valid_594872, JString, required = false,
                                 default = nil)
  if valid_594872 != nil:
    section.add "X-Amz-SignedHeaders", valid_594872
  var valid_594873 = header.getOrDefault("X-Amz-Credential")
  valid_594873 = validateParameter(valid_594873, JString, required = false,
                                 default = nil)
  if valid_594873 != nil:
    section.add "X-Amz-Credential", valid_594873
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594875: Call_DescribeSessions_594863; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of all active sessions (both connected and disconnected) or terminated sessions from the past 30 days.
  ## 
  let valid = call_594875.validator(path, query, header, formData, body)
  let scheme = call_594875.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594875.url(scheme.get, call_594875.host, call_594875.base,
                         call_594875.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594875, url, valid)

proc call*(call_594876: Call_DescribeSessions_594863; body: JsonNode): Recallable =
  ## describeSessions
  ## Retrieves a list of all active sessions (both connected and disconnected) or terminated sessions from the past 30 days.
  ##   body: JObject (required)
  var body_594877 = newJObject()
  if body != nil:
    body_594877 = body
  result = call_594876.call(nil, nil, nil, nil, body_594877)

var describeSessions* = Call_DescribeSessions_594863(name: "describeSessions",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeSessions",
    validator: validate_DescribeSessions_594864, base: "/",
    url: url_DescribeSessions_594865, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAutomationExecution_594878 = ref object of OpenApiRestCall_593437
proc url_GetAutomationExecution_594880(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetAutomationExecution_594879(path: JsonNode; query: JsonNode;
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
  var valid_594881 = header.getOrDefault("X-Amz-Date")
  valid_594881 = validateParameter(valid_594881, JString, required = false,
                                 default = nil)
  if valid_594881 != nil:
    section.add "X-Amz-Date", valid_594881
  var valid_594882 = header.getOrDefault("X-Amz-Security-Token")
  valid_594882 = validateParameter(valid_594882, JString, required = false,
                                 default = nil)
  if valid_594882 != nil:
    section.add "X-Amz-Security-Token", valid_594882
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594883 = header.getOrDefault("X-Amz-Target")
  valid_594883 = validateParameter(valid_594883, JString, required = true, default = newJString(
      "AmazonSSM.GetAutomationExecution"))
  if valid_594883 != nil:
    section.add "X-Amz-Target", valid_594883
  var valid_594884 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594884 = validateParameter(valid_594884, JString, required = false,
                                 default = nil)
  if valid_594884 != nil:
    section.add "X-Amz-Content-Sha256", valid_594884
  var valid_594885 = header.getOrDefault("X-Amz-Algorithm")
  valid_594885 = validateParameter(valid_594885, JString, required = false,
                                 default = nil)
  if valid_594885 != nil:
    section.add "X-Amz-Algorithm", valid_594885
  var valid_594886 = header.getOrDefault("X-Amz-Signature")
  valid_594886 = validateParameter(valid_594886, JString, required = false,
                                 default = nil)
  if valid_594886 != nil:
    section.add "X-Amz-Signature", valid_594886
  var valid_594887 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594887 = validateParameter(valid_594887, JString, required = false,
                                 default = nil)
  if valid_594887 != nil:
    section.add "X-Amz-SignedHeaders", valid_594887
  var valid_594888 = header.getOrDefault("X-Amz-Credential")
  valid_594888 = validateParameter(valid_594888, JString, required = false,
                                 default = nil)
  if valid_594888 != nil:
    section.add "X-Amz-Credential", valid_594888
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594890: Call_GetAutomationExecution_594878; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Get detailed information about a particular Automation execution.
  ## 
  let valid = call_594890.validator(path, query, header, formData, body)
  let scheme = call_594890.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594890.url(scheme.get, call_594890.host, call_594890.base,
                         call_594890.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594890, url, valid)

proc call*(call_594891: Call_GetAutomationExecution_594878; body: JsonNode): Recallable =
  ## getAutomationExecution
  ## Get detailed information about a particular Automation execution.
  ##   body: JObject (required)
  var body_594892 = newJObject()
  if body != nil:
    body_594892 = body
  result = call_594891.call(nil, nil, nil, nil, body_594892)

var getAutomationExecution* = Call_GetAutomationExecution_594878(
    name: "getAutomationExecution", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetAutomationExecution",
    validator: validate_GetAutomationExecution_594879, base: "/",
    url: url_GetAutomationExecution_594880, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCommandInvocation_594893 = ref object of OpenApiRestCall_593437
proc url_GetCommandInvocation_594895(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCommandInvocation_594894(path: JsonNode; query: JsonNode;
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
  var valid_594896 = header.getOrDefault("X-Amz-Date")
  valid_594896 = validateParameter(valid_594896, JString, required = false,
                                 default = nil)
  if valid_594896 != nil:
    section.add "X-Amz-Date", valid_594896
  var valid_594897 = header.getOrDefault("X-Amz-Security-Token")
  valid_594897 = validateParameter(valid_594897, JString, required = false,
                                 default = nil)
  if valid_594897 != nil:
    section.add "X-Amz-Security-Token", valid_594897
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594898 = header.getOrDefault("X-Amz-Target")
  valid_594898 = validateParameter(valid_594898, JString, required = true, default = newJString(
      "AmazonSSM.GetCommandInvocation"))
  if valid_594898 != nil:
    section.add "X-Amz-Target", valid_594898
  var valid_594899 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594899 = validateParameter(valid_594899, JString, required = false,
                                 default = nil)
  if valid_594899 != nil:
    section.add "X-Amz-Content-Sha256", valid_594899
  var valid_594900 = header.getOrDefault("X-Amz-Algorithm")
  valid_594900 = validateParameter(valid_594900, JString, required = false,
                                 default = nil)
  if valid_594900 != nil:
    section.add "X-Amz-Algorithm", valid_594900
  var valid_594901 = header.getOrDefault("X-Amz-Signature")
  valid_594901 = validateParameter(valid_594901, JString, required = false,
                                 default = nil)
  if valid_594901 != nil:
    section.add "X-Amz-Signature", valid_594901
  var valid_594902 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594902 = validateParameter(valid_594902, JString, required = false,
                                 default = nil)
  if valid_594902 != nil:
    section.add "X-Amz-SignedHeaders", valid_594902
  var valid_594903 = header.getOrDefault("X-Amz-Credential")
  valid_594903 = validateParameter(valid_594903, JString, required = false,
                                 default = nil)
  if valid_594903 != nil:
    section.add "X-Amz-Credential", valid_594903
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594905: Call_GetCommandInvocation_594893; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns detailed information about command execution for an invocation or plugin. 
  ## 
  let valid = call_594905.validator(path, query, header, formData, body)
  let scheme = call_594905.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594905.url(scheme.get, call_594905.host, call_594905.base,
                         call_594905.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594905, url, valid)

proc call*(call_594906: Call_GetCommandInvocation_594893; body: JsonNode): Recallable =
  ## getCommandInvocation
  ## Returns detailed information about command execution for an invocation or plugin. 
  ##   body: JObject (required)
  var body_594907 = newJObject()
  if body != nil:
    body_594907 = body
  result = call_594906.call(nil, nil, nil, nil, body_594907)

var getCommandInvocation* = Call_GetCommandInvocation_594893(
    name: "getCommandInvocation", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetCommandInvocation",
    validator: validate_GetCommandInvocation_594894, base: "/",
    url: url_GetCommandInvocation_594895, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetConnectionStatus_594908 = ref object of OpenApiRestCall_593437
proc url_GetConnectionStatus_594910(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetConnectionStatus_594909(path: JsonNode; query: JsonNode;
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
  var valid_594911 = header.getOrDefault("X-Amz-Date")
  valid_594911 = validateParameter(valid_594911, JString, required = false,
                                 default = nil)
  if valid_594911 != nil:
    section.add "X-Amz-Date", valid_594911
  var valid_594912 = header.getOrDefault("X-Amz-Security-Token")
  valid_594912 = validateParameter(valid_594912, JString, required = false,
                                 default = nil)
  if valid_594912 != nil:
    section.add "X-Amz-Security-Token", valid_594912
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594913 = header.getOrDefault("X-Amz-Target")
  valid_594913 = validateParameter(valid_594913, JString, required = true, default = newJString(
      "AmazonSSM.GetConnectionStatus"))
  if valid_594913 != nil:
    section.add "X-Amz-Target", valid_594913
  var valid_594914 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594914 = validateParameter(valid_594914, JString, required = false,
                                 default = nil)
  if valid_594914 != nil:
    section.add "X-Amz-Content-Sha256", valid_594914
  var valid_594915 = header.getOrDefault("X-Amz-Algorithm")
  valid_594915 = validateParameter(valid_594915, JString, required = false,
                                 default = nil)
  if valid_594915 != nil:
    section.add "X-Amz-Algorithm", valid_594915
  var valid_594916 = header.getOrDefault("X-Amz-Signature")
  valid_594916 = validateParameter(valid_594916, JString, required = false,
                                 default = nil)
  if valid_594916 != nil:
    section.add "X-Amz-Signature", valid_594916
  var valid_594917 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594917 = validateParameter(valid_594917, JString, required = false,
                                 default = nil)
  if valid_594917 != nil:
    section.add "X-Amz-SignedHeaders", valid_594917
  var valid_594918 = header.getOrDefault("X-Amz-Credential")
  valid_594918 = validateParameter(valid_594918, JString, required = false,
                                 default = nil)
  if valid_594918 != nil:
    section.add "X-Amz-Credential", valid_594918
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594920: Call_GetConnectionStatus_594908; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the Session Manager connection status for an instance to determine whether it is connected and ready to receive Session Manager connections.
  ## 
  let valid = call_594920.validator(path, query, header, formData, body)
  let scheme = call_594920.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594920.url(scheme.get, call_594920.host, call_594920.base,
                         call_594920.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594920, url, valid)

proc call*(call_594921: Call_GetConnectionStatus_594908; body: JsonNode): Recallable =
  ## getConnectionStatus
  ## Retrieves the Session Manager connection status for an instance to determine whether it is connected and ready to receive Session Manager connections.
  ##   body: JObject (required)
  var body_594922 = newJObject()
  if body != nil:
    body_594922 = body
  result = call_594921.call(nil, nil, nil, nil, body_594922)

var getConnectionStatus* = Call_GetConnectionStatus_594908(
    name: "getConnectionStatus", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetConnectionStatus",
    validator: validate_GetConnectionStatus_594909, base: "/",
    url: url_GetConnectionStatus_594910, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDefaultPatchBaseline_594923 = ref object of OpenApiRestCall_593437
proc url_GetDefaultPatchBaseline_594925(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDefaultPatchBaseline_594924(path: JsonNode; query: JsonNode;
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
  var valid_594926 = header.getOrDefault("X-Amz-Date")
  valid_594926 = validateParameter(valid_594926, JString, required = false,
                                 default = nil)
  if valid_594926 != nil:
    section.add "X-Amz-Date", valid_594926
  var valid_594927 = header.getOrDefault("X-Amz-Security-Token")
  valid_594927 = validateParameter(valid_594927, JString, required = false,
                                 default = nil)
  if valid_594927 != nil:
    section.add "X-Amz-Security-Token", valid_594927
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594928 = header.getOrDefault("X-Amz-Target")
  valid_594928 = validateParameter(valid_594928, JString, required = true, default = newJString(
      "AmazonSSM.GetDefaultPatchBaseline"))
  if valid_594928 != nil:
    section.add "X-Amz-Target", valid_594928
  var valid_594929 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594929 = validateParameter(valid_594929, JString, required = false,
                                 default = nil)
  if valid_594929 != nil:
    section.add "X-Amz-Content-Sha256", valid_594929
  var valid_594930 = header.getOrDefault("X-Amz-Algorithm")
  valid_594930 = validateParameter(valid_594930, JString, required = false,
                                 default = nil)
  if valid_594930 != nil:
    section.add "X-Amz-Algorithm", valid_594930
  var valid_594931 = header.getOrDefault("X-Amz-Signature")
  valid_594931 = validateParameter(valid_594931, JString, required = false,
                                 default = nil)
  if valid_594931 != nil:
    section.add "X-Amz-Signature", valid_594931
  var valid_594932 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594932 = validateParameter(valid_594932, JString, required = false,
                                 default = nil)
  if valid_594932 != nil:
    section.add "X-Amz-SignedHeaders", valid_594932
  var valid_594933 = header.getOrDefault("X-Amz-Credential")
  valid_594933 = validateParameter(valid_594933, JString, required = false,
                                 default = nil)
  if valid_594933 != nil:
    section.add "X-Amz-Credential", valid_594933
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594935: Call_GetDefaultPatchBaseline_594923; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves the default patch baseline. Note that Systems Manager supports creating multiple default patch baselines. For example, you can create a default patch baseline for each operating system.</p> <p>If you do not specify an operating system value, the default patch baseline for Windows is returned.</p>
  ## 
  let valid = call_594935.validator(path, query, header, formData, body)
  let scheme = call_594935.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594935.url(scheme.get, call_594935.host, call_594935.base,
                         call_594935.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594935, url, valid)

proc call*(call_594936: Call_GetDefaultPatchBaseline_594923; body: JsonNode): Recallable =
  ## getDefaultPatchBaseline
  ## <p>Retrieves the default patch baseline. Note that Systems Manager supports creating multiple default patch baselines. For example, you can create a default patch baseline for each operating system.</p> <p>If you do not specify an operating system value, the default patch baseline for Windows is returned.</p>
  ##   body: JObject (required)
  var body_594937 = newJObject()
  if body != nil:
    body_594937 = body
  result = call_594936.call(nil, nil, nil, nil, body_594937)

var getDefaultPatchBaseline* = Call_GetDefaultPatchBaseline_594923(
    name: "getDefaultPatchBaseline", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetDefaultPatchBaseline",
    validator: validate_GetDefaultPatchBaseline_594924, base: "/",
    url: url_GetDefaultPatchBaseline_594925, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeployablePatchSnapshotForInstance_594938 = ref object of OpenApiRestCall_593437
proc url_GetDeployablePatchSnapshotForInstance_594940(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeployablePatchSnapshotForInstance_594939(path: JsonNode;
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
  var valid_594941 = header.getOrDefault("X-Amz-Date")
  valid_594941 = validateParameter(valid_594941, JString, required = false,
                                 default = nil)
  if valid_594941 != nil:
    section.add "X-Amz-Date", valid_594941
  var valid_594942 = header.getOrDefault("X-Amz-Security-Token")
  valid_594942 = validateParameter(valid_594942, JString, required = false,
                                 default = nil)
  if valid_594942 != nil:
    section.add "X-Amz-Security-Token", valid_594942
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594943 = header.getOrDefault("X-Amz-Target")
  valid_594943 = validateParameter(valid_594943, JString, required = true, default = newJString(
      "AmazonSSM.GetDeployablePatchSnapshotForInstance"))
  if valid_594943 != nil:
    section.add "X-Amz-Target", valid_594943
  var valid_594944 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594944 = validateParameter(valid_594944, JString, required = false,
                                 default = nil)
  if valid_594944 != nil:
    section.add "X-Amz-Content-Sha256", valid_594944
  var valid_594945 = header.getOrDefault("X-Amz-Algorithm")
  valid_594945 = validateParameter(valid_594945, JString, required = false,
                                 default = nil)
  if valid_594945 != nil:
    section.add "X-Amz-Algorithm", valid_594945
  var valid_594946 = header.getOrDefault("X-Amz-Signature")
  valid_594946 = validateParameter(valid_594946, JString, required = false,
                                 default = nil)
  if valid_594946 != nil:
    section.add "X-Amz-Signature", valid_594946
  var valid_594947 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594947 = validateParameter(valid_594947, JString, required = false,
                                 default = nil)
  if valid_594947 != nil:
    section.add "X-Amz-SignedHeaders", valid_594947
  var valid_594948 = header.getOrDefault("X-Amz-Credential")
  valid_594948 = validateParameter(valid_594948, JString, required = false,
                                 default = nil)
  if valid_594948 != nil:
    section.add "X-Amz-Credential", valid_594948
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594950: Call_GetDeployablePatchSnapshotForInstance_594938;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves the current snapshot for the patch baseline the instance uses. This API is primarily used by the AWS-RunPatchBaseline Systems Manager document. 
  ## 
  let valid = call_594950.validator(path, query, header, formData, body)
  let scheme = call_594950.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594950.url(scheme.get, call_594950.host, call_594950.base,
                         call_594950.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594950, url, valid)

proc call*(call_594951: Call_GetDeployablePatchSnapshotForInstance_594938;
          body: JsonNode): Recallable =
  ## getDeployablePatchSnapshotForInstance
  ## Retrieves the current snapshot for the patch baseline the instance uses. This API is primarily used by the AWS-RunPatchBaseline Systems Manager document. 
  ##   body: JObject (required)
  var body_594952 = newJObject()
  if body != nil:
    body_594952 = body
  result = call_594951.call(nil, nil, nil, nil, body_594952)

var getDeployablePatchSnapshotForInstance* = Call_GetDeployablePatchSnapshotForInstance_594938(
    name: "getDeployablePatchSnapshotForInstance", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetDeployablePatchSnapshotForInstance",
    validator: validate_GetDeployablePatchSnapshotForInstance_594939, base: "/",
    url: url_GetDeployablePatchSnapshotForInstance_594940,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDocument_594953 = ref object of OpenApiRestCall_593437
proc url_GetDocument_594955(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDocument_594954(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594956 = header.getOrDefault("X-Amz-Date")
  valid_594956 = validateParameter(valid_594956, JString, required = false,
                                 default = nil)
  if valid_594956 != nil:
    section.add "X-Amz-Date", valid_594956
  var valid_594957 = header.getOrDefault("X-Amz-Security-Token")
  valid_594957 = validateParameter(valid_594957, JString, required = false,
                                 default = nil)
  if valid_594957 != nil:
    section.add "X-Amz-Security-Token", valid_594957
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594958 = header.getOrDefault("X-Amz-Target")
  valid_594958 = validateParameter(valid_594958, JString, required = true,
                                 default = newJString("AmazonSSM.GetDocument"))
  if valid_594958 != nil:
    section.add "X-Amz-Target", valid_594958
  var valid_594959 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594959 = validateParameter(valid_594959, JString, required = false,
                                 default = nil)
  if valid_594959 != nil:
    section.add "X-Amz-Content-Sha256", valid_594959
  var valid_594960 = header.getOrDefault("X-Amz-Algorithm")
  valid_594960 = validateParameter(valid_594960, JString, required = false,
                                 default = nil)
  if valid_594960 != nil:
    section.add "X-Amz-Algorithm", valid_594960
  var valid_594961 = header.getOrDefault("X-Amz-Signature")
  valid_594961 = validateParameter(valid_594961, JString, required = false,
                                 default = nil)
  if valid_594961 != nil:
    section.add "X-Amz-Signature", valid_594961
  var valid_594962 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594962 = validateParameter(valid_594962, JString, required = false,
                                 default = nil)
  if valid_594962 != nil:
    section.add "X-Amz-SignedHeaders", valid_594962
  var valid_594963 = header.getOrDefault("X-Amz-Credential")
  valid_594963 = validateParameter(valid_594963, JString, required = false,
                                 default = nil)
  if valid_594963 != nil:
    section.add "X-Amz-Credential", valid_594963
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594965: Call_GetDocument_594953; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the contents of the specified Systems Manager document.
  ## 
  let valid = call_594965.validator(path, query, header, formData, body)
  let scheme = call_594965.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594965.url(scheme.get, call_594965.host, call_594965.base,
                         call_594965.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594965, url, valid)

proc call*(call_594966: Call_GetDocument_594953; body: JsonNode): Recallable =
  ## getDocument
  ## Gets the contents of the specified Systems Manager document.
  ##   body: JObject (required)
  var body_594967 = newJObject()
  if body != nil:
    body_594967 = body
  result = call_594966.call(nil, nil, nil, nil, body_594967)

var getDocument* = Call_GetDocument_594953(name: "getDocument",
                                        meth: HttpMethod.HttpPost,
                                        host: "ssm.amazonaws.com", route: "/#X-Amz-Target=AmazonSSM.GetDocument",
                                        validator: validate_GetDocument_594954,
                                        base: "/", url: url_GetDocument_594955,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetInventory_594968 = ref object of OpenApiRestCall_593437
proc url_GetInventory_594970(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetInventory_594969(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594971 = header.getOrDefault("X-Amz-Date")
  valid_594971 = validateParameter(valid_594971, JString, required = false,
                                 default = nil)
  if valid_594971 != nil:
    section.add "X-Amz-Date", valid_594971
  var valid_594972 = header.getOrDefault("X-Amz-Security-Token")
  valid_594972 = validateParameter(valid_594972, JString, required = false,
                                 default = nil)
  if valid_594972 != nil:
    section.add "X-Amz-Security-Token", valid_594972
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594973 = header.getOrDefault("X-Amz-Target")
  valid_594973 = validateParameter(valid_594973, JString, required = true,
                                 default = newJString("AmazonSSM.GetInventory"))
  if valid_594973 != nil:
    section.add "X-Amz-Target", valid_594973
  var valid_594974 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594974 = validateParameter(valid_594974, JString, required = false,
                                 default = nil)
  if valid_594974 != nil:
    section.add "X-Amz-Content-Sha256", valid_594974
  var valid_594975 = header.getOrDefault("X-Amz-Algorithm")
  valid_594975 = validateParameter(valid_594975, JString, required = false,
                                 default = nil)
  if valid_594975 != nil:
    section.add "X-Amz-Algorithm", valid_594975
  var valid_594976 = header.getOrDefault("X-Amz-Signature")
  valid_594976 = validateParameter(valid_594976, JString, required = false,
                                 default = nil)
  if valid_594976 != nil:
    section.add "X-Amz-Signature", valid_594976
  var valid_594977 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594977 = validateParameter(valid_594977, JString, required = false,
                                 default = nil)
  if valid_594977 != nil:
    section.add "X-Amz-SignedHeaders", valid_594977
  var valid_594978 = header.getOrDefault("X-Amz-Credential")
  valid_594978 = validateParameter(valid_594978, JString, required = false,
                                 default = nil)
  if valid_594978 != nil:
    section.add "X-Amz-Credential", valid_594978
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594980: Call_GetInventory_594968; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Query inventory information.
  ## 
  let valid = call_594980.validator(path, query, header, formData, body)
  let scheme = call_594980.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594980.url(scheme.get, call_594980.host, call_594980.base,
                         call_594980.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594980, url, valid)

proc call*(call_594981: Call_GetInventory_594968; body: JsonNode): Recallable =
  ## getInventory
  ## Query inventory information.
  ##   body: JObject (required)
  var body_594982 = newJObject()
  if body != nil:
    body_594982 = body
  result = call_594981.call(nil, nil, nil, nil, body_594982)

var getInventory* = Call_GetInventory_594968(name: "getInventory",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetInventory",
    validator: validate_GetInventory_594969, base: "/", url: url_GetInventory_594970,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetInventorySchema_594983 = ref object of OpenApiRestCall_593437
proc url_GetInventorySchema_594985(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetInventorySchema_594984(path: JsonNode; query: JsonNode;
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
  var valid_594986 = header.getOrDefault("X-Amz-Date")
  valid_594986 = validateParameter(valid_594986, JString, required = false,
                                 default = nil)
  if valid_594986 != nil:
    section.add "X-Amz-Date", valid_594986
  var valid_594987 = header.getOrDefault("X-Amz-Security-Token")
  valid_594987 = validateParameter(valid_594987, JString, required = false,
                                 default = nil)
  if valid_594987 != nil:
    section.add "X-Amz-Security-Token", valid_594987
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594988 = header.getOrDefault("X-Amz-Target")
  valid_594988 = validateParameter(valid_594988, JString, required = true, default = newJString(
      "AmazonSSM.GetInventorySchema"))
  if valid_594988 != nil:
    section.add "X-Amz-Target", valid_594988
  var valid_594989 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594989 = validateParameter(valid_594989, JString, required = false,
                                 default = nil)
  if valid_594989 != nil:
    section.add "X-Amz-Content-Sha256", valid_594989
  var valid_594990 = header.getOrDefault("X-Amz-Algorithm")
  valid_594990 = validateParameter(valid_594990, JString, required = false,
                                 default = nil)
  if valid_594990 != nil:
    section.add "X-Amz-Algorithm", valid_594990
  var valid_594991 = header.getOrDefault("X-Amz-Signature")
  valid_594991 = validateParameter(valid_594991, JString, required = false,
                                 default = nil)
  if valid_594991 != nil:
    section.add "X-Amz-Signature", valid_594991
  var valid_594992 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594992 = validateParameter(valid_594992, JString, required = false,
                                 default = nil)
  if valid_594992 != nil:
    section.add "X-Amz-SignedHeaders", valid_594992
  var valid_594993 = header.getOrDefault("X-Amz-Credential")
  valid_594993 = validateParameter(valid_594993, JString, required = false,
                                 default = nil)
  if valid_594993 != nil:
    section.add "X-Amz-Credential", valid_594993
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594995: Call_GetInventorySchema_594983; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Return a list of inventory type names for the account, or return a list of attribute names for a specific Inventory item type. 
  ## 
  let valid = call_594995.validator(path, query, header, formData, body)
  let scheme = call_594995.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594995.url(scheme.get, call_594995.host, call_594995.base,
                         call_594995.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594995, url, valid)

proc call*(call_594996: Call_GetInventorySchema_594983; body: JsonNode): Recallable =
  ## getInventorySchema
  ## Return a list of inventory type names for the account, or return a list of attribute names for a specific Inventory item type. 
  ##   body: JObject (required)
  var body_594997 = newJObject()
  if body != nil:
    body_594997 = body
  result = call_594996.call(nil, nil, nil, nil, body_594997)

var getInventorySchema* = Call_GetInventorySchema_594983(
    name: "getInventorySchema", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetInventorySchema",
    validator: validate_GetInventorySchema_594984, base: "/",
    url: url_GetInventorySchema_594985, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMaintenanceWindow_594998 = ref object of OpenApiRestCall_593437
proc url_GetMaintenanceWindow_595000(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetMaintenanceWindow_594999(path: JsonNode; query: JsonNode;
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
  var valid_595001 = header.getOrDefault("X-Amz-Date")
  valid_595001 = validateParameter(valid_595001, JString, required = false,
                                 default = nil)
  if valid_595001 != nil:
    section.add "X-Amz-Date", valid_595001
  var valid_595002 = header.getOrDefault("X-Amz-Security-Token")
  valid_595002 = validateParameter(valid_595002, JString, required = false,
                                 default = nil)
  if valid_595002 != nil:
    section.add "X-Amz-Security-Token", valid_595002
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595003 = header.getOrDefault("X-Amz-Target")
  valid_595003 = validateParameter(valid_595003, JString, required = true, default = newJString(
      "AmazonSSM.GetMaintenanceWindow"))
  if valid_595003 != nil:
    section.add "X-Amz-Target", valid_595003
  var valid_595004 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595004 = validateParameter(valid_595004, JString, required = false,
                                 default = nil)
  if valid_595004 != nil:
    section.add "X-Amz-Content-Sha256", valid_595004
  var valid_595005 = header.getOrDefault("X-Amz-Algorithm")
  valid_595005 = validateParameter(valid_595005, JString, required = false,
                                 default = nil)
  if valid_595005 != nil:
    section.add "X-Amz-Algorithm", valid_595005
  var valid_595006 = header.getOrDefault("X-Amz-Signature")
  valid_595006 = validateParameter(valid_595006, JString, required = false,
                                 default = nil)
  if valid_595006 != nil:
    section.add "X-Amz-Signature", valid_595006
  var valid_595007 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595007 = validateParameter(valid_595007, JString, required = false,
                                 default = nil)
  if valid_595007 != nil:
    section.add "X-Amz-SignedHeaders", valid_595007
  var valid_595008 = header.getOrDefault("X-Amz-Credential")
  valid_595008 = validateParameter(valid_595008, JString, required = false,
                                 default = nil)
  if valid_595008 != nil:
    section.add "X-Amz-Credential", valid_595008
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595010: Call_GetMaintenanceWindow_594998; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a maintenance window.
  ## 
  let valid = call_595010.validator(path, query, header, formData, body)
  let scheme = call_595010.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595010.url(scheme.get, call_595010.host, call_595010.base,
                         call_595010.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595010, url, valid)

proc call*(call_595011: Call_GetMaintenanceWindow_594998; body: JsonNode): Recallable =
  ## getMaintenanceWindow
  ## Retrieves a maintenance window.
  ##   body: JObject (required)
  var body_595012 = newJObject()
  if body != nil:
    body_595012 = body
  result = call_595011.call(nil, nil, nil, nil, body_595012)

var getMaintenanceWindow* = Call_GetMaintenanceWindow_594998(
    name: "getMaintenanceWindow", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetMaintenanceWindow",
    validator: validate_GetMaintenanceWindow_594999, base: "/",
    url: url_GetMaintenanceWindow_595000, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMaintenanceWindowExecution_595013 = ref object of OpenApiRestCall_593437
proc url_GetMaintenanceWindowExecution_595015(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetMaintenanceWindowExecution_595014(path: JsonNode; query: JsonNode;
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
  var valid_595016 = header.getOrDefault("X-Amz-Date")
  valid_595016 = validateParameter(valid_595016, JString, required = false,
                                 default = nil)
  if valid_595016 != nil:
    section.add "X-Amz-Date", valid_595016
  var valid_595017 = header.getOrDefault("X-Amz-Security-Token")
  valid_595017 = validateParameter(valid_595017, JString, required = false,
                                 default = nil)
  if valid_595017 != nil:
    section.add "X-Amz-Security-Token", valid_595017
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595018 = header.getOrDefault("X-Amz-Target")
  valid_595018 = validateParameter(valid_595018, JString, required = true, default = newJString(
      "AmazonSSM.GetMaintenanceWindowExecution"))
  if valid_595018 != nil:
    section.add "X-Amz-Target", valid_595018
  var valid_595019 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595019 = validateParameter(valid_595019, JString, required = false,
                                 default = nil)
  if valid_595019 != nil:
    section.add "X-Amz-Content-Sha256", valid_595019
  var valid_595020 = header.getOrDefault("X-Amz-Algorithm")
  valid_595020 = validateParameter(valid_595020, JString, required = false,
                                 default = nil)
  if valid_595020 != nil:
    section.add "X-Amz-Algorithm", valid_595020
  var valid_595021 = header.getOrDefault("X-Amz-Signature")
  valid_595021 = validateParameter(valid_595021, JString, required = false,
                                 default = nil)
  if valid_595021 != nil:
    section.add "X-Amz-Signature", valid_595021
  var valid_595022 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595022 = validateParameter(valid_595022, JString, required = false,
                                 default = nil)
  if valid_595022 != nil:
    section.add "X-Amz-SignedHeaders", valid_595022
  var valid_595023 = header.getOrDefault("X-Amz-Credential")
  valid_595023 = validateParameter(valid_595023, JString, required = false,
                                 default = nil)
  if valid_595023 != nil:
    section.add "X-Amz-Credential", valid_595023
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595025: Call_GetMaintenanceWindowExecution_595013; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves details about a specific a maintenance window execution.
  ## 
  let valid = call_595025.validator(path, query, header, formData, body)
  let scheme = call_595025.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595025.url(scheme.get, call_595025.host, call_595025.base,
                         call_595025.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595025, url, valid)

proc call*(call_595026: Call_GetMaintenanceWindowExecution_595013; body: JsonNode): Recallable =
  ## getMaintenanceWindowExecution
  ## Retrieves details about a specific a maintenance window execution.
  ##   body: JObject (required)
  var body_595027 = newJObject()
  if body != nil:
    body_595027 = body
  result = call_595026.call(nil, nil, nil, nil, body_595027)

var getMaintenanceWindowExecution* = Call_GetMaintenanceWindowExecution_595013(
    name: "getMaintenanceWindowExecution", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetMaintenanceWindowExecution",
    validator: validate_GetMaintenanceWindowExecution_595014, base: "/",
    url: url_GetMaintenanceWindowExecution_595015,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMaintenanceWindowExecutionTask_595028 = ref object of OpenApiRestCall_593437
proc url_GetMaintenanceWindowExecutionTask_595030(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetMaintenanceWindowExecutionTask_595029(path: JsonNode;
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
  var valid_595031 = header.getOrDefault("X-Amz-Date")
  valid_595031 = validateParameter(valid_595031, JString, required = false,
                                 default = nil)
  if valid_595031 != nil:
    section.add "X-Amz-Date", valid_595031
  var valid_595032 = header.getOrDefault("X-Amz-Security-Token")
  valid_595032 = validateParameter(valid_595032, JString, required = false,
                                 default = nil)
  if valid_595032 != nil:
    section.add "X-Amz-Security-Token", valid_595032
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595033 = header.getOrDefault("X-Amz-Target")
  valid_595033 = validateParameter(valid_595033, JString, required = true, default = newJString(
      "AmazonSSM.GetMaintenanceWindowExecutionTask"))
  if valid_595033 != nil:
    section.add "X-Amz-Target", valid_595033
  var valid_595034 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595034 = validateParameter(valid_595034, JString, required = false,
                                 default = nil)
  if valid_595034 != nil:
    section.add "X-Amz-Content-Sha256", valid_595034
  var valid_595035 = header.getOrDefault("X-Amz-Algorithm")
  valid_595035 = validateParameter(valid_595035, JString, required = false,
                                 default = nil)
  if valid_595035 != nil:
    section.add "X-Amz-Algorithm", valid_595035
  var valid_595036 = header.getOrDefault("X-Amz-Signature")
  valid_595036 = validateParameter(valid_595036, JString, required = false,
                                 default = nil)
  if valid_595036 != nil:
    section.add "X-Amz-Signature", valid_595036
  var valid_595037 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595037 = validateParameter(valid_595037, JString, required = false,
                                 default = nil)
  if valid_595037 != nil:
    section.add "X-Amz-SignedHeaders", valid_595037
  var valid_595038 = header.getOrDefault("X-Amz-Credential")
  valid_595038 = validateParameter(valid_595038, JString, required = false,
                                 default = nil)
  if valid_595038 != nil:
    section.add "X-Amz-Credential", valid_595038
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595040: Call_GetMaintenanceWindowExecutionTask_595028;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves the details about a specific task run as part of a maintenance window execution.
  ## 
  let valid = call_595040.validator(path, query, header, formData, body)
  let scheme = call_595040.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595040.url(scheme.get, call_595040.host, call_595040.base,
                         call_595040.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595040, url, valid)

proc call*(call_595041: Call_GetMaintenanceWindowExecutionTask_595028;
          body: JsonNode): Recallable =
  ## getMaintenanceWindowExecutionTask
  ## Retrieves the details about a specific task run as part of a maintenance window execution.
  ##   body: JObject (required)
  var body_595042 = newJObject()
  if body != nil:
    body_595042 = body
  result = call_595041.call(nil, nil, nil, nil, body_595042)

var getMaintenanceWindowExecutionTask* = Call_GetMaintenanceWindowExecutionTask_595028(
    name: "getMaintenanceWindowExecutionTask", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetMaintenanceWindowExecutionTask",
    validator: validate_GetMaintenanceWindowExecutionTask_595029, base: "/",
    url: url_GetMaintenanceWindowExecutionTask_595030,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMaintenanceWindowExecutionTaskInvocation_595043 = ref object of OpenApiRestCall_593437
proc url_GetMaintenanceWindowExecutionTaskInvocation_595045(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetMaintenanceWindowExecutionTaskInvocation_595044(path: JsonNode;
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
  var valid_595046 = header.getOrDefault("X-Amz-Date")
  valid_595046 = validateParameter(valid_595046, JString, required = false,
                                 default = nil)
  if valid_595046 != nil:
    section.add "X-Amz-Date", valid_595046
  var valid_595047 = header.getOrDefault("X-Amz-Security-Token")
  valid_595047 = validateParameter(valid_595047, JString, required = false,
                                 default = nil)
  if valid_595047 != nil:
    section.add "X-Amz-Security-Token", valid_595047
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595048 = header.getOrDefault("X-Amz-Target")
  valid_595048 = validateParameter(valid_595048, JString, required = true, default = newJString(
      "AmazonSSM.GetMaintenanceWindowExecutionTaskInvocation"))
  if valid_595048 != nil:
    section.add "X-Amz-Target", valid_595048
  var valid_595049 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595049 = validateParameter(valid_595049, JString, required = false,
                                 default = nil)
  if valid_595049 != nil:
    section.add "X-Amz-Content-Sha256", valid_595049
  var valid_595050 = header.getOrDefault("X-Amz-Algorithm")
  valid_595050 = validateParameter(valid_595050, JString, required = false,
                                 default = nil)
  if valid_595050 != nil:
    section.add "X-Amz-Algorithm", valid_595050
  var valid_595051 = header.getOrDefault("X-Amz-Signature")
  valid_595051 = validateParameter(valid_595051, JString, required = false,
                                 default = nil)
  if valid_595051 != nil:
    section.add "X-Amz-Signature", valid_595051
  var valid_595052 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595052 = validateParameter(valid_595052, JString, required = false,
                                 default = nil)
  if valid_595052 != nil:
    section.add "X-Amz-SignedHeaders", valid_595052
  var valid_595053 = header.getOrDefault("X-Amz-Credential")
  valid_595053 = validateParameter(valid_595053, JString, required = false,
                                 default = nil)
  if valid_595053 != nil:
    section.add "X-Amz-Credential", valid_595053
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595055: Call_GetMaintenanceWindowExecutionTaskInvocation_595043;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves information about a specific task running on a specific target.
  ## 
  let valid = call_595055.validator(path, query, header, formData, body)
  let scheme = call_595055.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595055.url(scheme.get, call_595055.host, call_595055.base,
                         call_595055.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595055, url, valid)

proc call*(call_595056: Call_GetMaintenanceWindowExecutionTaskInvocation_595043;
          body: JsonNode): Recallable =
  ## getMaintenanceWindowExecutionTaskInvocation
  ## Retrieves information about a specific task running on a specific target.
  ##   body: JObject (required)
  var body_595057 = newJObject()
  if body != nil:
    body_595057 = body
  result = call_595056.call(nil, nil, nil, nil, body_595057)

var getMaintenanceWindowExecutionTaskInvocation* = Call_GetMaintenanceWindowExecutionTaskInvocation_595043(
    name: "getMaintenanceWindowExecutionTaskInvocation",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com", route: "/#X-Amz-Target=AmazonSSM.GetMaintenanceWindowExecutionTaskInvocation",
    validator: validate_GetMaintenanceWindowExecutionTaskInvocation_595044,
    base: "/", url: url_GetMaintenanceWindowExecutionTaskInvocation_595045,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMaintenanceWindowTask_595058 = ref object of OpenApiRestCall_593437
proc url_GetMaintenanceWindowTask_595060(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetMaintenanceWindowTask_595059(path: JsonNode; query: JsonNode;
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
  var valid_595061 = header.getOrDefault("X-Amz-Date")
  valid_595061 = validateParameter(valid_595061, JString, required = false,
                                 default = nil)
  if valid_595061 != nil:
    section.add "X-Amz-Date", valid_595061
  var valid_595062 = header.getOrDefault("X-Amz-Security-Token")
  valid_595062 = validateParameter(valid_595062, JString, required = false,
                                 default = nil)
  if valid_595062 != nil:
    section.add "X-Amz-Security-Token", valid_595062
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595063 = header.getOrDefault("X-Amz-Target")
  valid_595063 = validateParameter(valid_595063, JString, required = true, default = newJString(
      "AmazonSSM.GetMaintenanceWindowTask"))
  if valid_595063 != nil:
    section.add "X-Amz-Target", valid_595063
  var valid_595064 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595064 = validateParameter(valid_595064, JString, required = false,
                                 default = nil)
  if valid_595064 != nil:
    section.add "X-Amz-Content-Sha256", valid_595064
  var valid_595065 = header.getOrDefault("X-Amz-Algorithm")
  valid_595065 = validateParameter(valid_595065, JString, required = false,
                                 default = nil)
  if valid_595065 != nil:
    section.add "X-Amz-Algorithm", valid_595065
  var valid_595066 = header.getOrDefault("X-Amz-Signature")
  valid_595066 = validateParameter(valid_595066, JString, required = false,
                                 default = nil)
  if valid_595066 != nil:
    section.add "X-Amz-Signature", valid_595066
  var valid_595067 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595067 = validateParameter(valid_595067, JString, required = false,
                                 default = nil)
  if valid_595067 != nil:
    section.add "X-Amz-SignedHeaders", valid_595067
  var valid_595068 = header.getOrDefault("X-Amz-Credential")
  valid_595068 = validateParameter(valid_595068, JString, required = false,
                                 default = nil)
  if valid_595068 != nil:
    section.add "X-Amz-Credential", valid_595068
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595070: Call_GetMaintenanceWindowTask_595058; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the tasks in a maintenance window.
  ## 
  let valid = call_595070.validator(path, query, header, formData, body)
  let scheme = call_595070.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595070.url(scheme.get, call_595070.host, call_595070.base,
                         call_595070.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595070, url, valid)

proc call*(call_595071: Call_GetMaintenanceWindowTask_595058; body: JsonNode): Recallable =
  ## getMaintenanceWindowTask
  ## Lists the tasks in a maintenance window.
  ##   body: JObject (required)
  var body_595072 = newJObject()
  if body != nil:
    body_595072 = body
  result = call_595071.call(nil, nil, nil, nil, body_595072)

var getMaintenanceWindowTask* = Call_GetMaintenanceWindowTask_595058(
    name: "getMaintenanceWindowTask", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetMaintenanceWindowTask",
    validator: validate_GetMaintenanceWindowTask_595059, base: "/",
    url: url_GetMaintenanceWindowTask_595060, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetOpsItem_595073 = ref object of OpenApiRestCall_593437
proc url_GetOpsItem_595075(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetOpsItem_595074(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_595076 = header.getOrDefault("X-Amz-Date")
  valid_595076 = validateParameter(valid_595076, JString, required = false,
                                 default = nil)
  if valid_595076 != nil:
    section.add "X-Amz-Date", valid_595076
  var valid_595077 = header.getOrDefault("X-Amz-Security-Token")
  valid_595077 = validateParameter(valid_595077, JString, required = false,
                                 default = nil)
  if valid_595077 != nil:
    section.add "X-Amz-Security-Token", valid_595077
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595078 = header.getOrDefault("X-Amz-Target")
  valid_595078 = validateParameter(valid_595078, JString, required = true,
                                 default = newJString("AmazonSSM.GetOpsItem"))
  if valid_595078 != nil:
    section.add "X-Amz-Target", valid_595078
  var valid_595079 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595079 = validateParameter(valid_595079, JString, required = false,
                                 default = nil)
  if valid_595079 != nil:
    section.add "X-Amz-Content-Sha256", valid_595079
  var valid_595080 = header.getOrDefault("X-Amz-Algorithm")
  valid_595080 = validateParameter(valid_595080, JString, required = false,
                                 default = nil)
  if valid_595080 != nil:
    section.add "X-Amz-Algorithm", valid_595080
  var valid_595081 = header.getOrDefault("X-Amz-Signature")
  valid_595081 = validateParameter(valid_595081, JString, required = false,
                                 default = nil)
  if valid_595081 != nil:
    section.add "X-Amz-Signature", valid_595081
  var valid_595082 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595082 = validateParameter(valid_595082, JString, required = false,
                                 default = nil)
  if valid_595082 != nil:
    section.add "X-Amz-SignedHeaders", valid_595082
  var valid_595083 = header.getOrDefault("X-Amz-Credential")
  valid_595083 = validateParameter(valid_595083, JString, required = false,
                                 default = nil)
  if valid_595083 != nil:
    section.add "X-Amz-Credential", valid_595083
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595085: Call_GetOpsItem_595073; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Get information about an OpsItem by using the ID. You must have permission in AWS Identity and Access Management (IAM) to view information about an OpsItem. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter-getting-started.html">Getting Started with OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>.</p> <p>Operations engineers and IT professionals use OpsCenter to view, investigate, and remediate operational issues impacting the performance and health of their AWS resources. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter.html">AWS Systems Manager OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>. </p>
  ## 
  let valid = call_595085.validator(path, query, header, formData, body)
  let scheme = call_595085.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595085.url(scheme.get, call_595085.host, call_595085.base,
                         call_595085.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595085, url, valid)

proc call*(call_595086: Call_GetOpsItem_595073; body: JsonNode): Recallable =
  ## getOpsItem
  ## <p>Get information about an OpsItem by using the ID. You must have permission in AWS Identity and Access Management (IAM) to view information about an OpsItem. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter-getting-started.html">Getting Started with OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>.</p> <p>Operations engineers and IT professionals use OpsCenter to view, investigate, and remediate operational issues impacting the performance and health of their AWS resources. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter.html">AWS Systems Manager OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>. </p>
  ##   body: JObject (required)
  var body_595087 = newJObject()
  if body != nil:
    body_595087 = body
  result = call_595086.call(nil, nil, nil, nil, body_595087)

var getOpsItem* = Call_GetOpsItem_595073(name: "getOpsItem",
                                      meth: HttpMethod.HttpPost,
                                      host: "ssm.amazonaws.com", route: "/#X-Amz-Target=AmazonSSM.GetOpsItem",
                                      validator: validate_GetOpsItem_595074,
                                      base: "/", url: url_GetOpsItem_595075,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetOpsSummary_595088 = ref object of OpenApiRestCall_593437
proc url_GetOpsSummary_595090(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetOpsSummary_595089(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_595091 = header.getOrDefault("X-Amz-Date")
  valid_595091 = validateParameter(valid_595091, JString, required = false,
                                 default = nil)
  if valid_595091 != nil:
    section.add "X-Amz-Date", valid_595091
  var valid_595092 = header.getOrDefault("X-Amz-Security-Token")
  valid_595092 = validateParameter(valid_595092, JString, required = false,
                                 default = nil)
  if valid_595092 != nil:
    section.add "X-Amz-Security-Token", valid_595092
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595093 = header.getOrDefault("X-Amz-Target")
  valid_595093 = validateParameter(valid_595093, JString, required = true, default = newJString(
      "AmazonSSM.GetOpsSummary"))
  if valid_595093 != nil:
    section.add "X-Amz-Target", valid_595093
  var valid_595094 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595094 = validateParameter(valid_595094, JString, required = false,
                                 default = nil)
  if valid_595094 != nil:
    section.add "X-Amz-Content-Sha256", valid_595094
  var valid_595095 = header.getOrDefault("X-Amz-Algorithm")
  valid_595095 = validateParameter(valid_595095, JString, required = false,
                                 default = nil)
  if valid_595095 != nil:
    section.add "X-Amz-Algorithm", valid_595095
  var valid_595096 = header.getOrDefault("X-Amz-Signature")
  valid_595096 = validateParameter(valid_595096, JString, required = false,
                                 default = nil)
  if valid_595096 != nil:
    section.add "X-Amz-Signature", valid_595096
  var valid_595097 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595097 = validateParameter(valid_595097, JString, required = false,
                                 default = nil)
  if valid_595097 != nil:
    section.add "X-Amz-SignedHeaders", valid_595097
  var valid_595098 = header.getOrDefault("X-Amz-Credential")
  valid_595098 = validateParameter(valid_595098, JString, required = false,
                                 default = nil)
  if valid_595098 != nil:
    section.add "X-Amz-Credential", valid_595098
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595100: Call_GetOpsSummary_595088; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## View a summary of OpsItems based on specified filters and aggregators.
  ## 
  let valid = call_595100.validator(path, query, header, formData, body)
  let scheme = call_595100.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595100.url(scheme.get, call_595100.host, call_595100.base,
                         call_595100.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595100, url, valid)

proc call*(call_595101: Call_GetOpsSummary_595088; body: JsonNode): Recallable =
  ## getOpsSummary
  ## View a summary of OpsItems based on specified filters and aggregators.
  ##   body: JObject (required)
  var body_595102 = newJObject()
  if body != nil:
    body_595102 = body
  result = call_595101.call(nil, nil, nil, nil, body_595102)

var getOpsSummary* = Call_GetOpsSummary_595088(name: "getOpsSummary",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetOpsSummary",
    validator: validate_GetOpsSummary_595089, base: "/", url: url_GetOpsSummary_595090,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetParameter_595103 = ref object of OpenApiRestCall_593437
proc url_GetParameter_595105(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetParameter_595104(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_595106 = header.getOrDefault("X-Amz-Date")
  valid_595106 = validateParameter(valid_595106, JString, required = false,
                                 default = nil)
  if valid_595106 != nil:
    section.add "X-Amz-Date", valid_595106
  var valid_595107 = header.getOrDefault("X-Amz-Security-Token")
  valid_595107 = validateParameter(valid_595107, JString, required = false,
                                 default = nil)
  if valid_595107 != nil:
    section.add "X-Amz-Security-Token", valid_595107
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595108 = header.getOrDefault("X-Amz-Target")
  valid_595108 = validateParameter(valid_595108, JString, required = true,
                                 default = newJString("AmazonSSM.GetParameter"))
  if valid_595108 != nil:
    section.add "X-Amz-Target", valid_595108
  var valid_595109 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595109 = validateParameter(valid_595109, JString, required = false,
                                 default = nil)
  if valid_595109 != nil:
    section.add "X-Amz-Content-Sha256", valid_595109
  var valid_595110 = header.getOrDefault("X-Amz-Algorithm")
  valid_595110 = validateParameter(valid_595110, JString, required = false,
                                 default = nil)
  if valid_595110 != nil:
    section.add "X-Amz-Algorithm", valid_595110
  var valid_595111 = header.getOrDefault("X-Amz-Signature")
  valid_595111 = validateParameter(valid_595111, JString, required = false,
                                 default = nil)
  if valid_595111 != nil:
    section.add "X-Amz-Signature", valid_595111
  var valid_595112 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595112 = validateParameter(valid_595112, JString, required = false,
                                 default = nil)
  if valid_595112 != nil:
    section.add "X-Amz-SignedHeaders", valid_595112
  var valid_595113 = header.getOrDefault("X-Amz-Credential")
  valid_595113 = validateParameter(valid_595113, JString, required = false,
                                 default = nil)
  if valid_595113 != nil:
    section.add "X-Amz-Credential", valid_595113
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595115: Call_GetParameter_595103; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Get information about a parameter by using the parameter name. Don't confuse this API action with the <a>GetParameters</a> API action.
  ## 
  let valid = call_595115.validator(path, query, header, formData, body)
  let scheme = call_595115.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595115.url(scheme.get, call_595115.host, call_595115.base,
                         call_595115.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595115, url, valid)

proc call*(call_595116: Call_GetParameter_595103; body: JsonNode): Recallable =
  ## getParameter
  ## Get information about a parameter by using the parameter name. Don't confuse this API action with the <a>GetParameters</a> API action.
  ##   body: JObject (required)
  var body_595117 = newJObject()
  if body != nil:
    body_595117 = body
  result = call_595116.call(nil, nil, nil, nil, body_595117)

var getParameter* = Call_GetParameter_595103(name: "getParameter",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetParameter",
    validator: validate_GetParameter_595104, base: "/", url: url_GetParameter_595105,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetParameterHistory_595118 = ref object of OpenApiRestCall_593437
proc url_GetParameterHistory_595120(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetParameterHistory_595119(path: JsonNode; query: JsonNode;
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
  var valid_595121 = query.getOrDefault("NextToken")
  valid_595121 = validateParameter(valid_595121, JString, required = false,
                                 default = nil)
  if valid_595121 != nil:
    section.add "NextToken", valid_595121
  var valid_595122 = query.getOrDefault("MaxResults")
  valid_595122 = validateParameter(valid_595122, JString, required = false,
                                 default = nil)
  if valid_595122 != nil:
    section.add "MaxResults", valid_595122
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
  var valid_595123 = header.getOrDefault("X-Amz-Date")
  valid_595123 = validateParameter(valid_595123, JString, required = false,
                                 default = nil)
  if valid_595123 != nil:
    section.add "X-Amz-Date", valid_595123
  var valid_595124 = header.getOrDefault("X-Amz-Security-Token")
  valid_595124 = validateParameter(valid_595124, JString, required = false,
                                 default = nil)
  if valid_595124 != nil:
    section.add "X-Amz-Security-Token", valid_595124
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595125 = header.getOrDefault("X-Amz-Target")
  valid_595125 = validateParameter(valid_595125, JString, required = true, default = newJString(
      "AmazonSSM.GetParameterHistory"))
  if valid_595125 != nil:
    section.add "X-Amz-Target", valid_595125
  var valid_595126 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595126 = validateParameter(valid_595126, JString, required = false,
                                 default = nil)
  if valid_595126 != nil:
    section.add "X-Amz-Content-Sha256", valid_595126
  var valid_595127 = header.getOrDefault("X-Amz-Algorithm")
  valid_595127 = validateParameter(valid_595127, JString, required = false,
                                 default = nil)
  if valid_595127 != nil:
    section.add "X-Amz-Algorithm", valid_595127
  var valid_595128 = header.getOrDefault("X-Amz-Signature")
  valid_595128 = validateParameter(valid_595128, JString, required = false,
                                 default = nil)
  if valid_595128 != nil:
    section.add "X-Amz-Signature", valid_595128
  var valid_595129 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595129 = validateParameter(valid_595129, JString, required = false,
                                 default = nil)
  if valid_595129 != nil:
    section.add "X-Amz-SignedHeaders", valid_595129
  var valid_595130 = header.getOrDefault("X-Amz-Credential")
  valid_595130 = validateParameter(valid_595130, JString, required = false,
                                 default = nil)
  if valid_595130 != nil:
    section.add "X-Amz-Credential", valid_595130
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595132: Call_GetParameterHistory_595118; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Query a list of all parameters used by the AWS account.
  ## 
  let valid = call_595132.validator(path, query, header, formData, body)
  let scheme = call_595132.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595132.url(scheme.get, call_595132.host, call_595132.base,
                         call_595132.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595132, url, valid)

proc call*(call_595133: Call_GetParameterHistory_595118; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## getParameterHistory
  ## Query a list of all parameters used by the AWS account.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_595134 = newJObject()
  var body_595135 = newJObject()
  add(query_595134, "NextToken", newJString(NextToken))
  if body != nil:
    body_595135 = body
  add(query_595134, "MaxResults", newJString(MaxResults))
  result = call_595133.call(nil, query_595134, nil, nil, body_595135)

var getParameterHistory* = Call_GetParameterHistory_595118(
    name: "getParameterHistory", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetParameterHistory",
    validator: validate_GetParameterHistory_595119, base: "/",
    url: url_GetParameterHistory_595120, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetParameters_595136 = ref object of OpenApiRestCall_593437
proc url_GetParameters_595138(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetParameters_595137(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_595139 = header.getOrDefault("X-Amz-Date")
  valid_595139 = validateParameter(valid_595139, JString, required = false,
                                 default = nil)
  if valid_595139 != nil:
    section.add "X-Amz-Date", valid_595139
  var valid_595140 = header.getOrDefault("X-Amz-Security-Token")
  valid_595140 = validateParameter(valid_595140, JString, required = false,
                                 default = nil)
  if valid_595140 != nil:
    section.add "X-Amz-Security-Token", valid_595140
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595141 = header.getOrDefault("X-Amz-Target")
  valid_595141 = validateParameter(valid_595141, JString, required = true, default = newJString(
      "AmazonSSM.GetParameters"))
  if valid_595141 != nil:
    section.add "X-Amz-Target", valid_595141
  var valid_595142 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595142 = validateParameter(valid_595142, JString, required = false,
                                 default = nil)
  if valid_595142 != nil:
    section.add "X-Amz-Content-Sha256", valid_595142
  var valid_595143 = header.getOrDefault("X-Amz-Algorithm")
  valid_595143 = validateParameter(valid_595143, JString, required = false,
                                 default = nil)
  if valid_595143 != nil:
    section.add "X-Amz-Algorithm", valid_595143
  var valid_595144 = header.getOrDefault("X-Amz-Signature")
  valid_595144 = validateParameter(valid_595144, JString, required = false,
                                 default = nil)
  if valid_595144 != nil:
    section.add "X-Amz-Signature", valid_595144
  var valid_595145 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595145 = validateParameter(valid_595145, JString, required = false,
                                 default = nil)
  if valid_595145 != nil:
    section.add "X-Amz-SignedHeaders", valid_595145
  var valid_595146 = header.getOrDefault("X-Amz-Credential")
  valid_595146 = validateParameter(valid_595146, JString, required = false,
                                 default = nil)
  if valid_595146 != nil:
    section.add "X-Amz-Credential", valid_595146
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595148: Call_GetParameters_595136; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Get details of a parameter. Don't confuse this API action with the <a>GetParameter</a> API action.
  ## 
  let valid = call_595148.validator(path, query, header, formData, body)
  let scheme = call_595148.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595148.url(scheme.get, call_595148.host, call_595148.base,
                         call_595148.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595148, url, valid)

proc call*(call_595149: Call_GetParameters_595136; body: JsonNode): Recallable =
  ## getParameters
  ## Get details of a parameter. Don't confuse this API action with the <a>GetParameter</a> API action.
  ##   body: JObject (required)
  var body_595150 = newJObject()
  if body != nil:
    body_595150 = body
  result = call_595149.call(nil, nil, nil, nil, body_595150)

var getParameters* = Call_GetParameters_595136(name: "getParameters",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetParameters",
    validator: validate_GetParameters_595137, base: "/", url: url_GetParameters_595138,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetParametersByPath_595151 = ref object of OpenApiRestCall_593437
proc url_GetParametersByPath_595153(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetParametersByPath_595152(path: JsonNode; query: JsonNode;
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
  var valid_595154 = query.getOrDefault("NextToken")
  valid_595154 = validateParameter(valid_595154, JString, required = false,
                                 default = nil)
  if valid_595154 != nil:
    section.add "NextToken", valid_595154
  var valid_595155 = query.getOrDefault("MaxResults")
  valid_595155 = validateParameter(valid_595155, JString, required = false,
                                 default = nil)
  if valid_595155 != nil:
    section.add "MaxResults", valid_595155
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
  var valid_595156 = header.getOrDefault("X-Amz-Date")
  valid_595156 = validateParameter(valid_595156, JString, required = false,
                                 default = nil)
  if valid_595156 != nil:
    section.add "X-Amz-Date", valid_595156
  var valid_595157 = header.getOrDefault("X-Amz-Security-Token")
  valid_595157 = validateParameter(valid_595157, JString, required = false,
                                 default = nil)
  if valid_595157 != nil:
    section.add "X-Amz-Security-Token", valid_595157
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595158 = header.getOrDefault("X-Amz-Target")
  valid_595158 = validateParameter(valid_595158, JString, required = true, default = newJString(
      "AmazonSSM.GetParametersByPath"))
  if valid_595158 != nil:
    section.add "X-Amz-Target", valid_595158
  var valid_595159 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595159 = validateParameter(valid_595159, JString, required = false,
                                 default = nil)
  if valid_595159 != nil:
    section.add "X-Amz-Content-Sha256", valid_595159
  var valid_595160 = header.getOrDefault("X-Amz-Algorithm")
  valid_595160 = validateParameter(valid_595160, JString, required = false,
                                 default = nil)
  if valid_595160 != nil:
    section.add "X-Amz-Algorithm", valid_595160
  var valid_595161 = header.getOrDefault("X-Amz-Signature")
  valid_595161 = validateParameter(valid_595161, JString, required = false,
                                 default = nil)
  if valid_595161 != nil:
    section.add "X-Amz-Signature", valid_595161
  var valid_595162 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595162 = validateParameter(valid_595162, JString, required = false,
                                 default = nil)
  if valid_595162 != nil:
    section.add "X-Amz-SignedHeaders", valid_595162
  var valid_595163 = header.getOrDefault("X-Amz-Credential")
  valid_595163 = validateParameter(valid_595163, JString, required = false,
                                 default = nil)
  if valid_595163 != nil:
    section.add "X-Amz-Credential", valid_595163
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595165: Call_GetParametersByPath_595151; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieve parameters in a specific hierarchy. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/sysman-paramstore-working.html">Working with Systems Manager Parameters</a> in the <i>AWS Systems Manager User Guide</i>. </p> <p>Request results are returned on a best-effort basis. If you specify <code>MaxResults</code> in the request, the response includes information up to the limit specified. The number of items returned, however, can be between zero and the value of <code>MaxResults</code>. If the service reaches an internal limit while processing the results, it stops the operation and returns the matching values up to that point and a <code>NextToken</code>. You can specify the <code>NextToken</code> in a subsequent call to get the next set of results.</p> <note> <p>This API action doesn't support filtering by tags. </p> </note>
  ## 
  let valid = call_595165.validator(path, query, header, formData, body)
  let scheme = call_595165.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595165.url(scheme.get, call_595165.host, call_595165.base,
                         call_595165.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595165, url, valid)

proc call*(call_595166: Call_GetParametersByPath_595151; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## getParametersByPath
  ## <p>Retrieve parameters in a specific hierarchy. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/sysman-paramstore-working.html">Working with Systems Manager Parameters</a> in the <i>AWS Systems Manager User Guide</i>. </p> <p>Request results are returned on a best-effort basis. If you specify <code>MaxResults</code> in the request, the response includes information up to the limit specified. The number of items returned, however, can be between zero and the value of <code>MaxResults</code>. If the service reaches an internal limit while processing the results, it stops the operation and returns the matching values up to that point and a <code>NextToken</code>. You can specify the <code>NextToken</code> in a subsequent call to get the next set of results.</p> <note> <p>This API action doesn't support filtering by tags. </p> </note>
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_595167 = newJObject()
  var body_595168 = newJObject()
  add(query_595167, "NextToken", newJString(NextToken))
  if body != nil:
    body_595168 = body
  add(query_595167, "MaxResults", newJString(MaxResults))
  result = call_595166.call(nil, query_595167, nil, nil, body_595168)

var getParametersByPath* = Call_GetParametersByPath_595151(
    name: "getParametersByPath", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetParametersByPath",
    validator: validate_GetParametersByPath_595152, base: "/",
    url: url_GetParametersByPath_595153, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPatchBaseline_595169 = ref object of OpenApiRestCall_593437
proc url_GetPatchBaseline_595171(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetPatchBaseline_595170(path: JsonNode; query: JsonNode;
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
  var valid_595172 = header.getOrDefault("X-Amz-Date")
  valid_595172 = validateParameter(valid_595172, JString, required = false,
                                 default = nil)
  if valid_595172 != nil:
    section.add "X-Amz-Date", valid_595172
  var valid_595173 = header.getOrDefault("X-Amz-Security-Token")
  valid_595173 = validateParameter(valid_595173, JString, required = false,
                                 default = nil)
  if valid_595173 != nil:
    section.add "X-Amz-Security-Token", valid_595173
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595174 = header.getOrDefault("X-Amz-Target")
  valid_595174 = validateParameter(valid_595174, JString, required = true, default = newJString(
      "AmazonSSM.GetPatchBaseline"))
  if valid_595174 != nil:
    section.add "X-Amz-Target", valid_595174
  var valid_595175 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595175 = validateParameter(valid_595175, JString, required = false,
                                 default = nil)
  if valid_595175 != nil:
    section.add "X-Amz-Content-Sha256", valid_595175
  var valid_595176 = header.getOrDefault("X-Amz-Algorithm")
  valid_595176 = validateParameter(valid_595176, JString, required = false,
                                 default = nil)
  if valid_595176 != nil:
    section.add "X-Amz-Algorithm", valid_595176
  var valid_595177 = header.getOrDefault("X-Amz-Signature")
  valid_595177 = validateParameter(valid_595177, JString, required = false,
                                 default = nil)
  if valid_595177 != nil:
    section.add "X-Amz-Signature", valid_595177
  var valid_595178 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595178 = validateParameter(valid_595178, JString, required = false,
                                 default = nil)
  if valid_595178 != nil:
    section.add "X-Amz-SignedHeaders", valid_595178
  var valid_595179 = header.getOrDefault("X-Amz-Credential")
  valid_595179 = validateParameter(valid_595179, JString, required = false,
                                 default = nil)
  if valid_595179 != nil:
    section.add "X-Amz-Credential", valid_595179
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595181: Call_GetPatchBaseline_595169; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a patch baseline.
  ## 
  let valid = call_595181.validator(path, query, header, formData, body)
  let scheme = call_595181.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595181.url(scheme.get, call_595181.host, call_595181.base,
                         call_595181.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595181, url, valid)

proc call*(call_595182: Call_GetPatchBaseline_595169; body: JsonNode): Recallable =
  ## getPatchBaseline
  ## Retrieves information about a patch baseline.
  ##   body: JObject (required)
  var body_595183 = newJObject()
  if body != nil:
    body_595183 = body
  result = call_595182.call(nil, nil, nil, nil, body_595183)

var getPatchBaseline* = Call_GetPatchBaseline_595169(name: "getPatchBaseline",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetPatchBaseline",
    validator: validate_GetPatchBaseline_595170, base: "/",
    url: url_GetPatchBaseline_595171, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPatchBaselineForPatchGroup_595184 = ref object of OpenApiRestCall_593437
proc url_GetPatchBaselineForPatchGroup_595186(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetPatchBaselineForPatchGroup_595185(path: JsonNode; query: JsonNode;
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
  var valid_595187 = header.getOrDefault("X-Amz-Date")
  valid_595187 = validateParameter(valid_595187, JString, required = false,
                                 default = nil)
  if valid_595187 != nil:
    section.add "X-Amz-Date", valid_595187
  var valid_595188 = header.getOrDefault("X-Amz-Security-Token")
  valid_595188 = validateParameter(valid_595188, JString, required = false,
                                 default = nil)
  if valid_595188 != nil:
    section.add "X-Amz-Security-Token", valid_595188
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595189 = header.getOrDefault("X-Amz-Target")
  valid_595189 = validateParameter(valid_595189, JString, required = true, default = newJString(
      "AmazonSSM.GetPatchBaselineForPatchGroup"))
  if valid_595189 != nil:
    section.add "X-Amz-Target", valid_595189
  var valid_595190 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595190 = validateParameter(valid_595190, JString, required = false,
                                 default = nil)
  if valid_595190 != nil:
    section.add "X-Amz-Content-Sha256", valid_595190
  var valid_595191 = header.getOrDefault("X-Amz-Algorithm")
  valid_595191 = validateParameter(valid_595191, JString, required = false,
                                 default = nil)
  if valid_595191 != nil:
    section.add "X-Amz-Algorithm", valid_595191
  var valid_595192 = header.getOrDefault("X-Amz-Signature")
  valid_595192 = validateParameter(valid_595192, JString, required = false,
                                 default = nil)
  if valid_595192 != nil:
    section.add "X-Amz-Signature", valid_595192
  var valid_595193 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595193 = validateParameter(valid_595193, JString, required = false,
                                 default = nil)
  if valid_595193 != nil:
    section.add "X-Amz-SignedHeaders", valid_595193
  var valid_595194 = header.getOrDefault("X-Amz-Credential")
  valid_595194 = validateParameter(valid_595194, JString, required = false,
                                 default = nil)
  if valid_595194 != nil:
    section.add "X-Amz-Credential", valid_595194
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595196: Call_GetPatchBaselineForPatchGroup_595184; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the patch baseline that should be used for the specified patch group.
  ## 
  let valid = call_595196.validator(path, query, header, formData, body)
  let scheme = call_595196.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595196.url(scheme.get, call_595196.host, call_595196.base,
                         call_595196.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595196, url, valid)

proc call*(call_595197: Call_GetPatchBaselineForPatchGroup_595184; body: JsonNode): Recallable =
  ## getPatchBaselineForPatchGroup
  ## Retrieves the patch baseline that should be used for the specified patch group.
  ##   body: JObject (required)
  var body_595198 = newJObject()
  if body != nil:
    body_595198 = body
  result = call_595197.call(nil, nil, nil, nil, body_595198)

var getPatchBaselineForPatchGroup* = Call_GetPatchBaselineForPatchGroup_595184(
    name: "getPatchBaselineForPatchGroup", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetPatchBaselineForPatchGroup",
    validator: validate_GetPatchBaselineForPatchGroup_595185, base: "/",
    url: url_GetPatchBaselineForPatchGroup_595186,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetServiceSetting_595199 = ref object of OpenApiRestCall_593437
proc url_GetServiceSetting_595201(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetServiceSetting_595200(path: JsonNode; query: JsonNode;
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
  var valid_595202 = header.getOrDefault("X-Amz-Date")
  valid_595202 = validateParameter(valid_595202, JString, required = false,
                                 default = nil)
  if valid_595202 != nil:
    section.add "X-Amz-Date", valid_595202
  var valid_595203 = header.getOrDefault("X-Amz-Security-Token")
  valid_595203 = validateParameter(valid_595203, JString, required = false,
                                 default = nil)
  if valid_595203 != nil:
    section.add "X-Amz-Security-Token", valid_595203
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595204 = header.getOrDefault("X-Amz-Target")
  valid_595204 = validateParameter(valid_595204, JString, required = true, default = newJString(
      "AmazonSSM.GetServiceSetting"))
  if valid_595204 != nil:
    section.add "X-Amz-Target", valid_595204
  var valid_595205 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595205 = validateParameter(valid_595205, JString, required = false,
                                 default = nil)
  if valid_595205 != nil:
    section.add "X-Amz-Content-Sha256", valid_595205
  var valid_595206 = header.getOrDefault("X-Amz-Algorithm")
  valid_595206 = validateParameter(valid_595206, JString, required = false,
                                 default = nil)
  if valid_595206 != nil:
    section.add "X-Amz-Algorithm", valid_595206
  var valid_595207 = header.getOrDefault("X-Amz-Signature")
  valid_595207 = validateParameter(valid_595207, JString, required = false,
                                 default = nil)
  if valid_595207 != nil:
    section.add "X-Amz-Signature", valid_595207
  var valid_595208 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595208 = validateParameter(valid_595208, JString, required = false,
                                 default = nil)
  if valid_595208 != nil:
    section.add "X-Amz-SignedHeaders", valid_595208
  var valid_595209 = header.getOrDefault("X-Amz-Credential")
  valid_595209 = validateParameter(valid_595209, JString, required = false,
                                 default = nil)
  if valid_595209 != nil:
    section.add "X-Amz-Credential", valid_595209
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595211: Call_GetServiceSetting_595199; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> <code>ServiceSetting</code> is an account-level setting for an AWS service. This setting defines how a user interacts with or uses a service or a feature of a service. For example, if an AWS service charges money to the account based on feature or service usage, then the AWS service team might create a default setting of "false". This means the user can't use this feature unless they change the setting to "true" and intentionally opt in for a paid feature.</p> <p>Services map a <code>SettingId</code> object to a setting value. AWS services teams define the default value for a <code>SettingId</code>. You can't create a new <code>SettingId</code>, but you can overwrite the default value if you have the <code>ssm:UpdateServiceSetting</code> permission for the setting. Use the <a>UpdateServiceSetting</a> API action to change the default setting. Or use the <a>ResetServiceSetting</a> to change the value back to the original value defined by the AWS service team.</p> <p>Query the current service setting for the account. </p>
  ## 
  let valid = call_595211.validator(path, query, header, formData, body)
  let scheme = call_595211.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595211.url(scheme.get, call_595211.host, call_595211.base,
                         call_595211.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595211, url, valid)

proc call*(call_595212: Call_GetServiceSetting_595199; body: JsonNode): Recallable =
  ## getServiceSetting
  ## <p> <code>ServiceSetting</code> is an account-level setting for an AWS service. This setting defines how a user interacts with or uses a service or a feature of a service. For example, if an AWS service charges money to the account based on feature or service usage, then the AWS service team might create a default setting of "false". This means the user can't use this feature unless they change the setting to "true" and intentionally opt in for a paid feature.</p> <p>Services map a <code>SettingId</code> object to a setting value. AWS services teams define the default value for a <code>SettingId</code>. You can't create a new <code>SettingId</code>, but you can overwrite the default value if you have the <code>ssm:UpdateServiceSetting</code> permission for the setting. Use the <a>UpdateServiceSetting</a> API action to change the default setting. Or use the <a>ResetServiceSetting</a> to change the value back to the original value defined by the AWS service team.</p> <p>Query the current service setting for the account. </p>
  ##   body: JObject (required)
  var body_595213 = newJObject()
  if body != nil:
    body_595213 = body
  result = call_595212.call(nil, nil, nil, nil, body_595213)

var getServiceSetting* = Call_GetServiceSetting_595199(name: "getServiceSetting",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetServiceSetting",
    validator: validate_GetServiceSetting_595200, base: "/",
    url: url_GetServiceSetting_595201, schemes: {Scheme.Https, Scheme.Http})
type
  Call_LabelParameterVersion_595214 = ref object of OpenApiRestCall_593437
proc url_LabelParameterVersion_595216(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_LabelParameterVersion_595215(path: JsonNode; query: JsonNode;
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
  var valid_595217 = header.getOrDefault("X-Amz-Date")
  valid_595217 = validateParameter(valid_595217, JString, required = false,
                                 default = nil)
  if valid_595217 != nil:
    section.add "X-Amz-Date", valid_595217
  var valid_595218 = header.getOrDefault("X-Amz-Security-Token")
  valid_595218 = validateParameter(valid_595218, JString, required = false,
                                 default = nil)
  if valid_595218 != nil:
    section.add "X-Amz-Security-Token", valid_595218
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595219 = header.getOrDefault("X-Amz-Target")
  valid_595219 = validateParameter(valid_595219, JString, required = true, default = newJString(
      "AmazonSSM.LabelParameterVersion"))
  if valid_595219 != nil:
    section.add "X-Amz-Target", valid_595219
  var valid_595220 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595220 = validateParameter(valid_595220, JString, required = false,
                                 default = nil)
  if valid_595220 != nil:
    section.add "X-Amz-Content-Sha256", valid_595220
  var valid_595221 = header.getOrDefault("X-Amz-Algorithm")
  valid_595221 = validateParameter(valid_595221, JString, required = false,
                                 default = nil)
  if valid_595221 != nil:
    section.add "X-Amz-Algorithm", valid_595221
  var valid_595222 = header.getOrDefault("X-Amz-Signature")
  valid_595222 = validateParameter(valid_595222, JString, required = false,
                                 default = nil)
  if valid_595222 != nil:
    section.add "X-Amz-Signature", valid_595222
  var valid_595223 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595223 = validateParameter(valid_595223, JString, required = false,
                                 default = nil)
  if valid_595223 != nil:
    section.add "X-Amz-SignedHeaders", valid_595223
  var valid_595224 = header.getOrDefault("X-Amz-Credential")
  valid_595224 = validateParameter(valid_595224, JString, required = false,
                                 default = nil)
  if valid_595224 != nil:
    section.add "X-Amz-Credential", valid_595224
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595226: Call_LabelParameterVersion_595214; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>A parameter label is a user-defined alias to help you manage different versions of a parameter. When you modify a parameter, Systems Manager automatically saves a new version and increments the version number by one. A label can help you remember the purpose of a parameter when there are multiple versions. </p> <p>Parameter labels have the following requirements and restrictions.</p> <ul> <li> <p>A version of a parameter can have a maximum of 10 labels.</p> </li> <li> <p>You can't attach the same label to different versions of the same parameter. For example, if version 1 has the label Production, then you can't attach Production to version 2.</p> </li> <li> <p>You can move a label from one version of a parameter to another.</p> </li> <li> <p>You can't create a label when you create a new parameter. You must attach a label to a specific version of a parameter.</p> </li> <li> <p>You can't delete a parameter label. If you no longer want to use a parameter label, then you must move it to a different version of a parameter.</p> </li> <li> <p>A label can have a maximum of 100 characters.</p> </li> <li> <p>Labels can contain letters (case sensitive), numbers, periods (.), hyphens (-), or underscores (_).</p> </li> <li> <p>Labels can't begin with a number, "aws," or "ssm" (not case sensitive). If a label fails to meet these requirements, then the label is not associated with a parameter and the system displays it in the list of InvalidLabels.</p> </li> </ul>
  ## 
  let valid = call_595226.validator(path, query, header, formData, body)
  let scheme = call_595226.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595226.url(scheme.get, call_595226.host, call_595226.base,
                         call_595226.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595226, url, valid)

proc call*(call_595227: Call_LabelParameterVersion_595214; body: JsonNode): Recallable =
  ## labelParameterVersion
  ## <p>A parameter label is a user-defined alias to help you manage different versions of a parameter. When you modify a parameter, Systems Manager automatically saves a new version and increments the version number by one. A label can help you remember the purpose of a parameter when there are multiple versions. </p> <p>Parameter labels have the following requirements and restrictions.</p> <ul> <li> <p>A version of a parameter can have a maximum of 10 labels.</p> </li> <li> <p>You can't attach the same label to different versions of the same parameter. For example, if version 1 has the label Production, then you can't attach Production to version 2.</p> </li> <li> <p>You can move a label from one version of a parameter to another.</p> </li> <li> <p>You can't create a label when you create a new parameter. You must attach a label to a specific version of a parameter.</p> </li> <li> <p>You can't delete a parameter label. If you no longer want to use a parameter label, then you must move it to a different version of a parameter.</p> </li> <li> <p>A label can have a maximum of 100 characters.</p> </li> <li> <p>Labels can contain letters (case sensitive), numbers, periods (.), hyphens (-), or underscores (_).</p> </li> <li> <p>Labels can't begin with a number, "aws," or "ssm" (not case sensitive). If a label fails to meet these requirements, then the label is not associated with a parameter and the system displays it in the list of InvalidLabels.</p> </li> </ul>
  ##   body: JObject (required)
  var body_595228 = newJObject()
  if body != nil:
    body_595228 = body
  result = call_595227.call(nil, nil, nil, nil, body_595228)

var labelParameterVersion* = Call_LabelParameterVersion_595214(
    name: "labelParameterVersion", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.LabelParameterVersion",
    validator: validate_LabelParameterVersion_595215, base: "/",
    url: url_LabelParameterVersion_595216, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAssociationVersions_595229 = ref object of OpenApiRestCall_593437
proc url_ListAssociationVersions_595231(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListAssociationVersions_595230(path: JsonNode; query: JsonNode;
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
  var valid_595232 = header.getOrDefault("X-Amz-Date")
  valid_595232 = validateParameter(valid_595232, JString, required = false,
                                 default = nil)
  if valid_595232 != nil:
    section.add "X-Amz-Date", valid_595232
  var valid_595233 = header.getOrDefault("X-Amz-Security-Token")
  valid_595233 = validateParameter(valid_595233, JString, required = false,
                                 default = nil)
  if valid_595233 != nil:
    section.add "X-Amz-Security-Token", valid_595233
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595234 = header.getOrDefault("X-Amz-Target")
  valid_595234 = validateParameter(valid_595234, JString, required = true, default = newJString(
      "AmazonSSM.ListAssociationVersions"))
  if valid_595234 != nil:
    section.add "X-Amz-Target", valid_595234
  var valid_595235 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595235 = validateParameter(valid_595235, JString, required = false,
                                 default = nil)
  if valid_595235 != nil:
    section.add "X-Amz-Content-Sha256", valid_595235
  var valid_595236 = header.getOrDefault("X-Amz-Algorithm")
  valid_595236 = validateParameter(valid_595236, JString, required = false,
                                 default = nil)
  if valid_595236 != nil:
    section.add "X-Amz-Algorithm", valid_595236
  var valid_595237 = header.getOrDefault("X-Amz-Signature")
  valid_595237 = validateParameter(valid_595237, JString, required = false,
                                 default = nil)
  if valid_595237 != nil:
    section.add "X-Amz-Signature", valid_595237
  var valid_595238 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595238 = validateParameter(valid_595238, JString, required = false,
                                 default = nil)
  if valid_595238 != nil:
    section.add "X-Amz-SignedHeaders", valid_595238
  var valid_595239 = header.getOrDefault("X-Amz-Credential")
  valid_595239 = validateParameter(valid_595239, JString, required = false,
                                 default = nil)
  if valid_595239 != nil:
    section.add "X-Amz-Credential", valid_595239
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595241: Call_ListAssociationVersions_595229; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves all versions of an association for a specific association ID.
  ## 
  let valid = call_595241.validator(path, query, header, formData, body)
  let scheme = call_595241.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595241.url(scheme.get, call_595241.host, call_595241.base,
                         call_595241.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595241, url, valid)

proc call*(call_595242: Call_ListAssociationVersions_595229; body: JsonNode): Recallable =
  ## listAssociationVersions
  ## Retrieves all versions of an association for a specific association ID.
  ##   body: JObject (required)
  var body_595243 = newJObject()
  if body != nil:
    body_595243 = body
  result = call_595242.call(nil, nil, nil, nil, body_595243)

var listAssociationVersions* = Call_ListAssociationVersions_595229(
    name: "listAssociationVersions", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.ListAssociationVersions",
    validator: validate_ListAssociationVersions_595230, base: "/",
    url: url_ListAssociationVersions_595231, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAssociations_595244 = ref object of OpenApiRestCall_593437
proc url_ListAssociations_595246(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListAssociations_595245(path: JsonNode; query: JsonNode;
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
  var valid_595247 = query.getOrDefault("NextToken")
  valid_595247 = validateParameter(valid_595247, JString, required = false,
                                 default = nil)
  if valid_595247 != nil:
    section.add "NextToken", valid_595247
  var valid_595248 = query.getOrDefault("MaxResults")
  valid_595248 = validateParameter(valid_595248, JString, required = false,
                                 default = nil)
  if valid_595248 != nil:
    section.add "MaxResults", valid_595248
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
  var valid_595249 = header.getOrDefault("X-Amz-Date")
  valid_595249 = validateParameter(valid_595249, JString, required = false,
                                 default = nil)
  if valid_595249 != nil:
    section.add "X-Amz-Date", valid_595249
  var valid_595250 = header.getOrDefault("X-Amz-Security-Token")
  valid_595250 = validateParameter(valid_595250, JString, required = false,
                                 default = nil)
  if valid_595250 != nil:
    section.add "X-Amz-Security-Token", valid_595250
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595251 = header.getOrDefault("X-Amz-Target")
  valid_595251 = validateParameter(valid_595251, JString, required = true, default = newJString(
      "AmazonSSM.ListAssociations"))
  if valid_595251 != nil:
    section.add "X-Amz-Target", valid_595251
  var valid_595252 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595252 = validateParameter(valid_595252, JString, required = false,
                                 default = nil)
  if valid_595252 != nil:
    section.add "X-Amz-Content-Sha256", valid_595252
  var valid_595253 = header.getOrDefault("X-Amz-Algorithm")
  valid_595253 = validateParameter(valid_595253, JString, required = false,
                                 default = nil)
  if valid_595253 != nil:
    section.add "X-Amz-Algorithm", valid_595253
  var valid_595254 = header.getOrDefault("X-Amz-Signature")
  valid_595254 = validateParameter(valid_595254, JString, required = false,
                                 default = nil)
  if valid_595254 != nil:
    section.add "X-Amz-Signature", valid_595254
  var valid_595255 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595255 = validateParameter(valid_595255, JString, required = false,
                                 default = nil)
  if valid_595255 != nil:
    section.add "X-Amz-SignedHeaders", valid_595255
  var valid_595256 = header.getOrDefault("X-Amz-Credential")
  valid_595256 = validateParameter(valid_595256, JString, required = false,
                                 default = nil)
  if valid_595256 != nil:
    section.add "X-Amz-Credential", valid_595256
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595258: Call_ListAssociations_595244; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the associations for the specified Systems Manager document or instance.
  ## 
  let valid = call_595258.validator(path, query, header, formData, body)
  let scheme = call_595258.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595258.url(scheme.get, call_595258.host, call_595258.base,
                         call_595258.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595258, url, valid)

proc call*(call_595259: Call_ListAssociations_595244; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listAssociations
  ## Lists the associations for the specified Systems Manager document or instance.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_595260 = newJObject()
  var body_595261 = newJObject()
  add(query_595260, "NextToken", newJString(NextToken))
  if body != nil:
    body_595261 = body
  add(query_595260, "MaxResults", newJString(MaxResults))
  result = call_595259.call(nil, query_595260, nil, nil, body_595261)

var listAssociations* = Call_ListAssociations_595244(name: "listAssociations",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.ListAssociations",
    validator: validate_ListAssociations_595245, base: "/",
    url: url_ListAssociations_595246, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListCommandInvocations_595262 = ref object of OpenApiRestCall_593437
proc url_ListCommandInvocations_595264(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListCommandInvocations_595263(path: JsonNode; query: JsonNode;
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
  var valid_595265 = query.getOrDefault("NextToken")
  valid_595265 = validateParameter(valid_595265, JString, required = false,
                                 default = nil)
  if valid_595265 != nil:
    section.add "NextToken", valid_595265
  var valid_595266 = query.getOrDefault("MaxResults")
  valid_595266 = validateParameter(valid_595266, JString, required = false,
                                 default = nil)
  if valid_595266 != nil:
    section.add "MaxResults", valid_595266
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
  var valid_595267 = header.getOrDefault("X-Amz-Date")
  valid_595267 = validateParameter(valid_595267, JString, required = false,
                                 default = nil)
  if valid_595267 != nil:
    section.add "X-Amz-Date", valid_595267
  var valid_595268 = header.getOrDefault("X-Amz-Security-Token")
  valid_595268 = validateParameter(valid_595268, JString, required = false,
                                 default = nil)
  if valid_595268 != nil:
    section.add "X-Amz-Security-Token", valid_595268
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595269 = header.getOrDefault("X-Amz-Target")
  valid_595269 = validateParameter(valid_595269, JString, required = true, default = newJString(
      "AmazonSSM.ListCommandInvocations"))
  if valid_595269 != nil:
    section.add "X-Amz-Target", valid_595269
  var valid_595270 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595270 = validateParameter(valid_595270, JString, required = false,
                                 default = nil)
  if valid_595270 != nil:
    section.add "X-Amz-Content-Sha256", valid_595270
  var valid_595271 = header.getOrDefault("X-Amz-Algorithm")
  valid_595271 = validateParameter(valid_595271, JString, required = false,
                                 default = nil)
  if valid_595271 != nil:
    section.add "X-Amz-Algorithm", valid_595271
  var valid_595272 = header.getOrDefault("X-Amz-Signature")
  valid_595272 = validateParameter(valid_595272, JString, required = false,
                                 default = nil)
  if valid_595272 != nil:
    section.add "X-Amz-Signature", valid_595272
  var valid_595273 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595273 = validateParameter(valid_595273, JString, required = false,
                                 default = nil)
  if valid_595273 != nil:
    section.add "X-Amz-SignedHeaders", valid_595273
  var valid_595274 = header.getOrDefault("X-Amz-Credential")
  valid_595274 = validateParameter(valid_595274, JString, required = false,
                                 default = nil)
  if valid_595274 != nil:
    section.add "X-Amz-Credential", valid_595274
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595276: Call_ListCommandInvocations_595262; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## An invocation is copy of a command sent to a specific instance. A command can apply to one or more instances. A command invocation applies to one instance. For example, if a user runs SendCommand against three instances, then a command invocation is created for each requested instance ID. ListCommandInvocations provide status about command execution.
  ## 
  let valid = call_595276.validator(path, query, header, formData, body)
  let scheme = call_595276.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595276.url(scheme.get, call_595276.host, call_595276.base,
                         call_595276.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595276, url, valid)

proc call*(call_595277: Call_ListCommandInvocations_595262; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listCommandInvocations
  ## An invocation is copy of a command sent to a specific instance. A command can apply to one or more instances. A command invocation applies to one instance. For example, if a user runs SendCommand against three instances, then a command invocation is created for each requested instance ID. ListCommandInvocations provide status about command execution.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_595278 = newJObject()
  var body_595279 = newJObject()
  add(query_595278, "NextToken", newJString(NextToken))
  if body != nil:
    body_595279 = body
  add(query_595278, "MaxResults", newJString(MaxResults))
  result = call_595277.call(nil, query_595278, nil, nil, body_595279)

var listCommandInvocations* = Call_ListCommandInvocations_595262(
    name: "listCommandInvocations", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.ListCommandInvocations",
    validator: validate_ListCommandInvocations_595263, base: "/",
    url: url_ListCommandInvocations_595264, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListCommands_595280 = ref object of OpenApiRestCall_593437
proc url_ListCommands_595282(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListCommands_595281(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_595283 = query.getOrDefault("NextToken")
  valid_595283 = validateParameter(valid_595283, JString, required = false,
                                 default = nil)
  if valid_595283 != nil:
    section.add "NextToken", valid_595283
  var valid_595284 = query.getOrDefault("MaxResults")
  valid_595284 = validateParameter(valid_595284, JString, required = false,
                                 default = nil)
  if valid_595284 != nil:
    section.add "MaxResults", valid_595284
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
  var valid_595285 = header.getOrDefault("X-Amz-Date")
  valid_595285 = validateParameter(valid_595285, JString, required = false,
                                 default = nil)
  if valid_595285 != nil:
    section.add "X-Amz-Date", valid_595285
  var valid_595286 = header.getOrDefault("X-Amz-Security-Token")
  valid_595286 = validateParameter(valid_595286, JString, required = false,
                                 default = nil)
  if valid_595286 != nil:
    section.add "X-Amz-Security-Token", valid_595286
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595287 = header.getOrDefault("X-Amz-Target")
  valid_595287 = validateParameter(valid_595287, JString, required = true,
                                 default = newJString("AmazonSSM.ListCommands"))
  if valid_595287 != nil:
    section.add "X-Amz-Target", valid_595287
  var valid_595288 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595288 = validateParameter(valid_595288, JString, required = false,
                                 default = nil)
  if valid_595288 != nil:
    section.add "X-Amz-Content-Sha256", valid_595288
  var valid_595289 = header.getOrDefault("X-Amz-Algorithm")
  valid_595289 = validateParameter(valid_595289, JString, required = false,
                                 default = nil)
  if valid_595289 != nil:
    section.add "X-Amz-Algorithm", valid_595289
  var valid_595290 = header.getOrDefault("X-Amz-Signature")
  valid_595290 = validateParameter(valid_595290, JString, required = false,
                                 default = nil)
  if valid_595290 != nil:
    section.add "X-Amz-Signature", valid_595290
  var valid_595291 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595291 = validateParameter(valid_595291, JString, required = false,
                                 default = nil)
  if valid_595291 != nil:
    section.add "X-Amz-SignedHeaders", valid_595291
  var valid_595292 = header.getOrDefault("X-Amz-Credential")
  valid_595292 = validateParameter(valid_595292, JString, required = false,
                                 default = nil)
  if valid_595292 != nil:
    section.add "X-Amz-Credential", valid_595292
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595294: Call_ListCommands_595280; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the commands requested by users of the AWS account.
  ## 
  let valid = call_595294.validator(path, query, header, formData, body)
  let scheme = call_595294.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595294.url(scheme.get, call_595294.host, call_595294.base,
                         call_595294.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595294, url, valid)

proc call*(call_595295: Call_ListCommands_595280; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listCommands
  ## Lists the commands requested by users of the AWS account.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_595296 = newJObject()
  var body_595297 = newJObject()
  add(query_595296, "NextToken", newJString(NextToken))
  if body != nil:
    body_595297 = body
  add(query_595296, "MaxResults", newJString(MaxResults))
  result = call_595295.call(nil, query_595296, nil, nil, body_595297)

var listCommands* = Call_ListCommands_595280(name: "listCommands",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.ListCommands",
    validator: validate_ListCommands_595281, base: "/", url: url_ListCommands_595282,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListComplianceItems_595298 = ref object of OpenApiRestCall_593437
proc url_ListComplianceItems_595300(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListComplianceItems_595299(path: JsonNode; query: JsonNode;
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
  var valid_595301 = header.getOrDefault("X-Amz-Date")
  valid_595301 = validateParameter(valid_595301, JString, required = false,
                                 default = nil)
  if valid_595301 != nil:
    section.add "X-Amz-Date", valid_595301
  var valid_595302 = header.getOrDefault("X-Amz-Security-Token")
  valid_595302 = validateParameter(valid_595302, JString, required = false,
                                 default = nil)
  if valid_595302 != nil:
    section.add "X-Amz-Security-Token", valid_595302
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595303 = header.getOrDefault("X-Amz-Target")
  valid_595303 = validateParameter(valid_595303, JString, required = true, default = newJString(
      "AmazonSSM.ListComplianceItems"))
  if valid_595303 != nil:
    section.add "X-Amz-Target", valid_595303
  var valid_595304 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595304 = validateParameter(valid_595304, JString, required = false,
                                 default = nil)
  if valid_595304 != nil:
    section.add "X-Amz-Content-Sha256", valid_595304
  var valid_595305 = header.getOrDefault("X-Amz-Algorithm")
  valid_595305 = validateParameter(valid_595305, JString, required = false,
                                 default = nil)
  if valid_595305 != nil:
    section.add "X-Amz-Algorithm", valid_595305
  var valid_595306 = header.getOrDefault("X-Amz-Signature")
  valid_595306 = validateParameter(valid_595306, JString, required = false,
                                 default = nil)
  if valid_595306 != nil:
    section.add "X-Amz-Signature", valid_595306
  var valid_595307 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595307 = validateParameter(valid_595307, JString, required = false,
                                 default = nil)
  if valid_595307 != nil:
    section.add "X-Amz-SignedHeaders", valid_595307
  var valid_595308 = header.getOrDefault("X-Amz-Credential")
  valid_595308 = validateParameter(valid_595308, JString, required = false,
                                 default = nil)
  if valid_595308 != nil:
    section.add "X-Amz-Credential", valid_595308
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595310: Call_ListComplianceItems_595298; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## For a specified resource ID, this API action returns a list of compliance statuses for different resource types. Currently, you can only specify one resource ID per call. List results depend on the criteria specified in the filter. 
  ## 
  let valid = call_595310.validator(path, query, header, formData, body)
  let scheme = call_595310.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595310.url(scheme.get, call_595310.host, call_595310.base,
                         call_595310.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595310, url, valid)

proc call*(call_595311: Call_ListComplianceItems_595298; body: JsonNode): Recallable =
  ## listComplianceItems
  ## For a specified resource ID, this API action returns a list of compliance statuses for different resource types. Currently, you can only specify one resource ID per call. List results depend on the criteria specified in the filter. 
  ##   body: JObject (required)
  var body_595312 = newJObject()
  if body != nil:
    body_595312 = body
  result = call_595311.call(nil, nil, nil, nil, body_595312)

var listComplianceItems* = Call_ListComplianceItems_595298(
    name: "listComplianceItems", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.ListComplianceItems",
    validator: validate_ListComplianceItems_595299, base: "/",
    url: url_ListComplianceItems_595300, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListComplianceSummaries_595313 = ref object of OpenApiRestCall_593437
proc url_ListComplianceSummaries_595315(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListComplianceSummaries_595314(path: JsonNode; query: JsonNode;
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
  var valid_595316 = header.getOrDefault("X-Amz-Date")
  valid_595316 = validateParameter(valid_595316, JString, required = false,
                                 default = nil)
  if valid_595316 != nil:
    section.add "X-Amz-Date", valid_595316
  var valid_595317 = header.getOrDefault("X-Amz-Security-Token")
  valid_595317 = validateParameter(valid_595317, JString, required = false,
                                 default = nil)
  if valid_595317 != nil:
    section.add "X-Amz-Security-Token", valid_595317
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595318 = header.getOrDefault("X-Amz-Target")
  valid_595318 = validateParameter(valid_595318, JString, required = true, default = newJString(
      "AmazonSSM.ListComplianceSummaries"))
  if valid_595318 != nil:
    section.add "X-Amz-Target", valid_595318
  var valid_595319 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595319 = validateParameter(valid_595319, JString, required = false,
                                 default = nil)
  if valid_595319 != nil:
    section.add "X-Amz-Content-Sha256", valid_595319
  var valid_595320 = header.getOrDefault("X-Amz-Algorithm")
  valid_595320 = validateParameter(valid_595320, JString, required = false,
                                 default = nil)
  if valid_595320 != nil:
    section.add "X-Amz-Algorithm", valid_595320
  var valid_595321 = header.getOrDefault("X-Amz-Signature")
  valid_595321 = validateParameter(valid_595321, JString, required = false,
                                 default = nil)
  if valid_595321 != nil:
    section.add "X-Amz-Signature", valid_595321
  var valid_595322 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595322 = validateParameter(valid_595322, JString, required = false,
                                 default = nil)
  if valid_595322 != nil:
    section.add "X-Amz-SignedHeaders", valid_595322
  var valid_595323 = header.getOrDefault("X-Amz-Credential")
  valid_595323 = validateParameter(valid_595323, JString, required = false,
                                 default = nil)
  if valid_595323 != nil:
    section.add "X-Amz-Credential", valid_595323
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595325: Call_ListComplianceSummaries_595313; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a summary count of compliant and non-compliant resources for a compliance type. For example, this call can return State Manager associations, patches, or custom compliance types according to the filter criteria that you specify. 
  ## 
  let valid = call_595325.validator(path, query, header, formData, body)
  let scheme = call_595325.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595325.url(scheme.get, call_595325.host, call_595325.base,
                         call_595325.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595325, url, valid)

proc call*(call_595326: Call_ListComplianceSummaries_595313; body: JsonNode): Recallable =
  ## listComplianceSummaries
  ## Returns a summary count of compliant and non-compliant resources for a compliance type. For example, this call can return State Manager associations, patches, or custom compliance types according to the filter criteria that you specify. 
  ##   body: JObject (required)
  var body_595327 = newJObject()
  if body != nil:
    body_595327 = body
  result = call_595326.call(nil, nil, nil, nil, body_595327)

var listComplianceSummaries* = Call_ListComplianceSummaries_595313(
    name: "listComplianceSummaries", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.ListComplianceSummaries",
    validator: validate_ListComplianceSummaries_595314, base: "/",
    url: url_ListComplianceSummaries_595315, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDocumentVersions_595328 = ref object of OpenApiRestCall_593437
proc url_ListDocumentVersions_595330(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListDocumentVersions_595329(path: JsonNode; query: JsonNode;
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
  var valid_595331 = header.getOrDefault("X-Amz-Date")
  valid_595331 = validateParameter(valid_595331, JString, required = false,
                                 default = nil)
  if valid_595331 != nil:
    section.add "X-Amz-Date", valid_595331
  var valid_595332 = header.getOrDefault("X-Amz-Security-Token")
  valid_595332 = validateParameter(valid_595332, JString, required = false,
                                 default = nil)
  if valid_595332 != nil:
    section.add "X-Amz-Security-Token", valid_595332
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595333 = header.getOrDefault("X-Amz-Target")
  valid_595333 = validateParameter(valid_595333, JString, required = true, default = newJString(
      "AmazonSSM.ListDocumentVersions"))
  if valid_595333 != nil:
    section.add "X-Amz-Target", valid_595333
  var valid_595334 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595334 = validateParameter(valid_595334, JString, required = false,
                                 default = nil)
  if valid_595334 != nil:
    section.add "X-Amz-Content-Sha256", valid_595334
  var valid_595335 = header.getOrDefault("X-Amz-Algorithm")
  valid_595335 = validateParameter(valid_595335, JString, required = false,
                                 default = nil)
  if valid_595335 != nil:
    section.add "X-Amz-Algorithm", valid_595335
  var valid_595336 = header.getOrDefault("X-Amz-Signature")
  valid_595336 = validateParameter(valid_595336, JString, required = false,
                                 default = nil)
  if valid_595336 != nil:
    section.add "X-Amz-Signature", valid_595336
  var valid_595337 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595337 = validateParameter(valid_595337, JString, required = false,
                                 default = nil)
  if valid_595337 != nil:
    section.add "X-Amz-SignedHeaders", valid_595337
  var valid_595338 = header.getOrDefault("X-Amz-Credential")
  valid_595338 = validateParameter(valid_595338, JString, required = false,
                                 default = nil)
  if valid_595338 != nil:
    section.add "X-Amz-Credential", valid_595338
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595340: Call_ListDocumentVersions_595328; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List all versions for a document.
  ## 
  let valid = call_595340.validator(path, query, header, formData, body)
  let scheme = call_595340.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595340.url(scheme.get, call_595340.host, call_595340.base,
                         call_595340.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595340, url, valid)

proc call*(call_595341: Call_ListDocumentVersions_595328; body: JsonNode): Recallable =
  ## listDocumentVersions
  ## List all versions for a document.
  ##   body: JObject (required)
  var body_595342 = newJObject()
  if body != nil:
    body_595342 = body
  result = call_595341.call(nil, nil, nil, nil, body_595342)

var listDocumentVersions* = Call_ListDocumentVersions_595328(
    name: "listDocumentVersions", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.ListDocumentVersions",
    validator: validate_ListDocumentVersions_595329, base: "/",
    url: url_ListDocumentVersions_595330, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDocuments_595343 = ref object of OpenApiRestCall_593437
proc url_ListDocuments_595345(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListDocuments_595344(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_595346 = query.getOrDefault("NextToken")
  valid_595346 = validateParameter(valid_595346, JString, required = false,
                                 default = nil)
  if valid_595346 != nil:
    section.add "NextToken", valid_595346
  var valid_595347 = query.getOrDefault("MaxResults")
  valid_595347 = validateParameter(valid_595347, JString, required = false,
                                 default = nil)
  if valid_595347 != nil:
    section.add "MaxResults", valid_595347
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
  var valid_595348 = header.getOrDefault("X-Amz-Date")
  valid_595348 = validateParameter(valid_595348, JString, required = false,
                                 default = nil)
  if valid_595348 != nil:
    section.add "X-Amz-Date", valid_595348
  var valid_595349 = header.getOrDefault("X-Amz-Security-Token")
  valid_595349 = validateParameter(valid_595349, JString, required = false,
                                 default = nil)
  if valid_595349 != nil:
    section.add "X-Amz-Security-Token", valid_595349
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595350 = header.getOrDefault("X-Amz-Target")
  valid_595350 = validateParameter(valid_595350, JString, required = true, default = newJString(
      "AmazonSSM.ListDocuments"))
  if valid_595350 != nil:
    section.add "X-Amz-Target", valid_595350
  var valid_595351 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595351 = validateParameter(valid_595351, JString, required = false,
                                 default = nil)
  if valid_595351 != nil:
    section.add "X-Amz-Content-Sha256", valid_595351
  var valid_595352 = header.getOrDefault("X-Amz-Algorithm")
  valid_595352 = validateParameter(valid_595352, JString, required = false,
                                 default = nil)
  if valid_595352 != nil:
    section.add "X-Amz-Algorithm", valid_595352
  var valid_595353 = header.getOrDefault("X-Amz-Signature")
  valid_595353 = validateParameter(valid_595353, JString, required = false,
                                 default = nil)
  if valid_595353 != nil:
    section.add "X-Amz-Signature", valid_595353
  var valid_595354 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595354 = validateParameter(valid_595354, JString, required = false,
                                 default = nil)
  if valid_595354 != nil:
    section.add "X-Amz-SignedHeaders", valid_595354
  var valid_595355 = header.getOrDefault("X-Amz-Credential")
  valid_595355 = validateParameter(valid_595355, JString, required = false,
                                 default = nil)
  if valid_595355 != nil:
    section.add "X-Amz-Credential", valid_595355
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595357: Call_ListDocuments_595343; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes one or more of your Systems Manager documents.
  ## 
  let valid = call_595357.validator(path, query, header, formData, body)
  let scheme = call_595357.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595357.url(scheme.get, call_595357.host, call_595357.base,
                         call_595357.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595357, url, valid)

proc call*(call_595358: Call_ListDocuments_595343; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listDocuments
  ## Describes one or more of your Systems Manager documents.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_595359 = newJObject()
  var body_595360 = newJObject()
  add(query_595359, "NextToken", newJString(NextToken))
  if body != nil:
    body_595360 = body
  add(query_595359, "MaxResults", newJString(MaxResults))
  result = call_595358.call(nil, query_595359, nil, nil, body_595360)

var listDocuments* = Call_ListDocuments_595343(name: "listDocuments",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.ListDocuments",
    validator: validate_ListDocuments_595344, base: "/", url: url_ListDocuments_595345,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListInventoryEntries_595361 = ref object of OpenApiRestCall_593437
proc url_ListInventoryEntries_595363(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListInventoryEntries_595362(path: JsonNode; query: JsonNode;
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
  var valid_595364 = header.getOrDefault("X-Amz-Date")
  valid_595364 = validateParameter(valid_595364, JString, required = false,
                                 default = nil)
  if valid_595364 != nil:
    section.add "X-Amz-Date", valid_595364
  var valid_595365 = header.getOrDefault("X-Amz-Security-Token")
  valid_595365 = validateParameter(valid_595365, JString, required = false,
                                 default = nil)
  if valid_595365 != nil:
    section.add "X-Amz-Security-Token", valid_595365
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595366 = header.getOrDefault("X-Amz-Target")
  valid_595366 = validateParameter(valid_595366, JString, required = true, default = newJString(
      "AmazonSSM.ListInventoryEntries"))
  if valid_595366 != nil:
    section.add "X-Amz-Target", valid_595366
  var valid_595367 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595367 = validateParameter(valid_595367, JString, required = false,
                                 default = nil)
  if valid_595367 != nil:
    section.add "X-Amz-Content-Sha256", valid_595367
  var valid_595368 = header.getOrDefault("X-Amz-Algorithm")
  valid_595368 = validateParameter(valid_595368, JString, required = false,
                                 default = nil)
  if valid_595368 != nil:
    section.add "X-Amz-Algorithm", valid_595368
  var valid_595369 = header.getOrDefault("X-Amz-Signature")
  valid_595369 = validateParameter(valid_595369, JString, required = false,
                                 default = nil)
  if valid_595369 != nil:
    section.add "X-Amz-Signature", valid_595369
  var valid_595370 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595370 = validateParameter(valid_595370, JString, required = false,
                                 default = nil)
  if valid_595370 != nil:
    section.add "X-Amz-SignedHeaders", valid_595370
  var valid_595371 = header.getOrDefault("X-Amz-Credential")
  valid_595371 = validateParameter(valid_595371, JString, required = false,
                                 default = nil)
  if valid_595371 != nil:
    section.add "X-Amz-Credential", valid_595371
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595373: Call_ListInventoryEntries_595361; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## A list of inventory items returned by the request.
  ## 
  let valid = call_595373.validator(path, query, header, formData, body)
  let scheme = call_595373.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595373.url(scheme.get, call_595373.host, call_595373.base,
                         call_595373.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595373, url, valid)

proc call*(call_595374: Call_ListInventoryEntries_595361; body: JsonNode): Recallable =
  ## listInventoryEntries
  ## A list of inventory items returned by the request.
  ##   body: JObject (required)
  var body_595375 = newJObject()
  if body != nil:
    body_595375 = body
  result = call_595374.call(nil, nil, nil, nil, body_595375)

var listInventoryEntries* = Call_ListInventoryEntries_595361(
    name: "listInventoryEntries", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.ListInventoryEntries",
    validator: validate_ListInventoryEntries_595362, base: "/",
    url: url_ListInventoryEntries_595363, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListResourceComplianceSummaries_595376 = ref object of OpenApiRestCall_593437
proc url_ListResourceComplianceSummaries_595378(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListResourceComplianceSummaries_595377(path: JsonNode;
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
  var valid_595379 = header.getOrDefault("X-Amz-Date")
  valid_595379 = validateParameter(valid_595379, JString, required = false,
                                 default = nil)
  if valid_595379 != nil:
    section.add "X-Amz-Date", valid_595379
  var valid_595380 = header.getOrDefault("X-Amz-Security-Token")
  valid_595380 = validateParameter(valid_595380, JString, required = false,
                                 default = nil)
  if valid_595380 != nil:
    section.add "X-Amz-Security-Token", valid_595380
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595381 = header.getOrDefault("X-Amz-Target")
  valid_595381 = validateParameter(valid_595381, JString, required = true, default = newJString(
      "AmazonSSM.ListResourceComplianceSummaries"))
  if valid_595381 != nil:
    section.add "X-Amz-Target", valid_595381
  var valid_595382 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595382 = validateParameter(valid_595382, JString, required = false,
                                 default = nil)
  if valid_595382 != nil:
    section.add "X-Amz-Content-Sha256", valid_595382
  var valid_595383 = header.getOrDefault("X-Amz-Algorithm")
  valid_595383 = validateParameter(valid_595383, JString, required = false,
                                 default = nil)
  if valid_595383 != nil:
    section.add "X-Amz-Algorithm", valid_595383
  var valid_595384 = header.getOrDefault("X-Amz-Signature")
  valid_595384 = validateParameter(valid_595384, JString, required = false,
                                 default = nil)
  if valid_595384 != nil:
    section.add "X-Amz-Signature", valid_595384
  var valid_595385 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595385 = validateParameter(valid_595385, JString, required = false,
                                 default = nil)
  if valid_595385 != nil:
    section.add "X-Amz-SignedHeaders", valid_595385
  var valid_595386 = header.getOrDefault("X-Amz-Credential")
  valid_595386 = validateParameter(valid_595386, JString, required = false,
                                 default = nil)
  if valid_595386 != nil:
    section.add "X-Amz-Credential", valid_595386
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595388: Call_ListResourceComplianceSummaries_595376;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns a resource-level summary count. The summary includes information about compliant and non-compliant statuses and detailed compliance-item severity counts, according to the filter criteria you specify.
  ## 
  let valid = call_595388.validator(path, query, header, formData, body)
  let scheme = call_595388.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595388.url(scheme.get, call_595388.host, call_595388.base,
                         call_595388.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595388, url, valid)

proc call*(call_595389: Call_ListResourceComplianceSummaries_595376; body: JsonNode): Recallable =
  ## listResourceComplianceSummaries
  ## Returns a resource-level summary count. The summary includes information about compliant and non-compliant statuses and detailed compliance-item severity counts, according to the filter criteria you specify.
  ##   body: JObject (required)
  var body_595390 = newJObject()
  if body != nil:
    body_595390 = body
  result = call_595389.call(nil, nil, nil, nil, body_595390)

var listResourceComplianceSummaries* = Call_ListResourceComplianceSummaries_595376(
    name: "listResourceComplianceSummaries", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.ListResourceComplianceSummaries",
    validator: validate_ListResourceComplianceSummaries_595377, base: "/",
    url: url_ListResourceComplianceSummaries_595378,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListResourceDataSync_595391 = ref object of OpenApiRestCall_593437
proc url_ListResourceDataSync_595393(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListResourceDataSync_595392(path: JsonNode; query: JsonNode;
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
  var valid_595394 = header.getOrDefault("X-Amz-Date")
  valid_595394 = validateParameter(valid_595394, JString, required = false,
                                 default = nil)
  if valid_595394 != nil:
    section.add "X-Amz-Date", valid_595394
  var valid_595395 = header.getOrDefault("X-Amz-Security-Token")
  valid_595395 = validateParameter(valid_595395, JString, required = false,
                                 default = nil)
  if valid_595395 != nil:
    section.add "X-Amz-Security-Token", valid_595395
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595396 = header.getOrDefault("X-Amz-Target")
  valid_595396 = validateParameter(valid_595396, JString, required = true, default = newJString(
      "AmazonSSM.ListResourceDataSync"))
  if valid_595396 != nil:
    section.add "X-Amz-Target", valid_595396
  var valid_595397 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595397 = validateParameter(valid_595397, JString, required = false,
                                 default = nil)
  if valid_595397 != nil:
    section.add "X-Amz-Content-Sha256", valid_595397
  var valid_595398 = header.getOrDefault("X-Amz-Algorithm")
  valid_595398 = validateParameter(valid_595398, JString, required = false,
                                 default = nil)
  if valid_595398 != nil:
    section.add "X-Amz-Algorithm", valid_595398
  var valid_595399 = header.getOrDefault("X-Amz-Signature")
  valid_595399 = validateParameter(valid_595399, JString, required = false,
                                 default = nil)
  if valid_595399 != nil:
    section.add "X-Amz-Signature", valid_595399
  var valid_595400 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595400 = validateParameter(valid_595400, JString, required = false,
                                 default = nil)
  if valid_595400 != nil:
    section.add "X-Amz-SignedHeaders", valid_595400
  var valid_595401 = header.getOrDefault("X-Amz-Credential")
  valid_595401 = validateParameter(valid_595401, JString, required = false,
                                 default = nil)
  if valid_595401 != nil:
    section.add "X-Amz-Credential", valid_595401
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595403: Call_ListResourceDataSync_595391; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists your resource data sync configurations. Includes information about the last time a sync attempted to start, the last sync status, and the last time a sync successfully completed.</p> <p>The number of sync configurations might be too large to return using a single call to <code>ListResourceDataSync</code>. You can limit the number of sync configurations returned by using the <code>MaxResults</code> parameter. To determine whether there are more sync configurations to list, check the value of <code>NextToken</code> in the output. If there are more sync configurations to list, you can request them by specifying the <code>NextToken</code> returned in the call to the parameter of a subsequent call. </p>
  ## 
  let valid = call_595403.validator(path, query, header, formData, body)
  let scheme = call_595403.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595403.url(scheme.get, call_595403.host, call_595403.base,
                         call_595403.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595403, url, valid)

proc call*(call_595404: Call_ListResourceDataSync_595391; body: JsonNode): Recallable =
  ## listResourceDataSync
  ## <p>Lists your resource data sync configurations. Includes information about the last time a sync attempted to start, the last sync status, and the last time a sync successfully completed.</p> <p>The number of sync configurations might be too large to return using a single call to <code>ListResourceDataSync</code>. You can limit the number of sync configurations returned by using the <code>MaxResults</code> parameter. To determine whether there are more sync configurations to list, check the value of <code>NextToken</code> in the output. If there are more sync configurations to list, you can request them by specifying the <code>NextToken</code> returned in the call to the parameter of a subsequent call. </p>
  ##   body: JObject (required)
  var body_595405 = newJObject()
  if body != nil:
    body_595405 = body
  result = call_595404.call(nil, nil, nil, nil, body_595405)

var listResourceDataSync* = Call_ListResourceDataSync_595391(
    name: "listResourceDataSync", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.ListResourceDataSync",
    validator: validate_ListResourceDataSync_595392, base: "/",
    url: url_ListResourceDataSync_595393, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_595406 = ref object of OpenApiRestCall_593437
proc url_ListTagsForResource_595408(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListTagsForResource_595407(path: JsonNode; query: JsonNode;
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
  var valid_595409 = header.getOrDefault("X-Amz-Date")
  valid_595409 = validateParameter(valid_595409, JString, required = false,
                                 default = nil)
  if valid_595409 != nil:
    section.add "X-Amz-Date", valid_595409
  var valid_595410 = header.getOrDefault("X-Amz-Security-Token")
  valid_595410 = validateParameter(valid_595410, JString, required = false,
                                 default = nil)
  if valid_595410 != nil:
    section.add "X-Amz-Security-Token", valid_595410
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595411 = header.getOrDefault("X-Amz-Target")
  valid_595411 = validateParameter(valid_595411, JString, required = true, default = newJString(
      "AmazonSSM.ListTagsForResource"))
  if valid_595411 != nil:
    section.add "X-Amz-Target", valid_595411
  var valid_595412 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595412 = validateParameter(valid_595412, JString, required = false,
                                 default = nil)
  if valid_595412 != nil:
    section.add "X-Amz-Content-Sha256", valid_595412
  var valid_595413 = header.getOrDefault("X-Amz-Algorithm")
  valid_595413 = validateParameter(valid_595413, JString, required = false,
                                 default = nil)
  if valid_595413 != nil:
    section.add "X-Amz-Algorithm", valid_595413
  var valid_595414 = header.getOrDefault("X-Amz-Signature")
  valid_595414 = validateParameter(valid_595414, JString, required = false,
                                 default = nil)
  if valid_595414 != nil:
    section.add "X-Amz-Signature", valid_595414
  var valid_595415 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595415 = validateParameter(valid_595415, JString, required = false,
                                 default = nil)
  if valid_595415 != nil:
    section.add "X-Amz-SignedHeaders", valid_595415
  var valid_595416 = header.getOrDefault("X-Amz-Credential")
  valid_595416 = validateParameter(valid_595416, JString, required = false,
                                 default = nil)
  if valid_595416 != nil:
    section.add "X-Amz-Credential", valid_595416
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595418: Call_ListTagsForResource_595406; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of the tags assigned to the specified resource.
  ## 
  let valid = call_595418.validator(path, query, header, formData, body)
  let scheme = call_595418.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595418.url(scheme.get, call_595418.host, call_595418.base,
                         call_595418.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595418, url, valid)

proc call*(call_595419: Call_ListTagsForResource_595406; body: JsonNode): Recallable =
  ## listTagsForResource
  ## Returns a list of the tags assigned to the specified resource.
  ##   body: JObject (required)
  var body_595420 = newJObject()
  if body != nil:
    body_595420 = body
  result = call_595419.call(nil, nil, nil, nil, body_595420)

var listTagsForResource* = Call_ListTagsForResource_595406(
    name: "listTagsForResource", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.ListTagsForResource",
    validator: validate_ListTagsForResource_595407, base: "/",
    url: url_ListTagsForResource_595408, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ModifyDocumentPermission_595421 = ref object of OpenApiRestCall_593437
proc url_ModifyDocumentPermission_595423(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ModifyDocumentPermission_595422(path: JsonNode; query: JsonNode;
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
  var valid_595424 = header.getOrDefault("X-Amz-Date")
  valid_595424 = validateParameter(valid_595424, JString, required = false,
                                 default = nil)
  if valid_595424 != nil:
    section.add "X-Amz-Date", valid_595424
  var valid_595425 = header.getOrDefault("X-Amz-Security-Token")
  valid_595425 = validateParameter(valid_595425, JString, required = false,
                                 default = nil)
  if valid_595425 != nil:
    section.add "X-Amz-Security-Token", valid_595425
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595426 = header.getOrDefault("X-Amz-Target")
  valid_595426 = validateParameter(valid_595426, JString, required = true, default = newJString(
      "AmazonSSM.ModifyDocumentPermission"))
  if valid_595426 != nil:
    section.add "X-Amz-Target", valid_595426
  var valid_595427 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595427 = validateParameter(valid_595427, JString, required = false,
                                 default = nil)
  if valid_595427 != nil:
    section.add "X-Amz-Content-Sha256", valid_595427
  var valid_595428 = header.getOrDefault("X-Amz-Algorithm")
  valid_595428 = validateParameter(valid_595428, JString, required = false,
                                 default = nil)
  if valid_595428 != nil:
    section.add "X-Amz-Algorithm", valid_595428
  var valid_595429 = header.getOrDefault("X-Amz-Signature")
  valid_595429 = validateParameter(valid_595429, JString, required = false,
                                 default = nil)
  if valid_595429 != nil:
    section.add "X-Amz-Signature", valid_595429
  var valid_595430 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595430 = validateParameter(valid_595430, JString, required = false,
                                 default = nil)
  if valid_595430 != nil:
    section.add "X-Amz-SignedHeaders", valid_595430
  var valid_595431 = header.getOrDefault("X-Amz-Credential")
  valid_595431 = validateParameter(valid_595431, JString, required = false,
                                 default = nil)
  if valid_595431 != nil:
    section.add "X-Amz-Credential", valid_595431
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595433: Call_ModifyDocumentPermission_595421; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Shares a Systems Manager document publicly or privately. If you share a document privately, you must specify the AWS user account IDs for those people who can use the document. If you share a document publicly, you must specify <i>All</i> as the account ID.
  ## 
  let valid = call_595433.validator(path, query, header, formData, body)
  let scheme = call_595433.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595433.url(scheme.get, call_595433.host, call_595433.base,
                         call_595433.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595433, url, valid)

proc call*(call_595434: Call_ModifyDocumentPermission_595421; body: JsonNode): Recallable =
  ## modifyDocumentPermission
  ## Shares a Systems Manager document publicly or privately. If you share a document privately, you must specify the AWS user account IDs for those people who can use the document. If you share a document publicly, you must specify <i>All</i> as the account ID.
  ##   body: JObject (required)
  var body_595435 = newJObject()
  if body != nil:
    body_595435 = body
  result = call_595434.call(nil, nil, nil, nil, body_595435)

var modifyDocumentPermission* = Call_ModifyDocumentPermission_595421(
    name: "modifyDocumentPermission", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.ModifyDocumentPermission",
    validator: validate_ModifyDocumentPermission_595422, base: "/",
    url: url_ModifyDocumentPermission_595423, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutComplianceItems_595436 = ref object of OpenApiRestCall_593437
proc url_PutComplianceItems_595438(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PutComplianceItems_595437(path: JsonNode; query: JsonNode;
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
  var valid_595439 = header.getOrDefault("X-Amz-Date")
  valid_595439 = validateParameter(valid_595439, JString, required = false,
                                 default = nil)
  if valid_595439 != nil:
    section.add "X-Amz-Date", valid_595439
  var valid_595440 = header.getOrDefault("X-Amz-Security-Token")
  valid_595440 = validateParameter(valid_595440, JString, required = false,
                                 default = nil)
  if valid_595440 != nil:
    section.add "X-Amz-Security-Token", valid_595440
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595441 = header.getOrDefault("X-Amz-Target")
  valid_595441 = validateParameter(valid_595441, JString, required = true, default = newJString(
      "AmazonSSM.PutComplianceItems"))
  if valid_595441 != nil:
    section.add "X-Amz-Target", valid_595441
  var valid_595442 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595442 = validateParameter(valid_595442, JString, required = false,
                                 default = nil)
  if valid_595442 != nil:
    section.add "X-Amz-Content-Sha256", valid_595442
  var valid_595443 = header.getOrDefault("X-Amz-Algorithm")
  valid_595443 = validateParameter(valid_595443, JString, required = false,
                                 default = nil)
  if valid_595443 != nil:
    section.add "X-Amz-Algorithm", valid_595443
  var valid_595444 = header.getOrDefault("X-Amz-Signature")
  valid_595444 = validateParameter(valid_595444, JString, required = false,
                                 default = nil)
  if valid_595444 != nil:
    section.add "X-Amz-Signature", valid_595444
  var valid_595445 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595445 = validateParameter(valid_595445, JString, required = false,
                                 default = nil)
  if valid_595445 != nil:
    section.add "X-Amz-SignedHeaders", valid_595445
  var valid_595446 = header.getOrDefault("X-Amz-Credential")
  valid_595446 = validateParameter(valid_595446, JString, required = false,
                                 default = nil)
  if valid_595446 != nil:
    section.add "X-Amz-Credential", valid_595446
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595448: Call_PutComplianceItems_595436; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Registers a compliance type and other compliance details on a designated resource. This action lets you register custom compliance details with a resource. This call overwrites existing compliance information on the resource, so you must provide a full list of compliance items each time that you send the request.</p> <p>ComplianceType can be one of the following:</p> <ul> <li> <p>ExecutionId: The execution ID when the patch, association, or custom compliance item was applied.</p> </li> <li> <p>ExecutionType: Specify patch, association, or Custom:<code>string</code>.</p> </li> <li> <p>ExecutionTime. The time the patch, association, or custom compliance item was applied to the instance.</p> </li> <li> <p>Id: The patch, association, or custom compliance ID.</p> </li> <li> <p>Title: A title.</p> </li> <li> <p>Status: The status of the compliance item. For example, <code>approved</code> for patches, or <code>Failed</code> for associations.</p> </li> <li> <p>Severity: A patch severity. For example, <code>critical</code>.</p> </li> <li> <p>DocumentName: A SSM document name. For example, AWS-RunPatchBaseline.</p> </li> <li> <p>DocumentVersion: An SSM document version number. For example, 4.</p> </li> <li> <p>Classification: A patch classification. For example, <code>security updates</code>.</p> </li> <li> <p>PatchBaselineId: A patch baseline ID.</p> </li> <li> <p>PatchSeverity: A patch severity. For example, <code>Critical</code>.</p> </li> <li> <p>PatchState: A patch state. For example, <code>InstancesWithFailedPatches</code>.</p> </li> <li> <p>PatchGroup: The name of a patch group.</p> </li> <li> <p>InstalledTime: The time the association, patch, or custom compliance item was applied to the resource. Specify the time by using the following format: yyyy-MM-dd'T'HH:mm:ss'Z'</p> </li> </ul>
  ## 
  let valid = call_595448.validator(path, query, header, formData, body)
  let scheme = call_595448.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595448.url(scheme.get, call_595448.host, call_595448.base,
                         call_595448.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595448, url, valid)

proc call*(call_595449: Call_PutComplianceItems_595436; body: JsonNode): Recallable =
  ## putComplianceItems
  ## <p>Registers a compliance type and other compliance details on a designated resource. This action lets you register custom compliance details with a resource. This call overwrites existing compliance information on the resource, so you must provide a full list of compliance items each time that you send the request.</p> <p>ComplianceType can be one of the following:</p> <ul> <li> <p>ExecutionId: The execution ID when the patch, association, or custom compliance item was applied.</p> </li> <li> <p>ExecutionType: Specify patch, association, or Custom:<code>string</code>.</p> </li> <li> <p>ExecutionTime. The time the patch, association, or custom compliance item was applied to the instance.</p> </li> <li> <p>Id: The patch, association, or custom compliance ID.</p> </li> <li> <p>Title: A title.</p> </li> <li> <p>Status: The status of the compliance item. For example, <code>approved</code> for patches, or <code>Failed</code> for associations.</p> </li> <li> <p>Severity: A patch severity. For example, <code>critical</code>.</p> </li> <li> <p>DocumentName: A SSM document name. For example, AWS-RunPatchBaseline.</p> </li> <li> <p>DocumentVersion: An SSM document version number. For example, 4.</p> </li> <li> <p>Classification: A patch classification. For example, <code>security updates</code>.</p> </li> <li> <p>PatchBaselineId: A patch baseline ID.</p> </li> <li> <p>PatchSeverity: A patch severity. For example, <code>Critical</code>.</p> </li> <li> <p>PatchState: A patch state. For example, <code>InstancesWithFailedPatches</code>.</p> </li> <li> <p>PatchGroup: The name of a patch group.</p> </li> <li> <p>InstalledTime: The time the association, patch, or custom compliance item was applied to the resource. Specify the time by using the following format: yyyy-MM-dd'T'HH:mm:ss'Z'</p> </li> </ul>
  ##   body: JObject (required)
  var body_595450 = newJObject()
  if body != nil:
    body_595450 = body
  result = call_595449.call(nil, nil, nil, nil, body_595450)

var putComplianceItems* = Call_PutComplianceItems_595436(
    name: "putComplianceItems", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.PutComplianceItems",
    validator: validate_PutComplianceItems_595437, base: "/",
    url: url_PutComplianceItems_595438, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutInventory_595451 = ref object of OpenApiRestCall_593437
proc url_PutInventory_595453(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PutInventory_595452(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_595454 = header.getOrDefault("X-Amz-Date")
  valid_595454 = validateParameter(valid_595454, JString, required = false,
                                 default = nil)
  if valid_595454 != nil:
    section.add "X-Amz-Date", valid_595454
  var valid_595455 = header.getOrDefault("X-Amz-Security-Token")
  valid_595455 = validateParameter(valid_595455, JString, required = false,
                                 default = nil)
  if valid_595455 != nil:
    section.add "X-Amz-Security-Token", valid_595455
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595456 = header.getOrDefault("X-Amz-Target")
  valid_595456 = validateParameter(valid_595456, JString, required = true,
                                 default = newJString("AmazonSSM.PutInventory"))
  if valid_595456 != nil:
    section.add "X-Amz-Target", valid_595456
  var valid_595457 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595457 = validateParameter(valid_595457, JString, required = false,
                                 default = nil)
  if valid_595457 != nil:
    section.add "X-Amz-Content-Sha256", valid_595457
  var valid_595458 = header.getOrDefault("X-Amz-Algorithm")
  valid_595458 = validateParameter(valid_595458, JString, required = false,
                                 default = nil)
  if valid_595458 != nil:
    section.add "X-Amz-Algorithm", valid_595458
  var valid_595459 = header.getOrDefault("X-Amz-Signature")
  valid_595459 = validateParameter(valid_595459, JString, required = false,
                                 default = nil)
  if valid_595459 != nil:
    section.add "X-Amz-Signature", valid_595459
  var valid_595460 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595460 = validateParameter(valid_595460, JString, required = false,
                                 default = nil)
  if valid_595460 != nil:
    section.add "X-Amz-SignedHeaders", valid_595460
  var valid_595461 = header.getOrDefault("X-Amz-Credential")
  valid_595461 = validateParameter(valid_595461, JString, required = false,
                                 default = nil)
  if valid_595461 != nil:
    section.add "X-Amz-Credential", valid_595461
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595463: Call_PutInventory_595451; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Bulk update custom inventory items on one more instance. The request adds an inventory item, if it doesn't already exist, or updates an inventory item, if it does exist.
  ## 
  let valid = call_595463.validator(path, query, header, formData, body)
  let scheme = call_595463.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595463.url(scheme.get, call_595463.host, call_595463.base,
                         call_595463.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595463, url, valid)

proc call*(call_595464: Call_PutInventory_595451; body: JsonNode): Recallable =
  ## putInventory
  ## Bulk update custom inventory items on one more instance. The request adds an inventory item, if it doesn't already exist, or updates an inventory item, if it does exist.
  ##   body: JObject (required)
  var body_595465 = newJObject()
  if body != nil:
    body_595465 = body
  result = call_595464.call(nil, nil, nil, nil, body_595465)

var putInventory* = Call_PutInventory_595451(name: "putInventory",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.PutInventory",
    validator: validate_PutInventory_595452, base: "/", url: url_PutInventory_595453,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutParameter_595466 = ref object of OpenApiRestCall_593437
proc url_PutParameter_595468(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PutParameter_595467(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_595469 = header.getOrDefault("X-Amz-Date")
  valid_595469 = validateParameter(valid_595469, JString, required = false,
                                 default = nil)
  if valid_595469 != nil:
    section.add "X-Amz-Date", valid_595469
  var valid_595470 = header.getOrDefault("X-Amz-Security-Token")
  valid_595470 = validateParameter(valid_595470, JString, required = false,
                                 default = nil)
  if valid_595470 != nil:
    section.add "X-Amz-Security-Token", valid_595470
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595471 = header.getOrDefault("X-Amz-Target")
  valid_595471 = validateParameter(valid_595471, JString, required = true,
                                 default = newJString("AmazonSSM.PutParameter"))
  if valid_595471 != nil:
    section.add "X-Amz-Target", valid_595471
  var valid_595472 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595472 = validateParameter(valid_595472, JString, required = false,
                                 default = nil)
  if valid_595472 != nil:
    section.add "X-Amz-Content-Sha256", valid_595472
  var valid_595473 = header.getOrDefault("X-Amz-Algorithm")
  valid_595473 = validateParameter(valid_595473, JString, required = false,
                                 default = nil)
  if valid_595473 != nil:
    section.add "X-Amz-Algorithm", valid_595473
  var valid_595474 = header.getOrDefault("X-Amz-Signature")
  valid_595474 = validateParameter(valid_595474, JString, required = false,
                                 default = nil)
  if valid_595474 != nil:
    section.add "X-Amz-Signature", valid_595474
  var valid_595475 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595475 = validateParameter(valid_595475, JString, required = false,
                                 default = nil)
  if valid_595475 != nil:
    section.add "X-Amz-SignedHeaders", valid_595475
  var valid_595476 = header.getOrDefault("X-Amz-Credential")
  valid_595476 = validateParameter(valid_595476, JString, required = false,
                                 default = nil)
  if valid_595476 != nil:
    section.add "X-Amz-Credential", valid_595476
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595478: Call_PutParameter_595466; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Add a parameter to the system.
  ## 
  let valid = call_595478.validator(path, query, header, formData, body)
  let scheme = call_595478.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595478.url(scheme.get, call_595478.host, call_595478.base,
                         call_595478.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595478, url, valid)

proc call*(call_595479: Call_PutParameter_595466; body: JsonNode): Recallable =
  ## putParameter
  ## Add a parameter to the system.
  ##   body: JObject (required)
  var body_595480 = newJObject()
  if body != nil:
    body_595480 = body
  result = call_595479.call(nil, nil, nil, nil, body_595480)

var putParameter* = Call_PutParameter_595466(name: "putParameter",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.PutParameter",
    validator: validate_PutParameter_595467, base: "/", url: url_PutParameter_595468,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RegisterDefaultPatchBaseline_595481 = ref object of OpenApiRestCall_593437
proc url_RegisterDefaultPatchBaseline_595483(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_RegisterDefaultPatchBaseline_595482(path: JsonNode; query: JsonNode;
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
  var valid_595484 = header.getOrDefault("X-Amz-Date")
  valid_595484 = validateParameter(valid_595484, JString, required = false,
                                 default = nil)
  if valid_595484 != nil:
    section.add "X-Amz-Date", valid_595484
  var valid_595485 = header.getOrDefault("X-Amz-Security-Token")
  valid_595485 = validateParameter(valid_595485, JString, required = false,
                                 default = nil)
  if valid_595485 != nil:
    section.add "X-Amz-Security-Token", valid_595485
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595486 = header.getOrDefault("X-Amz-Target")
  valid_595486 = validateParameter(valid_595486, JString, required = true, default = newJString(
      "AmazonSSM.RegisterDefaultPatchBaseline"))
  if valid_595486 != nil:
    section.add "X-Amz-Target", valid_595486
  var valid_595487 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595487 = validateParameter(valid_595487, JString, required = false,
                                 default = nil)
  if valid_595487 != nil:
    section.add "X-Amz-Content-Sha256", valid_595487
  var valid_595488 = header.getOrDefault("X-Amz-Algorithm")
  valid_595488 = validateParameter(valid_595488, JString, required = false,
                                 default = nil)
  if valid_595488 != nil:
    section.add "X-Amz-Algorithm", valid_595488
  var valid_595489 = header.getOrDefault("X-Amz-Signature")
  valid_595489 = validateParameter(valid_595489, JString, required = false,
                                 default = nil)
  if valid_595489 != nil:
    section.add "X-Amz-Signature", valid_595489
  var valid_595490 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595490 = validateParameter(valid_595490, JString, required = false,
                                 default = nil)
  if valid_595490 != nil:
    section.add "X-Amz-SignedHeaders", valid_595490
  var valid_595491 = header.getOrDefault("X-Amz-Credential")
  valid_595491 = validateParameter(valid_595491, JString, required = false,
                                 default = nil)
  if valid_595491 != nil:
    section.add "X-Amz-Credential", valid_595491
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595493: Call_RegisterDefaultPatchBaseline_595481; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Defines the default patch baseline for the relevant operating system.</p> <p>To reset the AWS predefined patch baseline as the default, specify the full patch baseline ARN as the baseline ID value. For example, for CentOS, specify <code>arn:aws:ssm:us-east-2:733109147000:patchbaseline/pb-0574b43a65ea646ed</code> instead of <code>pb-0574b43a65ea646ed</code>.</p>
  ## 
  let valid = call_595493.validator(path, query, header, formData, body)
  let scheme = call_595493.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595493.url(scheme.get, call_595493.host, call_595493.base,
                         call_595493.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595493, url, valid)

proc call*(call_595494: Call_RegisterDefaultPatchBaseline_595481; body: JsonNode): Recallable =
  ## registerDefaultPatchBaseline
  ## <p>Defines the default patch baseline for the relevant operating system.</p> <p>To reset the AWS predefined patch baseline as the default, specify the full patch baseline ARN as the baseline ID value. For example, for CentOS, specify <code>arn:aws:ssm:us-east-2:733109147000:patchbaseline/pb-0574b43a65ea646ed</code> instead of <code>pb-0574b43a65ea646ed</code>.</p>
  ##   body: JObject (required)
  var body_595495 = newJObject()
  if body != nil:
    body_595495 = body
  result = call_595494.call(nil, nil, nil, nil, body_595495)

var registerDefaultPatchBaseline* = Call_RegisterDefaultPatchBaseline_595481(
    name: "registerDefaultPatchBaseline", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.RegisterDefaultPatchBaseline",
    validator: validate_RegisterDefaultPatchBaseline_595482, base: "/",
    url: url_RegisterDefaultPatchBaseline_595483,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RegisterPatchBaselineForPatchGroup_595496 = ref object of OpenApiRestCall_593437
proc url_RegisterPatchBaselineForPatchGroup_595498(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_RegisterPatchBaselineForPatchGroup_595497(path: JsonNode;
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
  var valid_595499 = header.getOrDefault("X-Amz-Date")
  valid_595499 = validateParameter(valid_595499, JString, required = false,
                                 default = nil)
  if valid_595499 != nil:
    section.add "X-Amz-Date", valid_595499
  var valid_595500 = header.getOrDefault("X-Amz-Security-Token")
  valid_595500 = validateParameter(valid_595500, JString, required = false,
                                 default = nil)
  if valid_595500 != nil:
    section.add "X-Amz-Security-Token", valid_595500
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595501 = header.getOrDefault("X-Amz-Target")
  valid_595501 = validateParameter(valid_595501, JString, required = true, default = newJString(
      "AmazonSSM.RegisterPatchBaselineForPatchGroup"))
  if valid_595501 != nil:
    section.add "X-Amz-Target", valid_595501
  var valid_595502 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595502 = validateParameter(valid_595502, JString, required = false,
                                 default = nil)
  if valid_595502 != nil:
    section.add "X-Amz-Content-Sha256", valid_595502
  var valid_595503 = header.getOrDefault("X-Amz-Algorithm")
  valid_595503 = validateParameter(valid_595503, JString, required = false,
                                 default = nil)
  if valid_595503 != nil:
    section.add "X-Amz-Algorithm", valid_595503
  var valid_595504 = header.getOrDefault("X-Amz-Signature")
  valid_595504 = validateParameter(valid_595504, JString, required = false,
                                 default = nil)
  if valid_595504 != nil:
    section.add "X-Amz-Signature", valid_595504
  var valid_595505 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595505 = validateParameter(valid_595505, JString, required = false,
                                 default = nil)
  if valid_595505 != nil:
    section.add "X-Amz-SignedHeaders", valid_595505
  var valid_595506 = header.getOrDefault("X-Amz-Credential")
  valid_595506 = validateParameter(valid_595506, JString, required = false,
                                 default = nil)
  if valid_595506 != nil:
    section.add "X-Amz-Credential", valid_595506
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595508: Call_RegisterPatchBaselineForPatchGroup_595496;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Registers a patch baseline for a patch group.
  ## 
  let valid = call_595508.validator(path, query, header, formData, body)
  let scheme = call_595508.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595508.url(scheme.get, call_595508.host, call_595508.base,
                         call_595508.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595508, url, valid)

proc call*(call_595509: Call_RegisterPatchBaselineForPatchGroup_595496;
          body: JsonNode): Recallable =
  ## registerPatchBaselineForPatchGroup
  ## Registers a patch baseline for a patch group.
  ##   body: JObject (required)
  var body_595510 = newJObject()
  if body != nil:
    body_595510 = body
  result = call_595509.call(nil, nil, nil, nil, body_595510)

var registerPatchBaselineForPatchGroup* = Call_RegisterPatchBaselineForPatchGroup_595496(
    name: "registerPatchBaselineForPatchGroup", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.RegisterPatchBaselineForPatchGroup",
    validator: validate_RegisterPatchBaselineForPatchGroup_595497, base: "/",
    url: url_RegisterPatchBaselineForPatchGroup_595498,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RegisterTargetWithMaintenanceWindow_595511 = ref object of OpenApiRestCall_593437
proc url_RegisterTargetWithMaintenanceWindow_595513(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_RegisterTargetWithMaintenanceWindow_595512(path: JsonNode;
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
  var valid_595514 = header.getOrDefault("X-Amz-Date")
  valid_595514 = validateParameter(valid_595514, JString, required = false,
                                 default = nil)
  if valid_595514 != nil:
    section.add "X-Amz-Date", valid_595514
  var valid_595515 = header.getOrDefault("X-Amz-Security-Token")
  valid_595515 = validateParameter(valid_595515, JString, required = false,
                                 default = nil)
  if valid_595515 != nil:
    section.add "X-Amz-Security-Token", valid_595515
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595516 = header.getOrDefault("X-Amz-Target")
  valid_595516 = validateParameter(valid_595516, JString, required = true, default = newJString(
      "AmazonSSM.RegisterTargetWithMaintenanceWindow"))
  if valid_595516 != nil:
    section.add "X-Amz-Target", valid_595516
  var valid_595517 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595517 = validateParameter(valid_595517, JString, required = false,
                                 default = nil)
  if valid_595517 != nil:
    section.add "X-Amz-Content-Sha256", valid_595517
  var valid_595518 = header.getOrDefault("X-Amz-Algorithm")
  valid_595518 = validateParameter(valid_595518, JString, required = false,
                                 default = nil)
  if valid_595518 != nil:
    section.add "X-Amz-Algorithm", valid_595518
  var valid_595519 = header.getOrDefault("X-Amz-Signature")
  valid_595519 = validateParameter(valid_595519, JString, required = false,
                                 default = nil)
  if valid_595519 != nil:
    section.add "X-Amz-Signature", valid_595519
  var valid_595520 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595520 = validateParameter(valid_595520, JString, required = false,
                                 default = nil)
  if valid_595520 != nil:
    section.add "X-Amz-SignedHeaders", valid_595520
  var valid_595521 = header.getOrDefault("X-Amz-Credential")
  valid_595521 = validateParameter(valid_595521, JString, required = false,
                                 default = nil)
  if valid_595521 != nil:
    section.add "X-Amz-Credential", valid_595521
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595523: Call_RegisterTargetWithMaintenanceWindow_595511;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Registers a target with a maintenance window.
  ## 
  let valid = call_595523.validator(path, query, header, formData, body)
  let scheme = call_595523.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595523.url(scheme.get, call_595523.host, call_595523.base,
                         call_595523.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595523, url, valid)

proc call*(call_595524: Call_RegisterTargetWithMaintenanceWindow_595511;
          body: JsonNode): Recallable =
  ## registerTargetWithMaintenanceWindow
  ## Registers a target with a maintenance window.
  ##   body: JObject (required)
  var body_595525 = newJObject()
  if body != nil:
    body_595525 = body
  result = call_595524.call(nil, nil, nil, nil, body_595525)

var registerTargetWithMaintenanceWindow* = Call_RegisterTargetWithMaintenanceWindow_595511(
    name: "registerTargetWithMaintenanceWindow", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.RegisterTargetWithMaintenanceWindow",
    validator: validate_RegisterTargetWithMaintenanceWindow_595512, base: "/",
    url: url_RegisterTargetWithMaintenanceWindow_595513,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RegisterTaskWithMaintenanceWindow_595526 = ref object of OpenApiRestCall_593437
proc url_RegisterTaskWithMaintenanceWindow_595528(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_RegisterTaskWithMaintenanceWindow_595527(path: JsonNode;
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
  var valid_595529 = header.getOrDefault("X-Amz-Date")
  valid_595529 = validateParameter(valid_595529, JString, required = false,
                                 default = nil)
  if valid_595529 != nil:
    section.add "X-Amz-Date", valid_595529
  var valid_595530 = header.getOrDefault("X-Amz-Security-Token")
  valid_595530 = validateParameter(valid_595530, JString, required = false,
                                 default = nil)
  if valid_595530 != nil:
    section.add "X-Amz-Security-Token", valid_595530
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595531 = header.getOrDefault("X-Amz-Target")
  valid_595531 = validateParameter(valid_595531, JString, required = true, default = newJString(
      "AmazonSSM.RegisterTaskWithMaintenanceWindow"))
  if valid_595531 != nil:
    section.add "X-Amz-Target", valid_595531
  var valid_595532 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595532 = validateParameter(valid_595532, JString, required = false,
                                 default = nil)
  if valid_595532 != nil:
    section.add "X-Amz-Content-Sha256", valid_595532
  var valid_595533 = header.getOrDefault("X-Amz-Algorithm")
  valid_595533 = validateParameter(valid_595533, JString, required = false,
                                 default = nil)
  if valid_595533 != nil:
    section.add "X-Amz-Algorithm", valid_595533
  var valid_595534 = header.getOrDefault("X-Amz-Signature")
  valid_595534 = validateParameter(valid_595534, JString, required = false,
                                 default = nil)
  if valid_595534 != nil:
    section.add "X-Amz-Signature", valid_595534
  var valid_595535 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595535 = validateParameter(valid_595535, JString, required = false,
                                 default = nil)
  if valid_595535 != nil:
    section.add "X-Amz-SignedHeaders", valid_595535
  var valid_595536 = header.getOrDefault("X-Amz-Credential")
  valid_595536 = validateParameter(valid_595536, JString, required = false,
                                 default = nil)
  if valid_595536 != nil:
    section.add "X-Amz-Credential", valid_595536
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595538: Call_RegisterTaskWithMaintenanceWindow_595526;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Adds a new task to a maintenance window.
  ## 
  let valid = call_595538.validator(path, query, header, formData, body)
  let scheme = call_595538.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595538.url(scheme.get, call_595538.host, call_595538.base,
                         call_595538.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595538, url, valid)

proc call*(call_595539: Call_RegisterTaskWithMaintenanceWindow_595526;
          body: JsonNode): Recallable =
  ## registerTaskWithMaintenanceWindow
  ## Adds a new task to a maintenance window.
  ##   body: JObject (required)
  var body_595540 = newJObject()
  if body != nil:
    body_595540 = body
  result = call_595539.call(nil, nil, nil, nil, body_595540)

var registerTaskWithMaintenanceWindow* = Call_RegisterTaskWithMaintenanceWindow_595526(
    name: "registerTaskWithMaintenanceWindow", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.RegisterTaskWithMaintenanceWindow",
    validator: validate_RegisterTaskWithMaintenanceWindow_595527, base: "/",
    url: url_RegisterTaskWithMaintenanceWindow_595528,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RemoveTagsFromResource_595541 = ref object of OpenApiRestCall_593437
proc url_RemoveTagsFromResource_595543(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_RemoveTagsFromResource_595542(path: JsonNode; query: JsonNode;
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
  var valid_595544 = header.getOrDefault("X-Amz-Date")
  valid_595544 = validateParameter(valid_595544, JString, required = false,
                                 default = nil)
  if valid_595544 != nil:
    section.add "X-Amz-Date", valid_595544
  var valid_595545 = header.getOrDefault("X-Amz-Security-Token")
  valid_595545 = validateParameter(valid_595545, JString, required = false,
                                 default = nil)
  if valid_595545 != nil:
    section.add "X-Amz-Security-Token", valid_595545
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595546 = header.getOrDefault("X-Amz-Target")
  valid_595546 = validateParameter(valid_595546, JString, required = true, default = newJString(
      "AmazonSSM.RemoveTagsFromResource"))
  if valid_595546 != nil:
    section.add "X-Amz-Target", valid_595546
  var valid_595547 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595547 = validateParameter(valid_595547, JString, required = false,
                                 default = nil)
  if valid_595547 != nil:
    section.add "X-Amz-Content-Sha256", valid_595547
  var valid_595548 = header.getOrDefault("X-Amz-Algorithm")
  valid_595548 = validateParameter(valid_595548, JString, required = false,
                                 default = nil)
  if valid_595548 != nil:
    section.add "X-Amz-Algorithm", valid_595548
  var valid_595549 = header.getOrDefault("X-Amz-Signature")
  valid_595549 = validateParameter(valid_595549, JString, required = false,
                                 default = nil)
  if valid_595549 != nil:
    section.add "X-Amz-Signature", valid_595549
  var valid_595550 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595550 = validateParameter(valid_595550, JString, required = false,
                                 default = nil)
  if valid_595550 != nil:
    section.add "X-Amz-SignedHeaders", valid_595550
  var valid_595551 = header.getOrDefault("X-Amz-Credential")
  valid_595551 = validateParameter(valid_595551, JString, required = false,
                                 default = nil)
  if valid_595551 != nil:
    section.add "X-Amz-Credential", valid_595551
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595553: Call_RemoveTagsFromResource_595541; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes tag keys from the specified resource.
  ## 
  let valid = call_595553.validator(path, query, header, formData, body)
  let scheme = call_595553.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595553.url(scheme.get, call_595553.host, call_595553.base,
                         call_595553.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595553, url, valid)

proc call*(call_595554: Call_RemoveTagsFromResource_595541; body: JsonNode): Recallable =
  ## removeTagsFromResource
  ## Removes tag keys from the specified resource.
  ##   body: JObject (required)
  var body_595555 = newJObject()
  if body != nil:
    body_595555 = body
  result = call_595554.call(nil, nil, nil, nil, body_595555)

var removeTagsFromResource* = Call_RemoveTagsFromResource_595541(
    name: "removeTagsFromResource", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.RemoveTagsFromResource",
    validator: validate_RemoveTagsFromResource_595542, base: "/",
    url: url_RemoveTagsFromResource_595543, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ResetServiceSetting_595556 = ref object of OpenApiRestCall_593437
proc url_ResetServiceSetting_595558(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ResetServiceSetting_595557(path: JsonNode; query: JsonNode;
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
  var valid_595559 = header.getOrDefault("X-Amz-Date")
  valid_595559 = validateParameter(valid_595559, JString, required = false,
                                 default = nil)
  if valid_595559 != nil:
    section.add "X-Amz-Date", valid_595559
  var valid_595560 = header.getOrDefault("X-Amz-Security-Token")
  valid_595560 = validateParameter(valid_595560, JString, required = false,
                                 default = nil)
  if valid_595560 != nil:
    section.add "X-Amz-Security-Token", valid_595560
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595561 = header.getOrDefault("X-Amz-Target")
  valid_595561 = validateParameter(valid_595561, JString, required = true, default = newJString(
      "AmazonSSM.ResetServiceSetting"))
  if valid_595561 != nil:
    section.add "X-Amz-Target", valid_595561
  var valid_595562 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595562 = validateParameter(valid_595562, JString, required = false,
                                 default = nil)
  if valid_595562 != nil:
    section.add "X-Amz-Content-Sha256", valid_595562
  var valid_595563 = header.getOrDefault("X-Amz-Algorithm")
  valid_595563 = validateParameter(valid_595563, JString, required = false,
                                 default = nil)
  if valid_595563 != nil:
    section.add "X-Amz-Algorithm", valid_595563
  var valid_595564 = header.getOrDefault("X-Amz-Signature")
  valid_595564 = validateParameter(valid_595564, JString, required = false,
                                 default = nil)
  if valid_595564 != nil:
    section.add "X-Amz-Signature", valid_595564
  var valid_595565 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595565 = validateParameter(valid_595565, JString, required = false,
                                 default = nil)
  if valid_595565 != nil:
    section.add "X-Amz-SignedHeaders", valid_595565
  var valid_595566 = header.getOrDefault("X-Amz-Credential")
  valid_595566 = validateParameter(valid_595566, JString, required = false,
                                 default = nil)
  if valid_595566 != nil:
    section.add "X-Amz-Credential", valid_595566
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595568: Call_ResetServiceSetting_595556; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> <code>ServiceSetting</code> is an account-level setting for an AWS service. This setting defines how a user interacts with or uses a service or a feature of a service. For example, if an AWS service charges money to the account based on feature or service usage, then the AWS service team might create a default setting of "false". This means the user can't use this feature unless they change the setting to "true" and intentionally opt in for a paid feature.</p> <p>Services map a <code>SettingId</code> object to a setting value. AWS services teams define the default value for a <code>SettingId</code>. You can't create a new <code>SettingId</code>, but you can overwrite the default value if you have the <code>ssm:UpdateServiceSetting</code> permission for the setting. Use the <a>GetServiceSetting</a> API action to view the current value. Use the <a>UpdateServiceSetting</a> API action to change the default setting. </p> <p>Reset the service setting for the account to the default value as provisioned by the AWS service team. </p>
  ## 
  let valid = call_595568.validator(path, query, header, formData, body)
  let scheme = call_595568.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595568.url(scheme.get, call_595568.host, call_595568.base,
                         call_595568.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595568, url, valid)

proc call*(call_595569: Call_ResetServiceSetting_595556; body: JsonNode): Recallable =
  ## resetServiceSetting
  ## <p> <code>ServiceSetting</code> is an account-level setting for an AWS service. This setting defines how a user interacts with or uses a service or a feature of a service. For example, if an AWS service charges money to the account based on feature or service usage, then the AWS service team might create a default setting of "false". This means the user can't use this feature unless they change the setting to "true" and intentionally opt in for a paid feature.</p> <p>Services map a <code>SettingId</code> object to a setting value. AWS services teams define the default value for a <code>SettingId</code>. You can't create a new <code>SettingId</code>, but you can overwrite the default value if you have the <code>ssm:UpdateServiceSetting</code> permission for the setting. Use the <a>GetServiceSetting</a> API action to view the current value. Use the <a>UpdateServiceSetting</a> API action to change the default setting. </p> <p>Reset the service setting for the account to the default value as provisioned by the AWS service team. </p>
  ##   body: JObject (required)
  var body_595570 = newJObject()
  if body != nil:
    body_595570 = body
  result = call_595569.call(nil, nil, nil, nil, body_595570)

var resetServiceSetting* = Call_ResetServiceSetting_595556(
    name: "resetServiceSetting", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.ResetServiceSetting",
    validator: validate_ResetServiceSetting_595557, base: "/",
    url: url_ResetServiceSetting_595558, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ResumeSession_595571 = ref object of OpenApiRestCall_593437
proc url_ResumeSession_595573(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ResumeSession_595572(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_595574 = header.getOrDefault("X-Amz-Date")
  valid_595574 = validateParameter(valid_595574, JString, required = false,
                                 default = nil)
  if valid_595574 != nil:
    section.add "X-Amz-Date", valid_595574
  var valid_595575 = header.getOrDefault("X-Amz-Security-Token")
  valid_595575 = validateParameter(valid_595575, JString, required = false,
                                 default = nil)
  if valid_595575 != nil:
    section.add "X-Amz-Security-Token", valid_595575
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595576 = header.getOrDefault("X-Amz-Target")
  valid_595576 = validateParameter(valid_595576, JString, required = true, default = newJString(
      "AmazonSSM.ResumeSession"))
  if valid_595576 != nil:
    section.add "X-Amz-Target", valid_595576
  var valid_595577 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595577 = validateParameter(valid_595577, JString, required = false,
                                 default = nil)
  if valid_595577 != nil:
    section.add "X-Amz-Content-Sha256", valid_595577
  var valid_595578 = header.getOrDefault("X-Amz-Algorithm")
  valid_595578 = validateParameter(valid_595578, JString, required = false,
                                 default = nil)
  if valid_595578 != nil:
    section.add "X-Amz-Algorithm", valid_595578
  var valid_595579 = header.getOrDefault("X-Amz-Signature")
  valid_595579 = validateParameter(valid_595579, JString, required = false,
                                 default = nil)
  if valid_595579 != nil:
    section.add "X-Amz-Signature", valid_595579
  var valid_595580 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595580 = validateParameter(valid_595580, JString, required = false,
                                 default = nil)
  if valid_595580 != nil:
    section.add "X-Amz-SignedHeaders", valid_595580
  var valid_595581 = header.getOrDefault("X-Amz-Credential")
  valid_595581 = validateParameter(valid_595581, JString, required = false,
                                 default = nil)
  if valid_595581 != nil:
    section.add "X-Amz-Credential", valid_595581
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595583: Call_ResumeSession_595571; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Reconnects a session to an instance after it has been disconnected. Connections can be resumed for disconnected sessions, but not terminated sessions.</p> <note> <p>This command is primarily for use by client machines to automatically reconnect during intermittent network issues. It is not intended for any other use.</p> </note>
  ## 
  let valid = call_595583.validator(path, query, header, formData, body)
  let scheme = call_595583.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595583.url(scheme.get, call_595583.host, call_595583.base,
                         call_595583.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595583, url, valid)

proc call*(call_595584: Call_ResumeSession_595571; body: JsonNode): Recallable =
  ## resumeSession
  ## <p>Reconnects a session to an instance after it has been disconnected. Connections can be resumed for disconnected sessions, but not terminated sessions.</p> <note> <p>This command is primarily for use by client machines to automatically reconnect during intermittent network issues. It is not intended for any other use.</p> </note>
  ##   body: JObject (required)
  var body_595585 = newJObject()
  if body != nil:
    body_595585 = body
  result = call_595584.call(nil, nil, nil, nil, body_595585)

var resumeSession* = Call_ResumeSession_595571(name: "resumeSession",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.ResumeSession",
    validator: validate_ResumeSession_595572, base: "/", url: url_ResumeSession_595573,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_SendAutomationSignal_595586 = ref object of OpenApiRestCall_593437
proc url_SendAutomationSignal_595588(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_SendAutomationSignal_595587(path: JsonNode; query: JsonNode;
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
  var valid_595589 = header.getOrDefault("X-Amz-Date")
  valid_595589 = validateParameter(valid_595589, JString, required = false,
                                 default = nil)
  if valid_595589 != nil:
    section.add "X-Amz-Date", valid_595589
  var valid_595590 = header.getOrDefault("X-Amz-Security-Token")
  valid_595590 = validateParameter(valid_595590, JString, required = false,
                                 default = nil)
  if valid_595590 != nil:
    section.add "X-Amz-Security-Token", valid_595590
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595591 = header.getOrDefault("X-Amz-Target")
  valid_595591 = validateParameter(valid_595591, JString, required = true, default = newJString(
      "AmazonSSM.SendAutomationSignal"))
  if valid_595591 != nil:
    section.add "X-Amz-Target", valid_595591
  var valid_595592 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595592 = validateParameter(valid_595592, JString, required = false,
                                 default = nil)
  if valid_595592 != nil:
    section.add "X-Amz-Content-Sha256", valid_595592
  var valid_595593 = header.getOrDefault("X-Amz-Algorithm")
  valid_595593 = validateParameter(valid_595593, JString, required = false,
                                 default = nil)
  if valid_595593 != nil:
    section.add "X-Amz-Algorithm", valid_595593
  var valid_595594 = header.getOrDefault("X-Amz-Signature")
  valid_595594 = validateParameter(valid_595594, JString, required = false,
                                 default = nil)
  if valid_595594 != nil:
    section.add "X-Amz-Signature", valid_595594
  var valid_595595 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595595 = validateParameter(valid_595595, JString, required = false,
                                 default = nil)
  if valid_595595 != nil:
    section.add "X-Amz-SignedHeaders", valid_595595
  var valid_595596 = header.getOrDefault("X-Amz-Credential")
  valid_595596 = validateParameter(valid_595596, JString, required = false,
                                 default = nil)
  if valid_595596 != nil:
    section.add "X-Amz-Credential", valid_595596
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595598: Call_SendAutomationSignal_595586; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sends a signal to an Automation execution to change the current behavior or status of the execution. 
  ## 
  let valid = call_595598.validator(path, query, header, formData, body)
  let scheme = call_595598.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595598.url(scheme.get, call_595598.host, call_595598.base,
                         call_595598.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595598, url, valid)

proc call*(call_595599: Call_SendAutomationSignal_595586; body: JsonNode): Recallable =
  ## sendAutomationSignal
  ## Sends a signal to an Automation execution to change the current behavior or status of the execution. 
  ##   body: JObject (required)
  var body_595600 = newJObject()
  if body != nil:
    body_595600 = body
  result = call_595599.call(nil, nil, nil, nil, body_595600)

var sendAutomationSignal* = Call_SendAutomationSignal_595586(
    name: "sendAutomationSignal", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.SendAutomationSignal",
    validator: validate_SendAutomationSignal_595587, base: "/",
    url: url_SendAutomationSignal_595588, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SendCommand_595601 = ref object of OpenApiRestCall_593437
proc url_SendCommand_595603(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_SendCommand_595602(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_595604 = header.getOrDefault("X-Amz-Date")
  valid_595604 = validateParameter(valid_595604, JString, required = false,
                                 default = nil)
  if valid_595604 != nil:
    section.add "X-Amz-Date", valid_595604
  var valid_595605 = header.getOrDefault("X-Amz-Security-Token")
  valid_595605 = validateParameter(valid_595605, JString, required = false,
                                 default = nil)
  if valid_595605 != nil:
    section.add "X-Amz-Security-Token", valid_595605
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595606 = header.getOrDefault("X-Amz-Target")
  valid_595606 = validateParameter(valid_595606, JString, required = true,
                                 default = newJString("AmazonSSM.SendCommand"))
  if valid_595606 != nil:
    section.add "X-Amz-Target", valid_595606
  var valid_595607 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595607 = validateParameter(valid_595607, JString, required = false,
                                 default = nil)
  if valid_595607 != nil:
    section.add "X-Amz-Content-Sha256", valid_595607
  var valid_595608 = header.getOrDefault("X-Amz-Algorithm")
  valid_595608 = validateParameter(valid_595608, JString, required = false,
                                 default = nil)
  if valid_595608 != nil:
    section.add "X-Amz-Algorithm", valid_595608
  var valid_595609 = header.getOrDefault("X-Amz-Signature")
  valid_595609 = validateParameter(valid_595609, JString, required = false,
                                 default = nil)
  if valid_595609 != nil:
    section.add "X-Amz-Signature", valid_595609
  var valid_595610 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595610 = validateParameter(valid_595610, JString, required = false,
                                 default = nil)
  if valid_595610 != nil:
    section.add "X-Amz-SignedHeaders", valid_595610
  var valid_595611 = header.getOrDefault("X-Amz-Credential")
  valid_595611 = validateParameter(valid_595611, JString, required = false,
                                 default = nil)
  if valid_595611 != nil:
    section.add "X-Amz-Credential", valid_595611
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595613: Call_SendCommand_595601; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Runs commands on one or more managed instances.
  ## 
  let valid = call_595613.validator(path, query, header, formData, body)
  let scheme = call_595613.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595613.url(scheme.get, call_595613.host, call_595613.base,
                         call_595613.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595613, url, valid)

proc call*(call_595614: Call_SendCommand_595601; body: JsonNode): Recallable =
  ## sendCommand
  ## Runs commands on one or more managed instances.
  ##   body: JObject (required)
  var body_595615 = newJObject()
  if body != nil:
    body_595615 = body
  result = call_595614.call(nil, nil, nil, nil, body_595615)

var sendCommand* = Call_SendCommand_595601(name: "sendCommand",
                                        meth: HttpMethod.HttpPost,
                                        host: "ssm.amazonaws.com", route: "/#X-Amz-Target=AmazonSSM.SendCommand",
                                        validator: validate_SendCommand_595602,
                                        base: "/", url: url_SendCommand_595603,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartAssociationsOnce_595616 = ref object of OpenApiRestCall_593437
proc url_StartAssociationsOnce_595618(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StartAssociationsOnce_595617(path: JsonNode; query: JsonNode;
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
  var valid_595619 = header.getOrDefault("X-Amz-Date")
  valid_595619 = validateParameter(valid_595619, JString, required = false,
                                 default = nil)
  if valid_595619 != nil:
    section.add "X-Amz-Date", valid_595619
  var valid_595620 = header.getOrDefault("X-Amz-Security-Token")
  valid_595620 = validateParameter(valid_595620, JString, required = false,
                                 default = nil)
  if valid_595620 != nil:
    section.add "X-Amz-Security-Token", valid_595620
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595621 = header.getOrDefault("X-Amz-Target")
  valid_595621 = validateParameter(valid_595621, JString, required = true, default = newJString(
      "AmazonSSM.StartAssociationsOnce"))
  if valid_595621 != nil:
    section.add "X-Amz-Target", valid_595621
  var valid_595622 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595622 = validateParameter(valid_595622, JString, required = false,
                                 default = nil)
  if valid_595622 != nil:
    section.add "X-Amz-Content-Sha256", valid_595622
  var valid_595623 = header.getOrDefault("X-Amz-Algorithm")
  valid_595623 = validateParameter(valid_595623, JString, required = false,
                                 default = nil)
  if valid_595623 != nil:
    section.add "X-Amz-Algorithm", valid_595623
  var valid_595624 = header.getOrDefault("X-Amz-Signature")
  valid_595624 = validateParameter(valid_595624, JString, required = false,
                                 default = nil)
  if valid_595624 != nil:
    section.add "X-Amz-Signature", valid_595624
  var valid_595625 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595625 = validateParameter(valid_595625, JString, required = false,
                                 default = nil)
  if valid_595625 != nil:
    section.add "X-Amz-SignedHeaders", valid_595625
  var valid_595626 = header.getOrDefault("X-Amz-Credential")
  valid_595626 = validateParameter(valid_595626, JString, required = false,
                                 default = nil)
  if valid_595626 != nil:
    section.add "X-Amz-Credential", valid_595626
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595628: Call_StartAssociationsOnce_595616; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Use this API action to run an association immediately and only one time. This action can be helpful when troubleshooting associations.
  ## 
  let valid = call_595628.validator(path, query, header, formData, body)
  let scheme = call_595628.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595628.url(scheme.get, call_595628.host, call_595628.base,
                         call_595628.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595628, url, valid)

proc call*(call_595629: Call_StartAssociationsOnce_595616; body: JsonNode): Recallable =
  ## startAssociationsOnce
  ## Use this API action to run an association immediately and only one time. This action can be helpful when troubleshooting associations.
  ##   body: JObject (required)
  var body_595630 = newJObject()
  if body != nil:
    body_595630 = body
  result = call_595629.call(nil, nil, nil, nil, body_595630)

var startAssociationsOnce* = Call_StartAssociationsOnce_595616(
    name: "startAssociationsOnce", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.StartAssociationsOnce",
    validator: validate_StartAssociationsOnce_595617, base: "/",
    url: url_StartAssociationsOnce_595618, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartAutomationExecution_595631 = ref object of OpenApiRestCall_593437
proc url_StartAutomationExecution_595633(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StartAutomationExecution_595632(path: JsonNode; query: JsonNode;
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
  var valid_595634 = header.getOrDefault("X-Amz-Date")
  valid_595634 = validateParameter(valid_595634, JString, required = false,
                                 default = nil)
  if valid_595634 != nil:
    section.add "X-Amz-Date", valid_595634
  var valid_595635 = header.getOrDefault("X-Amz-Security-Token")
  valid_595635 = validateParameter(valid_595635, JString, required = false,
                                 default = nil)
  if valid_595635 != nil:
    section.add "X-Amz-Security-Token", valid_595635
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595636 = header.getOrDefault("X-Amz-Target")
  valid_595636 = validateParameter(valid_595636, JString, required = true, default = newJString(
      "AmazonSSM.StartAutomationExecution"))
  if valid_595636 != nil:
    section.add "X-Amz-Target", valid_595636
  var valid_595637 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595637 = validateParameter(valid_595637, JString, required = false,
                                 default = nil)
  if valid_595637 != nil:
    section.add "X-Amz-Content-Sha256", valid_595637
  var valid_595638 = header.getOrDefault("X-Amz-Algorithm")
  valid_595638 = validateParameter(valid_595638, JString, required = false,
                                 default = nil)
  if valid_595638 != nil:
    section.add "X-Amz-Algorithm", valid_595638
  var valid_595639 = header.getOrDefault("X-Amz-Signature")
  valid_595639 = validateParameter(valid_595639, JString, required = false,
                                 default = nil)
  if valid_595639 != nil:
    section.add "X-Amz-Signature", valid_595639
  var valid_595640 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595640 = validateParameter(valid_595640, JString, required = false,
                                 default = nil)
  if valid_595640 != nil:
    section.add "X-Amz-SignedHeaders", valid_595640
  var valid_595641 = header.getOrDefault("X-Amz-Credential")
  valid_595641 = validateParameter(valid_595641, JString, required = false,
                                 default = nil)
  if valid_595641 != nil:
    section.add "X-Amz-Credential", valid_595641
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595643: Call_StartAutomationExecution_595631; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Initiates execution of an Automation document.
  ## 
  let valid = call_595643.validator(path, query, header, formData, body)
  let scheme = call_595643.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595643.url(scheme.get, call_595643.host, call_595643.base,
                         call_595643.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595643, url, valid)

proc call*(call_595644: Call_StartAutomationExecution_595631; body: JsonNode): Recallable =
  ## startAutomationExecution
  ## Initiates execution of an Automation document.
  ##   body: JObject (required)
  var body_595645 = newJObject()
  if body != nil:
    body_595645 = body
  result = call_595644.call(nil, nil, nil, nil, body_595645)

var startAutomationExecution* = Call_StartAutomationExecution_595631(
    name: "startAutomationExecution", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.StartAutomationExecution",
    validator: validate_StartAutomationExecution_595632, base: "/",
    url: url_StartAutomationExecution_595633, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartSession_595646 = ref object of OpenApiRestCall_593437
proc url_StartSession_595648(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StartSession_595647(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Initiates a connection to a target (for example, an instance) for a Session Manager session. Returns a URL and token that can be used to open a WebSocket connection for sending input and receiving outputs.</p> <note> <p>AWS CLI usage: <code>start-session</code> is an interactive command that requires the Session Manager plugin to be installed on the client machine making the call. For information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html"> Install the Session Manager Plugin for the AWS CLI</a> in the <i>AWS Systems Manager User Guide</i>.</p> </note>
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
  var valid_595649 = header.getOrDefault("X-Amz-Date")
  valid_595649 = validateParameter(valid_595649, JString, required = false,
                                 default = nil)
  if valid_595649 != nil:
    section.add "X-Amz-Date", valid_595649
  var valid_595650 = header.getOrDefault("X-Amz-Security-Token")
  valid_595650 = validateParameter(valid_595650, JString, required = false,
                                 default = nil)
  if valid_595650 != nil:
    section.add "X-Amz-Security-Token", valid_595650
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595651 = header.getOrDefault("X-Amz-Target")
  valid_595651 = validateParameter(valid_595651, JString, required = true,
                                 default = newJString("AmazonSSM.StartSession"))
  if valid_595651 != nil:
    section.add "X-Amz-Target", valid_595651
  var valid_595652 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595652 = validateParameter(valid_595652, JString, required = false,
                                 default = nil)
  if valid_595652 != nil:
    section.add "X-Amz-Content-Sha256", valid_595652
  var valid_595653 = header.getOrDefault("X-Amz-Algorithm")
  valid_595653 = validateParameter(valid_595653, JString, required = false,
                                 default = nil)
  if valid_595653 != nil:
    section.add "X-Amz-Algorithm", valid_595653
  var valid_595654 = header.getOrDefault("X-Amz-Signature")
  valid_595654 = validateParameter(valid_595654, JString, required = false,
                                 default = nil)
  if valid_595654 != nil:
    section.add "X-Amz-Signature", valid_595654
  var valid_595655 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595655 = validateParameter(valid_595655, JString, required = false,
                                 default = nil)
  if valid_595655 != nil:
    section.add "X-Amz-SignedHeaders", valid_595655
  var valid_595656 = header.getOrDefault("X-Amz-Credential")
  valid_595656 = validateParameter(valid_595656, JString, required = false,
                                 default = nil)
  if valid_595656 != nil:
    section.add "X-Amz-Credential", valid_595656
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595658: Call_StartSession_595646; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Initiates a connection to a target (for example, an instance) for a Session Manager session. Returns a URL and token that can be used to open a WebSocket connection for sending input and receiving outputs.</p> <note> <p>AWS CLI usage: <code>start-session</code> is an interactive command that requires the Session Manager plugin to be installed on the client machine making the call. For information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html"> Install the Session Manager Plugin for the AWS CLI</a> in the <i>AWS Systems Manager User Guide</i>.</p> </note>
  ## 
  let valid = call_595658.validator(path, query, header, formData, body)
  let scheme = call_595658.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595658.url(scheme.get, call_595658.host, call_595658.base,
                         call_595658.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595658, url, valid)

proc call*(call_595659: Call_StartSession_595646; body: JsonNode): Recallable =
  ## startSession
  ## <p>Initiates a connection to a target (for example, an instance) for a Session Manager session. Returns a URL and token that can be used to open a WebSocket connection for sending input and receiving outputs.</p> <note> <p>AWS CLI usage: <code>start-session</code> is an interactive command that requires the Session Manager plugin to be installed on the client machine making the call. For information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html"> Install the Session Manager Plugin for the AWS CLI</a> in the <i>AWS Systems Manager User Guide</i>.</p> </note>
  ##   body: JObject (required)
  var body_595660 = newJObject()
  if body != nil:
    body_595660 = body
  result = call_595659.call(nil, nil, nil, nil, body_595660)

var startSession* = Call_StartSession_595646(name: "startSession",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.StartSession",
    validator: validate_StartSession_595647, base: "/", url: url_StartSession_595648,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopAutomationExecution_595661 = ref object of OpenApiRestCall_593437
proc url_StopAutomationExecution_595663(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StopAutomationExecution_595662(path: JsonNode; query: JsonNode;
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
  var valid_595664 = header.getOrDefault("X-Amz-Date")
  valid_595664 = validateParameter(valid_595664, JString, required = false,
                                 default = nil)
  if valid_595664 != nil:
    section.add "X-Amz-Date", valid_595664
  var valid_595665 = header.getOrDefault("X-Amz-Security-Token")
  valid_595665 = validateParameter(valid_595665, JString, required = false,
                                 default = nil)
  if valid_595665 != nil:
    section.add "X-Amz-Security-Token", valid_595665
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595666 = header.getOrDefault("X-Amz-Target")
  valid_595666 = validateParameter(valid_595666, JString, required = true, default = newJString(
      "AmazonSSM.StopAutomationExecution"))
  if valid_595666 != nil:
    section.add "X-Amz-Target", valid_595666
  var valid_595667 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595667 = validateParameter(valid_595667, JString, required = false,
                                 default = nil)
  if valid_595667 != nil:
    section.add "X-Amz-Content-Sha256", valid_595667
  var valid_595668 = header.getOrDefault("X-Amz-Algorithm")
  valid_595668 = validateParameter(valid_595668, JString, required = false,
                                 default = nil)
  if valid_595668 != nil:
    section.add "X-Amz-Algorithm", valid_595668
  var valid_595669 = header.getOrDefault("X-Amz-Signature")
  valid_595669 = validateParameter(valid_595669, JString, required = false,
                                 default = nil)
  if valid_595669 != nil:
    section.add "X-Amz-Signature", valid_595669
  var valid_595670 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595670 = validateParameter(valid_595670, JString, required = false,
                                 default = nil)
  if valid_595670 != nil:
    section.add "X-Amz-SignedHeaders", valid_595670
  var valid_595671 = header.getOrDefault("X-Amz-Credential")
  valid_595671 = validateParameter(valid_595671, JString, required = false,
                                 default = nil)
  if valid_595671 != nil:
    section.add "X-Amz-Credential", valid_595671
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595673: Call_StopAutomationExecution_595661; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Stop an Automation that is currently running.
  ## 
  let valid = call_595673.validator(path, query, header, formData, body)
  let scheme = call_595673.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595673.url(scheme.get, call_595673.host, call_595673.base,
                         call_595673.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595673, url, valid)

proc call*(call_595674: Call_StopAutomationExecution_595661; body: JsonNode): Recallable =
  ## stopAutomationExecution
  ## Stop an Automation that is currently running.
  ##   body: JObject (required)
  var body_595675 = newJObject()
  if body != nil:
    body_595675 = body
  result = call_595674.call(nil, nil, nil, nil, body_595675)

var stopAutomationExecution* = Call_StopAutomationExecution_595661(
    name: "stopAutomationExecution", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.StopAutomationExecution",
    validator: validate_StopAutomationExecution_595662, base: "/",
    url: url_StopAutomationExecution_595663, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TerminateSession_595676 = ref object of OpenApiRestCall_593437
proc url_TerminateSession_595678(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_TerminateSession_595677(path: JsonNode; query: JsonNode;
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
  var valid_595679 = header.getOrDefault("X-Amz-Date")
  valid_595679 = validateParameter(valid_595679, JString, required = false,
                                 default = nil)
  if valid_595679 != nil:
    section.add "X-Amz-Date", valid_595679
  var valid_595680 = header.getOrDefault("X-Amz-Security-Token")
  valid_595680 = validateParameter(valid_595680, JString, required = false,
                                 default = nil)
  if valid_595680 != nil:
    section.add "X-Amz-Security-Token", valid_595680
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595681 = header.getOrDefault("X-Amz-Target")
  valid_595681 = validateParameter(valid_595681, JString, required = true, default = newJString(
      "AmazonSSM.TerminateSession"))
  if valid_595681 != nil:
    section.add "X-Amz-Target", valid_595681
  var valid_595682 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595682 = validateParameter(valid_595682, JString, required = false,
                                 default = nil)
  if valid_595682 != nil:
    section.add "X-Amz-Content-Sha256", valid_595682
  var valid_595683 = header.getOrDefault("X-Amz-Algorithm")
  valid_595683 = validateParameter(valid_595683, JString, required = false,
                                 default = nil)
  if valid_595683 != nil:
    section.add "X-Amz-Algorithm", valid_595683
  var valid_595684 = header.getOrDefault("X-Amz-Signature")
  valid_595684 = validateParameter(valid_595684, JString, required = false,
                                 default = nil)
  if valid_595684 != nil:
    section.add "X-Amz-Signature", valid_595684
  var valid_595685 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595685 = validateParameter(valid_595685, JString, required = false,
                                 default = nil)
  if valid_595685 != nil:
    section.add "X-Amz-SignedHeaders", valid_595685
  var valid_595686 = header.getOrDefault("X-Amz-Credential")
  valid_595686 = validateParameter(valid_595686, JString, required = false,
                                 default = nil)
  if valid_595686 != nil:
    section.add "X-Amz-Credential", valid_595686
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595688: Call_TerminateSession_595676; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Permanently ends a session and closes the data connection between the Session Manager client and SSM Agent on the instance. A terminated session cannot be resumed.
  ## 
  let valid = call_595688.validator(path, query, header, formData, body)
  let scheme = call_595688.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595688.url(scheme.get, call_595688.host, call_595688.base,
                         call_595688.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595688, url, valid)

proc call*(call_595689: Call_TerminateSession_595676; body: JsonNode): Recallable =
  ## terminateSession
  ## Permanently ends a session and closes the data connection between the Session Manager client and SSM Agent on the instance. A terminated session cannot be resumed.
  ##   body: JObject (required)
  var body_595690 = newJObject()
  if body != nil:
    body_595690 = body
  result = call_595689.call(nil, nil, nil, nil, body_595690)

var terminateSession* = Call_TerminateSession_595676(name: "terminateSession",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.TerminateSession",
    validator: validate_TerminateSession_595677, base: "/",
    url: url_TerminateSession_595678, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateAssociation_595691 = ref object of OpenApiRestCall_593437
proc url_UpdateAssociation_595693(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateAssociation_595692(path: JsonNode; query: JsonNode;
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
  var valid_595694 = header.getOrDefault("X-Amz-Date")
  valid_595694 = validateParameter(valid_595694, JString, required = false,
                                 default = nil)
  if valid_595694 != nil:
    section.add "X-Amz-Date", valid_595694
  var valid_595695 = header.getOrDefault("X-Amz-Security-Token")
  valid_595695 = validateParameter(valid_595695, JString, required = false,
                                 default = nil)
  if valid_595695 != nil:
    section.add "X-Amz-Security-Token", valid_595695
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595696 = header.getOrDefault("X-Amz-Target")
  valid_595696 = validateParameter(valid_595696, JString, required = true, default = newJString(
      "AmazonSSM.UpdateAssociation"))
  if valid_595696 != nil:
    section.add "X-Amz-Target", valid_595696
  var valid_595697 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595697 = validateParameter(valid_595697, JString, required = false,
                                 default = nil)
  if valid_595697 != nil:
    section.add "X-Amz-Content-Sha256", valid_595697
  var valid_595698 = header.getOrDefault("X-Amz-Algorithm")
  valid_595698 = validateParameter(valid_595698, JString, required = false,
                                 default = nil)
  if valid_595698 != nil:
    section.add "X-Amz-Algorithm", valid_595698
  var valid_595699 = header.getOrDefault("X-Amz-Signature")
  valid_595699 = validateParameter(valid_595699, JString, required = false,
                                 default = nil)
  if valid_595699 != nil:
    section.add "X-Amz-Signature", valid_595699
  var valid_595700 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595700 = validateParameter(valid_595700, JString, required = false,
                                 default = nil)
  if valid_595700 != nil:
    section.add "X-Amz-SignedHeaders", valid_595700
  var valid_595701 = header.getOrDefault("X-Amz-Credential")
  valid_595701 = validateParameter(valid_595701, JString, required = false,
                                 default = nil)
  if valid_595701 != nil:
    section.add "X-Amz-Credential", valid_595701
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595703: Call_UpdateAssociation_595691; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates an association. You can update the association name and version, the document version, schedule, parameters, and Amazon S3 output. </p> <p>In order to call this API action, your IAM user account, group, or role must be configured with permission to call the <a>DescribeAssociation</a> API action. If you don't have permission to call DescribeAssociation, then you receive the following error: <code>An error occurred (AccessDeniedException) when calling the UpdateAssociation operation: User: &lt;user_arn&gt; is not authorized to perform: ssm:DescribeAssociation on resource: &lt;resource_arn&gt;</code> </p> <important> <p>When you update an association, the association immediately runs against the specified targets.</p> </important>
  ## 
  let valid = call_595703.validator(path, query, header, formData, body)
  let scheme = call_595703.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595703.url(scheme.get, call_595703.host, call_595703.base,
                         call_595703.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595703, url, valid)

proc call*(call_595704: Call_UpdateAssociation_595691; body: JsonNode): Recallable =
  ## updateAssociation
  ## <p>Updates an association. You can update the association name and version, the document version, schedule, parameters, and Amazon S3 output. </p> <p>In order to call this API action, your IAM user account, group, or role must be configured with permission to call the <a>DescribeAssociation</a> API action. If you don't have permission to call DescribeAssociation, then you receive the following error: <code>An error occurred (AccessDeniedException) when calling the UpdateAssociation operation: User: &lt;user_arn&gt; is not authorized to perform: ssm:DescribeAssociation on resource: &lt;resource_arn&gt;</code> </p> <important> <p>When you update an association, the association immediately runs against the specified targets.</p> </important>
  ##   body: JObject (required)
  var body_595705 = newJObject()
  if body != nil:
    body_595705 = body
  result = call_595704.call(nil, nil, nil, nil, body_595705)

var updateAssociation* = Call_UpdateAssociation_595691(name: "updateAssociation",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.UpdateAssociation",
    validator: validate_UpdateAssociation_595692, base: "/",
    url: url_UpdateAssociation_595693, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateAssociationStatus_595706 = ref object of OpenApiRestCall_593437
proc url_UpdateAssociationStatus_595708(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateAssociationStatus_595707(path: JsonNode; query: JsonNode;
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
  var valid_595709 = header.getOrDefault("X-Amz-Date")
  valid_595709 = validateParameter(valid_595709, JString, required = false,
                                 default = nil)
  if valid_595709 != nil:
    section.add "X-Amz-Date", valid_595709
  var valid_595710 = header.getOrDefault("X-Amz-Security-Token")
  valid_595710 = validateParameter(valid_595710, JString, required = false,
                                 default = nil)
  if valid_595710 != nil:
    section.add "X-Amz-Security-Token", valid_595710
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595711 = header.getOrDefault("X-Amz-Target")
  valid_595711 = validateParameter(valid_595711, JString, required = true, default = newJString(
      "AmazonSSM.UpdateAssociationStatus"))
  if valid_595711 != nil:
    section.add "X-Amz-Target", valid_595711
  var valid_595712 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595712 = validateParameter(valid_595712, JString, required = false,
                                 default = nil)
  if valid_595712 != nil:
    section.add "X-Amz-Content-Sha256", valid_595712
  var valid_595713 = header.getOrDefault("X-Amz-Algorithm")
  valid_595713 = validateParameter(valid_595713, JString, required = false,
                                 default = nil)
  if valid_595713 != nil:
    section.add "X-Amz-Algorithm", valid_595713
  var valid_595714 = header.getOrDefault("X-Amz-Signature")
  valid_595714 = validateParameter(valid_595714, JString, required = false,
                                 default = nil)
  if valid_595714 != nil:
    section.add "X-Amz-Signature", valid_595714
  var valid_595715 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595715 = validateParameter(valid_595715, JString, required = false,
                                 default = nil)
  if valid_595715 != nil:
    section.add "X-Amz-SignedHeaders", valid_595715
  var valid_595716 = header.getOrDefault("X-Amz-Credential")
  valid_595716 = validateParameter(valid_595716, JString, required = false,
                                 default = nil)
  if valid_595716 != nil:
    section.add "X-Amz-Credential", valid_595716
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595718: Call_UpdateAssociationStatus_595706; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the status of the Systems Manager document associated with the specified instance.
  ## 
  let valid = call_595718.validator(path, query, header, formData, body)
  let scheme = call_595718.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595718.url(scheme.get, call_595718.host, call_595718.base,
                         call_595718.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595718, url, valid)

proc call*(call_595719: Call_UpdateAssociationStatus_595706; body: JsonNode): Recallable =
  ## updateAssociationStatus
  ## Updates the status of the Systems Manager document associated with the specified instance.
  ##   body: JObject (required)
  var body_595720 = newJObject()
  if body != nil:
    body_595720 = body
  result = call_595719.call(nil, nil, nil, nil, body_595720)

var updateAssociationStatus* = Call_UpdateAssociationStatus_595706(
    name: "updateAssociationStatus", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.UpdateAssociationStatus",
    validator: validate_UpdateAssociationStatus_595707, base: "/",
    url: url_UpdateAssociationStatus_595708, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDocument_595721 = ref object of OpenApiRestCall_593437
proc url_UpdateDocument_595723(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateDocument_595722(path: JsonNode; query: JsonNode;
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
  var valid_595724 = header.getOrDefault("X-Amz-Date")
  valid_595724 = validateParameter(valid_595724, JString, required = false,
                                 default = nil)
  if valid_595724 != nil:
    section.add "X-Amz-Date", valid_595724
  var valid_595725 = header.getOrDefault("X-Amz-Security-Token")
  valid_595725 = validateParameter(valid_595725, JString, required = false,
                                 default = nil)
  if valid_595725 != nil:
    section.add "X-Amz-Security-Token", valid_595725
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595726 = header.getOrDefault("X-Amz-Target")
  valid_595726 = validateParameter(valid_595726, JString, required = true, default = newJString(
      "AmazonSSM.UpdateDocument"))
  if valid_595726 != nil:
    section.add "X-Amz-Target", valid_595726
  var valid_595727 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595727 = validateParameter(valid_595727, JString, required = false,
                                 default = nil)
  if valid_595727 != nil:
    section.add "X-Amz-Content-Sha256", valid_595727
  var valid_595728 = header.getOrDefault("X-Amz-Algorithm")
  valid_595728 = validateParameter(valid_595728, JString, required = false,
                                 default = nil)
  if valid_595728 != nil:
    section.add "X-Amz-Algorithm", valid_595728
  var valid_595729 = header.getOrDefault("X-Amz-Signature")
  valid_595729 = validateParameter(valid_595729, JString, required = false,
                                 default = nil)
  if valid_595729 != nil:
    section.add "X-Amz-Signature", valid_595729
  var valid_595730 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595730 = validateParameter(valid_595730, JString, required = false,
                                 default = nil)
  if valid_595730 != nil:
    section.add "X-Amz-SignedHeaders", valid_595730
  var valid_595731 = header.getOrDefault("X-Amz-Credential")
  valid_595731 = validateParameter(valid_595731, JString, required = false,
                                 default = nil)
  if valid_595731 != nil:
    section.add "X-Amz-Credential", valid_595731
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595733: Call_UpdateDocument_595721; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates one or more values for an SSM document.
  ## 
  let valid = call_595733.validator(path, query, header, formData, body)
  let scheme = call_595733.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595733.url(scheme.get, call_595733.host, call_595733.base,
                         call_595733.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595733, url, valid)

proc call*(call_595734: Call_UpdateDocument_595721; body: JsonNode): Recallable =
  ## updateDocument
  ## Updates one or more values for an SSM document.
  ##   body: JObject (required)
  var body_595735 = newJObject()
  if body != nil:
    body_595735 = body
  result = call_595734.call(nil, nil, nil, nil, body_595735)

var updateDocument* = Call_UpdateDocument_595721(name: "updateDocument",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.UpdateDocument",
    validator: validate_UpdateDocument_595722, base: "/", url: url_UpdateDocument_595723,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDocumentDefaultVersion_595736 = ref object of OpenApiRestCall_593437
proc url_UpdateDocumentDefaultVersion_595738(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateDocumentDefaultVersion_595737(path: JsonNode; query: JsonNode;
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
  var valid_595739 = header.getOrDefault("X-Amz-Date")
  valid_595739 = validateParameter(valid_595739, JString, required = false,
                                 default = nil)
  if valid_595739 != nil:
    section.add "X-Amz-Date", valid_595739
  var valid_595740 = header.getOrDefault("X-Amz-Security-Token")
  valid_595740 = validateParameter(valid_595740, JString, required = false,
                                 default = nil)
  if valid_595740 != nil:
    section.add "X-Amz-Security-Token", valid_595740
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595741 = header.getOrDefault("X-Amz-Target")
  valid_595741 = validateParameter(valid_595741, JString, required = true, default = newJString(
      "AmazonSSM.UpdateDocumentDefaultVersion"))
  if valid_595741 != nil:
    section.add "X-Amz-Target", valid_595741
  var valid_595742 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595742 = validateParameter(valid_595742, JString, required = false,
                                 default = nil)
  if valid_595742 != nil:
    section.add "X-Amz-Content-Sha256", valid_595742
  var valid_595743 = header.getOrDefault("X-Amz-Algorithm")
  valid_595743 = validateParameter(valid_595743, JString, required = false,
                                 default = nil)
  if valid_595743 != nil:
    section.add "X-Amz-Algorithm", valid_595743
  var valid_595744 = header.getOrDefault("X-Amz-Signature")
  valid_595744 = validateParameter(valid_595744, JString, required = false,
                                 default = nil)
  if valid_595744 != nil:
    section.add "X-Amz-Signature", valid_595744
  var valid_595745 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595745 = validateParameter(valid_595745, JString, required = false,
                                 default = nil)
  if valid_595745 != nil:
    section.add "X-Amz-SignedHeaders", valid_595745
  var valid_595746 = header.getOrDefault("X-Amz-Credential")
  valid_595746 = validateParameter(valid_595746, JString, required = false,
                                 default = nil)
  if valid_595746 != nil:
    section.add "X-Amz-Credential", valid_595746
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595748: Call_UpdateDocumentDefaultVersion_595736; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Set the default version of a document. 
  ## 
  let valid = call_595748.validator(path, query, header, formData, body)
  let scheme = call_595748.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595748.url(scheme.get, call_595748.host, call_595748.base,
                         call_595748.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595748, url, valid)

proc call*(call_595749: Call_UpdateDocumentDefaultVersion_595736; body: JsonNode): Recallable =
  ## updateDocumentDefaultVersion
  ## Set the default version of a document. 
  ##   body: JObject (required)
  var body_595750 = newJObject()
  if body != nil:
    body_595750 = body
  result = call_595749.call(nil, nil, nil, nil, body_595750)

var updateDocumentDefaultVersion* = Call_UpdateDocumentDefaultVersion_595736(
    name: "updateDocumentDefaultVersion", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.UpdateDocumentDefaultVersion",
    validator: validate_UpdateDocumentDefaultVersion_595737, base: "/",
    url: url_UpdateDocumentDefaultVersion_595738,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateMaintenanceWindow_595751 = ref object of OpenApiRestCall_593437
proc url_UpdateMaintenanceWindow_595753(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateMaintenanceWindow_595752(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates an existing maintenance window. Only specified parameters are modified.
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
  var valid_595754 = header.getOrDefault("X-Amz-Date")
  valid_595754 = validateParameter(valid_595754, JString, required = false,
                                 default = nil)
  if valid_595754 != nil:
    section.add "X-Amz-Date", valid_595754
  var valid_595755 = header.getOrDefault("X-Amz-Security-Token")
  valid_595755 = validateParameter(valid_595755, JString, required = false,
                                 default = nil)
  if valid_595755 != nil:
    section.add "X-Amz-Security-Token", valid_595755
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595756 = header.getOrDefault("X-Amz-Target")
  valid_595756 = validateParameter(valid_595756, JString, required = true, default = newJString(
      "AmazonSSM.UpdateMaintenanceWindow"))
  if valid_595756 != nil:
    section.add "X-Amz-Target", valid_595756
  var valid_595757 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595757 = validateParameter(valid_595757, JString, required = false,
                                 default = nil)
  if valid_595757 != nil:
    section.add "X-Amz-Content-Sha256", valid_595757
  var valid_595758 = header.getOrDefault("X-Amz-Algorithm")
  valid_595758 = validateParameter(valid_595758, JString, required = false,
                                 default = nil)
  if valid_595758 != nil:
    section.add "X-Amz-Algorithm", valid_595758
  var valid_595759 = header.getOrDefault("X-Amz-Signature")
  valid_595759 = validateParameter(valid_595759, JString, required = false,
                                 default = nil)
  if valid_595759 != nil:
    section.add "X-Amz-Signature", valid_595759
  var valid_595760 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595760 = validateParameter(valid_595760, JString, required = false,
                                 default = nil)
  if valid_595760 != nil:
    section.add "X-Amz-SignedHeaders", valid_595760
  var valid_595761 = header.getOrDefault("X-Amz-Credential")
  valid_595761 = validateParameter(valid_595761, JString, required = false,
                                 default = nil)
  if valid_595761 != nil:
    section.add "X-Amz-Credential", valid_595761
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595763: Call_UpdateMaintenanceWindow_595751; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing maintenance window. Only specified parameters are modified.
  ## 
  let valid = call_595763.validator(path, query, header, formData, body)
  let scheme = call_595763.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595763.url(scheme.get, call_595763.host, call_595763.base,
                         call_595763.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595763, url, valid)

proc call*(call_595764: Call_UpdateMaintenanceWindow_595751; body: JsonNode): Recallable =
  ## updateMaintenanceWindow
  ## Updates an existing maintenance window. Only specified parameters are modified.
  ##   body: JObject (required)
  var body_595765 = newJObject()
  if body != nil:
    body_595765 = body
  result = call_595764.call(nil, nil, nil, nil, body_595765)

var updateMaintenanceWindow* = Call_UpdateMaintenanceWindow_595751(
    name: "updateMaintenanceWindow", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.UpdateMaintenanceWindow",
    validator: validate_UpdateMaintenanceWindow_595752, base: "/",
    url: url_UpdateMaintenanceWindow_595753, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateMaintenanceWindowTarget_595766 = ref object of OpenApiRestCall_593437
proc url_UpdateMaintenanceWindowTarget_595768(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateMaintenanceWindowTarget_595767(path: JsonNode; query: JsonNode;
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
  var valid_595769 = header.getOrDefault("X-Amz-Date")
  valid_595769 = validateParameter(valid_595769, JString, required = false,
                                 default = nil)
  if valid_595769 != nil:
    section.add "X-Amz-Date", valid_595769
  var valid_595770 = header.getOrDefault("X-Amz-Security-Token")
  valid_595770 = validateParameter(valid_595770, JString, required = false,
                                 default = nil)
  if valid_595770 != nil:
    section.add "X-Amz-Security-Token", valid_595770
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595771 = header.getOrDefault("X-Amz-Target")
  valid_595771 = validateParameter(valid_595771, JString, required = true, default = newJString(
      "AmazonSSM.UpdateMaintenanceWindowTarget"))
  if valid_595771 != nil:
    section.add "X-Amz-Target", valid_595771
  var valid_595772 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595772 = validateParameter(valid_595772, JString, required = false,
                                 default = nil)
  if valid_595772 != nil:
    section.add "X-Amz-Content-Sha256", valid_595772
  var valid_595773 = header.getOrDefault("X-Amz-Algorithm")
  valid_595773 = validateParameter(valid_595773, JString, required = false,
                                 default = nil)
  if valid_595773 != nil:
    section.add "X-Amz-Algorithm", valid_595773
  var valid_595774 = header.getOrDefault("X-Amz-Signature")
  valid_595774 = validateParameter(valid_595774, JString, required = false,
                                 default = nil)
  if valid_595774 != nil:
    section.add "X-Amz-Signature", valid_595774
  var valid_595775 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595775 = validateParameter(valid_595775, JString, required = false,
                                 default = nil)
  if valid_595775 != nil:
    section.add "X-Amz-SignedHeaders", valid_595775
  var valid_595776 = header.getOrDefault("X-Amz-Credential")
  valid_595776 = validateParameter(valid_595776, JString, required = false,
                                 default = nil)
  if valid_595776 != nil:
    section.add "X-Amz-Credential", valid_595776
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595778: Call_UpdateMaintenanceWindowTarget_595766; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Modifies the target of an existing maintenance window. You can change the following:</p> <ul> <li> <p>Name</p> </li> <li> <p>Description</p> </li> <li> <p>Owner</p> </li> <li> <p>IDs for an ID target</p> </li> <li> <p>Tags for a Tag target</p> </li> <li> <p>From any supported tag type to another. The three supported tag types are ID target, Tag target, and resource group. For more information, see <a>Target</a>.</p> </li> </ul> <note> <p>If a parameter is null, then the corresponding field is not modified.</p> </note>
  ## 
  let valid = call_595778.validator(path, query, header, formData, body)
  let scheme = call_595778.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595778.url(scheme.get, call_595778.host, call_595778.base,
                         call_595778.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595778, url, valid)

proc call*(call_595779: Call_UpdateMaintenanceWindowTarget_595766; body: JsonNode): Recallable =
  ## updateMaintenanceWindowTarget
  ## <p>Modifies the target of an existing maintenance window. You can change the following:</p> <ul> <li> <p>Name</p> </li> <li> <p>Description</p> </li> <li> <p>Owner</p> </li> <li> <p>IDs for an ID target</p> </li> <li> <p>Tags for a Tag target</p> </li> <li> <p>From any supported tag type to another. The three supported tag types are ID target, Tag target, and resource group. For more information, see <a>Target</a>.</p> </li> </ul> <note> <p>If a parameter is null, then the corresponding field is not modified.</p> </note>
  ##   body: JObject (required)
  var body_595780 = newJObject()
  if body != nil:
    body_595780 = body
  result = call_595779.call(nil, nil, nil, nil, body_595780)

var updateMaintenanceWindowTarget* = Call_UpdateMaintenanceWindowTarget_595766(
    name: "updateMaintenanceWindowTarget", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.UpdateMaintenanceWindowTarget",
    validator: validate_UpdateMaintenanceWindowTarget_595767, base: "/",
    url: url_UpdateMaintenanceWindowTarget_595768,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateMaintenanceWindowTask_595781 = ref object of OpenApiRestCall_593437
proc url_UpdateMaintenanceWindowTask_595783(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateMaintenanceWindowTask_595782(path: JsonNode; query: JsonNode;
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
  var valid_595784 = header.getOrDefault("X-Amz-Date")
  valid_595784 = validateParameter(valid_595784, JString, required = false,
                                 default = nil)
  if valid_595784 != nil:
    section.add "X-Amz-Date", valid_595784
  var valid_595785 = header.getOrDefault("X-Amz-Security-Token")
  valid_595785 = validateParameter(valid_595785, JString, required = false,
                                 default = nil)
  if valid_595785 != nil:
    section.add "X-Amz-Security-Token", valid_595785
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595786 = header.getOrDefault("X-Amz-Target")
  valid_595786 = validateParameter(valid_595786, JString, required = true, default = newJString(
      "AmazonSSM.UpdateMaintenanceWindowTask"))
  if valid_595786 != nil:
    section.add "X-Amz-Target", valid_595786
  var valid_595787 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595787 = validateParameter(valid_595787, JString, required = false,
                                 default = nil)
  if valid_595787 != nil:
    section.add "X-Amz-Content-Sha256", valid_595787
  var valid_595788 = header.getOrDefault("X-Amz-Algorithm")
  valid_595788 = validateParameter(valid_595788, JString, required = false,
                                 default = nil)
  if valid_595788 != nil:
    section.add "X-Amz-Algorithm", valid_595788
  var valid_595789 = header.getOrDefault("X-Amz-Signature")
  valid_595789 = validateParameter(valid_595789, JString, required = false,
                                 default = nil)
  if valid_595789 != nil:
    section.add "X-Amz-Signature", valid_595789
  var valid_595790 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595790 = validateParameter(valid_595790, JString, required = false,
                                 default = nil)
  if valid_595790 != nil:
    section.add "X-Amz-SignedHeaders", valid_595790
  var valid_595791 = header.getOrDefault("X-Amz-Credential")
  valid_595791 = validateParameter(valid_595791, JString, required = false,
                                 default = nil)
  if valid_595791 != nil:
    section.add "X-Amz-Credential", valid_595791
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595793: Call_UpdateMaintenanceWindowTask_595781; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Modifies a task assigned to a maintenance window. You can't change the task type, but you can change the following values:</p> <ul> <li> <p>TaskARN. For example, you can change a RUN_COMMAND task from AWS-RunPowerShellScript to AWS-RunShellScript.</p> </li> <li> <p>ServiceRoleArn</p> </li> <li> <p>TaskInvocationParameters</p> </li> <li> <p>Priority</p> </li> <li> <p>MaxConcurrency</p> </li> <li> <p>MaxErrors</p> </li> </ul> <p>If a parameter is null, then the corresponding field is not modified. Also, if you set Replace to true, then all fields required by the <a>RegisterTaskWithMaintenanceWindow</a> action are required for this request. Optional fields that aren't specified are set to null.</p>
  ## 
  let valid = call_595793.validator(path, query, header, formData, body)
  let scheme = call_595793.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595793.url(scheme.get, call_595793.host, call_595793.base,
                         call_595793.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595793, url, valid)

proc call*(call_595794: Call_UpdateMaintenanceWindowTask_595781; body: JsonNode): Recallable =
  ## updateMaintenanceWindowTask
  ## <p>Modifies a task assigned to a maintenance window. You can't change the task type, but you can change the following values:</p> <ul> <li> <p>TaskARN. For example, you can change a RUN_COMMAND task from AWS-RunPowerShellScript to AWS-RunShellScript.</p> </li> <li> <p>ServiceRoleArn</p> </li> <li> <p>TaskInvocationParameters</p> </li> <li> <p>Priority</p> </li> <li> <p>MaxConcurrency</p> </li> <li> <p>MaxErrors</p> </li> </ul> <p>If a parameter is null, then the corresponding field is not modified. Also, if you set Replace to true, then all fields required by the <a>RegisterTaskWithMaintenanceWindow</a> action are required for this request. Optional fields that aren't specified are set to null.</p>
  ##   body: JObject (required)
  var body_595795 = newJObject()
  if body != nil:
    body_595795 = body
  result = call_595794.call(nil, nil, nil, nil, body_595795)

var updateMaintenanceWindowTask* = Call_UpdateMaintenanceWindowTask_595781(
    name: "updateMaintenanceWindowTask", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.UpdateMaintenanceWindowTask",
    validator: validate_UpdateMaintenanceWindowTask_595782, base: "/",
    url: url_UpdateMaintenanceWindowTask_595783,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateManagedInstanceRole_595796 = ref object of OpenApiRestCall_593437
proc url_UpdateManagedInstanceRole_595798(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateManagedInstanceRole_595797(path: JsonNode; query: JsonNode;
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
  var valid_595799 = header.getOrDefault("X-Amz-Date")
  valid_595799 = validateParameter(valid_595799, JString, required = false,
                                 default = nil)
  if valid_595799 != nil:
    section.add "X-Amz-Date", valid_595799
  var valid_595800 = header.getOrDefault("X-Amz-Security-Token")
  valid_595800 = validateParameter(valid_595800, JString, required = false,
                                 default = nil)
  if valid_595800 != nil:
    section.add "X-Amz-Security-Token", valid_595800
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595801 = header.getOrDefault("X-Amz-Target")
  valid_595801 = validateParameter(valid_595801, JString, required = true, default = newJString(
      "AmazonSSM.UpdateManagedInstanceRole"))
  if valid_595801 != nil:
    section.add "X-Amz-Target", valid_595801
  var valid_595802 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595802 = validateParameter(valid_595802, JString, required = false,
                                 default = nil)
  if valid_595802 != nil:
    section.add "X-Amz-Content-Sha256", valid_595802
  var valid_595803 = header.getOrDefault("X-Amz-Algorithm")
  valid_595803 = validateParameter(valid_595803, JString, required = false,
                                 default = nil)
  if valid_595803 != nil:
    section.add "X-Amz-Algorithm", valid_595803
  var valid_595804 = header.getOrDefault("X-Amz-Signature")
  valid_595804 = validateParameter(valid_595804, JString, required = false,
                                 default = nil)
  if valid_595804 != nil:
    section.add "X-Amz-Signature", valid_595804
  var valid_595805 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595805 = validateParameter(valid_595805, JString, required = false,
                                 default = nil)
  if valid_595805 != nil:
    section.add "X-Amz-SignedHeaders", valid_595805
  var valid_595806 = header.getOrDefault("X-Amz-Credential")
  valid_595806 = validateParameter(valid_595806, JString, required = false,
                                 default = nil)
  if valid_595806 != nil:
    section.add "X-Amz-Credential", valid_595806
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595808: Call_UpdateManagedInstanceRole_595796; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Assigns or changes an Amazon Identity and Access Management (IAM) role for the managed instance.
  ## 
  let valid = call_595808.validator(path, query, header, formData, body)
  let scheme = call_595808.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595808.url(scheme.get, call_595808.host, call_595808.base,
                         call_595808.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595808, url, valid)

proc call*(call_595809: Call_UpdateManagedInstanceRole_595796; body: JsonNode): Recallable =
  ## updateManagedInstanceRole
  ## Assigns or changes an Amazon Identity and Access Management (IAM) role for the managed instance.
  ##   body: JObject (required)
  var body_595810 = newJObject()
  if body != nil:
    body_595810 = body
  result = call_595809.call(nil, nil, nil, nil, body_595810)

var updateManagedInstanceRole* = Call_UpdateManagedInstanceRole_595796(
    name: "updateManagedInstanceRole", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.UpdateManagedInstanceRole",
    validator: validate_UpdateManagedInstanceRole_595797, base: "/",
    url: url_UpdateManagedInstanceRole_595798,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateOpsItem_595811 = ref object of OpenApiRestCall_593437
proc url_UpdateOpsItem_595813(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateOpsItem_595812(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_595814 = header.getOrDefault("X-Amz-Date")
  valid_595814 = validateParameter(valid_595814, JString, required = false,
                                 default = nil)
  if valid_595814 != nil:
    section.add "X-Amz-Date", valid_595814
  var valid_595815 = header.getOrDefault("X-Amz-Security-Token")
  valid_595815 = validateParameter(valid_595815, JString, required = false,
                                 default = nil)
  if valid_595815 != nil:
    section.add "X-Amz-Security-Token", valid_595815
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595816 = header.getOrDefault("X-Amz-Target")
  valid_595816 = validateParameter(valid_595816, JString, required = true, default = newJString(
      "AmazonSSM.UpdateOpsItem"))
  if valid_595816 != nil:
    section.add "X-Amz-Target", valid_595816
  var valid_595817 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595817 = validateParameter(valid_595817, JString, required = false,
                                 default = nil)
  if valid_595817 != nil:
    section.add "X-Amz-Content-Sha256", valid_595817
  var valid_595818 = header.getOrDefault("X-Amz-Algorithm")
  valid_595818 = validateParameter(valid_595818, JString, required = false,
                                 default = nil)
  if valid_595818 != nil:
    section.add "X-Amz-Algorithm", valid_595818
  var valid_595819 = header.getOrDefault("X-Amz-Signature")
  valid_595819 = validateParameter(valid_595819, JString, required = false,
                                 default = nil)
  if valid_595819 != nil:
    section.add "X-Amz-Signature", valid_595819
  var valid_595820 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595820 = validateParameter(valid_595820, JString, required = false,
                                 default = nil)
  if valid_595820 != nil:
    section.add "X-Amz-SignedHeaders", valid_595820
  var valid_595821 = header.getOrDefault("X-Amz-Credential")
  valid_595821 = validateParameter(valid_595821, JString, required = false,
                                 default = nil)
  if valid_595821 != nil:
    section.add "X-Amz-Credential", valid_595821
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595823: Call_UpdateOpsItem_595811; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Edit or change an OpsItem. You must have permission in AWS Identity and Access Management (IAM) to update an OpsItem. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter-getting-started.html">Getting Started with OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>.</p> <p>Operations engineers and IT professionals use OpsCenter to view, investigate, and remediate operational issues impacting the performance and health of their AWS resources. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter.html">AWS Systems Manager OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>. </p>
  ## 
  let valid = call_595823.validator(path, query, header, formData, body)
  let scheme = call_595823.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595823.url(scheme.get, call_595823.host, call_595823.base,
                         call_595823.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595823, url, valid)

proc call*(call_595824: Call_UpdateOpsItem_595811; body: JsonNode): Recallable =
  ## updateOpsItem
  ## <p>Edit or change an OpsItem. You must have permission in AWS Identity and Access Management (IAM) to update an OpsItem. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter-getting-started.html">Getting Started with OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>.</p> <p>Operations engineers and IT professionals use OpsCenter to view, investigate, and remediate operational issues impacting the performance and health of their AWS resources. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter.html">AWS Systems Manager OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>. </p>
  ##   body: JObject (required)
  var body_595825 = newJObject()
  if body != nil:
    body_595825 = body
  result = call_595824.call(nil, nil, nil, nil, body_595825)

var updateOpsItem* = Call_UpdateOpsItem_595811(name: "updateOpsItem",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.UpdateOpsItem",
    validator: validate_UpdateOpsItem_595812, base: "/", url: url_UpdateOpsItem_595813,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdatePatchBaseline_595826 = ref object of OpenApiRestCall_593437
proc url_UpdatePatchBaseline_595828(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdatePatchBaseline_595827(path: JsonNode; query: JsonNode;
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
  var valid_595829 = header.getOrDefault("X-Amz-Date")
  valid_595829 = validateParameter(valid_595829, JString, required = false,
                                 default = nil)
  if valid_595829 != nil:
    section.add "X-Amz-Date", valid_595829
  var valid_595830 = header.getOrDefault("X-Amz-Security-Token")
  valid_595830 = validateParameter(valid_595830, JString, required = false,
                                 default = nil)
  if valid_595830 != nil:
    section.add "X-Amz-Security-Token", valid_595830
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595831 = header.getOrDefault("X-Amz-Target")
  valid_595831 = validateParameter(valid_595831, JString, required = true, default = newJString(
      "AmazonSSM.UpdatePatchBaseline"))
  if valid_595831 != nil:
    section.add "X-Amz-Target", valid_595831
  var valid_595832 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595832 = validateParameter(valid_595832, JString, required = false,
                                 default = nil)
  if valid_595832 != nil:
    section.add "X-Amz-Content-Sha256", valid_595832
  var valid_595833 = header.getOrDefault("X-Amz-Algorithm")
  valid_595833 = validateParameter(valid_595833, JString, required = false,
                                 default = nil)
  if valid_595833 != nil:
    section.add "X-Amz-Algorithm", valid_595833
  var valid_595834 = header.getOrDefault("X-Amz-Signature")
  valid_595834 = validateParameter(valid_595834, JString, required = false,
                                 default = nil)
  if valid_595834 != nil:
    section.add "X-Amz-Signature", valid_595834
  var valid_595835 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595835 = validateParameter(valid_595835, JString, required = false,
                                 default = nil)
  if valid_595835 != nil:
    section.add "X-Amz-SignedHeaders", valid_595835
  var valid_595836 = header.getOrDefault("X-Amz-Credential")
  valid_595836 = validateParameter(valid_595836, JString, required = false,
                                 default = nil)
  if valid_595836 != nil:
    section.add "X-Amz-Credential", valid_595836
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595838: Call_UpdatePatchBaseline_595826; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Modifies an existing patch baseline. Fields not specified in the request are left unchanged.</p> <note> <p>For information about valid key and value pairs in <code>PatchFilters</code> for each supported operating system type, see <a href="http://docs.aws.amazon.com/systems-manager/latest/APIReference/API_PatchFilter.html">PatchFilter</a>.</p> </note>
  ## 
  let valid = call_595838.validator(path, query, header, formData, body)
  let scheme = call_595838.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595838.url(scheme.get, call_595838.host, call_595838.base,
                         call_595838.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595838, url, valid)

proc call*(call_595839: Call_UpdatePatchBaseline_595826; body: JsonNode): Recallable =
  ## updatePatchBaseline
  ## <p>Modifies an existing patch baseline. Fields not specified in the request are left unchanged.</p> <note> <p>For information about valid key and value pairs in <code>PatchFilters</code> for each supported operating system type, see <a href="http://docs.aws.amazon.com/systems-manager/latest/APIReference/API_PatchFilter.html">PatchFilter</a>.</p> </note>
  ##   body: JObject (required)
  var body_595840 = newJObject()
  if body != nil:
    body_595840 = body
  result = call_595839.call(nil, nil, nil, nil, body_595840)

var updatePatchBaseline* = Call_UpdatePatchBaseline_595826(
    name: "updatePatchBaseline", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.UpdatePatchBaseline",
    validator: validate_UpdatePatchBaseline_595827, base: "/",
    url: url_UpdatePatchBaseline_595828, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateServiceSetting_595841 = ref object of OpenApiRestCall_593437
proc url_UpdateServiceSetting_595843(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateServiceSetting_595842(path: JsonNode; query: JsonNode;
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
  var valid_595844 = header.getOrDefault("X-Amz-Date")
  valid_595844 = validateParameter(valid_595844, JString, required = false,
                                 default = nil)
  if valid_595844 != nil:
    section.add "X-Amz-Date", valid_595844
  var valid_595845 = header.getOrDefault("X-Amz-Security-Token")
  valid_595845 = validateParameter(valid_595845, JString, required = false,
                                 default = nil)
  if valid_595845 != nil:
    section.add "X-Amz-Security-Token", valid_595845
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595846 = header.getOrDefault("X-Amz-Target")
  valid_595846 = validateParameter(valid_595846, JString, required = true, default = newJString(
      "AmazonSSM.UpdateServiceSetting"))
  if valid_595846 != nil:
    section.add "X-Amz-Target", valid_595846
  var valid_595847 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595847 = validateParameter(valid_595847, JString, required = false,
                                 default = nil)
  if valid_595847 != nil:
    section.add "X-Amz-Content-Sha256", valid_595847
  var valid_595848 = header.getOrDefault("X-Amz-Algorithm")
  valid_595848 = validateParameter(valid_595848, JString, required = false,
                                 default = nil)
  if valid_595848 != nil:
    section.add "X-Amz-Algorithm", valid_595848
  var valid_595849 = header.getOrDefault("X-Amz-Signature")
  valid_595849 = validateParameter(valid_595849, JString, required = false,
                                 default = nil)
  if valid_595849 != nil:
    section.add "X-Amz-Signature", valid_595849
  var valid_595850 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595850 = validateParameter(valid_595850, JString, required = false,
                                 default = nil)
  if valid_595850 != nil:
    section.add "X-Amz-SignedHeaders", valid_595850
  var valid_595851 = header.getOrDefault("X-Amz-Credential")
  valid_595851 = validateParameter(valid_595851, JString, required = false,
                                 default = nil)
  if valid_595851 != nil:
    section.add "X-Amz-Credential", valid_595851
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595853: Call_UpdateServiceSetting_595841; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> <code>ServiceSetting</code> is an account-level setting for an AWS service. This setting defines how a user interacts with or uses a service or a feature of a service. For example, if an AWS service charges money to the account based on feature or service usage, then the AWS service team might create a default setting of "false". This means the user can't use this feature unless they change the setting to "true" and intentionally opt in for a paid feature.</p> <p>Services map a <code>SettingId</code> object to a setting value. AWS services teams define the default value for a <code>SettingId</code>. You can't create a new <code>SettingId</code>, but you can overwrite the default value if you have the <code>ssm:UpdateServiceSetting</code> permission for the setting. Use the <a>GetServiceSetting</a> API action to view the current value. Or, use the <a>ResetServiceSetting</a> to change the value back to the original value defined by the AWS service team.</p> <p>Update the service setting for the account. </p>
  ## 
  let valid = call_595853.validator(path, query, header, formData, body)
  let scheme = call_595853.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595853.url(scheme.get, call_595853.host, call_595853.base,
                         call_595853.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595853, url, valid)

proc call*(call_595854: Call_UpdateServiceSetting_595841; body: JsonNode): Recallable =
  ## updateServiceSetting
  ## <p> <code>ServiceSetting</code> is an account-level setting for an AWS service. This setting defines how a user interacts with or uses a service or a feature of a service. For example, if an AWS service charges money to the account based on feature or service usage, then the AWS service team might create a default setting of "false". This means the user can't use this feature unless they change the setting to "true" and intentionally opt in for a paid feature.</p> <p>Services map a <code>SettingId</code> object to a setting value. AWS services teams define the default value for a <code>SettingId</code>. You can't create a new <code>SettingId</code>, but you can overwrite the default value if you have the <code>ssm:UpdateServiceSetting</code> permission for the setting. Use the <a>GetServiceSetting</a> API action to view the current value. Or, use the <a>ResetServiceSetting</a> to change the value back to the original value defined by the AWS service team.</p> <p>Update the service setting for the account. </p>
  ##   body: JObject (required)
  var body_595855 = newJObject()
  if body != nil:
    body_595855 = body
  result = call_595854.call(nil, nil, nil, nil, body_595855)

var updateServiceSetting* = Call_UpdateServiceSetting_595841(
    name: "updateServiceSetting", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.UpdateServiceSetting",
    validator: validate_UpdateServiceSetting_595842, base: "/",
    url: url_UpdateServiceSetting_595843, schemes: {Scheme.Https, Scheme.Http})
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
