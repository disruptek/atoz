
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5, base64,
  httpcore, sigv4

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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode; body: string = ""): Recallable {.
    base.}
type
  Call_AddTagsToResource_21625779 = ref object of OpenApiRestCall_21625435
proc url_AddTagsToResource_21625781(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AddTagsToResource_21625780(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
      "AmazonSSM.AddTagsToResource"))
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

proc call*(call_21625929: Call_AddTagsToResource_21625779; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Adds or overwrites one or more tags for the specified resource. Tags are metadata that you can assign to your documents, managed instances, maintenance windows, Parameter Store parameters, and patch baselines. Tags enable you to categorize your resources in different ways, for example, by purpose, owner, or environment. Each tag consists of a key and an optional value, both of which you define. For example, you could define a set of tags for your account's managed instances that helps you track each instance's owner and stack level. For example: Key=Owner and Value=DbAdmin, SysAdmin, or Dev. Or Key=Stack and Value=Production, Pre-Production, or Test.</p> <p>Each resource can have a maximum of 50 tags. </p> <p>We recommend that you devise a set of tag keys that meets your needs for each resource type. Using a consistent set of tag keys makes it easier for you to manage your resources. You can search and filter the resources based on the tags you add. Tags don't have any semantic meaning to Amazon EC2 and are interpreted strictly as a string of characters. </p> <p>For more information about tags, see <a href="http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/Using_Tags.html">Tagging Your Amazon EC2 Resources</a> in the <i>Amazon EC2 User Guide</i>.</p>
  ## 
  let valid = call_21625929.validator(path, query, header, formData, body, _)
  let scheme = call_21625929.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21625929.makeUrl(scheme.get, call_21625929.host, call_21625929.base,
                               call_21625929.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21625929, uri, valid, _)

proc call*(call_21625992: Call_AddTagsToResource_21625779; body: JsonNode): Recallable =
  ## addTagsToResource
  ## <p>Adds or overwrites one or more tags for the specified resource. Tags are metadata that you can assign to your documents, managed instances, maintenance windows, Parameter Store parameters, and patch baselines. Tags enable you to categorize your resources in different ways, for example, by purpose, owner, or environment. Each tag consists of a key and an optional value, both of which you define. For example, you could define a set of tags for your account's managed instances that helps you track each instance's owner and stack level. For example: Key=Owner and Value=DbAdmin, SysAdmin, or Dev. Or Key=Stack and Value=Production, Pre-Production, or Test.</p> <p>Each resource can have a maximum of 50 tags. </p> <p>We recommend that you devise a set of tag keys that meets your needs for each resource type. Using a consistent set of tag keys makes it easier for you to manage your resources. You can search and filter the resources based on the tags you add. Tags don't have any semantic meaning to Amazon EC2 and are interpreted strictly as a string of characters. </p> <p>For more information about tags, see <a href="http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/Using_Tags.html">Tagging Your Amazon EC2 Resources</a> in the <i>Amazon EC2 User Guide</i>.</p>
  ##   body: JObject (required)
  var body_21625993 = newJObject()
  if body != nil:
    body_21625993 = body
  result = call_21625992.call(nil, nil, nil, nil, body_21625993)

var addTagsToResource* = Call_AddTagsToResource_21625779(name: "addTagsToResource",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.AddTagsToResource",
    validator: validate_AddTagsToResource_21625780, base: "/",
    makeUrl: url_AddTagsToResource_21625781, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CancelCommand_21626029 = ref object of OpenApiRestCall_21625435
proc url_CancelCommand_21626031(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CancelCommand_21626030(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
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
      "AmazonSSM.CancelCommand"))
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

proc call*(call_21626041: Call_CancelCommand_21626029; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Attempts to cancel the command specified by the Command ID. There is no guarantee that the command will be terminated and the underlying process stopped.
  ## 
  let valid = call_21626041.validator(path, query, header, formData, body, _)
  let scheme = call_21626041.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626041.makeUrl(scheme.get, call_21626041.host, call_21626041.base,
                               call_21626041.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626041, uri, valid, _)

proc call*(call_21626042: Call_CancelCommand_21626029; body: JsonNode): Recallable =
  ## cancelCommand
  ## Attempts to cancel the command specified by the Command ID. There is no guarantee that the command will be terminated and the underlying process stopped.
  ##   body: JObject (required)
  var body_21626043 = newJObject()
  if body != nil:
    body_21626043 = body
  result = call_21626042.call(nil, nil, nil, nil, body_21626043)

var cancelCommand* = Call_CancelCommand_21626029(name: "cancelCommand",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.CancelCommand",
    validator: validate_CancelCommand_21626030, base: "/",
    makeUrl: url_CancelCommand_21626031, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CancelMaintenanceWindowExecution_21626044 = ref object of OpenApiRestCall_21625435
proc url_CancelMaintenanceWindowExecution_21626046(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CancelMaintenanceWindowExecution_21626045(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
      "AmazonSSM.CancelMaintenanceWindowExecution"))
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

proc call*(call_21626056: Call_CancelMaintenanceWindowExecution_21626044;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Stops a maintenance window execution that is already in progress and cancels any tasks in the window that have not already starting running. (Tasks already in progress will continue to completion.)
  ## 
  let valid = call_21626056.validator(path, query, header, formData, body, _)
  let scheme = call_21626056.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626056.makeUrl(scheme.get, call_21626056.host, call_21626056.base,
                               call_21626056.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626056, uri, valid, _)

proc call*(call_21626057: Call_CancelMaintenanceWindowExecution_21626044;
          body: JsonNode): Recallable =
  ## cancelMaintenanceWindowExecution
  ## Stops a maintenance window execution that is already in progress and cancels any tasks in the window that have not already starting running. (Tasks already in progress will continue to completion.)
  ##   body: JObject (required)
  var body_21626058 = newJObject()
  if body != nil:
    body_21626058 = body
  result = call_21626057.call(nil, nil, nil, nil, body_21626058)

var cancelMaintenanceWindowExecution* = Call_CancelMaintenanceWindowExecution_21626044(
    name: "cancelMaintenanceWindowExecution", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.CancelMaintenanceWindowExecution",
    validator: validate_CancelMaintenanceWindowExecution_21626045, base: "/",
    makeUrl: url_CancelMaintenanceWindowExecution_21626046,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateActivation_21626059 = ref object of OpenApiRestCall_21625435
proc url_CreateActivation_21626061(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateActivation_21626060(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Generates an activation code and activation ID you can use to register your on-premises server or virtual machine (VM) with Systems Manager. Registering these machines with Systems Manager makes it possible to manage them using Systems Manager capabilities. You use the activation code and ID when installing SSM Agent on machines in your hybrid environment. For more information about requirements for managing on-premises instances and VMs using Systems Manager, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-managedinstances.html">Setting Up AWS Systems Manager for Hybrid Environments</a> in the <i>AWS Systems Manager User Guide</i>. </p> <note> <p>On-premises servers or VMs that are registered with Systems Manager and Amazon EC2 instances that you manage with Systems Manager are all called <i>managed instances</i>.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
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
  valid_21626064 = validateParameter(valid_21626064, JString, required = true, default = newJString(
      "AmazonSSM.CreateActivation"))
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

proc call*(call_21626071: Call_CreateActivation_21626059; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Generates an activation code and activation ID you can use to register your on-premises server or virtual machine (VM) with Systems Manager. Registering these machines with Systems Manager makes it possible to manage them using Systems Manager capabilities. You use the activation code and ID when installing SSM Agent on machines in your hybrid environment. For more information about requirements for managing on-premises instances and VMs using Systems Manager, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-managedinstances.html">Setting Up AWS Systems Manager for Hybrid Environments</a> in the <i>AWS Systems Manager User Guide</i>. </p> <note> <p>On-premises servers or VMs that are registered with Systems Manager and Amazon EC2 instances that you manage with Systems Manager are all called <i>managed instances</i>.</p> </note>
  ## 
  let valid = call_21626071.validator(path, query, header, formData, body, _)
  let scheme = call_21626071.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626071.makeUrl(scheme.get, call_21626071.host, call_21626071.base,
                               call_21626071.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626071, uri, valid, _)

proc call*(call_21626072: Call_CreateActivation_21626059; body: JsonNode): Recallable =
  ## createActivation
  ## <p>Generates an activation code and activation ID you can use to register your on-premises server or virtual machine (VM) with Systems Manager. Registering these machines with Systems Manager makes it possible to manage them using Systems Manager capabilities. You use the activation code and ID when installing SSM Agent on machines in your hybrid environment. For more information about requirements for managing on-premises instances and VMs using Systems Manager, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-managedinstances.html">Setting Up AWS Systems Manager for Hybrid Environments</a> in the <i>AWS Systems Manager User Guide</i>. </p> <note> <p>On-premises servers or VMs that are registered with Systems Manager and Amazon EC2 instances that you manage with Systems Manager are all called <i>managed instances</i>.</p> </note>
  ##   body: JObject (required)
  var body_21626073 = newJObject()
  if body != nil:
    body_21626073 = body
  result = call_21626072.call(nil, nil, nil, nil, body_21626073)

var createActivation* = Call_CreateActivation_21626059(name: "createActivation",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.CreateActivation",
    validator: validate_CreateActivation_21626060, base: "/",
    makeUrl: url_CreateActivation_21626061, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateAssociation_21626074 = ref object of OpenApiRestCall_21625435
proc url_CreateAssociation_21626076(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateAssociation_21626075(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
      "AmazonSSM.CreateAssociation"))
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

proc call*(call_21626086: Call_CreateAssociation_21626074; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Associates the specified Systems Manager document with the specified instances or targets.</p> <p>When you associate a document with one or more instances using instance IDs or tags, SSM Agent running on the instance processes the document and configures the instance as specified.</p> <p>If you associate a document with an instance that already has an associated document, the system returns the AssociationAlreadyExists exception.</p>
  ## 
  let valid = call_21626086.validator(path, query, header, formData, body, _)
  let scheme = call_21626086.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626086.makeUrl(scheme.get, call_21626086.host, call_21626086.base,
                               call_21626086.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626086, uri, valid, _)

proc call*(call_21626087: Call_CreateAssociation_21626074; body: JsonNode): Recallable =
  ## createAssociation
  ## <p>Associates the specified Systems Manager document with the specified instances or targets.</p> <p>When you associate a document with one or more instances using instance IDs or tags, SSM Agent running on the instance processes the document and configures the instance as specified.</p> <p>If you associate a document with an instance that already has an associated document, the system returns the AssociationAlreadyExists exception.</p>
  ##   body: JObject (required)
  var body_21626088 = newJObject()
  if body != nil:
    body_21626088 = body
  result = call_21626087.call(nil, nil, nil, nil, body_21626088)

var createAssociation* = Call_CreateAssociation_21626074(name: "createAssociation",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.CreateAssociation",
    validator: validate_CreateAssociation_21626075, base: "/",
    makeUrl: url_CreateAssociation_21626076, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateAssociationBatch_21626089 = ref object of OpenApiRestCall_21625435
proc url_CreateAssociationBatch_21626091(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateAssociationBatch_21626090(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
      "AmazonSSM.CreateAssociationBatch"))
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

proc call*(call_21626101: Call_CreateAssociationBatch_21626089;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Associates the specified Systems Manager document with the specified instances or targets.</p> <p>When you associate a document with one or more instances using instance IDs or tags, SSM Agent running on the instance processes the document and configures the instance as specified.</p> <p>If you associate a document with an instance that already has an associated document, the system returns the AssociationAlreadyExists exception.</p>
  ## 
  let valid = call_21626101.validator(path, query, header, formData, body, _)
  let scheme = call_21626101.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626101.makeUrl(scheme.get, call_21626101.host, call_21626101.base,
                               call_21626101.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626101, uri, valid, _)

proc call*(call_21626102: Call_CreateAssociationBatch_21626089; body: JsonNode): Recallable =
  ## createAssociationBatch
  ## <p>Associates the specified Systems Manager document with the specified instances or targets.</p> <p>When you associate a document with one or more instances using instance IDs or tags, SSM Agent running on the instance processes the document and configures the instance as specified.</p> <p>If you associate a document with an instance that already has an associated document, the system returns the AssociationAlreadyExists exception.</p>
  ##   body: JObject (required)
  var body_21626103 = newJObject()
  if body != nil:
    body_21626103 = body
  result = call_21626102.call(nil, nil, nil, nil, body_21626103)

var createAssociationBatch* = Call_CreateAssociationBatch_21626089(
    name: "createAssociationBatch", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.CreateAssociationBatch",
    validator: validate_CreateAssociationBatch_21626090, base: "/",
    makeUrl: url_CreateAssociationBatch_21626091,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDocument_21626104 = ref object of OpenApiRestCall_21625435
proc url_CreateDocument_21626106(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateDocument_21626105(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
      "AmazonSSM.CreateDocument"))
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

proc call*(call_21626116: Call_CreateDocument_21626104; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates a Systems Manager document.</p> <p>After you create a document, you can use CreateAssociation to associate it with one or more running instances.</p>
  ## 
  let valid = call_21626116.validator(path, query, header, formData, body, _)
  let scheme = call_21626116.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626116.makeUrl(scheme.get, call_21626116.host, call_21626116.base,
                               call_21626116.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626116, uri, valid, _)

proc call*(call_21626117: Call_CreateDocument_21626104; body: JsonNode): Recallable =
  ## createDocument
  ## <p>Creates a Systems Manager document.</p> <p>After you create a document, you can use CreateAssociation to associate it with one or more running instances.</p>
  ##   body: JObject (required)
  var body_21626118 = newJObject()
  if body != nil:
    body_21626118 = body
  result = call_21626117.call(nil, nil, nil, nil, body_21626118)

var createDocument* = Call_CreateDocument_21626104(name: "createDocument",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.CreateDocument",
    validator: validate_CreateDocument_21626105, base: "/",
    makeUrl: url_CreateDocument_21626106, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateMaintenanceWindow_21626119 = ref object of OpenApiRestCall_21625435
proc url_CreateMaintenanceWindow_21626121(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateMaintenanceWindow_21626120(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
      "AmazonSSM.CreateMaintenanceWindow"))
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

proc call*(call_21626131: Call_CreateMaintenanceWindow_21626119;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates a new maintenance window.</p> <note> <p>The value you specify for <code>Duration</code> determines the specific end time for the maintenance window based on the time it begins. No maintenance window tasks are permitted to start after the resulting endtime minus the number of hours you specify for <code>Cutoff</code>. For example, if the maintenance window starts at 3 PM, the duration is three hours, and the value you specify for <code>Cutoff</code> is one hour, no maintenance window tasks can start after 5 PM.</p> </note>
  ## 
  let valid = call_21626131.validator(path, query, header, formData, body, _)
  let scheme = call_21626131.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626131.makeUrl(scheme.get, call_21626131.host, call_21626131.base,
                               call_21626131.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626131, uri, valid, _)

proc call*(call_21626132: Call_CreateMaintenanceWindow_21626119; body: JsonNode): Recallable =
  ## createMaintenanceWindow
  ## <p>Creates a new maintenance window.</p> <note> <p>The value you specify for <code>Duration</code> determines the specific end time for the maintenance window based on the time it begins. No maintenance window tasks are permitted to start after the resulting endtime minus the number of hours you specify for <code>Cutoff</code>. For example, if the maintenance window starts at 3 PM, the duration is three hours, and the value you specify for <code>Cutoff</code> is one hour, no maintenance window tasks can start after 5 PM.</p> </note>
  ##   body: JObject (required)
  var body_21626133 = newJObject()
  if body != nil:
    body_21626133 = body
  result = call_21626132.call(nil, nil, nil, nil, body_21626133)

var createMaintenanceWindow* = Call_CreateMaintenanceWindow_21626119(
    name: "createMaintenanceWindow", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.CreateMaintenanceWindow",
    validator: validate_CreateMaintenanceWindow_21626120, base: "/",
    makeUrl: url_CreateMaintenanceWindow_21626121,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateOpsItem_21626134 = ref object of OpenApiRestCall_21625435
proc url_CreateOpsItem_21626136(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateOpsItem_21626135(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
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
      "AmazonSSM.CreateOpsItem"))
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

proc call*(call_21626146: Call_CreateOpsItem_21626134; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates a new OpsItem. You must have permission in AWS Identity and Access Management (IAM) to create a new OpsItem. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter-getting-started.html">Getting Started with OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>.</p> <p>Operations engineers and IT professionals use OpsCenter to view, investigate, and remediate operational issues impacting the performance and health of their AWS resources. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter.html">AWS Systems Manager OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>. </p>
  ## 
  let valid = call_21626146.validator(path, query, header, formData, body, _)
  let scheme = call_21626146.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626146.makeUrl(scheme.get, call_21626146.host, call_21626146.base,
                               call_21626146.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626146, uri, valid, _)

proc call*(call_21626147: Call_CreateOpsItem_21626134; body: JsonNode): Recallable =
  ## createOpsItem
  ## <p>Creates a new OpsItem. You must have permission in AWS Identity and Access Management (IAM) to create a new OpsItem. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter-getting-started.html">Getting Started with OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>.</p> <p>Operations engineers and IT professionals use OpsCenter to view, investigate, and remediate operational issues impacting the performance and health of their AWS resources. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter.html">AWS Systems Manager OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>. </p>
  ##   body: JObject (required)
  var body_21626148 = newJObject()
  if body != nil:
    body_21626148 = body
  result = call_21626147.call(nil, nil, nil, nil, body_21626148)

var createOpsItem* = Call_CreateOpsItem_21626134(name: "createOpsItem",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.CreateOpsItem",
    validator: validate_CreateOpsItem_21626135, base: "/",
    makeUrl: url_CreateOpsItem_21626136, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePatchBaseline_21626149 = ref object of OpenApiRestCall_21625435
proc url_CreatePatchBaseline_21626151(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreatePatchBaseline_21626150(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
      "AmazonSSM.CreatePatchBaseline"))
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

proc call*(call_21626161: Call_CreatePatchBaseline_21626149; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates a patch baseline.</p> <note> <p>For information about valid key and value pairs in <code>PatchFilters</code> for each supported operating system type, see <a href="http://docs.aws.amazon.com/systems-manager/latest/APIReference/API_PatchFilter.html">PatchFilter</a>.</p> </note>
  ## 
  let valid = call_21626161.validator(path, query, header, formData, body, _)
  let scheme = call_21626161.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626161.makeUrl(scheme.get, call_21626161.host, call_21626161.base,
                               call_21626161.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626161, uri, valid, _)

proc call*(call_21626162: Call_CreatePatchBaseline_21626149; body: JsonNode): Recallable =
  ## createPatchBaseline
  ## <p>Creates a patch baseline.</p> <note> <p>For information about valid key and value pairs in <code>PatchFilters</code> for each supported operating system type, see <a href="http://docs.aws.amazon.com/systems-manager/latest/APIReference/API_PatchFilter.html">PatchFilter</a>.</p> </note>
  ##   body: JObject (required)
  var body_21626163 = newJObject()
  if body != nil:
    body_21626163 = body
  result = call_21626162.call(nil, nil, nil, nil, body_21626163)

var createPatchBaseline* = Call_CreatePatchBaseline_21626149(
    name: "createPatchBaseline", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.CreatePatchBaseline",
    validator: validate_CreatePatchBaseline_21626150, base: "/",
    makeUrl: url_CreatePatchBaseline_21626151,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateResourceDataSync_21626164 = ref object of OpenApiRestCall_21625435
proc url_CreateResourceDataSync_21626166(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateResourceDataSync_21626165(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>A resource data sync helps you view data from multiple sources in a single location. Systems Manager offers two types of resource data sync: <code>SyncToDestination</code> and <code>SyncFromSource</code>.</p> <p>You can configure Systems Manager Inventory to use the <code>SyncToDestination</code> type to synchronize Inventory data from multiple AWS Regions to a single Amazon S3 bucket. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/sysman-inventory-datasync.html">Configuring Resource Data Sync for Inventory</a> in the <i>AWS Systems Manager User Guide</i>.</p> <p>You can configure Systems Manager Explorer to use the <code>SyncFromSource</code> type to synchronize operational work items (OpsItems) and operational data (OpsData) from multiple AWS Regions to a single Amazon S3 bucket. This type can synchronize OpsItems and OpsData from multiple AWS accounts and Regions or <code>EntireOrganization</code> by using AWS Organizations. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/Explorer-resource-data-sync.html">Setting Up Explorer to Display Data from Multiple Accounts and Regions</a> in the <i>AWS Systems Manager User Guide</i>.</p> <p>A resource data sync is an asynchronous operation that returns immediately. After a successful initial sync is completed, the system continuously syncs data. To check the status of a sync, use the <a>ListResourceDataSync</a>.</p> <note> <p>By default, data is not encrypted in Amazon S3. We strongly recommend that you enable encryption in Amazon S3 to ensure secure data storage. We also recommend that you secure access to the Amazon S3 bucket by creating a restrictive bucket policy. </p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
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
      "AmazonSSM.CreateResourceDataSync"))
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

proc call*(call_21626176: Call_CreateResourceDataSync_21626164;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>A resource data sync helps you view data from multiple sources in a single location. Systems Manager offers two types of resource data sync: <code>SyncToDestination</code> and <code>SyncFromSource</code>.</p> <p>You can configure Systems Manager Inventory to use the <code>SyncToDestination</code> type to synchronize Inventory data from multiple AWS Regions to a single Amazon S3 bucket. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/sysman-inventory-datasync.html">Configuring Resource Data Sync for Inventory</a> in the <i>AWS Systems Manager User Guide</i>.</p> <p>You can configure Systems Manager Explorer to use the <code>SyncFromSource</code> type to synchronize operational work items (OpsItems) and operational data (OpsData) from multiple AWS Regions to a single Amazon S3 bucket. This type can synchronize OpsItems and OpsData from multiple AWS accounts and Regions or <code>EntireOrganization</code> by using AWS Organizations. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/Explorer-resource-data-sync.html">Setting Up Explorer to Display Data from Multiple Accounts and Regions</a> in the <i>AWS Systems Manager User Guide</i>.</p> <p>A resource data sync is an asynchronous operation that returns immediately. After a successful initial sync is completed, the system continuously syncs data. To check the status of a sync, use the <a>ListResourceDataSync</a>.</p> <note> <p>By default, data is not encrypted in Amazon S3. We strongly recommend that you enable encryption in Amazon S3 to ensure secure data storage. We also recommend that you secure access to the Amazon S3 bucket by creating a restrictive bucket policy. </p> </note>
  ## 
  let valid = call_21626176.validator(path, query, header, formData, body, _)
  let scheme = call_21626176.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626176.makeUrl(scheme.get, call_21626176.host, call_21626176.base,
                               call_21626176.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626176, uri, valid, _)

proc call*(call_21626177: Call_CreateResourceDataSync_21626164; body: JsonNode): Recallable =
  ## createResourceDataSync
  ## <p>A resource data sync helps you view data from multiple sources in a single location. Systems Manager offers two types of resource data sync: <code>SyncToDestination</code> and <code>SyncFromSource</code>.</p> <p>You can configure Systems Manager Inventory to use the <code>SyncToDestination</code> type to synchronize Inventory data from multiple AWS Regions to a single Amazon S3 bucket. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/sysman-inventory-datasync.html">Configuring Resource Data Sync for Inventory</a> in the <i>AWS Systems Manager User Guide</i>.</p> <p>You can configure Systems Manager Explorer to use the <code>SyncFromSource</code> type to synchronize operational work items (OpsItems) and operational data (OpsData) from multiple AWS Regions to a single Amazon S3 bucket. This type can synchronize OpsItems and OpsData from multiple AWS accounts and Regions or <code>EntireOrganization</code> by using AWS Organizations. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/Explorer-resource-data-sync.html">Setting Up Explorer to Display Data from Multiple Accounts and Regions</a> in the <i>AWS Systems Manager User Guide</i>.</p> <p>A resource data sync is an asynchronous operation that returns immediately. After a successful initial sync is completed, the system continuously syncs data. To check the status of a sync, use the <a>ListResourceDataSync</a>.</p> <note> <p>By default, data is not encrypted in Amazon S3. We strongly recommend that you enable encryption in Amazon S3 to ensure secure data storage. We also recommend that you secure access to the Amazon S3 bucket by creating a restrictive bucket policy. </p> </note>
  ##   body: JObject (required)
  var body_21626178 = newJObject()
  if body != nil:
    body_21626178 = body
  result = call_21626177.call(nil, nil, nil, nil, body_21626178)

var createResourceDataSync* = Call_CreateResourceDataSync_21626164(
    name: "createResourceDataSync", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.CreateResourceDataSync",
    validator: validate_CreateResourceDataSync_21626165, base: "/",
    makeUrl: url_CreateResourceDataSync_21626166,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteActivation_21626179 = ref object of OpenApiRestCall_21625435
proc url_DeleteActivation_21626181(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteActivation_21626180(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
      "AmazonSSM.DeleteActivation"))
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

proc call*(call_21626191: Call_DeleteActivation_21626179; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes an activation. You are not required to delete an activation. If you delete an activation, you can no longer use it to register additional managed instances. Deleting an activation does not de-register managed instances. You must manually de-register managed instances.
  ## 
  let valid = call_21626191.validator(path, query, header, formData, body, _)
  let scheme = call_21626191.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626191.makeUrl(scheme.get, call_21626191.host, call_21626191.base,
                               call_21626191.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626191, uri, valid, _)

proc call*(call_21626192: Call_DeleteActivation_21626179; body: JsonNode): Recallable =
  ## deleteActivation
  ## Deletes an activation. You are not required to delete an activation. If you delete an activation, you can no longer use it to register additional managed instances. Deleting an activation does not de-register managed instances. You must manually de-register managed instances.
  ##   body: JObject (required)
  var body_21626193 = newJObject()
  if body != nil:
    body_21626193 = body
  result = call_21626192.call(nil, nil, nil, nil, body_21626193)

var deleteActivation* = Call_DeleteActivation_21626179(name: "deleteActivation",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DeleteActivation",
    validator: validate_DeleteActivation_21626180, base: "/",
    makeUrl: url_DeleteActivation_21626181, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAssociation_21626194 = ref object of OpenApiRestCall_21625435
proc url_DeleteAssociation_21626196(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteAssociation_21626195(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
      "AmazonSSM.DeleteAssociation"))
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

proc call*(call_21626206: Call_DeleteAssociation_21626194; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Disassociates the specified Systems Manager document from the specified instance.</p> <p>When you disassociate a document from an instance, it does not change the configuration of the instance. To change the configuration state of an instance after you disassociate a document, you must create a new document with the desired configuration and associate it with the instance.</p>
  ## 
  let valid = call_21626206.validator(path, query, header, formData, body, _)
  let scheme = call_21626206.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626206.makeUrl(scheme.get, call_21626206.host, call_21626206.base,
                               call_21626206.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626206, uri, valid, _)

proc call*(call_21626207: Call_DeleteAssociation_21626194; body: JsonNode): Recallable =
  ## deleteAssociation
  ## <p>Disassociates the specified Systems Manager document from the specified instance.</p> <p>When you disassociate a document from an instance, it does not change the configuration of the instance. To change the configuration state of an instance after you disassociate a document, you must create a new document with the desired configuration and associate it with the instance.</p>
  ##   body: JObject (required)
  var body_21626208 = newJObject()
  if body != nil:
    body_21626208 = body
  result = call_21626207.call(nil, nil, nil, nil, body_21626208)

var deleteAssociation* = Call_DeleteAssociation_21626194(name: "deleteAssociation",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DeleteAssociation",
    validator: validate_DeleteAssociation_21626195, base: "/",
    makeUrl: url_DeleteAssociation_21626196, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDocument_21626209 = ref object of OpenApiRestCall_21625435
proc url_DeleteDocument_21626211(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteDocument_21626210(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
      "AmazonSSM.DeleteDocument"))
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

proc call*(call_21626221: Call_DeleteDocument_21626209; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deletes the Systems Manager document and all instance associations to the document.</p> <p>Before you delete the document, we recommend that you use <a>DeleteAssociation</a> to disassociate all instances that are associated with the document.</p>
  ## 
  let valid = call_21626221.validator(path, query, header, formData, body, _)
  let scheme = call_21626221.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626221.makeUrl(scheme.get, call_21626221.host, call_21626221.base,
                               call_21626221.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626221, uri, valid, _)

proc call*(call_21626222: Call_DeleteDocument_21626209; body: JsonNode): Recallable =
  ## deleteDocument
  ## <p>Deletes the Systems Manager document and all instance associations to the document.</p> <p>Before you delete the document, we recommend that you use <a>DeleteAssociation</a> to disassociate all instances that are associated with the document.</p>
  ##   body: JObject (required)
  var body_21626223 = newJObject()
  if body != nil:
    body_21626223 = body
  result = call_21626222.call(nil, nil, nil, nil, body_21626223)

var deleteDocument* = Call_DeleteDocument_21626209(name: "deleteDocument",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DeleteDocument",
    validator: validate_DeleteDocument_21626210, base: "/",
    makeUrl: url_DeleteDocument_21626211, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteInventory_21626224 = ref object of OpenApiRestCall_21625435
proc url_DeleteInventory_21626226(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteInventory_21626225(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
      "AmazonSSM.DeleteInventory"))
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

proc call*(call_21626236: Call_DeleteInventory_21626224; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Delete a custom inventory type, or the data associated with a custom Inventory type. Deleting a custom inventory type is also referred to as deleting a custom inventory schema.
  ## 
  let valid = call_21626236.validator(path, query, header, formData, body, _)
  let scheme = call_21626236.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626236.makeUrl(scheme.get, call_21626236.host, call_21626236.base,
                               call_21626236.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626236, uri, valid, _)

proc call*(call_21626237: Call_DeleteInventory_21626224; body: JsonNode): Recallable =
  ## deleteInventory
  ## Delete a custom inventory type, or the data associated with a custom Inventory type. Deleting a custom inventory type is also referred to as deleting a custom inventory schema.
  ##   body: JObject (required)
  var body_21626238 = newJObject()
  if body != nil:
    body_21626238 = body
  result = call_21626237.call(nil, nil, nil, nil, body_21626238)

var deleteInventory* = Call_DeleteInventory_21626224(name: "deleteInventory",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DeleteInventory",
    validator: validate_DeleteInventory_21626225, base: "/",
    makeUrl: url_DeleteInventory_21626226, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteMaintenanceWindow_21626239 = ref object of OpenApiRestCall_21625435
proc url_DeleteMaintenanceWindow_21626241(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteMaintenanceWindow_21626240(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
      "AmazonSSM.DeleteMaintenanceWindow"))
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

proc call*(call_21626251: Call_DeleteMaintenanceWindow_21626239;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a maintenance window.
  ## 
  let valid = call_21626251.validator(path, query, header, formData, body, _)
  let scheme = call_21626251.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626251.makeUrl(scheme.get, call_21626251.host, call_21626251.base,
                               call_21626251.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626251, uri, valid, _)

proc call*(call_21626252: Call_DeleteMaintenanceWindow_21626239; body: JsonNode): Recallable =
  ## deleteMaintenanceWindow
  ## Deletes a maintenance window.
  ##   body: JObject (required)
  var body_21626253 = newJObject()
  if body != nil:
    body_21626253 = body
  result = call_21626252.call(nil, nil, nil, nil, body_21626253)

var deleteMaintenanceWindow* = Call_DeleteMaintenanceWindow_21626239(
    name: "deleteMaintenanceWindow", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DeleteMaintenanceWindow",
    validator: validate_DeleteMaintenanceWindow_21626240, base: "/",
    makeUrl: url_DeleteMaintenanceWindow_21626241,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteParameter_21626254 = ref object of OpenApiRestCall_21625435
proc url_DeleteParameter_21626256(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteParameter_21626255(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
      "AmazonSSM.DeleteParameter"))
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

proc call*(call_21626266: Call_DeleteParameter_21626254; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Delete a parameter from the system.
  ## 
  let valid = call_21626266.validator(path, query, header, formData, body, _)
  let scheme = call_21626266.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626266.makeUrl(scheme.get, call_21626266.host, call_21626266.base,
                               call_21626266.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626266, uri, valid, _)

proc call*(call_21626267: Call_DeleteParameter_21626254; body: JsonNode): Recallable =
  ## deleteParameter
  ## Delete a parameter from the system.
  ##   body: JObject (required)
  var body_21626268 = newJObject()
  if body != nil:
    body_21626268 = body
  result = call_21626267.call(nil, nil, nil, nil, body_21626268)

var deleteParameter* = Call_DeleteParameter_21626254(name: "deleteParameter",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DeleteParameter",
    validator: validate_DeleteParameter_21626255, base: "/",
    makeUrl: url_DeleteParameter_21626256, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteParameters_21626269 = ref object of OpenApiRestCall_21625435
proc url_DeleteParameters_21626271(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteParameters_21626270(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
      "AmazonSSM.DeleteParameters"))
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

proc call*(call_21626281: Call_DeleteParameters_21626269; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Delete a list of parameters.
  ## 
  let valid = call_21626281.validator(path, query, header, formData, body, _)
  let scheme = call_21626281.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626281.makeUrl(scheme.get, call_21626281.host, call_21626281.base,
                               call_21626281.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626281, uri, valid, _)

proc call*(call_21626282: Call_DeleteParameters_21626269; body: JsonNode): Recallable =
  ## deleteParameters
  ## Delete a list of parameters.
  ##   body: JObject (required)
  var body_21626283 = newJObject()
  if body != nil:
    body_21626283 = body
  result = call_21626282.call(nil, nil, nil, nil, body_21626283)

var deleteParameters* = Call_DeleteParameters_21626269(name: "deleteParameters",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DeleteParameters",
    validator: validate_DeleteParameters_21626270, base: "/",
    makeUrl: url_DeleteParameters_21626271, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeletePatchBaseline_21626284 = ref object of OpenApiRestCall_21625435
proc url_DeletePatchBaseline_21626286(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeletePatchBaseline_21626285(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
      "AmazonSSM.DeletePatchBaseline"))
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

proc call*(call_21626296: Call_DeletePatchBaseline_21626284; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a patch baseline.
  ## 
  let valid = call_21626296.validator(path, query, header, formData, body, _)
  let scheme = call_21626296.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626296.makeUrl(scheme.get, call_21626296.host, call_21626296.base,
                               call_21626296.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626296, uri, valid, _)

proc call*(call_21626297: Call_DeletePatchBaseline_21626284; body: JsonNode): Recallable =
  ## deletePatchBaseline
  ## Deletes a patch baseline.
  ##   body: JObject (required)
  var body_21626298 = newJObject()
  if body != nil:
    body_21626298 = body
  result = call_21626297.call(nil, nil, nil, nil, body_21626298)

var deletePatchBaseline* = Call_DeletePatchBaseline_21626284(
    name: "deletePatchBaseline", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DeletePatchBaseline",
    validator: validate_DeletePatchBaseline_21626285, base: "/",
    makeUrl: url_DeletePatchBaseline_21626286,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteResourceDataSync_21626299 = ref object of OpenApiRestCall_21625435
proc url_DeleteResourceDataSync_21626301(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteResourceDataSync_21626300(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes a Resource Data Sync configuration. After the configuration is deleted, changes to data on managed instances are no longer synced to or from the target. Deleting a sync configuration does not delete data.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626302 = header.getOrDefault("X-Amz-Date")
  valid_21626302 = validateParameter(valid_21626302, JString, required = false,
                                   default = nil)
  if valid_21626302 != nil:
    section.add "X-Amz-Date", valid_21626302
  var valid_21626303 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626303 = validateParameter(valid_21626303, JString, required = false,
                                   default = nil)
  if valid_21626303 != nil:
    section.add "X-Amz-Security-Token", valid_21626303
  var valid_21626304 = header.getOrDefault("X-Amz-Target")
  valid_21626304 = validateParameter(valid_21626304, JString, required = true, default = newJString(
      "AmazonSSM.DeleteResourceDataSync"))
  if valid_21626304 != nil:
    section.add "X-Amz-Target", valid_21626304
  var valid_21626305 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626305 = validateParameter(valid_21626305, JString, required = false,
                                   default = nil)
  if valid_21626305 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626305
  var valid_21626306 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626306 = validateParameter(valid_21626306, JString, required = false,
                                   default = nil)
  if valid_21626306 != nil:
    section.add "X-Amz-Algorithm", valid_21626306
  var valid_21626307 = header.getOrDefault("X-Amz-Signature")
  valid_21626307 = validateParameter(valid_21626307, JString, required = false,
                                   default = nil)
  if valid_21626307 != nil:
    section.add "X-Amz-Signature", valid_21626307
  var valid_21626308 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626308 = validateParameter(valid_21626308, JString, required = false,
                                   default = nil)
  if valid_21626308 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626308
  var valid_21626309 = header.getOrDefault("X-Amz-Credential")
  valid_21626309 = validateParameter(valid_21626309, JString, required = false,
                                   default = nil)
  if valid_21626309 != nil:
    section.add "X-Amz-Credential", valid_21626309
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

proc call*(call_21626311: Call_DeleteResourceDataSync_21626299;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a Resource Data Sync configuration. After the configuration is deleted, changes to data on managed instances are no longer synced to or from the target. Deleting a sync configuration does not delete data.
  ## 
  let valid = call_21626311.validator(path, query, header, formData, body, _)
  let scheme = call_21626311.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626311.makeUrl(scheme.get, call_21626311.host, call_21626311.base,
                               call_21626311.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626311, uri, valid, _)

proc call*(call_21626312: Call_DeleteResourceDataSync_21626299; body: JsonNode): Recallable =
  ## deleteResourceDataSync
  ## Deletes a Resource Data Sync configuration. After the configuration is deleted, changes to data on managed instances are no longer synced to or from the target. Deleting a sync configuration does not delete data.
  ##   body: JObject (required)
  var body_21626313 = newJObject()
  if body != nil:
    body_21626313 = body
  result = call_21626312.call(nil, nil, nil, nil, body_21626313)

var deleteResourceDataSync* = Call_DeleteResourceDataSync_21626299(
    name: "deleteResourceDataSync", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DeleteResourceDataSync",
    validator: validate_DeleteResourceDataSync_21626300, base: "/",
    makeUrl: url_DeleteResourceDataSync_21626301,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeregisterManagedInstance_21626314 = ref object of OpenApiRestCall_21625435
proc url_DeregisterManagedInstance_21626316(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeregisterManagedInstance_21626315(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626317 = header.getOrDefault("X-Amz-Date")
  valid_21626317 = validateParameter(valid_21626317, JString, required = false,
                                   default = nil)
  if valid_21626317 != nil:
    section.add "X-Amz-Date", valid_21626317
  var valid_21626318 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626318 = validateParameter(valid_21626318, JString, required = false,
                                   default = nil)
  if valid_21626318 != nil:
    section.add "X-Amz-Security-Token", valid_21626318
  var valid_21626319 = header.getOrDefault("X-Amz-Target")
  valid_21626319 = validateParameter(valid_21626319, JString, required = true, default = newJString(
      "AmazonSSM.DeregisterManagedInstance"))
  if valid_21626319 != nil:
    section.add "X-Amz-Target", valid_21626319
  var valid_21626320 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626320 = validateParameter(valid_21626320, JString, required = false,
                                   default = nil)
  if valid_21626320 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626320
  var valid_21626321 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626321 = validateParameter(valid_21626321, JString, required = false,
                                   default = nil)
  if valid_21626321 != nil:
    section.add "X-Amz-Algorithm", valid_21626321
  var valid_21626322 = header.getOrDefault("X-Amz-Signature")
  valid_21626322 = validateParameter(valid_21626322, JString, required = false,
                                   default = nil)
  if valid_21626322 != nil:
    section.add "X-Amz-Signature", valid_21626322
  var valid_21626323 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626323 = validateParameter(valid_21626323, JString, required = false,
                                   default = nil)
  if valid_21626323 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626323
  var valid_21626324 = header.getOrDefault("X-Amz-Credential")
  valid_21626324 = validateParameter(valid_21626324, JString, required = false,
                                   default = nil)
  if valid_21626324 != nil:
    section.add "X-Amz-Credential", valid_21626324
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

proc call*(call_21626326: Call_DeregisterManagedInstance_21626314;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Removes the server or virtual machine from the list of registered servers. You can reregister the instance again at any time. If you don't plan to use Run Command on the server, we suggest uninstalling SSM Agent first.
  ## 
  let valid = call_21626326.validator(path, query, header, formData, body, _)
  let scheme = call_21626326.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626326.makeUrl(scheme.get, call_21626326.host, call_21626326.base,
                               call_21626326.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626326, uri, valid, _)

proc call*(call_21626327: Call_DeregisterManagedInstance_21626314; body: JsonNode): Recallable =
  ## deregisterManagedInstance
  ## Removes the server or virtual machine from the list of registered servers. You can reregister the instance again at any time. If you don't plan to use Run Command on the server, we suggest uninstalling SSM Agent first.
  ##   body: JObject (required)
  var body_21626328 = newJObject()
  if body != nil:
    body_21626328 = body
  result = call_21626327.call(nil, nil, nil, nil, body_21626328)

var deregisterManagedInstance* = Call_DeregisterManagedInstance_21626314(
    name: "deregisterManagedInstance", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DeregisterManagedInstance",
    validator: validate_DeregisterManagedInstance_21626315, base: "/",
    makeUrl: url_DeregisterManagedInstance_21626316,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeregisterPatchBaselineForPatchGroup_21626329 = ref object of OpenApiRestCall_21625435
proc url_DeregisterPatchBaselineForPatchGroup_21626331(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeregisterPatchBaselineForPatchGroup_21626330(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626332 = header.getOrDefault("X-Amz-Date")
  valid_21626332 = validateParameter(valid_21626332, JString, required = false,
                                   default = nil)
  if valid_21626332 != nil:
    section.add "X-Amz-Date", valid_21626332
  var valid_21626333 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626333 = validateParameter(valid_21626333, JString, required = false,
                                   default = nil)
  if valid_21626333 != nil:
    section.add "X-Amz-Security-Token", valid_21626333
  var valid_21626334 = header.getOrDefault("X-Amz-Target")
  valid_21626334 = validateParameter(valid_21626334, JString, required = true, default = newJString(
      "AmazonSSM.DeregisterPatchBaselineForPatchGroup"))
  if valid_21626334 != nil:
    section.add "X-Amz-Target", valid_21626334
  var valid_21626335 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626335 = validateParameter(valid_21626335, JString, required = false,
                                   default = nil)
  if valid_21626335 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626335
  var valid_21626336 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626336 = validateParameter(valid_21626336, JString, required = false,
                                   default = nil)
  if valid_21626336 != nil:
    section.add "X-Amz-Algorithm", valid_21626336
  var valid_21626337 = header.getOrDefault("X-Amz-Signature")
  valid_21626337 = validateParameter(valid_21626337, JString, required = false,
                                   default = nil)
  if valid_21626337 != nil:
    section.add "X-Amz-Signature", valid_21626337
  var valid_21626338 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626338 = validateParameter(valid_21626338, JString, required = false,
                                   default = nil)
  if valid_21626338 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626338
  var valid_21626339 = header.getOrDefault("X-Amz-Credential")
  valid_21626339 = validateParameter(valid_21626339, JString, required = false,
                                   default = nil)
  if valid_21626339 != nil:
    section.add "X-Amz-Credential", valid_21626339
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

proc call*(call_21626341: Call_DeregisterPatchBaselineForPatchGroup_21626329;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Removes a patch group from a patch baseline.
  ## 
  let valid = call_21626341.validator(path, query, header, formData, body, _)
  let scheme = call_21626341.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626341.makeUrl(scheme.get, call_21626341.host, call_21626341.base,
                               call_21626341.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626341, uri, valid, _)

proc call*(call_21626342: Call_DeregisterPatchBaselineForPatchGroup_21626329;
          body: JsonNode): Recallable =
  ## deregisterPatchBaselineForPatchGroup
  ## Removes a patch group from a patch baseline.
  ##   body: JObject (required)
  var body_21626343 = newJObject()
  if body != nil:
    body_21626343 = body
  result = call_21626342.call(nil, nil, nil, nil, body_21626343)

var deregisterPatchBaselineForPatchGroup* = Call_DeregisterPatchBaselineForPatchGroup_21626329(
    name: "deregisterPatchBaselineForPatchGroup", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DeregisterPatchBaselineForPatchGroup",
    validator: validate_DeregisterPatchBaselineForPatchGroup_21626330, base: "/",
    makeUrl: url_DeregisterPatchBaselineForPatchGroup_21626331,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeregisterTargetFromMaintenanceWindow_21626344 = ref object of OpenApiRestCall_21625435
proc url_DeregisterTargetFromMaintenanceWindow_21626346(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeregisterTargetFromMaintenanceWindow_21626345(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626347 = header.getOrDefault("X-Amz-Date")
  valid_21626347 = validateParameter(valid_21626347, JString, required = false,
                                   default = nil)
  if valid_21626347 != nil:
    section.add "X-Amz-Date", valid_21626347
  var valid_21626348 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626348 = validateParameter(valid_21626348, JString, required = false,
                                   default = nil)
  if valid_21626348 != nil:
    section.add "X-Amz-Security-Token", valid_21626348
  var valid_21626349 = header.getOrDefault("X-Amz-Target")
  valid_21626349 = validateParameter(valid_21626349, JString, required = true, default = newJString(
      "AmazonSSM.DeregisterTargetFromMaintenanceWindow"))
  if valid_21626349 != nil:
    section.add "X-Amz-Target", valid_21626349
  var valid_21626350 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626350 = validateParameter(valid_21626350, JString, required = false,
                                   default = nil)
  if valid_21626350 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626350
  var valid_21626351 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626351 = validateParameter(valid_21626351, JString, required = false,
                                   default = nil)
  if valid_21626351 != nil:
    section.add "X-Amz-Algorithm", valid_21626351
  var valid_21626352 = header.getOrDefault("X-Amz-Signature")
  valid_21626352 = validateParameter(valid_21626352, JString, required = false,
                                   default = nil)
  if valid_21626352 != nil:
    section.add "X-Amz-Signature", valid_21626352
  var valid_21626353 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626353 = validateParameter(valid_21626353, JString, required = false,
                                   default = nil)
  if valid_21626353 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626353
  var valid_21626354 = header.getOrDefault("X-Amz-Credential")
  valid_21626354 = validateParameter(valid_21626354, JString, required = false,
                                   default = nil)
  if valid_21626354 != nil:
    section.add "X-Amz-Credential", valid_21626354
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

proc call*(call_21626356: Call_DeregisterTargetFromMaintenanceWindow_21626344;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Removes a target from a maintenance window.
  ## 
  let valid = call_21626356.validator(path, query, header, formData, body, _)
  let scheme = call_21626356.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626356.makeUrl(scheme.get, call_21626356.host, call_21626356.base,
                               call_21626356.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626356, uri, valid, _)

proc call*(call_21626357: Call_DeregisterTargetFromMaintenanceWindow_21626344;
          body: JsonNode): Recallable =
  ## deregisterTargetFromMaintenanceWindow
  ## Removes a target from a maintenance window.
  ##   body: JObject (required)
  var body_21626358 = newJObject()
  if body != nil:
    body_21626358 = body
  result = call_21626357.call(nil, nil, nil, nil, body_21626358)

var deregisterTargetFromMaintenanceWindow* = Call_DeregisterTargetFromMaintenanceWindow_21626344(
    name: "deregisterTargetFromMaintenanceWindow", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DeregisterTargetFromMaintenanceWindow",
    validator: validate_DeregisterTargetFromMaintenanceWindow_21626345, base: "/",
    makeUrl: url_DeregisterTargetFromMaintenanceWindow_21626346,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeregisterTaskFromMaintenanceWindow_21626359 = ref object of OpenApiRestCall_21625435
proc url_DeregisterTaskFromMaintenanceWindow_21626361(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeregisterTaskFromMaintenanceWindow_21626360(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626362 = header.getOrDefault("X-Amz-Date")
  valid_21626362 = validateParameter(valid_21626362, JString, required = false,
                                   default = nil)
  if valid_21626362 != nil:
    section.add "X-Amz-Date", valid_21626362
  var valid_21626363 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626363 = validateParameter(valid_21626363, JString, required = false,
                                   default = nil)
  if valid_21626363 != nil:
    section.add "X-Amz-Security-Token", valid_21626363
  var valid_21626364 = header.getOrDefault("X-Amz-Target")
  valid_21626364 = validateParameter(valid_21626364, JString, required = true, default = newJString(
      "AmazonSSM.DeregisterTaskFromMaintenanceWindow"))
  if valid_21626364 != nil:
    section.add "X-Amz-Target", valid_21626364
  var valid_21626365 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626365 = validateParameter(valid_21626365, JString, required = false,
                                   default = nil)
  if valid_21626365 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626365
  var valid_21626366 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626366 = validateParameter(valid_21626366, JString, required = false,
                                   default = nil)
  if valid_21626366 != nil:
    section.add "X-Amz-Algorithm", valid_21626366
  var valid_21626367 = header.getOrDefault("X-Amz-Signature")
  valid_21626367 = validateParameter(valid_21626367, JString, required = false,
                                   default = nil)
  if valid_21626367 != nil:
    section.add "X-Amz-Signature", valid_21626367
  var valid_21626368 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626368 = validateParameter(valid_21626368, JString, required = false,
                                   default = nil)
  if valid_21626368 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626368
  var valid_21626369 = header.getOrDefault("X-Amz-Credential")
  valid_21626369 = validateParameter(valid_21626369, JString, required = false,
                                   default = nil)
  if valid_21626369 != nil:
    section.add "X-Amz-Credential", valid_21626369
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

proc call*(call_21626371: Call_DeregisterTaskFromMaintenanceWindow_21626359;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Removes a task from a maintenance window.
  ## 
  let valid = call_21626371.validator(path, query, header, formData, body, _)
  let scheme = call_21626371.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626371.makeUrl(scheme.get, call_21626371.host, call_21626371.base,
                               call_21626371.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626371, uri, valid, _)

proc call*(call_21626372: Call_DeregisterTaskFromMaintenanceWindow_21626359;
          body: JsonNode): Recallable =
  ## deregisterTaskFromMaintenanceWindow
  ## Removes a task from a maintenance window.
  ##   body: JObject (required)
  var body_21626373 = newJObject()
  if body != nil:
    body_21626373 = body
  result = call_21626372.call(nil, nil, nil, nil, body_21626373)

var deregisterTaskFromMaintenanceWindow* = Call_DeregisterTaskFromMaintenanceWindow_21626359(
    name: "deregisterTaskFromMaintenanceWindow", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DeregisterTaskFromMaintenanceWindow",
    validator: validate_DeregisterTaskFromMaintenanceWindow_21626360, base: "/",
    makeUrl: url_DeregisterTaskFromMaintenanceWindow_21626361,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeActivations_21626374 = ref object of OpenApiRestCall_21625435
proc url_DescribeActivations_21626376(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeActivations_21626375(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626377 = query.getOrDefault("NextToken")
  valid_21626377 = validateParameter(valid_21626377, JString, required = false,
                                   default = nil)
  if valid_21626377 != nil:
    section.add "NextToken", valid_21626377
  var valid_21626378 = query.getOrDefault("MaxResults")
  valid_21626378 = validateParameter(valid_21626378, JString, required = false,
                                   default = nil)
  if valid_21626378 != nil:
    section.add "MaxResults", valid_21626378
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626379 = header.getOrDefault("X-Amz-Date")
  valid_21626379 = validateParameter(valid_21626379, JString, required = false,
                                   default = nil)
  if valid_21626379 != nil:
    section.add "X-Amz-Date", valid_21626379
  var valid_21626380 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626380 = validateParameter(valid_21626380, JString, required = false,
                                   default = nil)
  if valid_21626380 != nil:
    section.add "X-Amz-Security-Token", valid_21626380
  var valid_21626381 = header.getOrDefault("X-Amz-Target")
  valid_21626381 = validateParameter(valid_21626381, JString, required = true, default = newJString(
      "AmazonSSM.DescribeActivations"))
  if valid_21626381 != nil:
    section.add "X-Amz-Target", valid_21626381
  var valid_21626382 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626382 = validateParameter(valid_21626382, JString, required = false,
                                   default = nil)
  if valid_21626382 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626382
  var valid_21626383 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626383 = validateParameter(valid_21626383, JString, required = false,
                                   default = nil)
  if valid_21626383 != nil:
    section.add "X-Amz-Algorithm", valid_21626383
  var valid_21626384 = header.getOrDefault("X-Amz-Signature")
  valid_21626384 = validateParameter(valid_21626384, JString, required = false,
                                   default = nil)
  if valid_21626384 != nil:
    section.add "X-Amz-Signature", valid_21626384
  var valid_21626385 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626385 = validateParameter(valid_21626385, JString, required = false,
                                   default = nil)
  if valid_21626385 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626385
  var valid_21626386 = header.getOrDefault("X-Amz-Credential")
  valid_21626386 = validateParameter(valid_21626386, JString, required = false,
                                   default = nil)
  if valid_21626386 != nil:
    section.add "X-Amz-Credential", valid_21626386
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

proc call*(call_21626388: Call_DescribeActivations_21626374; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Describes details about the activation, such as the date and time the activation was created, its expiration date, the IAM role assigned to the instances in the activation, and the number of instances registered by using this activation.
  ## 
  let valid = call_21626388.validator(path, query, header, formData, body, _)
  let scheme = call_21626388.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626388.makeUrl(scheme.get, call_21626388.host, call_21626388.base,
                               call_21626388.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626388, uri, valid, _)

proc call*(call_21626389: Call_DescribeActivations_21626374; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## describeActivations
  ## Describes details about the activation, such as the date and time the activation was created, its expiration date, the IAM role assigned to the instances in the activation, and the number of instances registered by using this activation.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_21626391 = newJObject()
  var body_21626392 = newJObject()
  add(query_21626391, "NextToken", newJString(NextToken))
  if body != nil:
    body_21626392 = body
  add(query_21626391, "MaxResults", newJString(MaxResults))
  result = call_21626389.call(nil, query_21626391, nil, nil, body_21626392)

var describeActivations* = Call_DescribeActivations_21626374(
    name: "describeActivations", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeActivations",
    validator: validate_DescribeActivations_21626375, base: "/",
    makeUrl: url_DescribeActivations_21626376,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAssociation_21626396 = ref object of OpenApiRestCall_21625435
proc url_DescribeAssociation_21626398(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeAssociation_21626397(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626399 = header.getOrDefault("X-Amz-Date")
  valid_21626399 = validateParameter(valid_21626399, JString, required = false,
                                   default = nil)
  if valid_21626399 != nil:
    section.add "X-Amz-Date", valid_21626399
  var valid_21626400 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626400 = validateParameter(valid_21626400, JString, required = false,
                                   default = nil)
  if valid_21626400 != nil:
    section.add "X-Amz-Security-Token", valid_21626400
  var valid_21626401 = header.getOrDefault("X-Amz-Target")
  valid_21626401 = validateParameter(valid_21626401, JString, required = true, default = newJString(
      "AmazonSSM.DescribeAssociation"))
  if valid_21626401 != nil:
    section.add "X-Amz-Target", valid_21626401
  var valid_21626402 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626402 = validateParameter(valid_21626402, JString, required = false,
                                   default = nil)
  if valid_21626402 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626402
  var valid_21626403 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626403 = validateParameter(valid_21626403, JString, required = false,
                                   default = nil)
  if valid_21626403 != nil:
    section.add "X-Amz-Algorithm", valid_21626403
  var valid_21626404 = header.getOrDefault("X-Amz-Signature")
  valid_21626404 = validateParameter(valid_21626404, JString, required = false,
                                   default = nil)
  if valid_21626404 != nil:
    section.add "X-Amz-Signature", valid_21626404
  var valid_21626405 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626405 = validateParameter(valid_21626405, JString, required = false,
                                   default = nil)
  if valid_21626405 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626405
  var valid_21626406 = header.getOrDefault("X-Amz-Credential")
  valid_21626406 = validateParameter(valid_21626406, JString, required = false,
                                   default = nil)
  if valid_21626406 != nil:
    section.add "X-Amz-Credential", valid_21626406
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

proc call*(call_21626408: Call_DescribeAssociation_21626396; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Describes the association for the specified target or instance. If you created the association by using the <code>Targets</code> parameter, then you must retrieve the association by using the association ID. If you created the association by specifying an instance ID and a Systems Manager document, then you retrieve the association by specifying the document name and the instance ID. 
  ## 
  let valid = call_21626408.validator(path, query, header, formData, body, _)
  let scheme = call_21626408.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626408.makeUrl(scheme.get, call_21626408.host, call_21626408.base,
                               call_21626408.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626408, uri, valid, _)

proc call*(call_21626409: Call_DescribeAssociation_21626396; body: JsonNode): Recallable =
  ## describeAssociation
  ## Describes the association for the specified target or instance. If you created the association by using the <code>Targets</code> parameter, then you must retrieve the association by using the association ID. If you created the association by specifying an instance ID and a Systems Manager document, then you retrieve the association by specifying the document name and the instance ID. 
  ##   body: JObject (required)
  var body_21626410 = newJObject()
  if body != nil:
    body_21626410 = body
  result = call_21626409.call(nil, nil, nil, nil, body_21626410)

var describeAssociation* = Call_DescribeAssociation_21626396(
    name: "describeAssociation", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeAssociation",
    validator: validate_DescribeAssociation_21626397, base: "/",
    makeUrl: url_DescribeAssociation_21626398,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAssociationExecutionTargets_21626411 = ref object of OpenApiRestCall_21625435
proc url_DescribeAssociationExecutionTargets_21626413(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeAssociationExecutionTargets_21626412(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626414 = header.getOrDefault("X-Amz-Date")
  valid_21626414 = validateParameter(valid_21626414, JString, required = false,
                                   default = nil)
  if valid_21626414 != nil:
    section.add "X-Amz-Date", valid_21626414
  var valid_21626415 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626415 = validateParameter(valid_21626415, JString, required = false,
                                   default = nil)
  if valid_21626415 != nil:
    section.add "X-Amz-Security-Token", valid_21626415
  var valid_21626416 = header.getOrDefault("X-Amz-Target")
  valid_21626416 = validateParameter(valid_21626416, JString, required = true, default = newJString(
      "AmazonSSM.DescribeAssociationExecutionTargets"))
  if valid_21626416 != nil:
    section.add "X-Amz-Target", valid_21626416
  var valid_21626417 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626417 = validateParameter(valid_21626417, JString, required = false,
                                   default = nil)
  if valid_21626417 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626417
  var valid_21626418 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626418 = validateParameter(valid_21626418, JString, required = false,
                                   default = nil)
  if valid_21626418 != nil:
    section.add "X-Amz-Algorithm", valid_21626418
  var valid_21626419 = header.getOrDefault("X-Amz-Signature")
  valid_21626419 = validateParameter(valid_21626419, JString, required = false,
                                   default = nil)
  if valid_21626419 != nil:
    section.add "X-Amz-Signature", valid_21626419
  var valid_21626420 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626420 = validateParameter(valid_21626420, JString, required = false,
                                   default = nil)
  if valid_21626420 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626420
  var valid_21626421 = header.getOrDefault("X-Amz-Credential")
  valid_21626421 = validateParameter(valid_21626421, JString, required = false,
                                   default = nil)
  if valid_21626421 != nil:
    section.add "X-Amz-Credential", valid_21626421
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

proc call*(call_21626423: Call_DescribeAssociationExecutionTargets_21626411;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Use this API action to view information about a specific execution of a specific association.
  ## 
  let valid = call_21626423.validator(path, query, header, formData, body, _)
  let scheme = call_21626423.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626423.makeUrl(scheme.get, call_21626423.host, call_21626423.base,
                               call_21626423.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626423, uri, valid, _)

proc call*(call_21626424: Call_DescribeAssociationExecutionTargets_21626411;
          body: JsonNode): Recallable =
  ## describeAssociationExecutionTargets
  ## Use this API action to view information about a specific execution of a specific association.
  ##   body: JObject (required)
  var body_21626425 = newJObject()
  if body != nil:
    body_21626425 = body
  result = call_21626424.call(nil, nil, nil, nil, body_21626425)

var describeAssociationExecutionTargets* = Call_DescribeAssociationExecutionTargets_21626411(
    name: "describeAssociationExecutionTargets", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeAssociationExecutionTargets",
    validator: validate_DescribeAssociationExecutionTargets_21626412, base: "/",
    makeUrl: url_DescribeAssociationExecutionTargets_21626413,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAssociationExecutions_21626426 = ref object of OpenApiRestCall_21625435
proc url_DescribeAssociationExecutions_21626428(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeAssociationExecutions_21626427(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626429 = header.getOrDefault("X-Amz-Date")
  valid_21626429 = validateParameter(valid_21626429, JString, required = false,
                                   default = nil)
  if valid_21626429 != nil:
    section.add "X-Amz-Date", valid_21626429
  var valid_21626430 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626430 = validateParameter(valid_21626430, JString, required = false,
                                   default = nil)
  if valid_21626430 != nil:
    section.add "X-Amz-Security-Token", valid_21626430
  var valid_21626431 = header.getOrDefault("X-Amz-Target")
  valid_21626431 = validateParameter(valid_21626431, JString, required = true, default = newJString(
      "AmazonSSM.DescribeAssociationExecutions"))
  if valid_21626431 != nil:
    section.add "X-Amz-Target", valid_21626431
  var valid_21626432 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626432 = validateParameter(valid_21626432, JString, required = false,
                                   default = nil)
  if valid_21626432 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626432
  var valid_21626433 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626433 = validateParameter(valid_21626433, JString, required = false,
                                   default = nil)
  if valid_21626433 != nil:
    section.add "X-Amz-Algorithm", valid_21626433
  var valid_21626434 = header.getOrDefault("X-Amz-Signature")
  valid_21626434 = validateParameter(valid_21626434, JString, required = false,
                                   default = nil)
  if valid_21626434 != nil:
    section.add "X-Amz-Signature", valid_21626434
  var valid_21626435 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626435 = validateParameter(valid_21626435, JString, required = false,
                                   default = nil)
  if valid_21626435 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626435
  var valid_21626436 = header.getOrDefault("X-Amz-Credential")
  valid_21626436 = validateParameter(valid_21626436, JString, required = false,
                                   default = nil)
  if valid_21626436 != nil:
    section.add "X-Amz-Credential", valid_21626436
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

proc call*(call_21626438: Call_DescribeAssociationExecutions_21626426;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Use this API action to view all executions for a specific association ID. 
  ## 
  let valid = call_21626438.validator(path, query, header, formData, body, _)
  let scheme = call_21626438.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626438.makeUrl(scheme.get, call_21626438.host, call_21626438.base,
                               call_21626438.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626438, uri, valid, _)

proc call*(call_21626439: Call_DescribeAssociationExecutions_21626426;
          body: JsonNode): Recallable =
  ## describeAssociationExecutions
  ## Use this API action to view all executions for a specific association ID. 
  ##   body: JObject (required)
  var body_21626440 = newJObject()
  if body != nil:
    body_21626440 = body
  result = call_21626439.call(nil, nil, nil, nil, body_21626440)

var describeAssociationExecutions* = Call_DescribeAssociationExecutions_21626426(
    name: "describeAssociationExecutions", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeAssociationExecutions",
    validator: validate_DescribeAssociationExecutions_21626427, base: "/",
    makeUrl: url_DescribeAssociationExecutions_21626428,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAutomationExecutions_21626441 = ref object of OpenApiRestCall_21625435
proc url_DescribeAutomationExecutions_21626443(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeAutomationExecutions_21626442(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626444 = header.getOrDefault("X-Amz-Date")
  valid_21626444 = validateParameter(valid_21626444, JString, required = false,
                                   default = nil)
  if valid_21626444 != nil:
    section.add "X-Amz-Date", valid_21626444
  var valid_21626445 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626445 = validateParameter(valid_21626445, JString, required = false,
                                   default = nil)
  if valid_21626445 != nil:
    section.add "X-Amz-Security-Token", valid_21626445
  var valid_21626446 = header.getOrDefault("X-Amz-Target")
  valid_21626446 = validateParameter(valid_21626446, JString, required = true, default = newJString(
      "AmazonSSM.DescribeAutomationExecutions"))
  if valid_21626446 != nil:
    section.add "X-Amz-Target", valid_21626446
  var valid_21626447 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626447 = validateParameter(valid_21626447, JString, required = false,
                                   default = nil)
  if valid_21626447 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626447
  var valid_21626448 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626448 = validateParameter(valid_21626448, JString, required = false,
                                   default = nil)
  if valid_21626448 != nil:
    section.add "X-Amz-Algorithm", valid_21626448
  var valid_21626449 = header.getOrDefault("X-Amz-Signature")
  valid_21626449 = validateParameter(valid_21626449, JString, required = false,
                                   default = nil)
  if valid_21626449 != nil:
    section.add "X-Amz-Signature", valid_21626449
  var valid_21626450 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626450 = validateParameter(valid_21626450, JString, required = false,
                                   default = nil)
  if valid_21626450 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626450
  var valid_21626451 = header.getOrDefault("X-Amz-Credential")
  valid_21626451 = validateParameter(valid_21626451, JString, required = false,
                                   default = nil)
  if valid_21626451 != nil:
    section.add "X-Amz-Credential", valid_21626451
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

proc call*(call_21626453: Call_DescribeAutomationExecutions_21626441;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Provides details about all active and terminated Automation executions.
  ## 
  let valid = call_21626453.validator(path, query, header, formData, body, _)
  let scheme = call_21626453.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626453.makeUrl(scheme.get, call_21626453.host, call_21626453.base,
                               call_21626453.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626453, uri, valid, _)

proc call*(call_21626454: Call_DescribeAutomationExecutions_21626441;
          body: JsonNode): Recallable =
  ## describeAutomationExecutions
  ## Provides details about all active and terminated Automation executions.
  ##   body: JObject (required)
  var body_21626455 = newJObject()
  if body != nil:
    body_21626455 = body
  result = call_21626454.call(nil, nil, nil, nil, body_21626455)

var describeAutomationExecutions* = Call_DescribeAutomationExecutions_21626441(
    name: "describeAutomationExecutions", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeAutomationExecutions",
    validator: validate_DescribeAutomationExecutions_21626442, base: "/",
    makeUrl: url_DescribeAutomationExecutions_21626443,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAutomationStepExecutions_21626456 = ref object of OpenApiRestCall_21625435
proc url_DescribeAutomationStepExecutions_21626458(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeAutomationStepExecutions_21626457(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626459 = header.getOrDefault("X-Amz-Date")
  valid_21626459 = validateParameter(valid_21626459, JString, required = false,
                                   default = nil)
  if valid_21626459 != nil:
    section.add "X-Amz-Date", valid_21626459
  var valid_21626460 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626460 = validateParameter(valid_21626460, JString, required = false,
                                   default = nil)
  if valid_21626460 != nil:
    section.add "X-Amz-Security-Token", valid_21626460
  var valid_21626461 = header.getOrDefault("X-Amz-Target")
  valid_21626461 = validateParameter(valid_21626461, JString, required = true, default = newJString(
      "AmazonSSM.DescribeAutomationStepExecutions"))
  if valid_21626461 != nil:
    section.add "X-Amz-Target", valid_21626461
  var valid_21626462 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626462 = validateParameter(valid_21626462, JString, required = false,
                                   default = nil)
  if valid_21626462 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626462
  var valid_21626463 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626463 = validateParameter(valid_21626463, JString, required = false,
                                   default = nil)
  if valid_21626463 != nil:
    section.add "X-Amz-Algorithm", valid_21626463
  var valid_21626464 = header.getOrDefault("X-Amz-Signature")
  valid_21626464 = validateParameter(valid_21626464, JString, required = false,
                                   default = nil)
  if valid_21626464 != nil:
    section.add "X-Amz-Signature", valid_21626464
  var valid_21626465 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626465 = validateParameter(valid_21626465, JString, required = false,
                                   default = nil)
  if valid_21626465 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626465
  var valid_21626466 = header.getOrDefault("X-Amz-Credential")
  valid_21626466 = validateParameter(valid_21626466, JString, required = false,
                                   default = nil)
  if valid_21626466 != nil:
    section.add "X-Amz-Credential", valid_21626466
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

proc call*(call_21626468: Call_DescribeAutomationStepExecutions_21626456;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Information about all active and terminated step executions in an Automation workflow.
  ## 
  let valid = call_21626468.validator(path, query, header, formData, body, _)
  let scheme = call_21626468.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626468.makeUrl(scheme.get, call_21626468.host, call_21626468.base,
                               call_21626468.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626468, uri, valid, _)

proc call*(call_21626469: Call_DescribeAutomationStepExecutions_21626456;
          body: JsonNode): Recallable =
  ## describeAutomationStepExecutions
  ## Information about all active and terminated step executions in an Automation workflow.
  ##   body: JObject (required)
  var body_21626470 = newJObject()
  if body != nil:
    body_21626470 = body
  result = call_21626469.call(nil, nil, nil, nil, body_21626470)

var describeAutomationStepExecutions* = Call_DescribeAutomationStepExecutions_21626456(
    name: "describeAutomationStepExecutions", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeAutomationStepExecutions",
    validator: validate_DescribeAutomationStepExecutions_21626457, base: "/",
    makeUrl: url_DescribeAutomationStepExecutions_21626458,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAvailablePatches_21626471 = ref object of OpenApiRestCall_21625435
proc url_DescribeAvailablePatches_21626473(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeAvailablePatches_21626472(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626474 = header.getOrDefault("X-Amz-Date")
  valid_21626474 = validateParameter(valid_21626474, JString, required = false,
                                   default = nil)
  if valid_21626474 != nil:
    section.add "X-Amz-Date", valid_21626474
  var valid_21626475 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626475 = validateParameter(valid_21626475, JString, required = false,
                                   default = nil)
  if valid_21626475 != nil:
    section.add "X-Amz-Security-Token", valid_21626475
  var valid_21626476 = header.getOrDefault("X-Amz-Target")
  valid_21626476 = validateParameter(valid_21626476, JString, required = true, default = newJString(
      "AmazonSSM.DescribeAvailablePatches"))
  if valid_21626476 != nil:
    section.add "X-Amz-Target", valid_21626476
  var valid_21626477 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626477 = validateParameter(valid_21626477, JString, required = false,
                                   default = nil)
  if valid_21626477 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626477
  var valid_21626478 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626478 = validateParameter(valid_21626478, JString, required = false,
                                   default = nil)
  if valid_21626478 != nil:
    section.add "X-Amz-Algorithm", valid_21626478
  var valid_21626479 = header.getOrDefault("X-Amz-Signature")
  valid_21626479 = validateParameter(valid_21626479, JString, required = false,
                                   default = nil)
  if valid_21626479 != nil:
    section.add "X-Amz-Signature", valid_21626479
  var valid_21626480 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626480 = validateParameter(valid_21626480, JString, required = false,
                                   default = nil)
  if valid_21626480 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626480
  var valid_21626481 = header.getOrDefault("X-Amz-Credential")
  valid_21626481 = validateParameter(valid_21626481, JString, required = false,
                                   default = nil)
  if valid_21626481 != nil:
    section.add "X-Amz-Credential", valid_21626481
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

proc call*(call_21626483: Call_DescribeAvailablePatches_21626471;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists all patches eligible to be included in a patch baseline.
  ## 
  let valid = call_21626483.validator(path, query, header, formData, body, _)
  let scheme = call_21626483.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626483.makeUrl(scheme.get, call_21626483.host, call_21626483.base,
                               call_21626483.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626483, uri, valid, _)

proc call*(call_21626484: Call_DescribeAvailablePatches_21626471; body: JsonNode): Recallable =
  ## describeAvailablePatches
  ## Lists all patches eligible to be included in a patch baseline.
  ##   body: JObject (required)
  var body_21626485 = newJObject()
  if body != nil:
    body_21626485 = body
  result = call_21626484.call(nil, nil, nil, nil, body_21626485)

var describeAvailablePatches* = Call_DescribeAvailablePatches_21626471(
    name: "describeAvailablePatches", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeAvailablePatches",
    validator: validate_DescribeAvailablePatches_21626472, base: "/",
    makeUrl: url_DescribeAvailablePatches_21626473,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDocument_21626486 = ref object of OpenApiRestCall_21625435
proc url_DescribeDocument_21626488(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeDocument_21626487(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626489 = header.getOrDefault("X-Amz-Date")
  valid_21626489 = validateParameter(valid_21626489, JString, required = false,
                                   default = nil)
  if valid_21626489 != nil:
    section.add "X-Amz-Date", valid_21626489
  var valid_21626490 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626490 = validateParameter(valid_21626490, JString, required = false,
                                   default = nil)
  if valid_21626490 != nil:
    section.add "X-Amz-Security-Token", valid_21626490
  var valid_21626491 = header.getOrDefault("X-Amz-Target")
  valid_21626491 = validateParameter(valid_21626491, JString, required = true, default = newJString(
      "AmazonSSM.DescribeDocument"))
  if valid_21626491 != nil:
    section.add "X-Amz-Target", valid_21626491
  var valid_21626492 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626492 = validateParameter(valid_21626492, JString, required = false,
                                   default = nil)
  if valid_21626492 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626492
  var valid_21626493 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626493 = validateParameter(valid_21626493, JString, required = false,
                                   default = nil)
  if valid_21626493 != nil:
    section.add "X-Amz-Algorithm", valid_21626493
  var valid_21626494 = header.getOrDefault("X-Amz-Signature")
  valid_21626494 = validateParameter(valid_21626494, JString, required = false,
                                   default = nil)
  if valid_21626494 != nil:
    section.add "X-Amz-Signature", valid_21626494
  var valid_21626495 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626495 = validateParameter(valid_21626495, JString, required = false,
                                   default = nil)
  if valid_21626495 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626495
  var valid_21626496 = header.getOrDefault("X-Amz-Credential")
  valid_21626496 = validateParameter(valid_21626496, JString, required = false,
                                   default = nil)
  if valid_21626496 != nil:
    section.add "X-Amz-Credential", valid_21626496
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

proc call*(call_21626498: Call_DescribeDocument_21626486; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Describes the specified Systems Manager document.
  ## 
  let valid = call_21626498.validator(path, query, header, formData, body, _)
  let scheme = call_21626498.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626498.makeUrl(scheme.get, call_21626498.host, call_21626498.base,
                               call_21626498.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626498, uri, valid, _)

proc call*(call_21626499: Call_DescribeDocument_21626486; body: JsonNode): Recallable =
  ## describeDocument
  ## Describes the specified Systems Manager document.
  ##   body: JObject (required)
  var body_21626500 = newJObject()
  if body != nil:
    body_21626500 = body
  result = call_21626499.call(nil, nil, nil, nil, body_21626500)

var describeDocument* = Call_DescribeDocument_21626486(name: "describeDocument",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeDocument",
    validator: validate_DescribeDocument_21626487, base: "/",
    makeUrl: url_DescribeDocument_21626488, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDocumentPermission_21626501 = ref object of OpenApiRestCall_21625435
proc url_DescribeDocumentPermission_21626503(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeDocumentPermission_21626502(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626504 = header.getOrDefault("X-Amz-Date")
  valid_21626504 = validateParameter(valid_21626504, JString, required = false,
                                   default = nil)
  if valid_21626504 != nil:
    section.add "X-Amz-Date", valid_21626504
  var valid_21626505 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626505 = validateParameter(valid_21626505, JString, required = false,
                                   default = nil)
  if valid_21626505 != nil:
    section.add "X-Amz-Security-Token", valid_21626505
  var valid_21626506 = header.getOrDefault("X-Amz-Target")
  valid_21626506 = validateParameter(valid_21626506, JString, required = true, default = newJString(
      "AmazonSSM.DescribeDocumentPermission"))
  if valid_21626506 != nil:
    section.add "X-Amz-Target", valid_21626506
  var valid_21626507 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626507 = validateParameter(valid_21626507, JString, required = false,
                                   default = nil)
  if valid_21626507 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626507
  var valid_21626508 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626508 = validateParameter(valid_21626508, JString, required = false,
                                   default = nil)
  if valid_21626508 != nil:
    section.add "X-Amz-Algorithm", valid_21626508
  var valid_21626509 = header.getOrDefault("X-Amz-Signature")
  valid_21626509 = validateParameter(valid_21626509, JString, required = false,
                                   default = nil)
  if valid_21626509 != nil:
    section.add "X-Amz-Signature", valid_21626509
  var valid_21626510 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626510 = validateParameter(valid_21626510, JString, required = false,
                                   default = nil)
  if valid_21626510 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626510
  var valid_21626511 = header.getOrDefault("X-Amz-Credential")
  valid_21626511 = validateParameter(valid_21626511, JString, required = false,
                                   default = nil)
  if valid_21626511 != nil:
    section.add "X-Amz-Credential", valid_21626511
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

proc call*(call_21626513: Call_DescribeDocumentPermission_21626501;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Describes the permissions for a Systems Manager document. If you created the document, you are the owner. If a document is shared, it can either be shared privately (by specifying a user's AWS account ID) or publicly (<i>All</i>). 
  ## 
  let valid = call_21626513.validator(path, query, header, formData, body, _)
  let scheme = call_21626513.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626513.makeUrl(scheme.get, call_21626513.host, call_21626513.base,
                               call_21626513.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626513, uri, valid, _)

proc call*(call_21626514: Call_DescribeDocumentPermission_21626501; body: JsonNode): Recallable =
  ## describeDocumentPermission
  ## Describes the permissions for a Systems Manager document. If you created the document, you are the owner. If a document is shared, it can either be shared privately (by specifying a user's AWS account ID) or publicly (<i>All</i>). 
  ##   body: JObject (required)
  var body_21626515 = newJObject()
  if body != nil:
    body_21626515 = body
  result = call_21626514.call(nil, nil, nil, nil, body_21626515)

var describeDocumentPermission* = Call_DescribeDocumentPermission_21626501(
    name: "describeDocumentPermission", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeDocumentPermission",
    validator: validate_DescribeDocumentPermission_21626502, base: "/",
    makeUrl: url_DescribeDocumentPermission_21626503,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEffectiveInstanceAssociations_21626516 = ref object of OpenApiRestCall_21625435
proc url_DescribeEffectiveInstanceAssociations_21626518(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeEffectiveInstanceAssociations_21626517(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626519 = header.getOrDefault("X-Amz-Date")
  valid_21626519 = validateParameter(valid_21626519, JString, required = false,
                                   default = nil)
  if valid_21626519 != nil:
    section.add "X-Amz-Date", valid_21626519
  var valid_21626520 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626520 = validateParameter(valid_21626520, JString, required = false,
                                   default = nil)
  if valid_21626520 != nil:
    section.add "X-Amz-Security-Token", valid_21626520
  var valid_21626521 = header.getOrDefault("X-Amz-Target")
  valid_21626521 = validateParameter(valid_21626521, JString, required = true, default = newJString(
      "AmazonSSM.DescribeEffectiveInstanceAssociations"))
  if valid_21626521 != nil:
    section.add "X-Amz-Target", valid_21626521
  var valid_21626522 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626522 = validateParameter(valid_21626522, JString, required = false,
                                   default = nil)
  if valid_21626522 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626522
  var valid_21626523 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626523 = validateParameter(valid_21626523, JString, required = false,
                                   default = nil)
  if valid_21626523 != nil:
    section.add "X-Amz-Algorithm", valid_21626523
  var valid_21626524 = header.getOrDefault("X-Amz-Signature")
  valid_21626524 = validateParameter(valid_21626524, JString, required = false,
                                   default = nil)
  if valid_21626524 != nil:
    section.add "X-Amz-Signature", valid_21626524
  var valid_21626525 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626525 = validateParameter(valid_21626525, JString, required = false,
                                   default = nil)
  if valid_21626525 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626525
  var valid_21626526 = header.getOrDefault("X-Amz-Credential")
  valid_21626526 = validateParameter(valid_21626526, JString, required = false,
                                   default = nil)
  if valid_21626526 != nil:
    section.add "X-Amz-Credential", valid_21626526
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

proc call*(call_21626528: Call_DescribeEffectiveInstanceAssociations_21626516;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## All associations for the instance(s).
  ## 
  let valid = call_21626528.validator(path, query, header, formData, body, _)
  let scheme = call_21626528.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626528.makeUrl(scheme.get, call_21626528.host, call_21626528.base,
                               call_21626528.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626528, uri, valid, _)

proc call*(call_21626529: Call_DescribeEffectiveInstanceAssociations_21626516;
          body: JsonNode): Recallable =
  ## describeEffectiveInstanceAssociations
  ## All associations for the instance(s).
  ##   body: JObject (required)
  var body_21626530 = newJObject()
  if body != nil:
    body_21626530 = body
  result = call_21626529.call(nil, nil, nil, nil, body_21626530)

var describeEffectiveInstanceAssociations* = Call_DescribeEffectiveInstanceAssociations_21626516(
    name: "describeEffectiveInstanceAssociations", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeEffectiveInstanceAssociations",
    validator: validate_DescribeEffectiveInstanceAssociations_21626517, base: "/",
    makeUrl: url_DescribeEffectiveInstanceAssociations_21626518,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEffectivePatchesForPatchBaseline_21626531 = ref object of OpenApiRestCall_21625435
proc url_DescribeEffectivePatchesForPatchBaseline_21626533(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeEffectivePatchesForPatchBaseline_21626532(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626534 = header.getOrDefault("X-Amz-Date")
  valid_21626534 = validateParameter(valid_21626534, JString, required = false,
                                   default = nil)
  if valid_21626534 != nil:
    section.add "X-Amz-Date", valid_21626534
  var valid_21626535 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626535 = validateParameter(valid_21626535, JString, required = false,
                                   default = nil)
  if valid_21626535 != nil:
    section.add "X-Amz-Security-Token", valid_21626535
  var valid_21626536 = header.getOrDefault("X-Amz-Target")
  valid_21626536 = validateParameter(valid_21626536, JString, required = true, default = newJString(
      "AmazonSSM.DescribeEffectivePatchesForPatchBaseline"))
  if valid_21626536 != nil:
    section.add "X-Amz-Target", valid_21626536
  var valid_21626537 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626537 = validateParameter(valid_21626537, JString, required = false,
                                   default = nil)
  if valid_21626537 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626537
  var valid_21626538 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626538 = validateParameter(valid_21626538, JString, required = false,
                                   default = nil)
  if valid_21626538 != nil:
    section.add "X-Amz-Algorithm", valid_21626538
  var valid_21626539 = header.getOrDefault("X-Amz-Signature")
  valid_21626539 = validateParameter(valid_21626539, JString, required = false,
                                   default = nil)
  if valid_21626539 != nil:
    section.add "X-Amz-Signature", valid_21626539
  var valid_21626540 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626540 = validateParameter(valid_21626540, JString, required = false,
                                   default = nil)
  if valid_21626540 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626540
  var valid_21626541 = header.getOrDefault("X-Amz-Credential")
  valid_21626541 = validateParameter(valid_21626541, JString, required = false,
                                   default = nil)
  if valid_21626541 != nil:
    section.add "X-Amz-Credential", valid_21626541
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

proc call*(call_21626543: Call_DescribeEffectivePatchesForPatchBaseline_21626531;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves the current effective patches (the patch and the approval state) for the specified patch baseline. Note that this API applies only to Windows patch baselines.
  ## 
  let valid = call_21626543.validator(path, query, header, formData, body, _)
  let scheme = call_21626543.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626543.makeUrl(scheme.get, call_21626543.host, call_21626543.base,
                               call_21626543.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626543, uri, valid, _)

proc call*(call_21626544: Call_DescribeEffectivePatchesForPatchBaseline_21626531;
          body: JsonNode): Recallable =
  ## describeEffectivePatchesForPatchBaseline
  ## Retrieves the current effective patches (the patch and the approval state) for the specified patch baseline. Note that this API applies only to Windows patch baselines.
  ##   body: JObject (required)
  var body_21626545 = newJObject()
  if body != nil:
    body_21626545 = body
  result = call_21626544.call(nil, nil, nil, nil, body_21626545)

var describeEffectivePatchesForPatchBaseline* = Call_DescribeEffectivePatchesForPatchBaseline_21626531(
    name: "describeEffectivePatchesForPatchBaseline", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeEffectivePatchesForPatchBaseline",
    validator: validate_DescribeEffectivePatchesForPatchBaseline_21626532,
    base: "/", makeUrl: url_DescribeEffectivePatchesForPatchBaseline_21626533,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeInstanceAssociationsStatus_21626546 = ref object of OpenApiRestCall_21625435
proc url_DescribeInstanceAssociationsStatus_21626548(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeInstanceAssociationsStatus_21626547(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626549 = header.getOrDefault("X-Amz-Date")
  valid_21626549 = validateParameter(valid_21626549, JString, required = false,
                                   default = nil)
  if valid_21626549 != nil:
    section.add "X-Amz-Date", valid_21626549
  var valid_21626550 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626550 = validateParameter(valid_21626550, JString, required = false,
                                   default = nil)
  if valid_21626550 != nil:
    section.add "X-Amz-Security-Token", valid_21626550
  var valid_21626551 = header.getOrDefault("X-Amz-Target")
  valid_21626551 = validateParameter(valid_21626551, JString, required = true, default = newJString(
      "AmazonSSM.DescribeInstanceAssociationsStatus"))
  if valid_21626551 != nil:
    section.add "X-Amz-Target", valid_21626551
  var valid_21626552 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626552 = validateParameter(valid_21626552, JString, required = false,
                                   default = nil)
  if valid_21626552 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626552
  var valid_21626553 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626553 = validateParameter(valid_21626553, JString, required = false,
                                   default = nil)
  if valid_21626553 != nil:
    section.add "X-Amz-Algorithm", valid_21626553
  var valid_21626554 = header.getOrDefault("X-Amz-Signature")
  valid_21626554 = validateParameter(valid_21626554, JString, required = false,
                                   default = nil)
  if valid_21626554 != nil:
    section.add "X-Amz-Signature", valid_21626554
  var valid_21626555 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626555 = validateParameter(valid_21626555, JString, required = false,
                                   default = nil)
  if valid_21626555 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626555
  var valid_21626556 = header.getOrDefault("X-Amz-Credential")
  valid_21626556 = validateParameter(valid_21626556, JString, required = false,
                                   default = nil)
  if valid_21626556 != nil:
    section.add "X-Amz-Credential", valid_21626556
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

proc call*(call_21626558: Call_DescribeInstanceAssociationsStatus_21626546;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## The status of the associations for the instance(s).
  ## 
  let valid = call_21626558.validator(path, query, header, formData, body, _)
  let scheme = call_21626558.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626558.makeUrl(scheme.get, call_21626558.host, call_21626558.base,
                               call_21626558.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626558, uri, valid, _)

proc call*(call_21626559: Call_DescribeInstanceAssociationsStatus_21626546;
          body: JsonNode): Recallable =
  ## describeInstanceAssociationsStatus
  ## The status of the associations for the instance(s).
  ##   body: JObject (required)
  var body_21626560 = newJObject()
  if body != nil:
    body_21626560 = body
  result = call_21626559.call(nil, nil, nil, nil, body_21626560)

var describeInstanceAssociationsStatus* = Call_DescribeInstanceAssociationsStatus_21626546(
    name: "describeInstanceAssociationsStatus", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeInstanceAssociationsStatus",
    validator: validate_DescribeInstanceAssociationsStatus_21626547, base: "/",
    makeUrl: url_DescribeInstanceAssociationsStatus_21626548,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeInstanceInformation_21626561 = ref object of OpenApiRestCall_21625435
proc url_DescribeInstanceInformation_21626563(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeInstanceInformation_21626562(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626564 = query.getOrDefault("NextToken")
  valid_21626564 = validateParameter(valid_21626564, JString, required = false,
                                   default = nil)
  if valid_21626564 != nil:
    section.add "NextToken", valid_21626564
  var valid_21626565 = query.getOrDefault("MaxResults")
  valid_21626565 = validateParameter(valid_21626565, JString, required = false,
                                   default = nil)
  if valid_21626565 != nil:
    section.add "MaxResults", valid_21626565
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626566 = header.getOrDefault("X-Amz-Date")
  valid_21626566 = validateParameter(valid_21626566, JString, required = false,
                                   default = nil)
  if valid_21626566 != nil:
    section.add "X-Amz-Date", valid_21626566
  var valid_21626567 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626567 = validateParameter(valid_21626567, JString, required = false,
                                   default = nil)
  if valid_21626567 != nil:
    section.add "X-Amz-Security-Token", valid_21626567
  var valid_21626568 = header.getOrDefault("X-Amz-Target")
  valid_21626568 = validateParameter(valid_21626568, JString, required = true, default = newJString(
      "AmazonSSM.DescribeInstanceInformation"))
  if valid_21626568 != nil:
    section.add "X-Amz-Target", valid_21626568
  var valid_21626569 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626569 = validateParameter(valid_21626569, JString, required = false,
                                   default = nil)
  if valid_21626569 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626569
  var valid_21626570 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626570 = validateParameter(valid_21626570, JString, required = false,
                                   default = nil)
  if valid_21626570 != nil:
    section.add "X-Amz-Algorithm", valid_21626570
  var valid_21626571 = header.getOrDefault("X-Amz-Signature")
  valid_21626571 = validateParameter(valid_21626571, JString, required = false,
                                   default = nil)
  if valid_21626571 != nil:
    section.add "X-Amz-Signature", valid_21626571
  var valid_21626572 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626572 = validateParameter(valid_21626572, JString, required = false,
                                   default = nil)
  if valid_21626572 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626572
  var valid_21626573 = header.getOrDefault("X-Amz-Credential")
  valid_21626573 = validateParameter(valid_21626573, JString, required = false,
                                   default = nil)
  if valid_21626573 != nil:
    section.add "X-Amz-Credential", valid_21626573
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

proc call*(call_21626575: Call_DescribeInstanceInformation_21626561;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Describes one or more of your instances. You can use this to get information about instances like the operating system platform, the SSM Agent version (Linux), status etc. If you specify one or more instance IDs, it returns information for those instances. If you do not specify instance IDs, it returns information for all your instances. If you specify an instance ID that is not valid or an instance that you do not own, you receive an error. </p> <note> <p>The IamRole field for this API action is the Amazon Identity and Access Management (IAM) role assigned to on-premises instances. This call does not return the IAM role for Amazon EC2 instances.</p> </note>
  ## 
  let valid = call_21626575.validator(path, query, header, formData, body, _)
  let scheme = call_21626575.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626575.makeUrl(scheme.get, call_21626575.host, call_21626575.base,
                               call_21626575.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626575, uri, valid, _)

proc call*(call_21626576: Call_DescribeInstanceInformation_21626561;
          body: JsonNode; NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## describeInstanceInformation
  ## <p>Describes one or more of your instances. You can use this to get information about instances like the operating system platform, the SSM Agent version (Linux), status etc. If you specify one or more instance IDs, it returns information for those instances. If you do not specify instance IDs, it returns information for all your instances. If you specify an instance ID that is not valid or an instance that you do not own, you receive an error. </p> <note> <p>The IamRole field for this API action is the Amazon Identity and Access Management (IAM) role assigned to on-premises instances. This call does not return the IAM role for Amazon EC2 instances.</p> </note>
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_21626577 = newJObject()
  var body_21626578 = newJObject()
  add(query_21626577, "NextToken", newJString(NextToken))
  if body != nil:
    body_21626578 = body
  add(query_21626577, "MaxResults", newJString(MaxResults))
  result = call_21626576.call(nil, query_21626577, nil, nil, body_21626578)

var describeInstanceInformation* = Call_DescribeInstanceInformation_21626561(
    name: "describeInstanceInformation", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeInstanceInformation",
    validator: validate_DescribeInstanceInformation_21626562, base: "/",
    makeUrl: url_DescribeInstanceInformation_21626563,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeInstancePatchStates_21626579 = ref object of OpenApiRestCall_21625435
proc url_DescribeInstancePatchStates_21626581(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeInstancePatchStates_21626580(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626582 = header.getOrDefault("X-Amz-Date")
  valid_21626582 = validateParameter(valid_21626582, JString, required = false,
                                   default = nil)
  if valid_21626582 != nil:
    section.add "X-Amz-Date", valid_21626582
  var valid_21626583 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626583 = validateParameter(valid_21626583, JString, required = false,
                                   default = nil)
  if valid_21626583 != nil:
    section.add "X-Amz-Security-Token", valid_21626583
  var valid_21626584 = header.getOrDefault("X-Amz-Target")
  valid_21626584 = validateParameter(valid_21626584, JString, required = true, default = newJString(
      "AmazonSSM.DescribeInstancePatchStates"))
  if valid_21626584 != nil:
    section.add "X-Amz-Target", valid_21626584
  var valid_21626585 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626585 = validateParameter(valid_21626585, JString, required = false,
                                   default = nil)
  if valid_21626585 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626585
  var valid_21626586 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626586 = validateParameter(valid_21626586, JString, required = false,
                                   default = nil)
  if valid_21626586 != nil:
    section.add "X-Amz-Algorithm", valid_21626586
  var valid_21626587 = header.getOrDefault("X-Amz-Signature")
  valid_21626587 = validateParameter(valid_21626587, JString, required = false,
                                   default = nil)
  if valid_21626587 != nil:
    section.add "X-Amz-Signature", valid_21626587
  var valid_21626588 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626588 = validateParameter(valid_21626588, JString, required = false,
                                   default = nil)
  if valid_21626588 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626588
  var valid_21626589 = header.getOrDefault("X-Amz-Credential")
  valid_21626589 = validateParameter(valid_21626589, JString, required = false,
                                   default = nil)
  if valid_21626589 != nil:
    section.add "X-Amz-Credential", valid_21626589
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

proc call*(call_21626591: Call_DescribeInstancePatchStates_21626579;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves the high-level patch state of one or more instances.
  ## 
  let valid = call_21626591.validator(path, query, header, formData, body, _)
  let scheme = call_21626591.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626591.makeUrl(scheme.get, call_21626591.host, call_21626591.base,
                               call_21626591.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626591, uri, valid, _)

proc call*(call_21626592: Call_DescribeInstancePatchStates_21626579; body: JsonNode): Recallable =
  ## describeInstancePatchStates
  ## Retrieves the high-level patch state of one or more instances.
  ##   body: JObject (required)
  var body_21626593 = newJObject()
  if body != nil:
    body_21626593 = body
  result = call_21626592.call(nil, nil, nil, nil, body_21626593)

var describeInstancePatchStates* = Call_DescribeInstancePatchStates_21626579(
    name: "describeInstancePatchStates", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeInstancePatchStates",
    validator: validate_DescribeInstancePatchStates_21626580, base: "/",
    makeUrl: url_DescribeInstancePatchStates_21626581,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeInstancePatchStatesForPatchGroup_21626594 = ref object of OpenApiRestCall_21625435
proc url_DescribeInstancePatchStatesForPatchGroup_21626596(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeInstancePatchStatesForPatchGroup_21626595(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626597 = header.getOrDefault("X-Amz-Date")
  valid_21626597 = validateParameter(valid_21626597, JString, required = false,
                                   default = nil)
  if valid_21626597 != nil:
    section.add "X-Amz-Date", valid_21626597
  var valid_21626598 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626598 = validateParameter(valid_21626598, JString, required = false,
                                   default = nil)
  if valid_21626598 != nil:
    section.add "X-Amz-Security-Token", valid_21626598
  var valid_21626599 = header.getOrDefault("X-Amz-Target")
  valid_21626599 = validateParameter(valid_21626599, JString, required = true, default = newJString(
      "AmazonSSM.DescribeInstancePatchStatesForPatchGroup"))
  if valid_21626599 != nil:
    section.add "X-Amz-Target", valid_21626599
  var valid_21626600 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626600 = validateParameter(valid_21626600, JString, required = false,
                                   default = nil)
  if valid_21626600 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626600
  var valid_21626601 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626601 = validateParameter(valid_21626601, JString, required = false,
                                   default = nil)
  if valid_21626601 != nil:
    section.add "X-Amz-Algorithm", valid_21626601
  var valid_21626602 = header.getOrDefault("X-Amz-Signature")
  valid_21626602 = validateParameter(valid_21626602, JString, required = false,
                                   default = nil)
  if valid_21626602 != nil:
    section.add "X-Amz-Signature", valid_21626602
  var valid_21626603 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626603 = validateParameter(valid_21626603, JString, required = false,
                                   default = nil)
  if valid_21626603 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626603
  var valid_21626604 = header.getOrDefault("X-Amz-Credential")
  valid_21626604 = validateParameter(valid_21626604, JString, required = false,
                                   default = nil)
  if valid_21626604 != nil:
    section.add "X-Amz-Credential", valid_21626604
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

proc call*(call_21626606: Call_DescribeInstancePatchStatesForPatchGroup_21626594;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves the high-level patch state for the instances in the specified patch group.
  ## 
  let valid = call_21626606.validator(path, query, header, formData, body, _)
  let scheme = call_21626606.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626606.makeUrl(scheme.get, call_21626606.host, call_21626606.base,
                               call_21626606.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626606, uri, valid, _)

proc call*(call_21626607: Call_DescribeInstancePatchStatesForPatchGroup_21626594;
          body: JsonNode): Recallable =
  ## describeInstancePatchStatesForPatchGroup
  ## Retrieves the high-level patch state for the instances in the specified patch group.
  ##   body: JObject (required)
  var body_21626608 = newJObject()
  if body != nil:
    body_21626608 = body
  result = call_21626607.call(nil, nil, nil, nil, body_21626608)

var describeInstancePatchStatesForPatchGroup* = Call_DescribeInstancePatchStatesForPatchGroup_21626594(
    name: "describeInstancePatchStatesForPatchGroup", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeInstancePatchStatesForPatchGroup",
    validator: validate_DescribeInstancePatchStatesForPatchGroup_21626595,
    base: "/", makeUrl: url_DescribeInstancePatchStatesForPatchGroup_21626596,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeInstancePatches_21626609 = ref object of OpenApiRestCall_21625435
proc url_DescribeInstancePatches_21626611(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeInstancePatches_21626610(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626612 = header.getOrDefault("X-Amz-Date")
  valid_21626612 = validateParameter(valid_21626612, JString, required = false,
                                   default = nil)
  if valid_21626612 != nil:
    section.add "X-Amz-Date", valid_21626612
  var valid_21626613 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626613 = validateParameter(valid_21626613, JString, required = false,
                                   default = nil)
  if valid_21626613 != nil:
    section.add "X-Amz-Security-Token", valid_21626613
  var valid_21626614 = header.getOrDefault("X-Amz-Target")
  valid_21626614 = validateParameter(valid_21626614, JString, required = true, default = newJString(
      "AmazonSSM.DescribeInstancePatches"))
  if valid_21626614 != nil:
    section.add "X-Amz-Target", valid_21626614
  var valid_21626615 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626615 = validateParameter(valid_21626615, JString, required = false,
                                   default = nil)
  if valid_21626615 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626615
  var valid_21626616 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626616 = validateParameter(valid_21626616, JString, required = false,
                                   default = nil)
  if valid_21626616 != nil:
    section.add "X-Amz-Algorithm", valid_21626616
  var valid_21626617 = header.getOrDefault("X-Amz-Signature")
  valid_21626617 = validateParameter(valid_21626617, JString, required = false,
                                   default = nil)
  if valid_21626617 != nil:
    section.add "X-Amz-Signature", valid_21626617
  var valid_21626618 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626618 = validateParameter(valid_21626618, JString, required = false,
                                   default = nil)
  if valid_21626618 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626618
  var valid_21626619 = header.getOrDefault("X-Amz-Credential")
  valid_21626619 = validateParameter(valid_21626619, JString, required = false,
                                   default = nil)
  if valid_21626619 != nil:
    section.add "X-Amz-Credential", valid_21626619
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

proc call*(call_21626621: Call_DescribeInstancePatches_21626609;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves information about the patches on the specified instance and their state relative to the patch baseline being used for the instance.
  ## 
  let valid = call_21626621.validator(path, query, header, formData, body, _)
  let scheme = call_21626621.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626621.makeUrl(scheme.get, call_21626621.host, call_21626621.base,
                               call_21626621.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626621, uri, valid, _)

proc call*(call_21626622: Call_DescribeInstancePatches_21626609; body: JsonNode): Recallable =
  ## describeInstancePatches
  ## Retrieves information about the patches on the specified instance and their state relative to the patch baseline being used for the instance.
  ##   body: JObject (required)
  var body_21626623 = newJObject()
  if body != nil:
    body_21626623 = body
  result = call_21626622.call(nil, nil, nil, nil, body_21626623)

var describeInstancePatches* = Call_DescribeInstancePatches_21626609(
    name: "describeInstancePatches", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeInstancePatches",
    validator: validate_DescribeInstancePatches_21626610, base: "/",
    makeUrl: url_DescribeInstancePatches_21626611,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeInventoryDeletions_21626624 = ref object of OpenApiRestCall_21625435
proc url_DescribeInventoryDeletions_21626626(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeInventoryDeletions_21626625(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626627 = header.getOrDefault("X-Amz-Date")
  valid_21626627 = validateParameter(valid_21626627, JString, required = false,
                                   default = nil)
  if valid_21626627 != nil:
    section.add "X-Amz-Date", valid_21626627
  var valid_21626628 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626628 = validateParameter(valid_21626628, JString, required = false,
                                   default = nil)
  if valid_21626628 != nil:
    section.add "X-Amz-Security-Token", valid_21626628
  var valid_21626629 = header.getOrDefault("X-Amz-Target")
  valid_21626629 = validateParameter(valid_21626629, JString, required = true, default = newJString(
      "AmazonSSM.DescribeInventoryDeletions"))
  if valid_21626629 != nil:
    section.add "X-Amz-Target", valid_21626629
  var valid_21626630 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626630 = validateParameter(valid_21626630, JString, required = false,
                                   default = nil)
  if valid_21626630 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626630
  var valid_21626631 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626631 = validateParameter(valid_21626631, JString, required = false,
                                   default = nil)
  if valid_21626631 != nil:
    section.add "X-Amz-Algorithm", valid_21626631
  var valid_21626632 = header.getOrDefault("X-Amz-Signature")
  valid_21626632 = validateParameter(valid_21626632, JString, required = false,
                                   default = nil)
  if valid_21626632 != nil:
    section.add "X-Amz-Signature", valid_21626632
  var valid_21626633 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626633 = validateParameter(valid_21626633, JString, required = false,
                                   default = nil)
  if valid_21626633 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626633
  var valid_21626634 = header.getOrDefault("X-Amz-Credential")
  valid_21626634 = validateParameter(valid_21626634, JString, required = false,
                                   default = nil)
  if valid_21626634 != nil:
    section.add "X-Amz-Credential", valid_21626634
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

proc call*(call_21626636: Call_DescribeInventoryDeletions_21626624;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Describes a specific delete inventory operation.
  ## 
  let valid = call_21626636.validator(path, query, header, formData, body, _)
  let scheme = call_21626636.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626636.makeUrl(scheme.get, call_21626636.host, call_21626636.base,
                               call_21626636.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626636, uri, valid, _)

proc call*(call_21626637: Call_DescribeInventoryDeletions_21626624; body: JsonNode): Recallable =
  ## describeInventoryDeletions
  ## Describes a specific delete inventory operation.
  ##   body: JObject (required)
  var body_21626638 = newJObject()
  if body != nil:
    body_21626638 = body
  result = call_21626637.call(nil, nil, nil, nil, body_21626638)

var describeInventoryDeletions* = Call_DescribeInventoryDeletions_21626624(
    name: "describeInventoryDeletions", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeInventoryDeletions",
    validator: validate_DescribeInventoryDeletions_21626625, base: "/",
    makeUrl: url_DescribeInventoryDeletions_21626626,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeMaintenanceWindowExecutionTaskInvocations_21626639 = ref object of OpenApiRestCall_21625435
proc url_DescribeMaintenanceWindowExecutionTaskInvocations_21626641(
    protocol: Scheme; host: string; base: string; route: string; path: JsonNode;
    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeMaintenanceWindowExecutionTaskInvocations_21626640(
    path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626642 = header.getOrDefault("X-Amz-Date")
  valid_21626642 = validateParameter(valid_21626642, JString, required = false,
                                   default = nil)
  if valid_21626642 != nil:
    section.add "X-Amz-Date", valid_21626642
  var valid_21626643 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626643 = validateParameter(valid_21626643, JString, required = false,
                                   default = nil)
  if valid_21626643 != nil:
    section.add "X-Amz-Security-Token", valid_21626643
  var valid_21626644 = header.getOrDefault("X-Amz-Target")
  valid_21626644 = validateParameter(valid_21626644, JString, required = true, default = newJString(
      "AmazonSSM.DescribeMaintenanceWindowExecutionTaskInvocations"))
  if valid_21626644 != nil:
    section.add "X-Amz-Target", valid_21626644
  var valid_21626645 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626645 = validateParameter(valid_21626645, JString, required = false,
                                   default = nil)
  if valid_21626645 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626645
  var valid_21626646 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626646 = validateParameter(valid_21626646, JString, required = false,
                                   default = nil)
  if valid_21626646 != nil:
    section.add "X-Amz-Algorithm", valid_21626646
  var valid_21626647 = header.getOrDefault("X-Amz-Signature")
  valid_21626647 = validateParameter(valid_21626647, JString, required = false,
                                   default = nil)
  if valid_21626647 != nil:
    section.add "X-Amz-Signature", valid_21626647
  var valid_21626648 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626648 = validateParameter(valid_21626648, JString, required = false,
                                   default = nil)
  if valid_21626648 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626648
  var valid_21626649 = header.getOrDefault("X-Amz-Credential")
  valid_21626649 = validateParameter(valid_21626649, JString, required = false,
                                   default = nil)
  if valid_21626649 != nil:
    section.add "X-Amz-Credential", valid_21626649
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

proc call*(call_21626651: Call_DescribeMaintenanceWindowExecutionTaskInvocations_21626639;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves the individual task executions (one per target) for a particular task run as part of a maintenance window execution.
  ## 
  let valid = call_21626651.validator(path, query, header, formData, body, _)
  let scheme = call_21626651.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626651.makeUrl(scheme.get, call_21626651.host, call_21626651.base,
                               call_21626651.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626651, uri, valid, _)

proc call*(call_21626652: Call_DescribeMaintenanceWindowExecutionTaskInvocations_21626639;
          body: JsonNode): Recallable =
  ## describeMaintenanceWindowExecutionTaskInvocations
  ## Retrieves the individual task executions (one per target) for a particular task run as part of a maintenance window execution.
  ##   body: JObject (required)
  var body_21626653 = newJObject()
  if body != nil:
    body_21626653 = body
  result = call_21626652.call(nil, nil, nil, nil, body_21626653)

var describeMaintenanceWindowExecutionTaskInvocations* = Call_DescribeMaintenanceWindowExecutionTaskInvocations_21626639(
    name: "describeMaintenanceWindowExecutionTaskInvocations",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com", route: "/#X-Amz-Target=AmazonSSM.DescribeMaintenanceWindowExecutionTaskInvocations",
    validator: validate_DescribeMaintenanceWindowExecutionTaskInvocations_21626640,
    base: "/", makeUrl: url_DescribeMaintenanceWindowExecutionTaskInvocations_21626641,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeMaintenanceWindowExecutionTasks_21626654 = ref object of OpenApiRestCall_21625435
proc url_DescribeMaintenanceWindowExecutionTasks_21626656(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeMaintenanceWindowExecutionTasks_21626655(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626657 = header.getOrDefault("X-Amz-Date")
  valid_21626657 = validateParameter(valid_21626657, JString, required = false,
                                   default = nil)
  if valid_21626657 != nil:
    section.add "X-Amz-Date", valid_21626657
  var valid_21626658 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626658 = validateParameter(valid_21626658, JString, required = false,
                                   default = nil)
  if valid_21626658 != nil:
    section.add "X-Amz-Security-Token", valid_21626658
  var valid_21626659 = header.getOrDefault("X-Amz-Target")
  valid_21626659 = validateParameter(valid_21626659, JString, required = true, default = newJString(
      "AmazonSSM.DescribeMaintenanceWindowExecutionTasks"))
  if valid_21626659 != nil:
    section.add "X-Amz-Target", valid_21626659
  var valid_21626660 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626660 = validateParameter(valid_21626660, JString, required = false,
                                   default = nil)
  if valid_21626660 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626660
  var valid_21626661 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626661 = validateParameter(valid_21626661, JString, required = false,
                                   default = nil)
  if valid_21626661 != nil:
    section.add "X-Amz-Algorithm", valid_21626661
  var valid_21626662 = header.getOrDefault("X-Amz-Signature")
  valid_21626662 = validateParameter(valid_21626662, JString, required = false,
                                   default = nil)
  if valid_21626662 != nil:
    section.add "X-Amz-Signature", valid_21626662
  var valid_21626663 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626663 = validateParameter(valid_21626663, JString, required = false,
                                   default = nil)
  if valid_21626663 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626663
  var valid_21626664 = header.getOrDefault("X-Amz-Credential")
  valid_21626664 = validateParameter(valid_21626664, JString, required = false,
                                   default = nil)
  if valid_21626664 != nil:
    section.add "X-Amz-Credential", valid_21626664
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

proc call*(call_21626666: Call_DescribeMaintenanceWindowExecutionTasks_21626654;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## For a given maintenance window execution, lists the tasks that were run.
  ## 
  let valid = call_21626666.validator(path, query, header, formData, body, _)
  let scheme = call_21626666.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626666.makeUrl(scheme.get, call_21626666.host, call_21626666.base,
                               call_21626666.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626666, uri, valid, _)

proc call*(call_21626667: Call_DescribeMaintenanceWindowExecutionTasks_21626654;
          body: JsonNode): Recallable =
  ## describeMaintenanceWindowExecutionTasks
  ## For a given maintenance window execution, lists the tasks that were run.
  ##   body: JObject (required)
  var body_21626668 = newJObject()
  if body != nil:
    body_21626668 = body
  result = call_21626667.call(nil, nil, nil, nil, body_21626668)

var describeMaintenanceWindowExecutionTasks* = Call_DescribeMaintenanceWindowExecutionTasks_21626654(
    name: "describeMaintenanceWindowExecutionTasks", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeMaintenanceWindowExecutionTasks",
    validator: validate_DescribeMaintenanceWindowExecutionTasks_21626655,
    base: "/", makeUrl: url_DescribeMaintenanceWindowExecutionTasks_21626656,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeMaintenanceWindowExecutions_21626669 = ref object of OpenApiRestCall_21625435
proc url_DescribeMaintenanceWindowExecutions_21626671(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeMaintenanceWindowExecutions_21626670(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626672 = header.getOrDefault("X-Amz-Date")
  valid_21626672 = validateParameter(valid_21626672, JString, required = false,
                                   default = nil)
  if valid_21626672 != nil:
    section.add "X-Amz-Date", valid_21626672
  var valid_21626673 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626673 = validateParameter(valid_21626673, JString, required = false,
                                   default = nil)
  if valid_21626673 != nil:
    section.add "X-Amz-Security-Token", valid_21626673
  var valid_21626674 = header.getOrDefault("X-Amz-Target")
  valid_21626674 = validateParameter(valid_21626674, JString, required = true, default = newJString(
      "AmazonSSM.DescribeMaintenanceWindowExecutions"))
  if valid_21626674 != nil:
    section.add "X-Amz-Target", valid_21626674
  var valid_21626675 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626675 = validateParameter(valid_21626675, JString, required = false,
                                   default = nil)
  if valid_21626675 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626675
  var valid_21626676 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626676 = validateParameter(valid_21626676, JString, required = false,
                                   default = nil)
  if valid_21626676 != nil:
    section.add "X-Amz-Algorithm", valid_21626676
  var valid_21626677 = header.getOrDefault("X-Amz-Signature")
  valid_21626677 = validateParameter(valid_21626677, JString, required = false,
                                   default = nil)
  if valid_21626677 != nil:
    section.add "X-Amz-Signature", valid_21626677
  var valid_21626678 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626678 = validateParameter(valid_21626678, JString, required = false,
                                   default = nil)
  if valid_21626678 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626678
  var valid_21626679 = header.getOrDefault("X-Amz-Credential")
  valid_21626679 = validateParameter(valid_21626679, JString, required = false,
                                   default = nil)
  if valid_21626679 != nil:
    section.add "X-Amz-Credential", valid_21626679
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

proc call*(call_21626681: Call_DescribeMaintenanceWindowExecutions_21626669;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the executions of a maintenance window. This includes information about when the maintenance window was scheduled to be active, and information about tasks registered and run with the maintenance window.
  ## 
  let valid = call_21626681.validator(path, query, header, formData, body, _)
  let scheme = call_21626681.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626681.makeUrl(scheme.get, call_21626681.host, call_21626681.base,
                               call_21626681.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626681, uri, valid, _)

proc call*(call_21626682: Call_DescribeMaintenanceWindowExecutions_21626669;
          body: JsonNode): Recallable =
  ## describeMaintenanceWindowExecutions
  ## Lists the executions of a maintenance window. This includes information about when the maintenance window was scheduled to be active, and information about tasks registered and run with the maintenance window.
  ##   body: JObject (required)
  var body_21626683 = newJObject()
  if body != nil:
    body_21626683 = body
  result = call_21626682.call(nil, nil, nil, nil, body_21626683)

var describeMaintenanceWindowExecutions* = Call_DescribeMaintenanceWindowExecutions_21626669(
    name: "describeMaintenanceWindowExecutions", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeMaintenanceWindowExecutions",
    validator: validate_DescribeMaintenanceWindowExecutions_21626670, base: "/",
    makeUrl: url_DescribeMaintenanceWindowExecutions_21626671,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeMaintenanceWindowSchedule_21626684 = ref object of OpenApiRestCall_21625435
proc url_DescribeMaintenanceWindowSchedule_21626686(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeMaintenanceWindowSchedule_21626685(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626687 = header.getOrDefault("X-Amz-Date")
  valid_21626687 = validateParameter(valid_21626687, JString, required = false,
                                   default = nil)
  if valid_21626687 != nil:
    section.add "X-Amz-Date", valid_21626687
  var valid_21626688 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626688 = validateParameter(valid_21626688, JString, required = false,
                                   default = nil)
  if valid_21626688 != nil:
    section.add "X-Amz-Security-Token", valid_21626688
  var valid_21626689 = header.getOrDefault("X-Amz-Target")
  valid_21626689 = validateParameter(valid_21626689, JString, required = true, default = newJString(
      "AmazonSSM.DescribeMaintenanceWindowSchedule"))
  if valid_21626689 != nil:
    section.add "X-Amz-Target", valid_21626689
  var valid_21626690 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626690 = validateParameter(valid_21626690, JString, required = false,
                                   default = nil)
  if valid_21626690 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626690
  var valid_21626691 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626691 = validateParameter(valid_21626691, JString, required = false,
                                   default = nil)
  if valid_21626691 != nil:
    section.add "X-Amz-Algorithm", valid_21626691
  var valid_21626692 = header.getOrDefault("X-Amz-Signature")
  valid_21626692 = validateParameter(valid_21626692, JString, required = false,
                                   default = nil)
  if valid_21626692 != nil:
    section.add "X-Amz-Signature", valid_21626692
  var valid_21626693 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626693 = validateParameter(valid_21626693, JString, required = false,
                                   default = nil)
  if valid_21626693 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626693
  var valid_21626694 = header.getOrDefault("X-Amz-Credential")
  valid_21626694 = validateParameter(valid_21626694, JString, required = false,
                                   default = nil)
  if valid_21626694 != nil:
    section.add "X-Amz-Credential", valid_21626694
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

proc call*(call_21626696: Call_DescribeMaintenanceWindowSchedule_21626684;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves information about upcoming executions of a maintenance window.
  ## 
  let valid = call_21626696.validator(path, query, header, formData, body, _)
  let scheme = call_21626696.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626696.makeUrl(scheme.get, call_21626696.host, call_21626696.base,
                               call_21626696.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626696, uri, valid, _)

proc call*(call_21626697: Call_DescribeMaintenanceWindowSchedule_21626684;
          body: JsonNode): Recallable =
  ## describeMaintenanceWindowSchedule
  ## Retrieves information about upcoming executions of a maintenance window.
  ##   body: JObject (required)
  var body_21626698 = newJObject()
  if body != nil:
    body_21626698 = body
  result = call_21626697.call(nil, nil, nil, nil, body_21626698)

var describeMaintenanceWindowSchedule* = Call_DescribeMaintenanceWindowSchedule_21626684(
    name: "describeMaintenanceWindowSchedule", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeMaintenanceWindowSchedule",
    validator: validate_DescribeMaintenanceWindowSchedule_21626685, base: "/",
    makeUrl: url_DescribeMaintenanceWindowSchedule_21626686,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeMaintenanceWindowTargets_21626699 = ref object of OpenApiRestCall_21625435
proc url_DescribeMaintenanceWindowTargets_21626701(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeMaintenanceWindowTargets_21626700(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626702 = header.getOrDefault("X-Amz-Date")
  valid_21626702 = validateParameter(valid_21626702, JString, required = false,
                                   default = nil)
  if valid_21626702 != nil:
    section.add "X-Amz-Date", valid_21626702
  var valid_21626703 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626703 = validateParameter(valid_21626703, JString, required = false,
                                   default = nil)
  if valid_21626703 != nil:
    section.add "X-Amz-Security-Token", valid_21626703
  var valid_21626704 = header.getOrDefault("X-Amz-Target")
  valid_21626704 = validateParameter(valid_21626704, JString, required = true, default = newJString(
      "AmazonSSM.DescribeMaintenanceWindowTargets"))
  if valid_21626704 != nil:
    section.add "X-Amz-Target", valid_21626704
  var valid_21626705 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626705 = validateParameter(valid_21626705, JString, required = false,
                                   default = nil)
  if valid_21626705 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626705
  var valid_21626706 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626706 = validateParameter(valid_21626706, JString, required = false,
                                   default = nil)
  if valid_21626706 != nil:
    section.add "X-Amz-Algorithm", valid_21626706
  var valid_21626707 = header.getOrDefault("X-Amz-Signature")
  valid_21626707 = validateParameter(valid_21626707, JString, required = false,
                                   default = nil)
  if valid_21626707 != nil:
    section.add "X-Amz-Signature", valid_21626707
  var valid_21626708 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626708 = validateParameter(valid_21626708, JString, required = false,
                                   default = nil)
  if valid_21626708 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626708
  var valid_21626709 = header.getOrDefault("X-Amz-Credential")
  valid_21626709 = validateParameter(valid_21626709, JString, required = false,
                                   default = nil)
  if valid_21626709 != nil:
    section.add "X-Amz-Credential", valid_21626709
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

proc call*(call_21626711: Call_DescribeMaintenanceWindowTargets_21626699;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the targets registered with the maintenance window.
  ## 
  let valid = call_21626711.validator(path, query, header, formData, body, _)
  let scheme = call_21626711.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626711.makeUrl(scheme.get, call_21626711.host, call_21626711.base,
                               call_21626711.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626711, uri, valid, _)

proc call*(call_21626712: Call_DescribeMaintenanceWindowTargets_21626699;
          body: JsonNode): Recallable =
  ## describeMaintenanceWindowTargets
  ## Lists the targets registered with the maintenance window.
  ##   body: JObject (required)
  var body_21626713 = newJObject()
  if body != nil:
    body_21626713 = body
  result = call_21626712.call(nil, nil, nil, nil, body_21626713)

var describeMaintenanceWindowTargets* = Call_DescribeMaintenanceWindowTargets_21626699(
    name: "describeMaintenanceWindowTargets", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeMaintenanceWindowTargets",
    validator: validate_DescribeMaintenanceWindowTargets_21626700, base: "/",
    makeUrl: url_DescribeMaintenanceWindowTargets_21626701,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeMaintenanceWindowTasks_21626714 = ref object of OpenApiRestCall_21625435
proc url_DescribeMaintenanceWindowTasks_21626716(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeMaintenanceWindowTasks_21626715(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626717 = header.getOrDefault("X-Amz-Date")
  valid_21626717 = validateParameter(valid_21626717, JString, required = false,
                                   default = nil)
  if valid_21626717 != nil:
    section.add "X-Amz-Date", valid_21626717
  var valid_21626718 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626718 = validateParameter(valid_21626718, JString, required = false,
                                   default = nil)
  if valid_21626718 != nil:
    section.add "X-Amz-Security-Token", valid_21626718
  var valid_21626719 = header.getOrDefault("X-Amz-Target")
  valid_21626719 = validateParameter(valid_21626719, JString, required = true, default = newJString(
      "AmazonSSM.DescribeMaintenanceWindowTasks"))
  if valid_21626719 != nil:
    section.add "X-Amz-Target", valid_21626719
  var valid_21626720 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626720 = validateParameter(valid_21626720, JString, required = false,
                                   default = nil)
  if valid_21626720 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626720
  var valid_21626721 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626721 = validateParameter(valid_21626721, JString, required = false,
                                   default = nil)
  if valid_21626721 != nil:
    section.add "X-Amz-Algorithm", valid_21626721
  var valid_21626722 = header.getOrDefault("X-Amz-Signature")
  valid_21626722 = validateParameter(valid_21626722, JString, required = false,
                                   default = nil)
  if valid_21626722 != nil:
    section.add "X-Amz-Signature", valid_21626722
  var valid_21626723 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626723 = validateParameter(valid_21626723, JString, required = false,
                                   default = nil)
  if valid_21626723 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626723
  var valid_21626724 = header.getOrDefault("X-Amz-Credential")
  valid_21626724 = validateParameter(valid_21626724, JString, required = false,
                                   default = nil)
  if valid_21626724 != nil:
    section.add "X-Amz-Credential", valid_21626724
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

proc call*(call_21626726: Call_DescribeMaintenanceWindowTasks_21626714;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the tasks in a maintenance window.
  ## 
  let valid = call_21626726.validator(path, query, header, formData, body, _)
  let scheme = call_21626726.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626726.makeUrl(scheme.get, call_21626726.host, call_21626726.base,
                               call_21626726.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626726, uri, valid, _)

proc call*(call_21626727: Call_DescribeMaintenanceWindowTasks_21626714;
          body: JsonNode): Recallable =
  ## describeMaintenanceWindowTasks
  ## Lists the tasks in a maintenance window.
  ##   body: JObject (required)
  var body_21626728 = newJObject()
  if body != nil:
    body_21626728 = body
  result = call_21626727.call(nil, nil, nil, nil, body_21626728)

var describeMaintenanceWindowTasks* = Call_DescribeMaintenanceWindowTasks_21626714(
    name: "describeMaintenanceWindowTasks", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeMaintenanceWindowTasks",
    validator: validate_DescribeMaintenanceWindowTasks_21626715, base: "/",
    makeUrl: url_DescribeMaintenanceWindowTasks_21626716,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeMaintenanceWindows_21626729 = ref object of OpenApiRestCall_21625435
proc url_DescribeMaintenanceWindows_21626731(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeMaintenanceWindows_21626730(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626732 = header.getOrDefault("X-Amz-Date")
  valid_21626732 = validateParameter(valid_21626732, JString, required = false,
                                   default = nil)
  if valid_21626732 != nil:
    section.add "X-Amz-Date", valid_21626732
  var valid_21626733 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626733 = validateParameter(valid_21626733, JString, required = false,
                                   default = nil)
  if valid_21626733 != nil:
    section.add "X-Amz-Security-Token", valid_21626733
  var valid_21626734 = header.getOrDefault("X-Amz-Target")
  valid_21626734 = validateParameter(valid_21626734, JString, required = true, default = newJString(
      "AmazonSSM.DescribeMaintenanceWindows"))
  if valid_21626734 != nil:
    section.add "X-Amz-Target", valid_21626734
  var valid_21626735 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626735 = validateParameter(valid_21626735, JString, required = false,
                                   default = nil)
  if valid_21626735 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626735
  var valid_21626736 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626736 = validateParameter(valid_21626736, JString, required = false,
                                   default = nil)
  if valid_21626736 != nil:
    section.add "X-Amz-Algorithm", valid_21626736
  var valid_21626737 = header.getOrDefault("X-Amz-Signature")
  valid_21626737 = validateParameter(valid_21626737, JString, required = false,
                                   default = nil)
  if valid_21626737 != nil:
    section.add "X-Amz-Signature", valid_21626737
  var valid_21626738 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626738 = validateParameter(valid_21626738, JString, required = false,
                                   default = nil)
  if valid_21626738 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626738
  var valid_21626739 = header.getOrDefault("X-Amz-Credential")
  valid_21626739 = validateParameter(valid_21626739, JString, required = false,
                                   default = nil)
  if valid_21626739 != nil:
    section.add "X-Amz-Credential", valid_21626739
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

proc call*(call_21626741: Call_DescribeMaintenanceWindows_21626729;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves the maintenance windows in an AWS account.
  ## 
  let valid = call_21626741.validator(path, query, header, formData, body, _)
  let scheme = call_21626741.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626741.makeUrl(scheme.get, call_21626741.host, call_21626741.base,
                               call_21626741.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626741, uri, valid, _)

proc call*(call_21626742: Call_DescribeMaintenanceWindows_21626729; body: JsonNode): Recallable =
  ## describeMaintenanceWindows
  ## Retrieves the maintenance windows in an AWS account.
  ##   body: JObject (required)
  var body_21626743 = newJObject()
  if body != nil:
    body_21626743 = body
  result = call_21626742.call(nil, nil, nil, nil, body_21626743)

var describeMaintenanceWindows* = Call_DescribeMaintenanceWindows_21626729(
    name: "describeMaintenanceWindows", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeMaintenanceWindows",
    validator: validate_DescribeMaintenanceWindows_21626730, base: "/",
    makeUrl: url_DescribeMaintenanceWindows_21626731,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeMaintenanceWindowsForTarget_21626744 = ref object of OpenApiRestCall_21625435
proc url_DescribeMaintenanceWindowsForTarget_21626746(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeMaintenanceWindowsForTarget_21626745(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626747 = header.getOrDefault("X-Amz-Date")
  valid_21626747 = validateParameter(valid_21626747, JString, required = false,
                                   default = nil)
  if valid_21626747 != nil:
    section.add "X-Amz-Date", valid_21626747
  var valid_21626748 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626748 = validateParameter(valid_21626748, JString, required = false,
                                   default = nil)
  if valid_21626748 != nil:
    section.add "X-Amz-Security-Token", valid_21626748
  var valid_21626749 = header.getOrDefault("X-Amz-Target")
  valid_21626749 = validateParameter(valid_21626749, JString, required = true, default = newJString(
      "AmazonSSM.DescribeMaintenanceWindowsForTarget"))
  if valid_21626749 != nil:
    section.add "X-Amz-Target", valid_21626749
  var valid_21626750 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626750 = validateParameter(valid_21626750, JString, required = false,
                                   default = nil)
  if valid_21626750 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626750
  var valid_21626751 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626751 = validateParameter(valid_21626751, JString, required = false,
                                   default = nil)
  if valid_21626751 != nil:
    section.add "X-Amz-Algorithm", valid_21626751
  var valid_21626752 = header.getOrDefault("X-Amz-Signature")
  valid_21626752 = validateParameter(valid_21626752, JString, required = false,
                                   default = nil)
  if valid_21626752 != nil:
    section.add "X-Amz-Signature", valid_21626752
  var valid_21626753 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626753 = validateParameter(valid_21626753, JString, required = false,
                                   default = nil)
  if valid_21626753 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626753
  var valid_21626754 = header.getOrDefault("X-Amz-Credential")
  valid_21626754 = validateParameter(valid_21626754, JString, required = false,
                                   default = nil)
  if valid_21626754 != nil:
    section.add "X-Amz-Credential", valid_21626754
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

proc call*(call_21626756: Call_DescribeMaintenanceWindowsForTarget_21626744;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves information about the maintenance window targets or tasks that an instance is associated with.
  ## 
  let valid = call_21626756.validator(path, query, header, formData, body, _)
  let scheme = call_21626756.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626756.makeUrl(scheme.get, call_21626756.host, call_21626756.base,
                               call_21626756.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626756, uri, valid, _)

proc call*(call_21626757: Call_DescribeMaintenanceWindowsForTarget_21626744;
          body: JsonNode): Recallable =
  ## describeMaintenanceWindowsForTarget
  ## Retrieves information about the maintenance window targets or tasks that an instance is associated with.
  ##   body: JObject (required)
  var body_21626758 = newJObject()
  if body != nil:
    body_21626758 = body
  result = call_21626757.call(nil, nil, nil, nil, body_21626758)

var describeMaintenanceWindowsForTarget* = Call_DescribeMaintenanceWindowsForTarget_21626744(
    name: "describeMaintenanceWindowsForTarget", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeMaintenanceWindowsForTarget",
    validator: validate_DescribeMaintenanceWindowsForTarget_21626745, base: "/",
    makeUrl: url_DescribeMaintenanceWindowsForTarget_21626746,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeOpsItems_21626759 = ref object of OpenApiRestCall_21625435
proc url_DescribeOpsItems_21626761(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeOpsItems_21626760(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626762 = header.getOrDefault("X-Amz-Date")
  valid_21626762 = validateParameter(valid_21626762, JString, required = false,
                                   default = nil)
  if valid_21626762 != nil:
    section.add "X-Amz-Date", valid_21626762
  var valid_21626763 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626763 = validateParameter(valid_21626763, JString, required = false,
                                   default = nil)
  if valid_21626763 != nil:
    section.add "X-Amz-Security-Token", valid_21626763
  var valid_21626764 = header.getOrDefault("X-Amz-Target")
  valid_21626764 = validateParameter(valid_21626764, JString, required = true, default = newJString(
      "AmazonSSM.DescribeOpsItems"))
  if valid_21626764 != nil:
    section.add "X-Amz-Target", valid_21626764
  var valid_21626765 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626765 = validateParameter(valid_21626765, JString, required = false,
                                   default = nil)
  if valid_21626765 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626765
  var valid_21626766 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626766 = validateParameter(valid_21626766, JString, required = false,
                                   default = nil)
  if valid_21626766 != nil:
    section.add "X-Amz-Algorithm", valid_21626766
  var valid_21626767 = header.getOrDefault("X-Amz-Signature")
  valid_21626767 = validateParameter(valid_21626767, JString, required = false,
                                   default = nil)
  if valid_21626767 != nil:
    section.add "X-Amz-Signature", valid_21626767
  var valid_21626768 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626768 = validateParameter(valid_21626768, JString, required = false,
                                   default = nil)
  if valid_21626768 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626768
  var valid_21626769 = header.getOrDefault("X-Amz-Credential")
  valid_21626769 = validateParameter(valid_21626769, JString, required = false,
                                   default = nil)
  if valid_21626769 != nil:
    section.add "X-Amz-Credential", valid_21626769
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

proc call*(call_21626771: Call_DescribeOpsItems_21626759; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Query a set of OpsItems. You must have permission in AWS Identity and Access Management (IAM) to query a list of OpsItems. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter-getting-started.html">Getting Started with OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>.</p> <p>Operations engineers and IT professionals use OpsCenter to view, investigate, and remediate operational issues impacting the performance and health of their AWS resources. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter.html">AWS Systems Manager OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>. </p>
  ## 
  let valid = call_21626771.validator(path, query, header, formData, body, _)
  let scheme = call_21626771.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626771.makeUrl(scheme.get, call_21626771.host, call_21626771.base,
                               call_21626771.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626771, uri, valid, _)

proc call*(call_21626772: Call_DescribeOpsItems_21626759; body: JsonNode): Recallable =
  ## describeOpsItems
  ## <p>Query a set of OpsItems. You must have permission in AWS Identity and Access Management (IAM) to query a list of OpsItems. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter-getting-started.html">Getting Started with OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>.</p> <p>Operations engineers and IT professionals use OpsCenter to view, investigate, and remediate operational issues impacting the performance and health of their AWS resources. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter.html">AWS Systems Manager OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>. </p>
  ##   body: JObject (required)
  var body_21626773 = newJObject()
  if body != nil:
    body_21626773 = body
  result = call_21626772.call(nil, nil, nil, nil, body_21626773)

var describeOpsItems* = Call_DescribeOpsItems_21626759(name: "describeOpsItems",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeOpsItems",
    validator: validate_DescribeOpsItems_21626760, base: "/",
    makeUrl: url_DescribeOpsItems_21626761, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeParameters_21626774 = ref object of OpenApiRestCall_21625435
proc url_DescribeParameters_21626776(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeParameters_21626775(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Get information about a parameter.</p> <note> <p>Request results are returned on a best-effort basis. If you specify <code>MaxResults</code> in the request, the response includes information up to the limit specified. The number of items returned, however, can be between zero and the value of <code>MaxResults</code>. If the service reaches an internal limit while processing the results, it stops the operation and returns the matching values up to that point and a <code>NextToken</code>. You can specify the <code>NextToken</code> in a subsequent call to get the next set of results.</p> </note>
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
  var valid_21626777 = query.getOrDefault("NextToken")
  valid_21626777 = validateParameter(valid_21626777, JString, required = false,
                                   default = nil)
  if valid_21626777 != nil:
    section.add "NextToken", valid_21626777
  var valid_21626778 = query.getOrDefault("MaxResults")
  valid_21626778 = validateParameter(valid_21626778, JString, required = false,
                                   default = nil)
  if valid_21626778 != nil:
    section.add "MaxResults", valid_21626778
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626779 = header.getOrDefault("X-Amz-Date")
  valid_21626779 = validateParameter(valid_21626779, JString, required = false,
                                   default = nil)
  if valid_21626779 != nil:
    section.add "X-Amz-Date", valid_21626779
  var valid_21626780 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626780 = validateParameter(valid_21626780, JString, required = false,
                                   default = nil)
  if valid_21626780 != nil:
    section.add "X-Amz-Security-Token", valid_21626780
  var valid_21626781 = header.getOrDefault("X-Amz-Target")
  valid_21626781 = validateParameter(valid_21626781, JString, required = true, default = newJString(
      "AmazonSSM.DescribeParameters"))
  if valid_21626781 != nil:
    section.add "X-Amz-Target", valid_21626781
  var valid_21626782 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626782 = validateParameter(valid_21626782, JString, required = false,
                                   default = nil)
  if valid_21626782 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626782
  var valid_21626783 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626783 = validateParameter(valid_21626783, JString, required = false,
                                   default = nil)
  if valid_21626783 != nil:
    section.add "X-Amz-Algorithm", valid_21626783
  var valid_21626784 = header.getOrDefault("X-Amz-Signature")
  valid_21626784 = validateParameter(valid_21626784, JString, required = false,
                                   default = nil)
  if valid_21626784 != nil:
    section.add "X-Amz-Signature", valid_21626784
  var valid_21626785 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626785 = validateParameter(valid_21626785, JString, required = false,
                                   default = nil)
  if valid_21626785 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626785
  var valid_21626786 = header.getOrDefault("X-Amz-Credential")
  valid_21626786 = validateParameter(valid_21626786, JString, required = false,
                                   default = nil)
  if valid_21626786 != nil:
    section.add "X-Amz-Credential", valid_21626786
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

proc call*(call_21626788: Call_DescribeParameters_21626774; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Get information about a parameter.</p> <note> <p>Request results are returned on a best-effort basis. If you specify <code>MaxResults</code> in the request, the response includes information up to the limit specified. The number of items returned, however, can be between zero and the value of <code>MaxResults</code>. If the service reaches an internal limit while processing the results, it stops the operation and returns the matching values up to that point and a <code>NextToken</code>. You can specify the <code>NextToken</code> in a subsequent call to get the next set of results.</p> </note>
  ## 
  let valid = call_21626788.validator(path, query, header, formData, body, _)
  let scheme = call_21626788.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626788.makeUrl(scheme.get, call_21626788.host, call_21626788.base,
                               call_21626788.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626788, uri, valid, _)

proc call*(call_21626789: Call_DescribeParameters_21626774; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## describeParameters
  ## <p>Get information about a parameter.</p> <note> <p>Request results are returned on a best-effort basis. If you specify <code>MaxResults</code> in the request, the response includes information up to the limit specified. The number of items returned, however, can be between zero and the value of <code>MaxResults</code>. If the service reaches an internal limit while processing the results, it stops the operation and returns the matching values up to that point and a <code>NextToken</code>. You can specify the <code>NextToken</code> in a subsequent call to get the next set of results.</p> </note>
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_21626790 = newJObject()
  var body_21626791 = newJObject()
  add(query_21626790, "NextToken", newJString(NextToken))
  if body != nil:
    body_21626791 = body
  add(query_21626790, "MaxResults", newJString(MaxResults))
  result = call_21626789.call(nil, query_21626790, nil, nil, body_21626791)

var describeParameters* = Call_DescribeParameters_21626774(
    name: "describeParameters", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeParameters",
    validator: validate_DescribeParameters_21626775, base: "/",
    makeUrl: url_DescribeParameters_21626776, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribePatchBaselines_21626792 = ref object of OpenApiRestCall_21625435
proc url_DescribePatchBaselines_21626794(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribePatchBaselines_21626793(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626795 = header.getOrDefault("X-Amz-Date")
  valid_21626795 = validateParameter(valid_21626795, JString, required = false,
                                   default = nil)
  if valid_21626795 != nil:
    section.add "X-Amz-Date", valid_21626795
  var valid_21626796 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626796 = validateParameter(valid_21626796, JString, required = false,
                                   default = nil)
  if valid_21626796 != nil:
    section.add "X-Amz-Security-Token", valid_21626796
  var valid_21626797 = header.getOrDefault("X-Amz-Target")
  valid_21626797 = validateParameter(valid_21626797, JString, required = true, default = newJString(
      "AmazonSSM.DescribePatchBaselines"))
  if valid_21626797 != nil:
    section.add "X-Amz-Target", valid_21626797
  var valid_21626798 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626798 = validateParameter(valid_21626798, JString, required = false,
                                   default = nil)
  if valid_21626798 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626798
  var valid_21626799 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626799 = validateParameter(valid_21626799, JString, required = false,
                                   default = nil)
  if valid_21626799 != nil:
    section.add "X-Amz-Algorithm", valid_21626799
  var valid_21626800 = header.getOrDefault("X-Amz-Signature")
  valid_21626800 = validateParameter(valid_21626800, JString, required = false,
                                   default = nil)
  if valid_21626800 != nil:
    section.add "X-Amz-Signature", valid_21626800
  var valid_21626801 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626801 = validateParameter(valid_21626801, JString, required = false,
                                   default = nil)
  if valid_21626801 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626801
  var valid_21626802 = header.getOrDefault("X-Amz-Credential")
  valid_21626802 = validateParameter(valid_21626802, JString, required = false,
                                   default = nil)
  if valid_21626802 != nil:
    section.add "X-Amz-Credential", valid_21626802
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

proc call*(call_21626804: Call_DescribePatchBaselines_21626792;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the patch baselines in your AWS account.
  ## 
  let valid = call_21626804.validator(path, query, header, formData, body, _)
  let scheme = call_21626804.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626804.makeUrl(scheme.get, call_21626804.host, call_21626804.base,
                               call_21626804.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626804, uri, valid, _)

proc call*(call_21626805: Call_DescribePatchBaselines_21626792; body: JsonNode): Recallable =
  ## describePatchBaselines
  ## Lists the patch baselines in your AWS account.
  ##   body: JObject (required)
  var body_21626806 = newJObject()
  if body != nil:
    body_21626806 = body
  result = call_21626805.call(nil, nil, nil, nil, body_21626806)

var describePatchBaselines* = Call_DescribePatchBaselines_21626792(
    name: "describePatchBaselines", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribePatchBaselines",
    validator: validate_DescribePatchBaselines_21626793, base: "/",
    makeUrl: url_DescribePatchBaselines_21626794,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribePatchGroupState_21626807 = ref object of OpenApiRestCall_21625435
proc url_DescribePatchGroupState_21626809(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribePatchGroupState_21626808(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626810 = header.getOrDefault("X-Amz-Date")
  valid_21626810 = validateParameter(valid_21626810, JString, required = false,
                                   default = nil)
  if valid_21626810 != nil:
    section.add "X-Amz-Date", valid_21626810
  var valid_21626811 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626811 = validateParameter(valid_21626811, JString, required = false,
                                   default = nil)
  if valid_21626811 != nil:
    section.add "X-Amz-Security-Token", valid_21626811
  var valid_21626812 = header.getOrDefault("X-Amz-Target")
  valid_21626812 = validateParameter(valid_21626812, JString, required = true, default = newJString(
      "AmazonSSM.DescribePatchGroupState"))
  if valid_21626812 != nil:
    section.add "X-Amz-Target", valid_21626812
  var valid_21626813 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626813 = validateParameter(valid_21626813, JString, required = false,
                                   default = nil)
  if valid_21626813 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626813
  var valid_21626814 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626814 = validateParameter(valid_21626814, JString, required = false,
                                   default = nil)
  if valid_21626814 != nil:
    section.add "X-Amz-Algorithm", valid_21626814
  var valid_21626815 = header.getOrDefault("X-Amz-Signature")
  valid_21626815 = validateParameter(valid_21626815, JString, required = false,
                                   default = nil)
  if valid_21626815 != nil:
    section.add "X-Amz-Signature", valid_21626815
  var valid_21626816 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626816 = validateParameter(valid_21626816, JString, required = false,
                                   default = nil)
  if valid_21626816 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626816
  var valid_21626817 = header.getOrDefault("X-Amz-Credential")
  valid_21626817 = validateParameter(valid_21626817, JString, required = false,
                                   default = nil)
  if valid_21626817 != nil:
    section.add "X-Amz-Credential", valid_21626817
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

proc call*(call_21626819: Call_DescribePatchGroupState_21626807;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns high-level aggregated patch compliance state for a patch group.
  ## 
  let valid = call_21626819.validator(path, query, header, formData, body, _)
  let scheme = call_21626819.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626819.makeUrl(scheme.get, call_21626819.host, call_21626819.base,
                               call_21626819.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626819, uri, valid, _)

proc call*(call_21626820: Call_DescribePatchGroupState_21626807; body: JsonNode): Recallable =
  ## describePatchGroupState
  ## Returns high-level aggregated patch compliance state for a patch group.
  ##   body: JObject (required)
  var body_21626821 = newJObject()
  if body != nil:
    body_21626821 = body
  result = call_21626820.call(nil, nil, nil, nil, body_21626821)

var describePatchGroupState* = Call_DescribePatchGroupState_21626807(
    name: "describePatchGroupState", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribePatchGroupState",
    validator: validate_DescribePatchGroupState_21626808, base: "/",
    makeUrl: url_DescribePatchGroupState_21626809,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribePatchGroups_21626822 = ref object of OpenApiRestCall_21625435
proc url_DescribePatchGroups_21626824(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribePatchGroups_21626823(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626825 = header.getOrDefault("X-Amz-Date")
  valid_21626825 = validateParameter(valid_21626825, JString, required = false,
                                   default = nil)
  if valid_21626825 != nil:
    section.add "X-Amz-Date", valid_21626825
  var valid_21626826 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626826 = validateParameter(valid_21626826, JString, required = false,
                                   default = nil)
  if valid_21626826 != nil:
    section.add "X-Amz-Security-Token", valid_21626826
  var valid_21626827 = header.getOrDefault("X-Amz-Target")
  valid_21626827 = validateParameter(valid_21626827, JString, required = true, default = newJString(
      "AmazonSSM.DescribePatchGroups"))
  if valid_21626827 != nil:
    section.add "X-Amz-Target", valid_21626827
  var valid_21626828 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626828 = validateParameter(valid_21626828, JString, required = false,
                                   default = nil)
  if valid_21626828 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626828
  var valid_21626829 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626829 = validateParameter(valid_21626829, JString, required = false,
                                   default = nil)
  if valid_21626829 != nil:
    section.add "X-Amz-Algorithm", valid_21626829
  var valid_21626830 = header.getOrDefault("X-Amz-Signature")
  valid_21626830 = validateParameter(valid_21626830, JString, required = false,
                                   default = nil)
  if valid_21626830 != nil:
    section.add "X-Amz-Signature", valid_21626830
  var valid_21626831 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626831 = validateParameter(valid_21626831, JString, required = false,
                                   default = nil)
  if valid_21626831 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626831
  var valid_21626832 = header.getOrDefault("X-Amz-Credential")
  valid_21626832 = validateParameter(valid_21626832, JString, required = false,
                                   default = nil)
  if valid_21626832 != nil:
    section.add "X-Amz-Credential", valid_21626832
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

proc call*(call_21626834: Call_DescribePatchGroups_21626822; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists all patch groups that have been registered with patch baselines.
  ## 
  let valid = call_21626834.validator(path, query, header, formData, body, _)
  let scheme = call_21626834.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626834.makeUrl(scheme.get, call_21626834.host, call_21626834.base,
                               call_21626834.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626834, uri, valid, _)

proc call*(call_21626835: Call_DescribePatchGroups_21626822; body: JsonNode): Recallable =
  ## describePatchGroups
  ## Lists all patch groups that have been registered with patch baselines.
  ##   body: JObject (required)
  var body_21626836 = newJObject()
  if body != nil:
    body_21626836 = body
  result = call_21626835.call(nil, nil, nil, nil, body_21626836)

var describePatchGroups* = Call_DescribePatchGroups_21626822(
    name: "describePatchGroups", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribePatchGroups",
    validator: validate_DescribePatchGroups_21626823, base: "/",
    makeUrl: url_DescribePatchGroups_21626824,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribePatchProperties_21626837 = ref object of OpenApiRestCall_21625435
proc url_DescribePatchProperties_21626839(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribePatchProperties_21626838(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626840 = header.getOrDefault("X-Amz-Date")
  valid_21626840 = validateParameter(valid_21626840, JString, required = false,
                                   default = nil)
  if valid_21626840 != nil:
    section.add "X-Amz-Date", valid_21626840
  var valid_21626841 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626841 = validateParameter(valid_21626841, JString, required = false,
                                   default = nil)
  if valid_21626841 != nil:
    section.add "X-Amz-Security-Token", valid_21626841
  var valid_21626842 = header.getOrDefault("X-Amz-Target")
  valid_21626842 = validateParameter(valid_21626842, JString, required = true, default = newJString(
      "AmazonSSM.DescribePatchProperties"))
  if valid_21626842 != nil:
    section.add "X-Amz-Target", valid_21626842
  var valid_21626843 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626843 = validateParameter(valid_21626843, JString, required = false,
                                   default = nil)
  if valid_21626843 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626843
  var valid_21626844 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626844 = validateParameter(valid_21626844, JString, required = false,
                                   default = nil)
  if valid_21626844 != nil:
    section.add "X-Amz-Algorithm", valid_21626844
  var valid_21626845 = header.getOrDefault("X-Amz-Signature")
  valid_21626845 = validateParameter(valid_21626845, JString, required = false,
                                   default = nil)
  if valid_21626845 != nil:
    section.add "X-Amz-Signature", valid_21626845
  var valid_21626846 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626846 = validateParameter(valid_21626846, JString, required = false,
                                   default = nil)
  if valid_21626846 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626846
  var valid_21626847 = header.getOrDefault("X-Amz-Credential")
  valid_21626847 = validateParameter(valid_21626847, JString, required = false,
                                   default = nil)
  if valid_21626847 != nil:
    section.add "X-Amz-Credential", valid_21626847
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

proc call*(call_21626849: Call_DescribePatchProperties_21626837;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Lists the properties of available patches organized by product, product family, classification, severity, and other properties of available patches. You can use the reported properties in the filters you specify in requests for actions such as <a>CreatePatchBaseline</a>, <a>UpdatePatchBaseline</a>, <a>DescribeAvailablePatches</a>, and <a>DescribePatchBaselines</a>.</p> <p>The following section lists the properties that can be used in filters for each major operating system type:</p> <dl> <dt>WINDOWS</dt> <dd> <p>Valid properties: PRODUCT, PRODUCT_FAMILY, CLASSIFICATION, MSRC_SEVERITY</p> </dd> <dt>AMAZON_LINUX</dt> <dd> <p>Valid properties: PRODUCT, CLASSIFICATION, SEVERITY</p> </dd> <dt>AMAZON_LINUX_2</dt> <dd> <p>Valid properties: PRODUCT, CLASSIFICATION, SEVERITY</p> </dd> <dt>UBUNTU </dt> <dd> <p>Valid properties: PRODUCT, PRIORITY</p> </dd> <dt>REDHAT_ENTERPRISE_LINUX</dt> <dd> <p>Valid properties: PRODUCT, CLASSIFICATION, SEVERITY</p> </dd> <dt>SUSE</dt> <dd> <p>Valid properties: PRODUCT, CLASSIFICATION, SEVERITY</p> </dd> <dt>CENTOS</dt> <dd> <p>Valid properties: PRODUCT, CLASSIFICATION, SEVERITY</p> </dd> </dl>
  ## 
  let valid = call_21626849.validator(path, query, header, formData, body, _)
  let scheme = call_21626849.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626849.makeUrl(scheme.get, call_21626849.host, call_21626849.base,
                               call_21626849.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626849, uri, valid, _)

proc call*(call_21626850: Call_DescribePatchProperties_21626837; body: JsonNode): Recallable =
  ## describePatchProperties
  ## <p>Lists the properties of available patches organized by product, product family, classification, severity, and other properties of available patches. You can use the reported properties in the filters you specify in requests for actions such as <a>CreatePatchBaseline</a>, <a>UpdatePatchBaseline</a>, <a>DescribeAvailablePatches</a>, and <a>DescribePatchBaselines</a>.</p> <p>The following section lists the properties that can be used in filters for each major operating system type:</p> <dl> <dt>WINDOWS</dt> <dd> <p>Valid properties: PRODUCT, PRODUCT_FAMILY, CLASSIFICATION, MSRC_SEVERITY</p> </dd> <dt>AMAZON_LINUX</dt> <dd> <p>Valid properties: PRODUCT, CLASSIFICATION, SEVERITY</p> </dd> <dt>AMAZON_LINUX_2</dt> <dd> <p>Valid properties: PRODUCT, CLASSIFICATION, SEVERITY</p> </dd> <dt>UBUNTU </dt> <dd> <p>Valid properties: PRODUCT, PRIORITY</p> </dd> <dt>REDHAT_ENTERPRISE_LINUX</dt> <dd> <p>Valid properties: PRODUCT, CLASSIFICATION, SEVERITY</p> </dd> <dt>SUSE</dt> <dd> <p>Valid properties: PRODUCT, CLASSIFICATION, SEVERITY</p> </dd> <dt>CENTOS</dt> <dd> <p>Valid properties: PRODUCT, CLASSIFICATION, SEVERITY</p> </dd> </dl>
  ##   body: JObject (required)
  var body_21626851 = newJObject()
  if body != nil:
    body_21626851 = body
  result = call_21626850.call(nil, nil, nil, nil, body_21626851)

var describePatchProperties* = Call_DescribePatchProperties_21626837(
    name: "describePatchProperties", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribePatchProperties",
    validator: validate_DescribePatchProperties_21626838, base: "/",
    makeUrl: url_DescribePatchProperties_21626839,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeSessions_21626852 = ref object of OpenApiRestCall_21625435
proc url_DescribeSessions_21626854(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeSessions_21626853(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626855 = header.getOrDefault("X-Amz-Date")
  valid_21626855 = validateParameter(valid_21626855, JString, required = false,
                                   default = nil)
  if valid_21626855 != nil:
    section.add "X-Amz-Date", valid_21626855
  var valid_21626856 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626856 = validateParameter(valid_21626856, JString, required = false,
                                   default = nil)
  if valid_21626856 != nil:
    section.add "X-Amz-Security-Token", valid_21626856
  var valid_21626857 = header.getOrDefault("X-Amz-Target")
  valid_21626857 = validateParameter(valid_21626857, JString, required = true, default = newJString(
      "AmazonSSM.DescribeSessions"))
  if valid_21626857 != nil:
    section.add "X-Amz-Target", valid_21626857
  var valid_21626858 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626858 = validateParameter(valid_21626858, JString, required = false,
                                   default = nil)
  if valid_21626858 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626858
  var valid_21626859 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626859 = validateParameter(valid_21626859, JString, required = false,
                                   default = nil)
  if valid_21626859 != nil:
    section.add "X-Amz-Algorithm", valid_21626859
  var valid_21626860 = header.getOrDefault("X-Amz-Signature")
  valid_21626860 = validateParameter(valid_21626860, JString, required = false,
                                   default = nil)
  if valid_21626860 != nil:
    section.add "X-Amz-Signature", valid_21626860
  var valid_21626861 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626861 = validateParameter(valid_21626861, JString, required = false,
                                   default = nil)
  if valid_21626861 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626861
  var valid_21626862 = header.getOrDefault("X-Amz-Credential")
  valid_21626862 = validateParameter(valid_21626862, JString, required = false,
                                   default = nil)
  if valid_21626862 != nil:
    section.add "X-Amz-Credential", valid_21626862
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

proc call*(call_21626864: Call_DescribeSessions_21626852; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves a list of all active sessions (both connected and disconnected) or terminated sessions from the past 30 days.
  ## 
  let valid = call_21626864.validator(path, query, header, formData, body, _)
  let scheme = call_21626864.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626864.makeUrl(scheme.get, call_21626864.host, call_21626864.base,
                               call_21626864.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626864, uri, valid, _)

proc call*(call_21626865: Call_DescribeSessions_21626852; body: JsonNode): Recallable =
  ## describeSessions
  ## Retrieves a list of all active sessions (both connected and disconnected) or terminated sessions from the past 30 days.
  ##   body: JObject (required)
  var body_21626866 = newJObject()
  if body != nil:
    body_21626866 = body
  result = call_21626865.call(nil, nil, nil, nil, body_21626866)

var describeSessions* = Call_DescribeSessions_21626852(name: "describeSessions",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeSessions",
    validator: validate_DescribeSessions_21626853, base: "/",
    makeUrl: url_DescribeSessions_21626854, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAutomationExecution_21626867 = ref object of OpenApiRestCall_21625435
proc url_GetAutomationExecution_21626869(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetAutomationExecution_21626868(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626870 = header.getOrDefault("X-Amz-Date")
  valid_21626870 = validateParameter(valid_21626870, JString, required = false,
                                   default = nil)
  if valid_21626870 != nil:
    section.add "X-Amz-Date", valid_21626870
  var valid_21626871 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626871 = validateParameter(valid_21626871, JString, required = false,
                                   default = nil)
  if valid_21626871 != nil:
    section.add "X-Amz-Security-Token", valid_21626871
  var valid_21626872 = header.getOrDefault("X-Amz-Target")
  valid_21626872 = validateParameter(valid_21626872, JString, required = true, default = newJString(
      "AmazonSSM.GetAutomationExecution"))
  if valid_21626872 != nil:
    section.add "X-Amz-Target", valid_21626872
  var valid_21626873 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626873 = validateParameter(valid_21626873, JString, required = false,
                                   default = nil)
  if valid_21626873 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626873
  var valid_21626874 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626874 = validateParameter(valid_21626874, JString, required = false,
                                   default = nil)
  if valid_21626874 != nil:
    section.add "X-Amz-Algorithm", valid_21626874
  var valid_21626875 = header.getOrDefault("X-Amz-Signature")
  valid_21626875 = validateParameter(valid_21626875, JString, required = false,
                                   default = nil)
  if valid_21626875 != nil:
    section.add "X-Amz-Signature", valid_21626875
  var valid_21626876 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626876 = validateParameter(valid_21626876, JString, required = false,
                                   default = nil)
  if valid_21626876 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626876
  var valid_21626877 = header.getOrDefault("X-Amz-Credential")
  valid_21626877 = validateParameter(valid_21626877, JString, required = false,
                                   default = nil)
  if valid_21626877 != nil:
    section.add "X-Amz-Credential", valid_21626877
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

proc call*(call_21626879: Call_GetAutomationExecution_21626867;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Get detailed information about a particular Automation execution.
  ## 
  let valid = call_21626879.validator(path, query, header, formData, body, _)
  let scheme = call_21626879.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626879.makeUrl(scheme.get, call_21626879.host, call_21626879.base,
                               call_21626879.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626879, uri, valid, _)

proc call*(call_21626880: Call_GetAutomationExecution_21626867; body: JsonNode): Recallable =
  ## getAutomationExecution
  ## Get detailed information about a particular Automation execution.
  ##   body: JObject (required)
  var body_21626881 = newJObject()
  if body != nil:
    body_21626881 = body
  result = call_21626880.call(nil, nil, nil, nil, body_21626881)

var getAutomationExecution* = Call_GetAutomationExecution_21626867(
    name: "getAutomationExecution", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetAutomationExecution",
    validator: validate_GetAutomationExecution_21626868, base: "/",
    makeUrl: url_GetAutomationExecution_21626869,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCalendarState_21626882 = ref object of OpenApiRestCall_21625435
proc url_GetCalendarState_21626884(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCalendarState_21626883(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Gets the state of the AWS Systems Manager Change Calendar at an optional, specified time. If you specify a time, <code>GetCalendarState</code> returns the state of the calendar at a specific time, and returns the next time that the Change Calendar state will transition. If you do not specify a time, <code>GetCalendarState</code> assumes the current time. Change Calendar entries have two possible states: <code>OPEN</code> or <code>CLOSED</code>. For more information about Systems Manager Change Calendar, see <a href="https://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-change-calendar.html">AWS Systems Manager Change Calendar</a> in the <i>AWS Systems Manager User Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626885 = header.getOrDefault("X-Amz-Date")
  valid_21626885 = validateParameter(valid_21626885, JString, required = false,
                                   default = nil)
  if valid_21626885 != nil:
    section.add "X-Amz-Date", valid_21626885
  var valid_21626886 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626886 = validateParameter(valid_21626886, JString, required = false,
                                   default = nil)
  if valid_21626886 != nil:
    section.add "X-Amz-Security-Token", valid_21626886
  var valid_21626887 = header.getOrDefault("X-Amz-Target")
  valid_21626887 = validateParameter(valid_21626887, JString, required = true, default = newJString(
      "AmazonSSM.GetCalendarState"))
  if valid_21626887 != nil:
    section.add "X-Amz-Target", valid_21626887
  var valid_21626888 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626888 = validateParameter(valid_21626888, JString, required = false,
                                   default = nil)
  if valid_21626888 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626888
  var valid_21626889 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626889 = validateParameter(valid_21626889, JString, required = false,
                                   default = nil)
  if valid_21626889 != nil:
    section.add "X-Amz-Algorithm", valid_21626889
  var valid_21626890 = header.getOrDefault("X-Amz-Signature")
  valid_21626890 = validateParameter(valid_21626890, JString, required = false,
                                   default = nil)
  if valid_21626890 != nil:
    section.add "X-Amz-Signature", valid_21626890
  var valid_21626891 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626891 = validateParameter(valid_21626891, JString, required = false,
                                   default = nil)
  if valid_21626891 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626891
  var valid_21626892 = header.getOrDefault("X-Amz-Credential")
  valid_21626892 = validateParameter(valid_21626892, JString, required = false,
                                   default = nil)
  if valid_21626892 != nil:
    section.add "X-Amz-Credential", valid_21626892
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

proc call*(call_21626894: Call_GetCalendarState_21626882; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets the state of the AWS Systems Manager Change Calendar at an optional, specified time. If you specify a time, <code>GetCalendarState</code> returns the state of the calendar at a specific time, and returns the next time that the Change Calendar state will transition. If you do not specify a time, <code>GetCalendarState</code> assumes the current time. Change Calendar entries have two possible states: <code>OPEN</code> or <code>CLOSED</code>. For more information about Systems Manager Change Calendar, see <a href="https://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-change-calendar.html">AWS Systems Manager Change Calendar</a> in the <i>AWS Systems Manager User Guide</i>.
  ## 
  let valid = call_21626894.validator(path, query, header, formData, body, _)
  let scheme = call_21626894.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626894.makeUrl(scheme.get, call_21626894.host, call_21626894.base,
                               call_21626894.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626894, uri, valid, _)

proc call*(call_21626895: Call_GetCalendarState_21626882; body: JsonNode): Recallable =
  ## getCalendarState
  ## Gets the state of the AWS Systems Manager Change Calendar at an optional, specified time. If you specify a time, <code>GetCalendarState</code> returns the state of the calendar at a specific time, and returns the next time that the Change Calendar state will transition. If you do not specify a time, <code>GetCalendarState</code> assumes the current time. Change Calendar entries have two possible states: <code>OPEN</code> or <code>CLOSED</code>. For more information about Systems Manager Change Calendar, see <a href="https://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-change-calendar.html">AWS Systems Manager Change Calendar</a> in the <i>AWS Systems Manager User Guide</i>.
  ##   body: JObject (required)
  var body_21626896 = newJObject()
  if body != nil:
    body_21626896 = body
  result = call_21626895.call(nil, nil, nil, nil, body_21626896)

var getCalendarState* = Call_GetCalendarState_21626882(name: "getCalendarState",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetCalendarState",
    validator: validate_GetCalendarState_21626883, base: "/",
    makeUrl: url_GetCalendarState_21626884, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCommandInvocation_21626897 = ref object of OpenApiRestCall_21625435
proc url_GetCommandInvocation_21626899(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCommandInvocation_21626898(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626900 = header.getOrDefault("X-Amz-Date")
  valid_21626900 = validateParameter(valid_21626900, JString, required = false,
                                   default = nil)
  if valid_21626900 != nil:
    section.add "X-Amz-Date", valid_21626900
  var valid_21626901 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626901 = validateParameter(valid_21626901, JString, required = false,
                                   default = nil)
  if valid_21626901 != nil:
    section.add "X-Amz-Security-Token", valid_21626901
  var valid_21626902 = header.getOrDefault("X-Amz-Target")
  valid_21626902 = validateParameter(valid_21626902, JString, required = true, default = newJString(
      "AmazonSSM.GetCommandInvocation"))
  if valid_21626902 != nil:
    section.add "X-Amz-Target", valid_21626902
  var valid_21626903 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626903 = validateParameter(valid_21626903, JString, required = false,
                                   default = nil)
  if valid_21626903 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626903
  var valid_21626904 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626904 = validateParameter(valid_21626904, JString, required = false,
                                   default = nil)
  if valid_21626904 != nil:
    section.add "X-Amz-Algorithm", valid_21626904
  var valid_21626905 = header.getOrDefault("X-Amz-Signature")
  valid_21626905 = validateParameter(valid_21626905, JString, required = false,
                                   default = nil)
  if valid_21626905 != nil:
    section.add "X-Amz-Signature", valid_21626905
  var valid_21626906 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626906 = validateParameter(valid_21626906, JString, required = false,
                                   default = nil)
  if valid_21626906 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626906
  var valid_21626907 = header.getOrDefault("X-Amz-Credential")
  valid_21626907 = validateParameter(valid_21626907, JString, required = false,
                                   default = nil)
  if valid_21626907 != nil:
    section.add "X-Amz-Credential", valid_21626907
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

proc call*(call_21626909: Call_GetCommandInvocation_21626897; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns detailed information about command execution for an invocation or plugin. 
  ## 
  let valid = call_21626909.validator(path, query, header, formData, body, _)
  let scheme = call_21626909.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626909.makeUrl(scheme.get, call_21626909.host, call_21626909.base,
                               call_21626909.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626909, uri, valid, _)

proc call*(call_21626910: Call_GetCommandInvocation_21626897; body: JsonNode): Recallable =
  ## getCommandInvocation
  ## Returns detailed information about command execution for an invocation or plugin. 
  ##   body: JObject (required)
  var body_21626911 = newJObject()
  if body != nil:
    body_21626911 = body
  result = call_21626910.call(nil, nil, nil, nil, body_21626911)

var getCommandInvocation* = Call_GetCommandInvocation_21626897(
    name: "getCommandInvocation", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetCommandInvocation",
    validator: validate_GetCommandInvocation_21626898, base: "/",
    makeUrl: url_GetCommandInvocation_21626899,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetConnectionStatus_21626912 = ref object of OpenApiRestCall_21625435
proc url_GetConnectionStatus_21626914(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetConnectionStatus_21626913(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626915 = header.getOrDefault("X-Amz-Date")
  valid_21626915 = validateParameter(valid_21626915, JString, required = false,
                                   default = nil)
  if valid_21626915 != nil:
    section.add "X-Amz-Date", valid_21626915
  var valid_21626916 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626916 = validateParameter(valid_21626916, JString, required = false,
                                   default = nil)
  if valid_21626916 != nil:
    section.add "X-Amz-Security-Token", valid_21626916
  var valid_21626917 = header.getOrDefault("X-Amz-Target")
  valid_21626917 = validateParameter(valid_21626917, JString, required = true, default = newJString(
      "AmazonSSM.GetConnectionStatus"))
  if valid_21626917 != nil:
    section.add "X-Amz-Target", valid_21626917
  var valid_21626918 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626918 = validateParameter(valid_21626918, JString, required = false,
                                   default = nil)
  if valid_21626918 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626918
  var valid_21626919 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626919 = validateParameter(valid_21626919, JString, required = false,
                                   default = nil)
  if valid_21626919 != nil:
    section.add "X-Amz-Algorithm", valid_21626919
  var valid_21626920 = header.getOrDefault("X-Amz-Signature")
  valid_21626920 = validateParameter(valid_21626920, JString, required = false,
                                   default = nil)
  if valid_21626920 != nil:
    section.add "X-Amz-Signature", valid_21626920
  var valid_21626921 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626921 = validateParameter(valid_21626921, JString, required = false,
                                   default = nil)
  if valid_21626921 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626921
  var valid_21626922 = header.getOrDefault("X-Amz-Credential")
  valid_21626922 = validateParameter(valid_21626922, JString, required = false,
                                   default = nil)
  if valid_21626922 != nil:
    section.add "X-Amz-Credential", valid_21626922
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

proc call*(call_21626924: Call_GetConnectionStatus_21626912; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves the Session Manager connection status for an instance to determine whether it is connected and ready to receive Session Manager connections.
  ## 
  let valid = call_21626924.validator(path, query, header, formData, body, _)
  let scheme = call_21626924.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626924.makeUrl(scheme.get, call_21626924.host, call_21626924.base,
                               call_21626924.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626924, uri, valid, _)

proc call*(call_21626925: Call_GetConnectionStatus_21626912; body: JsonNode): Recallable =
  ## getConnectionStatus
  ## Retrieves the Session Manager connection status for an instance to determine whether it is connected and ready to receive Session Manager connections.
  ##   body: JObject (required)
  var body_21626926 = newJObject()
  if body != nil:
    body_21626926 = body
  result = call_21626925.call(nil, nil, nil, nil, body_21626926)

var getConnectionStatus* = Call_GetConnectionStatus_21626912(
    name: "getConnectionStatus", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetConnectionStatus",
    validator: validate_GetConnectionStatus_21626913, base: "/",
    makeUrl: url_GetConnectionStatus_21626914,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDefaultPatchBaseline_21626927 = ref object of OpenApiRestCall_21625435
proc url_GetDefaultPatchBaseline_21626929(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDefaultPatchBaseline_21626928(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626930 = header.getOrDefault("X-Amz-Date")
  valid_21626930 = validateParameter(valid_21626930, JString, required = false,
                                   default = nil)
  if valid_21626930 != nil:
    section.add "X-Amz-Date", valid_21626930
  var valid_21626931 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626931 = validateParameter(valid_21626931, JString, required = false,
                                   default = nil)
  if valid_21626931 != nil:
    section.add "X-Amz-Security-Token", valid_21626931
  var valid_21626932 = header.getOrDefault("X-Amz-Target")
  valid_21626932 = validateParameter(valid_21626932, JString, required = true, default = newJString(
      "AmazonSSM.GetDefaultPatchBaseline"))
  if valid_21626932 != nil:
    section.add "X-Amz-Target", valid_21626932
  var valid_21626933 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626933 = validateParameter(valid_21626933, JString, required = false,
                                   default = nil)
  if valid_21626933 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626933
  var valid_21626934 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626934 = validateParameter(valid_21626934, JString, required = false,
                                   default = nil)
  if valid_21626934 != nil:
    section.add "X-Amz-Algorithm", valid_21626934
  var valid_21626935 = header.getOrDefault("X-Amz-Signature")
  valid_21626935 = validateParameter(valid_21626935, JString, required = false,
                                   default = nil)
  if valid_21626935 != nil:
    section.add "X-Amz-Signature", valid_21626935
  var valid_21626936 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626936 = validateParameter(valid_21626936, JString, required = false,
                                   default = nil)
  if valid_21626936 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626936
  var valid_21626937 = header.getOrDefault("X-Amz-Credential")
  valid_21626937 = validateParameter(valid_21626937, JString, required = false,
                                   default = nil)
  if valid_21626937 != nil:
    section.add "X-Amz-Credential", valid_21626937
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

proc call*(call_21626939: Call_GetDefaultPatchBaseline_21626927;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Retrieves the default patch baseline. Note that Systems Manager supports creating multiple default patch baselines. For example, you can create a default patch baseline for each operating system.</p> <p>If you do not specify an operating system value, the default patch baseline for Windows is returned.</p>
  ## 
  let valid = call_21626939.validator(path, query, header, formData, body, _)
  let scheme = call_21626939.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626939.makeUrl(scheme.get, call_21626939.host, call_21626939.base,
                               call_21626939.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626939, uri, valid, _)

proc call*(call_21626940: Call_GetDefaultPatchBaseline_21626927; body: JsonNode): Recallable =
  ## getDefaultPatchBaseline
  ## <p>Retrieves the default patch baseline. Note that Systems Manager supports creating multiple default patch baselines. For example, you can create a default patch baseline for each operating system.</p> <p>If you do not specify an operating system value, the default patch baseline for Windows is returned.</p>
  ##   body: JObject (required)
  var body_21626941 = newJObject()
  if body != nil:
    body_21626941 = body
  result = call_21626940.call(nil, nil, nil, nil, body_21626941)

var getDefaultPatchBaseline* = Call_GetDefaultPatchBaseline_21626927(
    name: "getDefaultPatchBaseline", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetDefaultPatchBaseline",
    validator: validate_GetDefaultPatchBaseline_21626928, base: "/",
    makeUrl: url_GetDefaultPatchBaseline_21626929,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeployablePatchSnapshotForInstance_21626942 = ref object of OpenApiRestCall_21625435
proc url_GetDeployablePatchSnapshotForInstance_21626944(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeployablePatchSnapshotForInstance_21626943(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626945 = header.getOrDefault("X-Amz-Date")
  valid_21626945 = validateParameter(valid_21626945, JString, required = false,
                                   default = nil)
  if valid_21626945 != nil:
    section.add "X-Amz-Date", valid_21626945
  var valid_21626946 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626946 = validateParameter(valid_21626946, JString, required = false,
                                   default = nil)
  if valid_21626946 != nil:
    section.add "X-Amz-Security-Token", valid_21626946
  var valid_21626947 = header.getOrDefault("X-Amz-Target")
  valid_21626947 = validateParameter(valid_21626947, JString, required = true, default = newJString(
      "AmazonSSM.GetDeployablePatchSnapshotForInstance"))
  if valid_21626947 != nil:
    section.add "X-Amz-Target", valid_21626947
  var valid_21626948 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626948 = validateParameter(valid_21626948, JString, required = false,
                                   default = nil)
  if valid_21626948 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626948
  var valid_21626949 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626949 = validateParameter(valid_21626949, JString, required = false,
                                   default = nil)
  if valid_21626949 != nil:
    section.add "X-Amz-Algorithm", valid_21626949
  var valid_21626950 = header.getOrDefault("X-Amz-Signature")
  valid_21626950 = validateParameter(valid_21626950, JString, required = false,
                                   default = nil)
  if valid_21626950 != nil:
    section.add "X-Amz-Signature", valid_21626950
  var valid_21626951 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626951 = validateParameter(valid_21626951, JString, required = false,
                                   default = nil)
  if valid_21626951 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626951
  var valid_21626952 = header.getOrDefault("X-Amz-Credential")
  valid_21626952 = validateParameter(valid_21626952, JString, required = false,
                                   default = nil)
  if valid_21626952 != nil:
    section.add "X-Amz-Credential", valid_21626952
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

proc call*(call_21626954: Call_GetDeployablePatchSnapshotForInstance_21626942;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves the current snapshot for the patch baseline the instance uses. This API is primarily used by the AWS-RunPatchBaseline Systems Manager document. 
  ## 
  let valid = call_21626954.validator(path, query, header, formData, body, _)
  let scheme = call_21626954.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626954.makeUrl(scheme.get, call_21626954.host, call_21626954.base,
                               call_21626954.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626954, uri, valid, _)

proc call*(call_21626955: Call_GetDeployablePatchSnapshotForInstance_21626942;
          body: JsonNode): Recallable =
  ## getDeployablePatchSnapshotForInstance
  ## Retrieves the current snapshot for the patch baseline the instance uses. This API is primarily used by the AWS-RunPatchBaseline Systems Manager document. 
  ##   body: JObject (required)
  var body_21626956 = newJObject()
  if body != nil:
    body_21626956 = body
  result = call_21626955.call(nil, nil, nil, nil, body_21626956)

var getDeployablePatchSnapshotForInstance* = Call_GetDeployablePatchSnapshotForInstance_21626942(
    name: "getDeployablePatchSnapshotForInstance", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetDeployablePatchSnapshotForInstance",
    validator: validate_GetDeployablePatchSnapshotForInstance_21626943, base: "/",
    makeUrl: url_GetDeployablePatchSnapshotForInstance_21626944,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDocument_21626957 = ref object of OpenApiRestCall_21625435
proc url_GetDocument_21626959(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDocument_21626958(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626960 = header.getOrDefault("X-Amz-Date")
  valid_21626960 = validateParameter(valid_21626960, JString, required = false,
                                   default = nil)
  if valid_21626960 != nil:
    section.add "X-Amz-Date", valid_21626960
  var valid_21626961 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626961 = validateParameter(valid_21626961, JString, required = false,
                                   default = nil)
  if valid_21626961 != nil:
    section.add "X-Amz-Security-Token", valid_21626961
  var valid_21626962 = header.getOrDefault("X-Amz-Target")
  valid_21626962 = validateParameter(valid_21626962, JString, required = true, default = newJString(
      "AmazonSSM.GetDocument"))
  if valid_21626962 != nil:
    section.add "X-Amz-Target", valid_21626962
  var valid_21626963 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626963 = validateParameter(valid_21626963, JString, required = false,
                                   default = nil)
  if valid_21626963 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626963
  var valid_21626964 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626964 = validateParameter(valid_21626964, JString, required = false,
                                   default = nil)
  if valid_21626964 != nil:
    section.add "X-Amz-Algorithm", valid_21626964
  var valid_21626965 = header.getOrDefault("X-Amz-Signature")
  valid_21626965 = validateParameter(valid_21626965, JString, required = false,
                                   default = nil)
  if valid_21626965 != nil:
    section.add "X-Amz-Signature", valid_21626965
  var valid_21626966 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626966 = validateParameter(valid_21626966, JString, required = false,
                                   default = nil)
  if valid_21626966 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626966
  var valid_21626967 = header.getOrDefault("X-Amz-Credential")
  valid_21626967 = validateParameter(valid_21626967, JString, required = false,
                                   default = nil)
  if valid_21626967 != nil:
    section.add "X-Amz-Credential", valid_21626967
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

proc call*(call_21626969: Call_GetDocument_21626957; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets the contents of the specified Systems Manager document.
  ## 
  let valid = call_21626969.validator(path, query, header, formData, body, _)
  let scheme = call_21626969.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626969.makeUrl(scheme.get, call_21626969.host, call_21626969.base,
                               call_21626969.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626969, uri, valid, _)

proc call*(call_21626970: Call_GetDocument_21626957; body: JsonNode): Recallable =
  ## getDocument
  ## Gets the contents of the specified Systems Manager document.
  ##   body: JObject (required)
  var body_21626971 = newJObject()
  if body != nil:
    body_21626971 = body
  result = call_21626970.call(nil, nil, nil, nil, body_21626971)

var getDocument* = Call_GetDocument_21626957(name: "getDocument",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetDocument",
    validator: validate_GetDocument_21626958, base: "/", makeUrl: url_GetDocument_21626959,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetInventory_21626972 = ref object of OpenApiRestCall_21625435
proc url_GetInventory_21626974(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetInventory_21626973(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626975 = header.getOrDefault("X-Amz-Date")
  valid_21626975 = validateParameter(valid_21626975, JString, required = false,
                                   default = nil)
  if valid_21626975 != nil:
    section.add "X-Amz-Date", valid_21626975
  var valid_21626976 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626976 = validateParameter(valid_21626976, JString, required = false,
                                   default = nil)
  if valid_21626976 != nil:
    section.add "X-Amz-Security-Token", valid_21626976
  var valid_21626977 = header.getOrDefault("X-Amz-Target")
  valid_21626977 = validateParameter(valid_21626977, JString, required = true, default = newJString(
      "AmazonSSM.GetInventory"))
  if valid_21626977 != nil:
    section.add "X-Amz-Target", valid_21626977
  var valid_21626978 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626978 = validateParameter(valid_21626978, JString, required = false,
                                   default = nil)
  if valid_21626978 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626978
  var valid_21626979 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626979 = validateParameter(valid_21626979, JString, required = false,
                                   default = nil)
  if valid_21626979 != nil:
    section.add "X-Amz-Algorithm", valid_21626979
  var valid_21626980 = header.getOrDefault("X-Amz-Signature")
  valid_21626980 = validateParameter(valid_21626980, JString, required = false,
                                   default = nil)
  if valid_21626980 != nil:
    section.add "X-Amz-Signature", valid_21626980
  var valid_21626981 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626981 = validateParameter(valid_21626981, JString, required = false,
                                   default = nil)
  if valid_21626981 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626981
  var valid_21626982 = header.getOrDefault("X-Amz-Credential")
  valid_21626982 = validateParameter(valid_21626982, JString, required = false,
                                   default = nil)
  if valid_21626982 != nil:
    section.add "X-Amz-Credential", valid_21626982
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

proc call*(call_21626984: Call_GetInventory_21626972; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Query inventory information.
  ## 
  let valid = call_21626984.validator(path, query, header, formData, body, _)
  let scheme = call_21626984.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626984.makeUrl(scheme.get, call_21626984.host, call_21626984.base,
                               call_21626984.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626984, uri, valid, _)

proc call*(call_21626985: Call_GetInventory_21626972; body: JsonNode): Recallable =
  ## getInventory
  ## Query inventory information.
  ##   body: JObject (required)
  var body_21626986 = newJObject()
  if body != nil:
    body_21626986 = body
  result = call_21626985.call(nil, nil, nil, nil, body_21626986)

var getInventory* = Call_GetInventory_21626972(name: "getInventory",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetInventory",
    validator: validate_GetInventory_21626973, base: "/", makeUrl: url_GetInventory_21626974,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetInventorySchema_21626987 = ref object of OpenApiRestCall_21625435
proc url_GetInventorySchema_21626989(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetInventorySchema_21626988(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626990 = header.getOrDefault("X-Amz-Date")
  valid_21626990 = validateParameter(valid_21626990, JString, required = false,
                                   default = nil)
  if valid_21626990 != nil:
    section.add "X-Amz-Date", valid_21626990
  var valid_21626991 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626991 = validateParameter(valid_21626991, JString, required = false,
                                   default = nil)
  if valid_21626991 != nil:
    section.add "X-Amz-Security-Token", valid_21626991
  var valid_21626992 = header.getOrDefault("X-Amz-Target")
  valid_21626992 = validateParameter(valid_21626992, JString, required = true, default = newJString(
      "AmazonSSM.GetInventorySchema"))
  if valid_21626992 != nil:
    section.add "X-Amz-Target", valid_21626992
  var valid_21626993 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626993 = validateParameter(valid_21626993, JString, required = false,
                                   default = nil)
  if valid_21626993 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626993
  var valid_21626994 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626994 = validateParameter(valid_21626994, JString, required = false,
                                   default = nil)
  if valid_21626994 != nil:
    section.add "X-Amz-Algorithm", valid_21626994
  var valid_21626995 = header.getOrDefault("X-Amz-Signature")
  valid_21626995 = validateParameter(valid_21626995, JString, required = false,
                                   default = nil)
  if valid_21626995 != nil:
    section.add "X-Amz-Signature", valid_21626995
  var valid_21626996 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626996 = validateParameter(valid_21626996, JString, required = false,
                                   default = nil)
  if valid_21626996 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626996
  var valid_21626997 = header.getOrDefault("X-Amz-Credential")
  valid_21626997 = validateParameter(valid_21626997, JString, required = false,
                                   default = nil)
  if valid_21626997 != nil:
    section.add "X-Amz-Credential", valid_21626997
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

proc call*(call_21626999: Call_GetInventorySchema_21626987; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Return a list of inventory type names for the account, or return a list of attribute names for a specific Inventory item type. 
  ## 
  let valid = call_21626999.validator(path, query, header, formData, body, _)
  let scheme = call_21626999.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626999.makeUrl(scheme.get, call_21626999.host, call_21626999.base,
                               call_21626999.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626999, uri, valid, _)

proc call*(call_21627000: Call_GetInventorySchema_21626987; body: JsonNode): Recallable =
  ## getInventorySchema
  ## Return a list of inventory type names for the account, or return a list of attribute names for a specific Inventory item type. 
  ##   body: JObject (required)
  var body_21627001 = newJObject()
  if body != nil:
    body_21627001 = body
  result = call_21627000.call(nil, nil, nil, nil, body_21627001)

var getInventorySchema* = Call_GetInventorySchema_21626987(
    name: "getInventorySchema", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetInventorySchema",
    validator: validate_GetInventorySchema_21626988, base: "/",
    makeUrl: url_GetInventorySchema_21626989, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMaintenanceWindow_21627002 = ref object of OpenApiRestCall_21625435
proc url_GetMaintenanceWindow_21627004(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetMaintenanceWindow_21627003(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627005 = header.getOrDefault("X-Amz-Date")
  valid_21627005 = validateParameter(valid_21627005, JString, required = false,
                                   default = nil)
  if valid_21627005 != nil:
    section.add "X-Amz-Date", valid_21627005
  var valid_21627006 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627006 = validateParameter(valid_21627006, JString, required = false,
                                   default = nil)
  if valid_21627006 != nil:
    section.add "X-Amz-Security-Token", valid_21627006
  var valid_21627007 = header.getOrDefault("X-Amz-Target")
  valid_21627007 = validateParameter(valid_21627007, JString, required = true, default = newJString(
      "AmazonSSM.GetMaintenanceWindow"))
  if valid_21627007 != nil:
    section.add "X-Amz-Target", valid_21627007
  var valid_21627008 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627008 = validateParameter(valid_21627008, JString, required = false,
                                   default = nil)
  if valid_21627008 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627008
  var valid_21627009 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627009 = validateParameter(valid_21627009, JString, required = false,
                                   default = nil)
  if valid_21627009 != nil:
    section.add "X-Amz-Algorithm", valid_21627009
  var valid_21627010 = header.getOrDefault("X-Amz-Signature")
  valid_21627010 = validateParameter(valid_21627010, JString, required = false,
                                   default = nil)
  if valid_21627010 != nil:
    section.add "X-Amz-Signature", valid_21627010
  var valid_21627011 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627011 = validateParameter(valid_21627011, JString, required = false,
                                   default = nil)
  if valid_21627011 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627011
  var valid_21627012 = header.getOrDefault("X-Amz-Credential")
  valid_21627012 = validateParameter(valid_21627012, JString, required = false,
                                   default = nil)
  if valid_21627012 != nil:
    section.add "X-Amz-Credential", valid_21627012
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

proc call*(call_21627014: Call_GetMaintenanceWindow_21627002; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves a maintenance window.
  ## 
  let valid = call_21627014.validator(path, query, header, formData, body, _)
  let scheme = call_21627014.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627014.makeUrl(scheme.get, call_21627014.host, call_21627014.base,
                               call_21627014.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627014, uri, valid, _)

proc call*(call_21627015: Call_GetMaintenanceWindow_21627002; body: JsonNode): Recallable =
  ## getMaintenanceWindow
  ## Retrieves a maintenance window.
  ##   body: JObject (required)
  var body_21627016 = newJObject()
  if body != nil:
    body_21627016 = body
  result = call_21627015.call(nil, nil, nil, nil, body_21627016)

var getMaintenanceWindow* = Call_GetMaintenanceWindow_21627002(
    name: "getMaintenanceWindow", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetMaintenanceWindow",
    validator: validate_GetMaintenanceWindow_21627003, base: "/",
    makeUrl: url_GetMaintenanceWindow_21627004,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMaintenanceWindowExecution_21627017 = ref object of OpenApiRestCall_21625435
proc url_GetMaintenanceWindowExecution_21627019(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetMaintenanceWindowExecution_21627018(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21627020 = header.getOrDefault("X-Amz-Date")
  valid_21627020 = validateParameter(valid_21627020, JString, required = false,
                                   default = nil)
  if valid_21627020 != nil:
    section.add "X-Amz-Date", valid_21627020
  var valid_21627021 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627021 = validateParameter(valid_21627021, JString, required = false,
                                   default = nil)
  if valid_21627021 != nil:
    section.add "X-Amz-Security-Token", valid_21627021
  var valid_21627022 = header.getOrDefault("X-Amz-Target")
  valid_21627022 = validateParameter(valid_21627022, JString, required = true, default = newJString(
      "AmazonSSM.GetMaintenanceWindowExecution"))
  if valid_21627022 != nil:
    section.add "X-Amz-Target", valid_21627022
  var valid_21627023 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627023 = validateParameter(valid_21627023, JString, required = false,
                                   default = nil)
  if valid_21627023 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627023
  var valid_21627024 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627024 = validateParameter(valid_21627024, JString, required = false,
                                   default = nil)
  if valid_21627024 != nil:
    section.add "X-Amz-Algorithm", valid_21627024
  var valid_21627025 = header.getOrDefault("X-Amz-Signature")
  valid_21627025 = validateParameter(valid_21627025, JString, required = false,
                                   default = nil)
  if valid_21627025 != nil:
    section.add "X-Amz-Signature", valid_21627025
  var valid_21627026 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627026 = validateParameter(valid_21627026, JString, required = false,
                                   default = nil)
  if valid_21627026 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627026
  var valid_21627027 = header.getOrDefault("X-Amz-Credential")
  valid_21627027 = validateParameter(valid_21627027, JString, required = false,
                                   default = nil)
  if valid_21627027 != nil:
    section.add "X-Amz-Credential", valid_21627027
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

proc call*(call_21627029: Call_GetMaintenanceWindowExecution_21627017;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves details about a specific a maintenance window execution.
  ## 
  let valid = call_21627029.validator(path, query, header, formData, body, _)
  let scheme = call_21627029.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627029.makeUrl(scheme.get, call_21627029.host, call_21627029.base,
                               call_21627029.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627029, uri, valid, _)

proc call*(call_21627030: Call_GetMaintenanceWindowExecution_21627017;
          body: JsonNode): Recallable =
  ## getMaintenanceWindowExecution
  ## Retrieves details about a specific a maintenance window execution.
  ##   body: JObject (required)
  var body_21627031 = newJObject()
  if body != nil:
    body_21627031 = body
  result = call_21627030.call(nil, nil, nil, nil, body_21627031)

var getMaintenanceWindowExecution* = Call_GetMaintenanceWindowExecution_21627017(
    name: "getMaintenanceWindowExecution", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetMaintenanceWindowExecution",
    validator: validate_GetMaintenanceWindowExecution_21627018, base: "/",
    makeUrl: url_GetMaintenanceWindowExecution_21627019,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMaintenanceWindowExecutionTask_21627032 = ref object of OpenApiRestCall_21625435
proc url_GetMaintenanceWindowExecutionTask_21627034(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetMaintenanceWindowExecutionTask_21627033(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21627035 = header.getOrDefault("X-Amz-Date")
  valid_21627035 = validateParameter(valid_21627035, JString, required = false,
                                   default = nil)
  if valid_21627035 != nil:
    section.add "X-Amz-Date", valid_21627035
  var valid_21627036 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627036 = validateParameter(valid_21627036, JString, required = false,
                                   default = nil)
  if valid_21627036 != nil:
    section.add "X-Amz-Security-Token", valid_21627036
  var valid_21627037 = header.getOrDefault("X-Amz-Target")
  valid_21627037 = validateParameter(valid_21627037, JString, required = true, default = newJString(
      "AmazonSSM.GetMaintenanceWindowExecutionTask"))
  if valid_21627037 != nil:
    section.add "X-Amz-Target", valid_21627037
  var valid_21627038 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627038 = validateParameter(valid_21627038, JString, required = false,
                                   default = nil)
  if valid_21627038 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627038
  var valid_21627039 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627039 = validateParameter(valid_21627039, JString, required = false,
                                   default = nil)
  if valid_21627039 != nil:
    section.add "X-Amz-Algorithm", valid_21627039
  var valid_21627040 = header.getOrDefault("X-Amz-Signature")
  valid_21627040 = validateParameter(valid_21627040, JString, required = false,
                                   default = nil)
  if valid_21627040 != nil:
    section.add "X-Amz-Signature", valid_21627040
  var valid_21627041 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627041 = validateParameter(valid_21627041, JString, required = false,
                                   default = nil)
  if valid_21627041 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627041
  var valid_21627042 = header.getOrDefault("X-Amz-Credential")
  valid_21627042 = validateParameter(valid_21627042, JString, required = false,
                                   default = nil)
  if valid_21627042 != nil:
    section.add "X-Amz-Credential", valid_21627042
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

proc call*(call_21627044: Call_GetMaintenanceWindowExecutionTask_21627032;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves the details about a specific task run as part of a maintenance window execution.
  ## 
  let valid = call_21627044.validator(path, query, header, formData, body, _)
  let scheme = call_21627044.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627044.makeUrl(scheme.get, call_21627044.host, call_21627044.base,
                               call_21627044.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627044, uri, valid, _)

proc call*(call_21627045: Call_GetMaintenanceWindowExecutionTask_21627032;
          body: JsonNode): Recallable =
  ## getMaintenanceWindowExecutionTask
  ## Retrieves the details about a specific task run as part of a maintenance window execution.
  ##   body: JObject (required)
  var body_21627046 = newJObject()
  if body != nil:
    body_21627046 = body
  result = call_21627045.call(nil, nil, nil, nil, body_21627046)

var getMaintenanceWindowExecutionTask* = Call_GetMaintenanceWindowExecutionTask_21627032(
    name: "getMaintenanceWindowExecutionTask", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetMaintenanceWindowExecutionTask",
    validator: validate_GetMaintenanceWindowExecutionTask_21627033, base: "/",
    makeUrl: url_GetMaintenanceWindowExecutionTask_21627034,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMaintenanceWindowExecutionTaskInvocation_21627047 = ref object of OpenApiRestCall_21625435
proc url_GetMaintenanceWindowExecutionTaskInvocation_21627049(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetMaintenanceWindowExecutionTaskInvocation_21627048(
    path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21627050 = header.getOrDefault("X-Amz-Date")
  valid_21627050 = validateParameter(valid_21627050, JString, required = false,
                                   default = nil)
  if valid_21627050 != nil:
    section.add "X-Amz-Date", valid_21627050
  var valid_21627051 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627051 = validateParameter(valid_21627051, JString, required = false,
                                   default = nil)
  if valid_21627051 != nil:
    section.add "X-Amz-Security-Token", valid_21627051
  var valid_21627052 = header.getOrDefault("X-Amz-Target")
  valid_21627052 = validateParameter(valid_21627052, JString, required = true, default = newJString(
      "AmazonSSM.GetMaintenanceWindowExecutionTaskInvocation"))
  if valid_21627052 != nil:
    section.add "X-Amz-Target", valid_21627052
  var valid_21627053 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627053 = validateParameter(valid_21627053, JString, required = false,
                                   default = nil)
  if valid_21627053 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627053
  var valid_21627054 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627054 = validateParameter(valid_21627054, JString, required = false,
                                   default = nil)
  if valid_21627054 != nil:
    section.add "X-Amz-Algorithm", valid_21627054
  var valid_21627055 = header.getOrDefault("X-Amz-Signature")
  valid_21627055 = validateParameter(valid_21627055, JString, required = false,
                                   default = nil)
  if valid_21627055 != nil:
    section.add "X-Amz-Signature", valid_21627055
  var valid_21627056 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627056 = validateParameter(valid_21627056, JString, required = false,
                                   default = nil)
  if valid_21627056 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627056
  var valid_21627057 = header.getOrDefault("X-Amz-Credential")
  valid_21627057 = validateParameter(valid_21627057, JString, required = false,
                                   default = nil)
  if valid_21627057 != nil:
    section.add "X-Amz-Credential", valid_21627057
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

proc call*(call_21627059: Call_GetMaintenanceWindowExecutionTaskInvocation_21627047;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves information about a specific task running on a specific target.
  ## 
  let valid = call_21627059.validator(path, query, header, formData, body, _)
  let scheme = call_21627059.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627059.makeUrl(scheme.get, call_21627059.host, call_21627059.base,
                               call_21627059.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627059, uri, valid, _)

proc call*(call_21627060: Call_GetMaintenanceWindowExecutionTaskInvocation_21627047;
          body: JsonNode): Recallable =
  ## getMaintenanceWindowExecutionTaskInvocation
  ## Retrieves information about a specific task running on a specific target.
  ##   body: JObject (required)
  var body_21627061 = newJObject()
  if body != nil:
    body_21627061 = body
  result = call_21627060.call(nil, nil, nil, nil, body_21627061)

var getMaintenanceWindowExecutionTaskInvocation* = Call_GetMaintenanceWindowExecutionTaskInvocation_21627047(
    name: "getMaintenanceWindowExecutionTaskInvocation",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com", route: "/#X-Amz-Target=AmazonSSM.GetMaintenanceWindowExecutionTaskInvocation",
    validator: validate_GetMaintenanceWindowExecutionTaskInvocation_21627048,
    base: "/", makeUrl: url_GetMaintenanceWindowExecutionTaskInvocation_21627049,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMaintenanceWindowTask_21627062 = ref object of OpenApiRestCall_21625435
proc url_GetMaintenanceWindowTask_21627064(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetMaintenanceWindowTask_21627063(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627065 = header.getOrDefault("X-Amz-Date")
  valid_21627065 = validateParameter(valid_21627065, JString, required = false,
                                   default = nil)
  if valid_21627065 != nil:
    section.add "X-Amz-Date", valid_21627065
  var valid_21627066 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627066 = validateParameter(valid_21627066, JString, required = false,
                                   default = nil)
  if valid_21627066 != nil:
    section.add "X-Amz-Security-Token", valid_21627066
  var valid_21627067 = header.getOrDefault("X-Amz-Target")
  valid_21627067 = validateParameter(valid_21627067, JString, required = true, default = newJString(
      "AmazonSSM.GetMaintenanceWindowTask"))
  if valid_21627067 != nil:
    section.add "X-Amz-Target", valid_21627067
  var valid_21627068 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627068 = validateParameter(valid_21627068, JString, required = false,
                                   default = nil)
  if valid_21627068 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627068
  var valid_21627069 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627069 = validateParameter(valid_21627069, JString, required = false,
                                   default = nil)
  if valid_21627069 != nil:
    section.add "X-Amz-Algorithm", valid_21627069
  var valid_21627070 = header.getOrDefault("X-Amz-Signature")
  valid_21627070 = validateParameter(valid_21627070, JString, required = false,
                                   default = nil)
  if valid_21627070 != nil:
    section.add "X-Amz-Signature", valid_21627070
  var valid_21627071 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627071 = validateParameter(valid_21627071, JString, required = false,
                                   default = nil)
  if valid_21627071 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627071
  var valid_21627072 = header.getOrDefault("X-Amz-Credential")
  valid_21627072 = validateParameter(valid_21627072, JString, required = false,
                                   default = nil)
  if valid_21627072 != nil:
    section.add "X-Amz-Credential", valid_21627072
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

proc call*(call_21627074: Call_GetMaintenanceWindowTask_21627062;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the tasks in a maintenance window.
  ## 
  let valid = call_21627074.validator(path, query, header, formData, body, _)
  let scheme = call_21627074.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627074.makeUrl(scheme.get, call_21627074.host, call_21627074.base,
                               call_21627074.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627074, uri, valid, _)

proc call*(call_21627075: Call_GetMaintenanceWindowTask_21627062; body: JsonNode): Recallable =
  ## getMaintenanceWindowTask
  ## Lists the tasks in a maintenance window.
  ##   body: JObject (required)
  var body_21627076 = newJObject()
  if body != nil:
    body_21627076 = body
  result = call_21627075.call(nil, nil, nil, nil, body_21627076)

var getMaintenanceWindowTask* = Call_GetMaintenanceWindowTask_21627062(
    name: "getMaintenanceWindowTask", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetMaintenanceWindowTask",
    validator: validate_GetMaintenanceWindowTask_21627063, base: "/",
    makeUrl: url_GetMaintenanceWindowTask_21627064,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetOpsItem_21627077 = ref object of OpenApiRestCall_21625435
proc url_GetOpsItem_21627079(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetOpsItem_21627078(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627080 = header.getOrDefault("X-Amz-Date")
  valid_21627080 = validateParameter(valid_21627080, JString, required = false,
                                   default = nil)
  if valid_21627080 != nil:
    section.add "X-Amz-Date", valid_21627080
  var valid_21627081 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627081 = validateParameter(valid_21627081, JString, required = false,
                                   default = nil)
  if valid_21627081 != nil:
    section.add "X-Amz-Security-Token", valid_21627081
  var valid_21627082 = header.getOrDefault("X-Amz-Target")
  valid_21627082 = validateParameter(valid_21627082, JString, required = true,
                                   default = newJString("AmazonSSM.GetOpsItem"))
  if valid_21627082 != nil:
    section.add "X-Amz-Target", valid_21627082
  var valid_21627083 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627083 = validateParameter(valid_21627083, JString, required = false,
                                   default = nil)
  if valid_21627083 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627083
  var valid_21627084 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627084 = validateParameter(valid_21627084, JString, required = false,
                                   default = nil)
  if valid_21627084 != nil:
    section.add "X-Amz-Algorithm", valid_21627084
  var valid_21627085 = header.getOrDefault("X-Amz-Signature")
  valid_21627085 = validateParameter(valid_21627085, JString, required = false,
                                   default = nil)
  if valid_21627085 != nil:
    section.add "X-Amz-Signature", valid_21627085
  var valid_21627086 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627086 = validateParameter(valid_21627086, JString, required = false,
                                   default = nil)
  if valid_21627086 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627086
  var valid_21627087 = header.getOrDefault("X-Amz-Credential")
  valid_21627087 = validateParameter(valid_21627087, JString, required = false,
                                   default = nil)
  if valid_21627087 != nil:
    section.add "X-Amz-Credential", valid_21627087
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

proc call*(call_21627089: Call_GetOpsItem_21627077; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Get information about an OpsItem by using the ID. You must have permission in AWS Identity and Access Management (IAM) to view information about an OpsItem. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter-getting-started.html">Getting Started with OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>.</p> <p>Operations engineers and IT professionals use OpsCenter to view, investigate, and remediate operational issues impacting the performance and health of their AWS resources. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter.html">AWS Systems Manager OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>. </p>
  ## 
  let valid = call_21627089.validator(path, query, header, formData, body, _)
  let scheme = call_21627089.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627089.makeUrl(scheme.get, call_21627089.host, call_21627089.base,
                               call_21627089.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627089, uri, valid, _)

proc call*(call_21627090: Call_GetOpsItem_21627077; body: JsonNode): Recallable =
  ## getOpsItem
  ## <p>Get information about an OpsItem by using the ID. You must have permission in AWS Identity and Access Management (IAM) to view information about an OpsItem. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter-getting-started.html">Getting Started with OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>.</p> <p>Operations engineers and IT professionals use OpsCenter to view, investigate, and remediate operational issues impacting the performance and health of their AWS resources. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter.html">AWS Systems Manager OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>. </p>
  ##   body: JObject (required)
  var body_21627091 = newJObject()
  if body != nil:
    body_21627091 = body
  result = call_21627090.call(nil, nil, nil, nil, body_21627091)

var getOpsItem* = Call_GetOpsItem_21627077(name: "getOpsItem",
                                        meth: HttpMethod.HttpPost,
                                        host: "ssm.amazonaws.com", route: "/#X-Amz-Target=AmazonSSM.GetOpsItem",
                                        validator: validate_GetOpsItem_21627078,
                                        base: "/", makeUrl: url_GetOpsItem_21627079,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetOpsSummary_21627092 = ref object of OpenApiRestCall_21625435
proc url_GetOpsSummary_21627094(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetOpsSummary_21627093(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21627095 = header.getOrDefault("X-Amz-Date")
  valid_21627095 = validateParameter(valid_21627095, JString, required = false,
                                   default = nil)
  if valid_21627095 != nil:
    section.add "X-Amz-Date", valid_21627095
  var valid_21627096 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627096 = validateParameter(valid_21627096, JString, required = false,
                                   default = nil)
  if valid_21627096 != nil:
    section.add "X-Amz-Security-Token", valid_21627096
  var valid_21627097 = header.getOrDefault("X-Amz-Target")
  valid_21627097 = validateParameter(valid_21627097, JString, required = true, default = newJString(
      "AmazonSSM.GetOpsSummary"))
  if valid_21627097 != nil:
    section.add "X-Amz-Target", valid_21627097
  var valid_21627098 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627098 = validateParameter(valid_21627098, JString, required = false,
                                   default = nil)
  if valid_21627098 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627098
  var valid_21627099 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627099 = validateParameter(valid_21627099, JString, required = false,
                                   default = nil)
  if valid_21627099 != nil:
    section.add "X-Amz-Algorithm", valid_21627099
  var valid_21627100 = header.getOrDefault("X-Amz-Signature")
  valid_21627100 = validateParameter(valid_21627100, JString, required = false,
                                   default = nil)
  if valid_21627100 != nil:
    section.add "X-Amz-Signature", valid_21627100
  var valid_21627101 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627101 = validateParameter(valid_21627101, JString, required = false,
                                   default = nil)
  if valid_21627101 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627101
  var valid_21627102 = header.getOrDefault("X-Amz-Credential")
  valid_21627102 = validateParameter(valid_21627102, JString, required = false,
                                   default = nil)
  if valid_21627102 != nil:
    section.add "X-Amz-Credential", valid_21627102
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

proc call*(call_21627104: Call_GetOpsSummary_21627092; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## View a summary of OpsItems based on specified filters and aggregators.
  ## 
  let valid = call_21627104.validator(path, query, header, formData, body, _)
  let scheme = call_21627104.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627104.makeUrl(scheme.get, call_21627104.host, call_21627104.base,
                               call_21627104.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627104, uri, valid, _)

proc call*(call_21627105: Call_GetOpsSummary_21627092; body: JsonNode): Recallable =
  ## getOpsSummary
  ## View a summary of OpsItems based on specified filters and aggregators.
  ##   body: JObject (required)
  var body_21627106 = newJObject()
  if body != nil:
    body_21627106 = body
  result = call_21627105.call(nil, nil, nil, nil, body_21627106)

var getOpsSummary* = Call_GetOpsSummary_21627092(name: "getOpsSummary",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetOpsSummary",
    validator: validate_GetOpsSummary_21627093, base: "/",
    makeUrl: url_GetOpsSummary_21627094, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetParameter_21627107 = ref object of OpenApiRestCall_21625435
proc url_GetParameter_21627109(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetParameter_21627108(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21627110 = header.getOrDefault("X-Amz-Date")
  valid_21627110 = validateParameter(valid_21627110, JString, required = false,
                                   default = nil)
  if valid_21627110 != nil:
    section.add "X-Amz-Date", valid_21627110
  var valid_21627111 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627111 = validateParameter(valid_21627111, JString, required = false,
                                   default = nil)
  if valid_21627111 != nil:
    section.add "X-Amz-Security-Token", valid_21627111
  var valid_21627112 = header.getOrDefault("X-Amz-Target")
  valid_21627112 = validateParameter(valid_21627112, JString, required = true, default = newJString(
      "AmazonSSM.GetParameter"))
  if valid_21627112 != nil:
    section.add "X-Amz-Target", valid_21627112
  var valid_21627113 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627113 = validateParameter(valid_21627113, JString, required = false,
                                   default = nil)
  if valid_21627113 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627113
  var valid_21627114 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627114 = validateParameter(valid_21627114, JString, required = false,
                                   default = nil)
  if valid_21627114 != nil:
    section.add "X-Amz-Algorithm", valid_21627114
  var valid_21627115 = header.getOrDefault("X-Amz-Signature")
  valid_21627115 = validateParameter(valid_21627115, JString, required = false,
                                   default = nil)
  if valid_21627115 != nil:
    section.add "X-Amz-Signature", valid_21627115
  var valid_21627116 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627116 = validateParameter(valid_21627116, JString, required = false,
                                   default = nil)
  if valid_21627116 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627116
  var valid_21627117 = header.getOrDefault("X-Amz-Credential")
  valid_21627117 = validateParameter(valid_21627117, JString, required = false,
                                   default = nil)
  if valid_21627117 != nil:
    section.add "X-Amz-Credential", valid_21627117
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

proc call*(call_21627119: Call_GetParameter_21627107; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Get information about a parameter by using the parameter name. Don't confuse this API action with the <a>GetParameters</a> API action.
  ## 
  let valid = call_21627119.validator(path, query, header, formData, body, _)
  let scheme = call_21627119.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627119.makeUrl(scheme.get, call_21627119.host, call_21627119.base,
                               call_21627119.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627119, uri, valid, _)

proc call*(call_21627120: Call_GetParameter_21627107; body: JsonNode): Recallable =
  ## getParameter
  ## Get information about a parameter by using the parameter name. Don't confuse this API action with the <a>GetParameters</a> API action.
  ##   body: JObject (required)
  var body_21627121 = newJObject()
  if body != nil:
    body_21627121 = body
  result = call_21627120.call(nil, nil, nil, nil, body_21627121)

var getParameter* = Call_GetParameter_21627107(name: "getParameter",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetParameter",
    validator: validate_GetParameter_21627108, base: "/", makeUrl: url_GetParameter_21627109,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetParameterHistory_21627122 = ref object of OpenApiRestCall_21625435
proc url_GetParameterHistory_21627124(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetParameterHistory_21627123(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627125 = query.getOrDefault("NextToken")
  valid_21627125 = validateParameter(valid_21627125, JString, required = false,
                                   default = nil)
  if valid_21627125 != nil:
    section.add "NextToken", valid_21627125
  var valid_21627126 = query.getOrDefault("MaxResults")
  valid_21627126 = validateParameter(valid_21627126, JString, required = false,
                                   default = nil)
  if valid_21627126 != nil:
    section.add "MaxResults", valid_21627126
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627127 = header.getOrDefault("X-Amz-Date")
  valid_21627127 = validateParameter(valid_21627127, JString, required = false,
                                   default = nil)
  if valid_21627127 != nil:
    section.add "X-Amz-Date", valid_21627127
  var valid_21627128 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627128 = validateParameter(valid_21627128, JString, required = false,
                                   default = nil)
  if valid_21627128 != nil:
    section.add "X-Amz-Security-Token", valid_21627128
  var valid_21627129 = header.getOrDefault("X-Amz-Target")
  valid_21627129 = validateParameter(valid_21627129, JString, required = true, default = newJString(
      "AmazonSSM.GetParameterHistory"))
  if valid_21627129 != nil:
    section.add "X-Amz-Target", valid_21627129
  var valid_21627130 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627130 = validateParameter(valid_21627130, JString, required = false,
                                   default = nil)
  if valid_21627130 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627130
  var valid_21627131 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627131 = validateParameter(valid_21627131, JString, required = false,
                                   default = nil)
  if valid_21627131 != nil:
    section.add "X-Amz-Algorithm", valid_21627131
  var valid_21627132 = header.getOrDefault("X-Amz-Signature")
  valid_21627132 = validateParameter(valid_21627132, JString, required = false,
                                   default = nil)
  if valid_21627132 != nil:
    section.add "X-Amz-Signature", valid_21627132
  var valid_21627133 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627133 = validateParameter(valid_21627133, JString, required = false,
                                   default = nil)
  if valid_21627133 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627133
  var valid_21627134 = header.getOrDefault("X-Amz-Credential")
  valid_21627134 = validateParameter(valid_21627134, JString, required = false,
                                   default = nil)
  if valid_21627134 != nil:
    section.add "X-Amz-Credential", valid_21627134
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

proc call*(call_21627136: Call_GetParameterHistory_21627122; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Query a list of all parameters used by the AWS account.
  ## 
  let valid = call_21627136.validator(path, query, header, formData, body, _)
  let scheme = call_21627136.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627136.makeUrl(scheme.get, call_21627136.host, call_21627136.base,
                               call_21627136.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627136, uri, valid, _)

proc call*(call_21627137: Call_GetParameterHistory_21627122; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## getParameterHistory
  ## Query a list of all parameters used by the AWS account.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_21627138 = newJObject()
  var body_21627139 = newJObject()
  add(query_21627138, "NextToken", newJString(NextToken))
  if body != nil:
    body_21627139 = body
  add(query_21627138, "MaxResults", newJString(MaxResults))
  result = call_21627137.call(nil, query_21627138, nil, nil, body_21627139)

var getParameterHistory* = Call_GetParameterHistory_21627122(
    name: "getParameterHistory", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetParameterHistory",
    validator: validate_GetParameterHistory_21627123, base: "/",
    makeUrl: url_GetParameterHistory_21627124,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetParameters_21627140 = ref object of OpenApiRestCall_21625435
proc url_GetParameters_21627142(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetParameters_21627141(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21627143 = header.getOrDefault("X-Amz-Date")
  valid_21627143 = validateParameter(valid_21627143, JString, required = false,
                                   default = nil)
  if valid_21627143 != nil:
    section.add "X-Amz-Date", valid_21627143
  var valid_21627144 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627144 = validateParameter(valid_21627144, JString, required = false,
                                   default = nil)
  if valid_21627144 != nil:
    section.add "X-Amz-Security-Token", valid_21627144
  var valid_21627145 = header.getOrDefault("X-Amz-Target")
  valid_21627145 = validateParameter(valid_21627145, JString, required = true, default = newJString(
      "AmazonSSM.GetParameters"))
  if valid_21627145 != nil:
    section.add "X-Amz-Target", valid_21627145
  var valid_21627146 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627146 = validateParameter(valid_21627146, JString, required = false,
                                   default = nil)
  if valid_21627146 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627146
  var valid_21627147 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627147 = validateParameter(valid_21627147, JString, required = false,
                                   default = nil)
  if valid_21627147 != nil:
    section.add "X-Amz-Algorithm", valid_21627147
  var valid_21627148 = header.getOrDefault("X-Amz-Signature")
  valid_21627148 = validateParameter(valid_21627148, JString, required = false,
                                   default = nil)
  if valid_21627148 != nil:
    section.add "X-Amz-Signature", valid_21627148
  var valid_21627149 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627149 = validateParameter(valid_21627149, JString, required = false,
                                   default = nil)
  if valid_21627149 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627149
  var valid_21627150 = header.getOrDefault("X-Amz-Credential")
  valid_21627150 = validateParameter(valid_21627150, JString, required = false,
                                   default = nil)
  if valid_21627150 != nil:
    section.add "X-Amz-Credential", valid_21627150
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

proc call*(call_21627152: Call_GetParameters_21627140; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Get details of a parameter. Don't confuse this API action with the <a>GetParameter</a> API action.
  ## 
  let valid = call_21627152.validator(path, query, header, formData, body, _)
  let scheme = call_21627152.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627152.makeUrl(scheme.get, call_21627152.host, call_21627152.base,
                               call_21627152.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627152, uri, valid, _)

proc call*(call_21627153: Call_GetParameters_21627140; body: JsonNode): Recallable =
  ## getParameters
  ## Get details of a parameter. Don't confuse this API action with the <a>GetParameter</a> API action.
  ##   body: JObject (required)
  var body_21627154 = newJObject()
  if body != nil:
    body_21627154 = body
  result = call_21627153.call(nil, nil, nil, nil, body_21627154)

var getParameters* = Call_GetParameters_21627140(name: "getParameters",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetParameters",
    validator: validate_GetParameters_21627141, base: "/",
    makeUrl: url_GetParameters_21627142, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetParametersByPath_21627155 = ref object of OpenApiRestCall_21625435
proc url_GetParametersByPath_21627157(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetParametersByPath_21627156(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Retrieve information about one or more parameters in a specific hierarchy. </p> <note> <p>Request results are returned on a best-effort basis. If you specify <code>MaxResults</code> in the request, the response includes information up to the limit specified. The number of items returned, however, can be between zero and the value of <code>MaxResults</code>. If the service reaches an internal limit while processing the results, it stops the operation and returns the matching values up to that point and a <code>NextToken</code>. You can specify the <code>NextToken</code> in a subsequent call to get the next set of results.</p> </note>
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
  var valid_21627158 = query.getOrDefault("NextToken")
  valid_21627158 = validateParameter(valid_21627158, JString, required = false,
                                   default = nil)
  if valid_21627158 != nil:
    section.add "NextToken", valid_21627158
  var valid_21627159 = query.getOrDefault("MaxResults")
  valid_21627159 = validateParameter(valid_21627159, JString, required = false,
                                   default = nil)
  if valid_21627159 != nil:
    section.add "MaxResults", valid_21627159
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627160 = header.getOrDefault("X-Amz-Date")
  valid_21627160 = validateParameter(valid_21627160, JString, required = false,
                                   default = nil)
  if valid_21627160 != nil:
    section.add "X-Amz-Date", valid_21627160
  var valid_21627161 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627161 = validateParameter(valid_21627161, JString, required = false,
                                   default = nil)
  if valid_21627161 != nil:
    section.add "X-Amz-Security-Token", valid_21627161
  var valid_21627162 = header.getOrDefault("X-Amz-Target")
  valid_21627162 = validateParameter(valid_21627162, JString, required = true, default = newJString(
      "AmazonSSM.GetParametersByPath"))
  if valid_21627162 != nil:
    section.add "X-Amz-Target", valid_21627162
  var valid_21627163 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627163 = validateParameter(valid_21627163, JString, required = false,
                                   default = nil)
  if valid_21627163 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627163
  var valid_21627164 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627164 = validateParameter(valid_21627164, JString, required = false,
                                   default = nil)
  if valid_21627164 != nil:
    section.add "X-Amz-Algorithm", valid_21627164
  var valid_21627165 = header.getOrDefault("X-Amz-Signature")
  valid_21627165 = validateParameter(valid_21627165, JString, required = false,
                                   default = nil)
  if valid_21627165 != nil:
    section.add "X-Amz-Signature", valid_21627165
  var valid_21627166 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627166 = validateParameter(valid_21627166, JString, required = false,
                                   default = nil)
  if valid_21627166 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627166
  var valid_21627167 = header.getOrDefault("X-Amz-Credential")
  valid_21627167 = validateParameter(valid_21627167, JString, required = false,
                                   default = nil)
  if valid_21627167 != nil:
    section.add "X-Amz-Credential", valid_21627167
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

proc call*(call_21627169: Call_GetParametersByPath_21627155; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Retrieve information about one or more parameters in a specific hierarchy. </p> <note> <p>Request results are returned on a best-effort basis. If you specify <code>MaxResults</code> in the request, the response includes information up to the limit specified. The number of items returned, however, can be between zero and the value of <code>MaxResults</code>. If the service reaches an internal limit while processing the results, it stops the operation and returns the matching values up to that point and a <code>NextToken</code>. You can specify the <code>NextToken</code> in a subsequent call to get the next set of results.</p> </note>
  ## 
  let valid = call_21627169.validator(path, query, header, formData, body, _)
  let scheme = call_21627169.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627169.makeUrl(scheme.get, call_21627169.host, call_21627169.base,
                               call_21627169.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627169, uri, valid, _)

proc call*(call_21627170: Call_GetParametersByPath_21627155; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## getParametersByPath
  ## <p>Retrieve information about one or more parameters in a specific hierarchy. </p> <note> <p>Request results are returned on a best-effort basis. If you specify <code>MaxResults</code> in the request, the response includes information up to the limit specified. The number of items returned, however, can be between zero and the value of <code>MaxResults</code>. If the service reaches an internal limit while processing the results, it stops the operation and returns the matching values up to that point and a <code>NextToken</code>. You can specify the <code>NextToken</code> in a subsequent call to get the next set of results.</p> </note>
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_21627171 = newJObject()
  var body_21627172 = newJObject()
  add(query_21627171, "NextToken", newJString(NextToken))
  if body != nil:
    body_21627172 = body
  add(query_21627171, "MaxResults", newJString(MaxResults))
  result = call_21627170.call(nil, query_21627171, nil, nil, body_21627172)

var getParametersByPath* = Call_GetParametersByPath_21627155(
    name: "getParametersByPath", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetParametersByPath",
    validator: validate_GetParametersByPath_21627156, base: "/",
    makeUrl: url_GetParametersByPath_21627157,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPatchBaseline_21627173 = ref object of OpenApiRestCall_21625435
proc url_GetPatchBaseline_21627175(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetPatchBaseline_21627174(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627176 = header.getOrDefault("X-Amz-Date")
  valid_21627176 = validateParameter(valid_21627176, JString, required = false,
                                   default = nil)
  if valid_21627176 != nil:
    section.add "X-Amz-Date", valid_21627176
  var valid_21627177 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627177 = validateParameter(valid_21627177, JString, required = false,
                                   default = nil)
  if valid_21627177 != nil:
    section.add "X-Amz-Security-Token", valid_21627177
  var valid_21627178 = header.getOrDefault("X-Amz-Target")
  valid_21627178 = validateParameter(valid_21627178, JString, required = true, default = newJString(
      "AmazonSSM.GetPatchBaseline"))
  if valid_21627178 != nil:
    section.add "X-Amz-Target", valid_21627178
  var valid_21627179 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627179 = validateParameter(valid_21627179, JString, required = false,
                                   default = nil)
  if valid_21627179 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627179
  var valid_21627180 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627180 = validateParameter(valid_21627180, JString, required = false,
                                   default = nil)
  if valid_21627180 != nil:
    section.add "X-Amz-Algorithm", valid_21627180
  var valid_21627181 = header.getOrDefault("X-Amz-Signature")
  valid_21627181 = validateParameter(valid_21627181, JString, required = false,
                                   default = nil)
  if valid_21627181 != nil:
    section.add "X-Amz-Signature", valid_21627181
  var valid_21627182 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627182 = validateParameter(valid_21627182, JString, required = false,
                                   default = nil)
  if valid_21627182 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627182
  var valid_21627183 = header.getOrDefault("X-Amz-Credential")
  valid_21627183 = validateParameter(valid_21627183, JString, required = false,
                                   default = nil)
  if valid_21627183 != nil:
    section.add "X-Amz-Credential", valid_21627183
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

proc call*(call_21627185: Call_GetPatchBaseline_21627173; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves information about a patch baseline.
  ## 
  let valid = call_21627185.validator(path, query, header, formData, body, _)
  let scheme = call_21627185.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627185.makeUrl(scheme.get, call_21627185.host, call_21627185.base,
                               call_21627185.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627185, uri, valid, _)

proc call*(call_21627186: Call_GetPatchBaseline_21627173; body: JsonNode): Recallable =
  ## getPatchBaseline
  ## Retrieves information about a patch baseline.
  ##   body: JObject (required)
  var body_21627187 = newJObject()
  if body != nil:
    body_21627187 = body
  result = call_21627186.call(nil, nil, nil, nil, body_21627187)

var getPatchBaseline* = Call_GetPatchBaseline_21627173(name: "getPatchBaseline",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetPatchBaseline",
    validator: validate_GetPatchBaseline_21627174, base: "/",
    makeUrl: url_GetPatchBaseline_21627175, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPatchBaselineForPatchGroup_21627188 = ref object of OpenApiRestCall_21625435
proc url_GetPatchBaselineForPatchGroup_21627190(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetPatchBaselineForPatchGroup_21627189(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21627191 = header.getOrDefault("X-Amz-Date")
  valid_21627191 = validateParameter(valid_21627191, JString, required = false,
                                   default = nil)
  if valid_21627191 != nil:
    section.add "X-Amz-Date", valid_21627191
  var valid_21627192 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627192 = validateParameter(valid_21627192, JString, required = false,
                                   default = nil)
  if valid_21627192 != nil:
    section.add "X-Amz-Security-Token", valid_21627192
  var valid_21627193 = header.getOrDefault("X-Amz-Target")
  valid_21627193 = validateParameter(valid_21627193, JString, required = true, default = newJString(
      "AmazonSSM.GetPatchBaselineForPatchGroup"))
  if valid_21627193 != nil:
    section.add "X-Amz-Target", valid_21627193
  var valid_21627194 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627194 = validateParameter(valid_21627194, JString, required = false,
                                   default = nil)
  if valid_21627194 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627194
  var valid_21627195 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627195 = validateParameter(valid_21627195, JString, required = false,
                                   default = nil)
  if valid_21627195 != nil:
    section.add "X-Amz-Algorithm", valid_21627195
  var valid_21627196 = header.getOrDefault("X-Amz-Signature")
  valid_21627196 = validateParameter(valid_21627196, JString, required = false,
                                   default = nil)
  if valid_21627196 != nil:
    section.add "X-Amz-Signature", valid_21627196
  var valid_21627197 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627197 = validateParameter(valid_21627197, JString, required = false,
                                   default = nil)
  if valid_21627197 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627197
  var valid_21627198 = header.getOrDefault("X-Amz-Credential")
  valid_21627198 = validateParameter(valid_21627198, JString, required = false,
                                   default = nil)
  if valid_21627198 != nil:
    section.add "X-Amz-Credential", valid_21627198
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

proc call*(call_21627200: Call_GetPatchBaselineForPatchGroup_21627188;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves the patch baseline that should be used for the specified patch group.
  ## 
  let valid = call_21627200.validator(path, query, header, formData, body, _)
  let scheme = call_21627200.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627200.makeUrl(scheme.get, call_21627200.host, call_21627200.base,
                               call_21627200.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627200, uri, valid, _)

proc call*(call_21627201: Call_GetPatchBaselineForPatchGroup_21627188;
          body: JsonNode): Recallable =
  ## getPatchBaselineForPatchGroup
  ## Retrieves the patch baseline that should be used for the specified patch group.
  ##   body: JObject (required)
  var body_21627202 = newJObject()
  if body != nil:
    body_21627202 = body
  result = call_21627201.call(nil, nil, nil, nil, body_21627202)

var getPatchBaselineForPatchGroup* = Call_GetPatchBaselineForPatchGroup_21627188(
    name: "getPatchBaselineForPatchGroup", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetPatchBaselineForPatchGroup",
    validator: validate_GetPatchBaselineForPatchGroup_21627189, base: "/",
    makeUrl: url_GetPatchBaselineForPatchGroup_21627190,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetServiceSetting_21627203 = ref object of OpenApiRestCall_21625435
proc url_GetServiceSetting_21627205(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetServiceSetting_21627204(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627206 = header.getOrDefault("X-Amz-Date")
  valid_21627206 = validateParameter(valid_21627206, JString, required = false,
                                   default = nil)
  if valid_21627206 != nil:
    section.add "X-Amz-Date", valid_21627206
  var valid_21627207 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627207 = validateParameter(valid_21627207, JString, required = false,
                                   default = nil)
  if valid_21627207 != nil:
    section.add "X-Amz-Security-Token", valid_21627207
  var valid_21627208 = header.getOrDefault("X-Amz-Target")
  valid_21627208 = validateParameter(valid_21627208, JString, required = true, default = newJString(
      "AmazonSSM.GetServiceSetting"))
  if valid_21627208 != nil:
    section.add "X-Amz-Target", valid_21627208
  var valid_21627209 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627209 = validateParameter(valid_21627209, JString, required = false,
                                   default = nil)
  if valid_21627209 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627209
  var valid_21627210 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627210 = validateParameter(valid_21627210, JString, required = false,
                                   default = nil)
  if valid_21627210 != nil:
    section.add "X-Amz-Algorithm", valid_21627210
  var valid_21627211 = header.getOrDefault("X-Amz-Signature")
  valid_21627211 = validateParameter(valid_21627211, JString, required = false,
                                   default = nil)
  if valid_21627211 != nil:
    section.add "X-Amz-Signature", valid_21627211
  var valid_21627212 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627212 = validateParameter(valid_21627212, JString, required = false,
                                   default = nil)
  if valid_21627212 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627212
  var valid_21627213 = header.getOrDefault("X-Amz-Credential")
  valid_21627213 = validateParameter(valid_21627213, JString, required = false,
                                   default = nil)
  if valid_21627213 != nil:
    section.add "X-Amz-Credential", valid_21627213
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

proc call*(call_21627215: Call_GetServiceSetting_21627203; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p> <code>ServiceSetting</code> is an account-level setting for an AWS service. This setting defines how a user interacts with or uses a service or a feature of a service. For example, if an AWS service charges money to the account based on feature or service usage, then the AWS service team might create a default setting of "false". This means the user can't use this feature unless they change the setting to "true" and intentionally opt in for a paid feature.</p> <p>Services map a <code>SettingId</code> object to a setting value. AWS services teams define the default value for a <code>SettingId</code>. You can't create a new <code>SettingId</code>, but you can overwrite the default value if you have the <code>ssm:UpdateServiceSetting</code> permission for the setting. Use the <a>UpdateServiceSetting</a> API action to change the default setting. Or use the <a>ResetServiceSetting</a> to change the value back to the original value defined by the AWS service team.</p> <p>Query the current service setting for the account. </p>
  ## 
  let valid = call_21627215.validator(path, query, header, formData, body, _)
  let scheme = call_21627215.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627215.makeUrl(scheme.get, call_21627215.host, call_21627215.base,
                               call_21627215.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627215, uri, valid, _)

proc call*(call_21627216: Call_GetServiceSetting_21627203; body: JsonNode): Recallable =
  ## getServiceSetting
  ## <p> <code>ServiceSetting</code> is an account-level setting for an AWS service. This setting defines how a user interacts with or uses a service or a feature of a service. For example, if an AWS service charges money to the account based on feature or service usage, then the AWS service team might create a default setting of "false". This means the user can't use this feature unless they change the setting to "true" and intentionally opt in for a paid feature.</p> <p>Services map a <code>SettingId</code> object to a setting value. AWS services teams define the default value for a <code>SettingId</code>. You can't create a new <code>SettingId</code>, but you can overwrite the default value if you have the <code>ssm:UpdateServiceSetting</code> permission for the setting. Use the <a>UpdateServiceSetting</a> API action to change the default setting. Or use the <a>ResetServiceSetting</a> to change the value back to the original value defined by the AWS service team.</p> <p>Query the current service setting for the account. </p>
  ##   body: JObject (required)
  var body_21627217 = newJObject()
  if body != nil:
    body_21627217 = body
  result = call_21627216.call(nil, nil, nil, nil, body_21627217)

var getServiceSetting* = Call_GetServiceSetting_21627203(name: "getServiceSetting",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetServiceSetting",
    validator: validate_GetServiceSetting_21627204, base: "/",
    makeUrl: url_GetServiceSetting_21627205, schemes: {Scheme.Https, Scheme.Http})
type
  Call_LabelParameterVersion_21627218 = ref object of OpenApiRestCall_21625435
proc url_LabelParameterVersion_21627220(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_LabelParameterVersion_21627219(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627221 = header.getOrDefault("X-Amz-Date")
  valid_21627221 = validateParameter(valid_21627221, JString, required = false,
                                   default = nil)
  if valid_21627221 != nil:
    section.add "X-Amz-Date", valid_21627221
  var valid_21627222 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627222 = validateParameter(valid_21627222, JString, required = false,
                                   default = nil)
  if valid_21627222 != nil:
    section.add "X-Amz-Security-Token", valid_21627222
  var valid_21627223 = header.getOrDefault("X-Amz-Target")
  valid_21627223 = validateParameter(valid_21627223, JString, required = true, default = newJString(
      "AmazonSSM.LabelParameterVersion"))
  if valid_21627223 != nil:
    section.add "X-Amz-Target", valid_21627223
  var valid_21627224 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627224 = validateParameter(valid_21627224, JString, required = false,
                                   default = nil)
  if valid_21627224 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627224
  var valid_21627225 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627225 = validateParameter(valid_21627225, JString, required = false,
                                   default = nil)
  if valid_21627225 != nil:
    section.add "X-Amz-Algorithm", valid_21627225
  var valid_21627226 = header.getOrDefault("X-Amz-Signature")
  valid_21627226 = validateParameter(valid_21627226, JString, required = false,
                                   default = nil)
  if valid_21627226 != nil:
    section.add "X-Amz-Signature", valid_21627226
  var valid_21627227 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627227 = validateParameter(valid_21627227, JString, required = false,
                                   default = nil)
  if valid_21627227 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627227
  var valid_21627228 = header.getOrDefault("X-Amz-Credential")
  valid_21627228 = validateParameter(valid_21627228, JString, required = false,
                                   default = nil)
  if valid_21627228 != nil:
    section.add "X-Amz-Credential", valid_21627228
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

proc call*(call_21627230: Call_LabelParameterVersion_21627218;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>A parameter label is a user-defined alias to help you manage different versions of a parameter. When you modify a parameter, Systems Manager automatically saves a new version and increments the version number by one. A label can help you remember the purpose of a parameter when there are multiple versions. </p> <p>Parameter labels have the following requirements and restrictions.</p> <ul> <li> <p>A version of a parameter can have a maximum of 10 labels.</p> </li> <li> <p>You can't attach the same label to different versions of the same parameter. For example, if version 1 has the label Production, then you can't attach Production to version 2.</p> </li> <li> <p>You can move a label from one version of a parameter to another.</p> </li> <li> <p>You can't create a label when you create a new parameter. You must attach a label to a specific version of a parameter.</p> </li> <li> <p>You can't delete a parameter label. If you no longer want to use a parameter label, then you must move it to a different version of a parameter.</p> </li> <li> <p>A label can have a maximum of 100 characters.</p> </li> <li> <p>Labels can contain letters (case sensitive), numbers, periods (.), hyphens (-), or underscores (_).</p> </li> <li> <p>Labels can't begin with a number, "aws," or "ssm" (not case sensitive). If a label fails to meet these requirements, then the label is not associated with a parameter and the system displays it in the list of InvalidLabels.</p> </li> </ul>
  ## 
  let valid = call_21627230.validator(path, query, header, formData, body, _)
  let scheme = call_21627230.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627230.makeUrl(scheme.get, call_21627230.host, call_21627230.base,
                               call_21627230.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627230, uri, valid, _)

proc call*(call_21627231: Call_LabelParameterVersion_21627218; body: JsonNode): Recallable =
  ## labelParameterVersion
  ## <p>A parameter label is a user-defined alias to help you manage different versions of a parameter. When you modify a parameter, Systems Manager automatically saves a new version and increments the version number by one. A label can help you remember the purpose of a parameter when there are multiple versions. </p> <p>Parameter labels have the following requirements and restrictions.</p> <ul> <li> <p>A version of a parameter can have a maximum of 10 labels.</p> </li> <li> <p>You can't attach the same label to different versions of the same parameter. For example, if version 1 has the label Production, then you can't attach Production to version 2.</p> </li> <li> <p>You can move a label from one version of a parameter to another.</p> </li> <li> <p>You can't create a label when you create a new parameter. You must attach a label to a specific version of a parameter.</p> </li> <li> <p>You can't delete a parameter label. If you no longer want to use a parameter label, then you must move it to a different version of a parameter.</p> </li> <li> <p>A label can have a maximum of 100 characters.</p> </li> <li> <p>Labels can contain letters (case sensitive), numbers, periods (.), hyphens (-), or underscores (_).</p> </li> <li> <p>Labels can't begin with a number, "aws," or "ssm" (not case sensitive). If a label fails to meet these requirements, then the label is not associated with a parameter and the system displays it in the list of InvalidLabels.</p> </li> </ul>
  ##   body: JObject (required)
  var body_21627232 = newJObject()
  if body != nil:
    body_21627232 = body
  result = call_21627231.call(nil, nil, nil, nil, body_21627232)

var labelParameterVersion* = Call_LabelParameterVersion_21627218(
    name: "labelParameterVersion", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.LabelParameterVersion",
    validator: validate_LabelParameterVersion_21627219, base: "/",
    makeUrl: url_LabelParameterVersion_21627220,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAssociationVersions_21627233 = ref object of OpenApiRestCall_21625435
proc url_ListAssociationVersions_21627235(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListAssociationVersions_21627234(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627236 = header.getOrDefault("X-Amz-Date")
  valid_21627236 = validateParameter(valid_21627236, JString, required = false,
                                   default = nil)
  if valid_21627236 != nil:
    section.add "X-Amz-Date", valid_21627236
  var valid_21627237 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627237 = validateParameter(valid_21627237, JString, required = false,
                                   default = nil)
  if valid_21627237 != nil:
    section.add "X-Amz-Security-Token", valid_21627237
  var valid_21627238 = header.getOrDefault("X-Amz-Target")
  valid_21627238 = validateParameter(valid_21627238, JString, required = true, default = newJString(
      "AmazonSSM.ListAssociationVersions"))
  if valid_21627238 != nil:
    section.add "X-Amz-Target", valid_21627238
  var valid_21627239 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627239 = validateParameter(valid_21627239, JString, required = false,
                                   default = nil)
  if valid_21627239 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627239
  var valid_21627240 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627240 = validateParameter(valid_21627240, JString, required = false,
                                   default = nil)
  if valid_21627240 != nil:
    section.add "X-Amz-Algorithm", valid_21627240
  var valid_21627241 = header.getOrDefault("X-Amz-Signature")
  valid_21627241 = validateParameter(valid_21627241, JString, required = false,
                                   default = nil)
  if valid_21627241 != nil:
    section.add "X-Amz-Signature", valid_21627241
  var valid_21627242 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627242 = validateParameter(valid_21627242, JString, required = false,
                                   default = nil)
  if valid_21627242 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627242
  var valid_21627243 = header.getOrDefault("X-Amz-Credential")
  valid_21627243 = validateParameter(valid_21627243, JString, required = false,
                                   default = nil)
  if valid_21627243 != nil:
    section.add "X-Amz-Credential", valid_21627243
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

proc call*(call_21627245: Call_ListAssociationVersions_21627233;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves all versions of an association for a specific association ID.
  ## 
  let valid = call_21627245.validator(path, query, header, formData, body, _)
  let scheme = call_21627245.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627245.makeUrl(scheme.get, call_21627245.host, call_21627245.base,
                               call_21627245.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627245, uri, valid, _)

proc call*(call_21627246: Call_ListAssociationVersions_21627233; body: JsonNode): Recallable =
  ## listAssociationVersions
  ## Retrieves all versions of an association for a specific association ID.
  ##   body: JObject (required)
  var body_21627247 = newJObject()
  if body != nil:
    body_21627247 = body
  result = call_21627246.call(nil, nil, nil, nil, body_21627247)

var listAssociationVersions* = Call_ListAssociationVersions_21627233(
    name: "listAssociationVersions", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.ListAssociationVersions",
    validator: validate_ListAssociationVersions_21627234, base: "/",
    makeUrl: url_ListAssociationVersions_21627235,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAssociations_21627248 = ref object of OpenApiRestCall_21625435
proc url_ListAssociations_21627250(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListAssociations_21627249(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns all State Manager associations in the current AWS account and Region. You can limit the results to a specific State Manager association document or instance by specifying a filter.
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
  var valid_21627251 = query.getOrDefault("NextToken")
  valid_21627251 = validateParameter(valid_21627251, JString, required = false,
                                   default = nil)
  if valid_21627251 != nil:
    section.add "NextToken", valid_21627251
  var valid_21627252 = query.getOrDefault("MaxResults")
  valid_21627252 = validateParameter(valid_21627252, JString, required = false,
                                   default = nil)
  if valid_21627252 != nil:
    section.add "MaxResults", valid_21627252
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627253 = header.getOrDefault("X-Amz-Date")
  valid_21627253 = validateParameter(valid_21627253, JString, required = false,
                                   default = nil)
  if valid_21627253 != nil:
    section.add "X-Amz-Date", valid_21627253
  var valid_21627254 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627254 = validateParameter(valid_21627254, JString, required = false,
                                   default = nil)
  if valid_21627254 != nil:
    section.add "X-Amz-Security-Token", valid_21627254
  var valid_21627255 = header.getOrDefault("X-Amz-Target")
  valid_21627255 = validateParameter(valid_21627255, JString, required = true, default = newJString(
      "AmazonSSM.ListAssociations"))
  if valid_21627255 != nil:
    section.add "X-Amz-Target", valid_21627255
  var valid_21627256 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627256 = validateParameter(valid_21627256, JString, required = false,
                                   default = nil)
  if valid_21627256 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627256
  var valid_21627257 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627257 = validateParameter(valid_21627257, JString, required = false,
                                   default = nil)
  if valid_21627257 != nil:
    section.add "X-Amz-Algorithm", valid_21627257
  var valid_21627258 = header.getOrDefault("X-Amz-Signature")
  valid_21627258 = validateParameter(valid_21627258, JString, required = false,
                                   default = nil)
  if valid_21627258 != nil:
    section.add "X-Amz-Signature", valid_21627258
  var valid_21627259 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627259 = validateParameter(valid_21627259, JString, required = false,
                                   default = nil)
  if valid_21627259 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627259
  var valid_21627260 = header.getOrDefault("X-Amz-Credential")
  valid_21627260 = validateParameter(valid_21627260, JString, required = false,
                                   default = nil)
  if valid_21627260 != nil:
    section.add "X-Amz-Credential", valid_21627260
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

proc call*(call_21627262: Call_ListAssociations_21627248; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns all State Manager associations in the current AWS account and Region. You can limit the results to a specific State Manager association document or instance by specifying a filter.
  ## 
  let valid = call_21627262.validator(path, query, header, formData, body, _)
  let scheme = call_21627262.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627262.makeUrl(scheme.get, call_21627262.host, call_21627262.base,
                               call_21627262.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627262, uri, valid, _)

proc call*(call_21627263: Call_ListAssociations_21627248; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listAssociations
  ## Returns all State Manager associations in the current AWS account and Region. You can limit the results to a specific State Manager association document or instance by specifying a filter.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_21627264 = newJObject()
  var body_21627265 = newJObject()
  add(query_21627264, "NextToken", newJString(NextToken))
  if body != nil:
    body_21627265 = body
  add(query_21627264, "MaxResults", newJString(MaxResults))
  result = call_21627263.call(nil, query_21627264, nil, nil, body_21627265)

var listAssociations* = Call_ListAssociations_21627248(name: "listAssociations",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.ListAssociations",
    validator: validate_ListAssociations_21627249, base: "/",
    makeUrl: url_ListAssociations_21627250, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListCommandInvocations_21627266 = ref object of OpenApiRestCall_21625435
proc url_ListCommandInvocations_21627268(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListCommandInvocations_21627267(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627269 = query.getOrDefault("NextToken")
  valid_21627269 = validateParameter(valid_21627269, JString, required = false,
                                   default = nil)
  if valid_21627269 != nil:
    section.add "NextToken", valid_21627269
  var valid_21627270 = query.getOrDefault("MaxResults")
  valid_21627270 = validateParameter(valid_21627270, JString, required = false,
                                   default = nil)
  if valid_21627270 != nil:
    section.add "MaxResults", valid_21627270
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627271 = header.getOrDefault("X-Amz-Date")
  valid_21627271 = validateParameter(valid_21627271, JString, required = false,
                                   default = nil)
  if valid_21627271 != nil:
    section.add "X-Amz-Date", valid_21627271
  var valid_21627272 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627272 = validateParameter(valid_21627272, JString, required = false,
                                   default = nil)
  if valid_21627272 != nil:
    section.add "X-Amz-Security-Token", valid_21627272
  var valid_21627273 = header.getOrDefault("X-Amz-Target")
  valid_21627273 = validateParameter(valid_21627273, JString, required = true, default = newJString(
      "AmazonSSM.ListCommandInvocations"))
  if valid_21627273 != nil:
    section.add "X-Amz-Target", valid_21627273
  var valid_21627274 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627274 = validateParameter(valid_21627274, JString, required = false,
                                   default = nil)
  if valid_21627274 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627274
  var valid_21627275 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627275 = validateParameter(valid_21627275, JString, required = false,
                                   default = nil)
  if valid_21627275 != nil:
    section.add "X-Amz-Algorithm", valid_21627275
  var valid_21627276 = header.getOrDefault("X-Amz-Signature")
  valid_21627276 = validateParameter(valid_21627276, JString, required = false,
                                   default = nil)
  if valid_21627276 != nil:
    section.add "X-Amz-Signature", valid_21627276
  var valid_21627277 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627277 = validateParameter(valid_21627277, JString, required = false,
                                   default = nil)
  if valid_21627277 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627277
  var valid_21627278 = header.getOrDefault("X-Amz-Credential")
  valid_21627278 = validateParameter(valid_21627278, JString, required = false,
                                   default = nil)
  if valid_21627278 != nil:
    section.add "X-Amz-Credential", valid_21627278
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

proc call*(call_21627280: Call_ListCommandInvocations_21627266;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## An invocation is copy of a command sent to a specific instance. A command can apply to one or more instances. A command invocation applies to one instance. For example, if a user runs SendCommand against three instances, then a command invocation is created for each requested instance ID. ListCommandInvocations provide status about command execution.
  ## 
  let valid = call_21627280.validator(path, query, header, formData, body, _)
  let scheme = call_21627280.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627280.makeUrl(scheme.get, call_21627280.host, call_21627280.base,
                               call_21627280.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627280, uri, valid, _)

proc call*(call_21627281: Call_ListCommandInvocations_21627266; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listCommandInvocations
  ## An invocation is copy of a command sent to a specific instance. A command can apply to one or more instances. A command invocation applies to one instance. For example, if a user runs SendCommand against three instances, then a command invocation is created for each requested instance ID. ListCommandInvocations provide status about command execution.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_21627282 = newJObject()
  var body_21627283 = newJObject()
  add(query_21627282, "NextToken", newJString(NextToken))
  if body != nil:
    body_21627283 = body
  add(query_21627282, "MaxResults", newJString(MaxResults))
  result = call_21627281.call(nil, query_21627282, nil, nil, body_21627283)

var listCommandInvocations* = Call_ListCommandInvocations_21627266(
    name: "listCommandInvocations", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.ListCommandInvocations",
    validator: validate_ListCommandInvocations_21627267, base: "/",
    makeUrl: url_ListCommandInvocations_21627268,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListCommands_21627284 = ref object of OpenApiRestCall_21625435
proc url_ListCommands_21627286(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListCommands_21627285(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21627287 = query.getOrDefault("NextToken")
  valid_21627287 = validateParameter(valid_21627287, JString, required = false,
                                   default = nil)
  if valid_21627287 != nil:
    section.add "NextToken", valid_21627287
  var valid_21627288 = query.getOrDefault("MaxResults")
  valid_21627288 = validateParameter(valid_21627288, JString, required = false,
                                   default = nil)
  if valid_21627288 != nil:
    section.add "MaxResults", valid_21627288
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627289 = header.getOrDefault("X-Amz-Date")
  valid_21627289 = validateParameter(valid_21627289, JString, required = false,
                                   default = nil)
  if valid_21627289 != nil:
    section.add "X-Amz-Date", valid_21627289
  var valid_21627290 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627290 = validateParameter(valid_21627290, JString, required = false,
                                   default = nil)
  if valid_21627290 != nil:
    section.add "X-Amz-Security-Token", valid_21627290
  var valid_21627291 = header.getOrDefault("X-Amz-Target")
  valid_21627291 = validateParameter(valid_21627291, JString, required = true, default = newJString(
      "AmazonSSM.ListCommands"))
  if valid_21627291 != nil:
    section.add "X-Amz-Target", valid_21627291
  var valid_21627292 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627292 = validateParameter(valid_21627292, JString, required = false,
                                   default = nil)
  if valid_21627292 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627292
  var valid_21627293 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627293 = validateParameter(valid_21627293, JString, required = false,
                                   default = nil)
  if valid_21627293 != nil:
    section.add "X-Amz-Algorithm", valid_21627293
  var valid_21627294 = header.getOrDefault("X-Amz-Signature")
  valid_21627294 = validateParameter(valid_21627294, JString, required = false,
                                   default = nil)
  if valid_21627294 != nil:
    section.add "X-Amz-Signature", valid_21627294
  var valid_21627295 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627295 = validateParameter(valid_21627295, JString, required = false,
                                   default = nil)
  if valid_21627295 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627295
  var valid_21627296 = header.getOrDefault("X-Amz-Credential")
  valid_21627296 = validateParameter(valid_21627296, JString, required = false,
                                   default = nil)
  if valid_21627296 != nil:
    section.add "X-Amz-Credential", valid_21627296
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

proc call*(call_21627298: Call_ListCommands_21627284; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the commands requested by users of the AWS account.
  ## 
  let valid = call_21627298.validator(path, query, header, formData, body, _)
  let scheme = call_21627298.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627298.makeUrl(scheme.get, call_21627298.host, call_21627298.base,
                               call_21627298.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627298, uri, valid, _)

proc call*(call_21627299: Call_ListCommands_21627284; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listCommands
  ## Lists the commands requested by users of the AWS account.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_21627300 = newJObject()
  var body_21627301 = newJObject()
  add(query_21627300, "NextToken", newJString(NextToken))
  if body != nil:
    body_21627301 = body
  add(query_21627300, "MaxResults", newJString(MaxResults))
  result = call_21627299.call(nil, query_21627300, nil, nil, body_21627301)

var listCommands* = Call_ListCommands_21627284(name: "listCommands",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.ListCommands",
    validator: validate_ListCommands_21627285, base: "/", makeUrl: url_ListCommands_21627286,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListComplianceItems_21627302 = ref object of OpenApiRestCall_21625435
proc url_ListComplianceItems_21627304(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListComplianceItems_21627303(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627305 = header.getOrDefault("X-Amz-Date")
  valid_21627305 = validateParameter(valid_21627305, JString, required = false,
                                   default = nil)
  if valid_21627305 != nil:
    section.add "X-Amz-Date", valid_21627305
  var valid_21627306 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627306 = validateParameter(valid_21627306, JString, required = false,
                                   default = nil)
  if valid_21627306 != nil:
    section.add "X-Amz-Security-Token", valid_21627306
  var valid_21627307 = header.getOrDefault("X-Amz-Target")
  valid_21627307 = validateParameter(valid_21627307, JString, required = true, default = newJString(
      "AmazonSSM.ListComplianceItems"))
  if valid_21627307 != nil:
    section.add "X-Amz-Target", valid_21627307
  var valid_21627308 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627308 = validateParameter(valid_21627308, JString, required = false,
                                   default = nil)
  if valid_21627308 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627308
  var valid_21627309 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627309 = validateParameter(valid_21627309, JString, required = false,
                                   default = nil)
  if valid_21627309 != nil:
    section.add "X-Amz-Algorithm", valid_21627309
  var valid_21627310 = header.getOrDefault("X-Amz-Signature")
  valid_21627310 = validateParameter(valid_21627310, JString, required = false,
                                   default = nil)
  if valid_21627310 != nil:
    section.add "X-Amz-Signature", valid_21627310
  var valid_21627311 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627311 = validateParameter(valid_21627311, JString, required = false,
                                   default = nil)
  if valid_21627311 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627311
  var valid_21627312 = header.getOrDefault("X-Amz-Credential")
  valid_21627312 = validateParameter(valid_21627312, JString, required = false,
                                   default = nil)
  if valid_21627312 != nil:
    section.add "X-Amz-Credential", valid_21627312
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

proc call*(call_21627314: Call_ListComplianceItems_21627302; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## For a specified resource ID, this API action returns a list of compliance statuses for different resource types. Currently, you can only specify one resource ID per call. List results depend on the criteria specified in the filter. 
  ## 
  let valid = call_21627314.validator(path, query, header, formData, body, _)
  let scheme = call_21627314.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627314.makeUrl(scheme.get, call_21627314.host, call_21627314.base,
                               call_21627314.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627314, uri, valid, _)

proc call*(call_21627315: Call_ListComplianceItems_21627302; body: JsonNode): Recallable =
  ## listComplianceItems
  ## For a specified resource ID, this API action returns a list of compliance statuses for different resource types. Currently, you can only specify one resource ID per call. List results depend on the criteria specified in the filter. 
  ##   body: JObject (required)
  var body_21627316 = newJObject()
  if body != nil:
    body_21627316 = body
  result = call_21627315.call(nil, nil, nil, nil, body_21627316)

var listComplianceItems* = Call_ListComplianceItems_21627302(
    name: "listComplianceItems", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.ListComplianceItems",
    validator: validate_ListComplianceItems_21627303, base: "/",
    makeUrl: url_ListComplianceItems_21627304,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListComplianceSummaries_21627317 = ref object of OpenApiRestCall_21625435
proc url_ListComplianceSummaries_21627319(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListComplianceSummaries_21627318(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627320 = header.getOrDefault("X-Amz-Date")
  valid_21627320 = validateParameter(valid_21627320, JString, required = false,
                                   default = nil)
  if valid_21627320 != nil:
    section.add "X-Amz-Date", valid_21627320
  var valid_21627321 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627321 = validateParameter(valid_21627321, JString, required = false,
                                   default = nil)
  if valid_21627321 != nil:
    section.add "X-Amz-Security-Token", valid_21627321
  var valid_21627322 = header.getOrDefault("X-Amz-Target")
  valid_21627322 = validateParameter(valid_21627322, JString, required = true, default = newJString(
      "AmazonSSM.ListComplianceSummaries"))
  if valid_21627322 != nil:
    section.add "X-Amz-Target", valid_21627322
  var valid_21627323 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627323 = validateParameter(valid_21627323, JString, required = false,
                                   default = nil)
  if valid_21627323 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627323
  var valid_21627324 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627324 = validateParameter(valid_21627324, JString, required = false,
                                   default = nil)
  if valid_21627324 != nil:
    section.add "X-Amz-Algorithm", valid_21627324
  var valid_21627325 = header.getOrDefault("X-Amz-Signature")
  valid_21627325 = validateParameter(valid_21627325, JString, required = false,
                                   default = nil)
  if valid_21627325 != nil:
    section.add "X-Amz-Signature", valid_21627325
  var valid_21627326 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627326 = validateParameter(valid_21627326, JString, required = false,
                                   default = nil)
  if valid_21627326 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627326
  var valid_21627327 = header.getOrDefault("X-Amz-Credential")
  valid_21627327 = validateParameter(valid_21627327, JString, required = false,
                                   default = nil)
  if valid_21627327 != nil:
    section.add "X-Amz-Credential", valid_21627327
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

proc call*(call_21627329: Call_ListComplianceSummaries_21627317;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a summary count of compliant and non-compliant resources for a compliance type. For example, this call can return State Manager associations, patches, or custom compliance types according to the filter criteria that you specify. 
  ## 
  let valid = call_21627329.validator(path, query, header, formData, body, _)
  let scheme = call_21627329.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627329.makeUrl(scheme.get, call_21627329.host, call_21627329.base,
                               call_21627329.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627329, uri, valid, _)

proc call*(call_21627330: Call_ListComplianceSummaries_21627317; body: JsonNode): Recallable =
  ## listComplianceSummaries
  ## Returns a summary count of compliant and non-compliant resources for a compliance type. For example, this call can return State Manager associations, patches, or custom compliance types according to the filter criteria that you specify. 
  ##   body: JObject (required)
  var body_21627331 = newJObject()
  if body != nil:
    body_21627331 = body
  result = call_21627330.call(nil, nil, nil, nil, body_21627331)

var listComplianceSummaries* = Call_ListComplianceSummaries_21627317(
    name: "listComplianceSummaries", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.ListComplianceSummaries",
    validator: validate_ListComplianceSummaries_21627318, base: "/",
    makeUrl: url_ListComplianceSummaries_21627319,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDocumentVersions_21627332 = ref object of OpenApiRestCall_21625435
proc url_ListDocumentVersions_21627334(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListDocumentVersions_21627333(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627335 = header.getOrDefault("X-Amz-Date")
  valid_21627335 = validateParameter(valid_21627335, JString, required = false,
                                   default = nil)
  if valid_21627335 != nil:
    section.add "X-Amz-Date", valid_21627335
  var valid_21627336 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627336 = validateParameter(valid_21627336, JString, required = false,
                                   default = nil)
  if valid_21627336 != nil:
    section.add "X-Amz-Security-Token", valid_21627336
  var valid_21627337 = header.getOrDefault("X-Amz-Target")
  valid_21627337 = validateParameter(valid_21627337, JString, required = true, default = newJString(
      "AmazonSSM.ListDocumentVersions"))
  if valid_21627337 != nil:
    section.add "X-Amz-Target", valid_21627337
  var valid_21627338 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627338 = validateParameter(valid_21627338, JString, required = false,
                                   default = nil)
  if valid_21627338 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627338
  var valid_21627339 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627339 = validateParameter(valid_21627339, JString, required = false,
                                   default = nil)
  if valid_21627339 != nil:
    section.add "X-Amz-Algorithm", valid_21627339
  var valid_21627340 = header.getOrDefault("X-Amz-Signature")
  valid_21627340 = validateParameter(valid_21627340, JString, required = false,
                                   default = nil)
  if valid_21627340 != nil:
    section.add "X-Amz-Signature", valid_21627340
  var valid_21627341 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627341 = validateParameter(valid_21627341, JString, required = false,
                                   default = nil)
  if valid_21627341 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627341
  var valid_21627342 = header.getOrDefault("X-Amz-Credential")
  valid_21627342 = validateParameter(valid_21627342, JString, required = false,
                                   default = nil)
  if valid_21627342 != nil:
    section.add "X-Amz-Credential", valid_21627342
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

proc call*(call_21627344: Call_ListDocumentVersions_21627332; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## List all versions for a document.
  ## 
  let valid = call_21627344.validator(path, query, header, formData, body, _)
  let scheme = call_21627344.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627344.makeUrl(scheme.get, call_21627344.host, call_21627344.base,
                               call_21627344.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627344, uri, valid, _)

proc call*(call_21627345: Call_ListDocumentVersions_21627332; body: JsonNode): Recallable =
  ## listDocumentVersions
  ## List all versions for a document.
  ##   body: JObject (required)
  var body_21627346 = newJObject()
  if body != nil:
    body_21627346 = body
  result = call_21627345.call(nil, nil, nil, nil, body_21627346)

var listDocumentVersions* = Call_ListDocumentVersions_21627332(
    name: "listDocumentVersions", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.ListDocumentVersions",
    validator: validate_ListDocumentVersions_21627333, base: "/",
    makeUrl: url_ListDocumentVersions_21627334,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDocuments_21627347 = ref object of OpenApiRestCall_21625435
proc url_ListDocuments_21627349(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListDocuments_21627348(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Returns all Systems Manager (SSM) documents in the current AWS account and Region. You can limit the results of this request by using a filter.
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
  var valid_21627350 = query.getOrDefault("NextToken")
  valid_21627350 = validateParameter(valid_21627350, JString, required = false,
                                   default = nil)
  if valid_21627350 != nil:
    section.add "NextToken", valid_21627350
  var valid_21627351 = query.getOrDefault("MaxResults")
  valid_21627351 = validateParameter(valid_21627351, JString, required = false,
                                   default = nil)
  if valid_21627351 != nil:
    section.add "MaxResults", valid_21627351
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627352 = header.getOrDefault("X-Amz-Date")
  valid_21627352 = validateParameter(valid_21627352, JString, required = false,
                                   default = nil)
  if valid_21627352 != nil:
    section.add "X-Amz-Date", valid_21627352
  var valid_21627353 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627353 = validateParameter(valid_21627353, JString, required = false,
                                   default = nil)
  if valid_21627353 != nil:
    section.add "X-Amz-Security-Token", valid_21627353
  var valid_21627354 = header.getOrDefault("X-Amz-Target")
  valid_21627354 = validateParameter(valid_21627354, JString, required = true, default = newJString(
      "AmazonSSM.ListDocuments"))
  if valid_21627354 != nil:
    section.add "X-Amz-Target", valid_21627354
  var valid_21627355 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627355 = validateParameter(valid_21627355, JString, required = false,
                                   default = nil)
  if valid_21627355 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627355
  var valid_21627356 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627356 = validateParameter(valid_21627356, JString, required = false,
                                   default = nil)
  if valid_21627356 != nil:
    section.add "X-Amz-Algorithm", valid_21627356
  var valid_21627357 = header.getOrDefault("X-Amz-Signature")
  valid_21627357 = validateParameter(valid_21627357, JString, required = false,
                                   default = nil)
  if valid_21627357 != nil:
    section.add "X-Amz-Signature", valid_21627357
  var valid_21627358 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627358 = validateParameter(valid_21627358, JString, required = false,
                                   default = nil)
  if valid_21627358 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627358
  var valid_21627359 = header.getOrDefault("X-Amz-Credential")
  valid_21627359 = validateParameter(valid_21627359, JString, required = false,
                                   default = nil)
  if valid_21627359 != nil:
    section.add "X-Amz-Credential", valid_21627359
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

proc call*(call_21627361: Call_ListDocuments_21627347; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns all Systems Manager (SSM) documents in the current AWS account and Region. You can limit the results of this request by using a filter.
  ## 
  let valid = call_21627361.validator(path, query, header, formData, body, _)
  let scheme = call_21627361.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627361.makeUrl(scheme.get, call_21627361.host, call_21627361.base,
                               call_21627361.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627361, uri, valid, _)

proc call*(call_21627362: Call_ListDocuments_21627347; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listDocuments
  ## Returns all Systems Manager (SSM) documents in the current AWS account and Region. You can limit the results of this request by using a filter.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_21627363 = newJObject()
  var body_21627364 = newJObject()
  add(query_21627363, "NextToken", newJString(NextToken))
  if body != nil:
    body_21627364 = body
  add(query_21627363, "MaxResults", newJString(MaxResults))
  result = call_21627362.call(nil, query_21627363, nil, nil, body_21627364)

var listDocuments* = Call_ListDocuments_21627347(name: "listDocuments",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.ListDocuments",
    validator: validate_ListDocuments_21627348, base: "/",
    makeUrl: url_ListDocuments_21627349, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListInventoryEntries_21627365 = ref object of OpenApiRestCall_21625435
proc url_ListInventoryEntries_21627367(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListInventoryEntries_21627366(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627368 = header.getOrDefault("X-Amz-Date")
  valid_21627368 = validateParameter(valid_21627368, JString, required = false,
                                   default = nil)
  if valid_21627368 != nil:
    section.add "X-Amz-Date", valid_21627368
  var valid_21627369 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627369 = validateParameter(valid_21627369, JString, required = false,
                                   default = nil)
  if valid_21627369 != nil:
    section.add "X-Amz-Security-Token", valid_21627369
  var valid_21627370 = header.getOrDefault("X-Amz-Target")
  valid_21627370 = validateParameter(valid_21627370, JString, required = true, default = newJString(
      "AmazonSSM.ListInventoryEntries"))
  if valid_21627370 != nil:
    section.add "X-Amz-Target", valid_21627370
  var valid_21627371 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627371 = validateParameter(valid_21627371, JString, required = false,
                                   default = nil)
  if valid_21627371 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627371
  var valid_21627372 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627372 = validateParameter(valid_21627372, JString, required = false,
                                   default = nil)
  if valid_21627372 != nil:
    section.add "X-Amz-Algorithm", valid_21627372
  var valid_21627373 = header.getOrDefault("X-Amz-Signature")
  valid_21627373 = validateParameter(valid_21627373, JString, required = false,
                                   default = nil)
  if valid_21627373 != nil:
    section.add "X-Amz-Signature", valid_21627373
  var valid_21627374 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627374 = validateParameter(valid_21627374, JString, required = false,
                                   default = nil)
  if valid_21627374 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627374
  var valid_21627375 = header.getOrDefault("X-Amz-Credential")
  valid_21627375 = validateParameter(valid_21627375, JString, required = false,
                                   default = nil)
  if valid_21627375 != nil:
    section.add "X-Amz-Credential", valid_21627375
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

proc call*(call_21627377: Call_ListInventoryEntries_21627365; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## A list of inventory items returned by the request.
  ## 
  let valid = call_21627377.validator(path, query, header, formData, body, _)
  let scheme = call_21627377.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627377.makeUrl(scheme.get, call_21627377.host, call_21627377.base,
                               call_21627377.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627377, uri, valid, _)

proc call*(call_21627378: Call_ListInventoryEntries_21627365; body: JsonNode): Recallable =
  ## listInventoryEntries
  ## A list of inventory items returned by the request.
  ##   body: JObject (required)
  var body_21627379 = newJObject()
  if body != nil:
    body_21627379 = body
  result = call_21627378.call(nil, nil, nil, nil, body_21627379)

var listInventoryEntries* = Call_ListInventoryEntries_21627365(
    name: "listInventoryEntries", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.ListInventoryEntries",
    validator: validate_ListInventoryEntries_21627366, base: "/",
    makeUrl: url_ListInventoryEntries_21627367,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListResourceComplianceSummaries_21627380 = ref object of OpenApiRestCall_21625435
proc url_ListResourceComplianceSummaries_21627382(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListResourceComplianceSummaries_21627381(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21627383 = header.getOrDefault("X-Amz-Date")
  valid_21627383 = validateParameter(valid_21627383, JString, required = false,
                                   default = nil)
  if valid_21627383 != nil:
    section.add "X-Amz-Date", valid_21627383
  var valid_21627384 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627384 = validateParameter(valid_21627384, JString, required = false,
                                   default = nil)
  if valid_21627384 != nil:
    section.add "X-Amz-Security-Token", valid_21627384
  var valid_21627385 = header.getOrDefault("X-Amz-Target")
  valid_21627385 = validateParameter(valid_21627385, JString, required = true, default = newJString(
      "AmazonSSM.ListResourceComplianceSummaries"))
  if valid_21627385 != nil:
    section.add "X-Amz-Target", valid_21627385
  var valid_21627386 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627386 = validateParameter(valid_21627386, JString, required = false,
                                   default = nil)
  if valid_21627386 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627386
  var valid_21627387 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627387 = validateParameter(valid_21627387, JString, required = false,
                                   default = nil)
  if valid_21627387 != nil:
    section.add "X-Amz-Algorithm", valid_21627387
  var valid_21627388 = header.getOrDefault("X-Amz-Signature")
  valid_21627388 = validateParameter(valid_21627388, JString, required = false,
                                   default = nil)
  if valid_21627388 != nil:
    section.add "X-Amz-Signature", valid_21627388
  var valid_21627389 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627389 = validateParameter(valid_21627389, JString, required = false,
                                   default = nil)
  if valid_21627389 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627389
  var valid_21627390 = header.getOrDefault("X-Amz-Credential")
  valid_21627390 = validateParameter(valid_21627390, JString, required = false,
                                   default = nil)
  if valid_21627390 != nil:
    section.add "X-Amz-Credential", valid_21627390
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

proc call*(call_21627392: Call_ListResourceComplianceSummaries_21627380;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a resource-level summary count. The summary includes information about compliant and non-compliant statuses and detailed compliance-item severity counts, according to the filter criteria you specify.
  ## 
  let valid = call_21627392.validator(path, query, header, formData, body, _)
  let scheme = call_21627392.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627392.makeUrl(scheme.get, call_21627392.host, call_21627392.base,
                               call_21627392.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627392, uri, valid, _)

proc call*(call_21627393: Call_ListResourceComplianceSummaries_21627380;
          body: JsonNode): Recallable =
  ## listResourceComplianceSummaries
  ## Returns a resource-level summary count. The summary includes information about compliant and non-compliant statuses and detailed compliance-item severity counts, according to the filter criteria you specify.
  ##   body: JObject (required)
  var body_21627394 = newJObject()
  if body != nil:
    body_21627394 = body
  result = call_21627393.call(nil, nil, nil, nil, body_21627394)

var listResourceComplianceSummaries* = Call_ListResourceComplianceSummaries_21627380(
    name: "listResourceComplianceSummaries", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.ListResourceComplianceSummaries",
    validator: validate_ListResourceComplianceSummaries_21627381, base: "/",
    makeUrl: url_ListResourceComplianceSummaries_21627382,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListResourceDataSync_21627395 = ref object of OpenApiRestCall_21625435
proc url_ListResourceDataSync_21627397(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListResourceDataSync_21627396(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627398 = header.getOrDefault("X-Amz-Date")
  valid_21627398 = validateParameter(valid_21627398, JString, required = false,
                                   default = nil)
  if valid_21627398 != nil:
    section.add "X-Amz-Date", valid_21627398
  var valid_21627399 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627399 = validateParameter(valid_21627399, JString, required = false,
                                   default = nil)
  if valid_21627399 != nil:
    section.add "X-Amz-Security-Token", valid_21627399
  var valid_21627400 = header.getOrDefault("X-Amz-Target")
  valid_21627400 = validateParameter(valid_21627400, JString, required = true, default = newJString(
      "AmazonSSM.ListResourceDataSync"))
  if valid_21627400 != nil:
    section.add "X-Amz-Target", valid_21627400
  var valid_21627401 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627401 = validateParameter(valid_21627401, JString, required = false,
                                   default = nil)
  if valid_21627401 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627401
  var valid_21627402 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627402 = validateParameter(valid_21627402, JString, required = false,
                                   default = nil)
  if valid_21627402 != nil:
    section.add "X-Amz-Algorithm", valid_21627402
  var valid_21627403 = header.getOrDefault("X-Amz-Signature")
  valid_21627403 = validateParameter(valid_21627403, JString, required = false,
                                   default = nil)
  if valid_21627403 != nil:
    section.add "X-Amz-Signature", valid_21627403
  var valid_21627404 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627404 = validateParameter(valid_21627404, JString, required = false,
                                   default = nil)
  if valid_21627404 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627404
  var valid_21627405 = header.getOrDefault("X-Amz-Credential")
  valid_21627405 = validateParameter(valid_21627405, JString, required = false,
                                   default = nil)
  if valid_21627405 != nil:
    section.add "X-Amz-Credential", valid_21627405
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

proc call*(call_21627407: Call_ListResourceDataSync_21627395; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Lists your resource data sync configurations. Includes information about the last time a sync attempted to start, the last sync status, and the last time a sync successfully completed.</p> <p>The number of sync configurations might be too large to return using a single call to <code>ListResourceDataSync</code>. You can limit the number of sync configurations returned by using the <code>MaxResults</code> parameter. To determine whether there are more sync configurations to list, check the value of <code>NextToken</code> in the output. If there are more sync configurations to list, you can request them by specifying the <code>NextToken</code> returned in the call to the parameter of a subsequent call. </p>
  ## 
  let valid = call_21627407.validator(path, query, header, formData, body, _)
  let scheme = call_21627407.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627407.makeUrl(scheme.get, call_21627407.host, call_21627407.base,
                               call_21627407.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627407, uri, valid, _)

proc call*(call_21627408: Call_ListResourceDataSync_21627395; body: JsonNode): Recallable =
  ## listResourceDataSync
  ## <p>Lists your resource data sync configurations. Includes information about the last time a sync attempted to start, the last sync status, and the last time a sync successfully completed.</p> <p>The number of sync configurations might be too large to return using a single call to <code>ListResourceDataSync</code>. You can limit the number of sync configurations returned by using the <code>MaxResults</code> parameter. To determine whether there are more sync configurations to list, check the value of <code>NextToken</code> in the output. If there are more sync configurations to list, you can request them by specifying the <code>NextToken</code> returned in the call to the parameter of a subsequent call. </p>
  ##   body: JObject (required)
  var body_21627409 = newJObject()
  if body != nil:
    body_21627409 = body
  result = call_21627408.call(nil, nil, nil, nil, body_21627409)

var listResourceDataSync* = Call_ListResourceDataSync_21627395(
    name: "listResourceDataSync", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.ListResourceDataSync",
    validator: validate_ListResourceDataSync_21627396, base: "/",
    makeUrl: url_ListResourceDataSync_21627397,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_21627410 = ref object of OpenApiRestCall_21625435
proc url_ListTagsForResource_21627412(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTagsForResource_21627411(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627413 = header.getOrDefault("X-Amz-Date")
  valid_21627413 = validateParameter(valid_21627413, JString, required = false,
                                   default = nil)
  if valid_21627413 != nil:
    section.add "X-Amz-Date", valid_21627413
  var valid_21627414 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627414 = validateParameter(valid_21627414, JString, required = false,
                                   default = nil)
  if valid_21627414 != nil:
    section.add "X-Amz-Security-Token", valid_21627414
  var valid_21627415 = header.getOrDefault("X-Amz-Target")
  valid_21627415 = validateParameter(valid_21627415, JString, required = true, default = newJString(
      "AmazonSSM.ListTagsForResource"))
  if valid_21627415 != nil:
    section.add "X-Amz-Target", valid_21627415
  var valid_21627416 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627416 = validateParameter(valid_21627416, JString, required = false,
                                   default = nil)
  if valid_21627416 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627416
  var valid_21627417 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627417 = validateParameter(valid_21627417, JString, required = false,
                                   default = nil)
  if valid_21627417 != nil:
    section.add "X-Amz-Algorithm", valid_21627417
  var valid_21627418 = header.getOrDefault("X-Amz-Signature")
  valid_21627418 = validateParameter(valid_21627418, JString, required = false,
                                   default = nil)
  if valid_21627418 != nil:
    section.add "X-Amz-Signature", valid_21627418
  var valid_21627419 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627419 = validateParameter(valid_21627419, JString, required = false,
                                   default = nil)
  if valid_21627419 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627419
  var valid_21627420 = header.getOrDefault("X-Amz-Credential")
  valid_21627420 = validateParameter(valid_21627420, JString, required = false,
                                   default = nil)
  if valid_21627420 != nil:
    section.add "X-Amz-Credential", valid_21627420
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

proc call*(call_21627422: Call_ListTagsForResource_21627410; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a list of the tags assigned to the specified resource.
  ## 
  let valid = call_21627422.validator(path, query, header, formData, body, _)
  let scheme = call_21627422.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627422.makeUrl(scheme.get, call_21627422.host, call_21627422.base,
                               call_21627422.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627422, uri, valid, _)

proc call*(call_21627423: Call_ListTagsForResource_21627410; body: JsonNode): Recallable =
  ## listTagsForResource
  ## Returns a list of the tags assigned to the specified resource.
  ##   body: JObject (required)
  var body_21627424 = newJObject()
  if body != nil:
    body_21627424 = body
  result = call_21627423.call(nil, nil, nil, nil, body_21627424)

var listTagsForResource* = Call_ListTagsForResource_21627410(
    name: "listTagsForResource", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.ListTagsForResource",
    validator: validate_ListTagsForResource_21627411, base: "/",
    makeUrl: url_ListTagsForResource_21627412,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ModifyDocumentPermission_21627425 = ref object of OpenApiRestCall_21625435
proc url_ModifyDocumentPermission_21627427(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ModifyDocumentPermission_21627426(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627428 = header.getOrDefault("X-Amz-Date")
  valid_21627428 = validateParameter(valid_21627428, JString, required = false,
                                   default = nil)
  if valid_21627428 != nil:
    section.add "X-Amz-Date", valid_21627428
  var valid_21627429 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627429 = validateParameter(valid_21627429, JString, required = false,
                                   default = nil)
  if valid_21627429 != nil:
    section.add "X-Amz-Security-Token", valid_21627429
  var valid_21627430 = header.getOrDefault("X-Amz-Target")
  valid_21627430 = validateParameter(valid_21627430, JString, required = true, default = newJString(
      "AmazonSSM.ModifyDocumentPermission"))
  if valid_21627430 != nil:
    section.add "X-Amz-Target", valid_21627430
  var valid_21627431 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627431 = validateParameter(valid_21627431, JString, required = false,
                                   default = nil)
  if valid_21627431 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627431
  var valid_21627432 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627432 = validateParameter(valid_21627432, JString, required = false,
                                   default = nil)
  if valid_21627432 != nil:
    section.add "X-Amz-Algorithm", valid_21627432
  var valid_21627433 = header.getOrDefault("X-Amz-Signature")
  valid_21627433 = validateParameter(valid_21627433, JString, required = false,
                                   default = nil)
  if valid_21627433 != nil:
    section.add "X-Amz-Signature", valid_21627433
  var valid_21627434 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627434 = validateParameter(valid_21627434, JString, required = false,
                                   default = nil)
  if valid_21627434 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627434
  var valid_21627435 = header.getOrDefault("X-Amz-Credential")
  valid_21627435 = validateParameter(valid_21627435, JString, required = false,
                                   default = nil)
  if valid_21627435 != nil:
    section.add "X-Amz-Credential", valid_21627435
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

proc call*(call_21627437: Call_ModifyDocumentPermission_21627425;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Shares a Systems Manager document publicly or privately. If you share a document privately, you must specify the AWS user account IDs for those people who can use the document. If you share a document publicly, you must specify <i>All</i> as the account ID.
  ## 
  let valid = call_21627437.validator(path, query, header, formData, body, _)
  let scheme = call_21627437.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627437.makeUrl(scheme.get, call_21627437.host, call_21627437.base,
                               call_21627437.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627437, uri, valid, _)

proc call*(call_21627438: Call_ModifyDocumentPermission_21627425; body: JsonNode): Recallable =
  ## modifyDocumentPermission
  ## Shares a Systems Manager document publicly or privately. If you share a document privately, you must specify the AWS user account IDs for those people who can use the document. If you share a document publicly, you must specify <i>All</i> as the account ID.
  ##   body: JObject (required)
  var body_21627439 = newJObject()
  if body != nil:
    body_21627439 = body
  result = call_21627438.call(nil, nil, nil, nil, body_21627439)

var modifyDocumentPermission* = Call_ModifyDocumentPermission_21627425(
    name: "modifyDocumentPermission", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.ModifyDocumentPermission",
    validator: validate_ModifyDocumentPermission_21627426, base: "/",
    makeUrl: url_ModifyDocumentPermission_21627427,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutComplianceItems_21627440 = ref object of OpenApiRestCall_21625435
proc url_PutComplianceItems_21627442(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutComplianceItems_21627441(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627443 = header.getOrDefault("X-Amz-Date")
  valid_21627443 = validateParameter(valid_21627443, JString, required = false,
                                   default = nil)
  if valid_21627443 != nil:
    section.add "X-Amz-Date", valid_21627443
  var valid_21627444 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627444 = validateParameter(valid_21627444, JString, required = false,
                                   default = nil)
  if valid_21627444 != nil:
    section.add "X-Amz-Security-Token", valid_21627444
  var valid_21627445 = header.getOrDefault("X-Amz-Target")
  valid_21627445 = validateParameter(valid_21627445, JString, required = true, default = newJString(
      "AmazonSSM.PutComplianceItems"))
  if valid_21627445 != nil:
    section.add "X-Amz-Target", valid_21627445
  var valid_21627446 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627446 = validateParameter(valid_21627446, JString, required = false,
                                   default = nil)
  if valid_21627446 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627446
  var valid_21627447 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627447 = validateParameter(valid_21627447, JString, required = false,
                                   default = nil)
  if valid_21627447 != nil:
    section.add "X-Amz-Algorithm", valid_21627447
  var valid_21627448 = header.getOrDefault("X-Amz-Signature")
  valid_21627448 = validateParameter(valid_21627448, JString, required = false,
                                   default = nil)
  if valid_21627448 != nil:
    section.add "X-Amz-Signature", valid_21627448
  var valid_21627449 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627449 = validateParameter(valid_21627449, JString, required = false,
                                   default = nil)
  if valid_21627449 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627449
  var valid_21627450 = header.getOrDefault("X-Amz-Credential")
  valid_21627450 = validateParameter(valid_21627450, JString, required = false,
                                   default = nil)
  if valid_21627450 != nil:
    section.add "X-Amz-Credential", valid_21627450
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

proc call*(call_21627452: Call_PutComplianceItems_21627440; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Registers a compliance type and other compliance details on a designated resource. This action lets you register custom compliance details with a resource. This call overwrites existing compliance information on the resource, so you must provide a full list of compliance items each time that you send the request.</p> <p>ComplianceType can be one of the following:</p> <ul> <li> <p>ExecutionId: The execution ID when the patch, association, or custom compliance item was applied.</p> </li> <li> <p>ExecutionType: Specify patch, association, or Custom:<code>string</code>.</p> </li> <li> <p>ExecutionTime. The time the patch, association, or custom compliance item was applied to the instance.</p> </li> <li> <p>Id: The patch, association, or custom compliance ID.</p> </li> <li> <p>Title: A title.</p> </li> <li> <p>Status: The status of the compliance item. For example, <code>approved</code> for patches, or <code>Failed</code> for associations.</p> </li> <li> <p>Severity: A patch severity. For example, <code>critical</code>.</p> </li> <li> <p>DocumentName: A SSM document name. For example, AWS-RunPatchBaseline.</p> </li> <li> <p>DocumentVersion: An SSM document version number. For example, 4.</p> </li> <li> <p>Classification: A patch classification. For example, <code>security updates</code>.</p> </li> <li> <p>PatchBaselineId: A patch baseline ID.</p> </li> <li> <p>PatchSeverity: A patch severity. For example, <code>Critical</code>.</p> </li> <li> <p>PatchState: A patch state. For example, <code>InstancesWithFailedPatches</code>.</p> </li> <li> <p>PatchGroup: The name of a patch group.</p> </li> <li> <p>InstalledTime: The time the association, patch, or custom compliance item was applied to the resource. Specify the time by using the following format: yyyy-MM-dd'T'HH:mm:ss'Z'</p> </li> </ul>
  ## 
  let valid = call_21627452.validator(path, query, header, formData, body, _)
  let scheme = call_21627452.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627452.makeUrl(scheme.get, call_21627452.host, call_21627452.base,
                               call_21627452.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627452, uri, valid, _)

proc call*(call_21627453: Call_PutComplianceItems_21627440; body: JsonNode): Recallable =
  ## putComplianceItems
  ## <p>Registers a compliance type and other compliance details on a designated resource. This action lets you register custom compliance details with a resource. This call overwrites existing compliance information on the resource, so you must provide a full list of compliance items each time that you send the request.</p> <p>ComplianceType can be one of the following:</p> <ul> <li> <p>ExecutionId: The execution ID when the patch, association, or custom compliance item was applied.</p> </li> <li> <p>ExecutionType: Specify patch, association, or Custom:<code>string</code>.</p> </li> <li> <p>ExecutionTime. The time the patch, association, or custom compliance item was applied to the instance.</p> </li> <li> <p>Id: The patch, association, or custom compliance ID.</p> </li> <li> <p>Title: A title.</p> </li> <li> <p>Status: The status of the compliance item. For example, <code>approved</code> for patches, or <code>Failed</code> for associations.</p> </li> <li> <p>Severity: A patch severity. For example, <code>critical</code>.</p> </li> <li> <p>DocumentName: A SSM document name. For example, AWS-RunPatchBaseline.</p> </li> <li> <p>DocumentVersion: An SSM document version number. For example, 4.</p> </li> <li> <p>Classification: A patch classification. For example, <code>security updates</code>.</p> </li> <li> <p>PatchBaselineId: A patch baseline ID.</p> </li> <li> <p>PatchSeverity: A patch severity. For example, <code>Critical</code>.</p> </li> <li> <p>PatchState: A patch state. For example, <code>InstancesWithFailedPatches</code>.</p> </li> <li> <p>PatchGroup: The name of a patch group.</p> </li> <li> <p>InstalledTime: The time the association, patch, or custom compliance item was applied to the resource. Specify the time by using the following format: yyyy-MM-dd'T'HH:mm:ss'Z'</p> </li> </ul>
  ##   body: JObject (required)
  var body_21627454 = newJObject()
  if body != nil:
    body_21627454 = body
  result = call_21627453.call(nil, nil, nil, nil, body_21627454)

var putComplianceItems* = Call_PutComplianceItems_21627440(
    name: "putComplianceItems", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.PutComplianceItems",
    validator: validate_PutComplianceItems_21627441, base: "/",
    makeUrl: url_PutComplianceItems_21627442, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutInventory_21627455 = ref object of OpenApiRestCall_21625435
proc url_PutInventory_21627457(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutInventory_21627456(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21627458 = header.getOrDefault("X-Amz-Date")
  valid_21627458 = validateParameter(valid_21627458, JString, required = false,
                                   default = nil)
  if valid_21627458 != nil:
    section.add "X-Amz-Date", valid_21627458
  var valid_21627459 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627459 = validateParameter(valid_21627459, JString, required = false,
                                   default = nil)
  if valid_21627459 != nil:
    section.add "X-Amz-Security-Token", valid_21627459
  var valid_21627460 = header.getOrDefault("X-Amz-Target")
  valid_21627460 = validateParameter(valid_21627460, JString, required = true, default = newJString(
      "AmazonSSM.PutInventory"))
  if valid_21627460 != nil:
    section.add "X-Amz-Target", valid_21627460
  var valid_21627461 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627461 = validateParameter(valid_21627461, JString, required = false,
                                   default = nil)
  if valid_21627461 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627461
  var valid_21627462 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627462 = validateParameter(valid_21627462, JString, required = false,
                                   default = nil)
  if valid_21627462 != nil:
    section.add "X-Amz-Algorithm", valid_21627462
  var valid_21627463 = header.getOrDefault("X-Amz-Signature")
  valid_21627463 = validateParameter(valid_21627463, JString, required = false,
                                   default = nil)
  if valid_21627463 != nil:
    section.add "X-Amz-Signature", valid_21627463
  var valid_21627464 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627464 = validateParameter(valid_21627464, JString, required = false,
                                   default = nil)
  if valid_21627464 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627464
  var valid_21627465 = header.getOrDefault("X-Amz-Credential")
  valid_21627465 = validateParameter(valid_21627465, JString, required = false,
                                   default = nil)
  if valid_21627465 != nil:
    section.add "X-Amz-Credential", valid_21627465
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

proc call*(call_21627467: Call_PutInventory_21627455; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Bulk update custom inventory items on one more instance. The request adds an inventory item, if it doesn't already exist, or updates an inventory item, if it does exist.
  ## 
  let valid = call_21627467.validator(path, query, header, formData, body, _)
  let scheme = call_21627467.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627467.makeUrl(scheme.get, call_21627467.host, call_21627467.base,
                               call_21627467.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627467, uri, valid, _)

proc call*(call_21627468: Call_PutInventory_21627455; body: JsonNode): Recallable =
  ## putInventory
  ## Bulk update custom inventory items on one more instance. The request adds an inventory item, if it doesn't already exist, or updates an inventory item, if it does exist.
  ##   body: JObject (required)
  var body_21627469 = newJObject()
  if body != nil:
    body_21627469 = body
  result = call_21627468.call(nil, nil, nil, nil, body_21627469)

var putInventory* = Call_PutInventory_21627455(name: "putInventory",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.PutInventory",
    validator: validate_PutInventory_21627456, base: "/", makeUrl: url_PutInventory_21627457,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutParameter_21627470 = ref object of OpenApiRestCall_21625435
proc url_PutParameter_21627472(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutParameter_21627471(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21627473 = header.getOrDefault("X-Amz-Date")
  valid_21627473 = validateParameter(valid_21627473, JString, required = false,
                                   default = nil)
  if valid_21627473 != nil:
    section.add "X-Amz-Date", valid_21627473
  var valid_21627474 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627474 = validateParameter(valid_21627474, JString, required = false,
                                   default = nil)
  if valid_21627474 != nil:
    section.add "X-Amz-Security-Token", valid_21627474
  var valid_21627475 = header.getOrDefault("X-Amz-Target")
  valid_21627475 = validateParameter(valid_21627475, JString, required = true, default = newJString(
      "AmazonSSM.PutParameter"))
  if valid_21627475 != nil:
    section.add "X-Amz-Target", valid_21627475
  var valid_21627476 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627476 = validateParameter(valid_21627476, JString, required = false,
                                   default = nil)
  if valid_21627476 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627476
  var valid_21627477 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627477 = validateParameter(valid_21627477, JString, required = false,
                                   default = nil)
  if valid_21627477 != nil:
    section.add "X-Amz-Algorithm", valid_21627477
  var valid_21627478 = header.getOrDefault("X-Amz-Signature")
  valid_21627478 = validateParameter(valid_21627478, JString, required = false,
                                   default = nil)
  if valid_21627478 != nil:
    section.add "X-Amz-Signature", valid_21627478
  var valid_21627479 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627479 = validateParameter(valid_21627479, JString, required = false,
                                   default = nil)
  if valid_21627479 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627479
  var valid_21627480 = header.getOrDefault("X-Amz-Credential")
  valid_21627480 = validateParameter(valid_21627480, JString, required = false,
                                   default = nil)
  if valid_21627480 != nil:
    section.add "X-Amz-Credential", valid_21627480
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

proc call*(call_21627482: Call_PutParameter_21627470; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Add a parameter to the system.
  ## 
  let valid = call_21627482.validator(path, query, header, formData, body, _)
  let scheme = call_21627482.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627482.makeUrl(scheme.get, call_21627482.host, call_21627482.base,
                               call_21627482.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627482, uri, valid, _)

proc call*(call_21627483: Call_PutParameter_21627470; body: JsonNode): Recallable =
  ## putParameter
  ## Add a parameter to the system.
  ##   body: JObject (required)
  var body_21627484 = newJObject()
  if body != nil:
    body_21627484 = body
  result = call_21627483.call(nil, nil, nil, nil, body_21627484)

var putParameter* = Call_PutParameter_21627470(name: "putParameter",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.PutParameter",
    validator: validate_PutParameter_21627471, base: "/", makeUrl: url_PutParameter_21627472,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RegisterDefaultPatchBaseline_21627485 = ref object of OpenApiRestCall_21625435
proc url_RegisterDefaultPatchBaseline_21627487(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_RegisterDefaultPatchBaseline_21627486(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21627488 = header.getOrDefault("X-Amz-Date")
  valid_21627488 = validateParameter(valid_21627488, JString, required = false,
                                   default = nil)
  if valid_21627488 != nil:
    section.add "X-Amz-Date", valid_21627488
  var valid_21627489 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627489 = validateParameter(valid_21627489, JString, required = false,
                                   default = nil)
  if valid_21627489 != nil:
    section.add "X-Amz-Security-Token", valid_21627489
  var valid_21627490 = header.getOrDefault("X-Amz-Target")
  valid_21627490 = validateParameter(valid_21627490, JString, required = true, default = newJString(
      "AmazonSSM.RegisterDefaultPatchBaseline"))
  if valid_21627490 != nil:
    section.add "X-Amz-Target", valid_21627490
  var valid_21627491 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627491 = validateParameter(valid_21627491, JString, required = false,
                                   default = nil)
  if valid_21627491 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627491
  var valid_21627492 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627492 = validateParameter(valid_21627492, JString, required = false,
                                   default = nil)
  if valid_21627492 != nil:
    section.add "X-Amz-Algorithm", valid_21627492
  var valid_21627493 = header.getOrDefault("X-Amz-Signature")
  valid_21627493 = validateParameter(valid_21627493, JString, required = false,
                                   default = nil)
  if valid_21627493 != nil:
    section.add "X-Amz-Signature", valid_21627493
  var valid_21627494 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627494 = validateParameter(valid_21627494, JString, required = false,
                                   default = nil)
  if valid_21627494 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627494
  var valid_21627495 = header.getOrDefault("X-Amz-Credential")
  valid_21627495 = validateParameter(valid_21627495, JString, required = false,
                                   default = nil)
  if valid_21627495 != nil:
    section.add "X-Amz-Credential", valid_21627495
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

proc call*(call_21627497: Call_RegisterDefaultPatchBaseline_21627485;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Defines the default patch baseline for the relevant operating system.</p> <p>To reset the AWS predefined patch baseline as the default, specify the full patch baseline ARN as the baseline ID value. For example, for CentOS, specify <code>arn:aws:ssm:us-east-2:733109147000:patchbaseline/pb-0574b43a65ea646ed</code> instead of <code>pb-0574b43a65ea646ed</code>.</p>
  ## 
  let valid = call_21627497.validator(path, query, header, formData, body, _)
  let scheme = call_21627497.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627497.makeUrl(scheme.get, call_21627497.host, call_21627497.base,
                               call_21627497.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627497, uri, valid, _)

proc call*(call_21627498: Call_RegisterDefaultPatchBaseline_21627485;
          body: JsonNode): Recallable =
  ## registerDefaultPatchBaseline
  ## <p>Defines the default patch baseline for the relevant operating system.</p> <p>To reset the AWS predefined patch baseline as the default, specify the full patch baseline ARN as the baseline ID value. For example, for CentOS, specify <code>arn:aws:ssm:us-east-2:733109147000:patchbaseline/pb-0574b43a65ea646ed</code> instead of <code>pb-0574b43a65ea646ed</code>.</p>
  ##   body: JObject (required)
  var body_21627499 = newJObject()
  if body != nil:
    body_21627499 = body
  result = call_21627498.call(nil, nil, nil, nil, body_21627499)

var registerDefaultPatchBaseline* = Call_RegisterDefaultPatchBaseline_21627485(
    name: "registerDefaultPatchBaseline", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.RegisterDefaultPatchBaseline",
    validator: validate_RegisterDefaultPatchBaseline_21627486, base: "/",
    makeUrl: url_RegisterDefaultPatchBaseline_21627487,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RegisterPatchBaselineForPatchGroup_21627500 = ref object of OpenApiRestCall_21625435
proc url_RegisterPatchBaselineForPatchGroup_21627502(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_RegisterPatchBaselineForPatchGroup_21627501(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21627503 = header.getOrDefault("X-Amz-Date")
  valid_21627503 = validateParameter(valid_21627503, JString, required = false,
                                   default = nil)
  if valid_21627503 != nil:
    section.add "X-Amz-Date", valid_21627503
  var valid_21627504 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627504 = validateParameter(valid_21627504, JString, required = false,
                                   default = nil)
  if valid_21627504 != nil:
    section.add "X-Amz-Security-Token", valid_21627504
  var valid_21627505 = header.getOrDefault("X-Amz-Target")
  valid_21627505 = validateParameter(valid_21627505, JString, required = true, default = newJString(
      "AmazonSSM.RegisterPatchBaselineForPatchGroup"))
  if valid_21627505 != nil:
    section.add "X-Amz-Target", valid_21627505
  var valid_21627506 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627506 = validateParameter(valid_21627506, JString, required = false,
                                   default = nil)
  if valid_21627506 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627506
  var valid_21627507 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627507 = validateParameter(valid_21627507, JString, required = false,
                                   default = nil)
  if valid_21627507 != nil:
    section.add "X-Amz-Algorithm", valid_21627507
  var valid_21627508 = header.getOrDefault("X-Amz-Signature")
  valid_21627508 = validateParameter(valid_21627508, JString, required = false,
                                   default = nil)
  if valid_21627508 != nil:
    section.add "X-Amz-Signature", valid_21627508
  var valid_21627509 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627509 = validateParameter(valid_21627509, JString, required = false,
                                   default = nil)
  if valid_21627509 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627509
  var valid_21627510 = header.getOrDefault("X-Amz-Credential")
  valid_21627510 = validateParameter(valid_21627510, JString, required = false,
                                   default = nil)
  if valid_21627510 != nil:
    section.add "X-Amz-Credential", valid_21627510
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

proc call*(call_21627512: Call_RegisterPatchBaselineForPatchGroup_21627500;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Registers a patch baseline for a patch group.
  ## 
  let valid = call_21627512.validator(path, query, header, formData, body, _)
  let scheme = call_21627512.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627512.makeUrl(scheme.get, call_21627512.host, call_21627512.base,
                               call_21627512.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627512, uri, valid, _)

proc call*(call_21627513: Call_RegisterPatchBaselineForPatchGroup_21627500;
          body: JsonNode): Recallable =
  ## registerPatchBaselineForPatchGroup
  ## Registers a patch baseline for a patch group.
  ##   body: JObject (required)
  var body_21627514 = newJObject()
  if body != nil:
    body_21627514 = body
  result = call_21627513.call(nil, nil, nil, nil, body_21627514)

var registerPatchBaselineForPatchGroup* = Call_RegisterPatchBaselineForPatchGroup_21627500(
    name: "registerPatchBaselineForPatchGroup", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.RegisterPatchBaselineForPatchGroup",
    validator: validate_RegisterPatchBaselineForPatchGroup_21627501, base: "/",
    makeUrl: url_RegisterPatchBaselineForPatchGroup_21627502,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RegisterTargetWithMaintenanceWindow_21627515 = ref object of OpenApiRestCall_21625435
proc url_RegisterTargetWithMaintenanceWindow_21627517(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_RegisterTargetWithMaintenanceWindow_21627516(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21627518 = header.getOrDefault("X-Amz-Date")
  valid_21627518 = validateParameter(valid_21627518, JString, required = false,
                                   default = nil)
  if valid_21627518 != nil:
    section.add "X-Amz-Date", valid_21627518
  var valid_21627519 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627519 = validateParameter(valid_21627519, JString, required = false,
                                   default = nil)
  if valid_21627519 != nil:
    section.add "X-Amz-Security-Token", valid_21627519
  var valid_21627520 = header.getOrDefault("X-Amz-Target")
  valid_21627520 = validateParameter(valid_21627520, JString, required = true, default = newJString(
      "AmazonSSM.RegisterTargetWithMaintenanceWindow"))
  if valid_21627520 != nil:
    section.add "X-Amz-Target", valid_21627520
  var valid_21627521 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627521 = validateParameter(valid_21627521, JString, required = false,
                                   default = nil)
  if valid_21627521 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627521
  var valid_21627522 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627522 = validateParameter(valid_21627522, JString, required = false,
                                   default = nil)
  if valid_21627522 != nil:
    section.add "X-Amz-Algorithm", valid_21627522
  var valid_21627523 = header.getOrDefault("X-Amz-Signature")
  valid_21627523 = validateParameter(valid_21627523, JString, required = false,
                                   default = nil)
  if valid_21627523 != nil:
    section.add "X-Amz-Signature", valid_21627523
  var valid_21627524 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627524 = validateParameter(valid_21627524, JString, required = false,
                                   default = nil)
  if valid_21627524 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627524
  var valid_21627525 = header.getOrDefault("X-Amz-Credential")
  valid_21627525 = validateParameter(valid_21627525, JString, required = false,
                                   default = nil)
  if valid_21627525 != nil:
    section.add "X-Amz-Credential", valid_21627525
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

proc call*(call_21627527: Call_RegisterTargetWithMaintenanceWindow_21627515;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Registers a target with a maintenance window.
  ## 
  let valid = call_21627527.validator(path, query, header, formData, body, _)
  let scheme = call_21627527.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627527.makeUrl(scheme.get, call_21627527.host, call_21627527.base,
                               call_21627527.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627527, uri, valid, _)

proc call*(call_21627528: Call_RegisterTargetWithMaintenanceWindow_21627515;
          body: JsonNode): Recallable =
  ## registerTargetWithMaintenanceWindow
  ## Registers a target with a maintenance window.
  ##   body: JObject (required)
  var body_21627529 = newJObject()
  if body != nil:
    body_21627529 = body
  result = call_21627528.call(nil, nil, nil, nil, body_21627529)

var registerTargetWithMaintenanceWindow* = Call_RegisterTargetWithMaintenanceWindow_21627515(
    name: "registerTargetWithMaintenanceWindow", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.RegisterTargetWithMaintenanceWindow",
    validator: validate_RegisterTargetWithMaintenanceWindow_21627516, base: "/",
    makeUrl: url_RegisterTargetWithMaintenanceWindow_21627517,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RegisterTaskWithMaintenanceWindow_21627530 = ref object of OpenApiRestCall_21625435
proc url_RegisterTaskWithMaintenanceWindow_21627532(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_RegisterTaskWithMaintenanceWindow_21627531(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21627533 = header.getOrDefault("X-Amz-Date")
  valid_21627533 = validateParameter(valid_21627533, JString, required = false,
                                   default = nil)
  if valid_21627533 != nil:
    section.add "X-Amz-Date", valid_21627533
  var valid_21627534 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627534 = validateParameter(valid_21627534, JString, required = false,
                                   default = nil)
  if valid_21627534 != nil:
    section.add "X-Amz-Security-Token", valid_21627534
  var valid_21627535 = header.getOrDefault("X-Amz-Target")
  valid_21627535 = validateParameter(valid_21627535, JString, required = true, default = newJString(
      "AmazonSSM.RegisterTaskWithMaintenanceWindow"))
  if valid_21627535 != nil:
    section.add "X-Amz-Target", valid_21627535
  var valid_21627536 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627536 = validateParameter(valid_21627536, JString, required = false,
                                   default = nil)
  if valid_21627536 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627536
  var valid_21627537 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627537 = validateParameter(valid_21627537, JString, required = false,
                                   default = nil)
  if valid_21627537 != nil:
    section.add "X-Amz-Algorithm", valid_21627537
  var valid_21627538 = header.getOrDefault("X-Amz-Signature")
  valid_21627538 = validateParameter(valid_21627538, JString, required = false,
                                   default = nil)
  if valid_21627538 != nil:
    section.add "X-Amz-Signature", valid_21627538
  var valid_21627539 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627539 = validateParameter(valid_21627539, JString, required = false,
                                   default = nil)
  if valid_21627539 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627539
  var valid_21627540 = header.getOrDefault("X-Amz-Credential")
  valid_21627540 = validateParameter(valid_21627540, JString, required = false,
                                   default = nil)
  if valid_21627540 != nil:
    section.add "X-Amz-Credential", valid_21627540
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

proc call*(call_21627542: Call_RegisterTaskWithMaintenanceWindow_21627530;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Adds a new task to a maintenance window.
  ## 
  let valid = call_21627542.validator(path, query, header, formData, body, _)
  let scheme = call_21627542.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627542.makeUrl(scheme.get, call_21627542.host, call_21627542.base,
                               call_21627542.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627542, uri, valid, _)

proc call*(call_21627543: Call_RegisterTaskWithMaintenanceWindow_21627530;
          body: JsonNode): Recallable =
  ## registerTaskWithMaintenanceWindow
  ## Adds a new task to a maintenance window.
  ##   body: JObject (required)
  var body_21627544 = newJObject()
  if body != nil:
    body_21627544 = body
  result = call_21627543.call(nil, nil, nil, nil, body_21627544)

var registerTaskWithMaintenanceWindow* = Call_RegisterTaskWithMaintenanceWindow_21627530(
    name: "registerTaskWithMaintenanceWindow", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.RegisterTaskWithMaintenanceWindow",
    validator: validate_RegisterTaskWithMaintenanceWindow_21627531, base: "/",
    makeUrl: url_RegisterTaskWithMaintenanceWindow_21627532,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RemoveTagsFromResource_21627545 = ref object of OpenApiRestCall_21625435
proc url_RemoveTagsFromResource_21627547(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_RemoveTagsFromResource_21627546(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627548 = header.getOrDefault("X-Amz-Date")
  valid_21627548 = validateParameter(valid_21627548, JString, required = false,
                                   default = nil)
  if valid_21627548 != nil:
    section.add "X-Amz-Date", valid_21627548
  var valid_21627549 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627549 = validateParameter(valid_21627549, JString, required = false,
                                   default = nil)
  if valid_21627549 != nil:
    section.add "X-Amz-Security-Token", valid_21627549
  var valid_21627550 = header.getOrDefault("X-Amz-Target")
  valid_21627550 = validateParameter(valid_21627550, JString, required = true, default = newJString(
      "AmazonSSM.RemoveTagsFromResource"))
  if valid_21627550 != nil:
    section.add "X-Amz-Target", valid_21627550
  var valid_21627551 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627551 = validateParameter(valid_21627551, JString, required = false,
                                   default = nil)
  if valid_21627551 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627551
  var valid_21627552 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627552 = validateParameter(valid_21627552, JString, required = false,
                                   default = nil)
  if valid_21627552 != nil:
    section.add "X-Amz-Algorithm", valid_21627552
  var valid_21627553 = header.getOrDefault("X-Amz-Signature")
  valid_21627553 = validateParameter(valid_21627553, JString, required = false,
                                   default = nil)
  if valid_21627553 != nil:
    section.add "X-Amz-Signature", valid_21627553
  var valid_21627554 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627554 = validateParameter(valid_21627554, JString, required = false,
                                   default = nil)
  if valid_21627554 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627554
  var valid_21627555 = header.getOrDefault("X-Amz-Credential")
  valid_21627555 = validateParameter(valid_21627555, JString, required = false,
                                   default = nil)
  if valid_21627555 != nil:
    section.add "X-Amz-Credential", valid_21627555
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

proc call*(call_21627557: Call_RemoveTagsFromResource_21627545;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Removes tag keys from the specified resource.
  ## 
  let valid = call_21627557.validator(path, query, header, formData, body, _)
  let scheme = call_21627557.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627557.makeUrl(scheme.get, call_21627557.host, call_21627557.base,
                               call_21627557.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627557, uri, valid, _)

proc call*(call_21627558: Call_RemoveTagsFromResource_21627545; body: JsonNode): Recallable =
  ## removeTagsFromResource
  ## Removes tag keys from the specified resource.
  ##   body: JObject (required)
  var body_21627559 = newJObject()
  if body != nil:
    body_21627559 = body
  result = call_21627558.call(nil, nil, nil, nil, body_21627559)

var removeTagsFromResource* = Call_RemoveTagsFromResource_21627545(
    name: "removeTagsFromResource", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.RemoveTagsFromResource",
    validator: validate_RemoveTagsFromResource_21627546, base: "/",
    makeUrl: url_RemoveTagsFromResource_21627547,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ResetServiceSetting_21627560 = ref object of OpenApiRestCall_21625435
proc url_ResetServiceSetting_21627562(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ResetServiceSetting_21627561(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627563 = header.getOrDefault("X-Amz-Date")
  valid_21627563 = validateParameter(valid_21627563, JString, required = false,
                                   default = nil)
  if valid_21627563 != nil:
    section.add "X-Amz-Date", valid_21627563
  var valid_21627564 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627564 = validateParameter(valid_21627564, JString, required = false,
                                   default = nil)
  if valid_21627564 != nil:
    section.add "X-Amz-Security-Token", valid_21627564
  var valid_21627565 = header.getOrDefault("X-Amz-Target")
  valid_21627565 = validateParameter(valid_21627565, JString, required = true, default = newJString(
      "AmazonSSM.ResetServiceSetting"))
  if valid_21627565 != nil:
    section.add "X-Amz-Target", valid_21627565
  var valid_21627566 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627566 = validateParameter(valid_21627566, JString, required = false,
                                   default = nil)
  if valid_21627566 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627566
  var valid_21627567 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627567 = validateParameter(valid_21627567, JString, required = false,
                                   default = nil)
  if valid_21627567 != nil:
    section.add "X-Amz-Algorithm", valid_21627567
  var valid_21627568 = header.getOrDefault("X-Amz-Signature")
  valid_21627568 = validateParameter(valid_21627568, JString, required = false,
                                   default = nil)
  if valid_21627568 != nil:
    section.add "X-Amz-Signature", valid_21627568
  var valid_21627569 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627569 = validateParameter(valid_21627569, JString, required = false,
                                   default = nil)
  if valid_21627569 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627569
  var valid_21627570 = header.getOrDefault("X-Amz-Credential")
  valid_21627570 = validateParameter(valid_21627570, JString, required = false,
                                   default = nil)
  if valid_21627570 != nil:
    section.add "X-Amz-Credential", valid_21627570
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

proc call*(call_21627572: Call_ResetServiceSetting_21627560; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p> <code>ServiceSetting</code> is an account-level setting for an AWS service. This setting defines how a user interacts with or uses a service or a feature of a service. For example, if an AWS service charges money to the account based on feature or service usage, then the AWS service team might create a default setting of "false". This means the user can't use this feature unless they change the setting to "true" and intentionally opt in for a paid feature.</p> <p>Services map a <code>SettingId</code> object to a setting value. AWS services teams define the default value for a <code>SettingId</code>. You can't create a new <code>SettingId</code>, but you can overwrite the default value if you have the <code>ssm:UpdateServiceSetting</code> permission for the setting. Use the <a>GetServiceSetting</a> API action to view the current value. Use the <a>UpdateServiceSetting</a> API action to change the default setting. </p> <p>Reset the service setting for the account to the default value as provisioned by the AWS service team. </p>
  ## 
  let valid = call_21627572.validator(path, query, header, formData, body, _)
  let scheme = call_21627572.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627572.makeUrl(scheme.get, call_21627572.host, call_21627572.base,
                               call_21627572.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627572, uri, valid, _)

proc call*(call_21627573: Call_ResetServiceSetting_21627560; body: JsonNode): Recallable =
  ## resetServiceSetting
  ## <p> <code>ServiceSetting</code> is an account-level setting for an AWS service. This setting defines how a user interacts with or uses a service or a feature of a service. For example, if an AWS service charges money to the account based on feature or service usage, then the AWS service team might create a default setting of "false". This means the user can't use this feature unless they change the setting to "true" and intentionally opt in for a paid feature.</p> <p>Services map a <code>SettingId</code> object to a setting value. AWS services teams define the default value for a <code>SettingId</code>. You can't create a new <code>SettingId</code>, but you can overwrite the default value if you have the <code>ssm:UpdateServiceSetting</code> permission for the setting. Use the <a>GetServiceSetting</a> API action to view the current value. Use the <a>UpdateServiceSetting</a> API action to change the default setting. </p> <p>Reset the service setting for the account to the default value as provisioned by the AWS service team. </p>
  ##   body: JObject (required)
  var body_21627574 = newJObject()
  if body != nil:
    body_21627574 = body
  result = call_21627573.call(nil, nil, nil, nil, body_21627574)

var resetServiceSetting* = Call_ResetServiceSetting_21627560(
    name: "resetServiceSetting", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.ResetServiceSetting",
    validator: validate_ResetServiceSetting_21627561, base: "/",
    makeUrl: url_ResetServiceSetting_21627562,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ResumeSession_21627575 = ref object of OpenApiRestCall_21625435
proc url_ResumeSession_21627577(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ResumeSession_21627576(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21627578 = header.getOrDefault("X-Amz-Date")
  valid_21627578 = validateParameter(valid_21627578, JString, required = false,
                                   default = nil)
  if valid_21627578 != nil:
    section.add "X-Amz-Date", valid_21627578
  var valid_21627579 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627579 = validateParameter(valid_21627579, JString, required = false,
                                   default = nil)
  if valid_21627579 != nil:
    section.add "X-Amz-Security-Token", valid_21627579
  var valid_21627580 = header.getOrDefault("X-Amz-Target")
  valid_21627580 = validateParameter(valid_21627580, JString, required = true, default = newJString(
      "AmazonSSM.ResumeSession"))
  if valid_21627580 != nil:
    section.add "X-Amz-Target", valid_21627580
  var valid_21627581 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627581 = validateParameter(valid_21627581, JString, required = false,
                                   default = nil)
  if valid_21627581 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627581
  var valid_21627582 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627582 = validateParameter(valid_21627582, JString, required = false,
                                   default = nil)
  if valid_21627582 != nil:
    section.add "X-Amz-Algorithm", valid_21627582
  var valid_21627583 = header.getOrDefault("X-Amz-Signature")
  valid_21627583 = validateParameter(valid_21627583, JString, required = false,
                                   default = nil)
  if valid_21627583 != nil:
    section.add "X-Amz-Signature", valid_21627583
  var valid_21627584 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627584 = validateParameter(valid_21627584, JString, required = false,
                                   default = nil)
  if valid_21627584 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627584
  var valid_21627585 = header.getOrDefault("X-Amz-Credential")
  valid_21627585 = validateParameter(valid_21627585, JString, required = false,
                                   default = nil)
  if valid_21627585 != nil:
    section.add "X-Amz-Credential", valid_21627585
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

proc call*(call_21627587: Call_ResumeSession_21627575; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Reconnects a session to an instance after it has been disconnected. Connections can be resumed for disconnected sessions, but not terminated sessions.</p> <note> <p>This command is primarily for use by client machines to automatically reconnect during intermittent network issues. It is not intended for any other use.</p> </note>
  ## 
  let valid = call_21627587.validator(path, query, header, formData, body, _)
  let scheme = call_21627587.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627587.makeUrl(scheme.get, call_21627587.host, call_21627587.base,
                               call_21627587.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627587, uri, valid, _)

proc call*(call_21627588: Call_ResumeSession_21627575; body: JsonNode): Recallable =
  ## resumeSession
  ## <p>Reconnects a session to an instance after it has been disconnected. Connections can be resumed for disconnected sessions, but not terminated sessions.</p> <note> <p>This command is primarily for use by client machines to automatically reconnect during intermittent network issues. It is not intended for any other use.</p> </note>
  ##   body: JObject (required)
  var body_21627589 = newJObject()
  if body != nil:
    body_21627589 = body
  result = call_21627588.call(nil, nil, nil, nil, body_21627589)

var resumeSession* = Call_ResumeSession_21627575(name: "resumeSession",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.ResumeSession",
    validator: validate_ResumeSession_21627576, base: "/",
    makeUrl: url_ResumeSession_21627577, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SendAutomationSignal_21627590 = ref object of OpenApiRestCall_21625435
proc url_SendAutomationSignal_21627592(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_SendAutomationSignal_21627591(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627593 = header.getOrDefault("X-Amz-Date")
  valid_21627593 = validateParameter(valid_21627593, JString, required = false,
                                   default = nil)
  if valid_21627593 != nil:
    section.add "X-Amz-Date", valid_21627593
  var valid_21627594 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627594 = validateParameter(valid_21627594, JString, required = false,
                                   default = nil)
  if valid_21627594 != nil:
    section.add "X-Amz-Security-Token", valid_21627594
  var valid_21627595 = header.getOrDefault("X-Amz-Target")
  valid_21627595 = validateParameter(valid_21627595, JString, required = true, default = newJString(
      "AmazonSSM.SendAutomationSignal"))
  if valid_21627595 != nil:
    section.add "X-Amz-Target", valid_21627595
  var valid_21627596 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627596 = validateParameter(valid_21627596, JString, required = false,
                                   default = nil)
  if valid_21627596 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627596
  var valid_21627597 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627597 = validateParameter(valid_21627597, JString, required = false,
                                   default = nil)
  if valid_21627597 != nil:
    section.add "X-Amz-Algorithm", valid_21627597
  var valid_21627598 = header.getOrDefault("X-Amz-Signature")
  valid_21627598 = validateParameter(valid_21627598, JString, required = false,
                                   default = nil)
  if valid_21627598 != nil:
    section.add "X-Amz-Signature", valid_21627598
  var valid_21627599 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627599 = validateParameter(valid_21627599, JString, required = false,
                                   default = nil)
  if valid_21627599 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627599
  var valid_21627600 = header.getOrDefault("X-Amz-Credential")
  valid_21627600 = validateParameter(valid_21627600, JString, required = false,
                                   default = nil)
  if valid_21627600 != nil:
    section.add "X-Amz-Credential", valid_21627600
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

proc call*(call_21627602: Call_SendAutomationSignal_21627590; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Sends a signal to an Automation execution to change the current behavior or status of the execution. 
  ## 
  let valid = call_21627602.validator(path, query, header, formData, body, _)
  let scheme = call_21627602.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627602.makeUrl(scheme.get, call_21627602.host, call_21627602.base,
                               call_21627602.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627602, uri, valid, _)

proc call*(call_21627603: Call_SendAutomationSignal_21627590; body: JsonNode): Recallable =
  ## sendAutomationSignal
  ## Sends a signal to an Automation execution to change the current behavior or status of the execution. 
  ##   body: JObject (required)
  var body_21627604 = newJObject()
  if body != nil:
    body_21627604 = body
  result = call_21627603.call(nil, nil, nil, nil, body_21627604)

var sendAutomationSignal* = Call_SendAutomationSignal_21627590(
    name: "sendAutomationSignal", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.SendAutomationSignal",
    validator: validate_SendAutomationSignal_21627591, base: "/",
    makeUrl: url_SendAutomationSignal_21627592,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_SendCommand_21627605 = ref object of OpenApiRestCall_21625435
proc url_SendCommand_21627607(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_SendCommand_21627606(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627608 = header.getOrDefault("X-Amz-Date")
  valid_21627608 = validateParameter(valid_21627608, JString, required = false,
                                   default = nil)
  if valid_21627608 != nil:
    section.add "X-Amz-Date", valid_21627608
  var valid_21627609 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627609 = validateParameter(valid_21627609, JString, required = false,
                                   default = nil)
  if valid_21627609 != nil:
    section.add "X-Amz-Security-Token", valid_21627609
  var valid_21627610 = header.getOrDefault("X-Amz-Target")
  valid_21627610 = validateParameter(valid_21627610, JString, required = true, default = newJString(
      "AmazonSSM.SendCommand"))
  if valid_21627610 != nil:
    section.add "X-Amz-Target", valid_21627610
  var valid_21627611 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627611 = validateParameter(valid_21627611, JString, required = false,
                                   default = nil)
  if valid_21627611 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627611
  var valid_21627612 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627612 = validateParameter(valid_21627612, JString, required = false,
                                   default = nil)
  if valid_21627612 != nil:
    section.add "X-Amz-Algorithm", valid_21627612
  var valid_21627613 = header.getOrDefault("X-Amz-Signature")
  valid_21627613 = validateParameter(valid_21627613, JString, required = false,
                                   default = nil)
  if valid_21627613 != nil:
    section.add "X-Amz-Signature", valid_21627613
  var valid_21627614 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627614 = validateParameter(valid_21627614, JString, required = false,
                                   default = nil)
  if valid_21627614 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627614
  var valid_21627615 = header.getOrDefault("X-Amz-Credential")
  valid_21627615 = validateParameter(valid_21627615, JString, required = false,
                                   default = nil)
  if valid_21627615 != nil:
    section.add "X-Amz-Credential", valid_21627615
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

proc call*(call_21627617: Call_SendCommand_21627605; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Runs commands on one or more managed instances.
  ## 
  let valid = call_21627617.validator(path, query, header, formData, body, _)
  let scheme = call_21627617.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627617.makeUrl(scheme.get, call_21627617.host, call_21627617.base,
                               call_21627617.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627617, uri, valid, _)

proc call*(call_21627618: Call_SendCommand_21627605; body: JsonNode): Recallable =
  ## sendCommand
  ## Runs commands on one or more managed instances.
  ##   body: JObject (required)
  var body_21627619 = newJObject()
  if body != nil:
    body_21627619 = body
  result = call_21627618.call(nil, nil, nil, nil, body_21627619)

var sendCommand* = Call_SendCommand_21627605(name: "sendCommand",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.SendCommand",
    validator: validate_SendCommand_21627606, base: "/", makeUrl: url_SendCommand_21627607,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartAssociationsOnce_21627620 = ref object of OpenApiRestCall_21625435
proc url_StartAssociationsOnce_21627622(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StartAssociationsOnce_21627621(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627623 = header.getOrDefault("X-Amz-Date")
  valid_21627623 = validateParameter(valid_21627623, JString, required = false,
                                   default = nil)
  if valid_21627623 != nil:
    section.add "X-Amz-Date", valid_21627623
  var valid_21627624 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627624 = validateParameter(valid_21627624, JString, required = false,
                                   default = nil)
  if valid_21627624 != nil:
    section.add "X-Amz-Security-Token", valid_21627624
  var valid_21627625 = header.getOrDefault("X-Amz-Target")
  valid_21627625 = validateParameter(valid_21627625, JString, required = true, default = newJString(
      "AmazonSSM.StartAssociationsOnce"))
  if valid_21627625 != nil:
    section.add "X-Amz-Target", valid_21627625
  var valid_21627626 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627626 = validateParameter(valid_21627626, JString, required = false,
                                   default = nil)
  if valid_21627626 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627626
  var valid_21627627 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627627 = validateParameter(valid_21627627, JString, required = false,
                                   default = nil)
  if valid_21627627 != nil:
    section.add "X-Amz-Algorithm", valid_21627627
  var valid_21627628 = header.getOrDefault("X-Amz-Signature")
  valid_21627628 = validateParameter(valid_21627628, JString, required = false,
                                   default = nil)
  if valid_21627628 != nil:
    section.add "X-Amz-Signature", valid_21627628
  var valid_21627629 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627629 = validateParameter(valid_21627629, JString, required = false,
                                   default = nil)
  if valid_21627629 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627629
  var valid_21627630 = header.getOrDefault("X-Amz-Credential")
  valid_21627630 = validateParameter(valid_21627630, JString, required = false,
                                   default = nil)
  if valid_21627630 != nil:
    section.add "X-Amz-Credential", valid_21627630
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

proc call*(call_21627632: Call_StartAssociationsOnce_21627620;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Use this API action to run an association immediately and only one time. This action can be helpful when troubleshooting associations.
  ## 
  let valid = call_21627632.validator(path, query, header, formData, body, _)
  let scheme = call_21627632.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627632.makeUrl(scheme.get, call_21627632.host, call_21627632.base,
                               call_21627632.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627632, uri, valid, _)

proc call*(call_21627633: Call_StartAssociationsOnce_21627620; body: JsonNode): Recallable =
  ## startAssociationsOnce
  ## Use this API action to run an association immediately and only one time. This action can be helpful when troubleshooting associations.
  ##   body: JObject (required)
  var body_21627634 = newJObject()
  if body != nil:
    body_21627634 = body
  result = call_21627633.call(nil, nil, nil, nil, body_21627634)

var startAssociationsOnce* = Call_StartAssociationsOnce_21627620(
    name: "startAssociationsOnce", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.StartAssociationsOnce",
    validator: validate_StartAssociationsOnce_21627621, base: "/",
    makeUrl: url_StartAssociationsOnce_21627622,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartAutomationExecution_21627635 = ref object of OpenApiRestCall_21625435
proc url_StartAutomationExecution_21627637(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StartAutomationExecution_21627636(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627638 = header.getOrDefault("X-Amz-Date")
  valid_21627638 = validateParameter(valid_21627638, JString, required = false,
                                   default = nil)
  if valid_21627638 != nil:
    section.add "X-Amz-Date", valid_21627638
  var valid_21627639 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627639 = validateParameter(valid_21627639, JString, required = false,
                                   default = nil)
  if valid_21627639 != nil:
    section.add "X-Amz-Security-Token", valid_21627639
  var valid_21627640 = header.getOrDefault("X-Amz-Target")
  valid_21627640 = validateParameter(valid_21627640, JString, required = true, default = newJString(
      "AmazonSSM.StartAutomationExecution"))
  if valid_21627640 != nil:
    section.add "X-Amz-Target", valid_21627640
  var valid_21627641 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627641 = validateParameter(valid_21627641, JString, required = false,
                                   default = nil)
  if valid_21627641 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627641
  var valid_21627642 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627642 = validateParameter(valid_21627642, JString, required = false,
                                   default = nil)
  if valid_21627642 != nil:
    section.add "X-Amz-Algorithm", valid_21627642
  var valid_21627643 = header.getOrDefault("X-Amz-Signature")
  valid_21627643 = validateParameter(valid_21627643, JString, required = false,
                                   default = nil)
  if valid_21627643 != nil:
    section.add "X-Amz-Signature", valid_21627643
  var valid_21627644 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627644 = validateParameter(valid_21627644, JString, required = false,
                                   default = nil)
  if valid_21627644 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627644
  var valid_21627645 = header.getOrDefault("X-Amz-Credential")
  valid_21627645 = validateParameter(valid_21627645, JString, required = false,
                                   default = nil)
  if valid_21627645 != nil:
    section.add "X-Amz-Credential", valid_21627645
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

proc call*(call_21627647: Call_StartAutomationExecution_21627635;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Initiates execution of an Automation document.
  ## 
  let valid = call_21627647.validator(path, query, header, formData, body, _)
  let scheme = call_21627647.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627647.makeUrl(scheme.get, call_21627647.host, call_21627647.base,
                               call_21627647.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627647, uri, valid, _)

proc call*(call_21627648: Call_StartAutomationExecution_21627635; body: JsonNode): Recallable =
  ## startAutomationExecution
  ## Initiates execution of an Automation document.
  ##   body: JObject (required)
  var body_21627649 = newJObject()
  if body != nil:
    body_21627649 = body
  result = call_21627648.call(nil, nil, nil, nil, body_21627649)

var startAutomationExecution* = Call_StartAutomationExecution_21627635(
    name: "startAutomationExecution", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.StartAutomationExecution",
    validator: validate_StartAutomationExecution_21627636, base: "/",
    makeUrl: url_StartAutomationExecution_21627637,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartSession_21627650 = ref object of OpenApiRestCall_21625435
proc url_StartSession_21627652(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StartSession_21627651(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21627653 = header.getOrDefault("X-Amz-Date")
  valid_21627653 = validateParameter(valid_21627653, JString, required = false,
                                   default = nil)
  if valid_21627653 != nil:
    section.add "X-Amz-Date", valid_21627653
  var valid_21627654 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627654 = validateParameter(valid_21627654, JString, required = false,
                                   default = nil)
  if valid_21627654 != nil:
    section.add "X-Amz-Security-Token", valid_21627654
  var valid_21627655 = header.getOrDefault("X-Amz-Target")
  valid_21627655 = validateParameter(valid_21627655, JString, required = true, default = newJString(
      "AmazonSSM.StartSession"))
  if valid_21627655 != nil:
    section.add "X-Amz-Target", valid_21627655
  var valid_21627656 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627656 = validateParameter(valid_21627656, JString, required = false,
                                   default = nil)
  if valid_21627656 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627656
  var valid_21627657 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627657 = validateParameter(valid_21627657, JString, required = false,
                                   default = nil)
  if valid_21627657 != nil:
    section.add "X-Amz-Algorithm", valid_21627657
  var valid_21627658 = header.getOrDefault("X-Amz-Signature")
  valid_21627658 = validateParameter(valid_21627658, JString, required = false,
                                   default = nil)
  if valid_21627658 != nil:
    section.add "X-Amz-Signature", valid_21627658
  var valid_21627659 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627659 = validateParameter(valid_21627659, JString, required = false,
                                   default = nil)
  if valid_21627659 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627659
  var valid_21627660 = header.getOrDefault("X-Amz-Credential")
  valid_21627660 = validateParameter(valid_21627660, JString, required = false,
                                   default = nil)
  if valid_21627660 != nil:
    section.add "X-Amz-Credential", valid_21627660
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

proc call*(call_21627662: Call_StartSession_21627650; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Initiates a connection to a target (for example, an instance) for a Session Manager session. Returns a URL and token that can be used to open a WebSocket connection for sending input and receiving outputs.</p> <note> <p>AWS CLI usage: <code>start-session</code> is an interactive command that requires the Session Manager plugin to be installed on the client machine making the call. For information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html"> Install the Session Manager Plugin for the AWS CLI</a> in the <i>AWS Systems Manager User Guide</i>.</p> <p>AWS Tools for PowerShell usage: Start-SSMSession is not currently supported by AWS Tools for PowerShell on Windows local machines.</p> </note>
  ## 
  let valid = call_21627662.validator(path, query, header, formData, body, _)
  let scheme = call_21627662.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627662.makeUrl(scheme.get, call_21627662.host, call_21627662.base,
                               call_21627662.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627662, uri, valid, _)

proc call*(call_21627663: Call_StartSession_21627650; body: JsonNode): Recallable =
  ## startSession
  ## <p>Initiates a connection to a target (for example, an instance) for a Session Manager session. Returns a URL and token that can be used to open a WebSocket connection for sending input and receiving outputs.</p> <note> <p>AWS CLI usage: <code>start-session</code> is an interactive command that requires the Session Manager plugin to be installed on the client machine making the call. For information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html"> Install the Session Manager Plugin for the AWS CLI</a> in the <i>AWS Systems Manager User Guide</i>.</p> <p>AWS Tools for PowerShell usage: Start-SSMSession is not currently supported by AWS Tools for PowerShell on Windows local machines.</p> </note>
  ##   body: JObject (required)
  var body_21627664 = newJObject()
  if body != nil:
    body_21627664 = body
  result = call_21627663.call(nil, nil, nil, nil, body_21627664)

var startSession* = Call_StartSession_21627650(name: "startSession",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.StartSession",
    validator: validate_StartSession_21627651, base: "/", makeUrl: url_StartSession_21627652,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopAutomationExecution_21627665 = ref object of OpenApiRestCall_21625435
proc url_StopAutomationExecution_21627667(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StopAutomationExecution_21627666(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627668 = header.getOrDefault("X-Amz-Date")
  valid_21627668 = validateParameter(valid_21627668, JString, required = false,
                                   default = nil)
  if valid_21627668 != nil:
    section.add "X-Amz-Date", valid_21627668
  var valid_21627669 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627669 = validateParameter(valid_21627669, JString, required = false,
                                   default = nil)
  if valid_21627669 != nil:
    section.add "X-Amz-Security-Token", valid_21627669
  var valid_21627670 = header.getOrDefault("X-Amz-Target")
  valid_21627670 = validateParameter(valid_21627670, JString, required = true, default = newJString(
      "AmazonSSM.StopAutomationExecution"))
  if valid_21627670 != nil:
    section.add "X-Amz-Target", valid_21627670
  var valid_21627671 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627671 = validateParameter(valid_21627671, JString, required = false,
                                   default = nil)
  if valid_21627671 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627671
  var valid_21627672 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627672 = validateParameter(valid_21627672, JString, required = false,
                                   default = nil)
  if valid_21627672 != nil:
    section.add "X-Amz-Algorithm", valid_21627672
  var valid_21627673 = header.getOrDefault("X-Amz-Signature")
  valid_21627673 = validateParameter(valid_21627673, JString, required = false,
                                   default = nil)
  if valid_21627673 != nil:
    section.add "X-Amz-Signature", valid_21627673
  var valid_21627674 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627674 = validateParameter(valid_21627674, JString, required = false,
                                   default = nil)
  if valid_21627674 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627674
  var valid_21627675 = header.getOrDefault("X-Amz-Credential")
  valid_21627675 = validateParameter(valid_21627675, JString, required = false,
                                   default = nil)
  if valid_21627675 != nil:
    section.add "X-Amz-Credential", valid_21627675
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

proc call*(call_21627677: Call_StopAutomationExecution_21627665;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Stop an Automation that is currently running.
  ## 
  let valid = call_21627677.validator(path, query, header, formData, body, _)
  let scheme = call_21627677.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627677.makeUrl(scheme.get, call_21627677.host, call_21627677.base,
                               call_21627677.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627677, uri, valid, _)

proc call*(call_21627678: Call_StopAutomationExecution_21627665; body: JsonNode): Recallable =
  ## stopAutomationExecution
  ## Stop an Automation that is currently running.
  ##   body: JObject (required)
  var body_21627679 = newJObject()
  if body != nil:
    body_21627679 = body
  result = call_21627678.call(nil, nil, nil, nil, body_21627679)

var stopAutomationExecution* = Call_StopAutomationExecution_21627665(
    name: "stopAutomationExecution", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.StopAutomationExecution",
    validator: validate_StopAutomationExecution_21627666, base: "/",
    makeUrl: url_StopAutomationExecution_21627667,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TerminateSession_21627680 = ref object of OpenApiRestCall_21625435
proc url_TerminateSession_21627682(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_TerminateSession_21627681(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627683 = header.getOrDefault("X-Amz-Date")
  valid_21627683 = validateParameter(valid_21627683, JString, required = false,
                                   default = nil)
  if valid_21627683 != nil:
    section.add "X-Amz-Date", valid_21627683
  var valid_21627684 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627684 = validateParameter(valid_21627684, JString, required = false,
                                   default = nil)
  if valid_21627684 != nil:
    section.add "X-Amz-Security-Token", valid_21627684
  var valid_21627685 = header.getOrDefault("X-Amz-Target")
  valid_21627685 = validateParameter(valid_21627685, JString, required = true, default = newJString(
      "AmazonSSM.TerminateSession"))
  if valid_21627685 != nil:
    section.add "X-Amz-Target", valid_21627685
  var valid_21627686 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627686 = validateParameter(valid_21627686, JString, required = false,
                                   default = nil)
  if valid_21627686 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627686
  var valid_21627687 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627687 = validateParameter(valid_21627687, JString, required = false,
                                   default = nil)
  if valid_21627687 != nil:
    section.add "X-Amz-Algorithm", valid_21627687
  var valid_21627688 = header.getOrDefault("X-Amz-Signature")
  valid_21627688 = validateParameter(valid_21627688, JString, required = false,
                                   default = nil)
  if valid_21627688 != nil:
    section.add "X-Amz-Signature", valid_21627688
  var valid_21627689 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627689 = validateParameter(valid_21627689, JString, required = false,
                                   default = nil)
  if valid_21627689 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627689
  var valid_21627690 = header.getOrDefault("X-Amz-Credential")
  valid_21627690 = validateParameter(valid_21627690, JString, required = false,
                                   default = nil)
  if valid_21627690 != nil:
    section.add "X-Amz-Credential", valid_21627690
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

proc call*(call_21627692: Call_TerminateSession_21627680; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Permanently ends a session and closes the data connection between the Session Manager client and SSM Agent on the instance. A terminated session cannot be resumed.
  ## 
  let valid = call_21627692.validator(path, query, header, formData, body, _)
  let scheme = call_21627692.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627692.makeUrl(scheme.get, call_21627692.host, call_21627692.base,
                               call_21627692.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627692, uri, valid, _)

proc call*(call_21627693: Call_TerminateSession_21627680; body: JsonNode): Recallable =
  ## terminateSession
  ## Permanently ends a session and closes the data connection between the Session Manager client and SSM Agent on the instance. A terminated session cannot be resumed.
  ##   body: JObject (required)
  var body_21627694 = newJObject()
  if body != nil:
    body_21627694 = body
  result = call_21627693.call(nil, nil, nil, nil, body_21627694)

var terminateSession* = Call_TerminateSession_21627680(name: "terminateSession",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.TerminateSession",
    validator: validate_TerminateSession_21627681, base: "/",
    makeUrl: url_TerminateSession_21627682, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateAssociation_21627695 = ref object of OpenApiRestCall_21625435
proc url_UpdateAssociation_21627697(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateAssociation_21627696(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627698 = header.getOrDefault("X-Amz-Date")
  valid_21627698 = validateParameter(valid_21627698, JString, required = false,
                                   default = nil)
  if valid_21627698 != nil:
    section.add "X-Amz-Date", valid_21627698
  var valid_21627699 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627699 = validateParameter(valid_21627699, JString, required = false,
                                   default = nil)
  if valid_21627699 != nil:
    section.add "X-Amz-Security-Token", valid_21627699
  var valid_21627700 = header.getOrDefault("X-Amz-Target")
  valid_21627700 = validateParameter(valid_21627700, JString, required = true, default = newJString(
      "AmazonSSM.UpdateAssociation"))
  if valid_21627700 != nil:
    section.add "X-Amz-Target", valid_21627700
  var valid_21627701 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627701 = validateParameter(valid_21627701, JString, required = false,
                                   default = nil)
  if valid_21627701 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627701
  var valid_21627702 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627702 = validateParameter(valid_21627702, JString, required = false,
                                   default = nil)
  if valid_21627702 != nil:
    section.add "X-Amz-Algorithm", valid_21627702
  var valid_21627703 = header.getOrDefault("X-Amz-Signature")
  valid_21627703 = validateParameter(valid_21627703, JString, required = false,
                                   default = nil)
  if valid_21627703 != nil:
    section.add "X-Amz-Signature", valid_21627703
  var valid_21627704 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627704 = validateParameter(valid_21627704, JString, required = false,
                                   default = nil)
  if valid_21627704 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627704
  var valid_21627705 = header.getOrDefault("X-Amz-Credential")
  valid_21627705 = validateParameter(valid_21627705, JString, required = false,
                                   default = nil)
  if valid_21627705 != nil:
    section.add "X-Amz-Credential", valid_21627705
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

proc call*(call_21627707: Call_UpdateAssociation_21627695; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Updates an association. You can update the association name and version, the document version, schedule, parameters, and Amazon S3 output. </p> <p>In order to call this API action, your IAM user account, group, or role must be configured with permission to call the <a>DescribeAssociation</a> API action. If you don't have permission to call DescribeAssociation, then you receive the following error: <code>An error occurred (AccessDeniedException) when calling the UpdateAssociation operation: User: &lt;user_arn&gt; is not authorized to perform: ssm:DescribeAssociation on resource: &lt;resource_arn&gt;</code> </p> <important> <p>When you update an association, the association immediately runs against the specified targets.</p> </important>
  ## 
  let valid = call_21627707.validator(path, query, header, formData, body, _)
  let scheme = call_21627707.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627707.makeUrl(scheme.get, call_21627707.host, call_21627707.base,
                               call_21627707.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627707, uri, valid, _)

proc call*(call_21627708: Call_UpdateAssociation_21627695; body: JsonNode): Recallable =
  ## updateAssociation
  ## <p>Updates an association. You can update the association name and version, the document version, schedule, parameters, and Amazon S3 output. </p> <p>In order to call this API action, your IAM user account, group, or role must be configured with permission to call the <a>DescribeAssociation</a> API action. If you don't have permission to call DescribeAssociation, then you receive the following error: <code>An error occurred (AccessDeniedException) when calling the UpdateAssociation operation: User: &lt;user_arn&gt; is not authorized to perform: ssm:DescribeAssociation on resource: &lt;resource_arn&gt;</code> </p> <important> <p>When you update an association, the association immediately runs against the specified targets.</p> </important>
  ##   body: JObject (required)
  var body_21627709 = newJObject()
  if body != nil:
    body_21627709 = body
  result = call_21627708.call(nil, nil, nil, nil, body_21627709)

var updateAssociation* = Call_UpdateAssociation_21627695(name: "updateAssociation",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.UpdateAssociation",
    validator: validate_UpdateAssociation_21627696, base: "/",
    makeUrl: url_UpdateAssociation_21627697, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateAssociationStatus_21627710 = ref object of OpenApiRestCall_21625435
proc url_UpdateAssociationStatus_21627712(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateAssociationStatus_21627711(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627713 = header.getOrDefault("X-Amz-Date")
  valid_21627713 = validateParameter(valid_21627713, JString, required = false,
                                   default = nil)
  if valid_21627713 != nil:
    section.add "X-Amz-Date", valid_21627713
  var valid_21627714 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627714 = validateParameter(valid_21627714, JString, required = false,
                                   default = nil)
  if valid_21627714 != nil:
    section.add "X-Amz-Security-Token", valid_21627714
  var valid_21627715 = header.getOrDefault("X-Amz-Target")
  valid_21627715 = validateParameter(valid_21627715, JString, required = true, default = newJString(
      "AmazonSSM.UpdateAssociationStatus"))
  if valid_21627715 != nil:
    section.add "X-Amz-Target", valid_21627715
  var valid_21627716 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627716 = validateParameter(valid_21627716, JString, required = false,
                                   default = nil)
  if valid_21627716 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627716
  var valid_21627717 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627717 = validateParameter(valid_21627717, JString, required = false,
                                   default = nil)
  if valid_21627717 != nil:
    section.add "X-Amz-Algorithm", valid_21627717
  var valid_21627718 = header.getOrDefault("X-Amz-Signature")
  valid_21627718 = validateParameter(valid_21627718, JString, required = false,
                                   default = nil)
  if valid_21627718 != nil:
    section.add "X-Amz-Signature", valid_21627718
  var valid_21627719 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627719 = validateParameter(valid_21627719, JString, required = false,
                                   default = nil)
  if valid_21627719 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627719
  var valid_21627720 = header.getOrDefault("X-Amz-Credential")
  valid_21627720 = validateParameter(valid_21627720, JString, required = false,
                                   default = nil)
  if valid_21627720 != nil:
    section.add "X-Amz-Credential", valid_21627720
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

proc call*(call_21627722: Call_UpdateAssociationStatus_21627710;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates the status of the Systems Manager document associated with the specified instance.
  ## 
  let valid = call_21627722.validator(path, query, header, formData, body, _)
  let scheme = call_21627722.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627722.makeUrl(scheme.get, call_21627722.host, call_21627722.base,
                               call_21627722.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627722, uri, valid, _)

proc call*(call_21627723: Call_UpdateAssociationStatus_21627710; body: JsonNode): Recallable =
  ## updateAssociationStatus
  ## Updates the status of the Systems Manager document associated with the specified instance.
  ##   body: JObject (required)
  var body_21627724 = newJObject()
  if body != nil:
    body_21627724 = body
  result = call_21627723.call(nil, nil, nil, nil, body_21627724)

var updateAssociationStatus* = Call_UpdateAssociationStatus_21627710(
    name: "updateAssociationStatus", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.UpdateAssociationStatus",
    validator: validate_UpdateAssociationStatus_21627711, base: "/",
    makeUrl: url_UpdateAssociationStatus_21627712,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDocument_21627725 = ref object of OpenApiRestCall_21625435
proc url_UpdateDocument_21627727(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateDocument_21627726(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627728 = header.getOrDefault("X-Amz-Date")
  valid_21627728 = validateParameter(valid_21627728, JString, required = false,
                                   default = nil)
  if valid_21627728 != nil:
    section.add "X-Amz-Date", valid_21627728
  var valid_21627729 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627729 = validateParameter(valid_21627729, JString, required = false,
                                   default = nil)
  if valid_21627729 != nil:
    section.add "X-Amz-Security-Token", valid_21627729
  var valid_21627730 = header.getOrDefault("X-Amz-Target")
  valid_21627730 = validateParameter(valid_21627730, JString, required = true, default = newJString(
      "AmazonSSM.UpdateDocument"))
  if valid_21627730 != nil:
    section.add "X-Amz-Target", valid_21627730
  var valid_21627731 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627731 = validateParameter(valid_21627731, JString, required = false,
                                   default = nil)
  if valid_21627731 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627731
  var valid_21627732 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627732 = validateParameter(valid_21627732, JString, required = false,
                                   default = nil)
  if valid_21627732 != nil:
    section.add "X-Amz-Algorithm", valid_21627732
  var valid_21627733 = header.getOrDefault("X-Amz-Signature")
  valid_21627733 = validateParameter(valid_21627733, JString, required = false,
                                   default = nil)
  if valid_21627733 != nil:
    section.add "X-Amz-Signature", valid_21627733
  var valid_21627734 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627734 = validateParameter(valid_21627734, JString, required = false,
                                   default = nil)
  if valid_21627734 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627734
  var valid_21627735 = header.getOrDefault("X-Amz-Credential")
  valid_21627735 = validateParameter(valid_21627735, JString, required = false,
                                   default = nil)
  if valid_21627735 != nil:
    section.add "X-Amz-Credential", valid_21627735
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

proc call*(call_21627737: Call_UpdateDocument_21627725; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates one or more values for an SSM document.
  ## 
  let valid = call_21627737.validator(path, query, header, formData, body, _)
  let scheme = call_21627737.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627737.makeUrl(scheme.get, call_21627737.host, call_21627737.base,
                               call_21627737.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627737, uri, valid, _)

proc call*(call_21627738: Call_UpdateDocument_21627725; body: JsonNode): Recallable =
  ## updateDocument
  ## Updates one or more values for an SSM document.
  ##   body: JObject (required)
  var body_21627739 = newJObject()
  if body != nil:
    body_21627739 = body
  result = call_21627738.call(nil, nil, nil, nil, body_21627739)

var updateDocument* = Call_UpdateDocument_21627725(name: "updateDocument",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.UpdateDocument",
    validator: validate_UpdateDocument_21627726, base: "/",
    makeUrl: url_UpdateDocument_21627727, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDocumentDefaultVersion_21627740 = ref object of OpenApiRestCall_21625435
proc url_UpdateDocumentDefaultVersion_21627742(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateDocumentDefaultVersion_21627741(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21627743 = header.getOrDefault("X-Amz-Date")
  valid_21627743 = validateParameter(valid_21627743, JString, required = false,
                                   default = nil)
  if valid_21627743 != nil:
    section.add "X-Amz-Date", valid_21627743
  var valid_21627744 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627744 = validateParameter(valid_21627744, JString, required = false,
                                   default = nil)
  if valid_21627744 != nil:
    section.add "X-Amz-Security-Token", valid_21627744
  var valid_21627745 = header.getOrDefault("X-Amz-Target")
  valid_21627745 = validateParameter(valid_21627745, JString, required = true, default = newJString(
      "AmazonSSM.UpdateDocumentDefaultVersion"))
  if valid_21627745 != nil:
    section.add "X-Amz-Target", valid_21627745
  var valid_21627746 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627746 = validateParameter(valid_21627746, JString, required = false,
                                   default = nil)
  if valid_21627746 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627746
  var valid_21627747 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627747 = validateParameter(valid_21627747, JString, required = false,
                                   default = nil)
  if valid_21627747 != nil:
    section.add "X-Amz-Algorithm", valid_21627747
  var valid_21627748 = header.getOrDefault("X-Amz-Signature")
  valid_21627748 = validateParameter(valid_21627748, JString, required = false,
                                   default = nil)
  if valid_21627748 != nil:
    section.add "X-Amz-Signature", valid_21627748
  var valid_21627749 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627749 = validateParameter(valid_21627749, JString, required = false,
                                   default = nil)
  if valid_21627749 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627749
  var valid_21627750 = header.getOrDefault("X-Amz-Credential")
  valid_21627750 = validateParameter(valid_21627750, JString, required = false,
                                   default = nil)
  if valid_21627750 != nil:
    section.add "X-Amz-Credential", valid_21627750
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

proc call*(call_21627752: Call_UpdateDocumentDefaultVersion_21627740;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Set the default version of a document. 
  ## 
  let valid = call_21627752.validator(path, query, header, formData, body, _)
  let scheme = call_21627752.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627752.makeUrl(scheme.get, call_21627752.host, call_21627752.base,
                               call_21627752.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627752, uri, valid, _)

proc call*(call_21627753: Call_UpdateDocumentDefaultVersion_21627740;
          body: JsonNode): Recallable =
  ## updateDocumentDefaultVersion
  ## Set the default version of a document. 
  ##   body: JObject (required)
  var body_21627754 = newJObject()
  if body != nil:
    body_21627754 = body
  result = call_21627753.call(nil, nil, nil, nil, body_21627754)

var updateDocumentDefaultVersion* = Call_UpdateDocumentDefaultVersion_21627740(
    name: "updateDocumentDefaultVersion", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.UpdateDocumentDefaultVersion",
    validator: validate_UpdateDocumentDefaultVersion_21627741, base: "/",
    makeUrl: url_UpdateDocumentDefaultVersion_21627742,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateMaintenanceWindow_21627755 = ref object of OpenApiRestCall_21625435
proc url_UpdateMaintenanceWindow_21627757(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateMaintenanceWindow_21627756(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627758 = header.getOrDefault("X-Amz-Date")
  valid_21627758 = validateParameter(valid_21627758, JString, required = false,
                                   default = nil)
  if valid_21627758 != nil:
    section.add "X-Amz-Date", valid_21627758
  var valid_21627759 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627759 = validateParameter(valid_21627759, JString, required = false,
                                   default = nil)
  if valid_21627759 != nil:
    section.add "X-Amz-Security-Token", valid_21627759
  var valid_21627760 = header.getOrDefault("X-Amz-Target")
  valid_21627760 = validateParameter(valid_21627760, JString, required = true, default = newJString(
      "AmazonSSM.UpdateMaintenanceWindow"))
  if valid_21627760 != nil:
    section.add "X-Amz-Target", valid_21627760
  var valid_21627761 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627761 = validateParameter(valid_21627761, JString, required = false,
                                   default = nil)
  if valid_21627761 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627761
  var valid_21627762 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627762 = validateParameter(valid_21627762, JString, required = false,
                                   default = nil)
  if valid_21627762 != nil:
    section.add "X-Amz-Algorithm", valid_21627762
  var valid_21627763 = header.getOrDefault("X-Amz-Signature")
  valid_21627763 = validateParameter(valid_21627763, JString, required = false,
                                   default = nil)
  if valid_21627763 != nil:
    section.add "X-Amz-Signature", valid_21627763
  var valid_21627764 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627764 = validateParameter(valid_21627764, JString, required = false,
                                   default = nil)
  if valid_21627764 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627764
  var valid_21627765 = header.getOrDefault("X-Amz-Credential")
  valid_21627765 = validateParameter(valid_21627765, JString, required = false,
                                   default = nil)
  if valid_21627765 != nil:
    section.add "X-Amz-Credential", valid_21627765
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

proc call*(call_21627767: Call_UpdateMaintenanceWindow_21627755;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Updates an existing maintenance window. Only specified parameters are modified.</p> <note> <p>The value you specify for <code>Duration</code> determines the specific end time for the maintenance window based on the time it begins. No maintenance window tasks are permitted to start after the resulting endtime minus the number of hours you specify for <code>Cutoff</code>. For example, if the maintenance window starts at 3 PM, the duration is three hours, and the value you specify for <code>Cutoff</code> is one hour, no maintenance window tasks can start after 5 PM.</p> </note>
  ## 
  let valid = call_21627767.validator(path, query, header, formData, body, _)
  let scheme = call_21627767.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627767.makeUrl(scheme.get, call_21627767.host, call_21627767.base,
                               call_21627767.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627767, uri, valid, _)

proc call*(call_21627768: Call_UpdateMaintenanceWindow_21627755; body: JsonNode): Recallable =
  ## updateMaintenanceWindow
  ## <p>Updates an existing maintenance window. Only specified parameters are modified.</p> <note> <p>The value you specify for <code>Duration</code> determines the specific end time for the maintenance window based on the time it begins. No maintenance window tasks are permitted to start after the resulting endtime minus the number of hours you specify for <code>Cutoff</code>. For example, if the maintenance window starts at 3 PM, the duration is three hours, and the value you specify for <code>Cutoff</code> is one hour, no maintenance window tasks can start after 5 PM.</p> </note>
  ##   body: JObject (required)
  var body_21627769 = newJObject()
  if body != nil:
    body_21627769 = body
  result = call_21627768.call(nil, nil, nil, nil, body_21627769)

var updateMaintenanceWindow* = Call_UpdateMaintenanceWindow_21627755(
    name: "updateMaintenanceWindow", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.UpdateMaintenanceWindow",
    validator: validate_UpdateMaintenanceWindow_21627756, base: "/",
    makeUrl: url_UpdateMaintenanceWindow_21627757,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateMaintenanceWindowTarget_21627770 = ref object of OpenApiRestCall_21625435
proc url_UpdateMaintenanceWindowTarget_21627772(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateMaintenanceWindowTarget_21627771(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21627773 = header.getOrDefault("X-Amz-Date")
  valid_21627773 = validateParameter(valid_21627773, JString, required = false,
                                   default = nil)
  if valid_21627773 != nil:
    section.add "X-Amz-Date", valid_21627773
  var valid_21627774 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627774 = validateParameter(valid_21627774, JString, required = false,
                                   default = nil)
  if valid_21627774 != nil:
    section.add "X-Amz-Security-Token", valid_21627774
  var valid_21627775 = header.getOrDefault("X-Amz-Target")
  valid_21627775 = validateParameter(valid_21627775, JString, required = true, default = newJString(
      "AmazonSSM.UpdateMaintenanceWindowTarget"))
  if valid_21627775 != nil:
    section.add "X-Amz-Target", valid_21627775
  var valid_21627776 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627776 = validateParameter(valid_21627776, JString, required = false,
                                   default = nil)
  if valid_21627776 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627776
  var valid_21627777 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627777 = validateParameter(valid_21627777, JString, required = false,
                                   default = nil)
  if valid_21627777 != nil:
    section.add "X-Amz-Algorithm", valid_21627777
  var valid_21627778 = header.getOrDefault("X-Amz-Signature")
  valid_21627778 = validateParameter(valid_21627778, JString, required = false,
                                   default = nil)
  if valid_21627778 != nil:
    section.add "X-Amz-Signature", valid_21627778
  var valid_21627779 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627779 = validateParameter(valid_21627779, JString, required = false,
                                   default = nil)
  if valid_21627779 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627779
  var valid_21627780 = header.getOrDefault("X-Amz-Credential")
  valid_21627780 = validateParameter(valid_21627780, JString, required = false,
                                   default = nil)
  if valid_21627780 != nil:
    section.add "X-Amz-Credential", valid_21627780
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

proc call*(call_21627782: Call_UpdateMaintenanceWindowTarget_21627770;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Modifies the target of an existing maintenance window. You can change the following:</p> <ul> <li> <p>Name</p> </li> <li> <p>Description</p> </li> <li> <p>Owner</p> </li> <li> <p>IDs for an ID target</p> </li> <li> <p>Tags for a Tag target</p> </li> <li> <p>From any supported tag type to another. The three supported tag types are ID target, Tag target, and resource group. For more information, see <a>Target</a>.</p> </li> </ul> <note> <p>If a parameter is null, then the corresponding field is not modified.</p> </note>
  ## 
  let valid = call_21627782.validator(path, query, header, formData, body, _)
  let scheme = call_21627782.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627782.makeUrl(scheme.get, call_21627782.host, call_21627782.base,
                               call_21627782.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627782, uri, valid, _)

proc call*(call_21627783: Call_UpdateMaintenanceWindowTarget_21627770;
          body: JsonNode): Recallable =
  ## updateMaintenanceWindowTarget
  ## <p>Modifies the target of an existing maintenance window. You can change the following:</p> <ul> <li> <p>Name</p> </li> <li> <p>Description</p> </li> <li> <p>Owner</p> </li> <li> <p>IDs for an ID target</p> </li> <li> <p>Tags for a Tag target</p> </li> <li> <p>From any supported tag type to another. The three supported tag types are ID target, Tag target, and resource group. For more information, see <a>Target</a>.</p> </li> </ul> <note> <p>If a parameter is null, then the corresponding field is not modified.</p> </note>
  ##   body: JObject (required)
  var body_21627784 = newJObject()
  if body != nil:
    body_21627784 = body
  result = call_21627783.call(nil, nil, nil, nil, body_21627784)

var updateMaintenanceWindowTarget* = Call_UpdateMaintenanceWindowTarget_21627770(
    name: "updateMaintenanceWindowTarget", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.UpdateMaintenanceWindowTarget",
    validator: validate_UpdateMaintenanceWindowTarget_21627771, base: "/",
    makeUrl: url_UpdateMaintenanceWindowTarget_21627772,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateMaintenanceWindowTask_21627785 = ref object of OpenApiRestCall_21625435
proc url_UpdateMaintenanceWindowTask_21627787(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateMaintenanceWindowTask_21627786(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627788 = header.getOrDefault("X-Amz-Date")
  valid_21627788 = validateParameter(valid_21627788, JString, required = false,
                                   default = nil)
  if valid_21627788 != nil:
    section.add "X-Amz-Date", valid_21627788
  var valid_21627789 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627789 = validateParameter(valid_21627789, JString, required = false,
                                   default = nil)
  if valid_21627789 != nil:
    section.add "X-Amz-Security-Token", valid_21627789
  var valid_21627790 = header.getOrDefault("X-Amz-Target")
  valid_21627790 = validateParameter(valid_21627790, JString, required = true, default = newJString(
      "AmazonSSM.UpdateMaintenanceWindowTask"))
  if valid_21627790 != nil:
    section.add "X-Amz-Target", valid_21627790
  var valid_21627791 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627791 = validateParameter(valid_21627791, JString, required = false,
                                   default = nil)
  if valid_21627791 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627791
  var valid_21627792 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627792 = validateParameter(valid_21627792, JString, required = false,
                                   default = nil)
  if valid_21627792 != nil:
    section.add "X-Amz-Algorithm", valid_21627792
  var valid_21627793 = header.getOrDefault("X-Amz-Signature")
  valid_21627793 = validateParameter(valid_21627793, JString, required = false,
                                   default = nil)
  if valid_21627793 != nil:
    section.add "X-Amz-Signature", valid_21627793
  var valid_21627794 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627794 = validateParameter(valid_21627794, JString, required = false,
                                   default = nil)
  if valid_21627794 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627794
  var valid_21627795 = header.getOrDefault("X-Amz-Credential")
  valid_21627795 = validateParameter(valid_21627795, JString, required = false,
                                   default = nil)
  if valid_21627795 != nil:
    section.add "X-Amz-Credential", valid_21627795
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

proc call*(call_21627797: Call_UpdateMaintenanceWindowTask_21627785;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Modifies a task assigned to a maintenance window. You can't change the task type, but you can change the following values:</p> <ul> <li> <p>TaskARN. For example, you can change a RUN_COMMAND task from AWS-RunPowerShellScript to AWS-RunShellScript.</p> </li> <li> <p>ServiceRoleArn</p> </li> <li> <p>TaskInvocationParameters</p> </li> <li> <p>Priority</p> </li> <li> <p>MaxConcurrency</p> </li> <li> <p>MaxErrors</p> </li> </ul> <p>If a parameter is null, then the corresponding field is not modified. Also, if you set Replace to true, then all fields required by the <a>RegisterTaskWithMaintenanceWindow</a> action are required for this request. Optional fields that aren't specified are set to null.</p>
  ## 
  let valid = call_21627797.validator(path, query, header, formData, body, _)
  let scheme = call_21627797.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627797.makeUrl(scheme.get, call_21627797.host, call_21627797.base,
                               call_21627797.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627797, uri, valid, _)

proc call*(call_21627798: Call_UpdateMaintenanceWindowTask_21627785; body: JsonNode): Recallable =
  ## updateMaintenanceWindowTask
  ## <p>Modifies a task assigned to a maintenance window. You can't change the task type, but you can change the following values:</p> <ul> <li> <p>TaskARN. For example, you can change a RUN_COMMAND task from AWS-RunPowerShellScript to AWS-RunShellScript.</p> </li> <li> <p>ServiceRoleArn</p> </li> <li> <p>TaskInvocationParameters</p> </li> <li> <p>Priority</p> </li> <li> <p>MaxConcurrency</p> </li> <li> <p>MaxErrors</p> </li> </ul> <p>If a parameter is null, then the corresponding field is not modified. Also, if you set Replace to true, then all fields required by the <a>RegisterTaskWithMaintenanceWindow</a> action are required for this request. Optional fields that aren't specified are set to null.</p>
  ##   body: JObject (required)
  var body_21627799 = newJObject()
  if body != nil:
    body_21627799 = body
  result = call_21627798.call(nil, nil, nil, nil, body_21627799)

var updateMaintenanceWindowTask* = Call_UpdateMaintenanceWindowTask_21627785(
    name: "updateMaintenanceWindowTask", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.UpdateMaintenanceWindowTask",
    validator: validate_UpdateMaintenanceWindowTask_21627786, base: "/",
    makeUrl: url_UpdateMaintenanceWindowTask_21627787,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateManagedInstanceRole_21627800 = ref object of OpenApiRestCall_21625435
proc url_UpdateManagedInstanceRole_21627802(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateManagedInstanceRole_21627801(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627803 = header.getOrDefault("X-Amz-Date")
  valid_21627803 = validateParameter(valid_21627803, JString, required = false,
                                   default = nil)
  if valid_21627803 != nil:
    section.add "X-Amz-Date", valid_21627803
  var valid_21627804 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627804 = validateParameter(valid_21627804, JString, required = false,
                                   default = nil)
  if valid_21627804 != nil:
    section.add "X-Amz-Security-Token", valid_21627804
  var valid_21627805 = header.getOrDefault("X-Amz-Target")
  valid_21627805 = validateParameter(valid_21627805, JString, required = true, default = newJString(
      "AmazonSSM.UpdateManagedInstanceRole"))
  if valid_21627805 != nil:
    section.add "X-Amz-Target", valid_21627805
  var valid_21627806 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627806 = validateParameter(valid_21627806, JString, required = false,
                                   default = nil)
  if valid_21627806 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627806
  var valid_21627807 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627807 = validateParameter(valid_21627807, JString, required = false,
                                   default = nil)
  if valid_21627807 != nil:
    section.add "X-Amz-Algorithm", valid_21627807
  var valid_21627808 = header.getOrDefault("X-Amz-Signature")
  valid_21627808 = validateParameter(valid_21627808, JString, required = false,
                                   default = nil)
  if valid_21627808 != nil:
    section.add "X-Amz-Signature", valid_21627808
  var valid_21627809 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627809 = validateParameter(valid_21627809, JString, required = false,
                                   default = nil)
  if valid_21627809 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627809
  var valid_21627810 = header.getOrDefault("X-Amz-Credential")
  valid_21627810 = validateParameter(valid_21627810, JString, required = false,
                                   default = nil)
  if valid_21627810 != nil:
    section.add "X-Amz-Credential", valid_21627810
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

proc call*(call_21627812: Call_UpdateManagedInstanceRole_21627800;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Assigns or changes an Amazon Identity and Access Management (IAM) role for the managed instance.
  ## 
  let valid = call_21627812.validator(path, query, header, formData, body, _)
  let scheme = call_21627812.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627812.makeUrl(scheme.get, call_21627812.host, call_21627812.base,
                               call_21627812.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627812, uri, valid, _)

proc call*(call_21627813: Call_UpdateManagedInstanceRole_21627800; body: JsonNode): Recallable =
  ## updateManagedInstanceRole
  ## Assigns or changes an Amazon Identity and Access Management (IAM) role for the managed instance.
  ##   body: JObject (required)
  var body_21627814 = newJObject()
  if body != nil:
    body_21627814 = body
  result = call_21627813.call(nil, nil, nil, nil, body_21627814)

var updateManagedInstanceRole* = Call_UpdateManagedInstanceRole_21627800(
    name: "updateManagedInstanceRole", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.UpdateManagedInstanceRole",
    validator: validate_UpdateManagedInstanceRole_21627801, base: "/",
    makeUrl: url_UpdateManagedInstanceRole_21627802,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateOpsItem_21627815 = ref object of OpenApiRestCall_21625435
proc url_UpdateOpsItem_21627817(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateOpsItem_21627816(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21627818 = header.getOrDefault("X-Amz-Date")
  valid_21627818 = validateParameter(valid_21627818, JString, required = false,
                                   default = nil)
  if valid_21627818 != nil:
    section.add "X-Amz-Date", valid_21627818
  var valid_21627819 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627819 = validateParameter(valid_21627819, JString, required = false,
                                   default = nil)
  if valid_21627819 != nil:
    section.add "X-Amz-Security-Token", valid_21627819
  var valid_21627820 = header.getOrDefault("X-Amz-Target")
  valid_21627820 = validateParameter(valid_21627820, JString, required = true, default = newJString(
      "AmazonSSM.UpdateOpsItem"))
  if valid_21627820 != nil:
    section.add "X-Amz-Target", valid_21627820
  var valid_21627821 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627821 = validateParameter(valid_21627821, JString, required = false,
                                   default = nil)
  if valid_21627821 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627821
  var valid_21627822 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627822 = validateParameter(valid_21627822, JString, required = false,
                                   default = nil)
  if valid_21627822 != nil:
    section.add "X-Amz-Algorithm", valid_21627822
  var valid_21627823 = header.getOrDefault("X-Amz-Signature")
  valid_21627823 = validateParameter(valid_21627823, JString, required = false,
                                   default = nil)
  if valid_21627823 != nil:
    section.add "X-Amz-Signature", valid_21627823
  var valid_21627824 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627824 = validateParameter(valid_21627824, JString, required = false,
                                   default = nil)
  if valid_21627824 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627824
  var valid_21627825 = header.getOrDefault("X-Amz-Credential")
  valid_21627825 = validateParameter(valid_21627825, JString, required = false,
                                   default = nil)
  if valid_21627825 != nil:
    section.add "X-Amz-Credential", valid_21627825
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

proc call*(call_21627827: Call_UpdateOpsItem_21627815; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Edit or change an OpsItem. You must have permission in AWS Identity and Access Management (IAM) to update an OpsItem. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter-getting-started.html">Getting Started with OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>.</p> <p>Operations engineers and IT professionals use OpsCenter to view, investigate, and remediate operational issues impacting the performance and health of their AWS resources. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter.html">AWS Systems Manager OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>. </p>
  ## 
  let valid = call_21627827.validator(path, query, header, formData, body, _)
  let scheme = call_21627827.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627827.makeUrl(scheme.get, call_21627827.host, call_21627827.base,
                               call_21627827.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627827, uri, valid, _)

proc call*(call_21627828: Call_UpdateOpsItem_21627815; body: JsonNode): Recallable =
  ## updateOpsItem
  ## <p>Edit or change an OpsItem. You must have permission in AWS Identity and Access Management (IAM) to update an OpsItem. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter-getting-started.html">Getting Started with OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>.</p> <p>Operations engineers and IT professionals use OpsCenter to view, investigate, and remediate operational issues impacting the performance and health of their AWS resources. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter.html">AWS Systems Manager OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>. </p>
  ##   body: JObject (required)
  var body_21627829 = newJObject()
  if body != nil:
    body_21627829 = body
  result = call_21627828.call(nil, nil, nil, nil, body_21627829)

var updateOpsItem* = Call_UpdateOpsItem_21627815(name: "updateOpsItem",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.UpdateOpsItem",
    validator: validate_UpdateOpsItem_21627816, base: "/",
    makeUrl: url_UpdateOpsItem_21627817, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdatePatchBaseline_21627830 = ref object of OpenApiRestCall_21625435
proc url_UpdatePatchBaseline_21627832(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdatePatchBaseline_21627831(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627833 = header.getOrDefault("X-Amz-Date")
  valid_21627833 = validateParameter(valid_21627833, JString, required = false,
                                   default = nil)
  if valid_21627833 != nil:
    section.add "X-Amz-Date", valid_21627833
  var valid_21627834 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627834 = validateParameter(valid_21627834, JString, required = false,
                                   default = nil)
  if valid_21627834 != nil:
    section.add "X-Amz-Security-Token", valid_21627834
  var valid_21627835 = header.getOrDefault("X-Amz-Target")
  valid_21627835 = validateParameter(valid_21627835, JString, required = true, default = newJString(
      "AmazonSSM.UpdatePatchBaseline"))
  if valid_21627835 != nil:
    section.add "X-Amz-Target", valid_21627835
  var valid_21627836 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627836 = validateParameter(valid_21627836, JString, required = false,
                                   default = nil)
  if valid_21627836 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627836
  var valid_21627837 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627837 = validateParameter(valid_21627837, JString, required = false,
                                   default = nil)
  if valid_21627837 != nil:
    section.add "X-Amz-Algorithm", valid_21627837
  var valid_21627838 = header.getOrDefault("X-Amz-Signature")
  valid_21627838 = validateParameter(valid_21627838, JString, required = false,
                                   default = nil)
  if valid_21627838 != nil:
    section.add "X-Amz-Signature", valid_21627838
  var valid_21627839 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627839 = validateParameter(valid_21627839, JString, required = false,
                                   default = nil)
  if valid_21627839 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627839
  var valid_21627840 = header.getOrDefault("X-Amz-Credential")
  valid_21627840 = validateParameter(valid_21627840, JString, required = false,
                                   default = nil)
  if valid_21627840 != nil:
    section.add "X-Amz-Credential", valid_21627840
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

proc call*(call_21627842: Call_UpdatePatchBaseline_21627830; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Modifies an existing patch baseline. Fields not specified in the request are left unchanged.</p> <note> <p>For information about valid key and value pairs in <code>PatchFilters</code> for each supported operating system type, see <a href="http://docs.aws.amazon.com/systems-manager/latest/APIReference/API_PatchFilter.html">PatchFilter</a>.</p> </note>
  ## 
  let valid = call_21627842.validator(path, query, header, formData, body, _)
  let scheme = call_21627842.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627842.makeUrl(scheme.get, call_21627842.host, call_21627842.base,
                               call_21627842.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627842, uri, valid, _)

proc call*(call_21627843: Call_UpdatePatchBaseline_21627830; body: JsonNode): Recallable =
  ## updatePatchBaseline
  ## <p>Modifies an existing patch baseline. Fields not specified in the request are left unchanged.</p> <note> <p>For information about valid key and value pairs in <code>PatchFilters</code> for each supported operating system type, see <a href="http://docs.aws.amazon.com/systems-manager/latest/APIReference/API_PatchFilter.html">PatchFilter</a>.</p> </note>
  ##   body: JObject (required)
  var body_21627844 = newJObject()
  if body != nil:
    body_21627844 = body
  result = call_21627843.call(nil, nil, nil, nil, body_21627844)

var updatePatchBaseline* = Call_UpdatePatchBaseline_21627830(
    name: "updatePatchBaseline", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.UpdatePatchBaseline",
    validator: validate_UpdatePatchBaseline_21627831, base: "/",
    makeUrl: url_UpdatePatchBaseline_21627832,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateResourceDataSync_21627845 = ref object of OpenApiRestCall_21625435
proc url_UpdateResourceDataSync_21627847(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateResourceDataSync_21627846(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Update a resource data sync. After you create a resource data sync for a Region, you can't change the account options for that sync. For example, if you create a sync in the us-east-2 (Ohio) Region and you choose the Include only the current account option, you can't edit that sync later and choose the Include all accounts from my AWS Organizations configuration option. Instead, you must delete the first resource data sync, and create a new one.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627848 = header.getOrDefault("X-Amz-Date")
  valid_21627848 = validateParameter(valid_21627848, JString, required = false,
                                   default = nil)
  if valid_21627848 != nil:
    section.add "X-Amz-Date", valid_21627848
  var valid_21627849 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627849 = validateParameter(valid_21627849, JString, required = false,
                                   default = nil)
  if valid_21627849 != nil:
    section.add "X-Amz-Security-Token", valid_21627849
  var valid_21627850 = header.getOrDefault("X-Amz-Target")
  valid_21627850 = validateParameter(valid_21627850, JString, required = true, default = newJString(
      "AmazonSSM.UpdateResourceDataSync"))
  if valid_21627850 != nil:
    section.add "X-Amz-Target", valid_21627850
  var valid_21627851 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627851 = validateParameter(valid_21627851, JString, required = false,
                                   default = nil)
  if valid_21627851 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627851
  var valid_21627852 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627852 = validateParameter(valid_21627852, JString, required = false,
                                   default = nil)
  if valid_21627852 != nil:
    section.add "X-Amz-Algorithm", valid_21627852
  var valid_21627853 = header.getOrDefault("X-Amz-Signature")
  valid_21627853 = validateParameter(valid_21627853, JString, required = false,
                                   default = nil)
  if valid_21627853 != nil:
    section.add "X-Amz-Signature", valid_21627853
  var valid_21627854 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627854 = validateParameter(valid_21627854, JString, required = false,
                                   default = nil)
  if valid_21627854 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627854
  var valid_21627855 = header.getOrDefault("X-Amz-Credential")
  valid_21627855 = validateParameter(valid_21627855, JString, required = false,
                                   default = nil)
  if valid_21627855 != nil:
    section.add "X-Amz-Credential", valid_21627855
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

proc call*(call_21627857: Call_UpdateResourceDataSync_21627845;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Update a resource data sync. After you create a resource data sync for a Region, you can't change the account options for that sync. For example, if you create a sync in the us-east-2 (Ohio) Region and you choose the Include only the current account option, you can't edit that sync later and choose the Include all accounts from my AWS Organizations configuration option. Instead, you must delete the first resource data sync, and create a new one.
  ## 
  let valid = call_21627857.validator(path, query, header, formData, body, _)
  let scheme = call_21627857.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627857.makeUrl(scheme.get, call_21627857.host, call_21627857.base,
                               call_21627857.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627857, uri, valid, _)

proc call*(call_21627858: Call_UpdateResourceDataSync_21627845; body: JsonNode): Recallable =
  ## updateResourceDataSync
  ## Update a resource data sync. After you create a resource data sync for a Region, you can't change the account options for that sync. For example, if you create a sync in the us-east-2 (Ohio) Region and you choose the Include only the current account option, you can't edit that sync later and choose the Include all accounts from my AWS Organizations configuration option. Instead, you must delete the first resource data sync, and create a new one.
  ##   body: JObject (required)
  var body_21627859 = newJObject()
  if body != nil:
    body_21627859 = body
  result = call_21627858.call(nil, nil, nil, nil, body_21627859)

var updateResourceDataSync* = Call_UpdateResourceDataSync_21627845(
    name: "updateResourceDataSync", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.UpdateResourceDataSync",
    validator: validate_UpdateResourceDataSync_21627846, base: "/",
    makeUrl: url_UpdateResourceDataSync_21627847,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateServiceSetting_21627860 = ref object of OpenApiRestCall_21625435
proc url_UpdateServiceSetting_21627862(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateServiceSetting_21627861(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627863 = header.getOrDefault("X-Amz-Date")
  valid_21627863 = validateParameter(valid_21627863, JString, required = false,
                                   default = nil)
  if valid_21627863 != nil:
    section.add "X-Amz-Date", valid_21627863
  var valid_21627864 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627864 = validateParameter(valid_21627864, JString, required = false,
                                   default = nil)
  if valid_21627864 != nil:
    section.add "X-Amz-Security-Token", valid_21627864
  var valid_21627865 = header.getOrDefault("X-Amz-Target")
  valid_21627865 = validateParameter(valid_21627865, JString, required = true, default = newJString(
      "AmazonSSM.UpdateServiceSetting"))
  if valid_21627865 != nil:
    section.add "X-Amz-Target", valid_21627865
  var valid_21627866 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627866 = validateParameter(valid_21627866, JString, required = false,
                                   default = nil)
  if valid_21627866 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627866
  var valid_21627867 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627867 = validateParameter(valid_21627867, JString, required = false,
                                   default = nil)
  if valid_21627867 != nil:
    section.add "X-Amz-Algorithm", valid_21627867
  var valid_21627868 = header.getOrDefault("X-Amz-Signature")
  valid_21627868 = validateParameter(valid_21627868, JString, required = false,
                                   default = nil)
  if valid_21627868 != nil:
    section.add "X-Amz-Signature", valid_21627868
  var valid_21627869 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627869 = validateParameter(valid_21627869, JString, required = false,
                                   default = nil)
  if valid_21627869 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627869
  var valid_21627870 = header.getOrDefault("X-Amz-Credential")
  valid_21627870 = validateParameter(valid_21627870, JString, required = false,
                                   default = nil)
  if valid_21627870 != nil:
    section.add "X-Amz-Credential", valid_21627870
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

proc call*(call_21627872: Call_UpdateServiceSetting_21627860; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p> <code>ServiceSetting</code> is an account-level setting for an AWS service. This setting defines how a user interacts with or uses a service or a feature of a service. For example, if an AWS service charges money to the account based on feature or service usage, then the AWS service team might create a default setting of "false". This means the user can't use this feature unless they change the setting to "true" and intentionally opt in for a paid feature.</p> <p>Services map a <code>SettingId</code> object to a setting value. AWS services teams define the default value for a <code>SettingId</code>. You can't create a new <code>SettingId</code>, but you can overwrite the default value if you have the <code>ssm:UpdateServiceSetting</code> permission for the setting. Use the <a>GetServiceSetting</a> API action to view the current value. Or, use the <a>ResetServiceSetting</a> to change the value back to the original value defined by the AWS service team.</p> <p>Update the service setting for the account. </p>
  ## 
  let valid = call_21627872.validator(path, query, header, formData, body, _)
  let scheme = call_21627872.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627872.makeUrl(scheme.get, call_21627872.host, call_21627872.base,
                               call_21627872.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627872, uri, valid, _)

proc call*(call_21627873: Call_UpdateServiceSetting_21627860; body: JsonNode): Recallable =
  ## updateServiceSetting
  ## <p> <code>ServiceSetting</code> is an account-level setting for an AWS service. This setting defines how a user interacts with or uses a service or a feature of a service. For example, if an AWS service charges money to the account based on feature or service usage, then the AWS service team might create a default setting of "false". This means the user can't use this feature unless they change the setting to "true" and intentionally opt in for a paid feature.</p> <p>Services map a <code>SettingId</code> object to a setting value. AWS services teams define the default value for a <code>SettingId</code>. You can't create a new <code>SettingId</code>, but you can overwrite the default value if you have the <code>ssm:UpdateServiceSetting</code> permission for the setting. Use the <a>GetServiceSetting</a> API action to view the current value. Or, use the <a>ResetServiceSetting</a> to change the value back to the original value defined by the AWS service team.</p> <p>Update the service setting for the account. </p>
  ##   body: JObject (required)
  var body_21627874 = newJObject()
  if body != nil:
    body_21627874 = body
  result = call_21627873.call(nil, nil, nil, nil, body_21627874)

var updateServiceSetting* = Call_UpdateServiceSetting_21627860(
    name: "updateServiceSetting", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.UpdateServiceSetting",
    validator: validate_UpdateServiceSetting_21627861, base: "/",
    makeUrl: url_UpdateServiceSetting_21627862,
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