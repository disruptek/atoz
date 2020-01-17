
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

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

  OpenApiRestCall_605589 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_605589](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_605589): Option[Scheme] {.used.} =
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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_CreateEnvironmentEC2_605927 = ref object of OpenApiRestCall_605589
proc url_CreateEnvironmentEC2_605929(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateEnvironmentEC2_605928(path: JsonNode; query: JsonNode;
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
  var valid_606054 = header.getOrDefault("X-Amz-Target")
  valid_606054 = validateParameter(valid_606054, JString, required = true, default = newJString(
      "AWSCloud9WorkspaceManagementService.CreateEnvironmentEC2"))
  if valid_606054 != nil:
    section.add "X-Amz-Target", valid_606054
  var valid_606055 = header.getOrDefault("X-Amz-Signature")
  valid_606055 = validateParameter(valid_606055, JString, required = false,
                                 default = nil)
  if valid_606055 != nil:
    section.add "X-Amz-Signature", valid_606055
  var valid_606056 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606056 = validateParameter(valid_606056, JString, required = false,
                                 default = nil)
  if valid_606056 != nil:
    section.add "X-Amz-Content-Sha256", valid_606056
  var valid_606057 = header.getOrDefault("X-Amz-Date")
  valid_606057 = validateParameter(valid_606057, JString, required = false,
                                 default = nil)
  if valid_606057 != nil:
    section.add "X-Amz-Date", valid_606057
  var valid_606058 = header.getOrDefault("X-Amz-Credential")
  valid_606058 = validateParameter(valid_606058, JString, required = false,
                                 default = nil)
  if valid_606058 != nil:
    section.add "X-Amz-Credential", valid_606058
  var valid_606059 = header.getOrDefault("X-Amz-Security-Token")
  valid_606059 = validateParameter(valid_606059, JString, required = false,
                                 default = nil)
  if valid_606059 != nil:
    section.add "X-Amz-Security-Token", valid_606059
  var valid_606060 = header.getOrDefault("X-Amz-Algorithm")
  valid_606060 = validateParameter(valid_606060, JString, required = false,
                                 default = nil)
  if valid_606060 != nil:
    section.add "X-Amz-Algorithm", valid_606060
  var valid_606061 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606061 = validateParameter(valid_606061, JString, required = false,
                                 default = nil)
  if valid_606061 != nil:
    section.add "X-Amz-SignedHeaders", valid_606061
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606085: Call_CreateEnvironmentEC2_605927; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an AWS Cloud9 development environment, launches an Amazon Elastic Compute Cloud (Amazon EC2) instance, and then connects from the instance to the environment.
  ## 
  let valid = call_606085.validator(path, query, header, formData, body)
  let scheme = call_606085.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606085.url(scheme.get, call_606085.host, call_606085.base,
                         call_606085.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606085, url, valid)

proc call*(call_606156: Call_CreateEnvironmentEC2_605927; body: JsonNode): Recallable =
  ## createEnvironmentEC2
  ## Creates an AWS Cloud9 development environment, launches an Amazon Elastic Compute Cloud (Amazon EC2) instance, and then connects from the instance to the environment.
  ##   body: JObject (required)
  var body_606157 = newJObject()
  if body != nil:
    body_606157 = body
  result = call_606156.call(nil, nil, nil, nil, body_606157)

var createEnvironmentEC2* = Call_CreateEnvironmentEC2_605927(
    name: "createEnvironmentEC2", meth: HttpMethod.HttpPost,
    host: "cloud9.amazonaws.com", route: "/#X-Amz-Target=AWSCloud9WorkspaceManagementService.CreateEnvironmentEC2",
    validator: validate_CreateEnvironmentEC2_605928, base: "/",
    url: url_CreateEnvironmentEC2_605929, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateEnvironmentMembership_606196 = ref object of OpenApiRestCall_605589
proc url_CreateEnvironmentMembership_606198(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateEnvironmentMembership_606197(path: JsonNode; query: JsonNode;
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
  var valid_606199 = header.getOrDefault("X-Amz-Target")
  valid_606199 = validateParameter(valid_606199, JString, required = true, default = newJString(
      "AWSCloud9WorkspaceManagementService.CreateEnvironmentMembership"))
  if valid_606199 != nil:
    section.add "X-Amz-Target", valid_606199
  var valid_606200 = header.getOrDefault("X-Amz-Signature")
  valid_606200 = validateParameter(valid_606200, JString, required = false,
                                 default = nil)
  if valid_606200 != nil:
    section.add "X-Amz-Signature", valid_606200
  var valid_606201 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606201 = validateParameter(valid_606201, JString, required = false,
                                 default = nil)
  if valid_606201 != nil:
    section.add "X-Amz-Content-Sha256", valid_606201
  var valid_606202 = header.getOrDefault("X-Amz-Date")
  valid_606202 = validateParameter(valid_606202, JString, required = false,
                                 default = nil)
  if valid_606202 != nil:
    section.add "X-Amz-Date", valid_606202
  var valid_606203 = header.getOrDefault("X-Amz-Credential")
  valid_606203 = validateParameter(valid_606203, JString, required = false,
                                 default = nil)
  if valid_606203 != nil:
    section.add "X-Amz-Credential", valid_606203
  var valid_606204 = header.getOrDefault("X-Amz-Security-Token")
  valid_606204 = validateParameter(valid_606204, JString, required = false,
                                 default = nil)
  if valid_606204 != nil:
    section.add "X-Amz-Security-Token", valid_606204
  var valid_606205 = header.getOrDefault("X-Amz-Algorithm")
  valid_606205 = validateParameter(valid_606205, JString, required = false,
                                 default = nil)
  if valid_606205 != nil:
    section.add "X-Amz-Algorithm", valid_606205
  var valid_606206 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606206 = validateParameter(valid_606206, JString, required = false,
                                 default = nil)
  if valid_606206 != nil:
    section.add "X-Amz-SignedHeaders", valid_606206
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606208: Call_CreateEnvironmentMembership_606196; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds an environment member to an AWS Cloud9 development environment.
  ## 
  let valid = call_606208.validator(path, query, header, formData, body)
  let scheme = call_606208.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606208.url(scheme.get, call_606208.host, call_606208.base,
                         call_606208.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606208, url, valid)

proc call*(call_606209: Call_CreateEnvironmentMembership_606196; body: JsonNode): Recallable =
  ## createEnvironmentMembership
  ## Adds an environment member to an AWS Cloud9 development environment.
  ##   body: JObject (required)
  var body_606210 = newJObject()
  if body != nil:
    body_606210 = body
  result = call_606209.call(nil, nil, nil, nil, body_606210)

var createEnvironmentMembership* = Call_CreateEnvironmentMembership_606196(
    name: "createEnvironmentMembership", meth: HttpMethod.HttpPost,
    host: "cloud9.amazonaws.com", route: "/#X-Amz-Target=AWSCloud9WorkspaceManagementService.CreateEnvironmentMembership",
    validator: validate_CreateEnvironmentMembership_606197, base: "/",
    url: url_CreateEnvironmentMembership_606198,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteEnvironment_606211 = ref object of OpenApiRestCall_605589
proc url_DeleteEnvironment_606213(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteEnvironment_606212(path: JsonNode; query: JsonNode;
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
  var valid_606214 = header.getOrDefault("X-Amz-Target")
  valid_606214 = validateParameter(valid_606214, JString, required = true, default = newJString(
      "AWSCloud9WorkspaceManagementService.DeleteEnvironment"))
  if valid_606214 != nil:
    section.add "X-Amz-Target", valid_606214
  var valid_606215 = header.getOrDefault("X-Amz-Signature")
  valid_606215 = validateParameter(valid_606215, JString, required = false,
                                 default = nil)
  if valid_606215 != nil:
    section.add "X-Amz-Signature", valid_606215
  var valid_606216 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606216 = validateParameter(valid_606216, JString, required = false,
                                 default = nil)
  if valid_606216 != nil:
    section.add "X-Amz-Content-Sha256", valid_606216
  var valid_606217 = header.getOrDefault("X-Amz-Date")
  valid_606217 = validateParameter(valid_606217, JString, required = false,
                                 default = nil)
  if valid_606217 != nil:
    section.add "X-Amz-Date", valid_606217
  var valid_606218 = header.getOrDefault("X-Amz-Credential")
  valid_606218 = validateParameter(valid_606218, JString, required = false,
                                 default = nil)
  if valid_606218 != nil:
    section.add "X-Amz-Credential", valid_606218
  var valid_606219 = header.getOrDefault("X-Amz-Security-Token")
  valid_606219 = validateParameter(valid_606219, JString, required = false,
                                 default = nil)
  if valid_606219 != nil:
    section.add "X-Amz-Security-Token", valid_606219
  var valid_606220 = header.getOrDefault("X-Amz-Algorithm")
  valid_606220 = validateParameter(valid_606220, JString, required = false,
                                 default = nil)
  if valid_606220 != nil:
    section.add "X-Amz-Algorithm", valid_606220
  var valid_606221 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606221 = validateParameter(valid_606221, JString, required = false,
                                 default = nil)
  if valid_606221 != nil:
    section.add "X-Amz-SignedHeaders", valid_606221
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606223: Call_DeleteEnvironment_606211; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an AWS Cloud9 development environment. If an Amazon EC2 instance is connected to the environment, also terminates the instance.
  ## 
  let valid = call_606223.validator(path, query, header, formData, body)
  let scheme = call_606223.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606223.url(scheme.get, call_606223.host, call_606223.base,
                         call_606223.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606223, url, valid)

proc call*(call_606224: Call_DeleteEnvironment_606211; body: JsonNode): Recallable =
  ## deleteEnvironment
  ## Deletes an AWS Cloud9 development environment. If an Amazon EC2 instance is connected to the environment, also terminates the instance.
  ##   body: JObject (required)
  var body_606225 = newJObject()
  if body != nil:
    body_606225 = body
  result = call_606224.call(nil, nil, nil, nil, body_606225)

var deleteEnvironment* = Call_DeleteEnvironment_606211(name: "deleteEnvironment",
    meth: HttpMethod.HttpPost, host: "cloud9.amazonaws.com", route: "/#X-Amz-Target=AWSCloud9WorkspaceManagementService.DeleteEnvironment",
    validator: validate_DeleteEnvironment_606212, base: "/",
    url: url_DeleteEnvironment_606213, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteEnvironmentMembership_606226 = ref object of OpenApiRestCall_605589
proc url_DeleteEnvironmentMembership_606228(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteEnvironmentMembership_606227(path: JsonNode; query: JsonNode;
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
  var valid_606229 = header.getOrDefault("X-Amz-Target")
  valid_606229 = validateParameter(valid_606229, JString, required = true, default = newJString(
      "AWSCloud9WorkspaceManagementService.DeleteEnvironmentMembership"))
  if valid_606229 != nil:
    section.add "X-Amz-Target", valid_606229
  var valid_606230 = header.getOrDefault("X-Amz-Signature")
  valid_606230 = validateParameter(valid_606230, JString, required = false,
                                 default = nil)
  if valid_606230 != nil:
    section.add "X-Amz-Signature", valid_606230
  var valid_606231 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606231 = validateParameter(valid_606231, JString, required = false,
                                 default = nil)
  if valid_606231 != nil:
    section.add "X-Amz-Content-Sha256", valid_606231
  var valid_606232 = header.getOrDefault("X-Amz-Date")
  valid_606232 = validateParameter(valid_606232, JString, required = false,
                                 default = nil)
  if valid_606232 != nil:
    section.add "X-Amz-Date", valid_606232
  var valid_606233 = header.getOrDefault("X-Amz-Credential")
  valid_606233 = validateParameter(valid_606233, JString, required = false,
                                 default = nil)
  if valid_606233 != nil:
    section.add "X-Amz-Credential", valid_606233
  var valid_606234 = header.getOrDefault("X-Amz-Security-Token")
  valid_606234 = validateParameter(valid_606234, JString, required = false,
                                 default = nil)
  if valid_606234 != nil:
    section.add "X-Amz-Security-Token", valid_606234
  var valid_606235 = header.getOrDefault("X-Amz-Algorithm")
  valid_606235 = validateParameter(valid_606235, JString, required = false,
                                 default = nil)
  if valid_606235 != nil:
    section.add "X-Amz-Algorithm", valid_606235
  var valid_606236 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606236 = validateParameter(valid_606236, JString, required = false,
                                 default = nil)
  if valid_606236 != nil:
    section.add "X-Amz-SignedHeaders", valid_606236
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606238: Call_DeleteEnvironmentMembership_606226; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an environment member from an AWS Cloud9 development environment.
  ## 
  let valid = call_606238.validator(path, query, header, formData, body)
  let scheme = call_606238.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606238.url(scheme.get, call_606238.host, call_606238.base,
                         call_606238.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606238, url, valid)

proc call*(call_606239: Call_DeleteEnvironmentMembership_606226; body: JsonNode): Recallable =
  ## deleteEnvironmentMembership
  ## Deletes an environment member from an AWS Cloud9 development environment.
  ##   body: JObject (required)
  var body_606240 = newJObject()
  if body != nil:
    body_606240 = body
  result = call_606239.call(nil, nil, nil, nil, body_606240)

var deleteEnvironmentMembership* = Call_DeleteEnvironmentMembership_606226(
    name: "deleteEnvironmentMembership", meth: HttpMethod.HttpPost,
    host: "cloud9.amazonaws.com", route: "/#X-Amz-Target=AWSCloud9WorkspaceManagementService.DeleteEnvironmentMembership",
    validator: validate_DeleteEnvironmentMembership_606227, base: "/",
    url: url_DeleteEnvironmentMembership_606228,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEnvironmentMemberships_606241 = ref object of OpenApiRestCall_605589
proc url_DescribeEnvironmentMemberships_606243(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeEnvironmentMemberships_606242(path: JsonNode;
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
  var valid_606244 = query.getOrDefault("nextToken")
  valid_606244 = validateParameter(valid_606244, JString, required = false,
                                 default = nil)
  if valid_606244 != nil:
    section.add "nextToken", valid_606244
  var valid_606245 = query.getOrDefault("maxResults")
  valid_606245 = validateParameter(valid_606245, JString, required = false,
                                 default = nil)
  if valid_606245 != nil:
    section.add "maxResults", valid_606245
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
  var valid_606246 = header.getOrDefault("X-Amz-Target")
  valid_606246 = validateParameter(valid_606246, JString, required = true, default = newJString(
      "AWSCloud9WorkspaceManagementService.DescribeEnvironmentMemberships"))
  if valid_606246 != nil:
    section.add "X-Amz-Target", valid_606246
  var valid_606247 = header.getOrDefault("X-Amz-Signature")
  valid_606247 = validateParameter(valid_606247, JString, required = false,
                                 default = nil)
  if valid_606247 != nil:
    section.add "X-Amz-Signature", valid_606247
  var valid_606248 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606248 = validateParameter(valid_606248, JString, required = false,
                                 default = nil)
  if valid_606248 != nil:
    section.add "X-Amz-Content-Sha256", valid_606248
  var valid_606249 = header.getOrDefault("X-Amz-Date")
  valid_606249 = validateParameter(valid_606249, JString, required = false,
                                 default = nil)
  if valid_606249 != nil:
    section.add "X-Amz-Date", valid_606249
  var valid_606250 = header.getOrDefault("X-Amz-Credential")
  valid_606250 = validateParameter(valid_606250, JString, required = false,
                                 default = nil)
  if valid_606250 != nil:
    section.add "X-Amz-Credential", valid_606250
  var valid_606251 = header.getOrDefault("X-Amz-Security-Token")
  valid_606251 = validateParameter(valid_606251, JString, required = false,
                                 default = nil)
  if valid_606251 != nil:
    section.add "X-Amz-Security-Token", valid_606251
  var valid_606252 = header.getOrDefault("X-Amz-Algorithm")
  valid_606252 = validateParameter(valid_606252, JString, required = false,
                                 default = nil)
  if valid_606252 != nil:
    section.add "X-Amz-Algorithm", valid_606252
  var valid_606253 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606253 = validateParameter(valid_606253, JString, required = false,
                                 default = nil)
  if valid_606253 != nil:
    section.add "X-Amz-SignedHeaders", valid_606253
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606255: Call_DescribeEnvironmentMemberships_606241; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about environment members for an AWS Cloud9 development environment.
  ## 
  let valid = call_606255.validator(path, query, header, formData, body)
  let scheme = call_606255.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606255.url(scheme.get, call_606255.host, call_606255.base,
                         call_606255.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606255, url, valid)

proc call*(call_606256: Call_DescribeEnvironmentMemberships_606241; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## describeEnvironmentMemberships
  ## Gets information about environment members for an AWS Cloud9 development environment.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_606257 = newJObject()
  var body_606258 = newJObject()
  add(query_606257, "nextToken", newJString(nextToken))
  if body != nil:
    body_606258 = body
  add(query_606257, "maxResults", newJString(maxResults))
  result = call_606256.call(nil, query_606257, nil, nil, body_606258)

var describeEnvironmentMemberships* = Call_DescribeEnvironmentMemberships_606241(
    name: "describeEnvironmentMemberships", meth: HttpMethod.HttpPost,
    host: "cloud9.amazonaws.com", route: "/#X-Amz-Target=AWSCloud9WorkspaceManagementService.DescribeEnvironmentMemberships",
    validator: validate_DescribeEnvironmentMemberships_606242, base: "/",
    url: url_DescribeEnvironmentMemberships_606243,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEnvironmentStatus_606260 = ref object of OpenApiRestCall_605589
proc url_DescribeEnvironmentStatus_606262(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeEnvironmentStatus_606261(path: JsonNode; query: JsonNode;
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
  var valid_606263 = header.getOrDefault("X-Amz-Target")
  valid_606263 = validateParameter(valid_606263, JString, required = true, default = newJString(
      "AWSCloud9WorkspaceManagementService.DescribeEnvironmentStatus"))
  if valid_606263 != nil:
    section.add "X-Amz-Target", valid_606263
  var valid_606264 = header.getOrDefault("X-Amz-Signature")
  valid_606264 = validateParameter(valid_606264, JString, required = false,
                                 default = nil)
  if valid_606264 != nil:
    section.add "X-Amz-Signature", valid_606264
  var valid_606265 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606265 = validateParameter(valid_606265, JString, required = false,
                                 default = nil)
  if valid_606265 != nil:
    section.add "X-Amz-Content-Sha256", valid_606265
  var valid_606266 = header.getOrDefault("X-Amz-Date")
  valid_606266 = validateParameter(valid_606266, JString, required = false,
                                 default = nil)
  if valid_606266 != nil:
    section.add "X-Amz-Date", valid_606266
  var valid_606267 = header.getOrDefault("X-Amz-Credential")
  valid_606267 = validateParameter(valid_606267, JString, required = false,
                                 default = nil)
  if valid_606267 != nil:
    section.add "X-Amz-Credential", valid_606267
  var valid_606268 = header.getOrDefault("X-Amz-Security-Token")
  valid_606268 = validateParameter(valid_606268, JString, required = false,
                                 default = nil)
  if valid_606268 != nil:
    section.add "X-Amz-Security-Token", valid_606268
  var valid_606269 = header.getOrDefault("X-Amz-Algorithm")
  valid_606269 = validateParameter(valid_606269, JString, required = false,
                                 default = nil)
  if valid_606269 != nil:
    section.add "X-Amz-Algorithm", valid_606269
  var valid_606270 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606270 = validateParameter(valid_606270, JString, required = false,
                                 default = nil)
  if valid_606270 != nil:
    section.add "X-Amz-SignedHeaders", valid_606270
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606272: Call_DescribeEnvironmentStatus_606260; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets status information for an AWS Cloud9 development environment.
  ## 
  let valid = call_606272.validator(path, query, header, formData, body)
  let scheme = call_606272.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606272.url(scheme.get, call_606272.host, call_606272.base,
                         call_606272.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606272, url, valid)

proc call*(call_606273: Call_DescribeEnvironmentStatus_606260; body: JsonNode): Recallable =
  ## describeEnvironmentStatus
  ## Gets status information for an AWS Cloud9 development environment.
  ##   body: JObject (required)
  var body_606274 = newJObject()
  if body != nil:
    body_606274 = body
  result = call_606273.call(nil, nil, nil, nil, body_606274)

var describeEnvironmentStatus* = Call_DescribeEnvironmentStatus_606260(
    name: "describeEnvironmentStatus", meth: HttpMethod.HttpPost,
    host: "cloud9.amazonaws.com", route: "/#X-Amz-Target=AWSCloud9WorkspaceManagementService.DescribeEnvironmentStatus",
    validator: validate_DescribeEnvironmentStatus_606261, base: "/",
    url: url_DescribeEnvironmentStatus_606262,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEnvironments_606275 = ref object of OpenApiRestCall_605589
proc url_DescribeEnvironments_606277(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeEnvironments_606276(path: JsonNode; query: JsonNode;
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
  var valid_606278 = header.getOrDefault("X-Amz-Target")
  valid_606278 = validateParameter(valid_606278, JString, required = true, default = newJString(
      "AWSCloud9WorkspaceManagementService.DescribeEnvironments"))
  if valid_606278 != nil:
    section.add "X-Amz-Target", valid_606278
  var valid_606279 = header.getOrDefault("X-Amz-Signature")
  valid_606279 = validateParameter(valid_606279, JString, required = false,
                                 default = nil)
  if valid_606279 != nil:
    section.add "X-Amz-Signature", valid_606279
  var valid_606280 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606280 = validateParameter(valid_606280, JString, required = false,
                                 default = nil)
  if valid_606280 != nil:
    section.add "X-Amz-Content-Sha256", valid_606280
  var valid_606281 = header.getOrDefault("X-Amz-Date")
  valid_606281 = validateParameter(valid_606281, JString, required = false,
                                 default = nil)
  if valid_606281 != nil:
    section.add "X-Amz-Date", valid_606281
  var valid_606282 = header.getOrDefault("X-Amz-Credential")
  valid_606282 = validateParameter(valid_606282, JString, required = false,
                                 default = nil)
  if valid_606282 != nil:
    section.add "X-Amz-Credential", valid_606282
  var valid_606283 = header.getOrDefault("X-Amz-Security-Token")
  valid_606283 = validateParameter(valid_606283, JString, required = false,
                                 default = nil)
  if valid_606283 != nil:
    section.add "X-Amz-Security-Token", valid_606283
  var valid_606284 = header.getOrDefault("X-Amz-Algorithm")
  valid_606284 = validateParameter(valid_606284, JString, required = false,
                                 default = nil)
  if valid_606284 != nil:
    section.add "X-Amz-Algorithm", valid_606284
  var valid_606285 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606285 = validateParameter(valid_606285, JString, required = false,
                                 default = nil)
  if valid_606285 != nil:
    section.add "X-Amz-SignedHeaders", valid_606285
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606287: Call_DescribeEnvironments_606275; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about AWS Cloud9 development environments.
  ## 
  let valid = call_606287.validator(path, query, header, formData, body)
  let scheme = call_606287.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606287.url(scheme.get, call_606287.host, call_606287.base,
                         call_606287.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606287, url, valid)

proc call*(call_606288: Call_DescribeEnvironments_606275; body: JsonNode): Recallable =
  ## describeEnvironments
  ## Gets information about AWS Cloud9 development environments.
  ##   body: JObject (required)
  var body_606289 = newJObject()
  if body != nil:
    body_606289 = body
  result = call_606288.call(nil, nil, nil, nil, body_606289)

var describeEnvironments* = Call_DescribeEnvironments_606275(
    name: "describeEnvironments", meth: HttpMethod.HttpPost,
    host: "cloud9.amazonaws.com", route: "/#X-Amz-Target=AWSCloud9WorkspaceManagementService.DescribeEnvironments",
    validator: validate_DescribeEnvironments_606276, base: "/",
    url: url_DescribeEnvironments_606277, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListEnvironments_606290 = ref object of OpenApiRestCall_605589
proc url_ListEnvironments_606292(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListEnvironments_606291(path: JsonNode; query: JsonNode;
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
  var valid_606293 = query.getOrDefault("nextToken")
  valid_606293 = validateParameter(valid_606293, JString, required = false,
                                 default = nil)
  if valid_606293 != nil:
    section.add "nextToken", valid_606293
  var valid_606294 = query.getOrDefault("maxResults")
  valid_606294 = validateParameter(valid_606294, JString, required = false,
                                 default = nil)
  if valid_606294 != nil:
    section.add "maxResults", valid_606294
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
  var valid_606295 = header.getOrDefault("X-Amz-Target")
  valid_606295 = validateParameter(valid_606295, JString, required = true, default = newJString(
      "AWSCloud9WorkspaceManagementService.ListEnvironments"))
  if valid_606295 != nil:
    section.add "X-Amz-Target", valid_606295
  var valid_606296 = header.getOrDefault("X-Amz-Signature")
  valid_606296 = validateParameter(valid_606296, JString, required = false,
                                 default = nil)
  if valid_606296 != nil:
    section.add "X-Amz-Signature", valid_606296
  var valid_606297 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606297 = validateParameter(valid_606297, JString, required = false,
                                 default = nil)
  if valid_606297 != nil:
    section.add "X-Amz-Content-Sha256", valid_606297
  var valid_606298 = header.getOrDefault("X-Amz-Date")
  valid_606298 = validateParameter(valid_606298, JString, required = false,
                                 default = nil)
  if valid_606298 != nil:
    section.add "X-Amz-Date", valid_606298
  var valid_606299 = header.getOrDefault("X-Amz-Credential")
  valid_606299 = validateParameter(valid_606299, JString, required = false,
                                 default = nil)
  if valid_606299 != nil:
    section.add "X-Amz-Credential", valid_606299
  var valid_606300 = header.getOrDefault("X-Amz-Security-Token")
  valid_606300 = validateParameter(valid_606300, JString, required = false,
                                 default = nil)
  if valid_606300 != nil:
    section.add "X-Amz-Security-Token", valid_606300
  var valid_606301 = header.getOrDefault("X-Amz-Algorithm")
  valid_606301 = validateParameter(valid_606301, JString, required = false,
                                 default = nil)
  if valid_606301 != nil:
    section.add "X-Amz-Algorithm", valid_606301
  var valid_606302 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606302 = validateParameter(valid_606302, JString, required = false,
                                 default = nil)
  if valid_606302 != nil:
    section.add "X-Amz-SignedHeaders", valid_606302
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606304: Call_ListEnvironments_606290; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a list of AWS Cloud9 development environment identifiers.
  ## 
  let valid = call_606304.validator(path, query, header, formData, body)
  let scheme = call_606304.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606304.url(scheme.get, call_606304.host, call_606304.base,
                         call_606304.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606304, url, valid)

proc call*(call_606305: Call_ListEnvironments_606290; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listEnvironments
  ## Gets a list of AWS Cloud9 development environment identifiers.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_606306 = newJObject()
  var body_606307 = newJObject()
  add(query_606306, "nextToken", newJString(nextToken))
  if body != nil:
    body_606307 = body
  add(query_606306, "maxResults", newJString(maxResults))
  result = call_606305.call(nil, query_606306, nil, nil, body_606307)

var listEnvironments* = Call_ListEnvironments_606290(name: "listEnvironments",
    meth: HttpMethod.HttpPost, host: "cloud9.amazonaws.com", route: "/#X-Amz-Target=AWSCloud9WorkspaceManagementService.ListEnvironments",
    validator: validate_ListEnvironments_606291, base: "/",
    url: url_ListEnvironments_606292, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateEnvironment_606308 = ref object of OpenApiRestCall_605589
proc url_UpdateEnvironment_606310(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateEnvironment_606309(path: JsonNode; query: JsonNode;
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
  var valid_606311 = header.getOrDefault("X-Amz-Target")
  valid_606311 = validateParameter(valid_606311, JString, required = true, default = newJString(
      "AWSCloud9WorkspaceManagementService.UpdateEnvironment"))
  if valid_606311 != nil:
    section.add "X-Amz-Target", valid_606311
  var valid_606312 = header.getOrDefault("X-Amz-Signature")
  valid_606312 = validateParameter(valid_606312, JString, required = false,
                                 default = nil)
  if valid_606312 != nil:
    section.add "X-Amz-Signature", valid_606312
  var valid_606313 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606313 = validateParameter(valid_606313, JString, required = false,
                                 default = nil)
  if valid_606313 != nil:
    section.add "X-Amz-Content-Sha256", valid_606313
  var valid_606314 = header.getOrDefault("X-Amz-Date")
  valid_606314 = validateParameter(valid_606314, JString, required = false,
                                 default = nil)
  if valid_606314 != nil:
    section.add "X-Amz-Date", valid_606314
  var valid_606315 = header.getOrDefault("X-Amz-Credential")
  valid_606315 = validateParameter(valid_606315, JString, required = false,
                                 default = nil)
  if valid_606315 != nil:
    section.add "X-Amz-Credential", valid_606315
  var valid_606316 = header.getOrDefault("X-Amz-Security-Token")
  valid_606316 = validateParameter(valid_606316, JString, required = false,
                                 default = nil)
  if valid_606316 != nil:
    section.add "X-Amz-Security-Token", valid_606316
  var valid_606317 = header.getOrDefault("X-Amz-Algorithm")
  valid_606317 = validateParameter(valid_606317, JString, required = false,
                                 default = nil)
  if valid_606317 != nil:
    section.add "X-Amz-Algorithm", valid_606317
  var valid_606318 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606318 = validateParameter(valid_606318, JString, required = false,
                                 default = nil)
  if valid_606318 != nil:
    section.add "X-Amz-SignedHeaders", valid_606318
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606320: Call_UpdateEnvironment_606308; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes the settings of an existing AWS Cloud9 development environment.
  ## 
  let valid = call_606320.validator(path, query, header, formData, body)
  let scheme = call_606320.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606320.url(scheme.get, call_606320.host, call_606320.base,
                         call_606320.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606320, url, valid)

proc call*(call_606321: Call_UpdateEnvironment_606308; body: JsonNode): Recallable =
  ## updateEnvironment
  ## Changes the settings of an existing AWS Cloud9 development environment.
  ##   body: JObject (required)
  var body_606322 = newJObject()
  if body != nil:
    body_606322 = body
  result = call_606321.call(nil, nil, nil, nil, body_606322)

var updateEnvironment* = Call_UpdateEnvironment_606308(name: "updateEnvironment",
    meth: HttpMethod.HttpPost, host: "cloud9.amazonaws.com", route: "/#X-Amz-Target=AWSCloud9WorkspaceManagementService.UpdateEnvironment",
    validator: validate_UpdateEnvironment_606309, base: "/",
    url: url_UpdateEnvironment_606310, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateEnvironmentMembership_606323 = ref object of OpenApiRestCall_605589
proc url_UpdateEnvironmentMembership_606325(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateEnvironmentMembership_606324(path: JsonNode; query: JsonNode;
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
  var valid_606326 = header.getOrDefault("X-Amz-Target")
  valid_606326 = validateParameter(valid_606326, JString, required = true, default = newJString(
      "AWSCloud9WorkspaceManagementService.UpdateEnvironmentMembership"))
  if valid_606326 != nil:
    section.add "X-Amz-Target", valid_606326
  var valid_606327 = header.getOrDefault("X-Amz-Signature")
  valid_606327 = validateParameter(valid_606327, JString, required = false,
                                 default = nil)
  if valid_606327 != nil:
    section.add "X-Amz-Signature", valid_606327
  var valid_606328 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606328 = validateParameter(valid_606328, JString, required = false,
                                 default = nil)
  if valid_606328 != nil:
    section.add "X-Amz-Content-Sha256", valid_606328
  var valid_606329 = header.getOrDefault("X-Amz-Date")
  valid_606329 = validateParameter(valid_606329, JString, required = false,
                                 default = nil)
  if valid_606329 != nil:
    section.add "X-Amz-Date", valid_606329
  var valid_606330 = header.getOrDefault("X-Amz-Credential")
  valid_606330 = validateParameter(valid_606330, JString, required = false,
                                 default = nil)
  if valid_606330 != nil:
    section.add "X-Amz-Credential", valid_606330
  var valid_606331 = header.getOrDefault("X-Amz-Security-Token")
  valid_606331 = validateParameter(valid_606331, JString, required = false,
                                 default = nil)
  if valid_606331 != nil:
    section.add "X-Amz-Security-Token", valid_606331
  var valid_606332 = header.getOrDefault("X-Amz-Algorithm")
  valid_606332 = validateParameter(valid_606332, JString, required = false,
                                 default = nil)
  if valid_606332 != nil:
    section.add "X-Amz-Algorithm", valid_606332
  var valid_606333 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606333 = validateParameter(valid_606333, JString, required = false,
                                 default = nil)
  if valid_606333 != nil:
    section.add "X-Amz-SignedHeaders", valid_606333
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606335: Call_UpdateEnvironmentMembership_606323; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes the settings of an existing environment member for an AWS Cloud9 development environment.
  ## 
  let valid = call_606335.validator(path, query, header, formData, body)
  let scheme = call_606335.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606335.url(scheme.get, call_606335.host, call_606335.base,
                         call_606335.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606335, url, valid)

proc call*(call_606336: Call_UpdateEnvironmentMembership_606323; body: JsonNode): Recallable =
  ## updateEnvironmentMembership
  ## Changes the settings of an existing environment member for an AWS Cloud9 development environment.
  ##   body: JObject (required)
  var body_606337 = newJObject()
  if body != nil:
    body_606337 = body
  result = call_606336.call(nil, nil, nil, nil, body_606337)

var updateEnvironmentMembership* = Call_UpdateEnvironmentMembership_606323(
    name: "updateEnvironmentMembership", meth: HttpMethod.HttpPost,
    host: "cloud9.amazonaws.com", route: "/#X-Amz-Target=AWSCloud9WorkspaceManagementService.UpdateEnvironmentMembership",
    validator: validate_UpdateEnvironmentMembership_606324, base: "/",
    url: url_UpdateEnvironmentMembership_606325,
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
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)
