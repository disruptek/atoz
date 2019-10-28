
import
  json, options, hashes, uri, tables, rest, os, uri, strutils, httpcore, sigv4

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

  OpenApiRestCall_590364 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_590364](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_590364): Option[Scheme] {.used.} =
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
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_CancelCluster_590703 = ref object of OpenApiRestCall_590364
proc url_CancelCluster_590705(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CancelCluster_590704(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_590830 = header.getOrDefault("X-Amz-Target")
  valid_590830 = validateParameter(valid_590830, JString, required = true, default = newJString(
      "AWSIESnowballJobManagementService.CancelCluster"))
  if valid_590830 != nil:
    section.add "X-Amz-Target", valid_590830
  var valid_590831 = header.getOrDefault("X-Amz-Signature")
  valid_590831 = validateParameter(valid_590831, JString, required = false,
                                 default = nil)
  if valid_590831 != nil:
    section.add "X-Amz-Signature", valid_590831
  var valid_590832 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_590832 = validateParameter(valid_590832, JString, required = false,
                                 default = nil)
  if valid_590832 != nil:
    section.add "X-Amz-Content-Sha256", valid_590832
  var valid_590833 = header.getOrDefault("X-Amz-Date")
  valid_590833 = validateParameter(valid_590833, JString, required = false,
                                 default = nil)
  if valid_590833 != nil:
    section.add "X-Amz-Date", valid_590833
  var valid_590834 = header.getOrDefault("X-Amz-Credential")
  valid_590834 = validateParameter(valid_590834, JString, required = false,
                                 default = nil)
  if valid_590834 != nil:
    section.add "X-Amz-Credential", valid_590834
  var valid_590835 = header.getOrDefault("X-Amz-Security-Token")
  valid_590835 = validateParameter(valid_590835, JString, required = false,
                                 default = nil)
  if valid_590835 != nil:
    section.add "X-Amz-Security-Token", valid_590835
  var valid_590836 = header.getOrDefault("X-Amz-Algorithm")
  valid_590836 = validateParameter(valid_590836, JString, required = false,
                                 default = nil)
  if valid_590836 != nil:
    section.add "X-Amz-Algorithm", valid_590836
  var valid_590837 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_590837 = validateParameter(valid_590837, JString, required = false,
                                 default = nil)
  if valid_590837 != nil:
    section.add "X-Amz-SignedHeaders", valid_590837
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_590861: Call_CancelCluster_590703; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Cancels a cluster job. You can only cancel a cluster job while it's in the <code>AwaitingQuorum</code> status. You'll have at least an hour after creating a cluster job to cancel it.
  ## 
  let valid = call_590861.validator(path, query, header, formData, body)
  let scheme = call_590861.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_590861.url(scheme.get, call_590861.host, call_590861.base,
                         call_590861.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_590861, url, valid)

proc call*(call_590932: Call_CancelCluster_590703; body: JsonNode): Recallable =
  ## cancelCluster
  ## Cancels a cluster job. You can only cancel a cluster job while it's in the <code>AwaitingQuorum</code> status. You'll have at least an hour after creating a cluster job to cancel it.
  ##   body: JObject (required)
  var body_590933 = newJObject()
  if body != nil:
    body_590933 = body
  result = call_590932.call(nil, nil, nil, nil, body_590933)

var cancelCluster* = Call_CancelCluster_590703(name: "cancelCluster",
    meth: HttpMethod.HttpPost, host: "snowball.amazonaws.com",
    route: "/#X-Amz-Target=AWSIESnowballJobManagementService.CancelCluster",
    validator: validate_CancelCluster_590704, base: "/", url: url_CancelCluster_590705,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CancelJob_590972 = ref object of OpenApiRestCall_590364
proc url_CancelJob_590974(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CancelJob_590973(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_590975 = header.getOrDefault("X-Amz-Target")
  valid_590975 = validateParameter(valid_590975, JString, required = true, default = newJString(
      "AWSIESnowballJobManagementService.CancelJob"))
  if valid_590975 != nil:
    section.add "X-Amz-Target", valid_590975
  var valid_590976 = header.getOrDefault("X-Amz-Signature")
  valid_590976 = validateParameter(valid_590976, JString, required = false,
                                 default = nil)
  if valid_590976 != nil:
    section.add "X-Amz-Signature", valid_590976
  var valid_590977 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_590977 = validateParameter(valid_590977, JString, required = false,
                                 default = nil)
  if valid_590977 != nil:
    section.add "X-Amz-Content-Sha256", valid_590977
  var valid_590978 = header.getOrDefault("X-Amz-Date")
  valid_590978 = validateParameter(valid_590978, JString, required = false,
                                 default = nil)
  if valid_590978 != nil:
    section.add "X-Amz-Date", valid_590978
  var valid_590979 = header.getOrDefault("X-Amz-Credential")
  valid_590979 = validateParameter(valid_590979, JString, required = false,
                                 default = nil)
  if valid_590979 != nil:
    section.add "X-Amz-Credential", valid_590979
  var valid_590980 = header.getOrDefault("X-Amz-Security-Token")
  valid_590980 = validateParameter(valid_590980, JString, required = false,
                                 default = nil)
  if valid_590980 != nil:
    section.add "X-Amz-Security-Token", valid_590980
  var valid_590981 = header.getOrDefault("X-Amz-Algorithm")
  valid_590981 = validateParameter(valid_590981, JString, required = false,
                                 default = nil)
  if valid_590981 != nil:
    section.add "X-Amz-Algorithm", valid_590981
  var valid_590982 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_590982 = validateParameter(valid_590982, JString, required = false,
                                 default = nil)
  if valid_590982 != nil:
    section.add "X-Amz-SignedHeaders", valid_590982
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_590984: Call_CancelJob_590972; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Cancels the specified job. You can only cancel a job before its <code>JobState</code> value changes to <code>PreparingAppliance</code>. Requesting the <code>ListJobs</code> or <code>DescribeJob</code> action returns a job's <code>JobState</code> as part of the response element data returned.
  ## 
  let valid = call_590984.validator(path, query, header, formData, body)
  let scheme = call_590984.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_590984.url(scheme.get, call_590984.host, call_590984.base,
                         call_590984.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_590984, url, valid)

proc call*(call_590985: Call_CancelJob_590972; body: JsonNode): Recallable =
  ## cancelJob
  ## Cancels the specified job. You can only cancel a job before its <code>JobState</code> value changes to <code>PreparingAppliance</code>. Requesting the <code>ListJobs</code> or <code>DescribeJob</code> action returns a job's <code>JobState</code> as part of the response element data returned.
  ##   body: JObject (required)
  var body_590986 = newJObject()
  if body != nil:
    body_590986 = body
  result = call_590985.call(nil, nil, nil, nil, body_590986)

var cancelJob* = Call_CancelJob_590972(name: "cancelJob", meth: HttpMethod.HttpPost,
                                    host: "snowball.amazonaws.com", route: "/#X-Amz-Target=AWSIESnowballJobManagementService.CancelJob",
                                    validator: validate_CancelJob_590973,
                                    base: "/", url: url_CancelJob_590974,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateAddress_590987 = ref object of OpenApiRestCall_590364
proc url_CreateAddress_590989(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateAddress_590988(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_590990 = header.getOrDefault("X-Amz-Target")
  valid_590990 = validateParameter(valid_590990, JString, required = true, default = newJString(
      "AWSIESnowballJobManagementService.CreateAddress"))
  if valid_590990 != nil:
    section.add "X-Amz-Target", valid_590990
  var valid_590991 = header.getOrDefault("X-Amz-Signature")
  valid_590991 = validateParameter(valid_590991, JString, required = false,
                                 default = nil)
  if valid_590991 != nil:
    section.add "X-Amz-Signature", valid_590991
  var valid_590992 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_590992 = validateParameter(valid_590992, JString, required = false,
                                 default = nil)
  if valid_590992 != nil:
    section.add "X-Amz-Content-Sha256", valid_590992
  var valid_590993 = header.getOrDefault("X-Amz-Date")
  valid_590993 = validateParameter(valid_590993, JString, required = false,
                                 default = nil)
  if valid_590993 != nil:
    section.add "X-Amz-Date", valid_590993
  var valid_590994 = header.getOrDefault("X-Amz-Credential")
  valid_590994 = validateParameter(valid_590994, JString, required = false,
                                 default = nil)
  if valid_590994 != nil:
    section.add "X-Amz-Credential", valid_590994
  var valid_590995 = header.getOrDefault("X-Amz-Security-Token")
  valid_590995 = validateParameter(valid_590995, JString, required = false,
                                 default = nil)
  if valid_590995 != nil:
    section.add "X-Amz-Security-Token", valid_590995
  var valid_590996 = header.getOrDefault("X-Amz-Algorithm")
  valid_590996 = validateParameter(valid_590996, JString, required = false,
                                 default = nil)
  if valid_590996 != nil:
    section.add "X-Amz-Algorithm", valid_590996
  var valid_590997 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_590997 = validateParameter(valid_590997, JString, required = false,
                                 default = nil)
  if valid_590997 != nil:
    section.add "X-Amz-SignedHeaders", valid_590997
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_590999: Call_CreateAddress_590987; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an address for a Snowball to be shipped to. In most regions, addresses are validated at the time of creation. The address you provide must be located within the serviceable area of your region. If the address is invalid or unsupported, then an exception is thrown.
  ## 
  let valid = call_590999.validator(path, query, header, formData, body)
  let scheme = call_590999.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_590999.url(scheme.get, call_590999.host, call_590999.base,
                         call_590999.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_590999, url, valid)

proc call*(call_591000: Call_CreateAddress_590987; body: JsonNode): Recallable =
  ## createAddress
  ## Creates an address for a Snowball to be shipped to. In most regions, addresses are validated at the time of creation. The address you provide must be located within the serviceable area of your region. If the address is invalid or unsupported, then an exception is thrown.
  ##   body: JObject (required)
  var body_591001 = newJObject()
  if body != nil:
    body_591001 = body
  result = call_591000.call(nil, nil, nil, nil, body_591001)

var createAddress* = Call_CreateAddress_590987(name: "createAddress",
    meth: HttpMethod.HttpPost, host: "snowball.amazonaws.com",
    route: "/#X-Amz-Target=AWSIESnowballJobManagementService.CreateAddress",
    validator: validate_CreateAddress_590988, base: "/", url: url_CreateAddress_590989,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateCluster_591002 = ref object of OpenApiRestCall_590364
proc url_CreateCluster_591004(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateCluster_591003(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_591005 = header.getOrDefault("X-Amz-Target")
  valid_591005 = validateParameter(valid_591005, JString, required = true, default = newJString(
      "AWSIESnowballJobManagementService.CreateCluster"))
  if valid_591005 != nil:
    section.add "X-Amz-Target", valid_591005
  var valid_591006 = header.getOrDefault("X-Amz-Signature")
  valid_591006 = validateParameter(valid_591006, JString, required = false,
                                 default = nil)
  if valid_591006 != nil:
    section.add "X-Amz-Signature", valid_591006
  var valid_591007 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591007 = validateParameter(valid_591007, JString, required = false,
                                 default = nil)
  if valid_591007 != nil:
    section.add "X-Amz-Content-Sha256", valid_591007
  var valid_591008 = header.getOrDefault("X-Amz-Date")
  valid_591008 = validateParameter(valid_591008, JString, required = false,
                                 default = nil)
  if valid_591008 != nil:
    section.add "X-Amz-Date", valid_591008
  var valid_591009 = header.getOrDefault("X-Amz-Credential")
  valid_591009 = validateParameter(valid_591009, JString, required = false,
                                 default = nil)
  if valid_591009 != nil:
    section.add "X-Amz-Credential", valid_591009
  var valid_591010 = header.getOrDefault("X-Amz-Security-Token")
  valid_591010 = validateParameter(valid_591010, JString, required = false,
                                 default = nil)
  if valid_591010 != nil:
    section.add "X-Amz-Security-Token", valid_591010
  var valid_591011 = header.getOrDefault("X-Amz-Algorithm")
  valid_591011 = validateParameter(valid_591011, JString, required = false,
                                 default = nil)
  if valid_591011 != nil:
    section.add "X-Amz-Algorithm", valid_591011
  var valid_591012 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591012 = validateParameter(valid_591012, JString, required = false,
                                 default = nil)
  if valid_591012 != nil:
    section.add "X-Amz-SignedHeaders", valid_591012
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591014: Call_CreateCluster_591002; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an empty cluster. Each cluster supports five nodes. You use the <a>CreateJob</a> action separately to create the jobs for each of these nodes. The cluster does not ship until these five node jobs have been created.
  ## 
  let valid = call_591014.validator(path, query, header, formData, body)
  let scheme = call_591014.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591014.url(scheme.get, call_591014.host, call_591014.base,
                         call_591014.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591014, url, valid)

proc call*(call_591015: Call_CreateCluster_591002; body: JsonNode): Recallable =
  ## createCluster
  ## Creates an empty cluster. Each cluster supports five nodes. You use the <a>CreateJob</a> action separately to create the jobs for each of these nodes. The cluster does not ship until these five node jobs have been created.
  ##   body: JObject (required)
  var body_591016 = newJObject()
  if body != nil:
    body_591016 = body
  result = call_591015.call(nil, nil, nil, nil, body_591016)

var createCluster* = Call_CreateCluster_591002(name: "createCluster",
    meth: HttpMethod.HttpPost, host: "snowball.amazonaws.com",
    route: "/#X-Amz-Target=AWSIESnowballJobManagementService.CreateCluster",
    validator: validate_CreateCluster_591003, base: "/", url: url_CreateCluster_591004,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateJob_591017 = ref object of OpenApiRestCall_590364
proc url_CreateJob_591019(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateJob_591018(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_591020 = header.getOrDefault("X-Amz-Target")
  valid_591020 = validateParameter(valid_591020, JString, required = true, default = newJString(
      "AWSIESnowballJobManagementService.CreateJob"))
  if valid_591020 != nil:
    section.add "X-Amz-Target", valid_591020
  var valid_591021 = header.getOrDefault("X-Amz-Signature")
  valid_591021 = validateParameter(valid_591021, JString, required = false,
                                 default = nil)
  if valid_591021 != nil:
    section.add "X-Amz-Signature", valid_591021
  var valid_591022 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591022 = validateParameter(valid_591022, JString, required = false,
                                 default = nil)
  if valid_591022 != nil:
    section.add "X-Amz-Content-Sha256", valid_591022
  var valid_591023 = header.getOrDefault("X-Amz-Date")
  valid_591023 = validateParameter(valid_591023, JString, required = false,
                                 default = nil)
  if valid_591023 != nil:
    section.add "X-Amz-Date", valid_591023
  var valid_591024 = header.getOrDefault("X-Amz-Credential")
  valid_591024 = validateParameter(valid_591024, JString, required = false,
                                 default = nil)
  if valid_591024 != nil:
    section.add "X-Amz-Credential", valid_591024
  var valid_591025 = header.getOrDefault("X-Amz-Security-Token")
  valid_591025 = validateParameter(valid_591025, JString, required = false,
                                 default = nil)
  if valid_591025 != nil:
    section.add "X-Amz-Security-Token", valid_591025
  var valid_591026 = header.getOrDefault("X-Amz-Algorithm")
  valid_591026 = validateParameter(valid_591026, JString, required = false,
                                 default = nil)
  if valid_591026 != nil:
    section.add "X-Amz-Algorithm", valid_591026
  var valid_591027 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591027 = validateParameter(valid_591027, JString, required = false,
                                 default = nil)
  if valid_591027 != nil:
    section.add "X-Amz-SignedHeaders", valid_591027
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591029: Call_CreateJob_591017; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a job to import or export data between Amazon S3 and your on-premises data center. Your AWS account must have the right trust policies and permissions in place to create a job for Snowball. If you're creating a job for a node in a cluster, you only need to provide the <code>clusterId</code> value; the other job attributes are inherited from the cluster. 
  ## 
  let valid = call_591029.validator(path, query, header, formData, body)
  let scheme = call_591029.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591029.url(scheme.get, call_591029.host, call_591029.base,
                         call_591029.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591029, url, valid)

proc call*(call_591030: Call_CreateJob_591017; body: JsonNode): Recallable =
  ## createJob
  ## Creates a job to import or export data between Amazon S3 and your on-premises data center. Your AWS account must have the right trust policies and permissions in place to create a job for Snowball. If you're creating a job for a node in a cluster, you only need to provide the <code>clusterId</code> value; the other job attributes are inherited from the cluster. 
  ##   body: JObject (required)
  var body_591031 = newJObject()
  if body != nil:
    body_591031 = body
  result = call_591030.call(nil, nil, nil, nil, body_591031)

var createJob* = Call_CreateJob_591017(name: "createJob", meth: HttpMethod.HttpPost,
                                    host: "snowball.amazonaws.com", route: "/#X-Amz-Target=AWSIESnowballJobManagementService.CreateJob",
                                    validator: validate_CreateJob_591018,
                                    base: "/", url: url_CreateJob_591019,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAddress_591032 = ref object of OpenApiRestCall_590364
proc url_DescribeAddress_591034(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeAddress_591033(path: JsonNode; query: JsonNode;
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
  var valid_591035 = header.getOrDefault("X-Amz-Target")
  valid_591035 = validateParameter(valid_591035, JString, required = true, default = newJString(
      "AWSIESnowballJobManagementService.DescribeAddress"))
  if valid_591035 != nil:
    section.add "X-Amz-Target", valid_591035
  var valid_591036 = header.getOrDefault("X-Amz-Signature")
  valid_591036 = validateParameter(valid_591036, JString, required = false,
                                 default = nil)
  if valid_591036 != nil:
    section.add "X-Amz-Signature", valid_591036
  var valid_591037 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591037 = validateParameter(valid_591037, JString, required = false,
                                 default = nil)
  if valid_591037 != nil:
    section.add "X-Amz-Content-Sha256", valid_591037
  var valid_591038 = header.getOrDefault("X-Amz-Date")
  valid_591038 = validateParameter(valid_591038, JString, required = false,
                                 default = nil)
  if valid_591038 != nil:
    section.add "X-Amz-Date", valid_591038
  var valid_591039 = header.getOrDefault("X-Amz-Credential")
  valid_591039 = validateParameter(valid_591039, JString, required = false,
                                 default = nil)
  if valid_591039 != nil:
    section.add "X-Amz-Credential", valid_591039
  var valid_591040 = header.getOrDefault("X-Amz-Security-Token")
  valid_591040 = validateParameter(valid_591040, JString, required = false,
                                 default = nil)
  if valid_591040 != nil:
    section.add "X-Amz-Security-Token", valid_591040
  var valid_591041 = header.getOrDefault("X-Amz-Algorithm")
  valid_591041 = validateParameter(valid_591041, JString, required = false,
                                 default = nil)
  if valid_591041 != nil:
    section.add "X-Amz-Algorithm", valid_591041
  var valid_591042 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591042 = validateParameter(valid_591042, JString, required = false,
                                 default = nil)
  if valid_591042 != nil:
    section.add "X-Amz-SignedHeaders", valid_591042
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591044: Call_DescribeAddress_591032; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Takes an <code>AddressId</code> and returns specific details about that address in the form of an <code>Address</code> object.
  ## 
  let valid = call_591044.validator(path, query, header, formData, body)
  let scheme = call_591044.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591044.url(scheme.get, call_591044.host, call_591044.base,
                         call_591044.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591044, url, valid)

proc call*(call_591045: Call_DescribeAddress_591032; body: JsonNode): Recallable =
  ## describeAddress
  ## Takes an <code>AddressId</code> and returns specific details about that address in the form of an <code>Address</code> object.
  ##   body: JObject (required)
  var body_591046 = newJObject()
  if body != nil:
    body_591046 = body
  result = call_591045.call(nil, nil, nil, nil, body_591046)

var describeAddress* = Call_DescribeAddress_591032(name: "describeAddress",
    meth: HttpMethod.HttpPost, host: "snowball.amazonaws.com",
    route: "/#X-Amz-Target=AWSIESnowballJobManagementService.DescribeAddress",
    validator: validate_DescribeAddress_591033, base: "/", url: url_DescribeAddress_591034,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAddresses_591047 = ref object of OpenApiRestCall_590364
proc url_DescribeAddresses_591049(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeAddresses_591048(path: JsonNode; query: JsonNode;
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
  var valid_591050 = query.getOrDefault("MaxResults")
  valid_591050 = validateParameter(valid_591050, JString, required = false,
                                 default = nil)
  if valid_591050 != nil:
    section.add "MaxResults", valid_591050
  var valid_591051 = query.getOrDefault("NextToken")
  valid_591051 = validateParameter(valid_591051, JString, required = false,
                                 default = nil)
  if valid_591051 != nil:
    section.add "NextToken", valid_591051
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
  var valid_591052 = header.getOrDefault("X-Amz-Target")
  valid_591052 = validateParameter(valid_591052, JString, required = true, default = newJString(
      "AWSIESnowballJobManagementService.DescribeAddresses"))
  if valid_591052 != nil:
    section.add "X-Amz-Target", valid_591052
  var valid_591053 = header.getOrDefault("X-Amz-Signature")
  valid_591053 = validateParameter(valid_591053, JString, required = false,
                                 default = nil)
  if valid_591053 != nil:
    section.add "X-Amz-Signature", valid_591053
  var valid_591054 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591054 = validateParameter(valid_591054, JString, required = false,
                                 default = nil)
  if valid_591054 != nil:
    section.add "X-Amz-Content-Sha256", valid_591054
  var valid_591055 = header.getOrDefault("X-Amz-Date")
  valid_591055 = validateParameter(valid_591055, JString, required = false,
                                 default = nil)
  if valid_591055 != nil:
    section.add "X-Amz-Date", valid_591055
  var valid_591056 = header.getOrDefault("X-Amz-Credential")
  valid_591056 = validateParameter(valid_591056, JString, required = false,
                                 default = nil)
  if valid_591056 != nil:
    section.add "X-Amz-Credential", valid_591056
  var valid_591057 = header.getOrDefault("X-Amz-Security-Token")
  valid_591057 = validateParameter(valid_591057, JString, required = false,
                                 default = nil)
  if valid_591057 != nil:
    section.add "X-Amz-Security-Token", valid_591057
  var valid_591058 = header.getOrDefault("X-Amz-Algorithm")
  valid_591058 = validateParameter(valid_591058, JString, required = false,
                                 default = nil)
  if valid_591058 != nil:
    section.add "X-Amz-Algorithm", valid_591058
  var valid_591059 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591059 = validateParameter(valid_591059, JString, required = false,
                                 default = nil)
  if valid_591059 != nil:
    section.add "X-Amz-SignedHeaders", valid_591059
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591061: Call_DescribeAddresses_591047; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a specified number of <code>ADDRESS</code> objects. Calling this API in one of the US regions will return addresses from the list of all addresses associated with this account in all US regions.
  ## 
  let valid = call_591061.validator(path, query, header, formData, body)
  let scheme = call_591061.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591061.url(scheme.get, call_591061.host, call_591061.base,
                         call_591061.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591061, url, valid)

proc call*(call_591062: Call_DescribeAddresses_591047; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## describeAddresses
  ## Returns a specified number of <code>ADDRESS</code> objects. Calling this API in one of the US regions will return addresses from the list of all addresses associated with this account in all US regions.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_591063 = newJObject()
  var body_591064 = newJObject()
  add(query_591063, "MaxResults", newJString(MaxResults))
  add(query_591063, "NextToken", newJString(NextToken))
  if body != nil:
    body_591064 = body
  result = call_591062.call(nil, query_591063, nil, nil, body_591064)

var describeAddresses* = Call_DescribeAddresses_591047(name: "describeAddresses",
    meth: HttpMethod.HttpPost, host: "snowball.amazonaws.com", route: "/#X-Amz-Target=AWSIESnowballJobManagementService.DescribeAddresses",
    validator: validate_DescribeAddresses_591048, base: "/",
    url: url_DescribeAddresses_591049, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeCluster_591066 = ref object of OpenApiRestCall_590364
proc url_DescribeCluster_591068(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeCluster_591067(path: JsonNode; query: JsonNode;
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
  var valid_591069 = header.getOrDefault("X-Amz-Target")
  valid_591069 = validateParameter(valid_591069, JString, required = true, default = newJString(
      "AWSIESnowballJobManagementService.DescribeCluster"))
  if valid_591069 != nil:
    section.add "X-Amz-Target", valid_591069
  var valid_591070 = header.getOrDefault("X-Amz-Signature")
  valid_591070 = validateParameter(valid_591070, JString, required = false,
                                 default = nil)
  if valid_591070 != nil:
    section.add "X-Amz-Signature", valid_591070
  var valid_591071 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591071 = validateParameter(valid_591071, JString, required = false,
                                 default = nil)
  if valid_591071 != nil:
    section.add "X-Amz-Content-Sha256", valid_591071
  var valid_591072 = header.getOrDefault("X-Amz-Date")
  valid_591072 = validateParameter(valid_591072, JString, required = false,
                                 default = nil)
  if valid_591072 != nil:
    section.add "X-Amz-Date", valid_591072
  var valid_591073 = header.getOrDefault("X-Amz-Credential")
  valid_591073 = validateParameter(valid_591073, JString, required = false,
                                 default = nil)
  if valid_591073 != nil:
    section.add "X-Amz-Credential", valid_591073
  var valid_591074 = header.getOrDefault("X-Amz-Security-Token")
  valid_591074 = validateParameter(valid_591074, JString, required = false,
                                 default = nil)
  if valid_591074 != nil:
    section.add "X-Amz-Security-Token", valid_591074
  var valid_591075 = header.getOrDefault("X-Amz-Algorithm")
  valid_591075 = validateParameter(valid_591075, JString, required = false,
                                 default = nil)
  if valid_591075 != nil:
    section.add "X-Amz-Algorithm", valid_591075
  var valid_591076 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591076 = validateParameter(valid_591076, JString, required = false,
                                 default = nil)
  if valid_591076 != nil:
    section.add "X-Amz-SignedHeaders", valid_591076
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591078: Call_DescribeCluster_591066; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about a specific cluster including shipping information, cluster status, and other important metadata.
  ## 
  let valid = call_591078.validator(path, query, header, formData, body)
  let scheme = call_591078.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591078.url(scheme.get, call_591078.host, call_591078.base,
                         call_591078.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591078, url, valid)

proc call*(call_591079: Call_DescribeCluster_591066; body: JsonNode): Recallable =
  ## describeCluster
  ## Returns information about a specific cluster including shipping information, cluster status, and other important metadata.
  ##   body: JObject (required)
  var body_591080 = newJObject()
  if body != nil:
    body_591080 = body
  result = call_591079.call(nil, nil, nil, nil, body_591080)

var describeCluster* = Call_DescribeCluster_591066(name: "describeCluster",
    meth: HttpMethod.HttpPost, host: "snowball.amazonaws.com",
    route: "/#X-Amz-Target=AWSIESnowballJobManagementService.DescribeCluster",
    validator: validate_DescribeCluster_591067, base: "/", url: url_DescribeCluster_591068,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeJob_591081 = ref object of OpenApiRestCall_590364
proc url_DescribeJob_591083(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeJob_591082(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_591084 = header.getOrDefault("X-Amz-Target")
  valid_591084 = validateParameter(valid_591084, JString, required = true, default = newJString(
      "AWSIESnowballJobManagementService.DescribeJob"))
  if valid_591084 != nil:
    section.add "X-Amz-Target", valid_591084
  var valid_591085 = header.getOrDefault("X-Amz-Signature")
  valid_591085 = validateParameter(valid_591085, JString, required = false,
                                 default = nil)
  if valid_591085 != nil:
    section.add "X-Amz-Signature", valid_591085
  var valid_591086 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591086 = validateParameter(valid_591086, JString, required = false,
                                 default = nil)
  if valid_591086 != nil:
    section.add "X-Amz-Content-Sha256", valid_591086
  var valid_591087 = header.getOrDefault("X-Amz-Date")
  valid_591087 = validateParameter(valid_591087, JString, required = false,
                                 default = nil)
  if valid_591087 != nil:
    section.add "X-Amz-Date", valid_591087
  var valid_591088 = header.getOrDefault("X-Amz-Credential")
  valid_591088 = validateParameter(valid_591088, JString, required = false,
                                 default = nil)
  if valid_591088 != nil:
    section.add "X-Amz-Credential", valid_591088
  var valid_591089 = header.getOrDefault("X-Amz-Security-Token")
  valid_591089 = validateParameter(valid_591089, JString, required = false,
                                 default = nil)
  if valid_591089 != nil:
    section.add "X-Amz-Security-Token", valid_591089
  var valid_591090 = header.getOrDefault("X-Amz-Algorithm")
  valid_591090 = validateParameter(valid_591090, JString, required = false,
                                 default = nil)
  if valid_591090 != nil:
    section.add "X-Amz-Algorithm", valid_591090
  var valid_591091 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591091 = validateParameter(valid_591091, JString, required = false,
                                 default = nil)
  if valid_591091 != nil:
    section.add "X-Amz-SignedHeaders", valid_591091
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591093: Call_DescribeJob_591081; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about a specific job including shipping information, job status, and other important metadata. 
  ## 
  let valid = call_591093.validator(path, query, header, formData, body)
  let scheme = call_591093.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591093.url(scheme.get, call_591093.host, call_591093.base,
                         call_591093.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591093, url, valid)

proc call*(call_591094: Call_DescribeJob_591081; body: JsonNode): Recallable =
  ## describeJob
  ## Returns information about a specific job including shipping information, job status, and other important metadata. 
  ##   body: JObject (required)
  var body_591095 = newJObject()
  if body != nil:
    body_591095 = body
  result = call_591094.call(nil, nil, nil, nil, body_591095)

var describeJob* = Call_DescribeJob_591081(name: "describeJob",
                                        meth: HttpMethod.HttpPost,
                                        host: "snowball.amazonaws.com", route: "/#X-Amz-Target=AWSIESnowballJobManagementService.DescribeJob",
                                        validator: validate_DescribeJob_591082,
                                        base: "/", url: url_DescribeJob_591083,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetJobManifest_591096 = ref object of OpenApiRestCall_590364
proc url_GetJobManifest_591098(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetJobManifest_591097(path: JsonNode; query: JsonNode;
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
  var valid_591099 = header.getOrDefault("X-Amz-Target")
  valid_591099 = validateParameter(valid_591099, JString, required = true, default = newJString(
      "AWSIESnowballJobManagementService.GetJobManifest"))
  if valid_591099 != nil:
    section.add "X-Amz-Target", valid_591099
  var valid_591100 = header.getOrDefault("X-Amz-Signature")
  valid_591100 = validateParameter(valid_591100, JString, required = false,
                                 default = nil)
  if valid_591100 != nil:
    section.add "X-Amz-Signature", valid_591100
  var valid_591101 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591101 = validateParameter(valid_591101, JString, required = false,
                                 default = nil)
  if valid_591101 != nil:
    section.add "X-Amz-Content-Sha256", valid_591101
  var valid_591102 = header.getOrDefault("X-Amz-Date")
  valid_591102 = validateParameter(valid_591102, JString, required = false,
                                 default = nil)
  if valid_591102 != nil:
    section.add "X-Amz-Date", valid_591102
  var valid_591103 = header.getOrDefault("X-Amz-Credential")
  valid_591103 = validateParameter(valid_591103, JString, required = false,
                                 default = nil)
  if valid_591103 != nil:
    section.add "X-Amz-Credential", valid_591103
  var valid_591104 = header.getOrDefault("X-Amz-Security-Token")
  valid_591104 = validateParameter(valid_591104, JString, required = false,
                                 default = nil)
  if valid_591104 != nil:
    section.add "X-Amz-Security-Token", valid_591104
  var valid_591105 = header.getOrDefault("X-Amz-Algorithm")
  valid_591105 = validateParameter(valid_591105, JString, required = false,
                                 default = nil)
  if valid_591105 != nil:
    section.add "X-Amz-Algorithm", valid_591105
  var valid_591106 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591106 = validateParameter(valid_591106, JString, required = false,
                                 default = nil)
  if valid_591106 != nil:
    section.add "X-Amz-SignedHeaders", valid_591106
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591108: Call_GetJobManifest_591096; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a link to an Amazon S3 presigned URL for the manifest file associated with the specified <code>JobId</code> value. You can access the manifest file for up to 60 minutes after this request has been made. To access the manifest file after 60 minutes have passed, you'll have to make another call to the <code>GetJobManifest</code> action.</p> <p>The manifest is an encrypted file that you can download after your job enters the <code>WithCustomer</code> status. The manifest is decrypted by using the <code>UnlockCode</code> code value, when you pass both values to the Snowball through the Snowball client when the client is started for the first time.</p> <p>As a best practice, we recommend that you don't save a copy of an <code>UnlockCode</code> value in the same location as the manifest file for that job. Saving these separately helps prevent unauthorized parties from gaining access to the Snowball associated with that job.</p> <p>The credentials of a given job, including its manifest file and unlock code, expire 90 days after the job is created.</p>
  ## 
  let valid = call_591108.validator(path, query, header, formData, body)
  let scheme = call_591108.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591108.url(scheme.get, call_591108.host, call_591108.base,
                         call_591108.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591108, url, valid)

proc call*(call_591109: Call_GetJobManifest_591096; body: JsonNode): Recallable =
  ## getJobManifest
  ## <p>Returns a link to an Amazon S3 presigned URL for the manifest file associated with the specified <code>JobId</code> value. You can access the manifest file for up to 60 minutes after this request has been made. To access the manifest file after 60 minutes have passed, you'll have to make another call to the <code>GetJobManifest</code> action.</p> <p>The manifest is an encrypted file that you can download after your job enters the <code>WithCustomer</code> status. The manifest is decrypted by using the <code>UnlockCode</code> code value, when you pass both values to the Snowball through the Snowball client when the client is started for the first time.</p> <p>As a best practice, we recommend that you don't save a copy of an <code>UnlockCode</code> value in the same location as the manifest file for that job. Saving these separately helps prevent unauthorized parties from gaining access to the Snowball associated with that job.</p> <p>The credentials of a given job, including its manifest file and unlock code, expire 90 days after the job is created.</p>
  ##   body: JObject (required)
  var body_591110 = newJObject()
  if body != nil:
    body_591110 = body
  result = call_591109.call(nil, nil, nil, nil, body_591110)

var getJobManifest* = Call_GetJobManifest_591096(name: "getJobManifest",
    meth: HttpMethod.HttpPost, host: "snowball.amazonaws.com",
    route: "/#X-Amz-Target=AWSIESnowballJobManagementService.GetJobManifest",
    validator: validate_GetJobManifest_591097, base: "/", url: url_GetJobManifest_591098,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetJobUnlockCode_591111 = ref object of OpenApiRestCall_590364
proc url_GetJobUnlockCode_591113(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetJobUnlockCode_591112(path: JsonNode; query: JsonNode;
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
  var valid_591114 = header.getOrDefault("X-Amz-Target")
  valid_591114 = validateParameter(valid_591114, JString, required = true, default = newJString(
      "AWSIESnowballJobManagementService.GetJobUnlockCode"))
  if valid_591114 != nil:
    section.add "X-Amz-Target", valid_591114
  var valid_591115 = header.getOrDefault("X-Amz-Signature")
  valid_591115 = validateParameter(valid_591115, JString, required = false,
                                 default = nil)
  if valid_591115 != nil:
    section.add "X-Amz-Signature", valid_591115
  var valid_591116 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591116 = validateParameter(valid_591116, JString, required = false,
                                 default = nil)
  if valid_591116 != nil:
    section.add "X-Amz-Content-Sha256", valid_591116
  var valid_591117 = header.getOrDefault("X-Amz-Date")
  valid_591117 = validateParameter(valid_591117, JString, required = false,
                                 default = nil)
  if valid_591117 != nil:
    section.add "X-Amz-Date", valid_591117
  var valid_591118 = header.getOrDefault("X-Amz-Credential")
  valid_591118 = validateParameter(valid_591118, JString, required = false,
                                 default = nil)
  if valid_591118 != nil:
    section.add "X-Amz-Credential", valid_591118
  var valid_591119 = header.getOrDefault("X-Amz-Security-Token")
  valid_591119 = validateParameter(valid_591119, JString, required = false,
                                 default = nil)
  if valid_591119 != nil:
    section.add "X-Amz-Security-Token", valid_591119
  var valid_591120 = header.getOrDefault("X-Amz-Algorithm")
  valid_591120 = validateParameter(valid_591120, JString, required = false,
                                 default = nil)
  if valid_591120 != nil:
    section.add "X-Amz-Algorithm", valid_591120
  var valid_591121 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591121 = validateParameter(valid_591121, JString, required = false,
                                 default = nil)
  if valid_591121 != nil:
    section.add "X-Amz-SignedHeaders", valid_591121
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591123: Call_GetJobUnlockCode_591111; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the <code>UnlockCode</code> code value for the specified job. A particular <code>UnlockCode</code> value can be accessed for up to 90 days after the associated job has been created.</p> <p>The <code>UnlockCode</code> value is a 29-character code with 25 alphanumeric characters and 4 hyphens. This code is used to decrypt the manifest file when it is passed along with the manifest to the Snowball through the Snowball client when the client is started for the first time.</p> <p>As a best practice, we recommend that you don't save a copy of the <code>UnlockCode</code> in the same location as the manifest file for that job. Saving these separately helps prevent unauthorized parties from gaining access to the Snowball associated with that job.</p>
  ## 
  let valid = call_591123.validator(path, query, header, formData, body)
  let scheme = call_591123.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591123.url(scheme.get, call_591123.host, call_591123.base,
                         call_591123.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591123, url, valid)

proc call*(call_591124: Call_GetJobUnlockCode_591111; body: JsonNode): Recallable =
  ## getJobUnlockCode
  ## <p>Returns the <code>UnlockCode</code> code value for the specified job. A particular <code>UnlockCode</code> value can be accessed for up to 90 days after the associated job has been created.</p> <p>The <code>UnlockCode</code> value is a 29-character code with 25 alphanumeric characters and 4 hyphens. This code is used to decrypt the manifest file when it is passed along with the manifest to the Snowball through the Snowball client when the client is started for the first time.</p> <p>As a best practice, we recommend that you don't save a copy of the <code>UnlockCode</code> in the same location as the manifest file for that job. Saving these separately helps prevent unauthorized parties from gaining access to the Snowball associated with that job.</p>
  ##   body: JObject (required)
  var body_591125 = newJObject()
  if body != nil:
    body_591125 = body
  result = call_591124.call(nil, nil, nil, nil, body_591125)

var getJobUnlockCode* = Call_GetJobUnlockCode_591111(name: "getJobUnlockCode",
    meth: HttpMethod.HttpPost, host: "snowball.amazonaws.com",
    route: "/#X-Amz-Target=AWSIESnowballJobManagementService.GetJobUnlockCode",
    validator: validate_GetJobUnlockCode_591112, base: "/",
    url: url_GetJobUnlockCode_591113, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSnowballUsage_591126 = ref object of OpenApiRestCall_590364
proc url_GetSnowballUsage_591128(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetSnowballUsage_591127(path: JsonNode; query: JsonNode;
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
  var valid_591129 = header.getOrDefault("X-Amz-Target")
  valid_591129 = validateParameter(valid_591129, JString, required = true, default = newJString(
      "AWSIESnowballJobManagementService.GetSnowballUsage"))
  if valid_591129 != nil:
    section.add "X-Amz-Target", valid_591129
  var valid_591130 = header.getOrDefault("X-Amz-Signature")
  valid_591130 = validateParameter(valid_591130, JString, required = false,
                                 default = nil)
  if valid_591130 != nil:
    section.add "X-Amz-Signature", valid_591130
  var valid_591131 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591131 = validateParameter(valid_591131, JString, required = false,
                                 default = nil)
  if valid_591131 != nil:
    section.add "X-Amz-Content-Sha256", valid_591131
  var valid_591132 = header.getOrDefault("X-Amz-Date")
  valid_591132 = validateParameter(valid_591132, JString, required = false,
                                 default = nil)
  if valid_591132 != nil:
    section.add "X-Amz-Date", valid_591132
  var valid_591133 = header.getOrDefault("X-Amz-Credential")
  valid_591133 = validateParameter(valid_591133, JString, required = false,
                                 default = nil)
  if valid_591133 != nil:
    section.add "X-Amz-Credential", valid_591133
  var valid_591134 = header.getOrDefault("X-Amz-Security-Token")
  valid_591134 = validateParameter(valid_591134, JString, required = false,
                                 default = nil)
  if valid_591134 != nil:
    section.add "X-Amz-Security-Token", valid_591134
  var valid_591135 = header.getOrDefault("X-Amz-Algorithm")
  valid_591135 = validateParameter(valid_591135, JString, required = false,
                                 default = nil)
  if valid_591135 != nil:
    section.add "X-Amz-Algorithm", valid_591135
  var valid_591136 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591136 = validateParameter(valid_591136, JString, required = false,
                                 default = nil)
  if valid_591136 != nil:
    section.add "X-Amz-SignedHeaders", valid_591136
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591138: Call_GetSnowballUsage_591126; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns information about the Snowball service limit for your account, and also the number of Snowballs your account has in use.</p> <p>The default service limit for the number of Snowballs that you can have at one time is 1. If you want to increase your service limit, contact AWS Support.</p>
  ## 
  let valid = call_591138.validator(path, query, header, formData, body)
  let scheme = call_591138.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591138.url(scheme.get, call_591138.host, call_591138.base,
                         call_591138.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591138, url, valid)

proc call*(call_591139: Call_GetSnowballUsage_591126; body: JsonNode): Recallable =
  ## getSnowballUsage
  ## <p>Returns information about the Snowball service limit for your account, and also the number of Snowballs your account has in use.</p> <p>The default service limit for the number of Snowballs that you can have at one time is 1. If you want to increase your service limit, contact AWS Support.</p>
  ##   body: JObject (required)
  var body_591140 = newJObject()
  if body != nil:
    body_591140 = body
  result = call_591139.call(nil, nil, nil, nil, body_591140)

var getSnowballUsage* = Call_GetSnowballUsage_591126(name: "getSnowballUsage",
    meth: HttpMethod.HttpPost, host: "snowball.amazonaws.com",
    route: "/#X-Amz-Target=AWSIESnowballJobManagementService.GetSnowballUsage",
    validator: validate_GetSnowballUsage_591127, base: "/",
    url: url_GetSnowballUsage_591128, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSoftwareUpdates_591141 = ref object of OpenApiRestCall_590364
proc url_GetSoftwareUpdates_591143(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetSoftwareUpdates_591142(path: JsonNode; query: JsonNode;
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
  var valid_591144 = header.getOrDefault("X-Amz-Target")
  valid_591144 = validateParameter(valid_591144, JString, required = true, default = newJString(
      "AWSIESnowballJobManagementService.GetSoftwareUpdates"))
  if valid_591144 != nil:
    section.add "X-Amz-Target", valid_591144
  var valid_591145 = header.getOrDefault("X-Amz-Signature")
  valid_591145 = validateParameter(valid_591145, JString, required = false,
                                 default = nil)
  if valid_591145 != nil:
    section.add "X-Amz-Signature", valid_591145
  var valid_591146 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591146 = validateParameter(valid_591146, JString, required = false,
                                 default = nil)
  if valid_591146 != nil:
    section.add "X-Amz-Content-Sha256", valid_591146
  var valid_591147 = header.getOrDefault("X-Amz-Date")
  valid_591147 = validateParameter(valid_591147, JString, required = false,
                                 default = nil)
  if valid_591147 != nil:
    section.add "X-Amz-Date", valid_591147
  var valid_591148 = header.getOrDefault("X-Amz-Credential")
  valid_591148 = validateParameter(valid_591148, JString, required = false,
                                 default = nil)
  if valid_591148 != nil:
    section.add "X-Amz-Credential", valid_591148
  var valid_591149 = header.getOrDefault("X-Amz-Security-Token")
  valid_591149 = validateParameter(valid_591149, JString, required = false,
                                 default = nil)
  if valid_591149 != nil:
    section.add "X-Amz-Security-Token", valid_591149
  var valid_591150 = header.getOrDefault("X-Amz-Algorithm")
  valid_591150 = validateParameter(valid_591150, JString, required = false,
                                 default = nil)
  if valid_591150 != nil:
    section.add "X-Amz-Algorithm", valid_591150
  var valid_591151 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591151 = validateParameter(valid_591151, JString, required = false,
                                 default = nil)
  if valid_591151 != nil:
    section.add "X-Amz-SignedHeaders", valid_591151
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591153: Call_GetSoftwareUpdates_591141; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns an Amazon S3 presigned URL for an update file associated with a specified <code>JobId</code>.
  ## 
  let valid = call_591153.validator(path, query, header, formData, body)
  let scheme = call_591153.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591153.url(scheme.get, call_591153.host, call_591153.base,
                         call_591153.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591153, url, valid)

proc call*(call_591154: Call_GetSoftwareUpdates_591141; body: JsonNode): Recallable =
  ## getSoftwareUpdates
  ## Returns an Amazon S3 presigned URL for an update file associated with a specified <code>JobId</code>.
  ##   body: JObject (required)
  var body_591155 = newJObject()
  if body != nil:
    body_591155 = body
  result = call_591154.call(nil, nil, nil, nil, body_591155)

var getSoftwareUpdates* = Call_GetSoftwareUpdates_591141(
    name: "getSoftwareUpdates", meth: HttpMethod.HttpPost,
    host: "snowball.amazonaws.com", route: "/#X-Amz-Target=AWSIESnowballJobManagementService.GetSoftwareUpdates",
    validator: validate_GetSoftwareUpdates_591142, base: "/",
    url: url_GetSoftwareUpdates_591143, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListClusterJobs_591156 = ref object of OpenApiRestCall_590364
proc url_ListClusterJobs_591158(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListClusterJobs_591157(path: JsonNode; query: JsonNode;
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
  var valid_591159 = header.getOrDefault("X-Amz-Target")
  valid_591159 = validateParameter(valid_591159, JString, required = true, default = newJString(
      "AWSIESnowballJobManagementService.ListClusterJobs"))
  if valid_591159 != nil:
    section.add "X-Amz-Target", valid_591159
  var valid_591160 = header.getOrDefault("X-Amz-Signature")
  valid_591160 = validateParameter(valid_591160, JString, required = false,
                                 default = nil)
  if valid_591160 != nil:
    section.add "X-Amz-Signature", valid_591160
  var valid_591161 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591161 = validateParameter(valid_591161, JString, required = false,
                                 default = nil)
  if valid_591161 != nil:
    section.add "X-Amz-Content-Sha256", valid_591161
  var valid_591162 = header.getOrDefault("X-Amz-Date")
  valid_591162 = validateParameter(valid_591162, JString, required = false,
                                 default = nil)
  if valid_591162 != nil:
    section.add "X-Amz-Date", valid_591162
  var valid_591163 = header.getOrDefault("X-Amz-Credential")
  valid_591163 = validateParameter(valid_591163, JString, required = false,
                                 default = nil)
  if valid_591163 != nil:
    section.add "X-Amz-Credential", valid_591163
  var valid_591164 = header.getOrDefault("X-Amz-Security-Token")
  valid_591164 = validateParameter(valid_591164, JString, required = false,
                                 default = nil)
  if valid_591164 != nil:
    section.add "X-Amz-Security-Token", valid_591164
  var valid_591165 = header.getOrDefault("X-Amz-Algorithm")
  valid_591165 = validateParameter(valid_591165, JString, required = false,
                                 default = nil)
  if valid_591165 != nil:
    section.add "X-Amz-Algorithm", valid_591165
  var valid_591166 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591166 = validateParameter(valid_591166, JString, required = false,
                                 default = nil)
  if valid_591166 != nil:
    section.add "X-Amz-SignedHeaders", valid_591166
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591168: Call_ListClusterJobs_591156; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns an array of <code>JobListEntry</code> objects of the specified length. Each <code>JobListEntry</code> object is for a job in the specified cluster and contains a job's state, a job's ID, and other information.
  ## 
  let valid = call_591168.validator(path, query, header, formData, body)
  let scheme = call_591168.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591168.url(scheme.get, call_591168.host, call_591168.base,
                         call_591168.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591168, url, valid)

proc call*(call_591169: Call_ListClusterJobs_591156; body: JsonNode): Recallable =
  ## listClusterJobs
  ## Returns an array of <code>JobListEntry</code> objects of the specified length. Each <code>JobListEntry</code> object is for a job in the specified cluster and contains a job's state, a job's ID, and other information.
  ##   body: JObject (required)
  var body_591170 = newJObject()
  if body != nil:
    body_591170 = body
  result = call_591169.call(nil, nil, nil, nil, body_591170)

var listClusterJobs* = Call_ListClusterJobs_591156(name: "listClusterJobs",
    meth: HttpMethod.HttpPost, host: "snowball.amazonaws.com",
    route: "/#X-Amz-Target=AWSIESnowballJobManagementService.ListClusterJobs",
    validator: validate_ListClusterJobs_591157, base: "/", url: url_ListClusterJobs_591158,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListClusters_591171 = ref object of OpenApiRestCall_590364
proc url_ListClusters_591173(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListClusters_591172(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_591174 = header.getOrDefault("X-Amz-Target")
  valid_591174 = validateParameter(valid_591174, JString, required = true, default = newJString(
      "AWSIESnowballJobManagementService.ListClusters"))
  if valid_591174 != nil:
    section.add "X-Amz-Target", valid_591174
  var valid_591175 = header.getOrDefault("X-Amz-Signature")
  valid_591175 = validateParameter(valid_591175, JString, required = false,
                                 default = nil)
  if valid_591175 != nil:
    section.add "X-Amz-Signature", valid_591175
  var valid_591176 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591176 = validateParameter(valid_591176, JString, required = false,
                                 default = nil)
  if valid_591176 != nil:
    section.add "X-Amz-Content-Sha256", valid_591176
  var valid_591177 = header.getOrDefault("X-Amz-Date")
  valid_591177 = validateParameter(valid_591177, JString, required = false,
                                 default = nil)
  if valid_591177 != nil:
    section.add "X-Amz-Date", valid_591177
  var valid_591178 = header.getOrDefault("X-Amz-Credential")
  valid_591178 = validateParameter(valid_591178, JString, required = false,
                                 default = nil)
  if valid_591178 != nil:
    section.add "X-Amz-Credential", valid_591178
  var valid_591179 = header.getOrDefault("X-Amz-Security-Token")
  valid_591179 = validateParameter(valid_591179, JString, required = false,
                                 default = nil)
  if valid_591179 != nil:
    section.add "X-Amz-Security-Token", valid_591179
  var valid_591180 = header.getOrDefault("X-Amz-Algorithm")
  valid_591180 = validateParameter(valid_591180, JString, required = false,
                                 default = nil)
  if valid_591180 != nil:
    section.add "X-Amz-Algorithm", valid_591180
  var valid_591181 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591181 = validateParameter(valid_591181, JString, required = false,
                                 default = nil)
  if valid_591181 != nil:
    section.add "X-Amz-SignedHeaders", valid_591181
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591183: Call_ListClusters_591171; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns an array of <code>ClusterListEntry</code> objects of the specified length. Each <code>ClusterListEntry</code> object contains a cluster's state, a cluster's ID, and other important status information.
  ## 
  let valid = call_591183.validator(path, query, header, formData, body)
  let scheme = call_591183.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591183.url(scheme.get, call_591183.host, call_591183.base,
                         call_591183.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591183, url, valid)

proc call*(call_591184: Call_ListClusters_591171; body: JsonNode): Recallable =
  ## listClusters
  ## Returns an array of <code>ClusterListEntry</code> objects of the specified length. Each <code>ClusterListEntry</code> object contains a cluster's state, a cluster's ID, and other important status information.
  ##   body: JObject (required)
  var body_591185 = newJObject()
  if body != nil:
    body_591185 = body
  result = call_591184.call(nil, nil, nil, nil, body_591185)

var listClusters* = Call_ListClusters_591171(name: "listClusters",
    meth: HttpMethod.HttpPost, host: "snowball.amazonaws.com",
    route: "/#X-Amz-Target=AWSIESnowballJobManagementService.ListClusters",
    validator: validate_ListClusters_591172, base: "/", url: url_ListClusters_591173,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListCompatibleImages_591186 = ref object of OpenApiRestCall_590364
proc url_ListCompatibleImages_591188(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListCompatibleImages_591187(path: JsonNode; query: JsonNode;
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
  var valid_591189 = header.getOrDefault("X-Amz-Target")
  valid_591189 = validateParameter(valid_591189, JString, required = true, default = newJString(
      "AWSIESnowballJobManagementService.ListCompatibleImages"))
  if valid_591189 != nil:
    section.add "X-Amz-Target", valid_591189
  var valid_591190 = header.getOrDefault("X-Amz-Signature")
  valid_591190 = validateParameter(valid_591190, JString, required = false,
                                 default = nil)
  if valid_591190 != nil:
    section.add "X-Amz-Signature", valid_591190
  var valid_591191 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591191 = validateParameter(valid_591191, JString, required = false,
                                 default = nil)
  if valid_591191 != nil:
    section.add "X-Amz-Content-Sha256", valid_591191
  var valid_591192 = header.getOrDefault("X-Amz-Date")
  valid_591192 = validateParameter(valid_591192, JString, required = false,
                                 default = nil)
  if valid_591192 != nil:
    section.add "X-Amz-Date", valid_591192
  var valid_591193 = header.getOrDefault("X-Amz-Credential")
  valid_591193 = validateParameter(valid_591193, JString, required = false,
                                 default = nil)
  if valid_591193 != nil:
    section.add "X-Amz-Credential", valid_591193
  var valid_591194 = header.getOrDefault("X-Amz-Security-Token")
  valid_591194 = validateParameter(valid_591194, JString, required = false,
                                 default = nil)
  if valid_591194 != nil:
    section.add "X-Amz-Security-Token", valid_591194
  var valid_591195 = header.getOrDefault("X-Amz-Algorithm")
  valid_591195 = validateParameter(valid_591195, JString, required = false,
                                 default = nil)
  if valid_591195 != nil:
    section.add "X-Amz-Algorithm", valid_591195
  var valid_591196 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591196 = validateParameter(valid_591196, JString, required = false,
                                 default = nil)
  if valid_591196 != nil:
    section.add "X-Amz-SignedHeaders", valid_591196
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591198: Call_ListCompatibleImages_591186; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This action returns a list of the different Amazon EC2 Amazon Machine Images (AMIs) that are owned by your AWS account that would be supported for use on a Snowball Edge device. Currently, supported AMIs are based on the CentOS 7 (x86_64) - with Updates HVM, Ubuntu Server 14.04 LTS (HVM), and Ubuntu 16.04 LTS - Xenial (HVM) images, available on the AWS Marketplace.
  ## 
  let valid = call_591198.validator(path, query, header, formData, body)
  let scheme = call_591198.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591198.url(scheme.get, call_591198.host, call_591198.base,
                         call_591198.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591198, url, valid)

proc call*(call_591199: Call_ListCompatibleImages_591186; body: JsonNode): Recallable =
  ## listCompatibleImages
  ## This action returns a list of the different Amazon EC2 Amazon Machine Images (AMIs) that are owned by your AWS account that would be supported for use on a Snowball Edge device. Currently, supported AMIs are based on the CentOS 7 (x86_64) - with Updates HVM, Ubuntu Server 14.04 LTS (HVM), and Ubuntu 16.04 LTS - Xenial (HVM) images, available on the AWS Marketplace.
  ##   body: JObject (required)
  var body_591200 = newJObject()
  if body != nil:
    body_591200 = body
  result = call_591199.call(nil, nil, nil, nil, body_591200)

var listCompatibleImages* = Call_ListCompatibleImages_591186(
    name: "listCompatibleImages", meth: HttpMethod.HttpPost,
    host: "snowball.amazonaws.com", route: "/#X-Amz-Target=AWSIESnowballJobManagementService.ListCompatibleImages",
    validator: validate_ListCompatibleImages_591187, base: "/",
    url: url_ListCompatibleImages_591188, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListJobs_591201 = ref object of OpenApiRestCall_590364
proc url_ListJobs_591203(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListJobs_591202(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_591204 = query.getOrDefault("MaxResults")
  valid_591204 = validateParameter(valid_591204, JString, required = false,
                                 default = nil)
  if valid_591204 != nil:
    section.add "MaxResults", valid_591204
  var valid_591205 = query.getOrDefault("NextToken")
  valid_591205 = validateParameter(valid_591205, JString, required = false,
                                 default = nil)
  if valid_591205 != nil:
    section.add "NextToken", valid_591205
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
  var valid_591206 = header.getOrDefault("X-Amz-Target")
  valid_591206 = validateParameter(valid_591206, JString, required = true, default = newJString(
      "AWSIESnowballJobManagementService.ListJobs"))
  if valid_591206 != nil:
    section.add "X-Amz-Target", valid_591206
  var valid_591207 = header.getOrDefault("X-Amz-Signature")
  valid_591207 = validateParameter(valid_591207, JString, required = false,
                                 default = nil)
  if valid_591207 != nil:
    section.add "X-Amz-Signature", valid_591207
  var valid_591208 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591208 = validateParameter(valid_591208, JString, required = false,
                                 default = nil)
  if valid_591208 != nil:
    section.add "X-Amz-Content-Sha256", valid_591208
  var valid_591209 = header.getOrDefault("X-Amz-Date")
  valid_591209 = validateParameter(valid_591209, JString, required = false,
                                 default = nil)
  if valid_591209 != nil:
    section.add "X-Amz-Date", valid_591209
  var valid_591210 = header.getOrDefault("X-Amz-Credential")
  valid_591210 = validateParameter(valid_591210, JString, required = false,
                                 default = nil)
  if valid_591210 != nil:
    section.add "X-Amz-Credential", valid_591210
  var valid_591211 = header.getOrDefault("X-Amz-Security-Token")
  valid_591211 = validateParameter(valid_591211, JString, required = false,
                                 default = nil)
  if valid_591211 != nil:
    section.add "X-Amz-Security-Token", valid_591211
  var valid_591212 = header.getOrDefault("X-Amz-Algorithm")
  valid_591212 = validateParameter(valid_591212, JString, required = false,
                                 default = nil)
  if valid_591212 != nil:
    section.add "X-Amz-Algorithm", valid_591212
  var valid_591213 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591213 = validateParameter(valid_591213, JString, required = false,
                                 default = nil)
  if valid_591213 != nil:
    section.add "X-Amz-SignedHeaders", valid_591213
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591215: Call_ListJobs_591201; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns an array of <code>JobListEntry</code> objects of the specified length. Each <code>JobListEntry</code> object contains a job's state, a job's ID, and a value that indicates whether the job is a job part, in the case of export jobs. Calling this API action in one of the US regions will return jobs from the list of all jobs associated with this account in all US regions.
  ## 
  let valid = call_591215.validator(path, query, header, formData, body)
  let scheme = call_591215.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591215.url(scheme.get, call_591215.host, call_591215.base,
                         call_591215.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591215, url, valid)

proc call*(call_591216: Call_ListJobs_591201; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listJobs
  ## Returns an array of <code>JobListEntry</code> objects of the specified length. Each <code>JobListEntry</code> object contains a job's state, a job's ID, and a value that indicates whether the job is a job part, in the case of export jobs. Calling this API action in one of the US regions will return jobs from the list of all jobs associated with this account in all US regions.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_591217 = newJObject()
  var body_591218 = newJObject()
  add(query_591217, "MaxResults", newJString(MaxResults))
  add(query_591217, "NextToken", newJString(NextToken))
  if body != nil:
    body_591218 = body
  result = call_591216.call(nil, query_591217, nil, nil, body_591218)

var listJobs* = Call_ListJobs_591201(name: "listJobs", meth: HttpMethod.HttpPost,
                                  host: "snowball.amazonaws.com", route: "/#X-Amz-Target=AWSIESnowballJobManagementService.ListJobs",
                                  validator: validate_ListJobs_591202, base: "/",
                                  url: url_ListJobs_591203,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateCluster_591219 = ref object of OpenApiRestCall_590364
proc url_UpdateCluster_591221(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateCluster_591220(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_591222 = header.getOrDefault("X-Amz-Target")
  valid_591222 = validateParameter(valid_591222, JString, required = true, default = newJString(
      "AWSIESnowballJobManagementService.UpdateCluster"))
  if valid_591222 != nil:
    section.add "X-Amz-Target", valid_591222
  var valid_591223 = header.getOrDefault("X-Amz-Signature")
  valid_591223 = validateParameter(valid_591223, JString, required = false,
                                 default = nil)
  if valid_591223 != nil:
    section.add "X-Amz-Signature", valid_591223
  var valid_591224 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591224 = validateParameter(valid_591224, JString, required = false,
                                 default = nil)
  if valid_591224 != nil:
    section.add "X-Amz-Content-Sha256", valid_591224
  var valid_591225 = header.getOrDefault("X-Amz-Date")
  valid_591225 = validateParameter(valid_591225, JString, required = false,
                                 default = nil)
  if valid_591225 != nil:
    section.add "X-Amz-Date", valid_591225
  var valid_591226 = header.getOrDefault("X-Amz-Credential")
  valid_591226 = validateParameter(valid_591226, JString, required = false,
                                 default = nil)
  if valid_591226 != nil:
    section.add "X-Amz-Credential", valid_591226
  var valid_591227 = header.getOrDefault("X-Amz-Security-Token")
  valid_591227 = validateParameter(valid_591227, JString, required = false,
                                 default = nil)
  if valid_591227 != nil:
    section.add "X-Amz-Security-Token", valid_591227
  var valid_591228 = header.getOrDefault("X-Amz-Algorithm")
  valid_591228 = validateParameter(valid_591228, JString, required = false,
                                 default = nil)
  if valid_591228 != nil:
    section.add "X-Amz-Algorithm", valid_591228
  var valid_591229 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591229 = validateParameter(valid_591229, JString, required = false,
                                 default = nil)
  if valid_591229 != nil:
    section.add "X-Amz-SignedHeaders", valid_591229
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591231: Call_UpdateCluster_591219; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## While a cluster's <code>ClusterState</code> value is in the <code>AwaitingQuorum</code> state, you can update some of the information associated with a cluster. Once the cluster changes to a different job state, usually 60 minutes after the cluster being created, this action is no longer available.
  ## 
  let valid = call_591231.validator(path, query, header, formData, body)
  let scheme = call_591231.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591231.url(scheme.get, call_591231.host, call_591231.base,
                         call_591231.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591231, url, valid)

proc call*(call_591232: Call_UpdateCluster_591219; body: JsonNode): Recallable =
  ## updateCluster
  ## While a cluster's <code>ClusterState</code> value is in the <code>AwaitingQuorum</code> state, you can update some of the information associated with a cluster. Once the cluster changes to a different job state, usually 60 minutes after the cluster being created, this action is no longer available.
  ##   body: JObject (required)
  var body_591233 = newJObject()
  if body != nil:
    body_591233 = body
  result = call_591232.call(nil, nil, nil, nil, body_591233)

var updateCluster* = Call_UpdateCluster_591219(name: "updateCluster",
    meth: HttpMethod.HttpPost, host: "snowball.amazonaws.com",
    route: "/#X-Amz-Target=AWSIESnowballJobManagementService.UpdateCluster",
    validator: validate_UpdateCluster_591220, base: "/", url: url_UpdateCluster_591221,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateJob_591234 = ref object of OpenApiRestCall_590364
proc url_UpdateJob_591236(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateJob_591235(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_591237 = header.getOrDefault("X-Amz-Target")
  valid_591237 = validateParameter(valid_591237, JString, required = true, default = newJString(
      "AWSIESnowballJobManagementService.UpdateJob"))
  if valid_591237 != nil:
    section.add "X-Amz-Target", valid_591237
  var valid_591238 = header.getOrDefault("X-Amz-Signature")
  valid_591238 = validateParameter(valid_591238, JString, required = false,
                                 default = nil)
  if valid_591238 != nil:
    section.add "X-Amz-Signature", valid_591238
  var valid_591239 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591239 = validateParameter(valid_591239, JString, required = false,
                                 default = nil)
  if valid_591239 != nil:
    section.add "X-Amz-Content-Sha256", valid_591239
  var valid_591240 = header.getOrDefault("X-Amz-Date")
  valid_591240 = validateParameter(valid_591240, JString, required = false,
                                 default = nil)
  if valid_591240 != nil:
    section.add "X-Amz-Date", valid_591240
  var valid_591241 = header.getOrDefault("X-Amz-Credential")
  valid_591241 = validateParameter(valid_591241, JString, required = false,
                                 default = nil)
  if valid_591241 != nil:
    section.add "X-Amz-Credential", valid_591241
  var valid_591242 = header.getOrDefault("X-Amz-Security-Token")
  valid_591242 = validateParameter(valid_591242, JString, required = false,
                                 default = nil)
  if valid_591242 != nil:
    section.add "X-Amz-Security-Token", valid_591242
  var valid_591243 = header.getOrDefault("X-Amz-Algorithm")
  valid_591243 = validateParameter(valid_591243, JString, required = false,
                                 default = nil)
  if valid_591243 != nil:
    section.add "X-Amz-Algorithm", valid_591243
  var valid_591244 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591244 = validateParameter(valid_591244, JString, required = false,
                                 default = nil)
  if valid_591244 != nil:
    section.add "X-Amz-SignedHeaders", valid_591244
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591246: Call_UpdateJob_591234; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## While a job's <code>JobState</code> value is <code>New</code>, you can update some of the information associated with a job. Once the job changes to a different job state, usually within 60 minutes of the job being created, this action is no longer available.
  ## 
  let valid = call_591246.validator(path, query, header, formData, body)
  let scheme = call_591246.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591246.url(scheme.get, call_591246.host, call_591246.base,
                         call_591246.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591246, url, valid)

proc call*(call_591247: Call_UpdateJob_591234; body: JsonNode): Recallable =
  ## updateJob
  ## While a job's <code>JobState</code> value is <code>New</code>, you can update some of the information associated with a job. Once the job changes to a different job state, usually within 60 minutes of the job being created, this action is no longer available.
  ##   body: JObject (required)
  var body_591248 = newJObject()
  if body != nil:
    body_591248 = body
  result = call_591247.call(nil, nil, nil, nil, body_591248)

var updateJob* = Call_UpdateJob_591234(name: "updateJob", meth: HttpMethod.HttpPost,
                                    host: "snowball.amazonaws.com", route: "/#X-Amz-Target=AWSIESnowballJobManagementService.UpdateJob",
                                    validator: validate_UpdateJob_591235,
                                    base: "/", url: url_UpdateJob_591236,
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
