
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

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

  OpenApiRestCall_601389 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_601389](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_601389): Option[Scheme] {.used.} =
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "snowball.ap-northeast-1.amazonaws.com", "ap-southeast-1": "snowball.ap-southeast-1.amazonaws.com",
                           "us-west-2": "snowball.us-west-2.amazonaws.com",
                           "eu-west-2": "snowball.eu-west-2.amazonaws.com", "ap-northeast-3": "snowball.ap-northeast-3.amazonaws.com", "eu-central-1": "snowball.eu-central-1.amazonaws.com",
                           "us-east-2": "snowball.us-east-2.amazonaws.com",
                           "us-east-1": "snowball.us-east-1.amazonaws.com", "cn-northwest-1": "snowball.cn-northwest-1.amazonaws.com.cn",
                           "ap-south-1": "snowball.ap-south-1.amazonaws.com",
                           "eu-north-1": "snowball.eu-north-1.amazonaws.com", "ap-northeast-2": "snowball.ap-northeast-2.amazonaws.com",
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
      "ap-south-1": "snowball.ap-south-1.amazonaws.com",
      "eu-north-1": "snowball.eu-north-1.amazonaws.com",
      "ap-northeast-2": "snowball.ap-northeast-2.amazonaws.com",
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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_CancelCluster_601727 = ref object of OpenApiRestCall_601389
proc url_CancelCluster_601729(protocol: Scheme; host: string; base: string;
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

proc validate_CancelCluster_601728(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Cancels a cluster job. You can only cancel a cluster job while it's in the <code>AwaitingQuorum</code> status. You'll have at least an hour after creating a cluster job to cancel it.
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
  var valid_601854 = header.getOrDefault("X-Amz-Target")
  valid_601854 = validateParameter(valid_601854, JString, required = true, default = newJString(
      "AWSIESnowballJobManagementService.CancelCluster"))
  if valid_601854 != nil:
    section.add "X-Amz-Target", valid_601854
  var valid_601855 = header.getOrDefault("X-Amz-Signature")
  valid_601855 = validateParameter(valid_601855, JString, required = false,
                                 default = nil)
  if valid_601855 != nil:
    section.add "X-Amz-Signature", valid_601855
  var valid_601856 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601856 = validateParameter(valid_601856, JString, required = false,
                                 default = nil)
  if valid_601856 != nil:
    section.add "X-Amz-Content-Sha256", valid_601856
  var valid_601857 = header.getOrDefault("X-Amz-Date")
  valid_601857 = validateParameter(valid_601857, JString, required = false,
                                 default = nil)
  if valid_601857 != nil:
    section.add "X-Amz-Date", valid_601857
  var valid_601858 = header.getOrDefault("X-Amz-Credential")
  valid_601858 = validateParameter(valid_601858, JString, required = false,
                                 default = nil)
  if valid_601858 != nil:
    section.add "X-Amz-Credential", valid_601858
  var valid_601859 = header.getOrDefault("X-Amz-Security-Token")
  valid_601859 = validateParameter(valid_601859, JString, required = false,
                                 default = nil)
  if valid_601859 != nil:
    section.add "X-Amz-Security-Token", valid_601859
  var valid_601860 = header.getOrDefault("X-Amz-Algorithm")
  valid_601860 = validateParameter(valid_601860, JString, required = false,
                                 default = nil)
  if valid_601860 != nil:
    section.add "X-Amz-Algorithm", valid_601860
  var valid_601861 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601861 = validateParameter(valid_601861, JString, required = false,
                                 default = nil)
  if valid_601861 != nil:
    section.add "X-Amz-SignedHeaders", valid_601861
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601885: Call_CancelCluster_601727; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Cancels a cluster job. You can only cancel a cluster job while it's in the <code>AwaitingQuorum</code> status. You'll have at least an hour after creating a cluster job to cancel it.
  ## 
  let valid = call_601885.validator(path, query, header, formData, body)
  let scheme = call_601885.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601885.url(scheme.get, call_601885.host, call_601885.base,
                         call_601885.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601885, url, valid)

proc call*(call_601956: Call_CancelCluster_601727; body: JsonNode): Recallable =
  ## cancelCluster
  ## Cancels a cluster job. You can only cancel a cluster job while it's in the <code>AwaitingQuorum</code> status. You'll have at least an hour after creating a cluster job to cancel it.
  ##   body: JObject (required)
  var body_601957 = newJObject()
  if body != nil:
    body_601957 = body
  result = call_601956.call(nil, nil, nil, nil, body_601957)

var cancelCluster* = Call_CancelCluster_601727(name: "cancelCluster",
    meth: HttpMethod.HttpPost, host: "snowball.amazonaws.com",
    route: "/#X-Amz-Target=AWSIESnowballJobManagementService.CancelCluster",
    validator: validate_CancelCluster_601728, base: "/", url: url_CancelCluster_601729,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CancelJob_601996 = ref object of OpenApiRestCall_601389
proc url_CancelJob_601998(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_CancelJob_601997(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## Cancels the specified job. You can only cancel a job before its <code>JobState</code> value changes to <code>PreparingAppliance</code>. Requesting the <code>ListJobs</code> or <code>DescribeJob</code> action returns a job's <code>JobState</code> as part of the response element data returned.
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
  var valid_601999 = header.getOrDefault("X-Amz-Target")
  valid_601999 = validateParameter(valid_601999, JString, required = true, default = newJString(
      "AWSIESnowballJobManagementService.CancelJob"))
  if valid_601999 != nil:
    section.add "X-Amz-Target", valid_601999
  var valid_602000 = header.getOrDefault("X-Amz-Signature")
  valid_602000 = validateParameter(valid_602000, JString, required = false,
                                 default = nil)
  if valid_602000 != nil:
    section.add "X-Amz-Signature", valid_602000
  var valid_602001 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602001 = validateParameter(valid_602001, JString, required = false,
                                 default = nil)
  if valid_602001 != nil:
    section.add "X-Amz-Content-Sha256", valid_602001
  var valid_602002 = header.getOrDefault("X-Amz-Date")
  valid_602002 = validateParameter(valid_602002, JString, required = false,
                                 default = nil)
  if valid_602002 != nil:
    section.add "X-Amz-Date", valid_602002
  var valid_602003 = header.getOrDefault("X-Amz-Credential")
  valid_602003 = validateParameter(valid_602003, JString, required = false,
                                 default = nil)
  if valid_602003 != nil:
    section.add "X-Amz-Credential", valid_602003
  var valid_602004 = header.getOrDefault("X-Amz-Security-Token")
  valid_602004 = validateParameter(valid_602004, JString, required = false,
                                 default = nil)
  if valid_602004 != nil:
    section.add "X-Amz-Security-Token", valid_602004
  var valid_602005 = header.getOrDefault("X-Amz-Algorithm")
  valid_602005 = validateParameter(valid_602005, JString, required = false,
                                 default = nil)
  if valid_602005 != nil:
    section.add "X-Amz-Algorithm", valid_602005
  var valid_602006 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602006 = validateParameter(valid_602006, JString, required = false,
                                 default = nil)
  if valid_602006 != nil:
    section.add "X-Amz-SignedHeaders", valid_602006
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602008: Call_CancelJob_601996; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Cancels the specified job. You can only cancel a job before its <code>JobState</code> value changes to <code>PreparingAppliance</code>. Requesting the <code>ListJobs</code> or <code>DescribeJob</code> action returns a job's <code>JobState</code> as part of the response element data returned.
  ## 
  let valid = call_602008.validator(path, query, header, formData, body)
  let scheme = call_602008.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602008.url(scheme.get, call_602008.host, call_602008.base,
                         call_602008.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602008, url, valid)

proc call*(call_602009: Call_CancelJob_601996; body: JsonNode): Recallable =
  ## cancelJob
  ## Cancels the specified job. You can only cancel a job before its <code>JobState</code> value changes to <code>PreparingAppliance</code>. Requesting the <code>ListJobs</code> or <code>DescribeJob</code> action returns a job's <code>JobState</code> as part of the response element data returned.
  ##   body: JObject (required)
  var body_602010 = newJObject()
  if body != nil:
    body_602010 = body
  result = call_602009.call(nil, nil, nil, nil, body_602010)

var cancelJob* = Call_CancelJob_601996(name: "cancelJob", meth: HttpMethod.HttpPost,
                                    host: "snowball.amazonaws.com", route: "/#X-Amz-Target=AWSIESnowballJobManagementService.CancelJob",
                                    validator: validate_CancelJob_601997,
                                    base: "/", url: url_CancelJob_601998,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateAddress_602011 = ref object of OpenApiRestCall_601389
proc url_CreateAddress_602013(protocol: Scheme; host: string; base: string;
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

proc validate_CreateAddress_602012(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates an address for a Snowball to be shipped to. In most regions, addresses are validated at the time of creation. The address you provide must be located within the serviceable area of your region. If the address is invalid or unsupported, then an exception is thrown.
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
  var valid_602014 = header.getOrDefault("X-Amz-Target")
  valid_602014 = validateParameter(valid_602014, JString, required = true, default = newJString(
      "AWSIESnowballJobManagementService.CreateAddress"))
  if valid_602014 != nil:
    section.add "X-Amz-Target", valid_602014
  var valid_602015 = header.getOrDefault("X-Amz-Signature")
  valid_602015 = validateParameter(valid_602015, JString, required = false,
                                 default = nil)
  if valid_602015 != nil:
    section.add "X-Amz-Signature", valid_602015
  var valid_602016 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602016 = validateParameter(valid_602016, JString, required = false,
                                 default = nil)
  if valid_602016 != nil:
    section.add "X-Amz-Content-Sha256", valid_602016
  var valid_602017 = header.getOrDefault("X-Amz-Date")
  valid_602017 = validateParameter(valid_602017, JString, required = false,
                                 default = nil)
  if valid_602017 != nil:
    section.add "X-Amz-Date", valid_602017
  var valid_602018 = header.getOrDefault("X-Amz-Credential")
  valid_602018 = validateParameter(valid_602018, JString, required = false,
                                 default = nil)
  if valid_602018 != nil:
    section.add "X-Amz-Credential", valid_602018
  var valid_602019 = header.getOrDefault("X-Amz-Security-Token")
  valid_602019 = validateParameter(valid_602019, JString, required = false,
                                 default = nil)
  if valid_602019 != nil:
    section.add "X-Amz-Security-Token", valid_602019
  var valid_602020 = header.getOrDefault("X-Amz-Algorithm")
  valid_602020 = validateParameter(valid_602020, JString, required = false,
                                 default = nil)
  if valid_602020 != nil:
    section.add "X-Amz-Algorithm", valid_602020
  var valid_602021 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602021 = validateParameter(valid_602021, JString, required = false,
                                 default = nil)
  if valid_602021 != nil:
    section.add "X-Amz-SignedHeaders", valid_602021
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602023: Call_CreateAddress_602011; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an address for a Snowball to be shipped to. In most regions, addresses are validated at the time of creation. The address you provide must be located within the serviceable area of your region. If the address is invalid or unsupported, then an exception is thrown.
  ## 
  let valid = call_602023.validator(path, query, header, formData, body)
  let scheme = call_602023.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602023.url(scheme.get, call_602023.host, call_602023.base,
                         call_602023.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602023, url, valid)

proc call*(call_602024: Call_CreateAddress_602011; body: JsonNode): Recallable =
  ## createAddress
  ## Creates an address for a Snowball to be shipped to. In most regions, addresses are validated at the time of creation. The address you provide must be located within the serviceable area of your region. If the address is invalid or unsupported, then an exception is thrown.
  ##   body: JObject (required)
  var body_602025 = newJObject()
  if body != nil:
    body_602025 = body
  result = call_602024.call(nil, nil, nil, nil, body_602025)

var createAddress* = Call_CreateAddress_602011(name: "createAddress",
    meth: HttpMethod.HttpPost, host: "snowball.amazonaws.com",
    route: "/#X-Amz-Target=AWSIESnowballJobManagementService.CreateAddress",
    validator: validate_CreateAddress_602012, base: "/", url: url_CreateAddress_602013,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateCluster_602026 = ref object of OpenApiRestCall_601389
proc url_CreateCluster_602028(protocol: Scheme; host: string; base: string;
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

proc validate_CreateCluster_602027(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates an empty cluster. Each cluster supports five nodes. You use the <a>CreateJob</a> action separately to create the jobs for each of these nodes. The cluster does not ship until these five node jobs have been created.
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
  var valid_602029 = header.getOrDefault("X-Amz-Target")
  valid_602029 = validateParameter(valid_602029, JString, required = true, default = newJString(
      "AWSIESnowballJobManagementService.CreateCluster"))
  if valid_602029 != nil:
    section.add "X-Amz-Target", valid_602029
  var valid_602030 = header.getOrDefault("X-Amz-Signature")
  valid_602030 = validateParameter(valid_602030, JString, required = false,
                                 default = nil)
  if valid_602030 != nil:
    section.add "X-Amz-Signature", valid_602030
  var valid_602031 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602031 = validateParameter(valid_602031, JString, required = false,
                                 default = nil)
  if valid_602031 != nil:
    section.add "X-Amz-Content-Sha256", valid_602031
  var valid_602032 = header.getOrDefault("X-Amz-Date")
  valid_602032 = validateParameter(valid_602032, JString, required = false,
                                 default = nil)
  if valid_602032 != nil:
    section.add "X-Amz-Date", valid_602032
  var valid_602033 = header.getOrDefault("X-Amz-Credential")
  valid_602033 = validateParameter(valid_602033, JString, required = false,
                                 default = nil)
  if valid_602033 != nil:
    section.add "X-Amz-Credential", valid_602033
  var valid_602034 = header.getOrDefault("X-Amz-Security-Token")
  valid_602034 = validateParameter(valid_602034, JString, required = false,
                                 default = nil)
  if valid_602034 != nil:
    section.add "X-Amz-Security-Token", valid_602034
  var valid_602035 = header.getOrDefault("X-Amz-Algorithm")
  valid_602035 = validateParameter(valid_602035, JString, required = false,
                                 default = nil)
  if valid_602035 != nil:
    section.add "X-Amz-Algorithm", valid_602035
  var valid_602036 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602036 = validateParameter(valid_602036, JString, required = false,
                                 default = nil)
  if valid_602036 != nil:
    section.add "X-Amz-SignedHeaders", valid_602036
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602038: Call_CreateCluster_602026; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an empty cluster. Each cluster supports five nodes. You use the <a>CreateJob</a> action separately to create the jobs for each of these nodes. The cluster does not ship until these five node jobs have been created.
  ## 
  let valid = call_602038.validator(path, query, header, formData, body)
  let scheme = call_602038.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602038.url(scheme.get, call_602038.host, call_602038.base,
                         call_602038.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602038, url, valid)

proc call*(call_602039: Call_CreateCluster_602026; body: JsonNode): Recallable =
  ## createCluster
  ## Creates an empty cluster. Each cluster supports five nodes. You use the <a>CreateJob</a> action separately to create the jobs for each of these nodes. The cluster does not ship until these five node jobs have been created.
  ##   body: JObject (required)
  var body_602040 = newJObject()
  if body != nil:
    body_602040 = body
  result = call_602039.call(nil, nil, nil, nil, body_602040)

var createCluster* = Call_CreateCluster_602026(name: "createCluster",
    meth: HttpMethod.HttpPost, host: "snowball.amazonaws.com",
    route: "/#X-Amz-Target=AWSIESnowballJobManagementService.CreateCluster",
    validator: validate_CreateCluster_602027, base: "/", url: url_CreateCluster_602028,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateJob_602041 = ref object of OpenApiRestCall_601389
proc url_CreateJob_602043(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_CreateJob_602042(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a job to import or export data between Amazon S3 and your on-premises data center. Your AWS account must have the right trust policies and permissions in place to create a job for Snowball. If you're creating a job for a node in a cluster, you only need to provide the <code>clusterId</code> value; the other job attributes are inherited from the cluster. 
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
  var valid_602044 = header.getOrDefault("X-Amz-Target")
  valid_602044 = validateParameter(valid_602044, JString, required = true, default = newJString(
      "AWSIESnowballJobManagementService.CreateJob"))
  if valid_602044 != nil:
    section.add "X-Amz-Target", valid_602044
  var valid_602045 = header.getOrDefault("X-Amz-Signature")
  valid_602045 = validateParameter(valid_602045, JString, required = false,
                                 default = nil)
  if valid_602045 != nil:
    section.add "X-Amz-Signature", valid_602045
  var valid_602046 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602046 = validateParameter(valid_602046, JString, required = false,
                                 default = nil)
  if valid_602046 != nil:
    section.add "X-Amz-Content-Sha256", valid_602046
  var valid_602047 = header.getOrDefault("X-Amz-Date")
  valid_602047 = validateParameter(valid_602047, JString, required = false,
                                 default = nil)
  if valid_602047 != nil:
    section.add "X-Amz-Date", valid_602047
  var valid_602048 = header.getOrDefault("X-Amz-Credential")
  valid_602048 = validateParameter(valid_602048, JString, required = false,
                                 default = nil)
  if valid_602048 != nil:
    section.add "X-Amz-Credential", valid_602048
  var valid_602049 = header.getOrDefault("X-Amz-Security-Token")
  valid_602049 = validateParameter(valid_602049, JString, required = false,
                                 default = nil)
  if valid_602049 != nil:
    section.add "X-Amz-Security-Token", valid_602049
  var valid_602050 = header.getOrDefault("X-Amz-Algorithm")
  valid_602050 = validateParameter(valid_602050, JString, required = false,
                                 default = nil)
  if valid_602050 != nil:
    section.add "X-Amz-Algorithm", valid_602050
  var valid_602051 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602051 = validateParameter(valid_602051, JString, required = false,
                                 default = nil)
  if valid_602051 != nil:
    section.add "X-Amz-SignedHeaders", valid_602051
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602053: Call_CreateJob_602041; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a job to import or export data between Amazon S3 and your on-premises data center. Your AWS account must have the right trust policies and permissions in place to create a job for Snowball. If you're creating a job for a node in a cluster, you only need to provide the <code>clusterId</code> value; the other job attributes are inherited from the cluster. 
  ## 
  let valid = call_602053.validator(path, query, header, formData, body)
  let scheme = call_602053.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602053.url(scheme.get, call_602053.host, call_602053.base,
                         call_602053.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602053, url, valid)

proc call*(call_602054: Call_CreateJob_602041; body: JsonNode): Recallable =
  ## createJob
  ## Creates a job to import or export data between Amazon S3 and your on-premises data center. Your AWS account must have the right trust policies and permissions in place to create a job for Snowball. If you're creating a job for a node in a cluster, you only need to provide the <code>clusterId</code> value; the other job attributes are inherited from the cluster. 
  ##   body: JObject (required)
  var body_602055 = newJObject()
  if body != nil:
    body_602055 = body
  result = call_602054.call(nil, nil, nil, nil, body_602055)

var createJob* = Call_CreateJob_602041(name: "createJob", meth: HttpMethod.HttpPost,
                                    host: "snowball.amazonaws.com", route: "/#X-Amz-Target=AWSIESnowballJobManagementService.CreateJob",
                                    validator: validate_CreateJob_602042,
                                    base: "/", url: url_CreateJob_602043,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAddress_602056 = ref object of OpenApiRestCall_601389
proc url_DescribeAddress_602058(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeAddress_602057(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Takes an <code>AddressId</code> and returns specific details about that address in the form of an <code>Address</code> object.
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
  var valid_602059 = header.getOrDefault("X-Amz-Target")
  valid_602059 = validateParameter(valid_602059, JString, required = true, default = newJString(
      "AWSIESnowballJobManagementService.DescribeAddress"))
  if valid_602059 != nil:
    section.add "X-Amz-Target", valid_602059
  var valid_602060 = header.getOrDefault("X-Amz-Signature")
  valid_602060 = validateParameter(valid_602060, JString, required = false,
                                 default = nil)
  if valid_602060 != nil:
    section.add "X-Amz-Signature", valid_602060
  var valid_602061 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602061 = validateParameter(valid_602061, JString, required = false,
                                 default = nil)
  if valid_602061 != nil:
    section.add "X-Amz-Content-Sha256", valid_602061
  var valid_602062 = header.getOrDefault("X-Amz-Date")
  valid_602062 = validateParameter(valid_602062, JString, required = false,
                                 default = nil)
  if valid_602062 != nil:
    section.add "X-Amz-Date", valid_602062
  var valid_602063 = header.getOrDefault("X-Amz-Credential")
  valid_602063 = validateParameter(valid_602063, JString, required = false,
                                 default = nil)
  if valid_602063 != nil:
    section.add "X-Amz-Credential", valid_602063
  var valid_602064 = header.getOrDefault("X-Amz-Security-Token")
  valid_602064 = validateParameter(valid_602064, JString, required = false,
                                 default = nil)
  if valid_602064 != nil:
    section.add "X-Amz-Security-Token", valid_602064
  var valid_602065 = header.getOrDefault("X-Amz-Algorithm")
  valid_602065 = validateParameter(valid_602065, JString, required = false,
                                 default = nil)
  if valid_602065 != nil:
    section.add "X-Amz-Algorithm", valid_602065
  var valid_602066 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602066 = validateParameter(valid_602066, JString, required = false,
                                 default = nil)
  if valid_602066 != nil:
    section.add "X-Amz-SignedHeaders", valid_602066
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602068: Call_DescribeAddress_602056; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Takes an <code>AddressId</code> and returns specific details about that address in the form of an <code>Address</code> object.
  ## 
  let valid = call_602068.validator(path, query, header, formData, body)
  let scheme = call_602068.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602068.url(scheme.get, call_602068.host, call_602068.base,
                         call_602068.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602068, url, valid)

proc call*(call_602069: Call_DescribeAddress_602056; body: JsonNode): Recallable =
  ## describeAddress
  ## Takes an <code>AddressId</code> and returns specific details about that address in the form of an <code>Address</code> object.
  ##   body: JObject (required)
  var body_602070 = newJObject()
  if body != nil:
    body_602070 = body
  result = call_602069.call(nil, nil, nil, nil, body_602070)

var describeAddress* = Call_DescribeAddress_602056(name: "describeAddress",
    meth: HttpMethod.HttpPost, host: "snowball.amazonaws.com",
    route: "/#X-Amz-Target=AWSIESnowballJobManagementService.DescribeAddress",
    validator: validate_DescribeAddress_602057, base: "/", url: url_DescribeAddress_602058,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAddresses_602071 = ref object of OpenApiRestCall_601389
proc url_DescribeAddresses_602073(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeAddresses_602072(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Returns a specified number of <code>ADDRESS</code> objects. Calling this API in one of the US regions will return addresses from the list of all addresses associated with this account in all US regions.
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
  var valid_602074 = query.getOrDefault("MaxResults")
  valid_602074 = validateParameter(valid_602074, JString, required = false,
                                 default = nil)
  if valid_602074 != nil:
    section.add "MaxResults", valid_602074
  var valid_602075 = query.getOrDefault("NextToken")
  valid_602075 = validateParameter(valid_602075, JString, required = false,
                                 default = nil)
  if valid_602075 != nil:
    section.add "NextToken", valid_602075
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
  var valid_602076 = header.getOrDefault("X-Amz-Target")
  valid_602076 = validateParameter(valid_602076, JString, required = true, default = newJString(
      "AWSIESnowballJobManagementService.DescribeAddresses"))
  if valid_602076 != nil:
    section.add "X-Amz-Target", valid_602076
  var valid_602077 = header.getOrDefault("X-Amz-Signature")
  valid_602077 = validateParameter(valid_602077, JString, required = false,
                                 default = nil)
  if valid_602077 != nil:
    section.add "X-Amz-Signature", valid_602077
  var valid_602078 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602078 = validateParameter(valid_602078, JString, required = false,
                                 default = nil)
  if valid_602078 != nil:
    section.add "X-Amz-Content-Sha256", valid_602078
  var valid_602079 = header.getOrDefault("X-Amz-Date")
  valid_602079 = validateParameter(valid_602079, JString, required = false,
                                 default = nil)
  if valid_602079 != nil:
    section.add "X-Amz-Date", valid_602079
  var valid_602080 = header.getOrDefault("X-Amz-Credential")
  valid_602080 = validateParameter(valid_602080, JString, required = false,
                                 default = nil)
  if valid_602080 != nil:
    section.add "X-Amz-Credential", valid_602080
  var valid_602081 = header.getOrDefault("X-Amz-Security-Token")
  valid_602081 = validateParameter(valid_602081, JString, required = false,
                                 default = nil)
  if valid_602081 != nil:
    section.add "X-Amz-Security-Token", valid_602081
  var valid_602082 = header.getOrDefault("X-Amz-Algorithm")
  valid_602082 = validateParameter(valid_602082, JString, required = false,
                                 default = nil)
  if valid_602082 != nil:
    section.add "X-Amz-Algorithm", valid_602082
  var valid_602083 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602083 = validateParameter(valid_602083, JString, required = false,
                                 default = nil)
  if valid_602083 != nil:
    section.add "X-Amz-SignedHeaders", valid_602083
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602085: Call_DescribeAddresses_602071; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a specified number of <code>ADDRESS</code> objects. Calling this API in one of the US regions will return addresses from the list of all addresses associated with this account in all US regions.
  ## 
  let valid = call_602085.validator(path, query, header, formData, body)
  let scheme = call_602085.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602085.url(scheme.get, call_602085.host, call_602085.base,
                         call_602085.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602085, url, valid)

proc call*(call_602086: Call_DescribeAddresses_602071; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## describeAddresses
  ## Returns a specified number of <code>ADDRESS</code> objects. Calling this API in one of the US regions will return addresses from the list of all addresses associated with this account in all US regions.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_602087 = newJObject()
  var body_602088 = newJObject()
  add(query_602087, "MaxResults", newJString(MaxResults))
  add(query_602087, "NextToken", newJString(NextToken))
  if body != nil:
    body_602088 = body
  result = call_602086.call(nil, query_602087, nil, nil, body_602088)

var describeAddresses* = Call_DescribeAddresses_602071(name: "describeAddresses",
    meth: HttpMethod.HttpPost, host: "snowball.amazonaws.com", route: "/#X-Amz-Target=AWSIESnowballJobManagementService.DescribeAddresses",
    validator: validate_DescribeAddresses_602072, base: "/",
    url: url_DescribeAddresses_602073, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeCluster_602090 = ref object of OpenApiRestCall_601389
proc url_DescribeCluster_602092(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeCluster_602091(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Returns information about a specific cluster including shipping information, cluster status, and other important metadata.
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
  var valid_602093 = header.getOrDefault("X-Amz-Target")
  valid_602093 = validateParameter(valid_602093, JString, required = true, default = newJString(
      "AWSIESnowballJobManagementService.DescribeCluster"))
  if valid_602093 != nil:
    section.add "X-Amz-Target", valid_602093
  var valid_602094 = header.getOrDefault("X-Amz-Signature")
  valid_602094 = validateParameter(valid_602094, JString, required = false,
                                 default = nil)
  if valid_602094 != nil:
    section.add "X-Amz-Signature", valid_602094
  var valid_602095 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602095 = validateParameter(valid_602095, JString, required = false,
                                 default = nil)
  if valid_602095 != nil:
    section.add "X-Amz-Content-Sha256", valid_602095
  var valid_602096 = header.getOrDefault("X-Amz-Date")
  valid_602096 = validateParameter(valid_602096, JString, required = false,
                                 default = nil)
  if valid_602096 != nil:
    section.add "X-Amz-Date", valid_602096
  var valid_602097 = header.getOrDefault("X-Amz-Credential")
  valid_602097 = validateParameter(valid_602097, JString, required = false,
                                 default = nil)
  if valid_602097 != nil:
    section.add "X-Amz-Credential", valid_602097
  var valid_602098 = header.getOrDefault("X-Amz-Security-Token")
  valid_602098 = validateParameter(valid_602098, JString, required = false,
                                 default = nil)
  if valid_602098 != nil:
    section.add "X-Amz-Security-Token", valid_602098
  var valid_602099 = header.getOrDefault("X-Amz-Algorithm")
  valid_602099 = validateParameter(valid_602099, JString, required = false,
                                 default = nil)
  if valid_602099 != nil:
    section.add "X-Amz-Algorithm", valid_602099
  var valid_602100 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602100 = validateParameter(valid_602100, JString, required = false,
                                 default = nil)
  if valid_602100 != nil:
    section.add "X-Amz-SignedHeaders", valid_602100
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602102: Call_DescribeCluster_602090; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about a specific cluster including shipping information, cluster status, and other important metadata.
  ## 
  let valid = call_602102.validator(path, query, header, formData, body)
  let scheme = call_602102.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602102.url(scheme.get, call_602102.host, call_602102.base,
                         call_602102.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602102, url, valid)

proc call*(call_602103: Call_DescribeCluster_602090; body: JsonNode): Recallable =
  ## describeCluster
  ## Returns information about a specific cluster including shipping information, cluster status, and other important metadata.
  ##   body: JObject (required)
  var body_602104 = newJObject()
  if body != nil:
    body_602104 = body
  result = call_602103.call(nil, nil, nil, nil, body_602104)

var describeCluster* = Call_DescribeCluster_602090(name: "describeCluster",
    meth: HttpMethod.HttpPost, host: "snowball.amazonaws.com",
    route: "/#X-Amz-Target=AWSIESnowballJobManagementService.DescribeCluster",
    validator: validate_DescribeCluster_602091, base: "/", url: url_DescribeCluster_602092,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeJob_602105 = ref object of OpenApiRestCall_601389
proc url_DescribeJob_602107(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeJob_602106(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns information about a specific job including shipping information, job status, and other important metadata. 
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
  var valid_602108 = header.getOrDefault("X-Amz-Target")
  valid_602108 = validateParameter(valid_602108, JString, required = true, default = newJString(
      "AWSIESnowballJobManagementService.DescribeJob"))
  if valid_602108 != nil:
    section.add "X-Amz-Target", valid_602108
  var valid_602109 = header.getOrDefault("X-Amz-Signature")
  valid_602109 = validateParameter(valid_602109, JString, required = false,
                                 default = nil)
  if valid_602109 != nil:
    section.add "X-Amz-Signature", valid_602109
  var valid_602110 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602110 = validateParameter(valid_602110, JString, required = false,
                                 default = nil)
  if valid_602110 != nil:
    section.add "X-Amz-Content-Sha256", valid_602110
  var valid_602111 = header.getOrDefault("X-Amz-Date")
  valid_602111 = validateParameter(valid_602111, JString, required = false,
                                 default = nil)
  if valid_602111 != nil:
    section.add "X-Amz-Date", valid_602111
  var valid_602112 = header.getOrDefault("X-Amz-Credential")
  valid_602112 = validateParameter(valid_602112, JString, required = false,
                                 default = nil)
  if valid_602112 != nil:
    section.add "X-Amz-Credential", valid_602112
  var valid_602113 = header.getOrDefault("X-Amz-Security-Token")
  valid_602113 = validateParameter(valid_602113, JString, required = false,
                                 default = nil)
  if valid_602113 != nil:
    section.add "X-Amz-Security-Token", valid_602113
  var valid_602114 = header.getOrDefault("X-Amz-Algorithm")
  valid_602114 = validateParameter(valid_602114, JString, required = false,
                                 default = nil)
  if valid_602114 != nil:
    section.add "X-Amz-Algorithm", valid_602114
  var valid_602115 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602115 = validateParameter(valid_602115, JString, required = false,
                                 default = nil)
  if valid_602115 != nil:
    section.add "X-Amz-SignedHeaders", valid_602115
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602117: Call_DescribeJob_602105; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about a specific job including shipping information, job status, and other important metadata. 
  ## 
  let valid = call_602117.validator(path, query, header, formData, body)
  let scheme = call_602117.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602117.url(scheme.get, call_602117.host, call_602117.base,
                         call_602117.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602117, url, valid)

proc call*(call_602118: Call_DescribeJob_602105; body: JsonNode): Recallable =
  ## describeJob
  ## Returns information about a specific job including shipping information, job status, and other important metadata. 
  ##   body: JObject (required)
  var body_602119 = newJObject()
  if body != nil:
    body_602119 = body
  result = call_602118.call(nil, nil, nil, nil, body_602119)

var describeJob* = Call_DescribeJob_602105(name: "describeJob",
                                        meth: HttpMethod.HttpPost,
                                        host: "snowball.amazonaws.com", route: "/#X-Amz-Target=AWSIESnowballJobManagementService.DescribeJob",
                                        validator: validate_DescribeJob_602106,
                                        base: "/", url: url_DescribeJob_602107,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetJobManifest_602120 = ref object of OpenApiRestCall_601389
proc url_GetJobManifest_602122(protocol: Scheme; host: string; base: string;
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

proc validate_GetJobManifest_602121(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>Returns a link to an Amazon S3 presigned URL for the manifest file associated with the specified <code>JobId</code> value. You can access the manifest file for up to 60 minutes after this request has been made. To access the manifest file after 60 minutes have passed, you'll have to make another call to the <code>GetJobManifest</code> action.</p> <p>The manifest is an encrypted file that you can download after your job enters the <code>WithCustomer</code> status. The manifest is decrypted by using the <code>UnlockCode</code> code value, when you pass both values to the Snowball through the Snowball client when the client is started for the first time.</p> <p>As a best practice, we recommend that you don't save a copy of an <code>UnlockCode</code> value in the same location as the manifest file for that job. Saving these separately helps prevent unauthorized parties from gaining access to the Snowball associated with that job.</p> <p>The credentials of a given job, including its manifest file and unlock code, expire 90 days after the job is created.</p>
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
  var valid_602123 = header.getOrDefault("X-Amz-Target")
  valid_602123 = validateParameter(valid_602123, JString, required = true, default = newJString(
      "AWSIESnowballJobManagementService.GetJobManifest"))
  if valid_602123 != nil:
    section.add "X-Amz-Target", valid_602123
  var valid_602124 = header.getOrDefault("X-Amz-Signature")
  valid_602124 = validateParameter(valid_602124, JString, required = false,
                                 default = nil)
  if valid_602124 != nil:
    section.add "X-Amz-Signature", valid_602124
  var valid_602125 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602125 = validateParameter(valid_602125, JString, required = false,
                                 default = nil)
  if valid_602125 != nil:
    section.add "X-Amz-Content-Sha256", valid_602125
  var valid_602126 = header.getOrDefault("X-Amz-Date")
  valid_602126 = validateParameter(valid_602126, JString, required = false,
                                 default = nil)
  if valid_602126 != nil:
    section.add "X-Amz-Date", valid_602126
  var valid_602127 = header.getOrDefault("X-Amz-Credential")
  valid_602127 = validateParameter(valid_602127, JString, required = false,
                                 default = nil)
  if valid_602127 != nil:
    section.add "X-Amz-Credential", valid_602127
  var valid_602128 = header.getOrDefault("X-Amz-Security-Token")
  valid_602128 = validateParameter(valid_602128, JString, required = false,
                                 default = nil)
  if valid_602128 != nil:
    section.add "X-Amz-Security-Token", valid_602128
  var valid_602129 = header.getOrDefault("X-Amz-Algorithm")
  valid_602129 = validateParameter(valid_602129, JString, required = false,
                                 default = nil)
  if valid_602129 != nil:
    section.add "X-Amz-Algorithm", valid_602129
  var valid_602130 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602130 = validateParameter(valid_602130, JString, required = false,
                                 default = nil)
  if valid_602130 != nil:
    section.add "X-Amz-SignedHeaders", valid_602130
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602132: Call_GetJobManifest_602120; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a link to an Amazon S3 presigned URL for the manifest file associated with the specified <code>JobId</code> value. You can access the manifest file for up to 60 minutes after this request has been made. To access the manifest file after 60 minutes have passed, you'll have to make another call to the <code>GetJobManifest</code> action.</p> <p>The manifest is an encrypted file that you can download after your job enters the <code>WithCustomer</code> status. The manifest is decrypted by using the <code>UnlockCode</code> code value, when you pass both values to the Snowball through the Snowball client when the client is started for the first time.</p> <p>As a best practice, we recommend that you don't save a copy of an <code>UnlockCode</code> value in the same location as the manifest file for that job. Saving these separately helps prevent unauthorized parties from gaining access to the Snowball associated with that job.</p> <p>The credentials of a given job, including its manifest file and unlock code, expire 90 days after the job is created.</p>
  ## 
  let valid = call_602132.validator(path, query, header, formData, body)
  let scheme = call_602132.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602132.url(scheme.get, call_602132.host, call_602132.base,
                         call_602132.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602132, url, valid)

proc call*(call_602133: Call_GetJobManifest_602120; body: JsonNode): Recallable =
  ## getJobManifest
  ## <p>Returns a link to an Amazon S3 presigned URL for the manifest file associated with the specified <code>JobId</code> value. You can access the manifest file for up to 60 minutes after this request has been made. To access the manifest file after 60 minutes have passed, you'll have to make another call to the <code>GetJobManifest</code> action.</p> <p>The manifest is an encrypted file that you can download after your job enters the <code>WithCustomer</code> status. The manifest is decrypted by using the <code>UnlockCode</code> code value, when you pass both values to the Snowball through the Snowball client when the client is started for the first time.</p> <p>As a best practice, we recommend that you don't save a copy of an <code>UnlockCode</code> value in the same location as the manifest file for that job. Saving these separately helps prevent unauthorized parties from gaining access to the Snowball associated with that job.</p> <p>The credentials of a given job, including its manifest file and unlock code, expire 90 days after the job is created.</p>
  ##   body: JObject (required)
  var body_602134 = newJObject()
  if body != nil:
    body_602134 = body
  result = call_602133.call(nil, nil, nil, nil, body_602134)

var getJobManifest* = Call_GetJobManifest_602120(name: "getJobManifest",
    meth: HttpMethod.HttpPost, host: "snowball.amazonaws.com",
    route: "/#X-Amz-Target=AWSIESnowballJobManagementService.GetJobManifest",
    validator: validate_GetJobManifest_602121, base: "/", url: url_GetJobManifest_602122,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetJobUnlockCode_602135 = ref object of OpenApiRestCall_601389
proc url_GetJobUnlockCode_602137(protocol: Scheme; host: string; base: string;
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

proc validate_GetJobUnlockCode_602136(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <p>Returns the <code>UnlockCode</code> code value for the specified job. A particular <code>UnlockCode</code> value can be accessed for up to 90 days after the associated job has been created.</p> <p>The <code>UnlockCode</code> value is a 29-character code with 25 alphanumeric characters and 4 hyphens. This code is used to decrypt the manifest file when it is passed along with the manifest to the Snowball through the Snowball client when the client is started for the first time.</p> <p>As a best practice, we recommend that you don't save a copy of the <code>UnlockCode</code> in the same location as the manifest file for that job. Saving these separately helps prevent unauthorized parties from gaining access to the Snowball associated with that job.</p>
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
  var valid_602138 = header.getOrDefault("X-Amz-Target")
  valid_602138 = validateParameter(valid_602138, JString, required = true, default = newJString(
      "AWSIESnowballJobManagementService.GetJobUnlockCode"))
  if valid_602138 != nil:
    section.add "X-Amz-Target", valid_602138
  var valid_602139 = header.getOrDefault("X-Amz-Signature")
  valid_602139 = validateParameter(valid_602139, JString, required = false,
                                 default = nil)
  if valid_602139 != nil:
    section.add "X-Amz-Signature", valid_602139
  var valid_602140 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602140 = validateParameter(valid_602140, JString, required = false,
                                 default = nil)
  if valid_602140 != nil:
    section.add "X-Amz-Content-Sha256", valid_602140
  var valid_602141 = header.getOrDefault("X-Amz-Date")
  valid_602141 = validateParameter(valid_602141, JString, required = false,
                                 default = nil)
  if valid_602141 != nil:
    section.add "X-Amz-Date", valid_602141
  var valid_602142 = header.getOrDefault("X-Amz-Credential")
  valid_602142 = validateParameter(valid_602142, JString, required = false,
                                 default = nil)
  if valid_602142 != nil:
    section.add "X-Amz-Credential", valid_602142
  var valid_602143 = header.getOrDefault("X-Amz-Security-Token")
  valid_602143 = validateParameter(valid_602143, JString, required = false,
                                 default = nil)
  if valid_602143 != nil:
    section.add "X-Amz-Security-Token", valid_602143
  var valid_602144 = header.getOrDefault("X-Amz-Algorithm")
  valid_602144 = validateParameter(valid_602144, JString, required = false,
                                 default = nil)
  if valid_602144 != nil:
    section.add "X-Amz-Algorithm", valid_602144
  var valid_602145 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602145 = validateParameter(valid_602145, JString, required = false,
                                 default = nil)
  if valid_602145 != nil:
    section.add "X-Amz-SignedHeaders", valid_602145
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602147: Call_GetJobUnlockCode_602135; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the <code>UnlockCode</code> code value for the specified job. A particular <code>UnlockCode</code> value can be accessed for up to 90 days after the associated job has been created.</p> <p>The <code>UnlockCode</code> value is a 29-character code with 25 alphanumeric characters and 4 hyphens. This code is used to decrypt the manifest file when it is passed along with the manifest to the Snowball through the Snowball client when the client is started for the first time.</p> <p>As a best practice, we recommend that you don't save a copy of the <code>UnlockCode</code> in the same location as the manifest file for that job. Saving these separately helps prevent unauthorized parties from gaining access to the Snowball associated with that job.</p>
  ## 
  let valid = call_602147.validator(path, query, header, formData, body)
  let scheme = call_602147.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602147.url(scheme.get, call_602147.host, call_602147.base,
                         call_602147.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602147, url, valid)

proc call*(call_602148: Call_GetJobUnlockCode_602135; body: JsonNode): Recallable =
  ## getJobUnlockCode
  ## <p>Returns the <code>UnlockCode</code> code value for the specified job. A particular <code>UnlockCode</code> value can be accessed for up to 90 days after the associated job has been created.</p> <p>The <code>UnlockCode</code> value is a 29-character code with 25 alphanumeric characters and 4 hyphens. This code is used to decrypt the manifest file when it is passed along with the manifest to the Snowball through the Snowball client when the client is started for the first time.</p> <p>As a best practice, we recommend that you don't save a copy of the <code>UnlockCode</code> in the same location as the manifest file for that job. Saving these separately helps prevent unauthorized parties from gaining access to the Snowball associated with that job.</p>
  ##   body: JObject (required)
  var body_602149 = newJObject()
  if body != nil:
    body_602149 = body
  result = call_602148.call(nil, nil, nil, nil, body_602149)

var getJobUnlockCode* = Call_GetJobUnlockCode_602135(name: "getJobUnlockCode",
    meth: HttpMethod.HttpPost, host: "snowball.amazonaws.com",
    route: "/#X-Amz-Target=AWSIESnowballJobManagementService.GetJobUnlockCode",
    validator: validate_GetJobUnlockCode_602136, base: "/",
    url: url_GetJobUnlockCode_602137, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSnowballUsage_602150 = ref object of OpenApiRestCall_601389
proc url_GetSnowballUsage_602152(protocol: Scheme; host: string; base: string;
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

proc validate_GetSnowballUsage_602151(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <p>Returns information about the Snowball service limit for your account, and also the number of Snowballs your account has in use.</p> <p>The default service limit for the number of Snowballs that you can have at one time is 1. If you want to increase your service limit, contact AWS Support.</p>
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
  var valid_602153 = header.getOrDefault("X-Amz-Target")
  valid_602153 = validateParameter(valid_602153, JString, required = true, default = newJString(
      "AWSIESnowballJobManagementService.GetSnowballUsage"))
  if valid_602153 != nil:
    section.add "X-Amz-Target", valid_602153
  var valid_602154 = header.getOrDefault("X-Amz-Signature")
  valid_602154 = validateParameter(valid_602154, JString, required = false,
                                 default = nil)
  if valid_602154 != nil:
    section.add "X-Amz-Signature", valid_602154
  var valid_602155 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602155 = validateParameter(valid_602155, JString, required = false,
                                 default = nil)
  if valid_602155 != nil:
    section.add "X-Amz-Content-Sha256", valid_602155
  var valid_602156 = header.getOrDefault("X-Amz-Date")
  valid_602156 = validateParameter(valid_602156, JString, required = false,
                                 default = nil)
  if valid_602156 != nil:
    section.add "X-Amz-Date", valid_602156
  var valid_602157 = header.getOrDefault("X-Amz-Credential")
  valid_602157 = validateParameter(valid_602157, JString, required = false,
                                 default = nil)
  if valid_602157 != nil:
    section.add "X-Amz-Credential", valid_602157
  var valid_602158 = header.getOrDefault("X-Amz-Security-Token")
  valid_602158 = validateParameter(valid_602158, JString, required = false,
                                 default = nil)
  if valid_602158 != nil:
    section.add "X-Amz-Security-Token", valid_602158
  var valid_602159 = header.getOrDefault("X-Amz-Algorithm")
  valid_602159 = validateParameter(valid_602159, JString, required = false,
                                 default = nil)
  if valid_602159 != nil:
    section.add "X-Amz-Algorithm", valid_602159
  var valid_602160 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602160 = validateParameter(valid_602160, JString, required = false,
                                 default = nil)
  if valid_602160 != nil:
    section.add "X-Amz-SignedHeaders", valid_602160
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602162: Call_GetSnowballUsage_602150; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns information about the Snowball service limit for your account, and also the number of Snowballs your account has in use.</p> <p>The default service limit for the number of Snowballs that you can have at one time is 1. If you want to increase your service limit, contact AWS Support.</p>
  ## 
  let valid = call_602162.validator(path, query, header, formData, body)
  let scheme = call_602162.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602162.url(scheme.get, call_602162.host, call_602162.base,
                         call_602162.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602162, url, valid)

proc call*(call_602163: Call_GetSnowballUsage_602150; body: JsonNode): Recallable =
  ## getSnowballUsage
  ## <p>Returns information about the Snowball service limit for your account, and also the number of Snowballs your account has in use.</p> <p>The default service limit for the number of Snowballs that you can have at one time is 1. If you want to increase your service limit, contact AWS Support.</p>
  ##   body: JObject (required)
  var body_602164 = newJObject()
  if body != nil:
    body_602164 = body
  result = call_602163.call(nil, nil, nil, nil, body_602164)

var getSnowballUsage* = Call_GetSnowballUsage_602150(name: "getSnowballUsage",
    meth: HttpMethod.HttpPost, host: "snowball.amazonaws.com",
    route: "/#X-Amz-Target=AWSIESnowballJobManagementService.GetSnowballUsage",
    validator: validate_GetSnowballUsage_602151, base: "/",
    url: url_GetSnowballUsage_602152, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSoftwareUpdates_602165 = ref object of OpenApiRestCall_601389
proc url_GetSoftwareUpdates_602167(protocol: Scheme; host: string; base: string;
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

proc validate_GetSoftwareUpdates_602166(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Returns an Amazon S3 presigned URL for an update file associated with a specified <code>JobId</code>.
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
  var valid_602168 = header.getOrDefault("X-Amz-Target")
  valid_602168 = validateParameter(valid_602168, JString, required = true, default = newJString(
      "AWSIESnowballJobManagementService.GetSoftwareUpdates"))
  if valid_602168 != nil:
    section.add "X-Amz-Target", valid_602168
  var valid_602169 = header.getOrDefault("X-Amz-Signature")
  valid_602169 = validateParameter(valid_602169, JString, required = false,
                                 default = nil)
  if valid_602169 != nil:
    section.add "X-Amz-Signature", valid_602169
  var valid_602170 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602170 = validateParameter(valid_602170, JString, required = false,
                                 default = nil)
  if valid_602170 != nil:
    section.add "X-Amz-Content-Sha256", valid_602170
  var valid_602171 = header.getOrDefault("X-Amz-Date")
  valid_602171 = validateParameter(valid_602171, JString, required = false,
                                 default = nil)
  if valid_602171 != nil:
    section.add "X-Amz-Date", valid_602171
  var valid_602172 = header.getOrDefault("X-Amz-Credential")
  valid_602172 = validateParameter(valid_602172, JString, required = false,
                                 default = nil)
  if valid_602172 != nil:
    section.add "X-Amz-Credential", valid_602172
  var valid_602173 = header.getOrDefault("X-Amz-Security-Token")
  valid_602173 = validateParameter(valid_602173, JString, required = false,
                                 default = nil)
  if valid_602173 != nil:
    section.add "X-Amz-Security-Token", valid_602173
  var valid_602174 = header.getOrDefault("X-Amz-Algorithm")
  valid_602174 = validateParameter(valid_602174, JString, required = false,
                                 default = nil)
  if valid_602174 != nil:
    section.add "X-Amz-Algorithm", valid_602174
  var valid_602175 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602175 = validateParameter(valid_602175, JString, required = false,
                                 default = nil)
  if valid_602175 != nil:
    section.add "X-Amz-SignedHeaders", valid_602175
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602177: Call_GetSoftwareUpdates_602165; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns an Amazon S3 presigned URL for an update file associated with a specified <code>JobId</code>.
  ## 
  let valid = call_602177.validator(path, query, header, formData, body)
  let scheme = call_602177.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602177.url(scheme.get, call_602177.host, call_602177.base,
                         call_602177.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602177, url, valid)

proc call*(call_602178: Call_GetSoftwareUpdates_602165; body: JsonNode): Recallable =
  ## getSoftwareUpdates
  ## Returns an Amazon S3 presigned URL for an update file associated with a specified <code>JobId</code>.
  ##   body: JObject (required)
  var body_602179 = newJObject()
  if body != nil:
    body_602179 = body
  result = call_602178.call(nil, nil, nil, nil, body_602179)

var getSoftwareUpdates* = Call_GetSoftwareUpdates_602165(
    name: "getSoftwareUpdates", meth: HttpMethod.HttpPost,
    host: "snowball.amazonaws.com", route: "/#X-Amz-Target=AWSIESnowballJobManagementService.GetSoftwareUpdates",
    validator: validate_GetSoftwareUpdates_602166, base: "/",
    url: url_GetSoftwareUpdates_602167, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListClusterJobs_602180 = ref object of OpenApiRestCall_601389
proc url_ListClusterJobs_602182(protocol: Scheme; host: string; base: string;
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

proc validate_ListClusterJobs_602181(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Returns an array of <code>JobListEntry</code> objects of the specified length. Each <code>JobListEntry</code> object is for a job in the specified cluster and contains a job's state, a job's ID, and other information.
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
  var valid_602183 = header.getOrDefault("X-Amz-Target")
  valid_602183 = validateParameter(valid_602183, JString, required = true, default = newJString(
      "AWSIESnowballJobManagementService.ListClusterJobs"))
  if valid_602183 != nil:
    section.add "X-Amz-Target", valid_602183
  var valid_602184 = header.getOrDefault("X-Amz-Signature")
  valid_602184 = validateParameter(valid_602184, JString, required = false,
                                 default = nil)
  if valid_602184 != nil:
    section.add "X-Amz-Signature", valid_602184
  var valid_602185 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602185 = validateParameter(valid_602185, JString, required = false,
                                 default = nil)
  if valid_602185 != nil:
    section.add "X-Amz-Content-Sha256", valid_602185
  var valid_602186 = header.getOrDefault("X-Amz-Date")
  valid_602186 = validateParameter(valid_602186, JString, required = false,
                                 default = nil)
  if valid_602186 != nil:
    section.add "X-Amz-Date", valid_602186
  var valid_602187 = header.getOrDefault("X-Amz-Credential")
  valid_602187 = validateParameter(valid_602187, JString, required = false,
                                 default = nil)
  if valid_602187 != nil:
    section.add "X-Amz-Credential", valid_602187
  var valid_602188 = header.getOrDefault("X-Amz-Security-Token")
  valid_602188 = validateParameter(valid_602188, JString, required = false,
                                 default = nil)
  if valid_602188 != nil:
    section.add "X-Amz-Security-Token", valid_602188
  var valid_602189 = header.getOrDefault("X-Amz-Algorithm")
  valid_602189 = validateParameter(valid_602189, JString, required = false,
                                 default = nil)
  if valid_602189 != nil:
    section.add "X-Amz-Algorithm", valid_602189
  var valid_602190 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602190 = validateParameter(valid_602190, JString, required = false,
                                 default = nil)
  if valid_602190 != nil:
    section.add "X-Amz-SignedHeaders", valid_602190
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602192: Call_ListClusterJobs_602180; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns an array of <code>JobListEntry</code> objects of the specified length. Each <code>JobListEntry</code> object is for a job in the specified cluster and contains a job's state, a job's ID, and other information.
  ## 
  let valid = call_602192.validator(path, query, header, formData, body)
  let scheme = call_602192.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602192.url(scheme.get, call_602192.host, call_602192.base,
                         call_602192.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602192, url, valid)

proc call*(call_602193: Call_ListClusterJobs_602180; body: JsonNode): Recallable =
  ## listClusterJobs
  ## Returns an array of <code>JobListEntry</code> objects of the specified length. Each <code>JobListEntry</code> object is for a job in the specified cluster and contains a job's state, a job's ID, and other information.
  ##   body: JObject (required)
  var body_602194 = newJObject()
  if body != nil:
    body_602194 = body
  result = call_602193.call(nil, nil, nil, nil, body_602194)

var listClusterJobs* = Call_ListClusterJobs_602180(name: "listClusterJobs",
    meth: HttpMethod.HttpPost, host: "snowball.amazonaws.com",
    route: "/#X-Amz-Target=AWSIESnowballJobManagementService.ListClusterJobs",
    validator: validate_ListClusterJobs_602181, base: "/", url: url_ListClusterJobs_602182,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListClusters_602195 = ref object of OpenApiRestCall_601389
proc url_ListClusters_602197(protocol: Scheme; host: string; base: string;
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

proc validate_ListClusters_602196(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns an array of <code>ClusterListEntry</code> objects of the specified length. Each <code>ClusterListEntry</code> object contains a cluster's state, a cluster's ID, and other important status information.
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
  var valid_602198 = header.getOrDefault("X-Amz-Target")
  valid_602198 = validateParameter(valid_602198, JString, required = true, default = newJString(
      "AWSIESnowballJobManagementService.ListClusters"))
  if valid_602198 != nil:
    section.add "X-Amz-Target", valid_602198
  var valid_602199 = header.getOrDefault("X-Amz-Signature")
  valid_602199 = validateParameter(valid_602199, JString, required = false,
                                 default = nil)
  if valid_602199 != nil:
    section.add "X-Amz-Signature", valid_602199
  var valid_602200 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602200 = validateParameter(valid_602200, JString, required = false,
                                 default = nil)
  if valid_602200 != nil:
    section.add "X-Amz-Content-Sha256", valid_602200
  var valid_602201 = header.getOrDefault("X-Amz-Date")
  valid_602201 = validateParameter(valid_602201, JString, required = false,
                                 default = nil)
  if valid_602201 != nil:
    section.add "X-Amz-Date", valid_602201
  var valid_602202 = header.getOrDefault("X-Amz-Credential")
  valid_602202 = validateParameter(valid_602202, JString, required = false,
                                 default = nil)
  if valid_602202 != nil:
    section.add "X-Amz-Credential", valid_602202
  var valid_602203 = header.getOrDefault("X-Amz-Security-Token")
  valid_602203 = validateParameter(valid_602203, JString, required = false,
                                 default = nil)
  if valid_602203 != nil:
    section.add "X-Amz-Security-Token", valid_602203
  var valid_602204 = header.getOrDefault("X-Amz-Algorithm")
  valid_602204 = validateParameter(valid_602204, JString, required = false,
                                 default = nil)
  if valid_602204 != nil:
    section.add "X-Amz-Algorithm", valid_602204
  var valid_602205 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602205 = validateParameter(valid_602205, JString, required = false,
                                 default = nil)
  if valid_602205 != nil:
    section.add "X-Amz-SignedHeaders", valid_602205
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602207: Call_ListClusters_602195; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns an array of <code>ClusterListEntry</code> objects of the specified length. Each <code>ClusterListEntry</code> object contains a cluster's state, a cluster's ID, and other important status information.
  ## 
  let valid = call_602207.validator(path, query, header, formData, body)
  let scheme = call_602207.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602207.url(scheme.get, call_602207.host, call_602207.base,
                         call_602207.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602207, url, valid)

proc call*(call_602208: Call_ListClusters_602195; body: JsonNode): Recallable =
  ## listClusters
  ## Returns an array of <code>ClusterListEntry</code> objects of the specified length. Each <code>ClusterListEntry</code> object contains a cluster's state, a cluster's ID, and other important status information.
  ##   body: JObject (required)
  var body_602209 = newJObject()
  if body != nil:
    body_602209 = body
  result = call_602208.call(nil, nil, nil, nil, body_602209)

var listClusters* = Call_ListClusters_602195(name: "listClusters",
    meth: HttpMethod.HttpPost, host: "snowball.amazonaws.com",
    route: "/#X-Amz-Target=AWSIESnowballJobManagementService.ListClusters",
    validator: validate_ListClusters_602196, base: "/", url: url_ListClusters_602197,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListCompatibleImages_602210 = ref object of OpenApiRestCall_601389
proc url_ListCompatibleImages_602212(protocol: Scheme; host: string; base: string;
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

proc validate_ListCompatibleImages_602211(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## This action returns a list of the different Amazon EC2 Amazon Machine Images (AMIs) that are owned by your AWS account that would be supported for use on a Snowball Edge device. Currently, supported AMIs are based on the CentOS 7 (x86_64) - with Updates HVM, Ubuntu Server 14.04 LTS (HVM), and Ubuntu 16.04 LTS - Xenial (HVM) images, available on the AWS Marketplace.
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
  var valid_602213 = header.getOrDefault("X-Amz-Target")
  valid_602213 = validateParameter(valid_602213, JString, required = true, default = newJString(
      "AWSIESnowballJobManagementService.ListCompatibleImages"))
  if valid_602213 != nil:
    section.add "X-Amz-Target", valid_602213
  var valid_602214 = header.getOrDefault("X-Amz-Signature")
  valid_602214 = validateParameter(valid_602214, JString, required = false,
                                 default = nil)
  if valid_602214 != nil:
    section.add "X-Amz-Signature", valid_602214
  var valid_602215 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602215 = validateParameter(valid_602215, JString, required = false,
                                 default = nil)
  if valid_602215 != nil:
    section.add "X-Amz-Content-Sha256", valid_602215
  var valid_602216 = header.getOrDefault("X-Amz-Date")
  valid_602216 = validateParameter(valid_602216, JString, required = false,
                                 default = nil)
  if valid_602216 != nil:
    section.add "X-Amz-Date", valid_602216
  var valid_602217 = header.getOrDefault("X-Amz-Credential")
  valid_602217 = validateParameter(valid_602217, JString, required = false,
                                 default = nil)
  if valid_602217 != nil:
    section.add "X-Amz-Credential", valid_602217
  var valid_602218 = header.getOrDefault("X-Amz-Security-Token")
  valid_602218 = validateParameter(valid_602218, JString, required = false,
                                 default = nil)
  if valid_602218 != nil:
    section.add "X-Amz-Security-Token", valid_602218
  var valid_602219 = header.getOrDefault("X-Amz-Algorithm")
  valid_602219 = validateParameter(valid_602219, JString, required = false,
                                 default = nil)
  if valid_602219 != nil:
    section.add "X-Amz-Algorithm", valid_602219
  var valid_602220 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602220 = validateParameter(valid_602220, JString, required = false,
                                 default = nil)
  if valid_602220 != nil:
    section.add "X-Amz-SignedHeaders", valid_602220
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602222: Call_ListCompatibleImages_602210; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This action returns a list of the different Amazon EC2 Amazon Machine Images (AMIs) that are owned by your AWS account that would be supported for use on a Snowball Edge device. Currently, supported AMIs are based on the CentOS 7 (x86_64) - with Updates HVM, Ubuntu Server 14.04 LTS (HVM), and Ubuntu 16.04 LTS - Xenial (HVM) images, available on the AWS Marketplace.
  ## 
  let valid = call_602222.validator(path, query, header, formData, body)
  let scheme = call_602222.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602222.url(scheme.get, call_602222.host, call_602222.base,
                         call_602222.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602222, url, valid)

proc call*(call_602223: Call_ListCompatibleImages_602210; body: JsonNode): Recallable =
  ## listCompatibleImages
  ## This action returns a list of the different Amazon EC2 Amazon Machine Images (AMIs) that are owned by your AWS account that would be supported for use on a Snowball Edge device. Currently, supported AMIs are based on the CentOS 7 (x86_64) - with Updates HVM, Ubuntu Server 14.04 LTS (HVM), and Ubuntu 16.04 LTS - Xenial (HVM) images, available on the AWS Marketplace.
  ##   body: JObject (required)
  var body_602224 = newJObject()
  if body != nil:
    body_602224 = body
  result = call_602223.call(nil, nil, nil, nil, body_602224)

var listCompatibleImages* = Call_ListCompatibleImages_602210(
    name: "listCompatibleImages", meth: HttpMethod.HttpPost,
    host: "snowball.amazonaws.com", route: "/#X-Amz-Target=AWSIESnowballJobManagementService.ListCompatibleImages",
    validator: validate_ListCompatibleImages_602211, base: "/",
    url: url_ListCompatibleImages_602212, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListJobs_602225 = ref object of OpenApiRestCall_601389
proc url_ListJobs_602227(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_ListJobs_602226(path: JsonNode; query: JsonNode; header: JsonNode;
                             formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns an array of <code>JobListEntry</code> objects of the specified length. Each <code>JobListEntry</code> object contains a job's state, a job's ID, and a value that indicates whether the job is a job part, in the case of export jobs. Calling this API action in one of the US regions will return jobs from the list of all jobs associated with this account in all US regions.
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
  var valid_602228 = query.getOrDefault("MaxResults")
  valid_602228 = validateParameter(valid_602228, JString, required = false,
                                 default = nil)
  if valid_602228 != nil:
    section.add "MaxResults", valid_602228
  var valid_602229 = query.getOrDefault("NextToken")
  valid_602229 = validateParameter(valid_602229, JString, required = false,
                                 default = nil)
  if valid_602229 != nil:
    section.add "NextToken", valid_602229
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
  var valid_602230 = header.getOrDefault("X-Amz-Target")
  valid_602230 = validateParameter(valid_602230, JString, required = true, default = newJString(
      "AWSIESnowballJobManagementService.ListJobs"))
  if valid_602230 != nil:
    section.add "X-Amz-Target", valid_602230
  var valid_602231 = header.getOrDefault("X-Amz-Signature")
  valid_602231 = validateParameter(valid_602231, JString, required = false,
                                 default = nil)
  if valid_602231 != nil:
    section.add "X-Amz-Signature", valid_602231
  var valid_602232 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602232 = validateParameter(valid_602232, JString, required = false,
                                 default = nil)
  if valid_602232 != nil:
    section.add "X-Amz-Content-Sha256", valid_602232
  var valid_602233 = header.getOrDefault("X-Amz-Date")
  valid_602233 = validateParameter(valid_602233, JString, required = false,
                                 default = nil)
  if valid_602233 != nil:
    section.add "X-Amz-Date", valid_602233
  var valid_602234 = header.getOrDefault("X-Amz-Credential")
  valid_602234 = validateParameter(valid_602234, JString, required = false,
                                 default = nil)
  if valid_602234 != nil:
    section.add "X-Amz-Credential", valid_602234
  var valid_602235 = header.getOrDefault("X-Amz-Security-Token")
  valid_602235 = validateParameter(valid_602235, JString, required = false,
                                 default = nil)
  if valid_602235 != nil:
    section.add "X-Amz-Security-Token", valid_602235
  var valid_602236 = header.getOrDefault("X-Amz-Algorithm")
  valid_602236 = validateParameter(valid_602236, JString, required = false,
                                 default = nil)
  if valid_602236 != nil:
    section.add "X-Amz-Algorithm", valid_602236
  var valid_602237 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602237 = validateParameter(valid_602237, JString, required = false,
                                 default = nil)
  if valid_602237 != nil:
    section.add "X-Amz-SignedHeaders", valid_602237
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602239: Call_ListJobs_602225; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns an array of <code>JobListEntry</code> objects of the specified length. Each <code>JobListEntry</code> object contains a job's state, a job's ID, and a value that indicates whether the job is a job part, in the case of export jobs. Calling this API action in one of the US regions will return jobs from the list of all jobs associated with this account in all US regions.
  ## 
  let valid = call_602239.validator(path, query, header, formData, body)
  let scheme = call_602239.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602239.url(scheme.get, call_602239.host, call_602239.base,
                         call_602239.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602239, url, valid)

proc call*(call_602240: Call_ListJobs_602225; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listJobs
  ## Returns an array of <code>JobListEntry</code> objects of the specified length. Each <code>JobListEntry</code> object contains a job's state, a job's ID, and a value that indicates whether the job is a job part, in the case of export jobs. Calling this API action in one of the US regions will return jobs from the list of all jobs associated with this account in all US regions.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_602241 = newJObject()
  var body_602242 = newJObject()
  add(query_602241, "MaxResults", newJString(MaxResults))
  add(query_602241, "NextToken", newJString(NextToken))
  if body != nil:
    body_602242 = body
  result = call_602240.call(nil, query_602241, nil, nil, body_602242)

var listJobs* = Call_ListJobs_602225(name: "listJobs", meth: HttpMethod.HttpPost,
                                  host: "snowball.amazonaws.com", route: "/#X-Amz-Target=AWSIESnowballJobManagementService.ListJobs",
                                  validator: validate_ListJobs_602226, base: "/",
                                  url: url_ListJobs_602227,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateCluster_602243 = ref object of OpenApiRestCall_601389
proc url_UpdateCluster_602245(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateCluster_602244(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## While a cluster's <code>ClusterState</code> value is in the <code>AwaitingQuorum</code> state, you can update some of the information associated with a cluster. Once the cluster changes to a different job state, usually 60 minutes after the cluster being created, this action is no longer available.
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
  var valid_602246 = header.getOrDefault("X-Amz-Target")
  valid_602246 = validateParameter(valid_602246, JString, required = true, default = newJString(
      "AWSIESnowballJobManagementService.UpdateCluster"))
  if valid_602246 != nil:
    section.add "X-Amz-Target", valid_602246
  var valid_602247 = header.getOrDefault("X-Amz-Signature")
  valid_602247 = validateParameter(valid_602247, JString, required = false,
                                 default = nil)
  if valid_602247 != nil:
    section.add "X-Amz-Signature", valid_602247
  var valid_602248 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602248 = validateParameter(valid_602248, JString, required = false,
                                 default = nil)
  if valid_602248 != nil:
    section.add "X-Amz-Content-Sha256", valid_602248
  var valid_602249 = header.getOrDefault("X-Amz-Date")
  valid_602249 = validateParameter(valid_602249, JString, required = false,
                                 default = nil)
  if valid_602249 != nil:
    section.add "X-Amz-Date", valid_602249
  var valid_602250 = header.getOrDefault("X-Amz-Credential")
  valid_602250 = validateParameter(valid_602250, JString, required = false,
                                 default = nil)
  if valid_602250 != nil:
    section.add "X-Amz-Credential", valid_602250
  var valid_602251 = header.getOrDefault("X-Amz-Security-Token")
  valid_602251 = validateParameter(valid_602251, JString, required = false,
                                 default = nil)
  if valid_602251 != nil:
    section.add "X-Amz-Security-Token", valid_602251
  var valid_602252 = header.getOrDefault("X-Amz-Algorithm")
  valid_602252 = validateParameter(valid_602252, JString, required = false,
                                 default = nil)
  if valid_602252 != nil:
    section.add "X-Amz-Algorithm", valid_602252
  var valid_602253 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602253 = validateParameter(valid_602253, JString, required = false,
                                 default = nil)
  if valid_602253 != nil:
    section.add "X-Amz-SignedHeaders", valid_602253
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602255: Call_UpdateCluster_602243; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## While a cluster's <code>ClusterState</code> value is in the <code>AwaitingQuorum</code> state, you can update some of the information associated with a cluster. Once the cluster changes to a different job state, usually 60 minutes after the cluster being created, this action is no longer available.
  ## 
  let valid = call_602255.validator(path, query, header, formData, body)
  let scheme = call_602255.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602255.url(scheme.get, call_602255.host, call_602255.base,
                         call_602255.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602255, url, valid)

proc call*(call_602256: Call_UpdateCluster_602243; body: JsonNode): Recallable =
  ## updateCluster
  ## While a cluster's <code>ClusterState</code> value is in the <code>AwaitingQuorum</code> state, you can update some of the information associated with a cluster. Once the cluster changes to a different job state, usually 60 minutes after the cluster being created, this action is no longer available.
  ##   body: JObject (required)
  var body_602257 = newJObject()
  if body != nil:
    body_602257 = body
  result = call_602256.call(nil, nil, nil, nil, body_602257)

var updateCluster* = Call_UpdateCluster_602243(name: "updateCluster",
    meth: HttpMethod.HttpPost, host: "snowball.amazonaws.com",
    route: "/#X-Amz-Target=AWSIESnowballJobManagementService.UpdateCluster",
    validator: validate_UpdateCluster_602244, base: "/", url: url_UpdateCluster_602245,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateJob_602258 = ref object of OpenApiRestCall_601389
proc url_UpdateJob_602260(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_UpdateJob_602259(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## While a job's <code>JobState</code> value is <code>New</code>, you can update some of the information associated with a job. Once the job changes to a different job state, usually within 60 minutes of the job being created, this action is no longer available.
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
  var valid_602261 = header.getOrDefault("X-Amz-Target")
  valid_602261 = validateParameter(valid_602261, JString, required = true, default = newJString(
      "AWSIESnowballJobManagementService.UpdateJob"))
  if valid_602261 != nil:
    section.add "X-Amz-Target", valid_602261
  var valid_602262 = header.getOrDefault("X-Amz-Signature")
  valid_602262 = validateParameter(valid_602262, JString, required = false,
                                 default = nil)
  if valid_602262 != nil:
    section.add "X-Amz-Signature", valid_602262
  var valid_602263 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602263 = validateParameter(valid_602263, JString, required = false,
                                 default = nil)
  if valid_602263 != nil:
    section.add "X-Amz-Content-Sha256", valid_602263
  var valid_602264 = header.getOrDefault("X-Amz-Date")
  valid_602264 = validateParameter(valid_602264, JString, required = false,
                                 default = nil)
  if valid_602264 != nil:
    section.add "X-Amz-Date", valid_602264
  var valid_602265 = header.getOrDefault("X-Amz-Credential")
  valid_602265 = validateParameter(valid_602265, JString, required = false,
                                 default = nil)
  if valid_602265 != nil:
    section.add "X-Amz-Credential", valid_602265
  var valid_602266 = header.getOrDefault("X-Amz-Security-Token")
  valid_602266 = validateParameter(valid_602266, JString, required = false,
                                 default = nil)
  if valid_602266 != nil:
    section.add "X-Amz-Security-Token", valid_602266
  var valid_602267 = header.getOrDefault("X-Amz-Algorithm")
  valid_602267 = validateParameter(valid_602267, JString, required = false,
                                 default = nil)
  if valid_602267 != nil:
    section.add "X-Amz-Algorithm", valid_602267
  var valid_602268 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602268 = validateParameter(valid_602268, JString, required = false,
                                 default = nil)
  if valid_602268 != nil:
    section.add "X-Amz-SignedHeaders", valid_602268
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602270: Call_UpdateJob_602258; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## While a job's <code>JobState</code> value is <code>New</code>, you can update some of the information associated with a job. Once the job changes to a different job state, usually within 60 minutes of the job being created, this action is no longer available.
  ## 
  let valid = call_602270.validator(path, query, header, formData, body)
  let scheme = call_602270.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602270.url(scheme.get, call_602270.host, call_602270.base,
                         call_602270.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602270, url, valid)

proc call*(call_602271: Call_UpdateJob_602258; body: JsonNode): Recallable =
  ## updateJob
  ## While a job's <code>JobState</code> value is <code>New</code>, you can update some of the information associated with a job. Once the job changes to a different job state, usually within 60 minutes of the job being created, this action is no longer available.
  ##   body: JObject (required)
  var body_602272 = newJObject()
  if body != nil:
    body_602272 = body
  result = call_602271.call(nil, nil, nil, nil, body_602272)

var updateJob* = Call_UpdateJob_602258(name: "updateJob", meth: HttpMethod.HttpPost,
                                    host: "snowball.amazonaws.com", route: "/#X-Amz-Target=AWSIESnowballJobManagementService.UpdateJob",
                                    validator: validate_UpdateJob_602259,
                                    base: "/", url: url_UpdateJob_602260,
                                    schemes: {Scheme.Https, Scheme.Http})
export
  rest

proc atozSign(recall: var Recallable; query: JsonNode; algo: SigningAlgo = SHA256) =
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

method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, input.getOrDefault("body").getStr)
  result.atozSign(input.getOrDefault("query"), SHA256)
