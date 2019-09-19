
import
  json, options, hashes, tables, openapi/rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: AWS Cloud9
## version: 2017-09-23
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <fullname>AWS Cloud9</fullname> <p>AWS Cloud9 is a collection of tools that you can use to code, build, run, test, debug, and release software in the cloud.</p> <p>For more information about AWS Cloud9, see the <a href="https://docs.aws.amazon.com/cloud9/latest/user-guide">AWS Cloud9 User Guide</a>.</p> <p>AWS Cloud9 supports these operations:</p> <ul> <li> <p> <code>CreateEnvironmentEC2</code>: Creates an AWS Cloud9 development environment, launches an Amazon EC2 instance, and then connects from the instance to the environment.</p> </li> <li> <p> <code>CreateEnvironmentMembership</code>: Adds an environment member to an environment.</p> </li> <li> <p> <code>DeleteEnvironment</code>: Deletes an environment. If an Amazon EC2 instance is connected to the environment, also terminates the instance.</p> </li> <li> <p> <code>DeleteEnvironmentMembership</code>: Deletes an environment member from an environment.</p> </li> <li> <p> <code>DescribeEnvironmentMemberships</code>: Gets information about environment members for an environment.</p> </li> <li> <p> <code>DescribeEnvironments</code>: Gets information about environments.</p> </li> <li> <p> <code>DescribeEnvironmentStatus</code>: Gets status information for an environment.</p> </li> <li> <p> <code>ListEnvironments</code>: Gets a list of environment identifiers.</p> </li> <li> <p> <code>UpdateEnvironment</code>: Changes the settings of an existing environment.</p> </li> <li> <p> <code>UpdateEnvironmentMembership</code>: Changes the settings of an existing environment member for an environment.</p> </li> </ul>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/cloud9/
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
              path: JsonNode): string

  OpenApiRestCall_600426 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_600426](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_600426): Option[Scheme] {.used.} =
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
proc hydratePath(input: JsonNode; segments: seq[PathToken]): Option[string] =
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
  result = some(head & remainder.get())

const
  awsServers = {Scheme.Http: {"ap-northeast-1": "cloud9.ap-northeast-1.amazonaws.com", "ap-southeast-1": "cloud9.ap-southeast-1.amazonaws.com",
                           "us-west-2": "cloud9.us-west-2.amazonaws.com",
                           "eu-west-2": "cloud9.eu-west-2.amazonaws.com", "ap-northeast-3": "cloud9.ap-northeast-3.amazonaws.com",
                           "eu-central-1": "cloud9.eu-central-1.amazonaws.com",
                           "us-east-2": "cloud9.us-east-2.amazonaws.com",
                           "us-east-1": "cloud9.us-east-1.amazonaws.com", "cn-northwest-1": "cloud9.cn-northwest-1.amazonaws.com.cn",
                           "ap-south-1": "cloud9.ap-south-1.amazonaws.com",
                           "eu-north-1": "cloud9.eu-north-1.amazonaws.com", "ap-northeast-2": "cloud9.ap-northeast-2.amazonaws.com",
                           "us-west-1": "cloud9.us-west-1.amazonaws.com", "us-gov-east-1": "cloud9.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "cloud9.eu-west-3.amazonaws.com",
                           "cn-north-1": "cloud9.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "cloud9.sa-east-1.amazonaws.com",
                           "eu-west-1": "cloud9.eu-west-1.amazonaws.com", "us-gov-west-1": "cloud9.us-gov-west-1.amazonaws.com", "ap-southeast-2": "cloud9.ap-southeast-2.amazonaws.com",
                           "ca-central-1": "cloud9.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "cloud9.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "cloud9.ap-southeast-1.amazonaws.com",
      "us-west-2": "cloud9.us-west-2.amazonaws.com",
      "eu-west-2": "cloud9.eu-west-2.amazonaws.com",
      "ap-northeast-3": "cloud9.ap-northeast-3.amazonaws.com",
      "eu-central-1": "cloud9.eu-central-1.amazonaws.com",
      "us-east-2": "cloud9.us-east-2.amazonaws.com",
      "us-east-1": "cloud9.us-east-1.amazonaws.com",
      "cn-northwest-1": "cloud9.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "cloud9.ap-south-1.amazonaws.com",
      "eu-north-1": "cloud9.eu-north-1.amazonaws.com",
      "ap-northeast-2": "cloud9.ap-northeast-2.amazonaws.com",
      "us-west-1": "cloud9.us-west-1.amazonaws.com",
      "us-gov-east-1": "cloud9.us-gov-east-1.amazonaws.com",
      "eu-west-3": "cloud9.eu-west-3.amazonaws.com",
      "cn-north-1": "cloud9.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "cloud9.sa-east-1.amazonaws.com",
      "eu-west-1": "cloud9.eu-west-1.amazonaws.com",
      "us-gov-west-1": "cloud9.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "cloud9.ap-southeast-2.amazonaws.com",
      "ca-central-1": "cloud9.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "cloud9"
method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.}
type
  Call_CreateEnvironmentEC2_600768 = ref object of OpenApiRestCall_600426
proc url_CreateEnvironmentEC2_600770(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateEnvironmentEC2_600769(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates an AWS Cloud9 development environment, launches an Amazon Elastic Compute Cloud (Amazon EC2) instance, and then connects from the instance to the environment.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600882 = header.getOrDefault("X-Amz-Date")
  valid_600882 = validateParameter(valid_600882, JString, required = false,
                                 default = nil)
  if valid_600882 != nil:
    section.add "X-Amz-Date", valid_600882
  var valid_600883 = header.getOrDefault("X-Amz-Security-Token")
  valid_600883 = validateParameter(valid_600883, JString, required = false,
                                 default = nil)
  if valid_600883 != nil:
    section.add "X-Amz-Security-Token", valid_600883
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600897 = header.getOrDefault("X-Amz-Target")
  valid_600897 = validateParameter(valid_600897, JString, required = true, default = newJString(
      "AWSCloud9WorkspaceManagementService.CreateEnvironmentEC2"))
  if valid_600897 != nil:
    section.add "X-Amz-Target", valid_600897
  var valid_600898 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600898 = validateParameter(valid_600898, JString, required = false,
                                 default = nil)
  if valid_600898 != nil:
    section.add "X-Amz-Content-Sha256", valid_600898
  var valid_600899 = header.getOrDefault("X-Amz-Algorithm")
  valid_600899 = validateParameter(valid_600899, JString, required = false,
                                 default = nil)
  if valid_600899 != nil:
    section.add "X-Amz-Algorithm", valid_600899
  var valid_600900 = header.getOrDefault("X-Amz-Signature")
  valid_600900 = validateParameter(valid_600900, JString, required = false,
                                 default = nil)
  if valid_600900 != nil:
    section.add "X-Amz-Signature", valid_600900
  var valid_600901 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600901 = validateParameter(valid_600901, JString, required = false,
                                 default = nil)
  if valid_600901 != nil:
    section.add "X-Amz-SignedHeaders", valid_600901
  var valid_600902 = header.getOrDefault("X-Amz-Credential")
  valid_600902 = validateParameter(valid_600902, JString, required = false,
                                 default = nil)
  if valid_600902 != nil:
    section.add "X-Amz-Credential", valid_600902
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600926: Call_CreateEnvironmentEC2_600768; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an AWS Cloud9 development environment, launches an Amazon Elastic Compute Cloud (Amazon EC2) instance, and then connects from the instance to the environment.
  ## 
  let valid = call_600926.validator(path, query, header, formData, body)
  let scheme = call_600926.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600926.url(scheme.get, call_600926.host, call_600926.base,
                         call_600926.route, valid.getOrDefault("path"))
  result = hook(call_600926, url, valid)

proc call*(call_600997: Call_CreateEnvironmentEC2_600768; body: JsonNode): Recallable =
  ## createEnvironmentEC2
  ## Creates an AWS Cloud9 development environment, launches an Amazon Elastic Compute Cloud (Amazon EC2) instance, and then connects from the instance to the environment.
  ##   body: JObject (required)
  var body_600998 = newJObject()
  if body != nil:
    body_600998 = body
  result = call_600997.call(nil, nil, nil, nil, body_600998)

var createEnvironmentEC2* = Call_CreateEnvironmentEC2_600768(
    name: "createEnvironmentEC2", meth: HttpMethod.HttpPost,
    host: "cloud9.amazonaws.com", route: "/#X-Amz-Target=AWSCloud9WorkspaceManagementService.CreateEnvironmentEC2",
    validator: validate_CreateEnvironmentEC2_600769, base: "/",
    url: url_CreateEnvironmentEC2_600770, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateEnvironmentMembership_601037 = ref object of OpenApiRestCall_600426
proc url_CreateEnvironmentMembership_601039(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateEnvironmentMembership_601038(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Adds an environment member to an AWS Cloud9 development environment.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601040 = header.getOrDefault("X-Amz-Date")
  valid_601040 = validateParameter(valid_601040, JString, required = false,
                                 default = nil)
  if valid_601040 != nil:
    section.add "X-Amz-Date", valid_601040
  var valid_601041 = header.getOrDefault("X-Amz-Security-Token")
  valid_601041 = validateParameter(valid_601041, JString, required = false,
                                 default = nil)
  if valid_601041 != nil:
    section.add "X-Amz-Security-Token", valid_601041
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601042 = header.getOrDefault("X-Amz-Target")
  valid_601042 = validateParameter(valid_601042, JString, required = true, default = newJString(
      "AWSCloud9WorkspaceManagementService.CreateEnvironmentMembership"))
  if valid_601042 != nil:
    section.add "X-Amz-Target", valid_601042
  var valid_601043 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601043 = validateParameter(valid_601043, JString, required = false,
                                 default = nil)
  if valid_601043 != nil:
    section.add "X-Amz-Content-Sha256", valid_601043
  var valid_601044 = header.getOrDefault("X-Amz-Algorithm")
  valid_601044 = validateParameter(valid_601044, JString, required = false,
                                 default = nil)
  if valid_601044 != nil:
    section.add "X-Amz-Algorithm", valid_601044
  var valid_601045 = header.getOrDefault("X-Amz-Signature")
  valid_601045 = validateParameter(valid_601045, JString, required = false,
                                 default = nil)
  if valid_601045 != nil:
    section.add "X-Amz-Signature", valid_601045
  var valid_601046 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601046 = validateParameter(valid_601046, JString, required = false,
                                 default = nil)
  if valid_601046 != nil:
    section.add "X-Amz-SignedHeaders", valid_601046
  var valid_601047 = header.getOrDefault("X-Amz-Credential")
  valid_601047 = validateParameter(valid_601047, JString, required = false,
                                 default = nil)
  if valid_601047 != nil:
    section.add "X-Amz-Credential", valid_601047
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601049: Call_CreateEnvironmentMembership_601037; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds an environment member to an AWS Cloud9 development environment.
  ## 
  let valid = call_601049.validator(path, query, header, formData, body)
  let scheme = call_601049.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601049.url(scheme.get, call_601049.host, call_601049.base,
                         call_601049.route, valid.getOrDefault("path"))
  result = hook(call_601049, url, valid)

proc call*(call_601050: Call_CreateEnvironmentMembership_601037; body: JsonNode): Recallable =
  ## createEnvironmentMembership
  ## Adds an environment member to an AWS Cloud9 development environment.
  ##   body: JObject (required)
  var body_601051 = newJObject()
  if body != nil:
    body_601051 = body
  result = call_601050.call(nil, nil, nil, nil, body_601051)

var createEnvironmentMembership* = Call_CreateEnvironmentMembership_601037(
    name: "createEnvironmentMembership", meth: HttpMethod.HttpPost,
    host: "cloud9.amazonaws.com", route: "/#X-Amz-Target=AWSCloud9WorkspaceManagementService.CreateEnvironmentMembership",
    validator: validate_CreateEnvironmentMembership_601038, base: "/",
    url: url_CreateEnvironmentMembership_601039,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteEnvironment_601052 = ref object of OpenApiRestCall_600426
proc url_DeleteEnvironment_601054(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteEnvironment_601053(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Deletes an AWS Cloud9 development environment. If an Amazon EC2 instance is connected to the environment, also terminates the instance.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601055 = header.getOrDefault("X-Amz-Date")
  valid_601055 = validateParameter(valid_601055, JString, required = false,
                                 default = nil)
  if valid_601055 != nil:
    section.add "X-Amz-Date", valid_601055
  var valid_601056 = header.getOrDefault("X-Amz-Security-Token")
  valid_601056 = validateParameter(valid_601056, JString, required = false,
                                 default = nil)
  if valid_601056 != nil:
    section.add "X-Amz-Security-Token", valid_601056
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601057 = header.getOrDefault("X-Amz-Target")
  valid_601057 = validateParameter(valid_601057, JString, required = true, default = newJString(
      "AWSCloud9WorkspaceManagementService.DeleteEnvironment"))
  if valid_601057 != nil:
    section.add "X-Amz-Target", valid_601057
  var valid_601058 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601058 = validateParameter(valid_601058, JString, required = false,
                                 default = nil)
  if valid_601058 != nil:
    section.add "X-Amz-Content-Sha256", valid_601058
  var valid_601059 = header.getOrDefault("X-Amz-Algorithm")
  valid_601059 = validateParameter(valid_601059, JString, required = false,
                                 default = nil)
  if valid_601059 != nil:
    section.add "X-Amz-Algorithm", valid_601059
  var valid_601060 = header.getOrDefault("X-Amz-Signature")
  valid_601060 = validateParameter(valid_601060, JString, required = false,
                                 default = nil)
  if valid_601060 != nil:
    section.add "X-Amz-Signature", valid_601060
  var valid_601061 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601061 = validateParameter(valid_601061, JString, required = false,
                                 default = nil)
  if valid_601061 != nil:
    section.add "X-Amz-SignedHeaders", valid_601061
  var valid_601062 = header.getOrDefault("X-Amz-Credential")
  valid_601062 = validateParameter(valid_601062, JString, required = false,
                                 default = nil)
  if valid_601062 != nil:
    section.add "X-Amz-Credential", valid_601062
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601064: Call_DeleteEnvironment_601052; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an AWS Cloud9 development environment. If an Amazon EC2 instance is connected to the environment, also terminates the instance.
  ## 
  let valid = call_601064.validator(path, query, header, formData, body)
  let scheme = call_601064.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601064.url(scheme.get, call_601064.host, call_601064.base,
                         call_601064.route, valid.getOrDefault("path"))
  result = hook(call_601064, url, valid)

proc call*(call_601065: Call_DeleteEnvironment_601052; body: JsonNode): Recallable =
  ## deleteEnvironment
  ## Deletes an AWS Cloud9 development environment. If an Amazon EC2 instance is connected to the environment, also terminates the instance.
  ##   body: JObject (required)
  var body_601066 = newJObject()
  if body != nil:
    body_601066 = body
  result = call_601065.call(nil, nil, nil, nil, body_601066)

var deleteEnvironment* = Call_DeleteEnvironment_601052(name: "deleteEnvironment",
    meth: HttpMethod.HttpPost, host: "cloud9.amazonaws.com", route: "/#X-Amz-Target=AWSCloud9WorkspaceManagementService.DeleteEnvironment",
    validator: validate_DeleteEnvironment_601053, base: "/",
    url: url_DeleteEnvironment_601054, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteEnvironmentMembership_601067 = ref object of OpenApiRestCall_600426
proc url_DeleteEnvironmentMembership_601069(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteEnvironmentMembership_601068(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes an environment member from an AWS Cloud9 development environment.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601070 = header.getOrDefault("X-Amz-Date")
  valid_601070 = validateParameter(valid_601070, JString, required = false,
                                 default = nil)
  if valid_601070 != nil:
    section.add "X-Amz-Date", valid_601070
  var valid_601071 = header.getOrDefault("X-Amz-Security-Token")
  valid_601071 = validateParameter(valid_601071, JString, required = false,
                                 default = nil)
  if valid_601071 != nil:
    section.add "X-Amz-Security-Token", valid_601071
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601072 = header.getOrDefault("X-Amz-Target")
  valid_601072 = validateParameter(valid_601072, JString, required = true, default = newJString(
      "AWSCloud9WorkspaceManagementService.DeleteEnvironmentMembership"))
  if valid_601072 != nil:
    section.add "X-Amz-Target", valid_601072
  var valid_601073 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601073 = validateParameter(valid_601073, JString, required = false,
                                 default = nil)
  if valid_601073 != nil:
    section.add "X-Amz-Content-Sha256", valid_601073
  var valid_601074 = header.getOrDefault("X-Amz-Algorithm")
  valid_601074 = validateParameter(valid_601074, JString, required = false,
                                 default = nil)
  if valid_601074 != nil:
    section.add "X-Amz-Algorithm", valid_601074
  var valid_601075 = header.getOrDefault("X-Amz-Signature")
  valid_601075 = validateParameter(valid_601075, JString, required = false,
                                 default = nil)
  if valid_601075 != nil:
    section.add "X-Amz-Signature", valid_601075
  var valid_601076 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601076 = validateParameter(valid_601076, JString, required = false,
                                 default = nil)
  if valid_601076 != nil:
    section.add "X-Amz-SignedHeaders", valid_601076
  var valid_601077 = header.getOrDefault("X-Amz-Credential")
  valid_601077 = validateParameter(valid_601077, JString, required = false,
                                 default = nil)
  if valid_601077 != nil:
    section.add "X-Amz-Credential", valid_601077
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601079: Call_DeleteEnvironmentMembership_601067; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an environment member from an AWS Cloud9 development environment.
  ## 
  let valid = call_601079.validator(path, query, header, formData, body)
  let scheme = call_601079.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601079.url(scheme.get, call_601079.host, call_601079.base,
                         call_601079.route, valid.getOrDefault("path"))
  result = hook(call_601079, url, valid)

proc call*(call_601080: Call_DeleteEnvironmentMembership_601067; body: JsonNode): Recallable =
  ## deleteEnvironmentMembership
  ## Deletes an environment member from an AWS Cloud9 development environment.
  ##   body: JObject (required)
  var body_601081 = newJObject()
  if body != nil:
    body_601081 = body
  result = call_601080.call(nil, nil, nil, nil, body_601081)

var deleteEnvironmentMembership* = Call_DeleteEnvironmentMembership_601067(
    name: "deleteEnvironmentMembership", meth: HttpMethod.HttpPost,
    host: "cloud9.amazonaws.com", route: "/#X-Amz-Target=AWSCloud9WorkspaceManagementService.DeleteEnvironmentMembership",
    validator: validate_DeleteEnvironmentMembership_601068, base: "/",
    url: url_DeleteEnvironmentMembership_601069,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEnvironmentMemberships_601082 = ref object of OpenApiRestCall_600426
proc url_DescribeEnvironmentMemberships_601084(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeEnvironmentMemberships_601083(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets information about environment members for an AWS Cloud9 development environment.
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
  var valid_601085 = query.getOrDefault("maxResults")
  valid_601085 = validateParameter(valid_601085, JString, required = false,
                                 default = nil)
  if valid_601085 != nil:
    section.add "maxResults", valid_601085
  var valid_601086 = query.getOrDefault("nextToken")
  valid_601086 = validateParameter(valid_601086, JString, required = false,
                                 default = nil)
  if valid_601086 != nil:
    section.add "nextToken", valid_601086
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601087 = header.getOrDefault("X-Amz-Date")
  valid_601087 = validateParameter(valid_601087, JString, required = false,
                                 default = nil)
  if valid_601087 != nil:
    section.add "X-Amz-Date", valid_601087
  var valid_601088 = header.getOrDefault("X-Amz-Security-Token")
  valid_601088 = validateParameter(valid_601088, JString, required = false,
                                 default = nil)
  if valid_601088 != nil:
    section.add "X-Amz-Security-Token", valid_601088
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601089 = header.getOrDefault("X-Amz-Target")
  valid_601089 = validateParameter(valid_601089, JString, required = true, default = newJString(
      "AWSCloud9WorkspaceManagementService.DescribeEnvironmentMemberships"))
  if valid_601089 != nil:
    section.add "X-Amz-Target", valid_601089
  var valid_601090 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601090 = validateParameter(valid_601090, JString, required = false,
                                 default = nil)
  if valid_601090 != nil:
    section.add "X-Amz-Content-Sha256", valid_601090
  var valid_601091 = header.getOrDefault("X-Amz-Algorithm")
  valid_601091 = validateParameter(valid_601091, JString, required = false,
                                 default = nil)
  if valid_601091 != nil:
    section.add "X-Amz-Algorithm", valid_601091
  var valid_601092 = header.getOrDefault("X-Amz-Signature")
  valid_601092 = validateParameter(valid_601092, JString, required = false,
                                 default = nil)
  if valid_601092 != nil:
    section.add "X-Amz-Signature", valid_601092
  var valid_601093 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601093 = validateParameter(valid_601093, JString, required = false,
                                 default = nil)
  if valid_601093 != nil:
    section.add "X-Amz-SignedHeaders", valid_601093
  var valid_601094 = header.getOrDefault("X-Amz-Credential")
  valid_601094 = validateParameter(valid_601094, JString, required = false,
                                 default = nil)
  if valid_601094 != nil:
    section.add "X-Amz-Credential", valid_601094
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601096: Call_DescribeEnvironmentMemberships_601082; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about environment members for an AWS Cloud9 development environment.
  ## 
  let valid = call_601096.validator(path, query, header, formData, body)
  let scheme = call_601096.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601096.url(scheme.get, call_601096.host, call_601096.base,
                         call_601096.route, valid.getOrDefault("path"))
  result = hook(call_601096, url, valid)

proc call*(call_601097: Call_DescribeEnvironmentMemberships_601082; body: JsonNode;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## describeEnvironmentMemberships
  ## Gets information about environment members for an AWS Cloud9 development environment.
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_601098 = newJObject()
  var body_601099 = newJObject()
  add(query_601098, "maxResults", newJString(maxResults))
  add(query_601098, "nextToken", newJString(nextToken))
  if body != nil:
    body_601099 = body
  result = call_601097.call(nil, query_601098, nil, nil, body_601099)

var describeEnvironmentMemberships* = Call_DescribeEnvironmentMemberships_601082(
    name: "describeEnvironmentMemberships", meth: HttpMethod.HttpPost,
    host: "cloud9.amazonaws.com", route: "/#X-Amz-Target=AWSCloud9WorkspaceManagementService.DescribeEnvironmentMemberships",
    validator: validate_DescribeEnvironmentMemberships_601083, base: "/",
    url: url_DescribeEnvironmentMemberships_601084,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEnvironmentStatus_601101 = ref object of OpenApiRestCall_600426
proc url_DescribeEnvironmentStatus_601103(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeEnvironmentStatus_601102(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets status information for an AWS Cloud9 development environment.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601104 = header.getOrDefault("X-Amz-Date")
  valid_601104 = validateParameter(valid_601104, JString, required = false,
                                 default = nil)
  if valid_601104 != nil:
    section.add "X-Amz-Date", valid_601104
  var valid_601105 = header.getOrDefault("X-Amz-Security-Token")
  valid_601105 = validateParameter(valid_601105, JString, required = false,
                                 default = nil)
  if valid_601105 != nil:
    section.add "X-Amz-Security-Token", valid_601105
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601106 = header.getOrDefault("X-Amz-Target")
  valid_601106 = validateParameter(valid_601106, JString, required = true, default = newJString(
      "AWSCloud9WorkspaceManagementService.DescribeEnvironmentStatus"))
  if valid_601106 != nil:
    section.add "X-Amz-Target", valid_601106
  var valid_601107 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601107 = validateParameter(valid_601107, JString, required = false,
                                 default = nil)
  if valid_601107 != nil:
    section.add "X-Amz-Content-Sha256", valid_601107
  var valid_601108 = header.getOrDefault("X-Amz-Algorithm")
  valid_601108 = validateParameter(valid_601108, JString, required = false,
                                 default = nil)
  if valid_601108 != nil:
    section.add "X-Amz-Algorithm", valid_601108
  var valid_601109 = header.getOrDefault("X-Amz-Signature")
  valid_601109 = validateParameter(valid_601109, JString, required = false,
                                 default = nil)
  if valid_601109 != nil:
    section.add "X-Amz-Signature", valid_601109
  var valid_601110 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601110 = validateParameter(valid_601110, JString, required = false,
                                 default = nil)
  if valid_601110 != nil:
    section.add "X-Amz-SignedHeaders", valid_601110
  var valid_601111 = header.getOrDefault("X-Amz-Credential")
  valid_601111 = validateParameter(valid_601111, JString, required = false,
                                 default = nil)
  if valid_601111 != nil:
    section.add "X-Amz-Credential", valid_601111
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601113: Call_DescribeEnvironmentStatus_601101; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets status information for an AWS Cloud9 development environment.
  ## 
  let valid = call_601113.validator(path, query, header, formData, body)
  let scheme = call_601113.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601113.url(scheme.get, call_601113.host, call_601113.base,
                         call_601113.route, valid.getOrDefault("path"))
  result = hook(call_601113, url, valid)

proc call*(call_601114: Call_DescribeEnvironmentStatus_601101; body: JsonNode): Recallable =
  ## describeEnvironmentStatus
  ## Gets status information for an AWS Cloud9 development environment.
  ##   body: JObject (required)
  var body_601115 = newJObject()
  if body != nil:
    body_601115 = body
  result = call_601114.call(nil, nil, nil, nil, body_601115)

var describeEnvironmentStatus* = Call_DescribeEnvironmentStatus_601101(
    name: "describeEnvironmentStatus", meth: HttpMethod.HttpPost,
    host: "cloud9.amazonaws.com", route: "/#X-Amz-Target=AWSCloud9WorkspaceManagementService.DescribeEnvironmentStatus",
    validator: validate_DescribeEnvironmentStatus_601102, base: "/",
    url: url_DescribeEnvironmentStatus_601103,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEnvironments_601116 = ref object of OpenApiRestCall_600426
proc url_DescribeEnvironments_601118(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeEnvironments_601117(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets information about AWS Cloud9 development environments.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601119 = header.getOrDefault("X-Amz-Date")
  valid_601119 = validateParameter(valid_601119, JString, required = false,
                                 default = nil)
  if valid_601119 != nil:
    section.add "X-Amz-Date", valid_601119
  var valid_601120 = header.getOrDefault("X-Amz-Security-Token")
  valid_601120 = validateParameter(valid_601120, JString, required = false,
                                 default = nil)
  if valid_601120 != nil:
    section.add "X-Amz-Security-Token", valid_601120
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601121 = header.getOrDefault("X-Amz-Target")
  valid_601121 = validateParameter(valid_601121, JString, required = true, default = newJString(
      "AWSCloud9WorkspaceManagementService.DescribeEnvironments"))
  if valid_601121 != nil:
    section.add "X-Amz-Target", valid_601121
  var valid_601122 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601122 = validateParameter(valid_601122, JString, required = false,
                                 default = nil)
  if valid_601122 != nil:
    section.add "X-Amz-Content-Sha256", valid_601122
  var valid_601123 = header.getOrDefault("X-Amz-Algorithm")
  valid_601123 = validateParameter(valid_601123, JString, required = false,
                                 default = nil)
  if valid_601123 != nil:
    section.add "X-Amz-Algorithm", valid_601123
  var valid_601124 = header.getOrDefault("X-Amz-Signature")
  valid_601124 = validateParameter(valid_601124, JString, required = false,
                                 default = nil)
  if valid_601124 != nil:
    section.add "X-Amz-Signature", valid_601124
  var valid_601125 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601125 = validateParameter(valid_601125, JString, required = false,
                                 default = nil)
  if valid_601125 != nil:
    section.add "X-Amz-SignedHeaders", valid_601125
  var valid_601126 = header.getOrDefault("X-Amz-Credential")
  valid_601126 = validateParameter(valid_601126, JString, required = false,
                                 default = nil)
  if valid_601126 != nil:
    section.add "X-Amz-Credential", valid_601126
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601128: Call_DescribeEnvironments_601116; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about AWS Cloud9 development environments.
  ## 
  let valid = call_601128.validator(path, query, header, formData, body)
  let scheme = call_601128.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601128.url(scheme.get, call_601128.host, call_601128.base,
                         call_601128.route, valid.getOrDefault("path"))
  result = hook(call_601128, url, valid)

proc call*(call_601129: Call_DescribeEnvironments_601116; body: JsonNode): Recallable =
  ## describeEnvironments
  ## Gets information about AWS Cloud9 development environments.
  ##   body: JObject (required)
  var body_601130 = newJObject()
  if body != nil:
    body_601130 = body
  result = call_601129.call(nil, nil, nil, nil, body_601130)

var describeEnvironments* = Call_DescribeEnvironments_601116(
    name: "describeEnvironments", meth: HttpMethod.HttpPost,
    host: "cloud9.amazonaws.com", route: "/#X-Amz-Target=AWSCloud9WorkspaceManagementService.DescribeEnvironments",
    validator: validate_DescribeEnvironments_601117, base: "/",
    url: url_DescribeEnvironments_601118, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListEnvironments_601131 = ref object of OpenApiRestCall_600426
proc url_ListEnvironments_601133(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListEnvironments_601132(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Gets a list of AWS Cloud9 development environment identifiers.
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
  var valid_601134 = query.getOrDefault("maxResults")
  valid_601134 = validateParameter(valid_601134, JString, required = false,
                                 default = nil)
  if valid_601134 != nil:
    section.add "maxResults", valid_601134
  var valid_601135 = query.getOrDefault("nextToken")
  valid_601135 = validateParameter(valid_601135, JString, required = false,
                                 default = nil)
  if valid_601135 != nil:
    section.add "nextToken", valid_601135
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601136 = header.getOrDefault("X-Amz-Date")
  valid_601136 = validateParameter(valid_601136, JString, required = false,
                                 default = nil)
  if valid_601136 != nil:
    section.add "X-Amz-Date", valid_601136
  var valid_601137 = header.getOrDefault("X-Amz-Security-Token")
  valid_601137 = validateParameter(valid_601137, JString, required = false,
                                 default = nil)
  if valid_601137 != nil:
    section.add "X-Amz-Security-Token", valid_601137
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601138 = header.getOrDefault("X-Amz-Target")
  valid_601138 = validateParameter(valid_601138, JString, required = true, default = newJString(
      "AWSCloud9WorkspaceManagementService.ListEnvironments"))
  if valid_601138 != nil:
    section.add "X-Amz-Target", valid_601138
  var valid_601139 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601139 = validateParameter(valid_601139, JString, required = false,
                                 default = nil)
  if valid_601139 != nil:
    section.add "X-Amz-Content-Sha256", valid_601139
  var valid_601140 = header.getOrDefault("X-Amz-Algorithm")
  valid_601140 = validateParameter(valid_601140, JString, required = false,
                                 default = nil)
  if valid_601140 != nil:
    section.add "X-Amz-Algorithm", valid_601140
  var valid_601141 = header.getOrDefault("X-Amz-Signature")
  valid_601141 = validateParameter(valid_601141, JString, required = false,
                                 default = nil)
  if valid_601141 != nil:
    section.add "X-Amz-Signature", valid_601141
  var valid_601142 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601142 = validateParameter(valid_601142, JString, required = false,
                                 default = nil)
  if valid_601142 != nil:
    section.add "X-Amz-SignedHeaders", valid_601142
  var valid_601143 = header.getOrDefault("X-Amz-Credential")
  valid_601143 = validateParameter(valid_601143, JString, required = false,
                                 default = nil)
  if valid_601143 != nil:
    section.add "X-Amz-Credential", valid_601143
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601145: Call_ListEnvironments_601131; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a list of AWS Cloud9 development environment identifiers.
  ## 
  let valid = call_601145.validator(path, query, header, formData, body)
  let scheme = call_601145.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601145.url(scheme.get, call_601145.host, call_601145.base,
                         call_601145.route, valid.getOrDefault("path"))
  result = hook(call_601145, url, valid)

proc call*(call_601146: Call_ListEnvironments_601131; body: JsonNode;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## listEnvironments
  ## Gets a list of AWS Cloud9 development environment identifiers.
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_601147 = newJObject()
  var body_601148 = newJObject()
  add(query_601147, "maxResults", newJString(maxResults))
  add(query_601147, "nextToken", newJString(nextToken))
  if body != nil:
    body_601148 = body
  result = call_601146.call(nil, query_601147, nil, nil, body_601148)

var listEnvironments* = Call_ListEnvironments_601131(name: "listEnvironments",
    meth: HttpMethod.HttpPost, host: "cloud9.amazonaws.com", route: "/#X-Amz-Target=AWSCloud9WorkspaceManagementService.ListEnvironments",
    validator: validate_ListEnvironments_601132, base: "/",
    url: url_ListEnvironments_601133, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateEnvironment_601149 = ref object of OpenApiRestCall_600426
proc url_UpdateEnvironment_601151(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateEnvironment_601150(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Changes the settings of an existing AWS Cloud9 development environment.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601152 = header.getOrDefault("X-Amz-Date")
  valid_601152 = validateParameter(valid_601152, JString, required = false,
                                 default = nil)
  if valid_601152 != nil:
    section.add "X-Amz-Date", valid_601152
  var valid_601153 = header.getOrDefault("X-Amz-Security-Token")
  valid_601153 = validateParameter(valid_601153, JString, required = false,
                                 default = nil)
  if valid_601153 != nil:
    section.add "X-Amz-Security-Token", valid_601153
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601154 = header.getOrDefault("X-Amz-Target")
  valid_601154 = validateParameter(valid_601154, JString, required = true, default = newJString(
      "AWSCloud9WorkspaceManagementService.UpdateEnvironment"))
  if valid_601154 != nil:
    section.add "X-Amz-Target", valid_601154
  var valid_601155 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601155 = validateParameter(valid_601155, JString, required = false,
                                 default = nil)
  if valid_601155 != nil:
    section.add "X-Amz-Content-Sha256", valid_601155
  var valid_601156 = header.getOrDefault("X-Amz-Algorithm")
  valid_601156 = validateParameter(valid_601156, JString, required = false,
                                 default = nil)
  if valid_601156 != nil:
    section.add "X-Amz-Algorithm", valid_601156
  var valid_601157 = header.getOrDefault("X-Amz-Signature")
  valid_601157 = validateParameter(valid_601157, JString, required = false,
                                 default = nil)
  if valid_601157 != nil:
    section.add "X-Amz-Signature", valid_601157
  var valid_601158 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601158 = validateParameter(valid_601158, JString, required = false,
                                 default = nil)
  if valid_601158 != nil:
    section.add "X-Amz-SignedHeaders", valid_601158
  var valid_601159 = header.getOrDefault("X-Amz-Credential")
  valid_601159 = validateParameter(valid_601159, JString, required = false,
                                 default = nil)
  if valid_601159 != nil:
    section.add "X-Amz-Credential", valid_601159
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601161: Call_UpdateEnvironment_601149; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes the settings of an existing AWS Cloud9 development environment.
  ## 
  let valid = call_601161.validator(path, query, header, formData, body)
  let scheme = call_601161.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601161.url(scheme.get, call_601161.host, call_601161.base,
                         call_601161.route, valid.getOrDefault("path"))
  result = hook(call_601161, url, valid)

proc call*(call_601162: Call_UpdateEnvironment_601149; body: JsonNode): Recallable =
  ## updateEnvironment
  ## Changes the settings of an existing AWS Cloud9 development environment.
  ##   body: JObject (required)
  var body_601163 = newJObject()
  if body != nil:
    body_601163 = body
  result = call_601162.call(nil, nil, nil, nil, body_601163)

var updateEnvironment* = Call_UpdateEnvironment_601149(name: "updateEnvironment",
    meth: HttpMethod.HttpPost, host: "cloud9.amazonaws.com", route: "/#X-Amz-Target=AWSCloud9WorkspaceManagementService.UpdateEnvironment",
    validator: validate_UpdateEnvironment_601150, base: "/",
    url: url_UpdateEnvironment_601151, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateEnvironmentMembership_601164 = ref object of OpenApiRestCall_600426
proc url_UpdateEnvironmentMembership_601166(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateEnvironmentMembership_601165(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Changes the settings of an existing environment member for an AWS Cloud9 development environment.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601167 = header.getOrDefault("X-Amz-Date")
  valid_601167 = validateParameter(valid_601167, JString, required = false,
                                 default = nil)
  if valid_601167 != nil:
    section.add "X-Amz-Date", valid_601167
  var valid_601168 = header.getOrDefault("X-Amz-Security-Token")
  valid_601168 = validateParameter(valid_601168, JString, required = false,
                                 default = nil)
  if valid_601168 != nil:
    section.add "X-Amz-Security-Token", valid_601168
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601169 = header.getOrDefault("X-Amz-Target")
  valid_601169 = validateParameter(valid_601169, JString, required = true, default = newJString(
      "AWSCloud9WorkspaceManagementService.UpdateEnvironmentMembership"))
  if valid_601169 != nil:
    section.add "X-Amz-Target", valid_601169
  var valid_601170 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601170 = validateParameter(valid_601170, JString, required = false,
                                 default = nil)
  if valid_601170 != nil:
    section.add "X-Amz-Content-Sha256", valid_601170
  var valid_601171 = header.getOrDefault("X-Amz-Algorithm")
  valid_601171 = validateParameter(valid_601171, JString, required = false,
                                 default = nil)
  if valid_601171 != nil:
    section.add "X-Amz-Algorithm", valid_601171
  var valid_601172 = header.getOrDefault("X-Amz-Signature")
  valid_601172 = validateParameter(valid_601172, JString, required = false,
                                 default = nil)
  if valid_601172 != nil:
    section.add "X-Amz-Signature", valid_601172
  var valid_601173 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601173 = validateParameter(valid_601173, JString, required = false,
                                 default = nil)
  if valid_601173 != nil:
    section.add "X-Amz-SignedHeaders", valid_601173
  var valid_601174 = header.getOrDefault("X-Amz-Credential")
  valid_601174 = validateParameter(valid_601174, JString, required = false,
                                 default = nil)
  if valid_601174 != nil:
    section.add "X-Amz-Credential", valid_601174
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601176: Call_UpdateEnvironmentMembership_601164; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes the settings of an existing environment member for an AWS Cloud9 development environment.
  ## 
  let valid = call_601176.validator(path, query, header, formData, body)
  let scheme = call_601176.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601176.url(scheme.get, call_601176.host, call_601176.base,
                         call_601176.route, valid.getOrDefault("path"))
  result = hook(call_601176, url, valid)

proc call*(call_601177: Call_UpdateEnvironmentMembership_601164; body: JsonNode): Recallable =
  ## updateEnvironmentMembership
  ## Changes the settings of an existing environment member for an AWS Cloud9 development environment.
  ##   body: JObject (required)
  var body_601178 = newJObject()
  if body != nil:
    body_601178 = body
  result = call_601177.call(nil, nil, nil, nil, body_601178)

var updateEnvironmentMembership* = Call_UpdateEnvironmentMembership_601164(
    name: "updateEnvironmentMembership", meth: HttpMethod.HttpPost,
    host: "cloud9.amazonaws.com", route: "/#X-Amz-Target=AWSCloud9WorkspaceManagementService.UpdateEnvironmentMembership",
    validator: validate_UpdateEnvironmentMembership_601165, base: "/",
    url: url_UpdateEnvironmentMembership_601166,
    schemes: {Scheme.Https, Scheme.Http})
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
  echo recall.headers
  recall.headers.del "Host"
  recall.url = $url

method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, "")
  result.sign(input.getOrDefault("query"), SHA256)
