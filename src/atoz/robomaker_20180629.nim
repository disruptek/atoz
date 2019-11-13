
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: AWS RoboMaker
## version: 2018-06-29
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## This section provides documentation for the AWS RoboMaker API operations.
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/robomaker/
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

  OpenApiRestCall_593389 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_593389](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_593389): Option[Scheme] {.used.} =
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "robomaker.ap-northeast-1.amazonaws.com", "ap-southeast-1": "robomaker.ap-southeast-1.amazonaws.com",
                           "us-west-2": "robomaker.us-west-2.amazonaws.com",
                           "eu-west-2": "robomaker.eu-west-2.amazonaws.com", "ap-northeast-3": "robomaker.ap-northeast-3.amazonaws.com", "eu-central-1": "robomaker.eu-central-1.amazonaws.com",
                           "us-east-2": "robomaker.us-east-2.amazonaws.com",
                           "us-east-1": "robomaker.us-east-1.amazonaws.com", "cn-northwest-1": "robomaker.cn-northwest-1.amazonaws.com.cn",
                           "ap-south-1": "robomaker.ap-south-1.amazonaws.com",
                           "eu-north-1": "robomaker.eu-north-1.amazonaws.com", "ap-northeast-2": "robomaker.ap-northeast-2.amazonaws.com",
                           "us-west-1": "robomaker.us-west-1.amazonaws.com", "us-gov-east-1": "robomaker.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "robomaker.eu-west-3.amazonaws.com", "cn-north-1": "robomaker.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "robomaker.sa-east-1.amazonaws.com",
                           "eu-west-1": "robomaker.eu-west-1.amazonaws.com", "us-gov-west-1": "robomaker.us-gov-west-1.amazonaws.com", "ap-southeast-2": "robomaker.ap-southeast-2.amazonaws.com", "ca-central-1": "robomaker.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "robomaker.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "robomaker.ap-southeast-1.amazonaws.com",
      "us-west-2": "robomaker.us-west-2.amazonaws.com",
      "eu-west-2": "robomaker.eu-west-2.amazonaws.com",
      "ap-northeast-3": "robomaker.ap-northeast-3.amazonaws.com",
      "eu-central-1": "robomaker.eu-central-1.amazonaws.com",
      "us-east-2": "robomaker.us-east-2.amazonaws.com",
      "us-east-1": "robomaker.us-east-1.amazonaws.com",
      "cn-northwest-1": "robomaker.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "robomaker.ap-south-1.amazonaws.com",
      "eu-north-1": "robomaker.eu-north-1.amazonaws.com",
      "ap-northeast-2": "robomaker.ap-northeast-2.amazonaws.com",
      "us-west-1": "robomaker.us-west-1.amazonaws.com",
      "us-gov-east-1": "robomaker.us-gov-east-1.amazonaws.com",
      "eu-west-3": "robomaker.eu-west-3.amazonaws.com",
      "cn-north-1": "robomaker.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "robomaker.sa-east-1.amazonaws.com",
      "eu-west-1": "robomaker.eu-west-1.amazonaws.com",
      "us-gov-west-1": "robomaker.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "robomaker.ap-southeast-2.amazonaws.com",
      "ca-central-1": "robomaker.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "robomaker"
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_BatchDescribeSimulationJob_593727 = ref object of OpenApiRestCall_593389
proc url_BatchDescribeSimulationJob_593729(protocol: Scheme; host: string;
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

proc validate_BatchDescribeSimulationJob_593728(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Describes one or more simulation jobs.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593841 = header.getOrDefault("X-Amz-Signature")
  valid_593841 = validateParameter(valid_593841, JString, required = false,
                                 default = nil)
  if valid_593841 != nil:
    section.add "X-Amz-Signature", valid_593841
  var valid_593842 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593842 = validateParameter(valid_593842, JString, required = false,
                                 default = nil)
  if valid_593842 != nil:
    section.add "X-Amz-Content-Sha256", valid_593842
  var valid_593843 = header.getOrDefault("X-Amz-Date")
  valid_593843 = validateParameter(valid_593843, JString, required = false,
                                 default = nil)
  if valid_593843 != nil:
    section.add "X-Amz-Date", valid_593843
  var valid_593844 = header.getOrDefault("X-Amz-Credential")
  valid_593844 = validateParameter(valid_593844, JString, required = false,
                                 default = nil)
  if valid_593844 != nil:
    section.add "X-Amz-Credential", valid_593844
  var valid_593845 = header.getOrDefault("X-Amz-Security-Token")
  valid_593845 = validateParameter(valid_593845, JString, required = false,
                                 default = nil)
  if valid_593845 != nil:
    section.add "X-Amz-Security-Token", valid_593845
  var valid_593846 = header.getOrDefault("X-Amz-Algorithm")
  valid_593846 = validateParameter(valid_593846, JString, required = false,
                                 default = nil)
  if valid_593846 != nil:
    section.add "X-Amz-Algorithm", valid_593846
  var valid_593847 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593847 = validateParameter(valid_593847, JString, required = false,
                                 default = nil)
  if valid_593847 != nil:
    section.add "X-Amz-SignedHeaders", valid_593847
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593871: Call_BatchDescribeSimulationJob_593727; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes one or more simulation jobs.
  ## 
  let valid = call_593871.validator(path, query, header, formData, body)
  let scheme = call_593871.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593871.url(scheme.get, call_593871.host, call_593871.base,
                         call_593871.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593871, url, valid)

proc call*(call_593942: Call_BatchDescribeSimulationJob_593727; body: JsonNode): Recallable =
  ## batchDescribeSimulationJob
  ## Describes one or more simulation jobs.
  ##   body: JObject (required)
  var body_593943 = newJObject()
  if body != nil:
    body_593943 = body
  result = call_593942.call(nil, nil, nil, nil, body_593943)

var batchDescribeSimulationJob* = Call_BatchDescribeSimulationJob_593727(
    name: "batchDescribeSimulationJob", meth: HttpMethod.HttpPost,
    host: "robomaker.amazonaws.com", route: "/batchDescribeSimulationJob",
    validator: validate_BatchDescribeSimulationJob_593728, base: "/",
    url: url_BatchDescribeSimulationJob_593729,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CancelDeploymentJob_593982 = ref object of OpenApiRestCall_593389
proc url_CancelDeploymentJob_593984(protocol: Scheme; host: string; base: string;
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

proc validate_CancelDeploymentJob_593983(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Cancels the specified deployment job.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593985 = header.getOrDefault("X-Amz-Signature")
  valid_593985 = validateParameter(valid_593985, JString, required = false,
                                 default = nil)
  if valid_593985 != nil:
    section.add "X-Amz-Signature", valid_593985
  var valid_593986 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593986 = validateParameter(valid_593986, JString, required = false,
                                 default = nil)
  if valid_593986 != nil:
    section.add "X-Amz-Content-Sha256", valid_593986
  var valid_593987 = header.getOrDefault("X-Amz-Date")
  valid_593987 = validateParameter(valid_593987, JString, required = false,
                                 default = nil)
  if valid_593987 != nil:
    section.add "X-Amz-Date", valid_593987
  var valid_593988 = header.getOrDefault("X-Amz-Credential")
  valid_593988 = validateParameter(valid_593988, JString, required = false,
                                 default = nil)
  if valid_593988 != nil:
    section.add "X-Amz-Credential", valid_593988
  var valid_593989 = header.getOrDefault("X-Amz-Security-Token")
  valid_593989 = validateParameter(valid_593989, JString, required = false,
                                 default = nil)
  if valid_593989 != nil:
    section.add "X-Amz-Security-Token", valid_593989
  var valid_593990 = header.getOrDefault("X-Amz-Algorithm")
  valid_593990 = validateParameter(valid_593990, JString, required = false,
                                 default = nil)
  if valid_593990 != nil:
    section.add "X-Amz-Algorithm", valid_593990
  var valid_593991 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593991 = validateParameter(valid_593991, JString, required = false,
                                 default = nil)
  if valid_593991 != nil:
    section.add "X-Amz-SignedHeaders", valid_593991
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593993: Call_CancelDeploymentJob_593982; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Cancels the specified deployment job.
  ## 
  let valid = call_593993.validator(path, query, header, formData, body)
  let scheme = call_593993.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593993.url(scheme.get, call_593993.host, call_593993.base,
                         call_593993.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593993, url, valid)

proc call*(call_593994: Call_CancelDeploymentJob_593982; body: JsonNode): Recallable =
  ## cancelDeploymentJob
  ## Cancels the specified deployment job.
  ##   body: JObject (required)
  var body_593995 = newJObject()
  if body != nil:
    body_593995 = body
  result = call_593994.call(nil, nil, nil, nil, body_593995)

var cancelDeploymentJob* = Call_CancelDeploymentJob_593982(
    name: "cancelDeploymentJob", meth: HttpMethod.HttpPost,
    host: "robomaker.amazonaws.com", route: "/cancelDeploymentJob",
    validator: validate_CancelDeploymentJob_593983, base: "/",
    url: url_CancelDeploymentJob_593984, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CancelSimulationJob_593996 = ref object of OpenApiRestCall_593389
proc url_CancelSimulationJob_593998(protocol: Scheme; host: string; base: string;
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

proc validate_CancelSimulationJob_593997(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Cancels the specified simulation job.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593999 = header.getOrDefault("X-Amz-Signature")
  valid_593999 = validateParameter(valid_593999, JString, required = false,
                                 default = nil)
  if valid_593999 != nil:
    section.add "X-Amz-Signature", valid_593999
  var valid_594000 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594000 = validateParameter(valid_594000, JString, required = false,
                                 default = nil)
  if valid_594000 != nil:
    section.add "X-Amz-Content-Sha256", valid_594000
  var valid_594001 = header.getOrDefault("X-Amz-Date")
  valid_594001 = validateParameter(valid_594001, JString, required = false,
                                 default = nil)
  if valid_594001 != nil:
    section.add "X-Amz-Date", valid_594001
  var valid_594002 = header.getOrDefault("X-Amz-Credential")
  valid_594002 = validateParameter(valid_594002, JString, required = false,
                                 default = nil)
  if valid_594002 != nil:
    section.add "X-Amz-Credential", valid_594002
  var valid_594003 = header.getOrDefault("X-Amz-Security-Token")
  valid_594003 = validateParameter(valid_594003, JString, required = false,
                                 default = nil)
  if valid_594003 != nil:
    section.add "X-Amz-Security-Token", valid_594003
  var valid_594004 = header.getOrDefault("X-Amz-Algorithm")
  valid_594004 = validateParameter(valid_594004, JString, required = false,
                                 default = nil)
  if valid_594004 != nil:
    section.add "X-Amz-Algorithm", valid_594004
  var valid_594005 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594005 = validateParameter(valid_594005, JString, required = false,
                                 default = nil)
  if valid_594005 != nil:
    section.add "X-Amz-SignedHeaders", valid_594005
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594007: Call_CancelSimulationJob_593996; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Cancels the specified simulation job.
  ## 
  let valid = call_594007.validator(path, query, header, formData, body)
  let scheme = call_594007.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594007.url(scheme.get, call_594007.host, call_594007.base,
                         call_594007.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594007, url, valid)

proc call*(call_594008: Call_CancelSimulationJob_593996; body: JsonNode): Recallable =
  ## cancelSimulationJob
  ## Cancels the specified simulation job.
  ##   body: JObject (required)
  var body_594009 = newJObject()
  if body != nil:
    body_594009 = body
  result = call_594008.call(nil, nil, nil, nil, body_594009)

var cancelSimulationJob* = Call_CancelSimulationJob_593996(
    name: "cancelSimulationJob", meth: HttpMethod.HttpPost,
    host: "robomaker.amazonaws.com", route: "/cancelSimulationJob",
    validator: validate_CancelSimulationJob_593997, base: "/",
    url: url_CancelSimulationJob_593998, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDeploymentJob_594010 = ref object of OpenApiRestCall_593389
proc url_CreateDeploymentJob_594012(protocol: Scheme; host: string; base: string;
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

proc validate_CreateDeploymentJob_594011(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p>Deploys a specific version of a robot application to robots in a fleet.</p> <p>The robot application must have a numbered <code>applicationVersion</code> for consistency reasons. To create a new version, use <code>CreateRobotApplicationVersion</code> or see <a href="https://docs.aws.amazon.com/robomaker/latest/dg/create-robot-application-version.html">Creating a Robot Application Version</a>. </p> <note> <p>After 90 days, deployment jobs expire and will be deleted. They will no longer be accessible. </p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594013 = header.getOrDefault("X-Amz-Signature")
  valid_594013 = validateParameter(valid_594013, JString, required = false,
                                 default = nil)
  if valid_594013 != nil:
    section.add "X-Amz-Signature", valid_594013
  var valid_594014 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594014 = validateParameter(valid_594014, JString, required = false,
                                 default = nil)
  if valid_594014 != nil:
    section.add "X-Amz-Content-Sha256", valid_594014
  var valid_594015 = header.getOrDefault("X-Amz-Date")
  valid_594015 = validateParameter(valid_594015, JString, required = false,
                                 default = nil)
  if valid_594015 != nil:
    section.add "X-Amz-Date", valid_594015
  var valid_594016 = header.getOrDefault("X-Amz-Credential")
  valid_594016 = validateParameter(valid_594016, JString, required = false,
                                 default = nil)
  if valid_594016 != nil:
    section.add "X-Amz-Credential", valid_594016
  var valid_594017 = header.getOrDefault("X-Amz-Security-Token")
  valid_594017 = validateParameter(valid_594017, JString, required = false,
                                 default = nil)
  if valid_594017 != nil:
    section.add "X-Amz-Security-Token", valid_594017
  var valid_594018 = header.getOrDefault("X-Amz-Algorithm")
  valid_594018 = validateParameter(valid_594018, JString, required = false,
                                 default = nil)
  if valid_594018 != nil:
    section.add "X-Amz-Algorithm", valid_594018
  var valid_594019 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594019 = validateParameter(valid_594019, JString, required = false,
                                 default = nil)
  if valid_594019 != nil:
    section.add "X-Amz-SignedHeaders", valid_594019
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594021: Call_CreateDeploymentJob_594010; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deploys a specific version of a robot application to robots in a fleet.</p> <p>The robot application must have a numbered <code>applicationVersion</code> for consistency reasons. To create a new version, use <code>CreateRobotApplicationVersion</code> or see <a href="https://docs.aws.amazon.com/robomaker/latest/dg/create-robot-application-version.html">Creating a Robot Application Version</a>. </p> <note> <p>After 90 days, deployment jobs expire and will be deleted. They will no longer be accessible. </p> </note>
  ## 
  let valid = call_594021.validator(path, query, header, formData, body)
  let scheme = call_594021.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594021.url(scheme.get, call_594021.host, call_594021.base,
                         call_594021.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594021, url, valid)

proc call*(call_594022: Call_CreateDeploymentJob_594010; body: JsonNode): Recallable =
  ## createDeploymentJob
  ## <p>Deploys a specific version of a robot application to robots in a fleet.</p> <p>The robot application must have a numbered <code>applicationVersion</code> for consistency reasons. To create a new version, use <code>CreateRobotApplicationVersion</code> or see <a href="https://docs.aws.amazon.com/robomaker/latest/dg/create-robot-application-version.html">Creating a Robot Application Version</a>. </p> <note> <p>After 90 days, deployment jobs expire and will be deleted. They will no longer be accessible. </p> </note>
  ##   body: JObject (required)
  var body_594023 = newJObject()
  if body != nil:
    body_594023 = body
  result = call_594022.call(nil, nil, nil, nil, body_594023)

var createDeploymentJob* = Call_CreateDeploymentJob_594010(
    name: "createDeploymentJob", meth: HttpMethod.HttpPost,
    host: "robomaker.amazonaws.com", route: "/createDeploymentJob",
    validator: validate_CreateDeploymentJob_594011, base: "/",
    url: url_CreateDeploymentJob_594012, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateFleet_594024 = ref object of OpenApiRestCall_593389
proc url_CreateFleet_594026(protocol: Scheme; host: string; base: string;
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

proc validate_CreateFleet_594025(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a fleet, a logical group of robots running the same robot application.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594027 = header.getOrDefault("X-Amz-Signature")
  valid_594027 = validateParameter(valid_594027, JString, required = false,
                                 default = nil)
  if valid_594027 != nil:
    section.add "X-Amz-Signature", valid_594027
  var valid_594028 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594028 = validateParameter(valid_594028, JString, required = false,
                                 default = nil)
  if valid_594028 != nil:
    section.add "X-Amz-Content-Sha256", valid_594028
  var valid_594029 = header.getOrDefault("X-Amz-Date")
  valid_594029 = validateParameter(valid_594029, JString, required = false,
                                 default = nil)
  if valid_594029 != nil:
    section.add "X-Amz-Date", valid_594029
  var valid_594030 = header.getOrDefault("X-Amz-Credential")
  valid_594030 = validateParameter(valid_594030, JString, required = false,
                                 default = nil)
  if valid_594030 != nil:
    section.add "X-Amz-Credential", valid_594030
  var valid_594031 = header.getOrDefault("X-Amz-Security-Token")
  valid_594031 = validateParameter(valid_594031, JString, required = false,
                                 default = nil)
  if valid_594031 != nil:
    section.add "X-Amz-Security-Token", valid_594031
  var valid_594032 = header.getOrDefault("X-Amz-Algorithm")
  valid_594032 = validateParameter(valid_594032, JString, required = false,
                                 default = nil)
  if valid_594032 != nil:
    section.add "X-Amz-Algorithm", valid_594032
  var valid_594033 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594033 = validateParameter(valid_594033, JString, required = false,
                                 default = nil)
  if valid_594033 != nil:
    section.add "X-Amz-SignedHeaders", valid_594033
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594035: Call_CreateFleet_594024; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a fleet, a logical group of robots running the same robot application.
  ## 
  let valid = call_594035.validator(path, query, header, formData, body)
  let scheme = call_594035.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594035.url(scheme.get, call_594035.host, call_594035.base,
                         call_594035.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594035, url, valid)

proc call*(call_594036: Call_CreateFleet_594024; body: JsonNode): Recallable =
  ## createFleet
  ## Creates a fleet, a logical group of robots running the same robot application.
  ##   body: JObject (required)
  var body_594037 = newJObject()
  if body != nil:
    body_594037 = body
  result = call_594036.call(nil, nil, nil, nil, body_594037)

var createFleet* = Call_CreateFleet_594024(name: "createFleet",
                                        meth: HttpMethod.HttpPost,
                                        host: "robomaker.amazonaws.com",
                                        route: "/createFleet",
                                        validator: validate_CreateFleet_594025,
                                        base: "/", url: url_CreateFleet_594026,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateRobot_594038 = ref object of OpenApiRestCall_593389
proc url_CreateRobot_594040(protocol: Scheme; host: string; base: string;
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

proc validate_CreateRobot_594039(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a robot.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594041 = header.getOrDefault("X-Amz-Signature")
  valid_594041 = validateParameter(valid_594041, JString, required = false,
                                 default = nil)
  if valid_594041 != nil:
    section.add "X-Amz-Signature", valid_594041
  var valid_594042 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594042 = validateParameter(valid_594042, JString, required = false,
                                 default = nil)
  if valid_594042 != nil:
    section.add "X-Amz-Content-Sha256", valid_594042
  var valid_594043 = header.getOrDefault("X-Amz-Date")
  valid_594043 = validateParameter(valid_594043, JString, required = false,
                                 default = nil)
  if valid_594043 != nil:
    section.add "X-Amz-Date", valid_594043
  var valid_594044 = header.getOrDefault("X-Amz-Credential")
  valid_594044 = validateParameter(valid_594044, JString, required = false,
                                 default = nil)
  if valid_594044 != nil:
    section.add "X-Amz-Credential", valid_594044
  var valid_594045 = header.getOrDefault("X-Amz-Security-Token")
  valid_594045 = validateParameter(valid_594045, JString, required = false,
                                 default = nil)
  if valid_594045 != nil:
    section.add "X-Amz-Security-Token", valid_594045
  var valid_594046 = header.getOrDefault("X-Amz-Algorithm")
  valid_594046 = validateParameter(valid_594046, JString, required = false,
                                 default = nil)
  if valid_594046 != nil:
    section.add "X-Amz-Algorithm", valid_594046
  var valid_594047 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594047 = validateParameter(valid_594047, JString, required = false,
                                 default = nil)
  if valid_594047 != nil:
    section.add "X-Amz-SignedHeaders", valid_594047
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594049: Call_CreateRobot_594038; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a robot.
  ## 
  let valid = call_594049.validator(path, query, header, formData, body)
  let scheme = call_594049.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594049.url(scheme.get, call_594049.host, call_594049.base,
                         call_594049.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594049, url, valid)

proc call*(call_594050: Call_CreateRobot_594038; body: JsonNode): Recallable =
  ## createRobot
  ## Creates a robot.
  ##   body: JObject (required)
  var body_594051 = newJObject()
  if body != nil:
    body_594051 = body
  result = call_594050.call(nil, nil, nil, nil, body_594051)

var createRobot* = Call_CreateRobot_594038(name: "createRobot",
                                        meth: HttpMethod.HttpPost,
                                        host: "robomaker.amazonaws.com",
                                        route: "/createRobot",
                                        validator: validate_CreateRobot_594039,
                                        base: "/", url: url_CreateRobot_594040,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateRobotApplication_594052 = ref object of OpenApiRestCall_593389
proc url_CreateRobotApplication_594054(protocol: Scheme; host: string; base: string;
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

proc validate_CreateRobotApplication_594053(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a robot application. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594055 = header.getOrDefault("X-Amz-Signature")
  valid_594055 = validateParameter(valid_594055, JString, required = false,
                                 default = nil)
  if valid_594055 != nil:
    section.add "X-Amz-Signature", valid_594055
  var valid_594056 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594056 = validateParameter(valid_594056, JString, required = false,
                                 default = nil)
  if valid_594056 != nil:
    section.add "X-Amz-Content-Sha256", valid_594056
  var valid_594057 = header.getOrDefault("X-Amz-Date")
  valid_594057 = validateParameter(valid_594057, JString, required = false,
                                 default = nil)
  if valid_594057 != nil:
    section.add "X-Amz-Date", valid_594057
  var valid_594058 = header.getOrDefault("X-Amz-Credential")
  valid_594058 = validateParameter(valid_594058, JString, required = false,
                                 default = nil)
  if valid_594058 != nil:
    section.add "X-Amz-Credential", valid_594058
  var valid_594059 = header.getOrDefault("X-Amz-Security-Token")
  valid_594059 = validateParameter(valid_594059, JString, required = false,
                                 default = nil)
  if valid_594059 != nil:
    section.add "X-Amz-Security-Token", valid_594059
  var valid_594060 = header.getOrDefault("X-Amz-Algorithm")
  valid_594060 = validateParameter(valid_594060, JString, required = false,
                                 default = nil)
  if valid_594060 != nil:
    section.add "X-Amz-Algorithm", valid_594060
  var valid_594061 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594061 = validateParameter(valid_594061, JString, required = false,
                                 default = nil)
  if valid_594061 != nil:
    section.add "X-Amz-SignedHeaders", valid_594061
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594063: Call_CreateRobotApplication_594052; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a robot application. 
  ## 
  let valid = call_594063.validator(path, query, header, formData, body)
  let scheme = call_594063.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594063.url(scheme.get, call_594063.host, call_594063.base,
                         call_594063.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594063, url, valid)

proc call*(call_594064: Call_CreateRobotApplication_594052; body: JsonNode): Recallable =
  ## createRobotApplication
  ## Creates a robot application. 
  ##   body: JObject (required)
  var body_594065 = newJObject()
  if body != nil:
    body_594065 = body
  result = call_594064.call(nil, nil, nil, nil, body_594065)

var createRobotApplication* = Call_CreateRobotApplication_594052(
    name: "createRobotApplication", meth: HttpMethod.HttpPost,
    host: "robomaker.amazonaws.com", route: "/createRobotApplication",
    validator: validate_CreateRobotApplication_594053, base: "/",
    url: url_CreateRobotApplication_594054, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateRobotApplicationVersion_594066 = ref object of OpenApiRestCall_593389
proc url_CreateRobotApplicationVersion_594068(protocol: Scheme; host: string;
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

proc validate_CreateRobotApplicationVersion_594067(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a version of a robot application.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594069 = header.getOrDefault("X-Amz-Signature")
  valid_594069 = validateParameter(valid_594069, JString, required = false,
                                 default = nil)
  if valid_594069 != nil:
    section.add "X-Amz-Signature", valid_594069
  var valid_594070 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594070 = validateParameter(valid_594070, JString, required = false,
                                 default = nil)
  if valid_594070 != nil:
    section.add "X-Amz-Content-Sha256", valid_594070
  var valid_594071 = header.getOrDefault("X-Amz-Date")
  valid_594071 = validateParameter(valid_594071, JString, required = false,
                                 default = nil)
  if valid_594071 != nil:
    section.add "X-Amz-Date", valid_594071
  var valid_594072 = header.getOrDefault("X-Amz-Credential")
  valid_594072 = validateParameter(valid_594072, JString, required = false,
                                 default = nil)
  if valid_594072 != nil:
    section.add "X-Amz-Credential", valid_594072
  var valid_594073 = header.getOrDefault("X-Amz-Security-Token")
  valid_594073 = validateParameter(valid_594073, JString, required = false,
                                 default = nil)
  if valid_594073 != nil:
    section.add "X-Amz-Security-Token", valid_594073
  var valid_594074 = header.getOrDefault("X-Amz-Algorithm")
  valid_594074 = validateParameter(valid_594074, JString, required = false,
                                 default = nil)
  if valid_594074 != nil:
    section.add "X-Amz-Algorithm", valid_594074
  var valid_594075 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594075 = validateParameter(valid_594075, JString, required = false,
                                 default = nil)
  if valid_594075 != nil:
    section.add "X-Amz-SignedHeaders", valid_594075
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594077: Call_CreateRobotApplicationVersion_594066; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a version of a robot application.
  ## 
  let valid = call_594077.validator(path, query, header, formData, body)
  let scheme = call_594077.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594077.url(scheme.get, call_594077.host, call_594077.base,
                         call_594077.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594077, url, valid)

proc call*(call_594078: Call_CreateRobotApplicationVersion_594066; body: JsonNode): Recallable =
  ## createRobotApplicationVersion
  ## Creates a version of a robot application.
  ##   body: JObject (required)
  var body_594079 = newJObject()
  if body != nil:
    body_594079 = body
  result = call_594078.call(nil, nil, nil, nil, body_594079)

var createRobotApplicationVersion* = Call_CreateRobotApplicationVersion_594066(
    name: "createRobotApplicationVersion", meth: HttpMethod.HttpPost,
    host: "robomaker.amazonaws.com", route: "/createRobotApplicationVersion",
    validator: validate_CreateRobotApplicationVersion_594067, base: "/",
    url: url_CreateRobotApplicationVersion_594068,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateSimulationApplication_594080 = ref object of OpenApiRestCall_593389
proc url_CreateSimulationApplication_594082(protocol: Scheme; host: string;
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

proc validate_CreateSimulationApplication_594081(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a simulation application.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594083 = header.getOrDefault("X-Amz-Signature")
  valid_594083 = validateParameter(valid_594083, JString, required = false,
                                 default = nil)
  if valid_594083 != nil:
    section.add "X-Amz-Signature", valid_594083
  var valid_594084 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594084 = validateParameter(valid_594084, JString, required = false,
                                 default = nil)
  if valid_594084 != nil:
    section.add "X-Amz-Content-Sha256", valid_594084
  var valid_594085 = header.getOrDefault("X-Amz-Date")
  valid_594085 = validateParameter(valid_594085, JString, required = false,
                                 default = nil)
  if valid_594085 != nil:
    section.add "X-Amz-Date", valid_594085
  var valid_594086 = header.getOrDefault("X-Amz-Credential")
  valid_594086 = validateParameter(valid_594086, JString, required = false,
                                 default = nil)
  if valid_594086 != nil:
    section.add "X-Amz-Credential", valid_594086
  var valid_594087 = header.getOrDefault("X-Amz-Security-Token")
  valid_594087 = validateParameter(valid_594087, JString, required = false,
                                 default = nil)
  if valid_594087 != nil:
    section.add "X-Amz-Security-Token", valid_594087
  var valid_594088 = header.getOrDefault("X-Amz-Algorithm")
  valid_594088 = validateParameter(valid_594088, JString, required = false,
                                 default = nil)
  if valid_594088 != nil:
    section.add "X-Amz-Algorithm", valid_594088
  var valid_594089 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594089 = validateParameter(valid_594089, JString, required = false,
                                 default = nil)
  if valid_594089 != nil:
    section.add "X-Amz-SignedHeaders", valid_594089
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594091: Call_CreateSimulationApplication_594080; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a simulation application.
  ## 
  let valid = call_594091.validator(path, query, header, formData, body)
  let scheme = call_594091.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594091.url(scheme.get, call_594091.host, call_594091.base,
                         call_594091.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594091, url, valid)

proc call*(call_594092: Call_CreateSimulationApplication_594080; body: JsonNode): Recallable =
  ## createSimulationApplication
  ## Creates a simulation application.
  ##   body: JObject (required)
  var body_594093 = newJObject()
  if body != nil:
    body_594093 = body
  result = call_594092.call(nil, nil, nil, nil, body_594093)

var createSimulationApplication* = Call_CreateSimulationApplication_594080(
    name: "createSimulationApplication", meth: HttpMethod.HttpPost,
    host: "robomaker.amazonaws.com", route: "/createSimulationApplication",
    validator: validate_CreateSimulationApplication_594081, base: "/",
    url: url_CreateSimulationApplication_594082,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateSimulationApplicationVersion_594094 = ref object of OpenApiRestCall_593389
proc url_CreateSimulationApplicationVersion_594096(protocol: Scheme; host: string;
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

proc validate_CreateSimulationApplicationVersion_594095(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a simulation application with a specific revision id.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594097 = header.getOrDefault("X-Amz-Signature")
  valid_594097 = validateParameter(valid_594097, JString, required = false,
                                 default = nil)
  if valid_594097 != nil:
    section.add "X-Amz-Signature", valid_594097
  var valid_594098 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594098 = validateParameter(valid_594098, JString, required = false,
                                 default = nil)
  if valid_594098 != nil:
    section.add "X-Amz-Content-Sha256", valid_594098
  var valid_594099 = header.getOrDefault("X-Amz-Date")
  valid_594099 = validateParameter(valid_594099, JString, required = false,
                                 default = nil)
  if valid_594099 != nil:
    section.add "X-Amz-Date", valid_594099
  var valid_594100 = header.getOrDefault("X-Amz-Credential")
  valid_594100 = validateParameter(valid_594100, JString, required = false,
                                 default = nil)
  if valid_594100 != nil:
    section.add "X-Amz-Credential", valid_594100
  var valid_594101 = header.getOrDefault("X-Amz-Security-Token")
  valid_594101 = validateParameter(valid_594101, JString, required = false,
                                 default = nil)
  if valid_594101 != nil:
    section.add "X-Amz-Security-Token", valid_594101
  var valid_594102 = header.getOrDefault("X-Amz-Algorithm")
  valid_594102 = validateParameter(valid_594102, JString, required = false,
                                 default = nil)
  if valid_594102 != nil:
    section.add "X-Amz-Algorithm", valid_594102
  var valid_594103 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594103 = validateParameter(valid_594103, JString, required = false,
                                 default = nil)
  if valid_594103 != nil:
    section.add "X-Amz-SignedHeaders", valid_594103
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594105: Call_CreateSimulationApplicationVersion_594094;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Creates a simulation application with a specific revision id.
  ## 
  let valid = call_594105.validator(path, query, header, formData, body)
  let scheme = call_594105.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594105.url(scheme.get, call_594105.host, call_594105.base,
                         call_594105.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594105, url, valid)

proc call*(call_594106: Call_CreateSimulationApplicationVersion_594094;
          body: JsonNode): Recallable =
  ## createSimulationApplicationVersion
  ## Creates a simulation application with a specific revision id.
  ##   body: JObject (required)
  var body_594107 = newJObject()
  if body != nil:
    body_594107 = body
  result = call_594106.call(nil, nil, nil, nil, body_594107)

var createSimulationApplicationVersion* = Call_CreateSimulationApplicationVersion_594094(
    name: "createSimulationApplicationVersion", meth: HttpMethod.HttpPost,
    host: "robomaker.amazonaws.com", route: "/createSimulationApplicationVersion",
    validator: validate_CreateSimulationApplicationVersion_594095, base: "/",
    url: url_CreateSimulationApplicationVersion_594096,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateSimulationJob_594108 = ref object of OpenApiRestCall_593389
proc url_CreateSimulationJob_594110(protocol: Scheme; host: string; base: string;
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

proc validate_CreateSimulationJob_594109(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p>Creates a simulation job.</p> <note> <p>After 90 days, simulation jobs expire and will be deleted. They will no longer be accessible. </p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594111 = header.getOrDefault("X-Amz-Signature")
  valid_594111 = validateParameter(valid_594111, JString, required = false,
                                 default = nil)
  if valid_594111 != nil:
    section.add "X-Amz-Signature", valid_594111
  var valid_594112 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594112 = validateParameter(valid_594112, JString, required = false,
                                 default = nil)
  if valid_594112 != nil:
    section.add "X-Amz-Content-Sha256", valid_594112
  var valid_594113 = header.getOrDefault("X-Amz-Date")
  valid_594113 = validateParameter(valid_594113, JString, required = false,
                                 default = nil)
  if valid_594113 != nil:
    section.add "X-Amz-Date", valid_594113
  var valid_594114 = header.getOrDefault("X-Amz-Credential")
  valid_594114 = validateParameter(valid_594114, JString, required = false,
                                 default = nil)
  if valid_594114 != nil:
    section.add "X-Amz-Credential", valid_594114
  var valid_594115 = header.getOrDefault("X-Amz-Security-Token")
  valid_594115 = validateParameter(valid_594115, JString, required = false,
                                 default = nil)
  if valid_594115 != nil:
    section.add "X-Amz-Security-Token", valid_594115
  var valid_594116 = header.getOrDefault("X-Amz-Algorithm")
  valid_594116 = validateParameter(valid_594116, JString, required = false,
                                 default = nil)
  if valid_594116 != nil:
    section.add "X-Amz-Algorithm", valid_594116
  var valid_594117 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594117 = validateParameter(valid_594117, JString, required = false,
                                 default = nil)
  if valid_594117 != nil:
    section.add "X-Amz-SignedHeaders", valid_594117
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594119: Call_CreateSimulationJob_594108; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a simulation job.</p> <note> <p>After 90 days, simulation jobs expire and will be deleted. They will no longer be accessible. </p> </note>
  ## 
  let valid = call_594119.validator(path, query, header, formData, body)
  let scheme = call_594119.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594119.url(scheme.get, call_594119.host, call_594119.base,
                         call_594119.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594119, url, valid)

proc call*(call_594120: Call_CreateSimulationJob_594108; body: JsonNode): Recallable =
  ## createSimulationJob
  ## <p>Creates a simulation job.</p> <note> <p>After 90 days, simulation jobs expire and will be deleted. They will no longer be accessible. </p> </note>
  ##   body: JObject (required)
  var body_594121 = newJObject()
  if body != nil:
    body_594121 = body
  result = call_594120.call(nil, nil, nil, nil, body_594121)

var createSimulationJob* = Call_CreateSimulationJob_594108(
    name: "createSimulationJob", meth: HttpMethod.HttpPost,
    host: "robomaker.amazonaws.com", route: "/createSimulationJob",
    validator: validate_CreateSimulationJob_594109, base: "/",
    url: url_CreateSimulationJob_594110, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteFleet_594122 = ref object of OpenApiRestCall_593389
proc url_DeleteFleet_594124(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteFleet_594123(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes a fleet.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594125 = header.getOrDefault("X-Amz-Signature")
  valid_594125 = validateParameter(valid_594125, JString, required = false,
                                 default = nil)
  if valid_594125 != nil:
    section.add "X-Amz-Signature", valid_594125
  var valid_594126 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594126 = validateParameter(valid_594126, JString, required = false,
                                 default = nil)
  if valid_594126 != nil:
    section.add "X-Amz-Content-Sha256", valid_594126
  var valid_594127 = header.getOrDefault("X-Amz-Date")
  valid_594127 = validateParameter(valid_594127, JString, required = false,
                                 default = nil)
  if valid_594127 != nil:
    section.add "X-Amz-Date", valid_594127
  var valid_594128 = header.getOrDefault("X-Amz-Credential")
  valid_594128 = validateParameter(valid_594128, JString, required = false,
                                 default = nil)
  if valid_594128 != nil:
    section.add "X-Amz-Credential", valid_594128
  var valid_594129 = header.getOrDefault("X-Amz-Security-Token")
  valid_594129 = validateParameter(valid_594129, JString, required = false,
                                 default = nil)
  if valid_594129 != nil:
    section.add "X-Amz-Security-Token", valid_594129
  var valid_594130 = header.getOrDefault("X-Amz-Algorithm")
  valid_594130 = validateParameter(valid_594130, JString, required = false,
                                 default = nil)
  if valid_594130 != nil:
    section.add "X-Amz-Algorithm", valid_594130
  var valid_594131 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594131 = validateParameter(valid_594131, JString, required = false,
                                 default = nil)
  if valid_594131 != nil:
    section.add "X-Amz-SignedHeaders", valid_594131
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594133: Call_DeleteFleet_594122; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a fleet.
  ## 
  let valid = call_594133.validator(path, query, header, formData, body)
  let scheme = call_594133.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594133.url(scheme.get, call_594133.host, call_594133.base,
                         call_594133.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594133, url, valid)

proc call*(call_594134: Call_DeleteFleet_594122; body: JsonNode): Recallable =
  ## deleteFleet
  ## Deletes a fleet.
  ##   body: JObject (required)
  var body_594135 = newJObject()
  if body != nil:
    body_594135 = body
  result = call_594134.call(nil, nil, nil, nil, body_594135)

var deleteFleet* = Call_DeleteFleet_594122(name: "deleteFleet",
                                        meth: HttpMethod.HttpPost,
                                        host: "robomaker.amazonaws.com",
                                        route: "/deleteFleet",
                                        validator: validate_DeleteFleet_594123,
                                        base: "/", url: url_DeleteFleet_594124,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRobot_594136 = ref object of OpenApiRestCall_593389
proc url_DeleteRobot_594138(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteRobot_594137(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes a robot.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594139 = header.getOrDefault("X-Amz-Signature")
  valid_594139 = validateParameter(valid_594139, JString, required = false,
                                 default = nil)
  if valid_594139 != nil:
    section.add "X-Amz-Signature", valid_594139
  var valid_594140 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594140 = validateParameter(valid_594140, JString, required = false,
                                 default = nil)
  if valid_594140 != nil:
    section.add "X-Amz-Content-Sha256", valid_594140
  var valid_594141 = header.getOrDefault("X-Amz-Date")
  valid_594141 = validateParameter(valid_594141, JString, required = false,
                                 default = nil)
  if valid_594141 != nil:
    section.add "X-Amz-Date", valid_594141
  var valid_594142 = header.getOrDefault("X-Amz-Credential")
  valid_594142 = validateParameter(valid_594142, JString, required = false,
                                 default = nil)
  if valid_594142 != nil:
    section.add "X-Amz-Credential", valid_594142
  var valid_594143 = header.getOrDefault("X-Amz-Security-Token")
  valid_594143 = validateParameter(valid_594143, JString, required = false,
                                 default = nil)
  if valid_594143 != nil:
    section.add "X-Amz-Security-Token", valid_594143
  var valid_594144 = header.getOrDefault("X-Amz-Algorithm")
  valid_594144 = validateParameter(valid_594144, JString, required = false,
                                 default = nil)
  if valid_594144 != nil:
    section.add "X-Amz-Algorithm", valid_594144
  var valid_594145 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594145 = validateParameter(valid_594145, JString, required = false,
                                 default = nil)
  if valid_594145 != nil:
    section.add "X-Amz-SignedHeaders", valid_594145
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594147: Call_DeleteRobot_594136; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a robot.
  ## 
  let valid = call_594147.validator(path, query, header, formData, body)
  let scheme = call_594147.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594147.url(scheme.get, call_594147.host, call_594147.base,
                         call_594147.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594147, url, valid)

proc call*(call_594148: Call_DeleteRobot_594136; body: JsonNode): Recallable =
  ## deleteRobot
  ## Deletes a robot.
  ##   body: JObject (required)
  var body_594149 = newJObject()
  if body != nil:
    body_594149 = body
  result = call_594148.call(nil, nil, nil, nil, body_594149)

var deleteRobot* = Call_DeleteRobot_594136(name: "deleteRobot",
                                        meth: HttpMethod.HttpPost,
                                        host: "robomaker.amazonaws.com",
                                        route: "/deleteRobot",
                                        validator: validate_DeleteRobot_594137,
                                        base: "/", url: url_DeleteRobot_594138,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRobotApplication_594150 = ref object of OpenApiRestCall_593389
proc url_DeleteRobotApplication_594152(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteRobotApplication_594151(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes a robot application.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594153 = header.getOrDefault("X-Amz-Signature")
  valid_594153 = validateParameter(valid_594153, JString, required = false,
                                 default = nil)
  if valid_594153 != nil:
    section.add "X-Amz-Signature", valid_594153
  var valid_594154 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594154 = validateParameter(valid_594154, JString, required = false,
                                 default = nil)
  if valid_594154 != nil:
    section.add "X-Amz-Content-Sha256", valid_594154
  var valid_594155 = header.getOrDefault("X-Amz-Date")
  valid_594155 = validateParameter(valid_594155, JString, required = false,
                                 default = nil)
  if valid_594155 != nil:
    section.add "X-Amz-Date", valid_594155
  var valid_594156 = header.getOrDefault("X-Amz-Credential")
  valid_594156 = validateParameter(valid_594156, JString, required = false,
                                 default = nil)
  if valid_594156 != nil:
    section.add "X-Amz-Credential", valid_594156
  var valid_594157 = header.getOrDefault("X-Amz-Security-Token")
  valid_594157 = validateParameter(valid_594157, JString, required = false,
                                 default = nil)
  if valid_594157 != nil:
    section.add "X-Amz-Security-Token", valid_594157
  var valid_594158 = header.getOrDefault("X-Amz-Algorithm")
  valid_594158 = validateParameter(valid_594158, JString, required = false,
                                 default = nil)
  if valid_594158 != nil:
    section.add "X-Amz-Algorithm", valid_594158
  var valid_594159 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594159 = validateParameter(valid_594159, JString, required = false,
                                 default = nil)
  if valid_594159 != nil:
    section.add "X-Amz-SignedHeaders", valid_594159
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594161: Call_DeleteRobotApplication_594150; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a robot application.
  ## 
  let valid = call_594161.validator(path, query, header, formData, body)
  let scheme = call_594161.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594161.url(scheme.get, call_594161.host, call_594161.base,
                         call_594161.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594161, url, valid)

proc call*(call_594162: Call_DeleteRobotApplication_594150; body: JsonNode): Recallable =
  ## deleteRobotApplication
  ## Deletes a robot application.
  ##   body: JObject (required)
  var body_594163 = newJObject()
  if body != nil:
    body_594163 = body
  result = call_594162.call(nil, nil, nil, nil, body_594163)

var deleteRobotApplication* = Call_DeleteRobotApplication_594150(
    name: "deleteRobotApplication", meth: HttpMethod.HttpPost,
    host: "robomaker.amazonaws.com", route: "/deleteRobotApplication",
    validator: validate_DeleteRobotApplication_594151, base: "/",
    url: url_DeleteRobotApplication_594152, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSimulationApplication_594164 = ref object of OpenApiRestCall_593389
proc url_DeleteSimulationApplication_594166(protocol: Scheme; host: string;
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

proc validate_DeleteSimulationApplication_594165(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes a simulation application.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594167 = header.getOrDefault("X-Amz-Signature")
  valid_594167 = validateParameter(valid_594167, JString, required = false,
                                 default = nil)
  if valid_594167 != nil:
    section.add "X-Amz-Signature", valid_594167
  var valid_594168 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594168 = validateParameter(valid_594168, JString, required = false,
                                 default = nil)
  if valid_594168 != nil:
    section.add "X-Amz-Content-Sha256", valid_594168
  var valid_594169 = header.getOrDefault("X-Amz-Date")
  valid_594169 = validateParameter(valid_594169, JString, required = false,
                                 default = nil)
  if valid_594169 != nil:
    section.add "X-Amz-Date", valid_594169
  var valid_594170 = header.getOrDefault("X-Amz-Credential")
  valid_594170 = validateParameter(valid_594170, JString, required = false,
                                 default = nil)
  if valid_594170 != nil:
    section.add "X-Amz-Credential", valid_594170
  var valid_594171 = header.getOrDefault("X-Amz-Security-Token")
  valid_594171 = validateParameter(valid_594171, JString, required = false,
                                 default = nil)
  if valid_594171 != nil:
    section.add "X-Amz-Security-Token", valid_594171
  var valid_594172 = header.getOrDefault("X-Amz-Algorithm")
  valid_594172 = validateParameter(valid_594172, JString, required = false,
                                 default = nil)
  if valid_594172 != nil:
    section.add "X-Amz-Algorithm", valid_594172
  var valid_594173 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594173 = validateParameter(valid_594173, JString, required = false,
                                 default = nil)
  if valid_594173 != nil:
    section.add "X-Amz-SignedHeaders", valid_594173
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594175: Call_DeleteSimulationApplication_594164; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a simulation application.
  ## 
  let valid = call_594175.validator(path, query, header, formData, body)
  let scheme = call_594175.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594175.url(scheme.get, call_594175.host, call_594175.base,
                         call_594175.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594175, url, valid)

proc call*(call_594176: Call_DeleteSimulationApplication_594164; body: JsonNode): Recallable =
  ## deleteSimulationApplication
  ## Deletes a simulation application.
  ##   body: JObject (required)
  var body_594177 = newJObject()
  if body != nil:
    body_594177 = body
  result = call_594176.call(nil, nil, nil, nil, body_594177)

var deleteSimulationApplication* = Call_DeleteSimulationApplication_594164(
    name: "deleteSimulationApplication", meth: HttpMethod.HttpPost,
    host: "robomaker.amazonaws.com", route: "/deleteSimulationApplication",
    validator: validate_DeleteSimulationApplication_594165, base: "/",
    url: url_DeleteSimulationApplication_594166,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeregisterRobot_594178 = ref object of OpenApiRestCall_593389
proc url_DeregisterRobot_594180(protocol: Scheme; host: string; base: string;
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

proc validate_DeregisterRobot_594179(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Deregisters a robot.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594181 = header.getOrDefault("X-Amz-Signature")
  valid_594181 = validateParameter(valid_594181, JString, required = false,
                                 default = nil)
  if valid_594181 != nil:
    section.add "X-Amz-Signature", valid_594181
  var valid_594182 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594182 = validateParameter(valid_594182, JString, required = false,
                                 default = nil)
  if valid_594182 != nil:
    section.add "X-Amz-Content-Sha256", valid_594182
  var valid_594183 = header.getOrDefault("X-Amz-Date")
  valid_594183 = validateParameter(valid_594183, JString, required = false,
                                 default = nil)
  if valid_594183 != nil:
    section.add "X-Amz-Date", valid_594183
  var valid_594184 = header.getOrDefault("X-Amz-Credential")
  valid_594184 = validateParameter(valid_594184, JString, required = false,
                                 default = nil)
  if valid_594184 != nil:
    section.add "X-Amz-Credential", valid_594184
  var valid_594185 = header.getOrDefault("X-Amz-Security-Token")
  valid_594185 = validateParameter(valid_594185, JString, required = false,
                                 default = nil)
  if valid_594185 != nil:
    section.add "X-Amz-Security-Token", valid_594185
  var valid_594186 = header.getOrDefault("X-Amz-Algorithm")
  valid_594186 = validateParameter(valid_594186, JString, required = false,
                                 default = nil)
  if valid_594186 != nil:
    section.add "X-Amz-Algorithm", valid_594186
  var valid_594187 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594187 = validateParameter(valid_594187, JString, required = false,
                                 default = nil)
  if valid_594187 != nil:
    section.add "X-Amz-SignedHeaders", valid_594187
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594189: Call_DeregisterRobot_594178; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deregisters a robot.
  ## 
  let valid = call_594189.validator(path, query, header, formData, body)
  let scheme = call_594189.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594189.url(scheme.get, call_594189.host, call_594189.base,
                         call_594189.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594189, url, valid)

proc call*(call_594190: Call_DeregisterRobot_594178; body: JsonNode): Recallable =
  ## deregisterRobot
  ## Deregisters a robot.
  ##   body: JObject (required)
  var body_594191 = newJObject()
  if body != nil:
    body_594191 = body
  result = call_594190.call(nil, nil, nil, nil, body_594191)

var deregisterRobot* = Call_DeregisterRobot_594178(name: "deregisterRobot",
    meth: HttpMethod.HttpPost, host: "robomaker.amazonaws.com",
    route: "/deregisterRobot", validator: validate_DeregisterRobot_594179,
    base: "/", url: url_DeregisterRobot_594180, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDeploymentJob_594192 = ref object of OpenApiRestCall_593389
proc url_DescribeDeploymentJob_594194(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeDeploymentJob_594193(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Describes a deployment job.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594195 = header.getOrDefault("X-Amz-Signature")
  valid_594195 = validateParameter(valid_594195, JString, required = false,
                                 default = nil)
  if valid_594195 != nil:
    section.add "X-Amz-Signature", valid_594195
  var valid_594196 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594196 = validateParameter(valid_594196, JString, required = false,
                                 default = nil)
  if valid_594196 != nil:
    section.add "X-Amz-Content-Sha256", valid_594196
  var valid_594197 = header.getOrDefault("X-Amz-Date")
  valid_594197 = validateParameter(valid_594197, JString, required = false,
                                 default = nil)
  if valid_594197 != nil:
    section.add "X-Amz-Date", valid_594197
  var valid_594198 = header.getOrDefault("X-Amz-Credential")
  valid_594198 = validateParameter(valid_594198, JString, required = false,
                                 default = nil)
  if valid_594198 != nil:
    section.add "X-Amz-Credential", valid_594198
  var valid_594199 = header.getOrDefault("X-Amz-Security-Token")
  valid_594199 = validateParameter(valid_594199, JString, required = false,
                                 default = nil)
  if valid_594199 != nil:
    section.add "X-Amz-Security-Token", valid_594199
  var valid_594200 = header.getOrDefault("X-Amz-Algorithm")
  valid_594200 = validateParameter(valid_594200, JString, required = false,
                                 default = nil)
  if valid_594200 != nil:
    section.add "X-Amz-Algorithm", valid_594200
  var valid_594201 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594201 = validateParameter(valid_594201, JString, required = false,
                                 default = nil)
  if valid_594201 != nil:
    section.add "X-Amz-SignedHeaders", valid_594201
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594203: Call_DescribeDeploymentJob_594192; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes a deployment job.
  ## 
  let valid = call_594203.validator(path, query, header, formData, body)
  let scheme = call_594203.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594203.url(scheme.get, call_594203.host, call_594203.base,
                         call_594203.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594203, url, valid)

proc call*(call_594204: Call_DescribeDeploymentJob_594192; body: JsonNode): Recallable =
  ## describeDeploymentJob
  ## Describes a deployment job.
  ##   body: JObject (required)
  var body_594205 = newJObject()
  if body != nil:
    body_594205 = body
  result = call_594204.call(nil, nil, nil, nil, body_594205)

var describeDeploymentJob* = Call_DescribeDeploymentJob_594192(
    name: "describeDeploymentJob", meth: HttpMethod.HttpPost,
    host: "robomaker.amazonaws.com", route: "/describeDeploymentJob",
    validator: validate_DescribeDeploymentJob_594193, base: "/",
    url: url_DescribeDeploymentJob_594194, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeFleet_594206 = ref object of OpenApiRestCall_593389
proc url_DescribeFleet_594208(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeFleet_594207(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Describes a fleet.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594209 = header.getOrDefault("X-Amz-Signature")
  valid_594209 = validateParameter(valid_594209, JString, required = false,
                                 default = nil)
  if valid_594209 != nil:
    section.add "X-Amz-Signature", valid_594209
  var valid_594210 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594210 = validateParameter(valid_594210, JString, required = false,
                                 default = nil)
  if valid_594210 != nil:
    section.add "X-Amz-Content-Sha256", valid_594210
  var valid_594211 = header.getOrDefault("X-Amz-Date")
  valid_594211 = validateParameter(valid_594211, JString, required = false,
                                 default = nil)
  if valid_594211 != nil:
    section.add "X-Amz-Date", valid_594211
  var valid_594212 = header.getOrDefault("X-Amz-Credential")
  valid_594212 = validateParameter(valid_594212, JString, required = false,
                                 default = nil)
  if valid_594212 != nil:
    section.add "X-Amz-Credential", valid_594212
  var valid_594213 = header.getOrDefault("X-Amz-Security-Token")
  valid_594213 = validateParameter(valid_594213, JString, required = false,
                                 default = nil)
  if valid_594213 != nil:
    section.add "X-Amz-Security-Token", valid_594213
  var valid_594214 = header.getOrDefault("X-Amz-Algorithm")
  valid_594214 = validateParameter(valid_594214, JString, required = false,
                                 default = nil)
  if valid_594214 != nil:
    section.add "X-Amz-Algorithm", valid_594214
  var valid_594215 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594215 = validateParameter(valid_594215, JString, required = false,
                                 default = nil)
  if valid_594215 != nil:
    section.add "X-Amz-SignedHeaders", valid_594215
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594217: Call_DescribeFleet_594206; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes a fleet.
  ## 
  let valid = call_594217.validator(path, query, header, formData, body)
  let scheme = call_594217.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594217.url(scheme.get, call_594217.host, call_594217.base,
                         call_594217.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594217, url, valid)

proc call*(call_594218: Call_DescribeFleet_594206; body: JsonNode): Recallable =
  ## describeFleet
  ## Describes a fleet.
  ##   body: JObject (required)
  var body_594219 = newJObject()
  if body != nil:
    body_594219 = body
  result = call_594218.call(nil, nil, nil, nil, body_594219)

var describeFleet* = Call_DescribeFleet_594206(name: "describeFleet",
    meth: HttpMethod.HttpPost, host: "robomaker.amazonaws.com",
    route: "/describeFleet", validator: validate_DescribeFleet_594207, base: "/",
    url: url_DescribeFleet_594208, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeRobot_594220 = ref object of OpenApiRestCall_593389
proc url_DescribeRobot_594222(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeRobot_594221(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Describes a robot.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594223 = header.getOrDefault("X-Amz-Signature")
  valid_594223 = validateParameter(valid_594223, JString, required = false,
                                 default = nil)
  if valid_594223 != nil:
    section.add "X-Amz-Signature", valid_594223
  var valid_594224 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594224 = validateParameter(valid_594224, JString, required = false,
                                 default = nil)
  if valid_594224 != nil:
    section.add "X-Amz-Content-Sha256", valid_594224
  var valid_594225 = header.getOrDefault("X-Amz-Date")
  valid_594225 = validateParameter(valid_594225, JString, required = false,
                                 default = nil)
  if valid_594225 != nil:
    section.add "X-Amz-Date", valid_594225
  var valid_594226 = header.getOrDefault("X-Amz-Credential")
  valid_594226 = validateParameter(valid_594226, JString, required = false,
                                 default = nil)
  if valid_594226 != nil:
    section.add "X-Amz-Credential", valid_594226
  var valid_594227 = header.getOrDefault("X-Amz-Security-Token")
  valid_594227 = validateParameter(valid_594227, JString, required = false,
                                 default = nil)
  if valid_594227 != nil:
    section.add "X-Amz-Security-Token", valid_594227
  var valid_594228 = header.getOrDefault("X-Amz-Algorithm")
  valid_594228 = validateParameter(valid_594228, JString, required = false,
                                 default = nil)
  if valid_594228 != nil:
    section.add "X-Amz-Algorithm", valid_594228
  var valid_594229 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594229 = validateParameter(valid_594229, JString, required = false,
                                 default = nil)
  if valid_594229 != nil:
    section.add "X-Amz-SignedHeaders", valid_594229
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594231: Call_DescribeRobot_594220; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes a robot.
  ## 
  let valid = call_594231.validator(path, query, header, formData, body)
  let scheme = call_594231.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594231.url(scheme.get, call_594231.host, call_594231.base,
                         call_594231.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594231, url, valid)

proc call*(call_594232: Call_DescribeRobot_594220; body: JsonNode): Recallable =
  ## describeRobot
  ## Describes a robot.
  ##   body: JObject (required)
  var body_594233 = newJObject()
  if body != nil:
    body_594233 = body
  result = call_594232.call(nil, nil, nil, nil, body_594233)

var describeRobot* = Call_DescribeRobot_594220(name: "describeRobot",
    meth: HttpMethod.HttpPost, host: "robomaker.amazonaws.com",
    route: "/describeRobot", validator: validate_DescribeRobot_594221, base: "/",
    url: url_DescribeRobot_594222, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeRobotApplication_594234 = ref object of OpenApiRestCall_593389
proc url_DescribeRobotApplication_594236(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeRobotApplication_594235(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Describes a robot application.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594237 = header.getOrDefault("X-Amz-Signature")
  valid_594237 = validateParameter(valid_594237, JString, required = false,
                                 default = nil)
  if valid_594237 != nil:
    section.add "X-Amz-Signature", valid_594237
  var valid_594238 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594238 = validateParameter(valid_594238, JString, required = false,
                                 default = nil)
  if valid_594238 != nil:
    section.add "X-Amz-Content-Sha256", valid_594238
  var valid_594239 = header.getOrDefault("X-Amz-Date")
  valid_594239 = validateParameter(valid_594239, JString, required = false,
                                 default = nil)
  if valid_594239 != nil:
    section.add "X-Amz-Date", valid_594239
  var valid_594240 = header.getOrDefault("X-Amz-Credential")
  valid_594240 = validateParameter(valid_594240, JString, required = false,
                                 default = nil)
  if valid_594240 != nil:
    section.add "X-Amz-Credential", valid_594240
  var valid_594241 = header.getOrDefault("X-Amz-Security-Token")
  valid_594241 = validateParameter(valid_594241, JString, required = false,
                                 default = nil)
  if valid_594241 != nil:
    section.add "X-Amz-Security-Token", valid_594241
  var valid_594242 = header.getOrDefault("X-Amz-Algorithm")
  valid_594242 = validateParameter(valid_594242, JString, required = false,
                                 default = nil)
  if valid_594242 != nil:
    section.add "X-Amz-Algorithm", valid_594242
  var valid_594243 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594243 = validateParameter(valid_594243, JString, required = false,
                                 default = nil)
  if valid_594243 != nil:
    section.add "X-Amz-SignedHeaders", valid_594243
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594245: Call_DescribeRobotApplication_594234; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes a robot application.
  ## 
  let valid = call_594245.validator(path, query, header, formData, body)
  let scheme = call_594245.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594245.url(scheme.get, call_594245.host, call_594245.base,
                         call_594245.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594245, url, valid)

proc call*(call_594246: Call_DescribeRobotApplication_594234; body: JsonNode): Recallable =
  ## describeRobotApplication
  ## Describes a robot application.
  ##   body: JObject (required)
  var body_594247 = newJObject()
  if body != nil:
    body_594247 = body
  result = call_594246.call(nil, nil, nil, nil, body_594247)

var describeRobotApplication* = Call_DescribeRobotApplication_594234(
    name: "describeRobotApplication", meth: HttpMethod.HttpPost,
    host: "robomaker.amazonaws.com", route: "/describeRobotApplication",
    validator: validate_DescribeRobotApplication_594235, base: "/",
    url: url_DescribeRobotApplication_594236, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeSimulationApplication_594248 = ref object of OpenApiRestCall_593389
proc url_DescribeSimulationApplication_594250(protocol: Scheme; host: string;
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

proc validate_DescribeSimulationApplication_594249(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Describes a simulation application.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594251 = header.getOrDefault("X-Amz-Signature")
  valid_594251 = validateParameter(valid_594251, JString, required = false,
                                 default = nil)
  if valid_594251 != nil:
    section.add "X-Amz-Signature", valid_594251
  var valid_594252 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594252 = validateParameter(valid_594252, JString, required = false,
                                 default = nil)
  if valid_594252 != nil:
    section.add "X-Amz-Content-Sha256", valid_594252
  var valid_594253 = header.getOrDefault("X-Amz-Date")
  valid_594253 = validateParameter(valid_594253, JString, required = false,
                                 default = nil)
  if valid_594253 != nil:
    section.add "X-Amz-Date", valid_594253
  var valid_594254 = header.getOrDefault("X-Amz-Credential")
  valid_594254 = validateParameter(valid_594254, JString, required = false,
                                 default = nil)
  if valid_594254 != nil:
    section.add "X-Amz-Credential", valid_594254
  var valid_594255 = header.getOrDefault("X-Amz-Security-Token")
  valid_594255 = validateParameter(valid_594255, JString, required = false,
                                 default = nil)
  if valid_594255 != nil:
    section.add "X-Amz-Security-Token", valid_594255
  var valid_594256 = header.getOrDefault("X-Amz-Algorithm")
  valid_594256 = validateParameter(valid_594256, JString, required = false,
                                 default = nil)
  if valid_594256 != nil:
    section.add "X-Amz-Algorithm", valid_594256
  var valid_594257 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594257 = validateParameter(valid_594257, JString, required = false,
                                 default = nil)
  if valid_594257 != nil:
    section.add "X-Amz-SignedHeaders", valid_594257
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594259: Call_DescribeSimulationApplication_594248; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes a simulation application.
  ## 
  let valid = call_594259.validator(path, query, header, formData, body)
  let scheme = call_594259.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594259.url(scheme.get, call_594259.host, call_594259.base,
                         call_594259.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594259, url, valid)

proc call*(call_594260: Call_DescribeSimulationApplication_594248; body: JsonNode): Recallable =
  ## describeSimulationApplication
  ## Describes a simulation application.
  ##   body: JObject (required)
  var body_594261 = newJObject()
  if body != nil:
    body_594261 = body
  result = call_594260.call(nil, nil, nil, nil, body_594261)

var describeSimulationApplication* = Call_DescribeSimulationApplication_594248(
    name: "describeSimulationApplication", meth: HttpMethod.HttpPost,
    host: "robomaker.amazonaws.com", route: "/describeSimulationApplication",
    validator: validate_DescribeSimulationApplication_594249, base: "/",
    url: url_DescribeSimulationApplication_594250,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeSimulationJob_594262 = ref object of OpenApiRestCall_593389
proc url_DescribeSimulationJob_594264(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeSimulationJob_594263(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Describes a simulation job.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594265 = header.getOrDefault("X-Amz-Signature")
  valid_594265 = validateParameter(valid_594265, JString, required = false,
                                 default = nil)
  if valid_594265 != nil:
    section.add "X-Amz-Signature", valid_594265
  var valid_594266 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594266 = validateParameter(valid_594266, JString, required = false,
                                 default = nil)
  if valid_594266 != nil:
    section.add "X-Amz-Content-Sha256", valid_594266
  var valid_594267 = header.getOrDefault("X-Amz-Date")
  valid_594267 = validateParameter(valid_594267, JString, required = false,
                                 default = nil)
  if valid_594267 != nil:
    section.add "X-Amz-Date", valid_594267
  var valid_594268 = header.getOrDefault("X-Amz-Credential")
  valid_594268 = validateParameter(valid_594268, JString, required = false,
                                 default = nil)
  if valid_594268 != nil:
    section.add "X-Amz-Credential", valid_594268
  var valid_594269 = header.getOrDefault("X-Amz-Security-Token")
  valid_594269 = validateParameter(valid_594269, JString, required = false,
                                 default = nil)
  if valid_594269 != nil:
    section.add "X-Amz-Security-Token", valid_594269
  var valid_594270 = header.getOrDefault("X-Amz-Algorithm")
  valid_594270 = validateParameter(valid_594270, JString, required = false,
                                 default = nil)
  if valid_594270 != nil:
    section.add "X-Amz-Algorithm", valid_594270
  var valid_594271 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594271 = validateParameter(valid_594271, JString, required = false,
                                 default = nil)
  if valid_594271 != nil:
    section.add "X-Amz-SignedHeaders", valid_594271
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594273: Call_DescribeSimulationJob_594262; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes a simulation job.
  ## 
  let valid = call_594273.validator(path, query, header, formData, body)
  let scheme = call_594273.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594273.url(scheme.get, call_594273.host, call_594273.base,
                         call_594273.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594273, url, valid)

proc call*(call_594274: Call_DescribeSimulationJob_594262; body: JsonNode): Recallable =
  ## describeSimulationJob
  ## Describes a simulation job.
  ##   body: JObject (required)
  var body_594275 = newJObject()
  if body != nil:
    body_594275 = body
  result = call_594274.call(nil, nil, nil, nil, body_594275)

var describeSimulationJob* = Call_DescribeSimulationJob_594262(
    name: "describeSimulationJob", meth: HttpMethod.HttpPost,
    host: "robomaker.amazonaws.com", route: "/describeSimulationJob",
    validator: validate_DescribeSimulationJob_594263, base: "/",
    url: url_DescribeSimulationJob_594264, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDeploymentJobs_594276 = ref object of OpenApiRestCall_593389
proc url_ListDeploymentJobs_594278(protocol: Scheme; host: string; base: string;
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

proc validate_ListDeploymentJobs_594277(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## <p>Returns a list of deployment jobs for a fleet. You can optionally provide filters to retrieve specific deployment jobs. </p> <note> <p> </p> </note>
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
  var valid_594279 = query.getOrDefault("nextToken")
  valid_594279 = validateParameter(valid_594279, JString, required = false,
                                 default = nil)
  if valid_594279 != nil:
    section.add "nextToken", valid_594279
  var valid_594280 = query.getOrDefault("maxResults")
  valid_594280 = validateParameter(valid_594280, JString, required = false,
                                 default = nil)
  if valid_594280 != nil:
    section.add "maxResults", valid_594280
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594281 = header.getOrDefault("X-Amz-Signature")
  valid_594281 = validateParameter(valid_594281, JString, required = false,
                                 default = nil)
  if valid_594281 != nil:
    section.add "X-Amz-Signature", valid_594281
  var valid_594282 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594282 = validateParameter(valid_594282, JString, required = false,
                                 default = nil)
  if valid_594282 != nil:
    section.add "X-Amz-Content-Sha256", valid_594282
  var valid_594283 = header.getOrDefault("X-Amz-Date")
  valid_594283 = validateParameter(valid_594283, JString, required = false,
                                 default = nil)
  if valid_594283 != nil:
    section.add "X-Amz-Date", valid_594283
  var valid_594284 = header.getOrDefault("X-Amz-Credential")
  valid_594284 = validateParameter(valid_594284, JString, required = false,
                                 default = nil)
  if valid_594284 != nil:
    section.add "X-Amz-Credential", valid_594284
  var valid_594285 = header.getOrDefault("X-Amz-Security-Token")
  valid_594285 = validateParameter(valid_594285, JString, required = false,
                                 default = nil)
  if valid_594285 != nil:
    section.add "X-Amz-Security-Token", valid_594285
  var valid_594286 = header.getOrDefault("X-Amz-Algorithm")
  valid_594286 = validateParameter(valid_594286, JString, required = false,
                                 default = nil)
  if valid_594286 != nil:
    section.add "X-Amz-Algorithm", valid_594286
  var valid_594287 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594287 = validateParameter(valid_594287, JString, required = false,
                                 default = nil)
  if valid_594287 != nil:
    section.add "X-Amz-SignedHeaders", valid_594287
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594289: Call_ListDeploymentJobs_594276; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of deployment jobs for a fleet. You can optionally provide filters to retrieve specific deployment jobs. </p> <note> <p> </p> </note>
  ## 
  let valid = call_594289.validator(path, query, header, formData, body)
  let scheme = call_594289.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594289.url(scheme.get, call_594289.host, call_594289.base,
                         call_594289.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594289, url, valid)

proc call*(call_594290: Call_ListDeploymentJobs_594276; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listDeploymentJobs
  ## <p>Returns a list of deployment jobs for a fleet. You can optionally provide filters to retrieve specific deployment jobs. </p> <note> <p> </p> </note>
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_594291 = newJObject()
  var body_594292 = newJObject()
  add(query_594291, "nextToken", newJString(nextToken))
  if body != nil:
    body_594292 = body
  add(query_594291, "maxResults", newJString(maxResults))
  result = call_594290.call(nil, query_594291, nil, nil, body_594292)

var listDeploymentJobs* = Call_ListDeploymentJobs_594276(
    name: "listDeploymentJobs", meth: HttpMethod.HttpPost,
    host: "robomaker.amazonaws.com", route: "/listDeploymentJobs",
    validator: validate_ListDeploymentJobs_594277, base: "/",
    url: url_ListDeploymentJobs_594278, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListFleets_594294 = ref object of OpenApiRestCall_593389
proc url_ListFleets_594296(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListFleets_594295(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a list of fleets. You can optionally provide filters to retrieve specific fleets. 
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
  var valid_594297 = query.getOrDefault("nextToken")
  valid_594297 = validateParameter(valid_594297, JString, required = false,
                                 default = nil)
  if valid_594297 != nil:
    section.add "nextToken", valid_594297
  var valid_594298 = query.getOrDefault("maxResults")
  valid_594298 = validateParameter(valid_594298, JString, required = false,
                                 default = nil)
  if valid_594298 != nil:
    section.add "maxResults", valid_594298
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594299 = header.getOrDefault("X-Amz-Signature")
  valid_594299 = validateParameter(valid_594299, JString, required = false,
                                 default = nil)
  if valid_594299 != nil:
    section.add "X-Amz-Signature", valid_594299
  var valid_594300 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594300 = validateParameter(valid_594300, JString, required = false,
                                 default = nil)
  if valid_594300 != nil:
    section.add "X-Amz-Content-Sha256", valid_594300
  var valid_594301 = header.getOrDefault("X-Amz-Date")
  valid_594301 = validateParameter(valid_594301, JString, required = false,
                                 default = nil)
  if valid_594301 != nil:
    section.add "X-Amz-Date", valid_594301
  var valid_594302 = header.getOrDefault("X-Amz-Credential")
  valid_594302 = validateParameter(valid_594302, JString, required = false,
                                 default = nil)
  if valid_594302 != nil:
    section.add "X-Amz-Credential", valid_594302
  var valid_594303 = header.getOrDefault("X-Amz-Security-Token")
  valid_594303 = validateParameter(valid_594303, JString, required = false,
                                 default = nil)
  if valid_594303 != nil:
    section.add "X-Amz-Security-Token", valid_594303
  var valid_594304 = header.getOrDefault("X-Amz-Algorithm")
  valid_594304 = validateParameter(valid_594304, JString, required = false,
                                 default = nil)
  if valid_594304 != nil:
    section.add "X-Amz-Algorithm", valid_594304
  var valid_594305 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594305 = validateParameter(valid_594305, JString, required = false,
                                 default = nil)
  if valid_594305 != nil:
    section.add "X-Amz-SignedHeaders", valid_594305
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594307: Call_ListFleets_594294; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of fleets. You can optionally provide filters to retrieve specific fleets. 
  ## 
  let valid = call_594307.validator(path, query, header, formData, body)
  let scheme = call_594307.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594307.url(scheme.get, call_594307.host, call_594307.base,
                         call_594307.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594307, url, valid)

proc call*(call_594308: Call_ListFleets_594294; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listFleets
  ## Returns a list of fleets. You can optionally provide filters to retrieve specific fleets. 
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_594309 = newJObject()
  var body_594310 = newJObject()
  add(query_594309, "nextToken", newJString(nextToken))
  if body != nil:
    body_594310 = body
  add(query_594309, "maxResults", newJString(maxResults))
  result = call_594308.call(nil, query_594309, nil, nil, body_594310)

var listFleets* = Call_ListFleets_594294(name: "listFleets",
                                      meth: HttpMethod.HttpPost,
                                      host: "robomaker.amazonaws.com",
                                      route: "/listFleets",
                                      validator: validate_ListFleets_594295,
                                      base: "/", url: url_ListFleets_594296,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRobotApplications_594311 = ref object of OpenApiRestCall_593389
proc url_ListRobotApplications_594313(protocol: Scheme; host: string; base: string;
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

proc validate_ListRobotApplications_594312(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a list of robot application. You can optionally provide filters to retrieve specific robot applications.
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
  var valid_594314 = query.getOrDefault("nextToken")
  valid_594314 = validateParameter(valid_594314, JString, required = false,
                                 default = nil)
  if valid_594314 != nil:
    section.add "nextToken", valid_594314
  var valid_594315 = query.getOrDefault("maxResults")
  valid_594315 = validateParameter(valid_594315, JString, required = false,
                                 default = nil)
  if valid_594315 != nil:
    section.add "maxResults", valid_594315
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594316 = header.getOrDefault("X-Amz-Signature")
  valid_594316 = validateParameter(valid_594316, JString, required = false,
                                 default = nil)
  if valid_594316 != nil:
    section.add "X-Amz-Signature", valid_594316
  var valid_594317 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594317 = validateParameter(valid_594317, JString, required = false,
                                 default = nil)
  if valid_594317 != nil:
    section.add "X-Amz-Content-Sha256", valid_594317
  var valid_594318 = header.getOrDefault("X-Amz-Date")
  valid_594318 = validateParameter(valid_594318, JString, required = false,
                                 default = nil)
  if valid_594318 != nil:
    section.add "X-Amz-Date", valid_594318
  var valid_594319 = header.getOrDefault("X-Amz-Credential")
  valid_594319 = validateParameter(valid_594319, JString, required = false,
                                 default = nil)
  if valid_594319 != nil:
    section.add "X-Amz-Credential", valid_594319
  var valid_594320 = header.getOrDefault("X-Amz-Security-Token")
  valid_594320 = validateParameter(valid_594320, JString, required = false,
                                 default = nil)
  if valid_594320 != nil:
    section.add "X-Amz-Security-Token", valid_594320
  var valid_594321 = header.getOrDefault("X-Amz-Algorithm")
  valid_594321 = validateParameter(valid_594321, JString, required = false,
                                 default = nil)
  if valid_594321 != nil:
    section.add "X-Amz-Algorithm", valid_594321
  var valid_594322 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594322 = validateParameter(valid_594322, JString, required = false,
                                 default = nil)
  if valid_594322 != nil:
    section.add "X-Amz-SignedHeaders", valid_594322
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594324: Call_ListRobotApplications_594311; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of robot application. You can optionally provide filters to retrieve specific robot applications.
  ## 
  let valid = call_594324.validator(path, query, header, formData, body)
  let scheme = call_594324.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594324.url(scheme.get, call_594324.host, call_594324.base,
                         call_594324.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594324, url, valid)

proc call*(call_594325: Call_ListRobotApplications_594311; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listRobotApplications
  ## Returns a list of robot application. You can optionally provide filters to retrieve specific robot applications.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_594326 = newJObject()
  var body_594327 = newJObject()
  add(query_594326, "nextToken", newJString(nextToken))
  if body != nil:
    body_594327 = body
  add(query_594326, "maxResults", newJString(maxResults))
  result = call_594325.call(nil, query_594326, nil, nil, body_594327)

var listRobotApplications* = Call_ListRobotApplications_594311(
    name: "listRobotApplications", meth: HttpMethod.HttpPost,
    host: "robomaker.amazonaws.com", route: "/listRobotApplications",
    validator: validate_ListRobotApplications_594312, base: "/",
    url: url_ListRobotApplications_594313, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRobots_594328 = ref object of OpenApiRestCall_593389
proc url_ListRobots_594330(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListRobots_594329(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a list of robots. You can optionally provide filters to retrieve specific robots.
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
  var valid_594331 = query.getOrDefault("nextToken")
  valid_594331 = validateParameter(valid_594331, JString, required = false,
                                 default = nil)
  if valid_594331 != nil:
    section.add "nextToken", valid_594331
  var valid_594332 = query.getOrDefault("maxResults")
  valid_594332 = validateParameter(valid_594332, JString, required = false,
                                 default = nil)
  if valid_594332 != nil:
    section.add "maxResults", valid_594332
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594333 = header.getOrDefault("X-Amz-Signature")
  valid_594333 = validateParameter(valid_594333, JString, required = false,
                                 default = nil)
  if valid_594333 != nil:
    section.add "X-Amz-Signature", valid_594333
  var valid_594334 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594334 = validateParameter(valid_594334, JString, required = false,
                                 default = nil)
  if valid_594334 != nil:
    section.add "X-Amz-Content-Sha256", valid_594334
  var valid_594335 = header.getOrDefault("X-Amz-Date")
  valid_594335 = validateParameter(valid_594335, JString, required = false,
                                 default = nil)
  if valid_594335 != nil:
    section.add "X-Amz-Date", valid_594335
  var valid_594336 = header.getOrDefault("X-Amz-Credential")
  valid_594336 = validateParameter(valid_594336, JString, required = false,
                                 default = nil)
  if valid_594336 != nil:
    section.add "X-Amz-Credential", valid_594336
  var valid_594337 = header.getOrDefault("X-Amz-Security-Token")
  valid_594337 = validateParameter(valid_594337, JString, required = false,
                                 default = nil)
  if valid_594337 != nil:
    section.add "X-Amz-Security-Token", valid_594337
  var valid_594338 = header.getOrDefault("X-Amz-Algorithm")
  valid_594338 = validateParameter(valid_594338, JString, required = false,
                                 default = nil)
  if valid_594338 != nil:
    section.add "X-Amz-Algorithm", valid_594338
  var valid_594339 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594339 = validateParameter(valid_594339, JString, required = false,
                                 default = nil)
  if valid_594339 != nil:
    section.add "X-Amz-SignedHeaders", valid_594339
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594341: Call_ListRobots_594328; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of robots. You can optionally provide filters to retrieve specific robots.
  ## 
  let valid = call_594341.validator(path, query, header, formData, body)
  let scheme = call_594341.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594341.url(scheme.get, call_594341.host, call_594341.base,
                         call_594341.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594341, url, valid)

proc call*(call_594342: Call_ListRobots_594328; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listRobots
  ## Returns a list of robots. You can optionally provide filters to retrieve specific robots.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_594343 = newJObject()
  var body_594344 = newJObject()
  add(query_594343, "nextToken", newJString(nextToken))
  if body != nil:
    body_594344 = body
  add(query_594343, "maxResults", newJString(maxResults))
  result = call_594342.call(nil, query_594343, nil, nil, body_594344)

var listRobots* = Call_ListRobots_594328(name: "listRobots",
                                      meth: HttpMethod.HttpPost,
                                      host: "robomaker.amazonaws.com",
                                      route: "/listRobots",
                                      validator: validate_ListRobots_594329,
                                      base: "/", url: url_ListRobots_594330,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSimulationApplications_594345 = ref object of OpenApiRestCall_593389
proc url_ListSimulationApplications_594347(protocol: Scheme; host: string;
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

proc validate_ListSimulationApplications_594346(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a list of simulation applications. You can optionally provide filters to retrieve specific simulation applications. 
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
  var valid_594348 = query.getOrDefault("nextToken")
  valid_594348 = validateParameter(valid_594348, JString, required = false,
                                 default = nil)
  if valid_594348 != nil:
    section.add "nextToken", valid_594348
  var valid_594349 = query.getOrDefault("maxResults")
  valid_594349 = validateParameter(valid_594349, JString, required = false,
                                 default = nil)
  if valid_594349 != nil:
    section.add "maxResults", valid_594349
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594350 = header.getOrDefault("X-Amz-Signature")
  valid_594350 = validateParameter(valid_594350, JString, required = false,
                                 default = nil)
  if valid_594350 != nil:
    section.add "X-Amz-Signature", valid_594350
  var valid_594351 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594351 = validateParameter(valid_594351, JString, required = false,
                                 default = nil)
  if valid_594351 != nil:
    section.add "X-Amz-Content-Sha256", valid_594351
  var valid_594352 = header.getOrDefault("X-Amz-Date")
  valid_594352 = validateParameter(valid_594352, JString, required = false,
                                 default = nil)
  if valid_594352 != nil:
    section.add "X-Amz-Date", valid_594352
  var valid_594353 = header.getOrDefault("X-Amz-Credential")
  valid_594353 = validateParameter(valid_594353, JString, required = false,
                                 default = nil)
  if valid_594353 != nil:
    section.add "X-Amz-Credential", valid_594353
  var valid_594354 = header.getOrDefault("X-Amz-Security-Token")
  valid_594354 = validateParameter(valid_594354, JString, required = false,
                                 default = nil)
  if valid_594354 != nil:
    section.add "X-Amz-Security-Token", valid_594354
  var valid_594355 = header.getOrDefault("X-Amz-Algorithm")
  valid_594355 = validateParameter(valid_594355, JString, required = false,
                                 default = nil)
  if valid_594355 != nil:
    section.add "X-Amz-Algorithm", valid_594355
  var valid_594356 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594356 = validateParameter(valid_594356, JString, required = false,
                                 default = nil)
  if valid_594356 != nil:
    section.add "X-Amz-SignedHeaders", valid_594356
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594358: Call_ListSimulationApplications_594345; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of simulation applications. You can optionally provide filters to retrieve specific simulation applications. 
  ## 
  let valid = call_594358.validator(path, query, header, formData, body)
  let scheme = call_594358.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594358.url(scheme.get, call_594358.host, call_594358.base,
                         call_594358.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594358, url, valid)

proc call*(call_594359: Call_ListSimulationApplications_594345; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listSimulationApplications
  ## Returns a list of simulation applications. You can optionally provide filters to retrieve specific simulation applications. 
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_594360 = newJObject()
  var body_594361 = newJObject()
  add(query_594360, "nextToken", newJString(nextToken))
  if body != nil:
    body_594361 = body
  add(query_594360, "maxResults", newJString(maxResults))
  result = call_594359.call(nil, query_594360, nil, nil, body_594361)

var listSimulationApplications* = Call_ListSimulationApplications_594345(
    name: "listSimulationApplications", meth: HttpMethod.HttpPost,
    host: "robomaker.amazonaws.com", route: "/listSimulationApplications",
    validator: validate_ListSimulationApplications_594346, base: "/",
    url: url_ListSimulationApplications_594347,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSimulationJobs_594362 = ref object of OpenApiRestCall_593389
proc url_ListSimulationJobs_594364(protocol: Scheme; host: string; base: string;
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

proc validate_ListSimulationJobs_594363(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Returns a list of simulation jobs. You can optionally provide filters to retrieve specific simulation jobs. 
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
  var valid_594365 = query.getOrDefault("nextToken")
  valid_594365 = validateParameter(valid_594365, JString, required = false,
                                 default = nil)
  if valid_594365 != nil:
    section.add "nextToken", valid_594365
  var valid_594366 = query.getOrDefault("maxResults")
  valid_594366 = validateParameter(valid_594366, JString, required = false,
                                 default = nil)
  if valid_594366 != nil:
    section.add "maxResults", valid_594366
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594367 = header.getOrDefault("X-Amz-Signature")
  valid_594367 = validateParameter(valid_594367, JString, required = false,
                                 default = nil)
  if valid_594367 != nil:
    section.add "X-Amz-Signature", valid_594367
  var valid_594368 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594368 = validateParameter(valid_594368, JString, required = false,
                                 default = nil)
  if valid_594368 != nil:
    section.add "X-Amz-Content-Sha256", valid_594368
  var valid_594369 = header.getOrDefault("X-Amz-Date")
  valid_594369 = validateParameter(valid_594369, JString, required = false,
                                 default = nil)
  if valid_594369 != nil:
    section.add "X-Amz-Date", valid_594369
  var valid_594370 = header.getOrDefault("X-Amz-Credential")
  valid_594370 = validateParameter(valid_594370, JString, required = false,
                                 default = nil)
  if valid_594370 != nil:
    section.add "X-Amz-Credential", valid_594370
  var valid_594371 = header.getOrDefault("X-Amz-Security-Token")
  valid_594371 = validateParameter(valid_594371, JString, required = false,
                                 default = nil)
  if valid_594371 != nil:
    section.add "X-Amz-Security-Token", valid_594371
  var valid_594372 = header.getOrDefault("X-Amz-Algorithm")
  valid_594372 = validateParameter(valid_594372, JString, required = false,
                                 default = nil)
  if valid_594372 != nil:
    section.add "X-Amz-Algorithm", valid_594372
  var valid_594373 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594373 = validateParameter(valid_594373, JString, required = false,
                                 default = nil)
  if valid_594373 != nil:
    section.add "X-Amz-SignedHeaders", valid_594373
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594375: Call_ListSimulationJobs_594362; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of simulation jobs. You can optionally provide filters to retrieve specific simulation jobs. 
  ## 
  let valid = call_594375.validator(path, query, header, formData, body)
  let scheme = call_594375.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594375.url(scheme.get, call_594375.host, call_594375.base,
                         call_594375.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594375, url, valid)

proc call*(call_594376: Call_ListSimulationJobs_594362; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listSimulationJobs
  ## Returns a list of simulation jobs. You can optionally provide filters to retrieve specific simulation jobs. 
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_594377 = newJObject()
  var body_594378 = newJObject()
  add(query_594377, "nextToken", newJString(nextToken))
  if body != nil:
    body_594378 = body
  add(query_594377, "maxResults", newJString(maxResults))
  result = call_594376.call(nil, query_594377, nil, nil, body_594378)

var listSimulationJobs* = Call_ListSimulationJobs_594362(
    name: "listSimulationJobs", meth: HttpMethod.HttpPost,
    host: "robomaker.amazonaws.com", route: "/listSimulationJobs",
    validator: validate_ListSimulationJobs_594363, base: "/",
    url: url_ListSimulationJobs_594364, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_594407 = ref object of OpenApiRestCall_593389
proc url_TagResource_594409(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "resourceArn" in path, "`resourceArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/tags/"),
               (kind: VariableSegment, value: "resourceArn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_TagResource_594408(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Adds or edits tags for a AWS RoboMaker resource.</p> <p>Each tag consists of a tag key and a tag value. Tag keys and tag values are both required, but tag values can be empty strings. </p> <p>For information about the rules that apply to tag keys and tag values, see <a href="https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/allocation-tag-restrictions.html">User-Defined Tag Restrictions</a> in the <i>AWS Billing and Cost Management User Guide</i>. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resourceArn: JString (required)
  ##              : The Amazon Resource Name (ARN) of the AWS RoboMaker resource you are tagging.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `resourceArn` field"
  var valid_594410 = path.getOrDefault("resourceArn")
  valid_594410 = validateParameter(valid_594410, JString, required = true,
                                 default = nil)
  if valid_594410 != nil:
    section.add "resourceArn", valid_594410
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594411 = header.getOrDefault("X-Amz-Signature")
  valid_594411 = validateParameter(valid_594411, JString, required = false,
                                 default = nil)
  if valid_594411 != nil:
    section.add "X-Amz-Signature", valid_594411
  var valid_594412 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594412 = validateParameter(valid_594412, JString, required = false,
                                 default = nil)
  if valid_594412 != nil:
    section.add "X-Amz-Content-Sha256", valid_594412
  var valid_594413 = header.getOrDefault("X-Amz-Date")
  valid_594413 = validateParameter(valid_594413, JString, required = false,
                                 default = nil)
  if valid_594413 != nil:
    section.add "X-Amz-Date", valid_594413
  var valid_594414 = header.getOrDefault("X-Amz-Credential")
  valid_594414 = validateParameter(valid_594414, JString, required = false,
                                 default = nil)
  if valid_594414 != nil:
    section.add "X-Amz-Credential", valid_594414
  var valid_594415 = header.getOrDefault("X-Amz-Security-Token")
  valid_594415 = validateParameter(valid_594415, JString, required = false,
                                 default = nil)
  if valid_594415 != nil:
    section.add "X-Amz-Security-Token", valid_594415
  var valid_594416 = header.getOrDefault("X-Amz-Algorithm")
  valid_594416 = validateParameter(valid_594416, JString, required = false,
                                 default = nil)
  if valid_594416 != nil:
    section.add "X-Amz-Algorithm", valid_594416
  var valid_594417 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594417 = validateParameter(valid_594417, JString, required = false,
                                 default = nil)
  if valid_594417 != nil:
    section.add "X-Amz-SignedHeaders", valid_594417
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594419: Call_TagResource_594407; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds or edits tags for a AWS RoboMaker resource.</p> <p>Each tag consists of a tag key and a tag value. Tag keys and tag values are both required, but tag values can be empty strings. </p> <p>For information about the rules that apply to tag keys and tag values, see <a href="https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/allocation-tag-restrictions.html">User-Defined Tag Restrictions</a> in the <i>AWS Billing and Cost Management User Guide</i>. </p>
  ## 
  let valid = call_594419.validator(path, query, header, formData, body)
  let scheme = call_594419.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594419.url(scheme.get, call_594419.host, call_594419.base,
                         call_594419.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594419, url, valid)

proc call*(call_594420: Call_TagResource_594407; resourceArn: string; body: JsonNode): Recallable =
  ## tagResource
  ## <p>Adds or edits tags for a AWS RoboMaker resource.</p> <p>Each tag consists of a tag key and a tag value. Tag keys and tag values are both required, but tag values can be empty strings. </p> <p>For information about the rules that apply to tag keys and tag values, see <a href="https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/allocation-tag-restrictions.html">User-Defined Tag Restrictions</a> in the <i>AWS Billing and Cost Management User Guide</i>. </p>
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the AWS RoboMaker resource you are tagging.
  ##   body: JObject (required)
  var path_594421 = newJObject()
  var body_594422 = newJObject()
  add(path_594421, "resourceArn", newJString(resourceArn))
  if body != nil:
    body_594422 = body
  result = call_594420.call(path_594421, nil, nil, nil, body_594422)

var tagResource* = Call_TagResource_594407(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "robomaker.amazonaws.com",
                                        route: "/tags/{resourceArn}",
                                        validator: validate_TagResource_594408,
                                        base: "/", url: url_TagResource_594409,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_594379 = ref object of OpenApiRestCall_593389
proc url_ListTagsForResource_594381(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "resourceArn" in path, "`resourceArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/tags/"),
               (kind: VariableSegment, value: "resourceArn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListTagsForResource_594380(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Lists all tags on a AWS RoboMaker resource.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resourceArn: JString (required)
  ##              : The AWS RoboMaker Amazon Resource Name (ARN) with tags to be listed.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `resourceArn` field"
  var valid_594396 = path.getOrDefault("resourceArn")
  valid_594396 = validateParameter(valid_594396, JString, required = true,
                                 default = nil)
  if valid_594396 != nil:
    section.add "resourceArn", valid_594396
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594397 = header.getOrDefault("X-Amz-Signature")
  valid_594397 = validateParameter(valid_594397, JString, required = false,
                                 default = nil)
  if valid_594397 != nil:
    section.add "X-Amz-Signature", valid_594397
  var valid_594398 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594398 = validateParameter(valid_594398, JString, required = false,
                                 default = nil)
  if valid_594398 != nil:
    section.add "X-Amz-Content-Sha256", valid_594398
  var valid_594399 = header.getOrDefault("X-Amz-Date")
  valid_594399 = validateParameter(valid_594399, JString, required = false,
                                 default = nil)
  if valid_594399 != nil:
    section.add "X-Amz-Date", valid_594399
  var valid_594400 = header.getOrDefault("X-Amz-Credential")
  valid_594400 = validateParameter(valid_594400, JString, required = false,
                                 default = nil)
  if valid_594400 != nil:
    section.add "X-Amz-Credential", valid_594400
  var valid_594401 = header.getOrDefault("X-Amz-Security-Token")
  valid_594401 = validateParameter(valid_594401, JString, required = false,
                                 default = nil)
  if valid_594401 != nil:
    section.add "X-Amz-Security-Token", valid_594401
  var valid_594402 = header.getOrDefault("X-Amz-Algorithm")
  valid_594402 = validateParameter(valid_594402, JString, required = false,
                                 default = nil)
  if valid_594402 != nil:
    section.add "X-Amz-Algorithm", valid_594402
  var valid_594403 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594403 = validateParameter(valid_594403, JString, required = false,
                                 default = nil)
  if valid_594403 != nil:
    section.add "X-Amz-SignedHeaders", valid_594403
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594404: Call_ListTagsForResource_594379; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all tags on a AWS RoboMaker resource.
  ## 
  let valid = call_594404.validator(path, query, header, formData, body)
  let scheme = call_594404.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594404.url(scheme.get, call_594404.host, call_594404.base,
                         call_594404.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594404, url, valid)

proc call*(call_594405: Call_ListTagsForResource_594379; resourceArn: string): Recallable =
  ## listTagsForResource
  ## Lists all tags on a AWS RoboMaker resource.
  ##   resourceArn: string (required)
  ##              : The AWS RoboMaker Amazon Resource Name (ARN) with tags to be listed.
  var path_594406 = newJObject()
  add(path_594406, "resourceArn", newJString(resourceArn))
  result = call_594405.call(path_594406, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_594379(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "robomaker.amazonaws.com", route: "/tags/{resourceArn}",
    validator: validate_ListTagsForResource_594380, base: "/",
    url: url_ListTagsForResource_594381, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RegisterRobot_594423 = ref object of OpenApiRestCall_593389
proc url_RegisterRobot_594425(protocol: Scheme; host: string; base: string;
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

proc validate_RegisterRobot_594424(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Registers a robot with a fleet.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594426 = header.getOrDefault("X-Amz-Signature")
  valid_594426 = validateParameter(valid_594426, JString, required = false,
                                 default = nil)
  if valid_594426 != nil:
    section.add "X-Amz-Signature", valid_594426
  var valid_594427 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594427 = validateParameter(valid_594427, JString, required = false,
                                 default = nil)
  if valid_594427 != nil:
    section.add "X-Amz-Content-Sha256", valid_594427
  var valid_594428 = header.getOrDefault("X-Amz-Date")
  valid_594428 = validateParameter(valid_594428, JString, required = false,
                                 default = nil)
  if valid_594428 != nil:
    section.add "X-Amz-Date", valid_594428
  var valid_594429 = header.getOrDefault("X-Amz-Credential")
  valid_594429 = validateParameter(valid_594429, JString, required = false,
                                 default = nil)
  if valid_594429 != nil:
    section.add "X-Amz-Credential", valid_594429
  var valid_594430 = header.getOrDefault("X-Amz-Security-Token")
  valid_594430 = validateParameter(valid_594430, JString, required = false,
                                 default = nil)
  if valid_594430 != nil:
    section.add "X-Amz-Security-Token", valid_594430
  var valid_594431 = header.getOrDefault("X-Amz-Algorithm")
  valid_594431 = validateParameter(valid_594431, JString, required = false,
                                 default = nil)
  if valid_594431 != nil:
    section.add "X-Amz-Algorithm", valid_594431
  var valid_594432 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594432 = validateParameter(valid_594432, JString, required = false,
                                 default = nil)
  if valid_594432 != nil:
    section.add "X-Amz-SignedHeaders", valid_594432
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594434: Call_RegisterRobot_594423; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Registers a robot with a fleet.
  ## 
  let valid = call_594434.validator(path, query, header, formData, body)
  let scheme = call_594434.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594434.url(scheme.get, call_594434.host, call_594434.base,
                         call_594434.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594434, url, valid)

proc call*(call_594435: Call_RegisterRobot_594423; body: JsonNode): Recallable =
  ## registerRobot
  ## Registers a robot with a fleet.
  ##   body: JObject (required)
  var body_594436 = newJObject()
  if body != nil:
    body_594436 = body
  result = call_594435.call(nil, nil, nil, nil, body_594436)

var registerRobot* = Call_RegisterRobot_594423(name: "registerRobot",
    meth: HttpMethod.HttpPost, host: "robomaker.amazonaws.com",
    route: "/registerRobot", validator: validate_RegisterRobot_594424, base: "/",
    url: url_RegisterRobot_594425, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RestartSimulationJob_594437 = ref object of OpenApiRestCall_593389
proc url_RestartSimulationJob_594439(protocol: Scheme; host: string; base: string;
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

proc validate_RestartSimulationJob_594438(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Restarts a running simulation job.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594440 = header.getOrDefault("X-Amz-Signature")
  valid_594440 = validateParameter(valid_594440, JString, required = false,
                                 default = nil)
  if valid_594440 != nil:
    section.add "X-Amz-Signature", valid_594440
  var valid_594441 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594441 = validateParameter(valid_594441, JString, required = false,
                                 default = nil)
  if valid_594441 != nil:
    section.add "X-Amz-Content-Sha256", valid_594441
  var valid_594442 = header.getOrDefault("X-Amz-Date")
  valid_594442 = validateParameter(valid_594442, JString, required = false,
                                 default = nil)
  if valid_594442 != nil:
    section.add "X-Amz-Date", valid_594442
  var valid_594443 = header.getOrDefault("X-Amz-Credential")
  valid_594443 = validateParameter(valid_594443, JString, required = false,
                                 default = nil)
  if valid_594443 != nil:
    section.add "X-Amz-Credential", valid_594443
  var valid_594444 = header.getOrDefault("X-Amz-Security-Token")
  valid_594444 = validateParameter(valid_594444, JString, required = false,
                                 default = nil)
  if valid_594444 != nil:
    section.add "X-Amz-Security-Token", valid_594444
  var valid_594445 = header.getOrDefault("X-Amz-Algorithm")
  valid_594445 = validateParameter(valid_594445, JString, required = false,
                                 default = nil)
  if valid_594445 != nil:
    section.add "X-Amz-Algorithm", valid_594445
  var valid_594446 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594446 = validateParameter(valid_594446, JString, required = false,
                                 default = nil)
  if valid_594446 != nil:
    section.add "X-Amz-SignedHeaders", valid_594446
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594448: Call_RestartSimulationJob_594437; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Restarts a running simulation job.
  ## 
  let valid = call_594448.validator(path, query, header, formData, body)
  let scheme = call_594448.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594448.url(scheme.get, call_594448.host, call_594448.base,
                         call_594448.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594448, url, valid)

proc call*(call_594449: Call_RestartSimulationJob_594437; body: JsonNode): Recallable =
  ## restartSimulationJob
  ## Restarts a running simulation job.
  ##   body: JObject (required)
  var body_594450 = newJObject()
  if body != nil:
    body_594450 = body
  result = call_594449.call(nil, nil, nil, nil, body_594450)

var restartSimulationJob* = Call_RestartSimulationJob_594437(
    name: "restartSimulationJob", meth: HttpMethod.HttpPost,
    host: "robomaker.amazonaws.com", route: "/restartSimulationJob",
    validator: validate_RestartSimulationJob_594438, base: "/",
    url: url_RestartSimulationJob_594439, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SyncDeploymentJob_594451 = ref object of OpenApiRestCall_593389
proc url_SyncDeploymentJob_594453(protocol: Scheme; host: string; base: string;
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

proc validate_SyncDeploymentJob_594452(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Syncrhonizes robots in a fleet to the latest deployment. This is helpful if robots were added after a deployment.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594454 = header.getOrDefault("X-Amz-Signature")
  valid_594454 = validateParameter(valid_594454, JString, required = false,
                                 default = nil)
  if valid_594454 != nil:
    section.add "X-Amz-Signature", valid_594454
  var valid_594455 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594455 = validateParameter(valid_594455, JString, required = false,
                                 default = nil)
  if valid_594455 != nil:
    section.add "X-Amz-Content-Sha256", valid_594455
  var valid_594456 = header.getOrDefault("X-Amz-Date")
  valid_594456 = validateParameter(valid_594456, JString, required = false,
                                 default = nil)
  if valid_594456 != nil:
    section.add "X-Amz-Date", valid_594456
  var valid_594457 = header.getOrDefault("X-Amz-Credential")
  valid_594457 = validateParameter(valid_594457, JString, required = false,
                                 default = nil)
  if valid_594457 != nil:
    section.add "X-Amz-Credential", valid_594457
  var valid_594458 = header.getOrDefault("X-Amz-Security-Token")
  valid_594458 = validateParameter(valid_594458, JString, required = false,
                                 default = nil)
  if valid_594458 != nil:
    section.add "X-Amz-Security-Token", valid_594458
  var valid_594459 = header.getOrDefault("X-Amz-Algorithm")
  valid_594459 = validateParameter(valid_594459, JString, required = false,
                                 default = nil)
  if valid_594459 != nil:
    section.add "X-Amz-Algorithm", valid_594459
  var valid_594460 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594460 = validateParameter(valid_594460, JString, required = false,
                                 default = nil)
  if valid_594460 != nil:
    section.add "X-Amz-SignedHeaders", valid_594460
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594462: Call_SyncDeploymentJob_594451; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Syncrhonizes robots in a fleet to the latest deployment. This is helpful if robots were added after a deployment.
  ## 
  let valid = call_594462.validator(path, query, header, formData, body)
  let scheme = call_594462.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594462.url(scheme.get, call_594462.host, call_594462.base,
                         call_594462.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594462, url, valid)

proc call*(call_594463: Call_SyncDeploymentJob_594451; body: JsonNode): Recallable =
  ## syncDeploymentJob
  ## Syncrhonizes robots in a fleet to the latest deployment. This is helpful if robots were added after a deployment.
  ##   body: JObject (required)
  var body_594464 = newJObject()
  if body != nil:
    body_594464 = body
  result = call_594463.call(nil, nil, nil, nil, body_594464)

var syncDeploymentJob* = Call_SyncDeploymentJob_594451(name: "syncDeploymentJob",
    meth: HttpMethod.HttpPost, host: "robomaker.amazonaws.com",
    route: "/syncDeploymentJob", validator: validate_SyncDeploymentJob_594452,
    base: "/", url: url_SyncDeploymentJob_594453,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_594465 = ref object of OpenApiRestCall_593389
proc url_UntagResource_594467(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "resourceArn" in path, "`resourceArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/tags/"),
               (kind: VariableSegment, value: "resourceArn"),
               (kind: ConstantSegment, value: "#tagKeys")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UntagResource_594466(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Removes the specified tags from the specified AWS RoboMaker resource.</p> <p>To remove a tag, specify the tag key. To change the tag value of an existing tag key, use <a href="https://docs.aws.amazon.com/robomaker/latest/dg/API_TagResource.html"> <code>TagResource</code> </a>. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resourceArn: JString (required)
  ##              : The Amazon Resource Name (ARN) of the AWS RoboMaker resource you are removing tags.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `resourceArn` field"
  var valid_594468 = path.getOrDefault("resourceArn")
  valid_594468 = validateParameter(valid_594468, JString, required = true,
                                 default = nil)
  if valid_594468 != nil:
    section.add "resourceArn", valid_594468
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          : A map that contains tag keys and tag values that will be unattached from the resource.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_594469 = query.getOrDefault("tagKeys")
  valid_594469 = validateParameter(valid_594469, JArray, required = true, default = nil)
  if valid_594469 != nil:
    section.add "tagKeys", valid_594469
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594470 = header.getOrDefault("X-Amz-Signature")
  valid_594470 = validateParameter(valid_594470, JString, required = false,
                                 default = nil)
  if valid_594470 != nil:
    section.add "X-Amz-Signature", valid_594470
  var valid_594471 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594471 = validateParameter(valid_594471, JString, required = false,
                                 default = nil)
  if valid_594471 != nil:
    section.add "X-Amz-Content-Sha256", valid_594471
  var valid_594472 = header.getOrDefault("X-Amz-Date")
  valid_594472 = validateParameter(valid_594472, JString, required = false,
                                 default = nil)
  if valid_594472 != nil:
    section.add "X-Amz-Date", valid_594472
  var valid_594473 = header.getOrDefault("X-Amz-Credential")
  valid_594473 = validateParameter(valid_594473, JString, required = false,
                                 default = nil)
  if valid_594473 != nil:
    section.add "X-Amz-Credential", valid_594473
  var valid_594474 = header.getOrDefault("X-Amz-Security-Token")
  valid_594474 = validateParameter(valid_594474, JString, required = false,
                                 default = nil)
  if valid_594474 != nil:
    section.add "X-Amz-Security-Token", valid_594474
  var valid_594475 = header.getOrDefault("X-Amz-Algorithm")
  valid_594475 = validateParameter(valid_594475, JString, required = false,
                                 default = nil)
  if valid_594475 != nil:
    section.add "X-Amz-Algorithm", valid_594475
  var valid_594476 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594476 = validateParameter(valid_594476, JString, required = false,
                                 default = nil)
  if valid_594476 != nil:
    section.add "X-Amz-SignedHeaders", valid_594476
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594477: Call_UntagResource_594465; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Removes the specified tags from the specified AWS RoboMaker resource.</p> <p>To remove a tag, specify the tag key. To change the tag value of an existing tag key, use <a href="https://docs.aws.amazon.com/robomaker/latest/dg/API_TagResource.html"> <code>TagResource</code> </a>. </p>
  ## 
  let valid = call_594477.validator(path, query, header, formData, body)
  let scheme = call_594477.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594477.url(scheme.get, call_594477.host, call_594477.base,
                         call_594477.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594477, url, valid)

proc call*(call_594478: Call_UntagResource_594465; resourceArn: string;
          tagKeys: JsonNode): Recallable =
  ## untagResource
  ## <p>Removes the specified tags from the specified AWS RoboMaker resource.</p> <p>To remove a tag, specify the tag key. To change the tag value of an existing tag key, use <a href="https://docs.aws.amazon.com/robomaker/latest/dg/API_TagResource.html"> <code>TagResource</code> </a>. </p>
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the AWS RoboMaker resource you are removing tags.
  ##   tagKeys: JArray (required)
  ##          : A map that contains tag keys and tag values that will be unattached from the resource.
  var path_594479 = newJObject()
  var query_594480 = newJObject()
  add(path_594479, "resourceArn", newJString(resourceArn))
  if tagKeys != nil:
    query_594480.add "tagKeys", tagKeys
  result = call_594478.call(path_594479, query_594480, nil, nil, nil)

var untagResource* = Call_UntagResource_594465(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "robomaker.amazonaws.com",
    route: "/tags/{resourceArn}#tagKeys", validator: validate_UntagResource_594466,
    base: "/", url: url_UntagResource_594467, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateRobotApplication_594481 = ref object of OpenApiRestCall_593389
proc url_UpdateRobotApplication_594483(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateRobotApplication_594482(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates a robot application.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594484 = header.getOrDefault("X-Amz-Signature")
  valid_594484 = validateParameter(valid_594484, JString, required = false,
                                 default = nil)
  if valid_594484 != nil:
    section.add "X-Amz-Signature", valid_594484
  var valid_594485 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594485 = validateParameter(valid_594485, JString, required = false,
                                 default = nil)
  if valid_594485 != nil:
    section.add "X-Amz-Content-Sha256", valid_594485
  var valid_594486 = header.getOrDefault("X-Amz-Date")
  valid_594486 = validateParameter(valid_594486, JString, required = false,
                                 default = nil)
  if valid_594486 != nil:
    section.add "X-Amz-Date", valid_594486
  var valid_594487 = header.getOrDefault("X-Amz-Credential")
  valid_594487 = validateParameter(valid_594487, JString, required = false,
                                 default = nil)
  if valid_594487 != nil:
    section.add "X-Amz-Credential", valid_594487
  var valid_594488 = header.getOrDefault("X-Amz-Security-Token")
  valid_594488 = validateParameter(valid_594488, JString, required = false,
                                 default = nil)
  if valid_594488 != nil:
    section.add "X-Amz-Security-Token", valid_594488
  var valid_594489 = header.getOrDefault("X-Amz-Algorithm")
  valid_594489 = validateParameter(valid_594489, JString, required = false,
                                 default = nil)
  if valid_594489 != nil:
    section.add "X-Amz-Algorithm", valid_594489
  var valid_594490 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594490 = validateParameter(valid_594490, JString, required = false,
                                 default = nil)
  if valid_594490 != nil:
    section.add "X-Amz-SignedHeaders", valid_594490
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594492: Call_UpdateRobotApplication_594481; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a robot application.
  ## 
  let valid = call_594492.validator(path, query, header, formData, body)
  let scheme = call_594492.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594492.url(scheme.get, call_594492.host, call_594492.base,
                         call_594492.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594492, url, valid)

proc call*(call_594493: Call_UpdateRobotApplication_594481; body: JsonNode): Recallable =
  ## updateRobotApplication
  ## Updates a robot application.
  ##   body: JObject (required)
  var body_594494 = newJObject()
  if body != nil:
    body_594494 = body
  result = call_594493.call(nil, nil, nil, nil, body_594494)

var updateRobotApplication* = Call_UpdateRobotApplication_594481(
    name: "updateRobotApplication", meth: HttpMethod.HttpPost,
    host: "robomaker.amazonaws.com", route: "/updateRobotApplication",
    validator: validate_UpdateRobotApplication_594482, base: "/",
    url: url_UpdateRobotApplication_594483, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateSimulationApplication_594495 = ref object of OpenApiRestCall_593389
proc url_UpdateSimulationApplication_594497(protocol: Scheme; host: string;
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

proc validate_UpdateSimulationApplication_594496(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates a simulation application.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594498 = header.getOrDefault("X-Amz-Signature")
  valid_594498 = validateParameter(valid_594498, JString, required = false,
                                 default = nil)
  if valid_594498 != nil:
    section.add "X-Amz-Signature", valid_594498
  var valid_594499 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594499 = validateParameter(valid_594499, JString, required = false,
                                 default = nil)
  if valid_594499 != nil:
    section.add "X-Amz-Content-Sha256", valid_594499
  var valid_594500 = header.getOrDefault("X-Amz-Date")
  valid_594500 = validateParameter(valid_594500, JString, required = false,
                                 default = nil)
  if valid_594500 != nil:
    section.add "X-Amz-Date", valid_594500
  var valid_594501 = header.getOrDefault("X-Amz-Credential")
  valid_594501 = validateParameter(valid_594501, JString, required = false,
                                 default = nil)
  if valid_594501 != nil:
    section.add "X-Amz-Credential", valid_594501
  var valid_594502 = header.getOrDefault("X-Amz-Security-Token")
  valid_594502 = validateParameter(valid_594502, JString, required = false,
                                 default = nil)
  if valid_594502 != nil:
    section.add "X-Amz-Security-Token", valid_594502
  var valid_594503 = header.getOrDefault("X-Amz-Algorithm")
  valid_594503 = validateParameter(valid_594503, JString, required = false,
                                 default = nil)
  if valid_594503 != nil:
    section.add "X-Amz-Algorithm", valid_594503
  var valid_594504 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594504 = validateParameter(valid_594504, JString, required = false,
                                 default = nil)
  if valid_594504 != nil:
    section.add "X-Amz-SignedHeaders", valid_594504
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594506: Call_UpdateSimulationApplication_594495; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a simulation application.
  ## 
  let valid = call_594506.validator(path, query, header, formData, body)
  let scheme = call_594506.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594506.url(scheme.get, call_594506.host, call_594506.base,
                         call_594506.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594506, url, valid)

proc call*(call_594507: Call_UpdateSimulationApplication_594495; body: JsonNode): Recallable =
  ## updateSimulationApplication
  ## Updates a simulation application.
  ##   body: JObject (required)
  var body_594508 = newJObject()
  if body != nil:
    body_594508 = body
  result = call_594507.call(nil, nil, nil, nil, body_594508)

var updateSimulationApplication* = Call_UpdateSimulationApplication_594495(
    name: "updateSimulationApplication", meth: HttpMethod.HttpPost,
    host: "robomaker.amazonaws.com", route: "/updateSimulationApplication",
    validator: validate_UpdateSimulationApplication_594496, base: "/",
    url: url_UpdateSimulationApplication_594497,
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
