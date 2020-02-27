
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5, httpcore,
  sigv4

## auto-generated via openapi macro
## title: Amazon Import/Export Snowball
## version: 2016-06-30
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## AWS Snowball is a petabyte-scale data transport solution that uses secure devices to transfer large amounts of data between your on-premises data centers and Amazon Simple Storage Service (Amazon S3). The Snowball commands described here provide access to the same functionality that is available in the AWS Snowball Management Console, which enables you to create and manage jobs for Snowball. To transfer data locally with a Snowball device, you'll need to use the Snowball client or the Amazon S3 API adapter for Snowball. For more information, see the <a href="https://docs.aws.amazon.com/AWSImportExport/latest/ug/api-reference.html">User Guide</a>.
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/snowball/
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
    url*: proc (protocol: Scheme; host: string; base: string; route: string;
              path: JsonNode; query: JsonNode): Uri

  OpenApiRestCall_616866 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_616866](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_616866): Option[Scheme] {.used.} =
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "snowball.ap-northeast-1.amazonaws.com", "ap-southeast-1": "snowball.ap-southeast-1.amazonaws.com",
                           "us-west-2": "snowball.us-west-2.amazonaws.com",
                           "eu-west-2": "snowball.eu-west-2.amazonaws.com", "ap-northeast-3": "snowball.ap-northeast-3.amazonaws.com", "eu-central-1": "snowball.eu-central-1.amazonaws.com",
                           "us-east-2": "snowball.us-east-2.amazonaws.com",
                           "us-east-1": "snowball.us-east-1.amazonaws.com", "cn-northwest-1": "snowball.cn-northwest-1.amazonaws.com.cn", "ap-northeast-2": "snowball.ap-northeast-2.amazonaws.com",
                           "ap-south-1": "snowball.ap-south-1.amazonaws.com",
                           "eu-north-1": "snowball.eu-north-1.amazonaws.com",
                           "us-west-1": "snowball.us-west-1.amazonaws.com", "us-gov-east-1": "snowball.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "snowball.eu-west-3.amazonaws.com", "cn-north-1": "snowball.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "snowball.sa-east-1.amazonaws.com",
                           "eu-west-1": "snowball.eu-west-1.amazonaws.com", "us-gov-west-1": "snowball.us-gov-west-1.amazonaws.com", "ap-southeast-2": "snowball.ap-southeast-2.amazonaws.com", "ca-central-1": "snowball.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "snowball.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "snowball.ap-southeast-1.amazonaws.com",
      "us-west-2": "snowball.us-west-2.amazonaws.com",
      "eu-west-2": "snowball.eu-west-2.amazonaws.com",
      "ap-northeast-3": "snowball.ap-northeast-3.amazonaws.com",
      "eu-central-1": "snowball.eu-central-1.amazonaws.com",
      "us-east-2": "snowball.us-east-2.amazonaws.com",
      "us-east-1": "snowball.us-east-1.amazonaws.com",
      "cn-northwest-1": "snowball.cn-northwest-1.amazonaws.com.cn",
      "ap-northeast-2": "snowball.ap-northeast-2.amazonaws.com",
      "ap-south-1": "snowball.ap-south-1.amazonaws.com",
      "eu-north-1": "snowball.eu-north-1.amazonaws.com",
      "us-west-1": "snowball.us-west-1.amazonaws.com",
      "us-gov-east-1": "snowball.us-gov-east-1.amazonaws.com",
      "eu-west-3": "snowball.eu-west-3.amazonaws.com",
      "cn-north-1": "snowball.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "snowball.sa-east-1.amazonaws.com",
      "eu-west-1": "snowball.eu-west-1.amazonaws.com",
      "us-gov-west-1": "snowball.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "snowball.ap-southeast-2.amazonaws.com",
      "ca-central-1": "snowball.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "snowball"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode; body: string = ""): Recallable {.
    base.}
type
  Call_CancelCluster_617205 = ref object of OpenApiRestCall_616866
proc url_CancelCluster_617207(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CancelCluster_617206(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
  ## Cancels a cluster job. You can only cancel a cluster job while it's in the <code>AwaitingQuorum</code> status. You'll have at least an hour after creating a cluster job to cancel it.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617319 = header.getOrDefault("X-Amz-Date")
  valid_617319 = validateParameter(valid_617319, JString, required = false,
                                 default = nil)
  if valid_617319 != nil:
    section.add "X-Amz-Date", valid_617319
  var valid_617320 = header.getOrDefault("X-Amz-Security-Token")
  valid_617320 = validateParameter(valid_617320, JString, required = false,
                                 default = nil)
  if valid_617320 != nil:
    section.add "X-Amz-Security-Token", valid_617320
  var valid_617321 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617321 = validateParameter(valid_617321, JString, required = false,
                                 default = nil)
  if valid_617321 != nil:
    section.add "X-Amz-Content-Sha256", valid_617321
  var valid_617322 = header.getOrDefault("X-Amz-Algorithm")
  valid_617322 = validateParameter(valid_617322, JString, required = false,
                                 default = nil)
  if valid_617322 != nil:
    section.add "X-Amz-Algorithm", valid_617322
  var valid_617323 = header.getOrDefault("X-Amz-Signature")
  valid_617323 = validateParameter(valid_617323, JString, required = false,
                                 default = nil)
  if valid_617323 != nil:
    section.add "X-Amz-Signature", valid_617323
  var valid_617324 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617324 = validateParameter(valid_617324, JString, required = false,
                                 default = nil)
  if valid_617324 != nil:
    section.add "X-Amz-SignedHeaders", valid_617324
  var valid_617338 = header.getOrDefault("X-Amz-Target")
  valid_617338 = validateParameter(valid_617338, JString, required = true, default = newJString(
      "AWSIESnowballJobManagementService.CancelCluster"))
  if valid_617338 != nil:
    section.add "X-Amz-Target", valid_617338
  var valid_617339 = header.getOrDefault("X-Amz-Credential")
  valid_617339 = validateParameter(valid_617339, JString, required = false,
                                 default = nil)
  if valid_617339 != nil:
    section.add "X-Amz-Credential", valid_617339
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617364: Call_CancelCluster_617205; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Cancels a cluster job. You can only cancel a cluster job while it's in the <code>AwaitingQuorum</code> status. You'll have at least an hour after creating a cluster job to cancel it.
  ## 
  let valid = call_617364.validator(path, query, header, formData, body, _)
  let scheme = call_617364.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617364.url(scheme.get, call_617364.host, call_617364.base,
                         call_617364.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617364, url, valid, _)

proc call*(call_617435: Call_CancelCluster_617205; body: JsonNode): Recallable =
  ## cancelCluster
  ## Cancels a cluster job. You can only cancel a cluster job while it's in the <code>AwaitingQuorum</code> status. You'll have at least an hour after creating a cluster job to cancel it.
  ##   body: JObject (required)
  var body_617436 = newJObject()
  if body != nil:
    body_617436 = body
  result = call_617435.call(nil, nil, nil, nil, body_617436)

var cancelCluster* = Call_CancelCluster_617205(name: "cancelCluster",
    meth: HttpMethod.HttpPost, host: "snowball.amazonaws.com",
    route: "/#X-Amz-Target=AWSIESnowballJobManagementService.CancelCluster",
    validator: validate_CancelCluster_617206, base: "/", url: url_CancelCluster_617207,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CancelJob_617477 = ref object of OpenApiRestCall_616866
proc url_CancelJob_617479(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CancelJob_617478(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
  ## Cancels the specified job. You can only cancel a job before its <code>JobState</code> value changes to <code>PreparingAppliance</code>. Requesting the <code>ListJobs</code> or <code>DescribeJob</code> action returns a job's <code>JobState</code> as part of the response element data returned.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617480 = header.getOrDefault("X-Amz-Date")
  valid_617480 = validateParameter(valid_617480, JString, required = false,
                                 default = nil)
  if valid_617480 != nil:
    section.add "X-Amz-Date", valid_617480
  var valid_617481 = header.getOrDefault("X-Amz-Security-Token")
  valid_617481 = validateParameter(valid_617481, JString, required = false,
                                 default = nil)
  if valid_617481 != nil:
    section.add "X-Amz-Security-Token", valid_617481
  var valid_617482 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617482 = validateParameter(valid_617482, JString, required = false,
                                 default = nil)
  if valid_617482 != nil:
    section.add "X-Amz-Content-Sha256", valid_617482
  var valid_617483 = header.getOrDefault("X-Amz-Algorithm")
  valid_617483 = validateParameter(valid_617483, JString, required = false,
                                 default = nil)
  if valid_617483 != nil:
    section.add "X-Amz-Algorithm", valid_617483
  var valid_617484 = header.getOrDefault("X-Amz-Signature")
  valid_617484 = validateParameter(valid_617484, JString, required = false,
                                 default = nil)
  if valid_617484 != nil:
    section.add "X-Amz-Signature", valid_617484
  var valid_617485 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617485 = validateParameter(valid_617485, JString, required = false,
                                 default = nil)
  if valid_617485 != nil:
    section.add "X-Amz-SignedHeaders", valid_617485
  var valid_617486 = header.getOrDefault("X-Amz-Target")
  valid_617486 = validateParameter(valid_617486, JString, required = true, default = newJString(
      "AWSIESnowballJobManagementService.CancelJob"))
  if valid_617486 != nil:
    section.add "X-Amz-Target", valid_617486
  var valid_617487 = header.getOrDefault("X-Amz-Credential")
  valid_617487 = validateParameter(valid_617487, JString, required = false,
                                 default = nil)
  if valid_617487 != nil:
    section.add "X-Amz-Credential", valid_617487
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617489: Call_CancelJob_617477; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Cancels the specified job. You can only cancel a job before its <code>JobState</code> value changes to <code>PreparingAppliance</code>. Requesting the <code>ListJobs</code> or <code>DescribeJob</code> action returns a job's <code>JobState</code> as part of the response element data returned.
  ## 
  let valid = call_617489.validator(path, query, header, formData, body, _)
  let scheme = call_617489.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617489.url(scheme.get, call_617489.host, call_617489.base,
                         call_617489.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617489, url, valid, _)

proc call*(call_617490: Call_CancelJob_617477; body: JsonNode): Recallable =
  ## cancelJob
  ## Cancels the specified job. You can only cancel a job before its <code>JobState</code> value changes to <code>PreparingAppliance</code>. Requesting the <code>ListJobs</code> or <code>DescribeJob</code> action returns a job's <code>JobState</code> as part of the response element data returned.
  ##   body: JObject (required)
  var body_617491 = newJObject()
  if body != nil:
    body_617491 = body
  result = call_617490.call(nil, nil, nil, nil, body_617491)

var cancelJob* = Call_CancelJob_617477(name: "cancelJob", meth: HttpMethod.HttpPost,
                                    host: "snowball.amazonaws.com", route: "/#X-Amz-Target=AWSIESnowballJobManagementService.CancelJob",
                                    validator: validate_CancelJob_617478,
                                    base: "/", url: url_CancelJob_617479,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateAddress_617492 = ref object of OpenApiRestCall_616866
proc url_CreateAddress_617494(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateAddress_617493(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
  ## Creates an address for a Snowball to be shipped to. In most regions, addresses are validated at the time of creation. The address you provide must be located within the serviceable area of your region. If the address is invalid or unsupported, then an exception is thrown.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617495 = header.getOrDefault("X-Amz-Date")
  valid_617495 = validateParameter(valid_617495, JString, required = false,
                                 default = nil)
  if valid_617495 != nil:
    section.add "X-Amz-Date", valid_617495
  var valid_617496 = header.getOrDefault("X-Amz-Security-Token")
  valid_617496 = validateParameter(valid_617496, JString, required = false,
                                 default = nil)
  if valid_617496 != nil:
    section.add "X-Amz-Security-Token", valid_617496
  var valid_617497 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617497 = validateParameter(valid_617497, JString, required = false,
                                 default = nil)
  if valid_617497 != nil:
    section.add "X-Amz-Content-Sha256", valid_617497
  var valid_617498 = header.getOrDefault("X-Amz-Algorithm")
  valid_617498 = validateParameter(valid_617498, JString, required = false,
                                 default = nil)
  if valid_617498 != nil:
    section.add "X-Amz-Algorithm", valid_617498
  var valid_617499 = header.getOrDefault("X-Amz-Signature")
  valid_617499 = validateParameter(valid_617499, JString, required = false,
                                 default = nil)
  if valid_617499 != nil:
    section.add "X-Amz-Signature", valid_617499
  var valid_617500 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617500 = validateParameter(valid_617500, JString, required = false,
                                 default = nil)
  if valid_617500 != nil:
    section.add "X-Amz-SignedHeaders", valid_617500
  var valid_617501 = header.getOrDefault("X-Amz-Target")
  valid_617501 = validateParameter(valid_617501, JString, required = true, default = newJString(
      "AWSIESnowballJobManagementService.CreateAddress"))
  if valid_617501 != nil:
    section.add "X-Amz-Target", valid_617501
  var valid_617502 = header.getOrDefault("X-Amz-Credential")
  valid_617502 = validateParameter(valid_617502, JString, required = false,
                                 default = nil)
  if valid_617502 != nil:
    section.add "X-Amz-Credential", valid_617502
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617504: Call_CreateAddress_617492; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates an address for a Snowball to be shipped to. In most regions, addresses are validated at the time of creation. The address you provide must be located within the serviceable area of your region. If the address is invalid or unsupported, then an exception is thrown.
  ## 
  let valid = call_617504.validator(path, query, header, formData, body, _)
  let scheme = call_617504.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617504.url(scheme.get, call_617504.host, call_617504.base,
                         call_617504.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617504, url, valid, _)

proc call*(call_617505: Call_CreateAddress_617492; body: JsonNode): Recallable =
  ## createAddress
  ## Creates an address for a Snowball to be shipped to. In most regions, addresses are validated at the time of creation. The address you provide must be located within the serviceable area of your region. If the address is invalid or unsupported, then an exception is thrown.
  ##   body: JObject (required)
  var body_617506 = newJObject()
  if body != nil:
    body_617506 = body
  result = call_617505.call(nil, nil, nil, nil, body_617506)

var createAddress* = Call_CreateAddress_617492(name: "createAddress",
    meth: HttpMethod.HttpPost, host: "snowball.amazonaws.com",
    route: "/#X-Amz-Target=AWSIESnowballJobManagementService.CreateAddress",
    validator: validate_CreateAddress_617493, base: "/", url: url_CreateAddress_617494,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateCluster_617507 = ref object of OpenApiRestCall_616866
proc url_CreateCluster_617509(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateCluster_617508(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
  ## Creates an empty cluster. Each cluster supports five nodes. You use the <a>CreateJob</a> action separately to create the jobs for each of these nodes. The cluster does not ship until these five node jobs have been created.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617510 = header.getOrDefault("X-Amz-Date")
  valid_617510 = validateParameter(valid_617510, JString, required = false,
                                 default = nil)
  if valid_617510 != nil:
    section.add "X-Amz-Date", valid_617510
  var valid_617511 = header.getOrDefault("X-Amz-Security-Token")
  valid_617511 = validateParameter(valid_617511, JString, required = false,
                                 default = nil)
  if valid_617511 != nil:
    section.add "X-Amz-Security-Token", valid_617511
  var valid_617512 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617512 = validateParameter(valid_617512, JString, required = false,
                                 default = nil)
  if valid_617512 != nil:
    section.add "X-Amz-Content-Sha256", valid_617512
  var valid_617513 = header.getOrDefault("X-Amz-Algorithm")
  valid_617513 = validateParameter(valid_617513, JString, required = false,
                                 default = nil)
  if valid_617513 != nil:
    section.add "X-Amz-Algorithm", valid_617513
  var valid_617514 = header.getOrDefault("X-Amz-Signature")
  valid_617514 = validateParameter(valid_617514, JString, required = false,
                                 default = nil)
  if valid_617514 != nil:
    section.add "X-Amz-Signature", valid_617514
  var valid_617515 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617515 = validateParameter(valid_617515, JString, required = false,
                                 default = nil)
  if valid_617515 != nil:
    section.add "X-Amz-SignedHeaders", valid_617515
  var valid_617516 = header.getOrDefault("X-Amz-Target")
  valid_617516 = validateParameter(valid_617516, JString, required = true, default = newJString(
      "AWSIESnowballJobManagementService.CreateCluster"))
  if valid_617516 != nil:
    section.add "X-Amz-Target", valid_617516
  var valid_617517 = header.getOrDefault("X-Amz-Credential")
  valid_617517 = validateParameter(valid_617517, JString, required = false,
                                 default = nil)
  if valid_617517 != nil:
    section.add "X-Amz-Credential", valid_617517
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617519: Call_CreateCluster_617507; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates an empty cluster. Each cluster supports five nodes. You use the <a>CreateJob</a> action separately to create the jobs for each of these nodes. The cluster does not ship until these five node jobs have been created.
  ## 
  let valid = call_617519.validator(path, query, header, formData, body, _)
  let scheme = call_617519.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617519.url(scheme.get, call_617519.host, call_617519.base,
                         call_617519.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617519, url, valid, _)

proc call*(call_617520: Call_CreateCluster_617507; body: JsonNode): Recallable =
  ## createCluster
  ## Creates an empty cluster. Each cluster supports five nodes. You use the <a>CreateJob</a> action separately to create the jobs for each of these nodes. The cluster does not ship until these five node jobs have been created.
  ##   body: JObject (required)
  var body_617521 = newJObject()
  if body != nil:
    body_617521 = body
  result = call_617520.call(nil, nil, nil, nil, body_617521)

var createCluster* = Call_CreateCluster_617507(name: "createCluster",
    meth: HttpMethod.HttpPost, host: "snowball.amazonaws.com",
    route: "/#X-Amz-Target=AWSIESnowballJobManagementService.CreateCluster",
    validator: validate_CreateCluster_617508, base: "/", url: url_CreateCluster_617509,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateJob_617522 = ref object of OpenApiRestCall_616866
proc url_CreateJob_617524(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateJob_617523(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
  ## Creates a job to import or export data between Amazon S3 and your on-premises data center. Your AWS account must have the right trust policies and permissions in place to create a job for Snowball. If you're creating a job for a node in a cluster, you only need to provide the <code>clusterId</code> value; the other job attributes are inherited from the cluster. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617525 = header.getOrDefault("X-Amz-Date")
  valid_617525 = validateParameter(valid_617525, JString, required = false,
                                 default = nil)
  if valid_617525 != nil:
    section.add "X-Amz-Date", valid_617525
  var valid_617526 = header.getOrDefault("X-Amz-Security-Token")
  valid_617526 = validateParameter(valid_617526, JString, required = false,
                                 default = nil)
  if valid_617526 != nil:
    section.add "X-Amz-Security-Token", valid_617526
  var valid_617527 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617527 = validateParameter(valid_617527, JString, required = false,
                                 default = nil)
  if valid_617527 != nil:
    section.add "X-Amz-Content-Sha256", valid_617527
  var valid_617528 = header.getOrDefault("X-Amz-Algorithm")
  valid_617528 = validateParameter(valid_617528, JString, required = false,
                                 default = nil)
  if valid_617528 != nil:
    section.add "X-Amz-Algorithm", valid_617528
  var valid_617529 = header.getOrDefault("X-Amz-Signature")
  valid_617529 = validateParameter(valid_617529, JString, required = false,
                                 default = nil)
  if valid_617529 != nil:
    section.add "X-Amz-Signature", valid_617529
  var valid_617530 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617530 = validateParameter(valid_617530, JString, required = false,
                                 default = nil)
  if valid_617530 != nil:
    section.add "X-Amz-SignedHeaders", valid_617530
  var valid_617531 = header.getOrDefault("X-Amz-Target")
  valid_617531 = validateParameter(valid_617531, JString, required = true, default = newJString(
      "AWSIESnowballJobManagementService.CreateJob"))
  if valid_617531 != nil:
    section.add "X-Amz-Target", valid_617531
  var valid_617532 = header.getOrDefault("X-Amz-Credential")
  valid_617532 = validateParameter(valid_617532, JString, required = false,
                                 default = nil)
  if valid_617532 != nil:
    section.add "X-Amz-Credential", valid_617532
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617534: Call_CreateJob_617522; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a job to import or export data between Amazon S3 and your on-premises data center. Your AWS account must have the right trust policies and permissions in place to create a job for Snowball. If you're creating a job for a node in a cluster, you only need to provide the <code>clusterId</code> value; the other job attributes are inherited from the cluster. 
  ## 
  let valid = call_617534.validator(path, query, header, formData, body, _)
  let scheme = call_617534.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617534.url(scheme.get, call_617534.host, call_617534.base,
                         call_617534.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617534, url, valid, _)

proc call*(call_617535: Call_CreateJob_617522; body: JsonNode): Recallable =
  ## createJob
  ## Creates a job to import or export data between Amazon S3 and your on-premises data center. Your AWS account must have the right trust policies and permissions in place to create a job for Snowball. If you're creating a job for a node in a cluster, you only need to provide the <code>clusterId</code> value; the other job attributes are inherited from the cluster. 
  ##   body: JObject (required)
  var body_617536 = newJObject()
  if body != nil:
    body_617536 = body
  result = call_617535.call(nil, nil, nil, nil, body_617536)

var createJob* = Call_CreateJob_617522(name: "createJob", meth: HttpMethod.HttpPost,
                                    host: "snowball.amazonaws.com", route: "/#X-Amz-Target=AWSIESnowballJobManagementService.CreateJob",
                                    validator: validate_CreateJob_617523,
                                    base: "/", url: url_CreateJob_617524,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAddress_617537 = ref object of OpenApiRestCall_616866
proc url_DescribeAddress_617539(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeAddress_617538(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode =
  ## Takes an <code>AddressId</code> and returns specific details about that address in the form of an <code>Address</code> object.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617540 = header.getOrDefault("X-Amz-Date")
  valid_617540 = validateParameter(valid_617540, JString, required = false,
                                 default = nil)
  if valid_617540 != nil:
    section.add "X-Amz-Date", valid_617540
  var valid_617541 = header.getOrDefault("X-Amz-Security-Token")
  valid_617541 = validateParameter(valid_617541, JString, required = false,
                                 default = nil)
  if valid_617541 != nil:
    section.add "X-Amz-Security-Token", valid_617541
  var valid_617542 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617542 = validateParameter(valid_617542, JString, required = false,
                                 default = nil)
  if valid_617542 != nil:
    section.add "X-Amz-Content-Sha256", valid_617542
  var valid_617543 = header.getOrDefault("X-Amz-Algorithm")
  valid_617543 = validateParameter(valid_617543, JString, required = false,
                                 default = nil)
  if valid_617543 != nil:
    section.add "X-Amz-Algorithm", valid_617543
  var valid_617544 = header.getOrDefault("X-Amz-Signature")
  valid_617544 = validateParameter(valid_617544, JString, required = false,
                                 default = nil)
  if valid_617544 != nil:
    section.add "X-Amz-Signature", valid_617544
  var valid_617545 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617545 = validateParameter(valid_617545, JString, required = false,
                                 default = nil)
  if valid_617545 != nil:
    section.add "X-Amz-SignedHeaders", valid_617545
  var valid_617546 = header.getOrDefault("X-Amz-Target")
  valid_617546 = validateParameter(valid_617546, JString, required = true, default = newJString(
      "AWSIESnowballJobManagementService.DescribeAddress"))
  if valid_617546 != nil:
    section.add "X-Amz-Target", valid_617546
  var valid_617547 = header.getOrDefault("X-Amz-Credential")
  valid_617547 = validateParameter(valid_617547, JString, required = false,
                                 default = nil)
  if valid_617547 != nil:
    section.add "X-Amz-Credential", valid_617547
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617549: Call_DescribeAddress_617537; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Takes an <code>AddressId</code> and returns specific details about that address in the form of an <code>Address</code> object.
  ## 
  let valid = call_617549.validator(path, query, header, formData, body, _)
  let scheme = call_617549.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617549.url(scheme.get, call_617549.host, call_617549.base,
                         call_617549.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617549, url, valid, _)

proc call*(call_617550: Call_DescribeAddress_617537; body: JsonNode): Recallable =
  ## describeAddress
  ## Takes an <code>AddressId</code> and returns specific details about that address in the form of an <code>Address</code> object.
  ##   body: JObject (required)
  var body_617551 = newJObject()
  if body != nil:
    body_617551 = body
  result = call_617550.call(nil, nil, nil, nil, body_617551)

var describeAddress* = Call_DescribeAddress_617537(name: "describeAddress",
    meth: HttpMethod.HttpPost, host: "snowball.amazonaws.com",
    route: "/#X-Amz-Target=AWSIESnowballJobManagementService.DescribeAddress",
    validator: validate_DescribeAddress_617538, base: "/", url: url_DescribeAddress_617539,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAddresses_617552 = ref object of OpenApiRestCall_616866
proc url_DescribeAddresses_617554(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeAddresses_617553(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode =
  ## Returns a specified number of <code>ADDRESS</code> objects. Calling this API in one of the US regions will return addresses from the list of all addresses associated with this account in all US regions.
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
  var valid_617555 = query.getOrDefault("NextToken")
  valid_617555 = validateParameter(valid_617555, JString, required = false,
                                 default = nil)
  if valid_617555 != nil:
    section.add "NextToken", valid_617555
  var valid_617556 = query.getOrDefault("MaxResults")
  valid_617556 = validateParameter(valid_617556, JString, required = false,
                                 default = nil)
  if valid_617556 != nil:
    section.add "MaxResults", valid_617556
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617557 = header.getOrDefault("X-Amz-Date")
  valid_617557 = validateParameter(valid_617557, JString, required = false,
                                 default = nil)
  if valid_617557 != nil:
    section.add "X-Amz-Date", valid_617557
  var valid_617558 = header.getOrDefault("X-Amz-Security-Token")
  valid_617558 = validateParameter(valid_617558, JString, required = false,
                                 default = nil)
  if valid_617558 != nil:
    section.add "X-Amz-Security-Token", valid_617558
  var valid_617559 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617559 = validateParameter(valid_617559, JString, required = false,
                                 default = nil)
  if valid_617559 != nil:
    section.add "X-Amz-Content-Sha256", valid_617559
  var valid_617560 = header.getOrDefault("X-Amz-Algorithm")
  valid_617560 = validateParameter(valid_617560, JString, required = false,
                                 default = nil)
  if valid_617560 != nil:
    section.add "X-Amz-Algorithm", valid_617560
  var valid_617561 = header.getOrDefault("X-Amz-Signature")
  valid_617561 = validateParameter(valid_617561, JString, required = false,
                                 default = nil)
  if valid_617561 != nil:
    section.add "X-Amz-Signature", valid_617561
  var valid_617562 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617562 = validateParameter(valid_617562, JString, required = false,
                                 default = nil)
  if valid_617562 != nil:
    section.add "X-Amz-SignedHeaders", valid_617562
  var valid_617563 = header.getOrDefault("X-Amz-Target")
  valid_617563 = validateParameter(valid_617563, JString, required = true, default = newJString(
      "AWSIESnowballJobManagementService.DescribeAddresses"))
  if valid_617563 != nil:
    section.add "X-Amz-Target", valid_617563
  var valid_617564 = header.getOrDefault("X-Amz-Credential")
  valid_617564 = validateParameter(valid_617564, JString, required = false,
                                 default = nil)
  if valid_617564 != nil:
    section.add "X-Amz-Credential", valid_617564
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617566: Call_DescribeAddresses_617552; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a specified number of <code>ADDRESS</code> objects. Calling this API in one of the US regions will return addresses from the list of all addresses associated with this account in all US regions.
  ## 
  let valid = call_617566.validator(path, query, header, formData, body, _)
  let scheme = call_617566.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617566.url(scheme.get, call_617566.host, call_617566.base,
                         call_617566.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617566, url, valid, _)

proc call*(call_617567: Call_DescribeAddresses_617552; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## describeAddresses
  ## Returns a specified number of <code>ADDRESS</code> objects. Calling this API in one of the US regions will return addresses from the list of all addresses associated with this account in all US regions.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_617568 = newJObject()
  var body_617569 = newJObject()
  add(query_617568, "NextToken", newJString(NextToken))
  if body != nil:
    body_617569 = body
  add(query_617568, "MaxResults", newJString(MaxResults))
  result = call_617567.call(nil, query_617568, nil, nil, body_617569)

var describeAddresses* = Call_DescribeAddresses_617552(name: "describeAddresses",
    meth: HttpMethod.HttpPost, host: "snowball.amazonaws.com", route: "/#X-Amz-Target=AWSIESnowballJobManagementService.DescribeAddresses",
    validator: validate_DescribeAddresses_617553, base: "/",
    url: url_DescribeAddresses_617554, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeCluster_617571 = ref object of OpenApiRestCall_616866
proc url_DescribeCluster_617573(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeCluster_617572(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode =
  ## Returns information about a specific cluster including shipping information, cluster status, and other important metadata.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617574 = header.getOrDefault("X-Amz-Date")
  valid_617574 = validateParameter(valid_617574, JString, required = false,
                                 default = nil)
  if valid_617574 != nil:
    section.add "X-Amz-Date", valid_617574
  var valid_617575 = header.getOrDefault("X-Amz-Security-Token")
  valid_617575 = validateParameter(valid_617575, JString, required = false,
                                 default = nil)
  if valid_617575 != nil:
    section.add "X-Amz-Security-Token", valid_617575
  var valid_617576 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617576 = validateParameter(valid_617576, JString, required = false,
                                 default = nil)
  if valid_617576 != nil:
    section.add "X-Amz-Content-Sha256", valid_617576
  var valid_617577 = header.getOrDefault("X-Amz-Algorithm")
  valid_617577 = validateParameter(valid_617577, JString, required = false,
                                 default = nil)
  if valid_617577 != nil:
    section.add "X-Amz-Algorithm", valid_617577
  var valid_617578 = header.getOrDefault("X-Amz-Signature")
  valid_617578 = validateParameter(valid_617578, JString, required = false,
                                 default = nil)
  if valid_617578 != nil:
    section.add "X-Amz-Signature", valid_617578
  var valid_617579 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617579 = validateParameter(valid_617579, JString, required = false,
                                 default = nil)
  if valid_617579 != nil:
    section.add "X-Amz-SignedHeaders", valid_617579
  var valid_617580 = header.getOrDefault("X-Amz-Target")
  valid_617580 = validateParameter(valid_617580, JString, required = true, default = newJString(
      "AWSIESnowballJobManagementService.DescribeCluster"))
  if valid_617580 != nil:
    section.add "X-Amz-Target", valid_617580
  var valid_617581 = header.getOrDefault("X-Amz-Credential")
  valid_617581 = validateParameter(valid_617581, JString, required = false,
                                 default = nil)
  if valid_617581 != nil:
    section.add "X-Amz-Credential", valid_617581
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617583: Call_DescribeCluster_617571; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns information about a specific cluster including shipping information, cluster status, and other important metadata.
  ## 
  let valid = call_617583.validator(path, query, header, formData, body, _)
  let scheme = call_617583.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617583.url(scheme.get, call_617583.host, call_617583.base,
                         call_617583.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617583, url, valid, _)

proc call*(call_617584: Call_DescribeCluster_617571; body: JsonNode): Recallable =
  ## describeCluster
  ## Returns information about a specific cluster including shipping information, cluster status, and other important metadata.
  ##   body: JObject (required)
  var body_617585 = newJObject()
  if body != nil:
    body_617585 = body
  result = call_617584.call(nil, nil, nil, nil, body_617585)

var describeCluster* = Call_DescribeCluster_617571(name: "describeCluster",
    meth: HttpMethod.HttpPost, host: "snowball.amazonaws.com",
    route: "/#X-Amz-Target=AWSIESnowballJobManagementService.DescribeCluster",
    validator: validate_DescribeCluster_617572, base: "/", url: url_DescribeCluster_617573,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeJob_617586 = ref object of OpenApiRestCall_616866
proc url_DescribeJob_617588(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeJob_617587(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
  ## Returns information about a specific job including shipping information, job status, and other important metadata. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617589 = header.getOrDefault("X-Amz-Date")
  valid_617589 = validateParameter(valid_617589, JString, required = false,
                                 default = nil)
  if valid_617589 != nil:
    section.add "X-Amz-Date", valid_617589
  var valid_617590 = header.getOrDefault("X-Amz-Security-Token")
  valid_617590 = validateParameter(valid_617590, JString, required = false,
                                 default = nil)
  if valid_617590 != nil:
    section.add "X-Amz-Security-Token", valid_617590
  var valid_617591 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617591 = validateParameter(valid_617591, JString, required = false,
                                 default = nil)
  if valid_617591 != nil:
    section.add "X-Amz-Content-Sha256", valid_617591
  var valid_617592 = header.getOrDefault("X-Amz-Algorithm")
  valid_617592 = validateParameter(valid_617592, JString, required = false,
                                 default = nil)
  if valid_617592 != nil:
    section.add "X-Amz-Algorithm", valid_617592
  var valid_617593 = header.getOrDefault("X-Amz-Signature")
  valid_617593 = validateParameter(valid_617593, JString, required = false,
                                 default = nil)
  if valid_617593 != nil:
    section.add "X-Amz-Signature", valid_617593
  var valid_617594 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617594 = validateParameter(valid_617594, JString, required = false,
                                 default = nil)
  if valid_617594 != nil:
    section.add "X-Amz-SignedHeaders", valid_617594
  var valid_617595 = header.getOrDefault("X-Amz-Target")
  valid_617595 = validateParameter(valid_617595, JString, required = true, default = newJString(
      "AWSIESnowballJobManagementService.DescribeJob"))
  if valid_617595 != nil:
    section.add "X-Amz-Target", valid_617595
  var valid_617596 = header.getOrDefault("X-Amz-Credential")
  valid_617596 = validateParameter(valid_617596, JString, required = false,
                                 default = nil)
  if valid_617596 != nil:
    section.add "X-Amz-Credential", valid_617596
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617598: Call_DescribeJob_617586; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns information about a specific job including shipping information, job status, and other important metadata. 
  ## 
  let valid = call_617598.validator(path, query, header, formData, body, _)
  let scheme = call_617598.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617598.url(scheme.get, call_617598.host, call_617598.base,
                         call_617598.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617598, url, valid, _)

proc call*(call_617599: Call_DescribeJob_617586; body: JsonNode): Recallable =
  ## describeJob
  ## Returns information about a specific job including shipping information, job status, and other important metadata. 
  ##   body: JObject (required)
  var body_617600 = newJObject()
  if body != nil:
    body_617600 = body
  result = call_617599.call(nil, nil, nil, nil, body_617600)

var describeJob* = Call_DescribeJob_617586(name: "describeJob",
                                        meth: HttpMethod.HttpPost,
                                        host: "snowball.amazonaws.com", route: "/#X-Amz-Target=AWSIESnowballJobManagementService.DescribeJob",
                                        validator: validate_DescribeJob_617587,
                                        base: "/", url: url_DescribeJob_617588,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetJobManifest_617601 = ref object of OpenApiRestCall_616866
proc url_GetJobManifest_617603(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetJobManifest_617602(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode =
  ## <p>Returns a link to an Amazon S3 presigned URL for the manifest file associated with the specified <code>JobId</code> value. You can access the manifest file for up to 60 minutes after this request has been made. To access the manifest file after 60 minutes have passed, you'll have to make another call to the <code>GetJobManifest</code> action.</p> <p>The manifest is an encrypted file that you can download after your job enters the <code>WithCustomer</code> status. The manifest is decrypted by using the <code>UnlockCode</code> code value, when you pass both values to the Snowball through the Snowball client when the client is started for the first time.</p> <p>As a best practice, we recommend that you don't save a copy of an <code>UnlockCode</code> value in the same location as the manifest file for that job. Saving these separately helps prevent unauthorized parties from gaining access to the Snowball associated with that job.</p> <p>The credentials of a given job, including its manifest file and unlock code, expire 90 days after the job is created.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617604 = header.getOrDefault("X-Amz-Date")
  valid_617604 = validateParameter(valid_617604, JString, required = false,
                                 default = nil)
  if valid_617604 != nil:
    section.add "X-Amz-Date", valid_617604
  var valid_617605 = header.getOrDefault("X-Amz-Security-Token")
  valid_617605 = validateParameter(valid_617605, JString, required = false,
                                 default = nil)
  if valid_617605 != nil:
    section.add "X-Amz-Security-Token", valid_617605
  var valid_617606 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617606 = validateParameter(valid_617606, JString, required = false,
                                 default = nil)
  if valid_617606 != nil:
    section.add "X-Amz-Content-Sha256", valid_617606
  var valid_617607 = header.getOrDefault("X-Amz-Algorithm")
  valid_617607 = validateParameter(valid_617607, JString, required = false,
                                 default = nil)
  if valid_617607 != nil:
    section.add "X-Amz-Algorithm", valid_617607
  var valid_617608 = header.getOrDefault("X-Amz-Signature")
  valid_617608 = validateParameter(valid_617608, JString, required = false,
                                 default = nil)
  if valid_617608 != nil:
    section.add "X-Amz-Signature", valid_617608
  var valid_617609 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617609 = validateParameter(valid_617609, JString, required = false,
                                 default = nil)
  if valid_617609 != nil:
    section.add "X-Amz-SignedHeaders", valid_617609
  var valid_617610 = header.getOrDefault("X-Amz-Target")
  valid_617610 = validateParameter(valid_617610, JString, required = true, default = newJString(
      "AWSIESnowballJobManagementService.GetJobManifest"))
  if valid_617610 != nil:
    section.add "X-Amz-Target", valid_617610
  var valid_617611 = header.getOrDefault("X-Amz-Credential")
  valid_617611 = validateParameter(valid_617611, JString, required = false,
                                 default = nil)
  if valid_617611 != nil:
    section.add "X-Amz-Credential", valid_617611
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617613: Call_GetJobManifest_617601; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns a link to an Amazon S3 presigned URL for the manifest file associated with the specified <code>JobId</code> value. You can access the manifest file for up to 60 minutes after this request has been made. To access the manifest file after 60 minutes have passed, you'll have to make another call to the <code>GetJobManifest</code> action.</p> <p>The manifest is an encrypted file that you can download after your job enters the <code>WithCustomer</code> status. The manifest is decrypted by using the <code>UnlockCode</code> code value, when you pass both values to the Snowball through the Snowball client when the client is started for the first time.</p> <p>As a best practice, we recommend that you don't save a copy of an <code>UnlockCode</code> value in the same location as the manifest file for that job. Saving these separately helps prevent unauthorized parties from gaining access to the Snowball associated with that job.</p> <p>The credentials of a given job, including its manifest file and unlock code, expire 90 days after the job is created.</p>
  ## 
  let valid = call_617613.validator(path, query, header, formData, body, _)
  let scheme = call_617613.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617613.url(scheme.get, call_617613.host, call_617613.base,
                         call_617613.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617613, url, valid, _)

proc call*(call_617614: Call_GetJobManifest_617601; body: JsonNode): Recallable =
  ## getJobManifest
  ## <p>Returns a link to an Amazon S3 presigned URL for the manifest file associated with the specified <code>JobId</code> value. You can access the manifest file for up to 60 minutes after this request has been made. To access the manifest file after 60 minutes have passed, you'll have to make another call to the <code>GetJobManifest</code> action.</p> <p>The manifest is an encrypted file that you can download after your job enters the <code>WithCustomer</code> status. The manifest is decrypted by using the <code>UnlockCode</code> code value, when you pass both values to the Snowball through the Snowball client when the client is started for the first time.</p> <p>As a best practice, we recommend that you don't save a copy of an <code>UnlockCode</code> value in the same location as the manifest file for that job. Saving these separately helps prevent unauthorized parties from gaining access to the Snowball associated with that job.</p> <p>The credentials of a given job, including its manifest file and unlock code, expire 90 days after the job is created.</p>
  ##   body: JObject (required)
  var body_617615 = newJObject()
  if body != nil:
    body_617615 = body
  result = call_617614.call(nil, nil, nil, nil, body_617615)

var getJobManifest* = Call_GetJobManifest_617601(name: "getJobManifest",
    meth: HttpMethod.HttpPost, host: "snowball.amazonaws.com",
    route: "/#X-Amz-Target=AWSIESnowballJobManagementService.GetJobManifest",
    validator: validate_GetJobManifest_617602, base: "/", url: url_GetJobManifest_617603,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetJobUnlockCode_617616 = ref object of OpenApiRestCall_616866
proc url_GetJobUnlockCode_617618(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetJobUnlockCode_617617(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode =
  ## <p>Returns the <code>UnlockCode</code> code value for the specified job. A particular <code>UnlockCode</code> value can be accessed for up to 90 days after the associated job has been created.</p> <p>The <code>UnlockCode</code> value is a 29-character code with 25 alphanumeric characters and 4 hyphens. This code is used to decrypt the manifest file when it is passed along with the manifest to the Snowball through the Snowball client when the client is started for the first time.</p> <p>As a best practice, we recommend that you don't save a copy of the <code>UnlockCode</code> in the same location as the manifest file for that job. Saving these separately helps prevent unauthorized parties from gaining access to the Snowball associated with that job.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617619 = header.getOrDefault("X-Amz-Date")
  valid_617619 = validateParameter(valid_617619, JString, required = false,
                                 default = nil)
  if valid_617619 != nil:
    section.add "X-Amz-Date", valid_617619
  var valid_617620 = header.getOrDefault("X-Amz-Security-Token")
  valid_617620 = validateParameter(valid_617620, JString, required = false,
                                 default = nil)
  if valid_617620 != nil:
    section.add "X-Amz-Security-Token", valid_617620
  var valid_617621 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617621 = validateParameter(valid_617621, JString, required = false,
                                 default = nil)
  if valid_617621 != nil:
    section.add "X-Amz-Content-Sha256", valid_617621
  var valid_617622 = header.getOrDefault("X-Amz-Algorithm")
  valid_617622 = validateParameter(valid_617622, JString, required = false,
                                 default = nil)
  if valid_617622 != nil:
    section.add "X-Amz-Algorithm", valid_617622
  var valid_617623 = header.getOrDefault("X-Amz-Signature")
  valid_617623 = validateParameter(valid_617623, JString, required = false,
                                 default = nil)
  if valid_617623 != nil:
    section.add "X-Amz-Signature", valid_617623
  var valid_617624 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617624 = validateParameter(valid_617624, JString, required = false,
                                 default = nil)
  if valid_617624 != nil:
    section.add "X-Amz-SignedHeaders", valid_617624
  var valid_617625 = header.getOrDefault("X-Amz-Target")
  valid_617625 = validateParameter(valid_617625, JString, required = true, default = newJString(
      "AWSIESnowballJobManagementService.GetJobUnlockCode"))
  if valid_617625 != nil:
    section.add "X-Amz-Target", valid_617625
  var valid_617626 = header.getOrDefault("X-Amz-Credential")
  valid_617626 = validateParameter(valid_617626, JString, required = false,
                                 default = nil)
  if valid_617626 != nil:
    section.add "X-Amz-Credential", valid_617626
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617628: Call_GetJobUnlockCode_617616; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns the <code>UnlockCode</code> code value for the specified job. A particular <code>UnlockCode</code> value can be accessed for up to 90 days after the associated job has been created.</p> <p>The <code>UnlockCode</code> value is a 29-character code with 25 alphanumeric characters and 4 hyphens. This code is used to decrypt the manifest file when it is passed along with the manifest to the Snowball through the Snowball client when the client is started for the first time.</p> <p>As a best practice, we recommend that you don't save a copy of the <code>UnlockCode</code> in the same location as the manifest file for that job. Saving these separately helps prevent unauthorized parties from gaining access to the Snowball associated with that job.</p>
  ## 
  let valid = call_617628.validator(path, query, header, formData, body, _)
  let scheme = call_617628.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617628.url(scheme.get, call_617628.host, call_617628.base,
                         call_617628.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617628, url, valid, _)

proc call*(call_617629: Call_GetJobUnlockCode_617616; body: JsonNode): Recallable =
  ## getJobUnlockCode
  ## <p>Returns the <code>UnlockCode</code> code value for the specified job. A particular <code>UnlockCode</code> value can be accessed for up to 90 days after the associated job has been created.</p> <p>The <code>UnlockCode</code> value is a 29-character code with 25 alphanumeric characters and 4 hyphens. This code is used to decrypt the manifest file when it is passed along with the manifest to the Snowball through the Snowball client when the client is started for the first time.</p> <p>As a best practice, we recommend that you don't save a copy of the <code>UnlockCode</code> in the same location as the manifest file for that job. Saving these separately helps prevent unauthorized parties from gaining access to the Snowball associated with that job.</p>
  ##   body: JObject (required)
  var body_617630 = newJObject()
  if body != nil:
    body_617630 = body
  result = call_617629.call(nil, nil, nil, nil, body_617630)

var getJobUnlockCode* = Call_GetJobUnlockCode_617616(name: "getJobUnlockCode",
    meth: HttpMethod.HttpPost, host: "snowball.amazonaws.com",
    route: "/#X-Amz-Target=AWSIESnowballJobManagementService.GetJobUnlockCode",
    validator: validate_GetJobUnlockCode_617617, base: "/",
    url: url_GetJobUnlockCode_617618, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSnowballUsage_617631 = ref object of OpenApiRestCall_616866
proc url_GetSnowballUsage_617633(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetSnowballUsage_617632(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode =
  ## <p>Returns information about the Snowball service limit for your account, and also the number of Snowballs your account has in use.</p> <p>The default service limit for the number of Snowballs that you can have at one time is 1. If you want to increase your service limit, contact AWS Support.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617634 = header.getOrDefault("X-Amz-Date")
  valid_617634 = validateParameter(valid_617634, JString, required = false,
                                 default = nil)
  if valid_617634 != nil:
    section.add "X-Amz-Date", valid_617634
  var valid_617635 = header.getOrDefault("X-Amz-Security-Token")
  valid_617635 = validateParameter(valid_617635, JString, required = false,
                                 default = nil)
  if valid_617635 != nil:
    section.add "X-Amz-Security-Token", valid_617635
  var valid_617636 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617636 = validateParameter(valid_617636, JString, required = false,
                                 default = nil)
  if valid_617636 != nil:
    section.add "X-Amz-Content-Sha256", valid_617636
  var valid_617637 = header.getOrDefault("X-Amz-Algorithm")
  valid_617637 = validateParameter(valid_617637, JString, required = false,
                                 default = nil)
  if valid_617637 != nil:
    section.add "X-Amz-Algorithm", valid_617637
  var valid_617638 = header.getOrDefault("X-Amz-Signature")
  valid_617638 = validateParameter(valid_617638, JString, required = false,
                                 default = nil)
  if valid_617638 != nil:
    section.add "X-Amz-Signature", valid_617638
  var valid_617639 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617639 = validateParameter(valid_617639, JString, required = false,
                                 default = nil)
  if valid_617639 != nil:
    section.add "X-Amz-SignedHeaders", valid_617639
  var valid_617640 = header.getOrDefault("X-Amz-Target")
  valid_617640 = validateParameter(valid_617640, JString, required = true, default = newJString(
      "AWSIESnowballJobManagementService.GetSnowballUsage"))
  if valid_617640 != nil:
    section.add "X-Amz-Target", valid_617640
  var valid_617641 = header.getOrDefault("X-Amz-Credential")
  valid_617641 = validateParameter(valid_617641, JString, required = false,
                                 default = nil)
  if valid_617641 != nil:
    section.add "X-Amz-Credential", valid_617641
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617643: Call_GetSnowballUsage_617631; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns information about the Snowball service limit for your account, and also the number of Snowballs your account has in use.</p> <p>The default service limit for the number of Snowballs that you can have at one time is 1. If you want to increase your service limit, contact AWS Support.</p>
  ## 
  let valid = call_617643.validator(path, query, header, formData, body, _)
  let scheme = call_617643.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617643.url(scheme.get, call_617643.host, call_617643.base,
                         call_617643.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617643, url, valid, _)

proc call*(call_617644: Call_GetSnowballUsage_617631; body: JsonNode): Recallable =
  ## getSnowballUsage
  ## <p>Returns information about the Snowball service limit for your account, and also the number of Snowballs your account has in use.</p> <p>The default service limit for the number of Snowballs that you can have at one time is 1. If you want to increase your service limit, contact AWS Support.</p>
  ##   body: JObject (required)
  var body_617645 = newJObject()
  if body != nil:
    body_617645 = body
  result = call_617644.call(nil, nil, nil, nil, body_617645)

var getSnowballUsage* = Call_GetSnowballUsage_617631(name: "getSnowballUsage",
    meth: HttpMethod.HttpPost, host: "snowball.amazonaws.com",
    route: "/#X-Amz-Target=AWSIESnowballJobManagementService.GetSnowballUsage",
    validator: validate_GetSnowballUsage_617632, base: "/",
    url: url_GetSnowballUsage_617633, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSoftwareUpdates_617646 = ref object of OpenApiRestCall_616866
proc url_GetSoftwareUpdates_617648(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetSoftwareUpdates_617647(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode =
  ## Returns an Amazon S3 presigned URL for an update file associated with a specified <code>JobId</code>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617649 = header.getOrDefault("X-Amz-Date")
  valid_617649 = validateParameter(valid_617649, JString, required = false,
                                 default = nil)
  if valid_617649 != nil:
    section.add "X-Amz-Date", valid_617649
  var valid_617650 = header.getOrDefault("X-Amz-Security-Token")
  valid_617650 = validateParameter(valid_617650, JString, required = false,
                                 default = nil)
  if valid_617650 != nil:
    section.add "X-Amz-Security-Token", valid_617650
  var valid_617651 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617651 = validateParameter(valid_617651, JString, required = false,
                                 default = nil)
  if valid_617651 != nil:
    section.add "X-Amz-Content-Sha256", valid_617651
  var valid_617652 = header.getOrDefault("X-Amz-Algorithm")
  valid_617652 = validateParameter(valid_617652, JString, required = false,
                                 default = nil)
  if valid_617652 != nil:
    section.add "X-Amz-Algorithm", valid_617652
  var valid_617653 = header.getOrDefault("X-Amz-Signature")
  valid_617653 = validateParameter(valid_617653, JString, required = false,
                                 default = nil)
  if valid_617653 != nil:
    section.add "X-Amz-Signature", valid_617653
  var valid_617654 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617654 = validateParameter(valid_617654, JString, required = false,
                                 default = nil)
  if valid_617654 != nil:
    section.add "X-Amz-SignedHeaders", valid_617654
  var valid_617655 = header.getOrDefault("X-Amz-Target")
  valid_617655 = validateParameter(valid_617655, JString, required = true, default = newJString(
      "AWSIESnowballJobManagementService.GetSoftwareUpdates"))
  if valid_617655 != nil:
    section.add "X-Amz-Target", valid_617655
  var valid_617656 = header.getOrDefault("X-Amz-Credential")
  valid_617656 = validateParameter(valid_617656, JString, required = false,
                                 default = nil)
  if valid_617656 != nil:
    section.add "X-Amz-Credential", valid_617656
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617658: Call_GetSoftwareUpdates_617646; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns an Amazon S3 presigned URL for an update file associated with a specified <code>JobId</code>.
  ## 
  let valid = call_617658.validator(path, query, header, formData, body, _)
  let scheme = call_617658.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617658.url(scheme.get, call_617658.host, call_617658.base,
                         call_617658.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617658, url, valid, _)

proc call*(call_617659: Call_GetSoftwareUpdates_617646; body: JsonNode): Recallable =
  ## getSoftwareUpdates
  ## Returns an Amazon S3 presigned URL for an update file associated with a specified <code>JobId</code>.
  ##   body: JObject (required)
  var body_617660 = newJObject()
  if body != nil:
    body_617660 = body
  result = call_617659.call(nil, nil, nil, nil, body_617660)

var getSoftwareUpdates* = Call_GetSoftwareUpdates_617646(
    name: "getSoftwareUpdates", meth: HttpMethod.HttpPost,
    host: "snowball.amazonaws.com", route: "/#X-Amz-Target=AWSIESnowballJobManagementService.GetSoftwareUpdates",
    validator: validate_GetSoftwareUpdates_617647, base: "/",
    url: url_GetSoftwareUpdates_617648, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListClusterJobs_617661 = ref object of OpenApiRestCall_616866
proc url_ListClusterJobs_617663(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListClusterJobs_617662(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode =
  ## Returns an array of <code>JobListEntry</code> objects of the specified length. Each <code>JobListEntry</code> object is for a job in the specified cluster and contains a job's state, a job's ID, and other information.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617664 = header.getOrDefault("X-Amz-Date")
  valid_617664 = validateParameter(valid_617664, JString, required = false,
                                 default = nil)
  if valid_617664 != nil:
    section.add "X-Amz-Date", valid_617664
  var valid_617665 = header.getOrDefault("X-Amz-Security-Token")
  valid_617665 = validateParameter(valid_617665, JString, required = false,
                                 default = nil)
  if valid_617665 != nil:
    section.add "X-Amz-Security-Token", valid_617665
  var valid_617666 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617666 = validateParameter(valid_617666, JString, required = false,
                                 default = nil)
  if valid_617666 != nil:
    section.add "X-Amz-Content-Sha256", valid_617666
  var valid_617667 = header.getOrDefault("X-Amz-Algorithm")
  valid_617667 = validateParameter(valid_617667, JString, required = false,
                                 default = nil)
  if valid_617667 != nil:
    section.add "X-Amz-Algorithm", valid_617667
  var valid_617668 = header.getOrDefault("X-Amz-Signature")
  valid_617668 = validateParameter(valid_617668, JString, required = false,
                                 default = nil)
  if valid_617668 != nil:
    section.add "X-Amz-Signature", valid_617668
  var valid_617669 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617669 = validateParameter(valid_617669, JString, required = false,
                                 default = nil)
  if valid_617669 != nil:
    section.add "X-Amz-SignedHeaders", valid_617669
  var valid_617670 = header.getOrDefault("X-Amz-Target")
  valid_617670 = validateParameter(valid_617670, JString, required = true, default = newJString(
      "AWSIESnowballJobManagementService.ListClusterJobs"))
  if valid_617670 != nil:
    section.add "X-Amz-Target", valid_617670
  var valid_617671 = header.getOrDefault("X-Amz-Credential")
  valid_617671 = validateParameter(valid_617671, JString, required = false,
                                 default = nil)
  if valid_617671 != nil:
    section.add "X-Amz-Credential", valid_617671
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617673: Call_ListClusterJobs_617661; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns an array of <code>JobListEntry</code> objects of the specified length. Each <code>JobListEntry</code> object is for a job in the specified cluster and contains a job's state, a job's ID, and other information.
  ## 
  let valid = call_617673.validator(path, query, header, formData, body, _)
  let scheme = call_617673.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617673.url(scheme.get, call_617673.host, call_617673.base,
                         call_617673.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617673, url, valid, _)

proc call*(call_617674: Call_ListClusterJobs_617661; body: JsonNode): Recallable =
  ## listClusterJobs
  ## Returns an array of <code>JobListEntry</code> objects of the specified length. Each <code>JobListEntry</code> object is for a job in the specified cluster and contains a job's state, a job's ID, and other information.
  ##   body: JObject (required)
  var body_617675 = newJObject()
  if body != nil:
    body_617675 = body
  result = call_617674.call(nil, nil, nil, nil, body_617675)

var listClusterJobs* = Call_ListClusterJobs_617661(name: "listClusterJobs",
    meth: HttpMethod.HttpPost, host: "snowball.amazonaws.com",
    route: "/#X-Amz-Target=AWSIESnowballJobManagementService.ListClusterJobs",
    validator: validate_ListClusterJobs_617662, base: "/", url: url_ListClusterJobs_617663,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListClusters_617676 = ref object of OpenApiRestCall_616866
proc url_ListClusters_617678(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListClusters_617677(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
  ## Returns an array of <code>ClusterListEntry</code> objects of the specified length. Each <code>ClusterListEntry</code> object contains a cluster's state, a cluster's ID, and other important status information.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617679 = header.getOrDefault("X-Amz-Date")
  valid_617679 = validateParameter(valid_617679, JString, required = false,
                                 default = nil)
  if valid_617679 != nil:
    section.add "X-Amz-Date", valid_617679
  var valid_617680 = header.getOrDefault("X-Amz-Security-Token")
  valid_617680 = validateParameter(valid_617680, JString, required = false,
                                 default = nil)
  if valid_617680 != nil:
    section.add "X-Amz-Security-Token", valid_617680
  var valid_617681 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617681 = validateParameter(valid_617681, JString, required = false,
                                 default = nil)
  if valid_617681 != nil:
    section.add "X-Amz-Content-Sha256", valid_617681
  var valid_617682 = header.getOrDefault("X-Amz-Algorithm")
  valid_617682 = validateParameter(valid_617682, JString, required = false,
                                 default = nil)
  if valid_617682 != nil:
    section.add "X-Amz-Algorithm", valid_617682
  var valid_617683 = header.getOrDefault("X-Amz-Signature")
  valid_617683 = validateParameter(valid_617683, JString, required = false,
                                 default = nil)
  if valid_617683 != nil:
    section.add "X-Amz-Signature", valid_617683
  var valid_617684 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617684 = validateParameter(valid_617684, JString, required = false,
                                 default = nil)
  if valid_617684 != nil:
    section.add "X-Amz-SignedHeaders", valid_617684
  var valid_617685 = header.getOrDefault("X-Amz-Target")
  valid_617685 = validateParameter(valid_617685, JString, required = true, default = newJString(
      "AWSIESnowballJobManagementService.ListClusters"))
  if valid_617685 != nil:
    section.add "X-Amz-Target", valid_617685
  var valid_617686 = header.getOrDefault("X-Amz-Credential")
  valid_617686 = validateParameter(valid_617686, JString, required = false,
                                 default = nil)
  if valid_617686 != nil:
    section.add "X-Amz-Credential", valid_617686
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617688: Call_ListClusters_617676; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns an array of <code>ClusterListEntry</code> objects of the specified length. Each <code>ClusterListEntry</code> object contains a cluster's state, a cluster's ID, and other important status information.
  ## 
  let valid = call_617688.validator(path, query, header, formData, body, _)
  let scheme = call_617688.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617688.url(scheme.get, call_617688.host, call_617688.base,
                         call_617688.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617688, url, valid, _)

proc call*(call_617689: Call_ListClusters_617676; body: JsonNode): Recallable =
  ## listClusters
  ## Returns an array of <code>ClusterListEntry</code> objects of the specified length. Each <code>ClusterListEntry</code> object contains a cluster's state, a cluster's ID, and other important status information.
  ##   body: JObject (required)
  var body_617690 = newJObject()
  if body != nil:
    body_617690 = body
  result = call_617689.call(nil, nil, nil, nil, body_617690)

var listClusters* = Call_ListClusters_617676(name: "listClusters",
    meth: HttpMethod.HttpPost, host: "snowball.amazonaws.com",
    route: "/#X-Amz-Target=AWSIESnowballJobManagementService.ListClusters",
    validator: validate_ListClusters_617677, base: "/", url: url_ListClusters_617678,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListCompatibleImages_617691 = ref object of OpenApiRestCall_616866
proc url_ListCompatibleImages_617693(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListCompatibleImages_617692(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
  ## This action returns a list of the different Amazon EC2 Amazon Machine Images (AMIs) that are owned by your AWS account that would be supported for use on a Snowball Edge device. Currently, supported AMIs are based on the CentOS 7 (x86_64) - with Updates HVM, Ubuntu Server 14.04 LTS (HVM), and Ubuntu 16.04 LTS - Xenial (HVM) images, available on the AWS Marketplace.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617694 = header.getOrDefault("X-Amz-Date")
  valid_617694 = validateParameter(valid_617694, JString, required = false,
                                 default = nil)
  if valid_617694 != nil:
    section.add "X-Amz-Date", valid_617694
  var valid_617695 = header.getOrDefault("X-Amz-Security-Token")
  valid_617695 = validateParameter(valid_617695, JString, required = false,
                                 default = nil)
  if valid_617695 != nil:
    section.add "X-Amz-Security-Token", valid_617695
  var valid_617696 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617696 = validateParameter(valid_617696, JString, required = false,
                                 default = nil)
  if valid_617696 != nil:
    section.add "X-Amz-Content-Sha256", valid_617696
  var valid_617697 = header.getOrDefault("X-Amz-Algorithm")
  valid_617697 = validateParameter(valid_617697, JString, required = false,
                                 default = nil)
  if valid_617697 != nil:
    section.add "X-Amz-Algorithm", valid_617697
  var valid_617698 = header.getOrDefault("X-Amz-Signature")
  valid_617698 = validateParameter(valid_617698, JString, required = false,
                                 default = nil)
  if valid_617698 != nil:
    section.add "X-Amz-Signature", valid_617698
  var valid_617699 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617699 = validateParameter(valid_617699, JString, required = false,
                                 default = nil)
  if valid_617699 != nil:
    section.add "X-Amz-SignedHeaders", valid_617699
  var valid_617700 = header.getOrDefault("X-Amz-Target")
  valid_617700 = validateParameter(valid_617700, JString, required = true, default = newJString(
      "AWSIESnowballJobManagementService.ListCompatibleImages"))
  if valid_617700 != nil:
    section.add "X-Amz-Target", valid_617700
  var valid_617701 = header.getOrDefault("X-Amz-Credential")
  valid_617701 = validateParameter(valid_617701, JString, required = false,
                                 default = nil)
  if valid_617701 != nil:
    section.add "X-Amz-Credential", valid_617701
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617703: Call_ListCompatibleImages_617691; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## This action returns a list of the different Amazon EC2 Amazon Machine Images (AMIs) that are owned by your AWS account that would be supported for use on a Snowball Edge device. Currently, supported AMIs are based on the CentOS 7 (x86_64) - with Updates HVM, Ubuntu Server 14.04 LTS (HVM), and Ubuntu 16.04 LTS - Xenial (HVM) images, available on the AWS Marketplace.
  ## 
  let valid = call_617703.validator(path, query, header, formData, body, _)
  let scheme = call_617703.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617703.url(scheme.get, call_617703.host, call_617703.base,
                         call_617703.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617703, url, valid, _)

proc call*(call_617704: Call_ListCompatibleImages_617691; body: JsonNode): Recallable =
  ## listCompatibleImages
  ## This action returns a list of the different Amazon EC2 Amazon Machine Images (AMIs) that are owned by your AWS account that would be supported for use on a Snowball Edge device. Currently, supported AMIs are based on the CentOS 7 (x86_64) - with Updates HVM, Ubuntu Server 14.04 LTS (HVM), and Ubuntu 16.04 LTS - Xenial (HVM) images, available on the AWS Marketplace.
  ##   body: JObject (required)
  var body_617705 = newJObject()
  if body != nil:
    body_617705 = body
  result = call_617704.call(nil, nil, nil, nil, body_617705)

var listCompatibleImages* = Call_ListCompatibleImages_617691(
    name: "listCompatibleImages", meth: HttpMethod.HttpPost,
    host: "snowball.amazonaws.com", route: "/#X-Amz-Target=AWSIESnowballJobManagementService.ListCompatibleImages",
    validator: validate_ListCompatibleImages_617692, base: "/",
    url: url_ListCompatibleImages_617693, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListJobs_617706 = ref object of OpenApiRestCall_616866
proc url_ListJobs_617708(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListJobs_617707(path: JsonNode; query: JsonNode; header: JsonNode;
                             formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
  ## Returns an array of <code>JobListEntry</code> objects of the specified length. Each <code>JobListEntry</code> object contains a job's state, a job's ID, and a value that indicates whether the job is a job part, in the case of export jobs. Calling this API action in one of the US regions will return jobs from the list of all jobs associated with this account in all US regions.
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
  var valid_617709 = query.getOrDefault("NextToken")
  valid_617709 = validateParameter(valid_617709, JString, required = false,
                                 default = nil)
  if valid_617709 != nil:
    section.add "NextToken", valid_617709
  var valid_617710 = query.getOrDefault("MaxResults")
  valid_617710 = validateParameter(valid_617710, JString, required = false,
                                 default = nil)
  if valid_617710 != nil:
    section.add "MaxResults", valid_617710
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617711 = header.getOrDefault("X-Amz-Date")
  valid_617711 = validateParameter(valid_617711, JString, required = false,
                                 default = nil)
  if valid_617711 != nil:
    section.add "X-Amz-Date", valid_617711
  var valid_617712 = header.getOrDefault("X-Amz-Security-Token")
  valid_617712 = validateParameter(valid_617712, JString, required = false,
                                 default = nil)
  if valid_617712 != nil:
    section.add "X-Amz-Security-Token", valid_617712
  var valid_617713 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617713 = validateParameter(valid_617713, JString, required = false,
                                 default = nil)
  if valid_617713 != nil:
    section.add "X-Amz-Content-Sha256", valid_617713
  var valid_617714 = header.getOrDefault("X-Amz-Algorithm")
  valid_617714 = validateParameter(valid_617714, JString, required = false,
                                 default = nil)
  if valid_617714 != nil:
    section.add "X-Amz-Algorithm", valid_617714
  var valid_617715 = header.getOrDefault("X-Amz-Signature")
  valid_617715 = validateParameter(valid_617715, JString, required = false,
                                 default = nil)
  if valid_617715 != nil:
    section.add "X-Amz-Signature", valid_617715
  var valid_617716 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617716 = validateParameter(valid_617716, JString, required = false,
                                 default = nil)
  if valid_617716 != nil:
    section.add "X-Amz-SignedHeaders", valid_617716
  var valid_617717 = header.getOrDefault("X-Amz-Target")
  valid_617717 = validateParameter(valid_617717, JString, required = true, default = newJString(
      "AWSIESnowballJobManagementService.ListJobs"))
  if valid_617717 != nil:
    section.add "X-Amz-Target", valid_617717
  var valid_617718 = header.getOrDefault("X-Amz-Credential")
  valid_617718 = validateParameter(valid_617718, JString, required = false,
                                 default = nil)
  if valid_617718 != nil:
    section.add "X-Amz-Credential", valid_617718
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617720: Call_ListJobs_617706; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns an array of <code>JobListEntry</code> objects of the specified length. Each <code>JobListEntry</code> object contains a job's state, a job's ID, and a value that indicates whether the job is a job part, in the case of export jobs. Calling this API action in one of the US regions will return jobs from the list of all jobs associated with this account in all US regions.
  ## 
  let valid = call_617720.validator(path, query, header, formData, body, _)
  let scheme = call_617720.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617720.url(scheme.get, call_617720.host, call_617720.base,
                         call_617720.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617720, url, valid, _)

proc call*(call_617721: Call_ListJobs_617706; body: JsonNode; NextToken: string = "";
          MaxResults: string = ""): Recallable =
  ## listJobs
  ## Returns an array of <code>JobListEntry</code> objects of the specified length. Each <code>JobListEntry</code> object contains a job's state, a job's ID, and a value that indicates whether the job is a job part, in the case of export jobs. Calling this API action in one of the US regions will return jobs from the list of all jobs associated with this account in all US regions.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_617722 = newJObject()
  var body_617723 = newJObject()
  add(query_617722, "NextToken", newJString(NextToken))
  if body != nil:
    body_617723 = body
  add(query_617722, "MaxResults", newJString(MaxResults))
  result = call_617721.call(nil, query_617722, nil, nil, body_617723)

var listJobs* = Call_ListJobs_617706(name: "listJobs", meth: HttpMethod.HttpPost,
                                  host: "snowball.amazonaws.com", route: "/#X-Amz-Target=AWSIESnowballJobManagementService.ListJobs",
                                  validator: validate_ListJobs_617707, base: "/",
                                  url: url_ListJobs_617708,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateCluster_617724 = ref object of OpenApiRestCall_616866
proc url_UpdateCluster_617726(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateCluster_617725(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
  ## While a cluster's <code>ClusterState</code> value is in the <code>AwaitingQuorum</code> state, you can update some of the information associated with a cluster. Once the cluster changes to a different job state, usually 60 minutes after the cluster being created, this action is no longer available.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617727 = header.getOrDefault("X-Amz-Date")
  valid_617727 = validateParameter(valid_617727, JString, required = false,
                                 default = nil)
  if valid_617727 != nil:
    section.add "X-Amz-Date", valid_617727
  var valid_617728 = header.getOrDefault("X-Amz-Security-Token")
  valid_617728 = validateParameter(valid_617728, JString, required = false,
                                 default = nil)
  if valid_617728 != nil:
    section.add "X-Amz-Security-Token", valid_617728
  var valid_617729 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617729 = validateParameter(valid_617729, JString, required = false,
                                 default = nil)
  if valid_617729 != nil:
    section.add "X-Amz-Content-Sha256", valid_617729
  var valid_617730 = header.getOrDefault("X-Amz-Algorithm")
  valid_617730 = validateParameter(valid_617730, JString, required = false,
                                 default = nil)
  if valid_617730 != nil:
    section.add "X-Amz-Algorithm", valid_617730
  var valid_617731 = header.getOrDefault("X-Amz-Signature")
  valid_617731 = validateParameter(valid_617731, JString, required = false,
                                 default = nil)
  if valid_617731 != nil:
    section.add "X-Amz-Signature", valid_617731
  var valid_617732 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617732 = validateParameter(valid_617732, JString, required = false,
                                 default = nil)
  if valid_617732 != nil:
    section.add "X-Amz-SignedHeaders", valid_617732
  var valid_617733 = header.getOrDefault("X-Amz-Target")
  valid_617733 = validateParameter(valid_617733, JString, required = true, default = newJString(
      "AWSIESnowballJobManagementService.UpdateCluster"))
  if valid_617733 != nil:
    section.add "X-Amz-Target", valid_617733
  var valid_617734 = header.getOrDefault("X-Amz-Credential")
  valid_617734 = validateParameter(valid_617734, JString, required = false,
                                 default = nil)
  if valid_617734 != nil:
    section.add "X-Amz-Credential", valid_617734
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617736: Call_UpdateCluster_617724; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## While a cluster's <code>ClusterState</code> value is in the <code>AwaitingQuorum</code> state, you can update some of the information associated with a cluster. Once the cluster changes to a different job state, usually 60 minutes after the cluster being created, this action is no longer available.
  ## 
  let valid = call_617736.validator(path, query, header, formData, body, _)
  let scheme = call_617736.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617736.url(scheme.get, call_617736.host, call_617736.base,
                         call_617736.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617736, url, valid, _)

proc call*(call_617737: Call_UpdateCluster_617724; body: JsonNode): Recallable =
  ## updateCluster
  ## While a cluster's <code>ClusterState</code> value is in the <code>AwaitingQuorum</code> state, you can update some of the information associated with a cluster. Once the cluster changes to a different job state, usually 60 minutes after the cluster being created, this action is no longer available.
  ##   body: JObject (required)
  var body_617738 = newJObject()
  if body != nil:
    body_617738 = body
  result = call_617737.call(nil, nil, nil, nil, body_617738)

var updateCluster* = Call_UpdateCluster_617724(name: "updateCluster",
    meth: HttpMethod.HttpPost, host: "snowball.amazonaws.com",
    route: "/#X-Amz-Target=AWSIESnowballJobManagementService.UpdateCluster",
    validator: validate_UpdateCluster_617725, base: "/", url: url_UpdateCluster_617726,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateJob_617739 = ref object of OpenApiRestCall_616866
proc url_UpdateJob_617741(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateJob_617740(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
  ## While a job's <code>JobState</code> value is <code>New</code>, you can update some of the information associated with a job. Once the job changes to a different job state, usually within 60 minutes of the job being created, this action is no longer available.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617742 = header.getOrDefault("X-Amz-Date")
  valid_617742 = validateParameter(valid_617742, JString, required = false,
                                 default = nil)
  if valid_617742 != nil:
    section.add "X-Amz-Date", valid_617742
  var valid_617743 = header.getOrDefault("X-Amz-Security-Token")
  valid_617743 = validateParameter(valid_617743, JString, required = false,
                                 default = nil)
  if valid_617743 != nil:
    section.add "X-Amz-Security-Token", valid_617743
  var valid_617744 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617744 = validateParameter(valid_617744, JString, required = false,
                                 default = nil)
  if valid_617744 != nil:
    section.add "X-Amz-Content-Sha256", valid_617744
  var valid_617745 = header.getOrDefault("X-Amz-Algorithm")
  valid_617745 = validateParameter(valid_617745, JString, required = false,
                                 default = nil)
  if valid_617745 != nil:
    section.add "X-Amz-Algorithm", valid_617745
  var valid_617746 = header.getOrDefault("X-Amz-Signature")
  valid_617746 = validateParameter(valid_617746, JString, required = false,
                                 default = nil)
  if valid_617746 != nil:
    section.add "X-Amz-Signature", valid_617746
  var valid_617747 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617747 = validateParameter(valid_617747, JString, required = false,
                                 default = nil)
  if valid_617747 != nil:
    section.add "X-Amz-SignedHeaders", valid_617747
  var valid_617748 = header.getOrDefault("X-Amz-Target")
  valid_617748 = validateParameter(valid_617748, JString, required = true, default = newJString(
      "AWSIESnowballJobManagementService.UpdateJob"))
  if valid_617748 != nil:
    section.add "X-Amz-Target", valid_617748
  var valid_617749 = header.getOrDefault("X-Amz-Credential")
  valid_617749 = validateParameter(valid_617749, JString, required = false,
                                 default = nil)
  if valid_617749 != nil:
    section.add "X-Amz-Credential", valid_617749
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617751: Call_UpdateJob_617739; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## While a job's <code>JobState</code> value is <code>New</code>, you can update some of the information associated with a job. Once the job changes to a different job state, usually within 60 minutes of the job being created, this action is no longer available.
  ## 
  let valid = call_617751.validator(path, query, header, formData, body, _)
  let scheme = call_617751.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617751.url(scheme.get, call_617751.host, call_617751.base,
                         call_617751.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617751, url, valid, _)

proc call*(call_617752: Call_UpdateJob_617739; body: JsonNode): Recallable =
  ## updateJob
  ## While a job's <code>JobState</code> value is <code>New</code>, you can update some of the information associated with a job. Once the job changes to a different job state, usually within 60 minutes of the job being created, this action is no longer available.
  ##   body: JObject (required)
  var body_617753 = newJObject()
  if body != nil:
    body_617753 = body
  result = call_617752.call(nil, nil, nil, nil, body_617753)

var updateJob* = Call_UpdateJob_617739(name: "updateJob", meth: HttpMethod.HttpPost,
                                    host: "snowball.amazonaws.com", route: "/#X-Amz-Target=AWSIESnowballJobManagementService.UpdateJob",
                                    validator: validate_UpdateJob_617740,
                                    base: "/", url: url_UpdateJob_617741,
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
    headers["content-md5"] = $text.toMD5
  if not headers.hasKey($SecurityToken):
    let session = getEnv("AWS_SESSION_TOKEN", "")
    if session != "":
      headers[$SecurityToken] = session
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)
