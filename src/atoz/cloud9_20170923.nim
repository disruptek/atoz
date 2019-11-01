
import
  json, options, hashes, uri, tables, rest, os, uri, strutils, httpcore, sigv4

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
              path: JsonNode; query: JsonNode): Uri

  OpenApiRestCall_591364 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_591364](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_591364): Option[Scheme] {.used.} =
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
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_CreateEnvironmentEC2_591703 = ref object of OpenApiRestCall_591364
proc url_CreateEnvironmentEC2_591705(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateEnvironmentEC2_591704(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591830 = header.getOrDefault("X-Amz-Target")
  valid_591830 = validateParameter(valid_591830, JString, required = true, default = newJString(
      "AWSCloud9WorkspaceManagementService.CreateEnvironmentEC2"))
  if valid_591830 != nil:
    section.add "X-Amz-Target", valid_591830
  var valid_591831 = header.getOrDefault("X-Amz-Signature")
  valid_591831 = validateParameter(valid_591831, JString, required = false,
                                 default = nil)
  if valid_591831 != nil:
    section.add "X-Amz-Signature", valid_591831
  var valid_591832 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591832 = validateParameter(valid_591832, JString, required = false,
                                 default = nil)
  if valid_591832 != nil:
    section.add "X-Amz-Content-Sha256", valid_591832
  var valid_591833 = header.getOrDefault("X-Amz-Date")
  valid_591833 = validateParameter(valid_591833, JString, required = false,
                                 default = nil)
  if valid_591833 != nil:
    section.add "X-Amz-Date", valid_591833
  var valid_591834 = header.getOrDefault("X-Amz-Credential")
  valid_591834 = validateParameter(valid_591834, JString, required = false,
                                 default = nil)
  if valid_591834 != nil:
    section.add "X-Amz-Credential", valid_591834
  var valid_591835 = header.getOrDefault("X-Amz-Security-Token")
  valid_591835 = validateParameter(valid_591835, JString, required = false,
                                 default = nil)
  if valid_591835 != nil:
    section.add "X-Amz-Security-Token", valid_591835
  var valid_591836 = header.getOrDefault("X-Amz-Algorithm")
  valid_591836 = validateParameter(valid_591836, JString, required = false,
                                 default = nil)
  if valid_591836 != nil:
    section.add "X-Amz-Algorithm", valid_591836
  var valid_591837 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591837 = validateParameter(valid_591837, JString, required = false,
                                 default = nil)
  if valid_591837 != nil:
    section.add "X-Amz-SignedHeaders", valid_591837
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591861: Call_CreateEnvironmentEC2_591703; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an AWS Cloud9 development environment, launches an Amazon Elastic Compute Cloud (Amazon EC2) instance, and then connects from the instance to the environment.
  ## 
  let valid = call_591861.validator(path, query, header, formData, body)
  let scheme = call_591861.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591861.url(scheme.get, call_591861.host, call_591861.base,
                         call_591861.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591861, url, valid)

proc call*(call_591932: Call_CreateEnvironmentEC2_591703; body: JsonNode): Recallable =
  ## createEnvironmentEC2
  ## Creates an AWS Cloud9 development environment, launches an Amazon Elastic Compute Cloud (Amazon EC2) instance, and then connects from the instance to the environment.
  ##   body: JObject (required)
  var body_591933 = newJObject()
  if body != nil:
    body_591933 = body
  result = call_591932.call(nil, nil, nil, nil, body_591933)

var createEnvironmentEC2* = Call_CreateEnvironmentEC2_591703(
    name: "createEnvironmentEC2", meth: HttpMethod.HttpPost,
    host: "cloud9.amazonaws.com", route: "/#X-Amz-Target=AWSCloud9WorkspaceManagementService.CreateEnvironmentEC2",
    validator: validate_CreateEnvironmentEC2_591704, base: "/",
    url: url_CreateEnvironmentEC2_591705, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateEnvironmentMembership_591972 = ref object of OpenApiRestCall_591364
proc url_CreateEnvironmentMembership_591974(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateEnvironmentMembership_591973(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591975 = header.getOrDefault("X-Amz-Target")
  valid_591975 = validateParameter(valid_591975, JString, required = true, default = newJString(
      "AWSCloud9WorkspaceManagementService.CreateEnvironmentMembership"))
  if valid_591975 != nil:
    section.add "X-Amz-Target", valid_591975
  var valid_591976 = header.getOrDefault("X-Amz-Signature")
  valid_591976 = validateParameter(valid_591976, JString, required = false,
                                 default = nil)
  if valid_591976 != nil:
    section.add "X-Amz-Signature", valid_591976
  var valid_591977 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591977 = validateParameter(valid_591977, JString, required = false,
                                 default = nil)
  if valid_591977 != nil:
    section.add "X-Amz-Content-Sha256", valid_591977
  var valid_591978 = header.getOrDefault("X-Amz-Date")
  valid_591978 = validateParameter(valid_591978, JString, required = false,
                                 default = nil)
  if valid_591978 != nil:
    section.add "X-Amz-Date", valid_591978
  var valid_591979 = header.getOrDefault("X-Amz-Credential")
  valid_591979 = validateParameter(valid_591979, JString, required = false,
                                 default = nil)
  if valid_591979 != nil:
    section.add "X-Amz-Credential", valid_591979
  var valid_591980 = header.getOrDefault("X-Amz-Security-Token")
  valid_591980 = validateParameter(valid_591980, JString, required = false,
                                 default = nil)
  if valid_591980 != nil:
    section.add "X-Amz-Security-Token", valid_591980
  var valid_591981 = header.getOrDefault("X-Amz-Algorithm")
  valid_591981 = validateParameter(valid_591981, JString, required = false,
                                 default = nil)
  if valid_591981 != nil:
    section.add "X-Amz-Algorithm", valid_591981
  var valid_591982 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591982 = validateParameter(valid_591982, JString, required = false,
                                 default = nil)
  if valid_591982 != nil:
    section.add "X-Amz-SignedHeaders", valid_591982
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591984: Call_CreateEnvironmentMembership_591972; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds an environment member to an AWS Cloud9 development environment.
  ## 
  let valid = call_591984.validator(path, query, header, formData, body)
  let scheme = call_591984.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591984.url(scheme.get, call_591984.host, call_591984.base,
                         call_591984.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591984, url, valid)

proc call*(call_591985: Call_CreateEnvironmentMembership_591972; body: JsonNode): Recallable =
  ## createEnvironmentMembership
  ## Adds an environment member to an AWS Cloud9 development environment.
  ##   body: JObject (required)
  var body_591986 = newJObject()
  if body != nil:
    body_591986 = body
  result = call_591985.call(nil, nil, nil, nil, body_591986)

var createEnvironmentMembership* = Call_CreateEnvironmentMembership_591972(
    name: "createEnvironmentMembership", meth: HttpMethod.HttpPost,
    host: "cloud9.amazonaws.com", route: "/#X-Amz-Target=AWSCloud9WorkspaceManagementService.CreateEnvironmentMembership",
    validator: validate_CreateEnvironmentMembership_591973, base: "/",
    url: url_CreateEnvironmentMembership_591974,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteEnvironment_591987 = ref object of OpenApiRestCall_591364
proc url_DeleteEnvironment_591989(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteEnvironment_591988(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591990 = header.getOrDefault("X-Amz-Target")
  valid_591990 = validateParameter(valid_591990, JString, required = true, default = newJString(
      "AWSCloud9WorkspaceManagementService.DeleteEnvironment"))
  if valid_591990 != nil:
    section.add "X-Amz-Target", valid_591990
  var valid_591991 = header.getOrDefault("X-Amz-Signature")
  valid_591991 = validateParameter(valid_591991, JString, required = false,
                                 default = nil)
  if valid_591991 != nil:
    section.add "X-Amz-Signature", valid_591991
  var valid_591992 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591992 = validateParameter(valid_591992, JString, required = false,
                                 default = nil)
  if valid_591992 != nil:
    section.add "X-Amz-Content-Sha256", valid_591992
  var valid_591993 = header.getOrDefault("X-Amz-Date")
  valid_591993 = validateParameter(valid_591993, JString, required = false,
                                 default = nil)
  if valid_591993 != nil:
    section.add "X-Amz-Date", valid_591993
  var valid_591994 = header.getOrDefault("X-Amz-Credential")
  valid_591994 = validateParameter(valid_591994, JString, required = false,
                                 default = nil)
  if valid_591994 != nil:
    section.add "X-Amz-Credential", valid_591994
  var valid_591995 = header.getOrDefault("X-Amz-Security-Token")
  valid_591995 = validateParameter(valid_591995, JString, required = false,
                                 default = nil)
  if valid_591995 != nil:
    section.add "X-Amz-Security-Token", valid_591995
  var valid_591996 = header.getOrDefault("X-Amz-Algorithm")
  valid_591996 = validateParameter(valid_591996, JString, required = false,
                                 default = nil)
  if valid_591996 != nil:
    section.add "X-Amz-Algorithm", valid_591996
  var valid_591997 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591997 = validateParameter(valid_591997, JString, required = false,
                                 default = nil)
  if valid_591997 != nil:
    section.add "X-Amz-SignedHeaders", valid_591997
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591999: Call_DeleteEnvironment_591987; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an AWS Cloud9 development environment. If an Amazon EC2 instance is connected to the environment, also terminates the instance.
  ## 
  let valid = call_591999.validator(path, query, header, formData, body)
  let scheme = call_591999.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591999.url(scheme.get, call_591999.host, call_591999.base,
                         call_591999.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591999, url, valid)

proc call*(call_592000: Call_DeleteEnvironment_591987; body: JsonNode): Recallable =
  ## deleteEnvironment
  ## Deletes an AWS Cloud9 development environment. If an Amazon EC2 instance is connected to the environment, also terminates the instance.
  ##   body: JObject (required)
  var body_592001 = newJObject()
  if body != nil:
    body_592001 = body
  result = call_592000.call(nil, nil, nil, nil, body_592001)

var deleteEnvironment* = Call_DeleteEnvironment_591987(name: "deleteEnvironment",
    meth: HttpMethod.HttpPost, host: "cloud9.amazonaws.com", route: "/#X-Amz-Target=AWSCloud9WorkspaceManagementService.DeleteEnvironment",
    validator: validate_DeleteEnvironment_591988, base: "/",
    url: url_DeleteEnvironment_591989, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteEnvironmentMembership_592002 = ref object of OpenApiRestCall_591364
proc url_DeleteEnvironmentMembership_592004(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteEnvironmentMembership_592003(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_592005 = header.getOrDefault("X-Amz-Target")
  valid_592005 = validateParameter(valid_592005, JString, required = true, default = newJString(
      "AWSCloud9WorkspaceManagementService.DeleteEnvironmentMembership"))
  if valid_592005 != nil:
    section.add "X-Amz-Target", valid_592005
  var valid_592006 = header.getOrDefault("X-Amz-Signature")
  valid_592006 = validateParameter(valid_592006, JString, required = false,
                                 default = nil)
  if valid_592006 != nil:
    section.add "X-Amz-Signature", valid_592006
  var valid_592007 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592007 = validateParameter(valid_592007, JString, required = false,
                                 default = nil)
  if valid_592007 != nil:
    section.add "X-Amz-Content-Sha256", valid_592007
  var valid_592008 = header.getOrDefault("X-Amz-Date")
  valid_592008 = validateParameter(valid_592008, JString, required = false,
                                 default = nil)
  if valid_592008 != nil:
    section.add "X-Amz-Date", valid_592008
  var valid_592009 = header.getOrDefault("X-Amz-Credential")
  valid_592009 = validateParameter(valid_592009, JString, required = false,
                                 default = nil)
  if valid_592009 != nil:
    section.add "X-Amz-Credential", valid_592009
  var valid_592010 = header.getOrDefault("X-Amz-Security-Token")
  valid_592010 = validateParameter(valid_592010, JString, required = false,
                                 default = nil)
  if valid_592010 != nil:
    section.add "X-Amz-Security-Token", valid_592010
  var valid_592011 = header.getOrDefault("X-Amz-Algorithm")
  valid_592011 = validateParameter(valid_592011, JString, required = false,
                                 default = nil)
  if valid_592011 != nil:
    section.add "X-Amz-Algorithm", valid_592011
  var valid_592012 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592012 = validateParameter(valid_592012, JString, required = false,
                                 default = nil)
  if valid_592012 != nil:
    section.add "X-Amz-SignedHeaders", valid_592012
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592014: Call_DeleteEnvironmentMembership_592002; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an environment member from an AWS Cloud9 development environment.
  ## 
  let valid = call_592014.validator(path, query, header, formData, body)
  let scheme = call_592014.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592014.url(scheme.get, call_592014.host, call_592014.base,
                         call_592014.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592014, url, valid)

proc call*(call_592015: Call_DeleteEnvironmentMembership_592002; body: JsonNode): Recallable =
  ## deleteEnvironmentMembership
  ## Deletes an environment member from an AWS Cloud9 development environment.
  ##   body: JObject (required)
  var body_592016 = newJObject()
  if body != nil:
    body_592016 = body
  result = call_592015.call(nil, nil, nil, nil, body_592016)

var deleteEnvironmentMembership* = Call_DeleteEnvironmentMembership_592002(
    name: "deleteEnvironmentMembership", meth: HttpMethod.HttpPost,
    host: "cloud9.amazonaws.com", route: "/#X-Amz-Target=AWSCloud9WorkspaceManagementService.DeleteEnvironmentMembership",
    validator: validate_DeleteEnvironmentMembership_592003, base: "/",
    url: url_DeleteEnvironmentMembership_592004,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEnvironmentMemberships_592017 = ref object of OpenApiRestCall_591364
proc url_DescribeEnvironmentMemberships_592019(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeEnvironmentMemberships_592018(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets information about environment members for an AWS Cloud9 development environment.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Pagination token
  ##   maxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_592020 = query.getOrDefault("nextToken")
  valid_592020 = validateParameter(valid_592020, JString, required = false,
                                 default = nil)
  if valid_592020 != nil:
    section.add "nextToken", valid_592020
  var valid_592021 = query.getOrDefault("maxResults")
  valid_592021 = validateParameter(valid_592021, JString, required = false,
                                 default = nil)
  if valid_592021 != nil:
    section.add "maxResults", valid_592021
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_592022 = header.getOrDefault("X-Amz-Target")
  valid_592022 = validateParameter(valid_592022, JString, required = true, default = newJString(
      "AWSCloud9WorkspaceManagementService.DescribeEnvironmentMemberships"))
  if valid_592022 != nil:
    section.add "X-Amz-Target", valid_592022
  var valid_592023 = header.getOrDefault("X-Amz-Signature")
  valid_592023 = validateParameter(valid_592023, JString, required = false,
                                 default = nil)
  if valid_592023 != nil:
    section.add "X-Amz-Signature", valid_592023
  var valid_592024 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592024 = validateParameter(valid_592024, JString, required = false,
                                 default = nil)
  if valid_592024 != nil:
    section.add "X-Amz-Content-Sha256", valid_592024
  var valid_592025 = header.getOrDefault("X-Amz-Date")
  valid_592025 = validateParameter(valid_592025, JString, required = false,
                                 default = nil)
  if valid_592025 != nil:
    section.add "X-Amz-Date", valid_592025
  var valid_592026 = header.getOrDefault("X-Amz-Credential")
  valid_592026 = validateParameter(valid_592026, JString, required = false,
                                 default = nil)
  if valid_592026 != nil:
    section.add "X-Amz-Credential", valid_592026
  var valid_592027 = header.getOrDefault("X-Amz-Security-Token")
  valid_592027 = validateParameter(valid_592027, JString, required = false,
                                 default = nil)
  if valid_592027 != nil:
    section.add "X-Amz-Security-Token", valid_592027
  var valid_592028 = header.getOrDefault("X-Amz-Algorithm")
  valid_592028 = validateParameter(valid_592028, JString, required = false,
                                 default = nil)
  if valid_592028 != nil:
    section.add "X-Amz-Algorithm", valid_592028
  var valid_592029 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592029 = validateParameter(valid_592029, JString, required = false,
                                 default = nil)
  if valid_592029 != nil:
    section.add "X-Amz-SignedHeaders", valid_592029
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592031: Call_DescribeEnvironmentMemberships_592017; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about environment members for an AWS Cloud9 development environment.
  ## 
  let valid = call_592031.validator(path, query, header, formData, body)
  let scheme = call_592031.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592031.url(scheme.get, call_592031.host, call_592031.base,
                         call_592031.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592031, url, valid)

proc call*(call_592032: Call_DescribeEnvironmentMemberships_592017; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## describeEnvironmentMemberships
  ## Gets information about environment members for an AWS Cloud9 development environment.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_592033 = newJObject()
  var body_592034 = newJObject()
  add(query_592033, "nextToken", newJString(nextToken))
  if body != nil:
    body_592034 = body
  add(query_592033, "maxResults", newJString(maxResults))
  result = call_592032.call(nil, query_592033, nil, nil, body_592034)

var describeEnvironmentMemberships* = Call_DescribeEnvironmentMemberships_592017(
    name: "describeEnvironmentMemberships", meth: HttpMethod.HttpPost,
    host: "cloud9.amazonaws.com", route: "/#X-Amz-Target=AWSCloud9WorkspaceManagementService.DescribeEnvironmentMemberships",
    validator: validate_DescribeEnvironmentMemberships_592018, base: "/",
    url: url_DescribeEnvironmentMemberships_592019,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEnvironmentStatus_592036 = ref object of OpenApiRestCall_591364
proc url_DescribeEnvironmentStatus_592038(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeEnvironmentStatus_592037(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_592039 = header.getOrDefault("X-Amz-Target")
  valid_592039 = validateParameter(valid_592039, JString, required = true, default = newJString(
      "AWSCloud9WorkspaceManagementService.DescribeEnvironmentStatus"))
  if valid_592039 != nil:
    section.add "X-Amz-Target", valid_592039
  var valid_592040 = header.getOrDefault("X-Amz-Signature")
  valid_592040 = validateParameter(valid_592040, JString, required = false,
                                 default = nil)
  if valid_592040 != nil:
    section.add "X-Amz-Signature", valid_592040
  var valid_592041 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592041 = validateParameter(valid_592041, JString, required = false,
                                 default = nil)
  if valid_592041 != nil:
    section.add "X-Amz-Content-Sha256", valid_592041
  var valid_592042 = header.getOrDefault("X-Amz-Date")
  valid_592042 = validateParameter(valid_592042, JString, required = false,
                                 default = nil)
  if valid_592042 != nil:
    section.add "X-Amz-Date", valid_592042
  var valid_592043 = header.getOrDefault("X-Amz-Credential")
  valid_592043 = validateParameter(valid_592043, JString, required = false,
                                 default = nil)
  if valid_592043 != nil:
    section.add "X-Amz-Credential", valid_592043
  var valid_592044 = header.getOrDefault("X-Amz-Security-Token")
  valid_592044 = validateParameter(valid_592044, JString, required = false,
                                 default = nil)
  if valid_592044 != nil:
    section.add "X-Amz-Security-Token", valid_592044
  var valid_592045 = header.getOrDefault("X-Amz-Algorithm")
  valid_592045 = validateParameter(valid_592045, JString, required = false,
                                 default = nil)
  if valid_592045 != nil:
    section.add "X-Amz-Algorithm", valid_592045
  var valid_592046 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592046 = validateParameter(valid_592046, JString, required = false,
                                 default = nil)
  if valid_592046 != nil:
    section.add "X-Amz-SignedHeaders", valid_592046
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592048: Call_DescribeEnvironmentStatus_592036; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets status information for an AWS Cloud9 development environment.
  ## 
  let valid = call_592048.validator(path, query, header, formData, body)
  let scheme = call_592048.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592048.url(scheme.get, call_592048.host, call_592048.base,
                         call_592048.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592048, url, valid)

proc call*(call_592049: Call_DescribeEnvironmentStatus_592036; body: JsonNode): Recallable =
  ## describeEnvironmentStatus
  ## Gets status information for an AWS Cloud9 development environment.
  ##   body: JObject (required)
  var body_592050 = newJObject()
  if body != nil:
    body_592050 = body
  result = call_592049.call(nil, nil, nil, nil, body_592050)

var describeEnvironmentStatus* = Call_DescribeEnvironmentStatus_592036(
    name: "describeEnvironmentStatus", meth: HttpMethod.HttpPost,
    host: "cloud9.amazonaws.com", route: "/#X-Amz-Target=AWSCloud9WorkspaceManagementService.DescribeEnvironmentStatus",
    validator: validate_DescribeEnvironmentStatus_592037, base: "/",
    url: url_DescribeEnvironmentStatus_592038,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEnvironments_592051 = ref object of OpenApiRestCall_591364
proc url_DescribeEnvironments_592053(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeEnvironments_592052(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_592054 = header.getOrDefault("X-Amz-Target")
  valid_592054 = validateParameter(valid_592054, JString, required = true, default = newJString(
      "AWSCloud9WorkspaceManagementService.DescribeEnvironments"))
  if valid_592054 != nil:
    section.add "X-Amz-Target", valid_592054
  var valid_592055 = header.getOrDefault("X-Amz-Signature")
  valid_592055 = validateParameter(valid_592055, JString, required = false,
                                 default = nil)
  if valid_592055 != nil:
    section.add "X-Amz-Signature", valid_592055
  var valid_592056 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592056 = validateParameter(valid_592056, JString, required = false,
                                 default = nil)
  if valid_592056 != nil:
    section.add "X-Amz-Content-Sha256", valid_592056
  var valid_592057 = header.getOrDefault("X-Amz-Date")
  valid_592057 = validateParameter(valid_592057, JString, required = false,
                                 default = nil)
  if valid_592057 != nil:
    section.add "X-Amz-Date", valid_592057
  var valid_592058 = header.getOrDefault("X-Amz-Credential")
  valid_592058 = validateParameter(valid_592058, JString, required = false,
                                 default = nil)
  if valid_592058 != nil:
    section.add "X-Amz-Credential", valid_592058
  var valid_592059 = header.getOrDefault("X-Amz-Security-Token")
  valid_592059 = validateParameter(valid_592059, JString, required = false,
                                 default = nil)
  if valid_592059 != nil:
    section.add "X-Amz-Security-Token", valid_592059
  var valid_592060 = header.getOrDefault("X-Amz-Algorithm")
  valid_592060 = validateParameter(valid_592060, JString, required = false,
                                 default = nil)
  if valid_592060 != nil:
    section.add "X-Amz-Algorithm", valid_592060
  var valid_592061 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592061 = validateParameter(valid_592061, JString, required = false,
                                 default = nil)
  if valid_592061 != nil:
    section.add "X-Amz-SignedHeaders", valid_592061
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592063: Call_DescribeEnvironments_592051; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about AWS Cloud9 development environments.
  ## 
  let valid = call_592063.validator(path, query, header, formData, body)
  let scheme = call_592063.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592063.url(scheme.get, call_592063.host, call_592063.base,
                         call_592063.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592063, url, valid)

proc call*(call_592064: Call_DescribeEnvironments_592051; body: JsonNode): Recallable =
  ## describeEnvironments
  ## Gets information about AWS Cloud9 development environments.
  ##   body: JObject (required)
  var body_592065 = newJObject()
  if body != nil:
    body_592065 = body
  result = call_592064.call(nil, nil, nil, nil, body_592065)

var describeEnvironments* = Call_DescribeEnvironments_592051(
    name: "describeEnvironments", meth: HttpMethod.HttpPost,
    host: "cloud9.amazonaws.com", route: "/#X-Amz-Target=AWSCloud9WorkspaceManagementService.DescribeEnvironments",
    validator: validate_DescribeEnvironments_592052, base: "/",
    url: url_DescribeEnvironments_592053, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListEnvironments_592066 = ref object of OpenApiRestCall_591364
proc url_ListEnvironments_592068(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListEnvironments_592067(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Gets a list of AWS Cloud9 development environment identifiers.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Pagination token
  ##   maxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_592069 = query.getOrDefault("nextToken")
  valid_592069 = validateParameter(valid_592069, JString, required = false,
                                 default = nil)
  if valid_592069 != nil:
    section.add "nextToken", valid_592069
  var valid_592070 = query.getOrDefault("maxResults")
  valid_592070 = validateParameter(valid_592070, JString, required = false,
                                 default = nil)
  if valid_592070 != nil:
    section.add "maxResults", valid_592070
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_592071 = header.getOrDefault("X-Amz-Target")
  valid_592071 = validateParameter(valid_592071, JString, required = true, default = newJString(
      "AWSCloud9WorkspaceManagementService.ListEnvironments"))
  if valid_592071 != nil:
    section.add "X-Amz-Target", valid_592071
  var valid_592072 = header.getOrDefault("X-Amz-Signature")
  valid_592072 = validateParameter(valid_592072, JString, required = false,
                                 default = nil)
  if valid_592072 != nil:
    section.add "X-Amz-Signature", valid_592072
  var valid_592073 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592073 = validateParameter(valid_592073, JString, required = false,
                                 default = nil)
  if valid_592073 != nil:
    section.add "X-Amz-Content-Sha256", valid_592073
  var valid_592074 = header.getOrDefault("X-Amz-Date")
  valid_592074 = validateParameter(valid_592074, JString, required = false,
                                 default = nil)
  if valid_592074 != nil:
    section.add "X-Amz-Date", valid_592074
  var valid_592075 = header.getOrDefault("X-Amz-Credential")
  valid_592075 = validateParameter(valid_592075, JString, required = false,
                                 default = nil)
  if valid_592075 != nil:
    section.add "X-Amz-Credential", valid_592075
  var valid_592076 = header.getOrDefault("X-Amz-Security-Token")
  valid_592076 = validateParameter(valid_592076, JString, required = false,
                                 default = nil)
  if valid_592076 != nil:
    section.add "X-Amz-Security-Token", valid_592076
  var valid_592077 = header.getOrDefault("X-Amz-Algorithm")
  valid_592077 = validateParameter(valid_592077, JString, required = false,
                                 default = nil)
  if valid_592077 != nil:
    section.add "X-Amz-Algorithm", valid_592077
  var valid_592078 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592078 = validateParameter(valid_592078, JString, required = false,
                                 default = nil)
  if valid_592078 != nil:
    section.add "X-Amz-SignedHeaders", valid_592078
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592080: Call_ListEnvironments_592066; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a list of AWS Cloud9 development environment identifiers.
  ## 
  let valid = call_592080.validator(path, query, header, formData, body)
  let scheme = call_592080.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592080.url(scheme.get, call_592080.host, call_592080.base,
                         call_592080.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592080, url, valid)

proc call*(call_592081: Call_ListEnvironments_592066; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listEnvironments
  ## Gets a list of AWS Cloud9 development environment identifiers.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_592082 = newJObject()
  var body_592083 = newJObject()
  add(query_592082, "nextToken", newJString(nextToken))
  if body != nil:
    body_592083 = body
  add(query_592082, "maxResults", newJString(maxResults))
  result = call_592081.call(nil, query_592082, nil, nil, body_592083)

var listEnvironments* = Call_ListEnvironments_592066(name: "listEnvironments",
    meth: HttpMethod.HttpPost, host: "cloud9.amazonaws.com", route: "/#X-Amz-Target=AWSCloud9WorkspaceManagementService.ListEnvironments",
    validator: validate_ListEnvironments_592067, base: "/",
    url: url_ListEnvironments_592068, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateEnvironment_592084 = ref object of OpenApiRestCall_591364
proc url_UpdateEnvironment_592086(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateEnvironment_592085(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_592087 = header.getOrDefault("X-Amz-Target")
  valid_592087 = validateParameter(valid_592087, JString, required = true, default = newJString(
      "AWSCloud9WorkspaceManagementService.UpdateEnvironment"))
  if valid_592087 != nil:
    section.add "X-Amz-Target", valid_592087
  var valid_592088 = header.getOrDefault("X-Amz-Signature")
  valid_592088 = validateParameter(valid_592088, JString, required = false,
                                 default = nil)
  if valid_592088 != nil:
    section.add "X-Amz-Signature", valid_592088
  var valid_592089 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592089 = validateParameter(valid_592089, JString, required = false,
                                 default = nil)
  if valid_592089 != nil:
    section.add "X-Amz-Content-Sha256", valid_592089
  var valid_592090 = header.getOrDefault("X-Amz-Date")
  valid_592090 = validateParameter(valid_592090, JString, required = false,
                                 default = nil)
  if valid_592090 != nil:
    section.add "X-Amz-Date", valid_592090
  var valid_592091 = header.getOrDefault("X-Amz-Credential")
  valid_592091 = validateParameter(valid_592091, JString, required = false,
                                 default = nil)
  if valid_592091 != nil:
    section.add "X-Amz-Credential", valid_592091
  var valid_592092 = header.getOrDefault("X-Amz-Security-Token")
  valid_592092 = validateParameter(valid_592092, JString, required = false,
                                 default = nil)
  if valid_592092 != nil:
    section.add "X-Amz-Security-Token", valid_592092
  var valid_592093 = header.getOrDefault("X-Amz-Algorithm")
  valid_592093 = validateParameter(valid_592093, JString, required = false,
                                 default = nil)
  if valid_592093 != nil:
    section.add "X-Amz-Algorithm", valid_592093
  var valid_592094 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592094 = validateParameter(valid_592094, JString, required = false,
                                 default = nil)
  if valid_592094 != nil:
    section.add "X-Amz-SignedHeaders", valid_592094
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592096: Call_UpdateEnvironment_592084; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes the settings of an existing AWS Cloud9 development environment.
  ## 
  let valid = call_592096.validator(path, query, header, formData, body)
  let scheme = call_592096.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592096.url(scheme.get, call_592096.host, call_592096.base,
                         call_592096.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592096, url, valid)

proc call*(call_592097: Call_UpdateEnvironment_592084; body: JsonNode): Recallable =
  ## updateEnvironment
  ## Changes the settings of an existing AWS Cloud9 development environment.
  ##   body: JObject (required)
  var body_592098 = newJObject()
  if body != nil:
    body_592098 = body
  result = call_592097.call(nil, nil, nil, nil, body_592098)

var updateEnvironment* = Call_UpdateEnvironment_592084(name: "updateEnvironment",
    meth: HttpMethod.HttpPost, host: "cloud9.amazonaws.com", route: "/#X-Amz-Target=AWSCloud9WorkspaceManagementService.UpdateEnvironment",
    validator: validate_UpdateEnvironment_592085, base: "/",
    url: url_UpdateEnvironment_592086, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateEnvironmentMembership_592099 = ref object of OpenApiRestCall_591364
proc url_UpdateEnvironmentMembership_592101(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateEnvironmentMembership_592100(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_592102 = header.getOrDefault("X-Amz-Target")
  valid_592102 = validateParameter(valid_592102, JString, required = true, default = newJString(
      "AWSCloud9WorkspaceManagementService.UpdateEnvironmentMembership"))
  if valid_592102 != nil:
    section.add "X-Amz-Target", valid_592102
  var valid_592103 = header.getOrDefault("X-Amz-Signature")
  valid_592103 = validateParameter(valid_592103, JString, required = false,
                                 default = nil)
  if valid_592103 != nil:
    section.add "X-Amz-Signature", valid_592103
  var valid_592104 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592104 = validateParameter(valid_592104, JString, required = false,
                                 default = nil)
  if valid_592104 != nil:
    section.add "X-Amz-Content-Sha256", valid_592104
  var valid_592105 = header.getOrDefault("X-Amz-Date")
  valid_592105 = validateParameter(valid_592105, JString, required = false,
                                 default = nil)
  if valid_592105 != nil:
    section.add "X-Amz-Date", valid_592105
  var valid_592106 = header.getOrDefault("X-Amz-Credential")
  valid_592106 = validateParameter(valid_592106, JString, required = false,
                                 default = nil)
  if valid_592106 != nil:
    section.add "X-Amz-Credential", valid_592106
  var valid_592107 = header.getOrDefault("X-Amz-Security-Token")
  valid_592107 = validateParameter(valid_592107, JString, required = false,
                                 default = nil)
  if valid_592107 != nil:
    section.add "X-Amz-Security-Token", valid_592107
  var valid_592108 = header.getOrDefault("X-Amz-Algorithm")
  valid_592108 = validateParameter(valid_592108, JString, required = false,
                                 default = nil)
  if valid_592108 != nil:
    section.add "X-Amz-Algorithm", valid_592108
  var valid_592109 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592109 = validateParameter(valid_592109, JString, required = false,
                                 default = nil)
  if valid_592109 != nil:
    section.add "X-Amz-SignedHeaders", valid_592109
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592111: Call_UpdateEnvironmentMembership_592099; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes the settings of an existing environment member for an AWS Cloud9 development environment.
  ## 
  let valid = call_592111.validator(path, query, header, formData, body)
  let scheme = call_592111.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592111.url(scheme.get, call_592111.host, call_592111.base,
                         call_592111.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592111, url, valid)

proc call*(call_592112: Call_UpdateEnvironmentMembership_592099; body: JsonNode): Recallable =
  ## updateEnvironmentMembership
  ## Changes the settings of an existing environment member for an AWS Cloud9 development environment.
  ##   body: JObject (required)
  var body_592113 = newJObject()
  if body != nil:
    body_592113 = body
  result = call_592112.call(nil, nil, nil, nil, body_592113)

var updateEnvironmentMembership* = Call_UpdateEnvironmentMembership_592099(
    name: "updateEnvironmentMembership", meth: HttpMethod.HttpPost,
    host: "cloud9.amazonaws.com", route: "/#X-Amz-Target=AWSCloud9WorkspaceManagementService.UpdateEnvironmentMembership",
    validator: validate_UpdateEnvironmentMembership_592100, base: "/",
    url: url_UpdateEnvironmentMembership_592101,
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

method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, input.getOrDefault("body").getStr)
  result.sign(input.getOrDefault("query"), SHA256)
