
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
## <fullname>AWS Cloud9</fullname> <p>AWS Cloud9 is a collection of tools that you can use to code, build, run, test, debug, and release software in the cloud.</p> <p>For more information about AWS Cloud9, see the <a href="https://docs.aws.amazon.com/cloud9/latest/user-guide">AWS Cloud9 User Guide</a>.</p> <p>AWS Cloud9 supports these operations:</p> <ul> <li> <p> <code>CreateEnvironmentEC2</code>: Creates an AWS Cloud9 development environment, launches an Amazon EC2 instance, and then connects from the instance to the environment.</p> </li> <li> <p> <code>CreateEnvironmentMembership</code>: Adds an environment member to an environment.</p> </li> <li> <p> <code>DeleteEnvironment</code>: Deletes an environment. If an Amazon EC2 instance is connected to the environment, also terminates the instance.</p> </li> <li> <p> <code>DeleteEnvironmentMembership</code>: Deletes an environment member from an environment.</p> </li> <li> <p> <code>DescribeEnvironmentMemberships</code>: Gets information about environment members for an environment.</p> </li> <li> <p> <code>DescribeEnvironments</code>: Gets information about environments.</p> </li> <li> <p> <code>DescribeEnvironmentStatus</code>: Gets status information for an environment.</p> </li> <li> <p> <code>ListEnvironments</code>: Gets a list of environment identifiers.</p> </li> <li> <p> <code>ListTagsForResource</code>: Gets the tags for an environment.</p> </li> <li> <p> <code>TagResource</code>: Adds tags to an environment.</p> </li> <li> <p> <code>UntagResource</code>: Removes tags from an environment.</p> </li> <li> <p> <code>UpdateEnvironment</code>: Changes the settings of an existing environment.</p> </li> <li> <p> <code>UpdateEnvironmentMembership</code>: Changes the settings of an existing environment member for an environment.</p> </li> </ul>
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
  Call_CreateEnvironmentEC2_610996 = ref object of OpenApiRestCall_610658
proc url_CreateEnvironmentEC2_610998(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateEnvironmentEC2_610997(path: JsonNode; query: JsonNode;
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
  var valid_611123 = header.getOrDefault("X-Amz-Target")
  valid_611123 = validateParameter(valid_611123, JString, required = true, default = newJString(
      "AWSCloud9WorkspaceManagementService.CreateEnvironmentEC2"))
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

proc call*(call_611154: Call_CreateEnvironmentEC2_610996; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an AWS Cloud9 development environment, launches an Amazon Elastic Compute Cloud (Amazon EC2) instance, and then connects from the instance to the environment.
  ## 
  let valid = call_611154.validator(path, query, header, formData, body)
  let scheme = call_611154.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611154.url(scheme.get, call_611154.host, call_611154.base,
                         call_611154.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611154, url, valid)

proc call*(call_611225: Call_CreateEnvironmentEC2_610996; body: JsonNode): Recallable =
  ## createEnvironmentEC2
  ## Creates an AWS Cloud9 development environment, launches an Amazon Elastic Compute Cloud (Amazon EC2) instance, and then connects from the instance to the environment.
  ##   body: JObject (required)
  var body_611226 = newJObject()
  if body != nil:
    body_611226 = body
  result = call_611225.call(nil, nil, nil, nil, body_611226)

var createEnvironmentEC2* = Call_CreateEnvironmentEC2_610996(
    name: "createEnvironmentEC2", meth: HttpMethod.HttpPost,
    host: "cloud9.amazonaws.com", route: "/#X-Amz-Target=AWSCloud9WorkspaceManagementService.CreateEnvironmentEC2",
    validator: validate_CreateEnvironmentEC2_610997, base: "/",
    url: url_CreateEnvironmentEC2_610998, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateEnvironmentMembership_611265 = ref object of OpenApiRestCall_610658
proc url_CreateEnvironmentMembership_611267(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateEnvironmentMembership_611266(path: JsonNode; query: JsonNode;
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
  var valid_611268 = header.getOrDefault("X-Amz-Target")
  valid_611268 = validateParameter(valid_611268, JString, required = true, default = newJString(
      "AWSCloud9WorkspaceManagementService.CreateEnvironmentMembership"))
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

proc call*(call_611277: Call_CreateEnvironmentMembership_611265; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds an environment member to an AWS Cloud9 development environment.
  ## 
  let valid = call_611277.validator(path, query, header, formData, body)
  let scheme = call_611277.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611277.url(scheme.get, call_611277.host, call_611277.base,
                         call_611277.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611277, url, valid)

proc call*(call_611278: Call_CreateEnvironmentMembership_611265; body: JsonNode): Recallable =
  ## createEnvironmentMembership
  ## Adds an environment member to an AWS Cloud9 development environment.
  ##   body: JObject (required)
  var body_611279 = newJObject()
  if body != nil:
    body_611279 = body
  result = call_611278.call(nil, nil, nil, nil, body_611279)

var createEnvironmentMembership* = Call_CreateEnvironmentMembership_611265(
    name: "createEnvironmentMembership", meth: HttpMethod.HttpPost,
    host: "cloud9.amazonaws.com", route: "/#X-Amz-Target=AWSCloud9WorkspaceManagementService.CreateEnvironmentMembership",
    validator: validate_CreateEnvironmentMembership_611266, base: "/",
    url: url_CreateEnvironmentMembership_611267,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteEnvironment_611280 = ref object of OpenApiRestCall_610658
proc url_DeleteEnvironment_611282(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteEnvironment_611281(path: JsonNode; query: JsonNode;
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
  var valid_611283 = header.getOrDefault("X-Amz-Target")
  valid_611283 = validateParameter(valid_611283, JString, required = true, default = newJString(
      "AWSCloud9WorkspaceManagementService.DeleteEnvironment"))
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

proc call*(call_611292: Call_DeleteEnvironment_611280; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an AWS Cloud9 development environment. If an Amazon EC2 instance is connected to the environment, also terminates the instance.
  ## 
  let valid = call_611292.validator(path, query, header, formData, body)
  let scheme = call_611292.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611292.url(scheme.get, call_611292.host, call_611292.base,
                         call_611292.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611292, url, valid)

proc call*(call_611293: Call_DeleteEnvironment_611280; body: JsonNode): Recallable =
  ## deleteEnvironment
  ## Deletes an AWS Cloud9 development environment. If an Amazon EC2 instance is connected to the environment, also terminates the instance.
  ##   body: JObject (required)
  var body_611294 = newJObject()
  if body != nil:
    body_611294 = body
  result = call_611293.call(nil, nil, nil, nil, body_611294)

var deleteEnvironment* = Call_DeleteEnvironment_611280(name: "deleteEnvironment",
    meth: HttpMethod.HttpPost, host: "cloud9.amazonaws.com", route: "/#X-Amz-Target=AWSCloud9WorkspaceManagementService.DeleteEnvironment",
    validator: validate_DeleteEnvironment_611281, base: "/",
    url: url_DeleteEnvironment_611282, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteEnvironmentMembership_611295 = ref object of OpenApiRestCall_610658
proc url_DeleteEnvironmentMembership_611297(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteEnvironmentMembership_611296(path: JsonNode; query: JsonNode;
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
  var valid_611298 = header.getOrDefault("X-Amz-Target")
  valid_611298 = validateParameter(valid_611298, JString, required = true, default = newJString(
      "AWSCloud9WorkspaceManagementService.DeleteEnvironmentMembership"))
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

proc call*(call_611307: Call_DeleteEnvironmentMembership_611295; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an environment member from an AWS Cloud9 development environment.
  ## 
  let valid = call_611307.validator(path, query, header, formData, body)
  let scheme = call_611307.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611307.url(scheme.get, call_611307.host, call_611307.base,
                         call_611307.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611307, url, valid)

proc call*(call_611308: Call_DeleteEnvironmentMembership_611295; body: JsonNode): Recallable =
  ## deleteEnvironmentMembership
  ## Deletes an environment member from an AWS Cloud9 development environment.
  ##   body: JObject (required)
  var body_611309 = newJObject()
  if body != nil:
    body_611309 = body
  result = call_611308.call(nil, nil, nil, nil, body_611309)

var deleteEnvironmentMembership* = Call_DeleteEnvironmentMembership_611295(
    name: "deleteEnvironmentMembership", meth: HttpMethod.HttpPost,
    host: "cloud9.amazonaws.com", route: "/#X-Amz-Target=AWSCloud9WorkspaceManagementService.DeleteEnvironmentMembership",
    validator: validate_DeleteEnvironmentMembership_611296, base: "/",
    url: url_DeleteEnvironmentMembership_611297,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEnvironmentMemberships_611310 = ref object of OpenApiRestCall_610658
proc url_DescribeEnvironmentMemberships_611312(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeEnvironmentMemberships_611311(path: JsonNode;
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
  var valid_611313 = query.getOrDefault("nextToken")
  valid_611313 = validateParameter(valid_611313, JString, required = false,
                                 default = nil)
  if valid_611313 != nil:
    section.add "nextToken", valid_611313
  var valid_611314 = query.getOrDefault("maxResults")
  valid_611314 = validateParameter(valid_611314, JString, required = false,
                                 default = nil)
  if valid_611314 != nil:
    section.add "maxResults", valid_611314
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
  var valid_611315 = header.getOrDefault("X-Amz-Target")
  valid_611315 = validateParameter(valid_611315, JString, required = true, default = newJString(
      "AWSCloud9WorkspaceManagementService.DescribeEnvironmentMemberships"))
  if valid_611315 != nil:
    section.add "X-Amz-Target", valid_611315
  var valid_611316 = header.getOrDefault("X-Amz-Signature")
  valid_611316 = validateParameter(valid_611316, JString, required = false,
                                 default = nil)
  if valid_611316 != nil:
    section.add "X-Amz-Signature", valid_611316
  var valid_611317 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611317 = validateParameter(valid_611317, JString, required = false,
                                 default = nil)
  if valid_611317 != nil:
    section.add "X-Amz-Content-Sha256", valid_611317
  var valid_611318 = header.getOrDefault("X-Amz-Date")
  valid_611318 = validateParameter(valid_611318, JString, required = false,
                                 default = nil)
  if valid_611318 != nil:
    section.add "X-Amz-Date", valid_611318
  var valid_611319 = header.getOrDefault("X-Amz-Credential")
  valid_611319 = validateParameter(valid_611319, JString, required = false,
                                 default = nil)
  if valid_611319 != nil:
    section.add "X-Amz-Credential", valid_611319
  var valid_611320 = header.getOrDefault("X-Amz-Security-Token")
  valid_611320 = validateParameter(valid_611320, JString, required = false,
                                 default = nil)
  if valid_611320 != nil:
    section.add "X-Amz-Security-Token", valid_611320
  var valid_611321 = header.getOrDefault("X-Amz-Algorithm")
  valid_611321 = validateParameter(valid_611321, JString, required = false,
                                 default = nil)
  if valid_611321 != nil:
    section.add "X-Amz-Algorithm", valid_611321
  var valid_611322 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611322 = validateParameter(valid_611322, JString, required = false,
                                 default = nil)
  if valid_611322 != nil:
    section.add "X-Amz-SignedHeaders", valid_611322
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611324: Call_DescribeEnvironmentMemberships_611310; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about environment members for an AWS Cloud9 development environment.
  ## 
  let valid = call_611324.validator(path, query, header, formData, body)
  let scheme = call_611324.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611324.url(scheme.get, call_611324.host, call_611324.base,
                         call_611324.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611324, url, valid)

proc call*(call_611325: Call_DescribeEnvironmentMemberships_611310; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## describeEnvironmentMemberships
  ## Gets information about environment members for an AWS Cloud9 development environment.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_611326 = newJObject()
  var body_611327 = newJObject()
  add(query_611326, "nextToken", newJString(nextToken))
  if body != nil:
    body_611327 = body
  add(query_611326, "maxResults", newJString(maxResults))
  result = call_611325.call(nil, query_611326, nil, nil, body_611327)

var describeEnvironmentMemberships* = Call_DescribeEnvironmentMemberships_611310(
    name: "describeEnvironmentMemberships", meth: HttpMethod.HttpPost,
    host: "cloud9.amazonaws.com", route: "/#X-Amz-Target=AWSCloud9WorkspaceManagementService.DescribeEnvironmentMemberships",
    validator: validate_DescribeEnvironmentMemberships_611311, base: "/",
    url: url_DescribeEnvironmentMemberships_611312,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEnvironmentStatus_611329 = ref object of OpenApiRestCall_610658
proc url_DescribeEnvironmentStatus_611331(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeEnvironmentStatus_611330(path: JsonNode; query: JsonNode;
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
  var valid_611332 = header.getOrDefault("X-Amz-Target")
  valid_611332 = validateParameter(valid_611332, JString, required = true, default = newJString(
      "AWSCloud9WorkspaceManagementService.DescribeEnvironmentStatus"))
  if valid_611332 != nil:
    section.add "X-Amz-Target", valid_611332
  var valid_611333 = header.getOrDefault("X-Amz-Signature")
  valid_611333 = validateParameter(valid_611333, JString, required = false,
                                 default = nil)
  if valid_611333 != nil:
    section.add "X-Amz-Signature", valid_611333
  var valid_611334 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611334 = validateParameter(valid_611334, JString, required = false,
                                 default = nil)
  if valid_611334 != nil:
    section.add "X-Amz-Content-Sha256", valid_611334
  var valid_611335 = header.getOrDefault("X-Amz-Date")
  valid_611335 = validateParameter(valid_611335, JString, required = false,
                                 default = nil)
  if valid_611335 != nil:
    section.add "X-Amz-Date", valid_611335
  var valid_611336 = header.getOrDefault("X-Amz-Credential")
  valid_611336 = validateParameter(valid_611336, JString, required = false,
                                 default = nil)
  if valid_611336 != nil:
    section.add "X-Amz-Credential", valid_611336
  var valid_611337 = header.getOrDefault("X-Amz-Security-Token")
  valid_611337 = validateParameter(valid_611337, JString, required = false,
                                 default = nil)
  if valid_611337 != nil:
    section.add "X-Amz-Security-Token", valid_611337
  var valid_611338 = header.getOrDefault("X-Amz-Algorithm")
  valid_611338 = validateParameter(valid_611338, JString, required = false,
                                 default = nil)
  if valid_611338 != nil:
    section.add "X-Amz-Algorithm", valid_611338
  var valid_611339 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611339 = validateParameter(valid_611339, JString, required = false,
                                 default = nil)
  if valid_611339 != nil:
    section.add "X-Amz-SignedHeaders", valid_611339
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611341: Call_DescribeEnvironmentStatus_611329; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets status information for an AWS Cloud9 development environment.
  ## 
  let valid = call_611341.validator(path, query, header, formData, body)
  let scheme = call_611341.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611341.url(scheme.get, call_611341.host, call_611341.base,
                         call_611341.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611341, url, valid)

proc call*(call_611342: Call_DescribeEnvironmentStatus_611329; body: JsonNode): Recallable =
  ## describeEnvironmentStatus
  ## Gets status information for an AWS Cloud9 development environment.
  ##   body: JObject (required)
  var body_611343 = newJObject()
  if body != nil:
    body_611343 = body
  result = call_611342.call(nil, nil, nil, nil, body_611343)

var describeEnvironmentStatus* = Call_DescribeEnvironmentStatus_611329(
    name: "describeEnvironmentStatus", meth: HttpMethod.HttpPost,
    host: "cloud9.amazonaws.com", route: "/#X-Amz-Target=AWSCloud9WorkspaceManagementService.DescribeEnvironmentStatus",
    validator: validate_DescribeEnvironmentStatus_611330, base: "/",
    url: url_DescribeEnvironmentStatus_611331,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEnvironments_611344 = ref object of OpenApiRestCall_610658
proc url_DescribeEnvironments_611346(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeEnvironments_611345(path: JsonNode; query: JsonNode;
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
  var valid_611347 = header.getOrDefault("X-Amz-Target")
  valid_611347 = validateParameter(valid_611347, JString, required = true, default = newJString(
      "AWSCloud9WorkspaceManagementService.DescribeEnvironments"))
  if valid_611347 != nil:
    section.add "X-Amz-Target", valid_611347
  var valid_611348 = header.getOrDefault("X-Amz-Signature")
  valid_611348 = validateParameter(valid_611348, JString, required = false,
                                 default = nil)
  if valid_611348 != nil:
    section.add "X-Amz-Signature", valid_611348
  var valid_611349 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611349 = validateParameter(valid_611349, JString, required = false,
                                 default = nil)
  if valid_611349 != nil:
    section.add "X-Amz-Content-Sha256", valid_611349
  var valid_611350 = header.getOrDefault("X-Amz-Date")
  valid_611350 = validateParameter(valid_611350, JString, required = false,
                                 default = nil)
  if valid_611350 != nil:
    section.add "X-Amz-Date", valid_611350
  var valid_611351 = header.getOrDefault("X-Amz-Credential")
  valid_611351 = validateParameter(valid_611351, JString, required = false,
                                 default = nil)
  if valid_611351 != nil:
    section.add "X-Amz-Credential", valid_611351
  var valid_611352 = header.getOrDefault("X-Amz-Security-Token")
  valid_611352 = validateParameter(valid_611352, JString, required = false,
                                 default = nil)
  if valid_611352 != nil:
    section.add "X-Amz-Security-Token", valid_611352
  var valid_611353 = header.getOrDefault("X-Amz-Algorithm")
  valid_611353 = validateParameter(valid_611353, JString, required = false,
                                 default = nil)
  if valid_611353 != nil:
    section.add "X-Amz-Algorithm", valid_611353
  var valid_611354 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611354 = validateParameter(valid_611354, JString, required = false,
                                 default = nil)
  if valid_611354 != nil:
    section.add "X-Amz-SignedHeaders", valid_611354
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611356: Call_DescribeEnvironments_611344; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about AWS Cloud9 development environments.
  ## 
  let valid = call_611356.validator(path, query, header, formData, body)
  let scheme = call_611356.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611356.url(scheme.get, call_611356.host, call_611356.base,
                         call_611356.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611356, url, valid)

proc call*(call_611357: Call_DescribeEnvironments_611344; body: JsonNode): Recallable =
  ## describeEnvironments
  ## Gets information about AWS Cloud9 development environments.
  ##   body: JObject (required)
  var body_611358 = newJObject()
  if body != nil:
    body_611358 = body
  result = call_611357.call(nil, nil, nil, nil, body_611358)

var describeEnvironments* = Call_DescribeEnvironments_611344(
    name: "describeEnvironments", meth: HttpMethod.HttpPost,
    host: "cloud9.amazonaws.com", route: "/#X-Amz-Target=AWSCloud9WorkspaceManagementService.DescribeEnvironments",
    validator: validate_DescribeEnvironments_611345, base: "/",
    url: url_DescribeEnvironments_611346, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListEnvironments_611359 = ref object of OpenApiRestCall_610658
proc url_ListEnvironments_611361(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListEnvironments_611360(path: JsonNode; query: JsonNode;
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
  var valid_611362 = query.getOrDefault("nextToken")
  valid_611362 = validateParameter(valid_611362, JString, required = false,
                                 default = nil)
  if valid_611362 != nil:
    section.add "nextToken", valid_611362
  var valid_611363 = query.getOrDefault("maxResults")
  valid_611363 = validateParameter(valid_611363, JString, required = false,
                                 default = nil)
  if valid_611363 != nil:
    section.add "maxResults", valid_611363
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
  var valid_611364 = header.getOrDefault("X-Amz-Target")
  valid_611364 = validateParameter(valid_611364, JString, required = true, default = newJString(
      "AWSCloud9WorkspaceManagementService.ListEnvironments"))
  if valid_611364 != nil:
    section.add "X-Amz-Target", valid_611364
  var valid_611365 = header.getOrDefault("X-Amz-Signature")
  valid_611365 = validateParameter(valid_611365, JString, required = false,
                                 default = nil)
  if valid_611365 != nil:
    section.add "X-Amz-Signature", valid_611365
  var valid_611366 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611366 = validateParameter(valid_611366, JString, required = false,
                                 default = nil)
  if valid_611366 != nil:
    section.add "X-Amz-Content-Sha256", valid_611366
  var valid_611367 = header.getOrDefault("X-Amz-Date")
  valid_611367 = validateParameter(valid_611367, JString, required = false,
                                 default = nil)
  if valid_611367 != nil:
    section.add "X-Amz-Date", valid_611367
  var valid_611368 = header.getOrDefault("X-Amz-Credential")
  valid_611368 = validateParameter(valid_611368, JString, required = false,
                                 default = nil)
  if valid_611368 != nil:
    section.add "X-Amz-Credential", valid_611368
  var valid_611369 = header.getOrDefault("X-Amz-Security-Token")
  valid_611369 = validateParameter(valid_611369, JString, required = false,
                                 default = nil)
  if valid_611369 != nil:
    section.add "X-Amz-Security-Token", valid_611369
  var valid_611370 = header.getOrDefault("X-Amz-Algorithm")
  valid_611370 = validateParameter(valid_611370, JString, required = false,
                                 default = nil)
  if valid_611370 != nil:
    section.add "X-Amz-Algorithm", valid_611370
  var valid_611371 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611371 = validateParameter(valid_611371, JString, required = false,
                                 default = nil)
  if valid_611371 != nil:
    section.add "X-Amz-SignedHeaders", valid_611371
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611373: Call_ListEnvironments_611359; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a list of AWS Cloud9 development environment identifiers.
  ## 
  let valid = call_611373.validator(path, query, header, formData, body)
  let scheme = call_611373.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611373.url(scheme.get, call_611373.host, call_611373.base,
                         call_611373.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611373, url, valid)

proc call*(call_611374: Call_ListEnvironments_611359; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listEnvironments
  ## Gets a list of AWS Cloud9 development environment identifiers.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_611375 = newJObject()
  var body_611376 = newJObject()
  add(query_611375, "nextToken", newJString(nextToken))
  if body != nil:
    body_611376 = body
  add(query_611375, "maxResults", newJString(maxResults))
  result = call_611374.call(nil, query_611375, nil, nil, body_611376)

var listEnvironments* = Call_ListEnvironments_611359(name: "listEnvironments",
    meth: HttpMethod.HttpPost, host: "cloud9.amazonaws.com", route: "/#X-Amz-Target=AWSCloud9WorkspaceManagementService.ListEnvironments",
    validator: validate_ListEnvironments_611360, base: "/",
    url: url_ListEnvironments_611361, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_611377 = ref object of OpenApiRestCall_610658
proc url_ListTagsForResource_611379(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTagsForResource_611378(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Gets a list of the tags associated with an AWS Cloud9 development environment.
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
  var valid_611380 = header.getOrDefault("X-Amz-Target")
  valid_611380 = validateParameter(valid_611380, JString, required = true, default = newJString(
      "AWSCloud9WorkspaceManagementService.ListTagsForResource"))
  if valid_611380 != nil:
    section.add "X-Amz-Target", valid_611380
  var valid_611381 = header.getOrDefault("X-Amz-Signature")
  valid_611381 = validateParameter(valid_611381, JString, required = false,
                                 default = nil)
  if valid_611381 != nil:
    section.add "X-Amz-Signature", valid_611381
  var valid_611382 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611382 = validateParameter(valid_611382, JString, required = false,
                                 default = nil)
  if valid_611382 != nil:
    section.add "X-Amz-Content-Sha256", valid_611382
  var valid_611383 = header.getOrDefault("X-Amz-Date")
  valid_611383 = validateParameter(valid_611383, JString, required = false,
                                 default = nil)
  if valid_611383 != nil:
    section.add "X-Amz-Date", valid_611383
  var valid_611384 = header.getOrDefault("X-Amz-Credential")
  valid_611384 = validateParameter(valid_611384, JString, required = false,
                                 default = nil)
  if valid_611384 != nil:
    section.add "X-Amz-Credential", valid_611384
  var valid_611385 = header.getOrDefault("X-Amz-Security-Token")
  valid_611385 = validateParameter(valid_611385, JString, required = false,
                                 default = nil)
  if valid_611385 != nil:
    section.add "X-Amz-Security-Token", valid_611385
  var valid_611386 = header.getOrDefault("X-Amz-Algorithm")
  valid_611386 = validateParameter(valid_611386, JString, required = false,
                                 default = nil)
  if valid_611386 != nil:
    section.add "X-Amz-Algorithm", valid_611386
  var valid_611387 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611387 = validateParameter(valid_611387, JString, required = false,
                                 default = nil)
  if valid_611387 != nil:
    section.add "X-Amz-SignedHeaders", valid_611387
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611389: Call_ListTagsForResource_611377; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a list of the tags associated with an AWS Cloud9 development environment.
  ## 
  let valid = call_611389.validator(path, query, header, formData, body)
  let scheme = call_611389.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611389.url(scheme.get, call_611389.host, call_611389.base,
                         call_611389.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611389, url, valid)

proc call*(call_611390: Call_ListTagsForResource_611377; body: JsonNode): Recallable =
  ## listTagsForResource
  ## Gets a list of the tags associated with an AWS Cloud9 development environment.
  ##   body: JObject (required)
  var body_611391 = newJObject()
  if body != nil:
    body_611391 = body
  result = call_611390.call(nil, nil, nil, nil, body_611391)

var listTagsForResource* = Call_ListTagsForResource_611377(
    name: "listTagsForResource", meth: HttpMethod.HttpPost,
    host: "cloud9.amazonaws.com", route: "/#X-Amz-Target=AWSCloud9WorkspaceManagementService.ListTagsForResource",
    validator: validate_ListTagsForResource_611378, base: "/",
    url: url_ListTagsForResource_611379, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_611392 = ref object of OpenApiRestCall_610658
proc url_TagResource_611394(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_TagResource_611393(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Adds tags to an AWS Cloud9 development environment.</p> <important> <p>Tags that you add to an AWS Cloud9 environment by using this method will NOT be automatically propagated to underlying resources.</p> </important>
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
  var valid_611395 = header.getOrDefault("X-Amz-Target")
  valid_611395 = validateParameter(valid_611395, JString, required = true, default = newJString(
      "AWSCloud9WorkspaceManagementService.TagResource"))
  if valid_611395 != nil:
    section.add "X-Amz-Target", valid_611395
  var valid_611396 = header.getOrDefault("X-Amz-Signature")
  valid_611396 = validateParameter(valid_611396, JString, required = false,
                                 default = nil)
  if valid_611396 != nil:
    section.add "X-Amz-Signature", valid_611396
  var valid_611397 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611397 = validateParameter(valid_611397, JString, required = false,
                                 default = nil)
  if valid_611397 != nil:
    section.add "X-Amz-Content-Sha256", valid_611397
  var valid_611398 = header.getOrDefault("X-Amz-Date")
  valid_611398 = validateParameter(valid_611398, JString, required = false,
                                 default = nil)
  if valid_611398 != nil:
    section.add "X-Amz-Date", valid_611398
  var valid_611399 = header.getOrDefault("X-Amz-Credential")
  valid_611399 = validateParameter(valid_611399, JString, required = false,
                                 default = nil)
  if valid_611399 != nil:
    section.add "X-Amz-Credential", valid_611399
  var valid_611400 = header.getOrDefault("X-Amz-Security-Token")
  valid_611400 = validateParameter(valid_611400, JString, required = false,
                                 default = nil)
  if valid_611400 != nil:
    section.add "X-Amz-Security-Token", valid_611400
  var valid_611401 = header.getOrDefault("X-Amz-Algorithm")
  valid_611401 = validateParameter(valid_611401, JString, required = false,
                                 default = nil)
  if valid_611401 != nil:
    section.add "X-Amz-Algorithm", valid_611401
  var valid_611402 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611402 = validateParameter(valid_611402, JString, required = false,
                                 default = nil)
  if valid_611402 != nil:
    section.add "X-Amz-SignedHeaders", valid_611402
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611404: Call_TagResource_611392; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds tags to an AWS Cloud9 development environment.</p> <important> <p>Tags that you add to an AWS Cloud9 environment by using this method will NOT be automatically propagated to underlying resources.</p> </important>
  ## 
  let valid = call_611404.validator(path, query, header, formData, body)
  let scheme = call_611404.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611404.url(scheme.get, call_611404.host, call_611404.base,
                         call_611404.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611404, url, valid)

proc call*(call_611405: Call_TagResource_611392; body: JsonNode): Recallable =
  ## tagResource
  ## <p>Adds tags to an AWS Cloud9 development environment.</p> <important> <p>Tags that you add to an AWS Cloud9 environment by using this method will NOT be automatically propagated to underlying resources.</p> </important>
  ##   body: JObject (required)
  var body_611406 = newJObject()
  if body != nil:
    body_611406 = body
  result = call_611405.call(nil, nil, nil, nil, body_611406)

var tagResource* = Call_TagResource_611392(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "cloud9.amazonaws.com", route: "/#X-Amz-Target=AWSCloud9WorkspaceManagementService.TagResource",
                                        validator: validate_TagResource_611393,
                                        base: "/", url: url_TagResource_611394,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_611407 = ref object of OpenApiRestCall_610658
proc url_UntagResource_611409(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UntagResource_611408(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Removes tags from an AWS Cloud9 development environment.
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
  var valid_611410 = header.getOrDefault("X-Amz-Target")
  valid_611410 = validateParameter(valid_611410, JString, required = true, default = newJString(
      "AWSCloud9WorkspaceManagementService.UntagResource"))
  if valid_611410 != nil:
    section.add "X-Amz-Target", valid_611410
  var valid_611411 = header.getOrDefault("X-Amz-Signature")
  valid_611411 = validateParameter(valid_611411, JString, required = false,
                                 default = nil)
  if valid_611411 != nil:
    section.add "X-Amz-Signature", valid_611411
  var valid_611412 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611412 = validateParameter(valid_611412, JString, required = false,
                                 default = nil)
  if valid_611412 != nil:
    section.add "X-Amz-Content-Sha256", valid_611412
  var valid_611413 = header.getOrDefault("X-Amz-Date")
  valid_611413 = validateParameter(valid_611413, JString, required = false,
                                 default = nil)
  if valid_611413 != nil:
    section.add "X-Amz-Date", valid_611413
  var valid_611414 = header.getOrDefault("X-Amz-Credential")
  valid_611414 = validateParameter(valid_611414, JString, required = false,
                                 default = nil)
  if valid_611414 != nil:
    section.add "X-Amz-Credential", valid_611414
  var valid_611415 = header.getOrDefault("X-Amz-Security-Token")
  valid_611415 = validateParameter(valid_611415, JString, required = false,
                                 default = nil)
  if valid_611415 != nil:
    section.add "X-Amz-Security-Token", valid_611415
  var valid_611416 = header.getOrDefault("X-Amz-Algorithm")
  valid_611416 = validateParameter(valid_611416, JString, required = false,
                                 default = nil)
  if valid_611416 != nil:
    section.add "X-Amz-Algorithm", valid_611416
  var valid_611417 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611417 = validateParameter(valid_611417, JString, required = false,
                                 default = nil)
  if valid_611417 != nil:
    section.add "X-Amz-SignedHeaders", valid_611417
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611419: Call_UntagResource_611407; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes tags from an AWS Cloud9 development environment.
  ## 
  let valid = call_611419.validator(path, query, header, formData, body)
  let scheme = call_611419.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611419.url(scheme.get, call_611419.host, call_611419.base,
                         call_611419.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611419, url, valid)

proc call*(call_611420: Call_UntagResource_611407; body: JsonNode): Recallable =
  ## untagResource
  ## Removes tags from an AWS Cloud9 development environment.
  ##   body: JObject (required)
  var body_611421 = newJObject()
  if body != nil:
    body_611421 = body
  result = call_611420.call(nil, nil, nil, nil, body_611421)

var untagResource* = Call_UntagResource_611407(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "cloud9.amazonaws.com",
    route: "/#X-Amz-Target=AWSCloud9WorkspaceManagementService.UntagResource",
    validator: validate_UntagResource_611408, base: "/", url: url_UntagResource_611409,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateEnvironment_611422 = ref object of OpenApiRestCall_610658
proc url_UpdateEnvironment_611424(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateEnvironment_611423(path: JsonNode; query: JsonNode;
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
  var valid_611425 = header.getOrDefault("X-Amz-Target")
  valid_611425 = validateParameter(valid_611425, JString, required = true, default = newJString(
      "AWSCloud9WorkspaceManagementService.UpdateEnvironment"))
  if valid_611425 != nil:
    section.add "X-Amz-Target", valid_611425
  var valid_611426 = header.getOrDefault("X-Amz-Signature")
  valid_611426 = validateParameter(valid_611426, JString, required = false,
                                 default = nil)
  if valid_611426 != nil:
    section.add "X-Amz-Signature", valid_611426
  var valid_611427 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611427 = validateParameter(valid_611427, JString, required = false,
                                 default = nil)
  if valid_611427 != nil:
    section.add "X-Amz-Content-Sha256", valid_611427
  var valid_611428 = header.getOrDefault("X-Amz-Date")
  valid_611428 = validateParameter(valid_611428, JString, required = false,
                                 default = nil)
  if valid_611428 != nil:
    section.add "X-Amz-Date", valid_611428
  var valid_611429 = header.getOrDefault("X-Amz-Credential")
  valid_611429 = validateParameter(valid_611429, JString, required = false,
                                 default = nil)
  if valid_611429 != nil:
    section.add "X-Amz-Credential", valid_611429
  var valid_611430 = header.getOrDefault("X-Amz-Security-Token")
  valid_611430 = validateParameter(valid_611430, JString, required = false,
                                 default = nil)
  if valid_611430 != nil:
    section.add "X-Amz-Security-Token", valid_611430
  var valid_611431 = header.getOrDefault("X-Amz-Algorithm")
  valid_611431 = validateParameter(valid_611431, JString, required = false,
                                 default = nil)
  if valid_611431 != nil:
    section.add "X-Amz-Algorithm", valid_611431
  var valid_611432 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611432 = validateParameter(valid_611432, JString, required = false,
                                 default = nil)
  if valid_611432 != nil:
    section.add "X-Amz-SignedHeaders", valid_611432
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611434: Call_UpdateEnvironment_611422; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes the settings of an existing AWS Cloud9 development environment.
  ## 
  let valid = call_611434.validator(path, query, header, formData, body)
  let scheme = call_611434.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611434.url(scheme.get, call_611434.host, call_611434.base,
                         call_611434.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611434, url, valid)

proc call*(call_611435: Call_UpdateEnvironment_611422; body: JsonNode): Recallable =
  ## updateEnvironment
  ## Changes the settings of an existing AWS Cloud9 development environment.
  ##   body: JObject (required)
  var body_611436 = newJObject()
  if body != nil:
    body_611436 = body
  result = call_611435.call(nil, nil, nil, nil, body_611436)

var updateEnvironment* = Call_UpdateEnvironment_611422(name: "updateEnvironment",
    meth: HttpMethod.HttpPost, host: "cloud9.amazonaws.com", route: "/#X-Amz-Target=AWSCloud9WorkspaceManagementService.UpdateEnvironment",
    validator: validate_UpdateEnvironment_611423, base: "/",
    url: url_UpdateEnvironment_611424, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateEnvironmentMembership_611437 = ref object of OpenApiRestCall_610658
proc url_UpdateEnvironmentMembership_611439(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateEnvironmentMembership_611438(path: JsonNode; query: JsonNode;
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
  var valid_611440 = header.getOrDefault("X-Amz-Target")
  valid_611440 = validateParameter(valid_611440, JString, required = true, default = newJString(
      "AWSCloud9WorkspaceManagementService.UpdateEnvironmentMembership"))
  if valid_611440 != nil:
    section.add "X-Amz-Target", valid_611440
  var valid_611441 = header.getOrDefault("X-Amz-Signature")
  valid_611441 = validateParameter(valid_611441, JString, required = false,
                                 default = nil)
  if valid_611441 != nil:
    section.add "X-Amz-Signature", valid_611441
  var valid_611442 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611442 = validateParameter(valid_611442, JString, required = false,
                                 default = nil)
  if valid_611442 != nil:
    section.add "X-Amz-Content-Sha256", valid_611442
  var valid_611443 = header.getOrDefault("X-Amz-Date")
  valid_611443 = validateParameter(valid_611443, JString, required = false,
                                 default = nil)
  if valid_611443 != nil:
    section.add "X-Amz-Date", valid_611443
  var valid_611444 = header.getOrDefault("X-Amz-Credential")
  valid_611444 = validateParameter(valid_611444, JString, required = false,
                                 default = nil)
  if valid_611444 != nil:
    section.add "X-Amz-Credential", valid_611444
  var valid_611445 = header.getOrDefault("X-Amz-Security-Token")
  valid_611445 = validateParameter(valid_611445, JString, required = false,
                                 default = nil)
  if valid_611445 != nil:
    section.add "X-Amz-Security-Token", valid_611445
  var valid_611446 = header.getOrDefault("X-Amz-Algorithm")
  valid_611446 = validateParameter(valid_611446, JString, required = false,
                                 default = nil)
  if valid_611446 != nil:
    section.add "X-Amz-Algorithm", valid_611446
  var valid_611447 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611447 = validateParameter(valid_611447, JString, required = false,
                                 default = nil)
  if valid_611447 != nil:
    section.add "X-Amz-SignedHeaders", valid_611447
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611449: Call_UpdateEnvironmentMembership_611437; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes the settings of an existing environment member for an AWS Cloud9 development environment.
  ## 
  let valid = call_611449.validator(path, query, header, formData, body)
  let scheme = call_611449.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611449.url(scheme.get, call_611449.host, call_611449.base,
                         call_611449.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611449, url, valid)

proc call*(call_611450: Call_UpdateEnvironmentMembership_611437; body: JsonNode): Recallable =
  ## updateEnvironmentMembership
  ## Changes the settings of an existing environment member for an AWS Cloud9 development environment.
  ##   body: JObject (required)
  var body_611451 = newJObject()
  if body != nil:
    body_611451 = body
  result = call_611450.call(nil, nil, nil, nil, body_611451)

var updateEnvironmentMembership* = Call_UpdateEnvironmentMembership_611437(
    name: "updateEnvironmentMembership", meth: HttpMethod.HttpPost,
    host: "cloud9.amazonaws.com", route: "/#X-Amz-Target=AWSCloud9WorkspaceManagementService.UpdateEnvironmentMembership",
    validator: validate_UpdateEnvironmentMembership_611438, base: "/",
    url: url_UpdateEnvironmentMembership_611439,
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
