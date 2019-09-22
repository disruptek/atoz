
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

  OpenApiRestCall_602433 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_602433](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_602433): Option[Scheme] {.used.} =
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
  result = some(head & remainder.get)

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
  Call_CreateEnvironmentEC2_602770 = ref object of OpenApiRestCall_602433
proc url_CreateEnvironmentEC2_602772(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateEnvironmentEC2_602771(path: JsonNode; query: JsonNode;
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
  var valid_602884 = header.getOrDefault("X-Amz-Date")
  valid_602884 = validateParameter(valid_602884, JString, required = false,
                                 default = nil)
  if valid_602884 != nil:
    section.add "X-Amz-Date", valid_602884
  var valid_602885 = header.getOrDefault("X-Amz-Security-Token")
  valid_602885 = validateParameter(valid_602885, JString, required = false,
                                 default = nil)
  if valid_602885 != nil:
    section.add "X-Amz-Security-Token", valid_602885
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602899 = header.getOrDefault("X-Amz-Target")
  valid_602899 = validateParameter(valid_602899, JString, required = true, default = newJString(
      "AWSCloud9WorkspaceManagementService.CreateEnvironmentEC2"))
  if valid_602899 != nil:
    section.add "X-Amz-Target", valid_602899
  var valid_602900 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602900 = validateParameter(valid_602900, JString, required = false,
                                 default = nil)
  if valid_602900 != nil:
    section.add "X-Amz-Content-Sha256", valid_602900
  var valid_602901 = header.getOrDefault("X-Amz-Algorithm")
  valid_602901 = validateParameter(valid_602901, JString, required = false,
                                 default = nil)
  if valid_602901 != nil:
    section.add "X-Amz-Algorithm", valid_602901
  var valid_602902 = header.getOrDefault("X-Amz-Signature")
  valid_602902 = validateParameter(valid_602902, JString, required = false,
                                 default = nil)
  if valid_602902 != nil:
    section.add "X-Amz-Signature", valid_602902
  var valid_602903 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602903 = validateParameter(valid_602903, JString, required = false,
                                 default = nil)
  if valid_602903 != nil:
    section.add "X-Amz-SignedHeaders", valid_602903
  var valid_602904 = header.getOrDefault("X-Amz-Credential")
  valid_602904 = validateParameter(valid_602904, JString, required = false,
                                 default = nil)
  if valid_602904 != nil:
    section.add "X-Amz-Credential", valid_602904
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602928: Call_CreateEnvironmentEC2_602770; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an AWS Cloud9 development environment, launches an Amazon Elastic Compute Cloud (Amazon EC2) instance, and then connects from the instance to the environment.
  ## 
  let valid = call_602928.validator(path, query, header, formData, body)
  let scheme = call_602928.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602928.url(scheme.get, call_602928.host, call_602928.base,
                         call_602928.route, valid.getOrDefault("path"))
  result = hook(call_602928, url, valid)

proc call*(call_602999: Call_CreateEnvironmentEC2_602770; body: JsonNode): Recallable =
  ## createEnvironmentEC2
  ## Creates an AWS Cloud9 development environment, launches an Amazon Elastic Compute Cloud (Amazon EC2) instance, and then connects from the instance to the environment.
  ##   body: JObject (required)
  var body_603000 = newJObject()
  if body != nil:
    body_603000 = body
  result = call_602999.call(nil, nil, nil, nil, body_603000)

var createEnvironmentEC2* = Call_CreateEnvironmentEC2_602770(
    name: "createEnvironmentEC2", meth: HttpMethod.HttpPost,
    host: "cloud9.amazonaws.com", route: "/#X-Amz-Target=AWSCloud9WorkspaceManagementService.CreateEnvironmentEC2",
    validator: validate_CreateEnvironmentEC2_602771, base: "/",
    url: url_CreateEnvironmentEC2_602772, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateEnvironmentMembership_603039 = ref object of OpenApiRestCall_602433
proc url_CreateEnvironmentMembership_603041(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateEnvironmentMembership_603040(path: JsonNode; query: JsonNode;
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
  var valid_603042 = header.getOrDefault("X-Amz-Date")
  valid_603042 = validateParameter(valid_603042, JString, required = false,
                                 default = nil)
  if valid_603042 != nil:
    section.add "X-Amz-Date", valid_603042
  var valid_603043 = header.getOrDefault("X-Amz-Security-Token")
  valid_603043 = validateParameter(valid_603043, JString, required = false,
                                 default = nil)
  if valid_603043 != nil:
    section.add "X-Amz-Security-Token", valid_603043
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603044 = header.getOrDefault("X-Amz-Target")
  valid_603044 = validateParameter(valid_603044, JString, required = true, default = newJString(
      "AWSCloud9WorkspaceManagementService.CreateEnvironmentMembership"))
  if valid_603044 != nil:
    section.add "X-Amz-Target", valid_603044
  var valid_603045 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603045 = validateParameter(valid_603045, JString, required = false,
                                 default = nil)
  if valid_603045 != nil:
    section.add "X-Amz-Content-Sha256", valid_603045
  var valid_603046 = header.getOrDefault("X-Amz-Algorithm")
  valid_603046 = validateParameter(valid_603046, JString, required = false,
                                 default = nil)
  if valid_603046 != nil:
    section.add "X-Amz-Algorithm", valid_603046
  var valid_603047 = header.getOrDefault("X-Amz-Signature")
  valid_603047 = validateParameter(valid_603047, JString, required = false,
                                 default = nil)
  if valid_603047 != nil:
    section.add "X-Amz-Signature", valid_603047
  var valid_603048 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603048 = validateParameter(valid_603048, JString, required = false,
                                 default = nil)
  if valid_603048 != nil:
    section.add "X-Amz-SignedHeaders", valid_603048
  var valid_603049 = header.getOrDefault("X-Amz-Credential")
  valid_603049 = validateParameter(valid_603049, JString, required = false,
                                 default = nil)
  if valid_603049 != nil:
    section.add "X-Amz-Credential", valid_603049
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603051: Call_CreateEnvironmentMembership_603039; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds an environment member to an AWS Cloud9 development environment.
  ## 
  let valid = call_603051.validator(path, query, header, formData, body)
  let scheme = call_603051.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603051.url(scheme.get, call_603051.host, call_603051.base,
                         call_603051.route, valid.getOrDefault("path"))
  result = hook(call_603051, url, valid)

proc call*(call_603052: Call_CreateEnvironmentMembership_603039; body: JsonNode): Recallable =
  ## createEnvironmentMembership
  ## Adds an environment member to an AWS Cloud9 development environment.
  ##   body: JObject (required)
  var body_603053 = newJObject()
  if body != nil:
    body_603053 = body
  result = call_603052.call(nil, nil, nil, nil, body_603053)

var createEnvironmentMembership* = Call_CreateEnvironmentMembership_603039(
    name: "createEnvironmentMembership", meth: HttpMethod.HttpPost,
    host: "cloud9.amazonaws.com", route: "/#X-Amz-Target=AWSCloud9WorkspaceManagementService.CreateEnvironmentMembership",
    validator: validate_CreateEnvironmentMembership_603040, base: "/",
    url: url_CreateEnvironmentMembership_603041,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteEnvironment_603054 = ref object of OpenApiRestCall_602433
proc url_DeleteEnvironment_603056(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteEnvironment_603055(path: JsonNode; query: JsonNode;
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
  var valid_603057 = header.getOrDefault("X-Amz-Date")
  valid_603057 = validateParameter(valid_603057, JString, required = false,
                                 default = nil)
  if valid_603057 != nil:
    section.add "X-Amz-Date", valid_603057
  var valid_603058 = header.getOrDefault("X-Amz-Security-Token")
  valid_603058 = validateParameter(valid_603058, JString, required = false,
                                 default = nil)
  if valid_603058 != nil:
    section.add "X-Amz-Security-Token", valid_603058
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603059 = header.getOrDefault("X-Amz-Target")
  valid_603059 = validateParameter(valid_603059, JString, required = true, default = newJString(
      "AWSCloud9WorkspaceManagementService.DeleteEnvironment"))
  if valid_603059 != nil:
    section.add "X-Amz-Target", valid_603059
  var valid_603060 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603060 = validateParameter(valid_603060, JString, required = false,
                                 default = nil)
  if valid_603060 != nil:
    section.add "X-Amz-Content-Sha256", valid_603060
  var valid_603061 = header.getOrDefault("X-Amz-Algorithm")
  valid_603061 = validateParameter(valid_603061, JString, required = false,
                                 default = nil)
  if valid_603061 != nil:
    section.add "X-Amz-Algorithm", valid_603061
  var valid_603062 = header.getOrDefault("X-Amz-Signature")
  valid_603062 = validateParameter(valid_603062, JString, required = false,
                                 default = nil)
  if valid_603062 != nil:
    section.add "X-Amz-Signature", valid_603062
  var valid_603063 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603063 = validateParameter(valid_603063, JString, required = false,
                                 default = nil)
  if valid_603063 != nil:
    section.add "X-Amz-SignedHeaders", valid_603063
  var valid_603064 = header.getOrDefault("X-Amz-Credential")
  valid_603064 = validateParameter(valid_603064, JString, required = false,
                                 default = nil)
  if valid_603064 != nil:
    section.add "X-Amz-Credential", valid_603064
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603066: Call_DeleteEnvironment_603054; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an AWS Cloud9 development environment. If an Amazon EC2 instance is connected to the environment, also terminates the instance.
  ## 
  let valid = call_603066.validator(path, query, header, formData, body)
  let scheme = call_603066.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603066.url(scheme.get, call_603066.host, call_603066.base,
                         call_603066.route, valid.getOrDefault("path"))
  result = hook(call_603066, url, valid)

proc call*(call_603067: Call_DeleteEnvironment_603054; body: JsonNode): Recallable =
  ## deleteEnvironment
  ## Deletes an AWS Cloud9 development environment. If an Amazon EC2 instance is connected to the environment, also terminates the instance.
  ##   body: JObject (required)
  var body_603068 = newJObject()
  if body != nil:
    body_603068 = body
  result = call_603067.call(nil, nil, nil, nil, body_603068)

var deleteEnvironment* = Call_DeleteEnvironment_603054(name: "deleteEnvironment",
    meth: HttpMethod.HttpPost, host: "cloud9.amazonaws.com", route: "/#X-Amz-Target=AWSCloud9WorkspaceManagementService.DeleteEnvironment",
    validator: validate_DeleteEnvironment_603055, base: "/",
    url: url_DeleteEnvironment_603056, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteEnvironmentMembership_603069 = ref object of OpenApiRestCall_602433
proc url_DeleteEnvironmentMembership_603071(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteEnvironmentMembership_603070(path: JsonNode; query: JsonNode;
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
  var valid_603072 = header.getOrDefault("X-Amz-Date")
  valid_603072 = validateParameter(valid_603072, JString, required = false,
                                 default = nil)
  if valid_603072 != nil:
    section.add "X-Amz-Date", valid_603072
  var valid_603073 = header.getOrDefault("X-Amz-Security-Token")
  valid_603073 = validateParameter(valid_603073, JString, required = false,
                                 default = nil)
  if valid_603073 != nil:
    section.add "X-Amz-Security-Token", valid_603073
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603074 = header.getOrDefault("X-Amz-Target")
  valid_603074 = validateParameter(valid_603074, JString, required = true, default = newJString(
      "AWSCloud9WorkspaceManagementService.DeleteEnvironmentMembership"))
  if valid_603074 != nil:
    section.add "X-Amz-Target", valid_603074
  var valid_603075 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603075 = validateParameter(valid_603075, JString, required = false,
                                 default = nil)
  if valid_603075 != nil:
    section.add "X-Amz-Content-Sha256", valid_603075
  var valid_603076 = header.getOrDefault("X-Amz-Algorithm")
  valid_603076 = validateParameter(valid_603076, JString, required = false,
                                 default = nil)
  if valid_603076 != nil:
    section.add "X-Amz-Algorithm", valid_603076
  var valid_603077 = header.getOrDefault("X-Amz-Signature")
  valid_603077 = validateParameter(valid_603077, JString, required = false,
                                 default = nil)
  if valid_603077 != nil:
    section.add "X-Amz-Signature", valid_603077
  var valid_603078 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603078 = validateParameter(valid_603078, JString, required = false,
                                 default = nil)
  if valid_603078 != nil:
    section.add "X-Amz-SignedHeaders", valid_603078
  var valid_603079 = header.getOrDefault("X-Amz-Credential")
  valid_603079 = validateParameter(valid_603079, JString, required = false,
                                 default = nil)
  if valid_603079 != nil:
    section.add "X-Amz-Credential", valid_603079
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603081: Call_DeleteEnvironmentMembership_603069; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an environment member from an AWS Cloud9 development environment.
  ## 
  let valid = call_603081.validator(path, query, header, formData, body)
  let scheme = call_603081.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603081.url(scheme.get, call_603081.host, call_603081.base,
                         call_603081.route, valid.getOrDefault("path"))
  result = hook(call_603081, url, valid)

proc call*(call_603082: Call_DeleteEnvironmentMembership_603069; body: JsonNode): Recallable =
  ## deleteEnvironmentMembership
  ## Deletes an environment member from an AWS Cloud9 development environment.
  ##   body: JObject (required)
  var body_603083 = newJObject()
  if body != nil:
    body_603083 = body
  result = call_603082.call(nil, nil, nil, nil, body_603083)

var deleteEnvironmentMembership* = Call_DeleteEnvironmentMembership_603069(
    name: "deleteEnvironmentMembership", meth: HttpMethod.HttpPost,
    host: "cloud9.amazonaws.com", route: "/#X-Amz-Target=AWSCloud9WorkspaceManagementService.DeleteEnvironmentMembership",
    validator: validate_DeleteEnvironmentMembership_603070, base: "/",
    url: url_DeleteEnvironmentMembership_603071,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEnvironmentMemberships_603084 = ref object of OpenApiRestCall_602433
proc url_DescribeEnvironmentMemberships_603086(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeEnvironmentMemberships_603085(path: JsonNode;
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
  var valid_603087 = query.getOrDefault("maxResults")
  valid_603087 = validateParameter(valid_603087, JString, required = false,
                                 default = nil)
  if valid_603087 != nil:
    section.add "maxResults", valid_603087
  var valid_603088 = query.getOrDefault("nextToken")
  valid_603088 = validateParameter(valid_603088, JString, required = false,
                                 default = nil)
  if valid_603088 != nil:
    section.add "nextToken", valid_603088
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603089 = header.getOrDefault("X-Amz-Date")
  valid_603089 = validateParameter(valid_603089, JString, required = false,
                                 default = nil)
  if valid_603089 != nil:
    section.add "X-Amz-Date", valid_603089
  var valid_603090 = header.getOrDefault("X-Amz-Security-Token")
  valid_603090 = validateParameter(valid_603090, JString, required = false,
                                 default = nil)
  if valid_603090 != nil:
    section.add "X-Amz-Security-Token", valid_603090
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603091 = header.getOrDefault("X-Amz-Target")
  valid_603091 = validateParameter(valid_603091, JString, required = true, default = newJString(
      "AWSCloud9WorkspaceManagementService.DescribeEnvironmentMemberships"))
  if valid_603091 != nil:
    section.add "X-Amz-Target", valid_603091
  var valid_603092 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603092 = validateParameter(valid_603092, JString, required = false,
                                 default = nil)
  if valid_603092 != nil:
    section.add "X-Amz-Content-Sha256", valid_603092
  var valid_603093 = header.getOrDefault("X-Amz-Algorithm")
  valid_603093 = validateParameter(valid_603093, JString, required = false,
                                 default = nil)
  if valid_603093 != nil:
    section.add "X-Amz-Algorithm", valid_603093
  var valid_603094 = header.getOrDefault("X-Amz-Signature")
  valid_603094 = validateParameter(valid_603094, JString, required = false,
                                 default = nil)
  if valid_603094 != nil:
    section.add "X-Amz-Signature", valid_603094
  var valid_603095 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603095 = validateParameter(valid_603095, JString, required = false,
                                 default = nil)
  if valid_603095 != nil:
    section.add "X-Amz-SignedHeaders", valid_603095
  var valid_603096 = header.getOrDefault("X-Amz-Credential")
  valid_603096 = validateParameter(valid_603096, JString, required = false,
                                 default = nil)
  if valid_603096 != nil:
    section.add "X-Amz-Credential", valid_603096
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603098: Call_DescribeEnvironmentMemberships_603084; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about environment members for an AWS Cloud9 development environment.
  ## 
  let valid = call_603098.validator(path, query, header, formData, body)
  let scheme = call_603098.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603098.url(scheme.get, call_603098.host, call_603098.base,
                         call_603098.route, valid.getOrDefault("path"))
  result = hook(call_603098, url, valid)

proc call*(call_603099: Call_DescribeEnvironmentMemberships_603084; body: JsonNode;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## describeEnvironmentMemberships
  ## Gets information about environment members for an AWS Cloud9 development environment.
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_603100 = newJObject()
  var body_603101 = newJObject()
  add(query_603100, "maxResults", newJString(maxResults))
  add(query_603100, "nextToken", newJString(nextToken))
  if body != nil:
    body_603101 = body
  result = call_603099.call(nil, query_603100, nil, nil, body_603101)

var describeEnvironmentMemberships* = Call_DescribeEnvironmentMemberships_603084(
    name: "describeEnvironmentMemberships", meth: HttpMethod.HttpPost,
    host: "cloud9.amazonaws.com", route: "/#X-Amz-Target=AWSCloud9WorkspaceManagementService.DescribeEnvironmentMemberships",
    validator: validate_DescribeEnvironmentMemberships_603085, base: "/",
    url: url_DescribeEnvironmentMemberships_603086,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEnvironmentStatus_603103 = ref object of OpenApiRestCall_602433
proc url_DescribeEnvironmentStatus_603105(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeEnvironmentStatus_603104(path: JsonNode; query: JsonNode;
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
  var valid_603106 = header.getOrDefault("X-Amz-Date")
  valid_603106 = validateParameter(valid_603106, JString, required = false,
                                 default = nil)
  if valid_603106 != nil:
    section.add "X-Amz-Date", valid_603106
  var valid_603107 = header.getOrDefault("X-Amz-Security-Token")
  valid_603107 = validateParameter(valid_603107, JString, required = false,
                                 default = nil)
  if valid_603107 != nil:
    section.add "X-Amz-Security-Token", valid_603107
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603108 = header.getOrDefault("X-Amz-Target")
  valid_603108 = validateParameter(valid_603108, JString, required = true, default = newJString(
      "AWSCloud9WorkspaceManagementService.DescribeEnvironmentStatus"))
  if valid_603108 != nil:
    section.add "X-Amz-Target", valid_603108
  var valid_603109 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603109 = validateParameter(valid_603109, JString, required = false,
                                 default = nil)
  if valid_603109 != nil:
    section.add "X-Amz-Content-Sha256", valid_603109
  var valid_603110 = header.getOrDefault("X-Amz-Algorithm")
  valid_603110 = validateParameter(valid_603110, JString, required = false,
                                 default = nil)
  if valid_603110 != nil:
    section.add "X-Amz-Algorithm", valid_603110
  var valid_603111 = header.getOrDefault("X-Amz-Signature")
  valid_603111 = validateParameter(valid_603111, JString, required = false,
                                 default = nil)
  if valid_603111 != nil:
    section.add "X-Amz-Signature", valid_603111
  var valid_603112 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603112 = validateParameter(valid_603112, JString, required = false,
                                 default = nil)
  if valid_603112 != nil:
    section.add "X-Amz-SignedHeaders", valid_603112
  var valid_603113 = header.getOrDefault("X-Amz-Credential")
  valid_603113 = validateParameter(valid_603113, JString, required = false,
                                 default = nil)
  if valid_603113 != nil:
    section.add "X-Amz-Credential", valid_603113
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603115: Call_DescribeEnvironmentStatus_603103; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets status information for an AWS Cloud9 development environment.
  ## 
  let valid = call_603115.validator(path, query, header, formData, body)
  let scheme = call_603115.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603115.url(scheme.get, call_603115.host, call_603115.base,
                         call_603115.route, valid.getOrDefault("path"))
  result = hook(call_603115, url, valid)

proc call*(call_603116: Call_DescribeEnvironmentStatus_603103; body: JsonNode): Recallable =
  ## describeEnvironmentStatus
  ## Gets status information for an AWS Cloud9 development environment.
  ##   body: JObject (required)
  var body_603117 = newJObject()
  if body != nil:
    body_603117 = body
  result = call_603116.call(nil, nil, nil, nil, body_603117)

var describeEnvironmentStatus* = Call_DescribeEnvironmentStatus_603103(
    name: "describeEnvironmentStatus", meth: HttpMethod.HttpPost,
    host: "cloud9.amazonaws.com", route: "/#X-Amz-Target=AWSCloud9WorkspaceManagementService.DescribeEnvironmentStatus",
    validator: validate_DescribeEnvironmentStatus_603104, base: "/",
    url: url_DescribeEnvironmentStatus_603105,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEnvironments_603118 = ref object of OpenApiRestCall_602433
proc url_DescribeEnvironments_603120(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeEnvironments_603119(path: JsonNode; query: JsonNode;
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
  var valid_603121 = header.getOrDefault("X-Amz-Date")
  valid_603121 = validateParameter(valid_603121, JString, required = false,
                                 default = nil)
  if valid_603121 != nil:
    section.add "X-Amz-Date", valid_603121
  var valid_603122 = header.getOrDefault("X-Amz-Security-Token")
  valid_603122 = validateParameter(valid_603122, JString, required = false,
                                 default = nil)
  if valid_603122 != nil:
    section.add "X-Amz-Security-Token", valid_603122
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603123 = header.getOrDefault("X-Amz-Target")
  valid_603123 = validateParameter(valid_603123, JString, required = true, default = newJString(
      "AWSCloud9WorkspaceManagementService.DescribeEnvironments"))
  if valid_603123 != nil:
    section.add "X-Amz-Target", valid_603123
  var valid_603124 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603124 = validateParameter(valid_603124, JString, required = false,
                                 default = nil)
  if valid_603124 != nil:
    section.add "X-Amz-Content-Sha256", valid_603124
  var valid_603125 = header.getOrDefault("X-Amz-Algorithm")
  valid_603125 = validateParameter(valid_603125, JString, required = false,
                                 default = nil)
  if valid_603125 != nil:
    section.add "X-Amz-Algorithm", valid_603125
  var valid_603126 = header.getOrDefault("X-Amz-Signature")
  valid_603126 = validateParameter(valid_603126, JString, required = false,
                                 default = nil)
  if valid_603126 != nil:
    section.add "X-Amz-Signature", valid_603126
  var valid_603127 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603127 = validateParameter(valid_603127, JString, required = false,
                                 default = nil)
  if valid_603127 != nil:
    section.add "X-Amz-SignedHeaders", valid_603127
  var valid_603128 = header.getOrDefault("X-Amz-Credential")
  valid_603128 = validateParameter(valid_603128, JString, required = false,
                                 default = nil)
  if valid_603128 != nil:
    section.add "X-Amz-Credential", valid_603128
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603130: Call_DescribeEnvironments_603118; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about AWS Cloud9 development environments.
  ## 
  let valid = call_603130.validator(path, query, header, formData, body)
  let scheme = call_603130.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603130.url(scheme.get, call_603130.host, call_603130.base,
                         call_603130.route, valid.getOrDefault("path"))
  result = hook(call_603130, url, valid)

proc call*(call_603131: Call_DescribeEnvironments_603118; body: JsonNode): Recallable =
  ## describeEnvironments
  ## Gets information about AWS Cloud9 development environments.
  ##   body: JObject (required)
  var body_603132 = newJObject()
  if body != nil:
    body_603132 = body
  result = call_603131.call(nil, nil, nil, nil, body_603132)

var describeEnvironments* = Call_DescribeEnvironments_603118(
    name: "describeEnvironments", meth: HttpMethod.HttpPost,
    host: "cloud9.amazonaws.com", route: "/#X-Amz-Target=AWSCloud9WorkspaceManagementService.DescribeEnvironments",
    validator: validate_DescribeEnvironments_603119, base: "/",
    url: url_DescribeEnvironments_603120, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListEnvironments_603133 = ref object of OpenApiRestCall_602433
proc url_ListEnvironments_603135(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListEnvironments_603134(path: JsonNode; query: JsonNode;
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
  var valid_603136 = query.getOrDefault("maxResults")
  valid_603136 = validateParameter(valid_603136, JString, required = false,
                                 default = nil)
  if valid_603136 != nil:
    section.add "maxResults", valid_603136
  var valid_603137 = query.getOrDefault("nextToken")
  valid_603137 = validateParameter(valid_603137, JString, required = false,
                                 default = nil)
  if valid_603137 != nil:
    section.add "nextToken", valid_603137
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603138 = header.getOrDefault("X-Amz-Date")
  valid_603138 = validateParameter(valid_603138, JString, required = false,
                                 default = nil)
  if valid_603138 != nil:
    section.add "X-Amz-Date", valid_603138
  var valid_603139 = header.getOrDefault("X-Amz-Security-Token")
  valid_603139 = validateParameter(valid_603139, JString, required = false,
                                 default = nil)
  if valid_603139 != nil:
    section.add "X-Amz-Security-Token", valid_603139
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603140 = header.getOrDefault("X-Amz-Target")
  valid_603140 = validateParameter(valid_603140, JString, required = true, default = newJString(
      "AWSCloud9WorkspaceManagementService.ListEnvironments"))
  if valid_603140 != nil:
    section.add "X-Amz-Target", valid_603140
  var valid_603141 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603141 = validateParameter(valid_603141, JString, required = false,
                                 default = nil)
  if valid_603141 != nil:
    section.add "X-Amz-Content-Sha256", valid_603141
  var valid_603142 = header.getOrDefault("X-Amz-Algorithm")
  valid_603142 = validateParameter(valid_603142, JString, required = false,
                                 default = nil)
  if valid_603142 != nil:
    section.add "X-Amz-Algorithm", valid_603142
  var valid_603143 = header.getOrDefault("X-Amz-Signature")
  valid_603143 = validateParameter(valid_603143, JString, required = false,
                                 default = nil)
  if valid_603143 != nil:
    section.add "X-Amz-Signature", valid_603143
  var valid_603144 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603144 = validateParameter(valid_603144, JString, required = false,
                                 default = nil)
  if valid_603144 != nil:
    section.add "X-Amz-SignedHeaders", valid_603144
  var valid_603145 = header.getOrDefault("X-Amz-Credential")
  valid_603145 = validateParameter(valid_603145, JString, required = false,
                                 default = nil)
  if valid_603145 != nil:
    section.add "X-Amz-Credential", valid_603145
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603147: Call_ListEnvironments_603133; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a list of AWS Cloud9 development environment identifiers.
  ## 
  let valid = call_603147.validator(path, query, header, formData, body)
  let scheme = call_603147.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603147.url(scheme.get, call_603147.host, call_603147.base,
                         call_603147.route, valid.getOrDefault("path"))
  result = hook(call_603147, url, valid)

proc call*(call_603148: Call_ListEnvironments_603133; body: JsonNode;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## listEnvironments
  ## Gets a list of AWS Cloud9 development environment identifiers.
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_603149 = newJObject()
  var body_603150 = newJObject()
  add(query_603149, "maxResults", newJString(maxResults))
  add(query_603149, "nextToken", newJString(nextToken))
  if body != nil:
    body_603150 = body
  result = call_603148.call(nil, query_603149, nil, nil, body_603150)

var listEnvironments* = Call_ListEnvironments_603133(name: "listEnvironments",
    meth: HttpMethod.HttpPost, host: "cloud9.amazonaws.com", route: "/#X-Amz-Target=AWSCloud9WorkspaceManagementService.ListEnvironments",
    validator: validate_ListEnvironments_603134, base: "/",
    url: url_ListEnvironments_603135, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateEnvironment_603151 = ref object of OpenApiRestCall_602433
proc url_UpdateEnvironment_603153(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateEnvironment_603152(path: JsonNode; query: JsonNode;
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
  var valid_603154 = header.getOrDefault("X-Amz-Date")
  valid_603154 = validateParameter(valid_603154, JString, required = false,
                                 default = nil)
  if valid_603154 != nil:
    section.add "X-Amz-Date", valid_603154
  var valid_603155 = header.getOrDefault("X-Amz-Security-Token")
  valid_603155 = validateParameter(valid_603155, JString, required = false,
                                 default = nil)
  if valid_603155 != nil:
    section.add "X-Amz-Security-Token", valid_603155
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603156 = header.getOrDefault("X-Amz-Target")
  valid_603156 = validateParameter(valid_603156, JString, required = true, default = newJString(
      "AWSCloud9WorkspaceManagementService.UpdateEnvironment"))
  if valid_603156 != nil:
    section.add "X-Amz-Target", valid_603156
  var valid_603157 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603157 = validateParameter(valid_603157, JString, required = false,
                                 default = nil)
  if valid_603157 != nil:
    section.add "X-Amz-Content-Sha256", valid_603157
  var valid_603158 = header.getOrDefault("X-Amz-Algorithm")
  valid_603158 = validateParameter(valid_603158, JString, required = false,
                                 default = nil)
  if valid_603158 != nil:
    section.add "X-Amz-Algorithm", valid_603158
  var valid_603159 = header.getOrDefault("X-Amz-Signature")
  valid_603159 = validateParameter(valid_603159, JString, required = false,
                                 default = nil)
  if valid_603159 != nil:
    section.add "X-Amz-Signature", valid_603159
  var valid_603160 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603160 = validateParameter(valid_603160, JString, required = false,
                                 default = nil)
  if valid_603160 != nil:
    section.add "X-Amz-SignedHeaders", valid_603160
  var valid_603161 = header.getOrDefault("X-Amz-Credential")
  valid_603161 = validateParameter(valid_603161, JString, required = false,
                                 default = nil)
  if valid_603161 != nil:
    section.add "X-Amz-Credential", valid_603161
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603163: Call_UpdateEnvironment_603151; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes the settings of an existing AWS Cloud9 development environment.
  ## 
  let valid = call_603163.validator(path, query, header, formData, body)
  let scheme = call_603163.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603163.url(scheme.get, call_603163.host, call_603163.base,
                         call_603163.route, valid.getOrDefault("path"))
  result = hook(call_603163, url, valid)

proc call*(call_603164: Call_UpdateEnvironment_603151; body: JsonNode): Recallable =
  ## updateEnvironment
  ## Changes the settings of an existing AWS Cloud9 development environment.
  ##   body: JObject (required)
  var body_603165 = newJObject()
  if body != nil:
    body_603165 = body
  result = call_603164.call(nil, nil, nil, nil, body_603165)

var updateEnvironment* = Call_UpdateEnvironment_603151(name: "updateEnvironment",
    meth: HttpMethod.HttpPost, host: "cloud9.amazonaws.com", route: "/#X-Amz-Target=AWSCloud9WorkspaceManagementService.UpdateEnvironment",
    validator: validate_UpdateEnvironment_603152, base: "/",
    url: url_UpdateEnvironment_603153, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateEnvironmentMembership_603166 = ref object of OpenApiRestCall_602433
proc url_UpdateEnvironmentMembership_603168(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateEnvironmentMembership_603167(path: JsonNode; query: JsonNode;
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
  var valid_603169 = header.getOrDefault("X-Amz-Date")
  valid_603169 = validateParameter(valid_603169, JString, required = false,
                                 default = nil)
  if valid_603169 != nil:
    section.add "X-Amz-Date", valid_603169
  var valid_603170 = header.getOrDefault("X-Amz-Security-Token")
  valid_603170 = validateParameter(valid_603170, JString, required = false,
                                 default = nil)
  if valid_603170 != nil:
    section.add "X-Amz-Security-Token", valid_603170
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603171 = header.getOrDefault("X-Amz-Target")
  valid_603171 = validateParameter(valid_603171, JString, required = true, default = newJString(
      "AWSCloud9WorkspaceManagementService.UpdateEnvironmentMembership"))
  if valid_603171 != nil:
    section.add "X-Amz-Target", valid_603171
  var valid_603172 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603172 = validateParameter(valid_603172, JString, required = false,
                                 default = nil)
  if valid_603172 != nil:
    section.add "X-Amz-Content-Sha256", valid_603172
  var valid_603173 = header.getOrDefault("X-Amz-Algorithm")
  valid_603173 = validateParameter(valid_603173, JString, required = false,
                                 default = nil)
  if valid_603173 != nil:
    section.add "X-Amz-Algorithm", valid_603173
  var valid_603174 = header.getOrDefault("X-Amz-Signature")
  valid_603174 = validateParameter(valid_603174, JString, required = false,
                                 default = nil)
  if valid_603174 != nil:
    section.add "X-Amz-Signature", valid_603174
  var valid_603175 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603175 = validateParameter(valid_603175, JString, required = false,
                                 default = nil)
  if valid_603175 != nil:
    section.add "X-Amz-SignedHeaders", valid_603175
  var valid_603176 = header.getOrDefault("X-Amz-Credential")
  valid_603176 = validateParameter(valid_603176, JString, required = false,
                                 default = nil)
  if valid_603176 != nil:
    section.add "X-Amz-Credential", valid_603176
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603178: Call_UpdateEnvironmentMembership_603166; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes the settings of an existing environment member for an AWS Cloud9 development environment.
  ## 
  let valid = call_603178.validator(path, query, header, formData, body)
  let scheme = call_603178.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603178.url(scheme.get, call_603178.host, call_603178.base,
                         call_603178.route, valid.getOrDefault("path"))
  result = hook(call_603178, url, valid)

proc call*(call_603179: Call_UpdateEnvironmentMembership_603166; body: JsonNode): Recallable =
  ## updateEnvironmentMembership
  ## Changes the settings of an existing environment member for an AWS Cloud9 development environment.
  ##   body: JObject (required)
  var body_603180 = newJObject()
  if body != nil:
    body_603180 = body
  result = call_603179.call(nil, nil, nil, nil, body_603180)

var updateEnvironmentMembership* = Call_UpdateEnvironmentMembership_603166(
    name: "updateEnvironmentMembership", meth: HttpMethod.HttpPost,
    host: "cloud9.amazonaws.com", route: "/#X-Amz-Target=AWSCloud9WorkspaceManagementService.UpdateEnvironmentMembership",
    validator: validate_UpdateEnvironmentMembership_603167, base: "/",
    url: url_UpdateEnvironmentMembership_603168,
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
  recall.headers.del "Host"
  recall.url = $url

method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, "")
  result.sign(input.getOrDefault("query"), SHA256)
