
import
  json, options, hashes, uri, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: Amazon CloudFront
## version: 2018-06-18
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <fullname>Amazon CloudFront</fullname> <p>This is the <i>Amazon CloudFront API Reference</i>. This guide is for developers who need detailed information about CloudFront API actions, data types, and errors. For detailed information about CloudFront features, see the <i>Amazon CloudFront Developer Guide</i>.</p>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/cloudfront/
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

  OpenApiRestCall_592364 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_592364](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_592364): Option[Scheme] {.used.} =
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
  awsServers = {Scheme.Http: {"cn-northwest-1": "cloudfront.cn-northwest-1.amazonaws.com.cn", "cn-north-1": "cloudfront.cn-north-1.amazonaws.com.cn"}.toTable, Scheme.Https: {
      "cn-northwest-1": "cloudfront.cn-northwest-1.amazonaws.com.cn",
      "cn-north-1": "cloudfront.cn-north-1.amazonaws.com.cn"}.toTable}.toTable
const
  awsServiceName = "cloudfront"
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_CreateCloudFrontOriginAccessIdentity20180618_592960 = ref object of OpenApiRestCall_592364
proc url_CreateCloudFrontOriginAccessIdentity20180618_592962(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateCloudFrontOriginAccessIdentity20180618_592961(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a new origin access identity. If you're using Amazon S3 for your origin, you can use an origin access identity to require users to access your content using a CloudFront URL instead of the Amazon S3 URL. For more information about how to use origin access identities, see <a href="http://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/PrivateContent.html">Serving Private Content through CloudFront</a> in the <i>Amazon CloudFront Developer Guide</i>.
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
  var valid_592963 = header.getOrDefault("X-Amz-Signature")
  valid_592963 = validateParameter(valid_592963, JString, required = false,
                                 default = nil)
  if valid_592963 != nil:
    section.add "X-Amz-Signature", valid_592963
  var valid_592964 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592964 = validateParameter(valid_592964, JString, required = false,
                                 default = nil)
  if valid_592964 != nil:
    section.add "X-Amz-Content-Sha256", valid_592964
  var valid_592965 = header.getOrDefault("X-Amz-Date")
  valid_592965 = validateParameter(valid_592965, JString, required = false,
                                 default = nil)
  if valid_592965 != nil:
    section.add "X-Amz-Date", valid_592965
  var valid_592966 = header.getOrDefault("X-Amz-Credential")
  valid_592966 = validateParameter(valid_592966, JString, required = false,
                                 default = nil)
  if valid_592966 != nil:
    section.add "X-Amz-Credential", valid_592966
  var valid_592967 = header.getOrDefault("X-Amz-Security-Token")
  valid_592967 = validateParameter(valid_592967, JString, required = false,
                                 default = nil)
  if valid_592967 != nil:
    section.add "X-Amz-Security-Token", valid_592967
  var valid_592968 = header.getOrDefault("X-Amz-Algorithm")
  valid_592968 = validateParameter(valid_592968, JString, required = false,
                                 default = nil)
  if valid_592968 != nil:
    section.add "X-Amz-Algorithm", valid_592968
  var valid_592969 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592969 = validateParameter(valid_592969, JString, required = false,
                                 default = nil)
  if valid_592969 != nil:
    section.add "X-Amz-SignedHeaders", valid_592969
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592971: Call_CreateCloudFrontOriginAccessIdentity20180618_592960;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Creates a new origin access identity. If you're using Amazon S3 for your origin, you can use an origin access identity to require users to access your content using a CloudFront URL instead of the Amazon S3 URL. For more information about how to use origin access identities, see <a href="http://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/PrivateContent.html">Serving Private Content through CloudFront</a> in the <i>Amazon CloudFront Developer Guide</i>.
  ## 
  let valid = call_592971.validator(path, query, header, formData, body)
  let scheme = call_592971.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592971.url(scheme.get, call_592971.host, call_592971.base,
                         call_592971.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592971, url, valid)

proc call*(call_592972: Call_CreateCloudFrontOriginAccessIdentity20180618_592960;
          body: JsonNode): Recallable =
  ## createCloudFrontOriginAccessIdentity20180618
  ## Creates a new origin access identity. If you're using Amazon S3 for your origin, you can use an origin access identity to require users to access your content using a CloudFront URL instead of the Amazon S3 URL. For more information about how to use origin access identities, see <a href="http://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/PrivateContent.html">Serving Private Content through CloudFront</a> in the <i>Amazon CloudFront Developer Guide</i>.
  ##   body: JObject (required)
  var body_592973 = newJObject()
  if body != nil:
    body_592973 = body
  result = call_592972.call(nil, nil, nil, nil, body_592973)

var createCloudFrontOriginAccessIdentity20180618* = Call_CreateCloudFrontOriginAccessIdentity20180618_592960(
    name: "createCloudFrontOriginAccessIdentity20180618",
    meth: HttpMethod.HttpPost, host: "cloudfront.amazonaws.com",
    route: "/2018-06-18/origin-access-identity/cloudfront",
    validator: validate_CreateCloudFrontOriginAccessIdentity20180618_592961,
    base: "/", url: url_CreateCloudFrontOriginAccessIdentity20180618_592962,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListCloudFrontOriginAccessIdentities20180618_592703 = ref object of OpenApiRestCall_592364
proc url_ListCloudFrontOriginAccessIdentities20180618_592705(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListCloudFrontOriginAccessIdentities20180618_592704(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists origin access identities.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##         : Use this when paginating results to indicate where to begin in your list of origin access identities. The results include identities in the list that occur after the marker. To get the next page of results, set the <code>Marker</code> to the value of the <code>NextMarker</code> from the current page's response (which is also the ID of the last identity on that page).
  ##   MaxItems: JString
  ##           : The maximum number of origin access identities you want in the response body. 
  section = newJObject()
  var valid_592817 = query.getOrDefault("Marker")
  valid_592817 = validateParameter(valid_592817, JString, required = false,
                                 default = nil)
  if valid_592817 != nil:
    section.add "Marker", valid_592817
  var valid_592818 = query.getOrDefault("MaxItems")
  valid_592818 = validateParameter(valid_592818, JString, required = false,
                                 default = nil)
  if valid_592818 != nil:
    section.add "MaxItems", valid_592818
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
  var valid_592819 = header.getOrDefault("X-Amz-Signature")
  valid_592819 = validateParameter(valid_592819, JString, required = false,
                                 default = nil)
  if valid_592819 != nil:
    section.add "X-Amz-Signature", valid_592819
  var valid_592820 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592820 = validateParameter(valid_592820, JString, required = false,
                                 default = nil)
  if valid_592820 != nil:
    section.add "X-Amz-Content-Sha256", valid_592820
  var valid_592821 = header.getOrDefault("X-Amz-Date")
  valid_592821 = validateParameter(valid_592821, JString, required = false,
                                 default = nil)
  if valid_592821 != nil:
    section.add "X-Amz-Date", valid_592821
  var valid_592822 = header.getOrDefault("X-Amz-Credential")
  valid_592822 = validateParameter(valid_592822, JString, required = false,
                                 default = nil)
  if valid_592822 != nil:
    section.add "X-Amz-Credential", valid_592822
  var valid_592823 = header.getOrDefault("X-Amz-Security-Token")
  valid_592823 = validateParameter(valid_592823, JString, required = false,
                                 default = nil)
  if valid_592823 != nil:
    section.add "X-Amz-Security-Token", valid_592823
  var valid_592824 = header.getOrDefault("X-Amz-Algorithm")
  valid_592824 = validateParameter(valid_592824, JString, required = false,
                                 default = nil)
  if valid_592824 != nil:
    section.add "X-Amz-Algorithm", valid_592824
  var valid_592825 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592825 = validateParameter(valid_592825, JString, required = false,
                                 default = nil)
  if valid_592825 != nil:
    section.add "X-Amz-SignedHeaders", valid_592825
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592848: Call_ListCloudFrontOriginAccessIdentities20180618_592703;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists origin access identities.
  ## 
  let valid = call_592848.validator(path, query, header, formData, body)
  let scheme = call_592848.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592848.url(scheme.get, call_592848.host, call_592848.base,
                         call_592848.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592848, url, valid)

proc call*(call_592919: Call_ListCloudFrontOriginAccessIdentities20180618_592703;
          Marker: string = ""; MaxItems: string = ""): Recallable =
  ## listCloudFrontOriginAccessIdentities20180618
  ## Lists origin access identities.
  ##   Marker: string
  ##         : Use this when paginating results to indicate where to begin in your list of origin access identities. The results include identities in the list that occur after the marker. To get the next page of results, set the <code>Marker</code> to the value of the <code>NextMarker</code> from the current page's response (which is also the ID of the last identity on that page).
  ##   MaxItems: string
  ##           : The maximum number of origin access identities you want in the response body. 
  var query_592920 = newJObject()
  add(query_592920, "Marker", newJString(Marker))
  add(query_592920, "MaxItems", newJString(MaxItems))
  result = call_592919.call(nil, query_592920, nil, nil, nil)

var listCloudFrontOriginAccessIdentities20180618* = Call_ListCloudFrontOriginAccessIdentities20180618_592703(
    name: "listCloudFrontOriginAccessIdentities20180618",
    meth: HttpMethod.HttpGet, host: "cloudfront.amazonaws.com",
    route: "/2018-06-18/origin-access-identity/cloudfront",
    validator: validate_ListCloudFrontOriginAccessIdentities20180618_592704,
    base: "/", url: url_ListCloudFrontOriginAccessIdentities20180618_592705,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDistribution20180618_592989 = ref object of OpenApiRestCall_592364
proc url_CreateDistribution20180618_592991(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateDistribution20180618_592990(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates a new web distribution. You create a CloudFront distribution to tell CloudFront where you want content to be delivered from, and the details about how to track and manage content delivery. Send a <code>POST</code> request to the <code>/<i>CloudFront API version</i>/distribution</code>/<code>distribution ID</code> resource.</p> <important> <p>When you update a distribution, there are more required fields than when you create a distribution. When you update your distribution by using <a>UpdateDistribution</a>, follow the steps included in the documentation to get the current configuration and then make your updates. This helps to make sure that you include all of the required fields. To view a summary, see <a href="http://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/distribution-overview-required-fields.html">Required Fields for Create Distribution and Update Distribution</a> in the <i>Amazon CloudFront Developer Guide</i>.</p> </important> <p>If you are using Adobe Flash Media Server's RTMP protocol, you set up a different kind of CloudFront distribution. For more information, see <a>CreateStreamingDistribution</a>.</p>
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
  var valid_592992 = header.getOrDefault("X-Amz-Signature")
  valid_592992 = validateParameter(valid_592992, JString, required = false,
                                 default = nil)
  if valid_592992 != nil:
    section.add "X-Amz-Signature", valid_592992
  var valid_592993 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592993 = validateParameter(valid_592993, JString, required = false,
                                 default = nil)
  if valid_592993 != nil:
    section.add "X-Amz-Content-Sha256", valid_592993
  var valid_592994 = header.getOrDefault("X-Amz-Date")
  valid_592994 = validateParameter(valid_592994, JString, required = false,
                                 default = nil)
  if valid_592994 != nil:
    section.add "X-Amz-Date", valid_592994
  var valid_592995 = header.getOrDefault("X-Amz-Credential")
  valid_592995 = validateParameter(valid_592995, JString, required = false,
                                 default = nil)
  if valid_592995 != nil:
    section.add "X-Amz-Credential", valid_592995
  var valid_592996 = header.getOrDefault("X-Amz-Security-Token")
  valid_592996 = validateParameter(valid_592996, JString, required = false,
                                 default = nil)
  if valid_592996 != nil:
    section.add "X-Amz-Security-Token", valid_592996
  var valid_592997 = header.getOrDefault("X-Amz-Algorithm")
  valid_592997 = validateParameter(valid_592997, JString, required = false,
                                 default = nil)
  if valid_592997 != nil:
    section.add "X-Amz-Algorithm", valid_592997
  var valid_592998 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592998 = validateParameter(valid_592998, JString, required = false,
                                 default = nil)
  if valid_592998 != nil:
    section.add "X-Amz-SignedHeaders", valid_592998
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593000: Call_CreateDistribution20180618_592989; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a new web distribution. You create a CloudFront distribution to tell CloudFront where you want content to be delivered from, and the details about how to track and manage content delivery. Send a <code>POST</code> request to the <code>/<i>CloudFront API version</i>/distribution</code>/<code>distribution ID</code> resource.</p> <important> <p>When you update a distribution, there are more required fields than when you create a distribution. When you update your distribution by using <a>UpdateDistribution</a>, follow the steps included in the documentation to get the current configuration and then make your updates. This helps to make sure that you include all of the required fields. To view a summary, see <a href="http://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/distribution-overview-required-fields.html">Required Fields for Create Distribution and Update Distribution</a> in the <i>Amazon CloudFront Developer Guide</i>.</p> </important> <p>If you are using Adobe Flash Media Server's RTMP protocol, you set up a different kind of CloudFront distribution. For more information, see <a>CreateStreamingDistribution</a>.</p>
  ## 
  let valid = call_593000.validator(path, query, header, formData, body)
  let scheme = call_593000.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593000.url(scheme.get, call_593000.host, call_593000.base,
                         call_593000.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593000, url, valid)

proc call*(call_593001: Call_CreateDistribution20180618_592989; body: JsonNode): Recallable =
  ## createDistribution20180618
  ## <p>Creates a new web distribution. You create a CloudFront distribution to tell CloudFront where you want content to be delivered from, and the details about how to track and manage content delivery. Send a <code>POST</code> request to the <code>/<i>CloudFront API version</i>/distribution</code>/<code>distribution ID</code> resource.</p> <important> <p>When you update a distribution, there are more required fields than when you create a distribution. When you update your distribution by using <a>UpdateDistribution</a>, follow the steps included in the documentation to get the current configuration and then make your updates. This helps to make sure that you include all of the required fields. To view a summary, see <a href="http://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/distribution-overview-required-fields.html">Required Fields for Create Distribution and Update Distribution</a> in the <i>Amazon CloudFront Developer Guide</i>.</p> </important> <p>If you are using Adobe Flash Media Server's RTMP protocol, you set up a different kind of CloudFront distribution. For more information, see <a>CreateStreamingDistribution</a>.</p>
  ##   body: JObject (required)
  var body_593002 = newJObject()
  if body != nil:
    body_593002 = body
  result = call_593001.call(nil, nil, nil, nil, body_593002)

var createDistribution20180618* = Call_CreateDistribution20180618_592989(
    name: "createDistribution20180618", meth: HttpMethod.HttpPost,
    host: "cloudfront.amazonaws.com", route: "/2018-06-18/distribution",
    validator: validate_CreateDistribution20180618_592990, base: "/",
    url: url_CreateDistribution20180618_592991,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDistributions20180618_592974 = ref object of OpenApiRestCall_592364
proc url_ListDistributions20180618_592976(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListDistributions20180618_592975(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## List distributions. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##         : Use this when paginating results to indicate where to begin in your list of distributions. The results include distributions in the list that occur after the marker. To get the next page of results, set the <code>Marker</code> to the value of the <code>NextMarker</code> from the current page's response (which is also the ID of the last distribution on that page).
  ##   MaxItems: JString
  ##           : The maximum number of distributions you want in the response body.
  section = newJObject()
  var valid_592977 = query.getOrDefault("Marker")
  valid_592977 = validateParameter(valid_592977, JString, required = false,
                                 default = nil)
  if valid_592977 != nil:
    section.add "Marker", valid_592977
  var valid_592978 = query.getOrDefault("MaxItems")
  valid_592978 = validateParameter(valid_592978, JString, required = false,
                                 default = nil)
  if valid_592978 != nil:
    section.add "MaxItems", valid_592978
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
  var valid_592979 = header.getOrDefault("X-Amz-Signature")
  valid_592979 = validateParameter(valid_592979, JString, required = false,
                                 default = nil)
  if valid_592979 != nil:
    section.add "X-Amz-Signature", valid_592979
  var valid_592980 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592980 = validateParameter(valid_592980, JString, required = false,
                                 default = nil)
  if valid_592980 != nil:
    section.add "X-Amz-Content-Sha256", valid_592980
  var valid_592981 = header.getOrDefault("X-Amz-Date")
  valid_592981 = validateParameter(valid_592981, JString, required = false,
                                 default = nil)
  if valid_592981 != nil:
    section.add "X-Amz-Date", valid_592981
  var valid_592982 = header.getOrDefault("X-Amz-Credential")
  valid_592982 = validateParameter(valid_592982, JString, required = false,
                                 default = nil)
  if valid_592982 != nil:
    section.add "X-Amz-Credential", valid_592982
  var valid_592983 = header.getOrDefault("X-Amz-Security-Token")
  valid_592983 = validateParameter(valid_592983, JString, required = false,
                                 default = nil)
  if valid_592983 != nil:
    section.add "X-Amz-Security-Token", valid_592983
  var valid_592984 = header.getOrDefault("X-Amz-Algorithm")
  valid_592984 = validateParameter(valid_592984, JString, required = false,
                                 default = nil)
  if valid_592984 != nil:
    section.add "X-Amz-Algorithm", valid_592984
  var valid_592985 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592985 = validateParameter(valid_592985, JString, required = false,
                                 default = nil)
  if valid_592985 != nil:
    section.add "X-Amz-SignedHeaders", valid_592985
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592986: Call_ListDistributions20180618_592974; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List distributions. 
  ## 
  let valid = call_592986.validator(path, query, header, formData, body)
  let scheme = call_592986.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592986.url(scheme.get, call_592986.host, call_592986.base,
                         call_592986.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592986, url, valid)

proc call*(call_592987: Call_ListDistributions20180618_592974; Marker: string = "";
          MaxItems: string = ""): Recallable =
  ## listDistributions20180618
  ## List distributions. 
  ##   Marker: string
  ##         : Use this when paginating results to indicate where to begin in your list of distributions. The results include distributions in the list that occur after the marker. To get the next page of results, set the <code>Marker</code> to the value of the <code>NextMarker</code> from the current page's response (which is also the ID of the last distribution on that page).
  ##   MaxItems: string
  ##           : The maximum number of distributions you want in the response body.
  var query_592988 = newJObject()
  add(query_592988, "Marker", newJString(Marker))
  add(query_592988, "MaxItems", newJString(MaxItems))
  result = call_592987.call(nil, query_592988, nil, nil, nil)

var listDistributions20180618* = Call_ListDistributions20180618_592974(
    name: "listDistributions20180618", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com", route: "/2018-06-18/distribution",
    validator: validate_ListDistributions20180618_592975, base: "/",
    url: url_ListDistributions20180618_592976,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDistributionWithTags20180618_593003 = ref object of OpenApiRestCall_592364
proc url_CreateDistributionWithTags20180618_593005(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateDistributionWithTags20180618_593004(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Create a new distribution with tags.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   WithTags: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `WithTags` field"
  var valid_593006 = query.getOrDefault("WithTags")
  valid_593006 = validateParameter(valid_593006, JBool, required = true, default = nil)
  if valid_593006 != nil:
    section.add "WithTags", valid_593006
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
  var valid_593007 = header.getOrDefault("X-Amz-Signature")
  valid_593007 = validateParameter(valid_593007, JString, required = false,
                                 default = nil)
  if valid_593007 != nil:
    section.add "X-Amz-Signature", valid_593007
  var valid_593008 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593008 = validateParameter(valid_593008, JString, required = false,
                                 default = nil)
  if valid_593008 != nil:
    section.add "X-Amz-Content-Sha256", valid_593008
  var valid_593009 = header.getOrDefault("X-Amz-Date")
  valid_593009 = validateParameter(valid_593009, JString, required = false,
                                 default = nil)
  if valid_593009 != nil:
    section.add "X-Amz-Date", valid_593009
  var valid_593010 = header.getOrDefault("X-Amz-Credential")
  valid_593010 = validateParameter(valid_593010, JString, required = false,
                                 default = nil)
  if valid_593010 != nil:
    section.add "X-Amz-Credential", valid_593010
  var valid_593011 = header.getOrDefault("X-Amz-Security-Token")
  valid_593011 = validateParameter(valid_593011, JString, required = false,
                                 default = nil)
  if valid_593011 != nil:
    section.add "X-Amz-Security-Token", valid_593011
  var valid_593012 = header.getOrDefault("X-Amz-Algorithm")
  valid_593012 = validateParameter(valid_593012, JString, required = false,
                                 default = nil)
  if valid_593012 != nil:
    section.add "X-Amz-Algorithm", valid_593012
  var valid_593013 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593013 = validateParameter(valid_593013, JString, required = false,
                                 default = nil)
  if valid_593013 != nil:
    section.add "X-Amz-SignedHeaders", valid_593013
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593015: Call_CreateDistributionWithTags20180618_593003;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Create a new distribution with tags.
  ## 
  let valid = call_593015.validator(path, query, header, formData, body)
  let scheme = call_593015.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593015.url(scheme.get, call_593015.host, call_593015.base,
                         call_593015.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593015, url, valid)

proc call*(call_593016: Call_CreateDistributionWithTags20180618_593003;
          body: JsonNode; WithTags: bool): Recallable =
  ## createDistributionWithTags20180618
  ## Create a new distribution with tags.
  ##   body: JObject (required)
  ##   WithTags: bool (required)
  var query_593017 = newJObject()
  var body_593018 = newJObject()
  if body != nil:
    body_593018 = body
  add(query_593017, "WithTags", newJBool(WithTags))
  result = call_593016.call(nil, query_593017, nil, nil, body_593018)

var createDistributionWithTags20180618* = Call_CreateDistributionWithTags20180618_593003(
    name: "createDistributionWithTags20180618", meth: HttpMethod.HttpPost,
    host: "cloudfront.amazonaws.com", route: "/2018-06-18/distribution#WithTags",
    validator: validate_CreateDistributionWithTags20180618_593004, base: "/",
    url: url_CreateDistributionWithTags20180618_593005,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateFieldLevelEncryptionConfig20180618_593034 = ref object of OpenApiRestCall_592364
proc url_CreateFieldLevelEncryptionConfig20180618_593036(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateFieldLevelEncryptionConfig20180618_593035(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Create a new field-level encryption configuration.
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
  var valid_593037 = header.getOrDefault("X-Amz-Signature")
  valid_593037 = validateParameter(valid_593037, JString, required = false,
                                 default = nil)
  if valid_593037 != nil:
    section.add "X-Amz-Signature", valid_593037
  var valid_593038 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593038 = validateParameter(valid_593038, JString, required = false,
                                 default = nil)
  if valid_593038 != nil:
    section.add "X-Amz-Content-Sha256", valid_593038
  var valid_593039 = header.getOrDefault("X-Amz-Date")
  valid_593039 = validateParameter(valid_593039, JString, required = false,
                                 default = nil)
  if valid_593039 != nil:
    section.add "X-Amz-Date", valid_593039
  var valid_593040 = header.getOrDefault("X-Amz-Credential")
  valid_593040 = validateParameter(valid_593040, JString, required = false,
                                 default = nil)
  if valid_593040 != nil:
    section.add "X-Amz-Credential", valid_593040
  var valid_593041 = header.getOrDefault("X-Amz-Security-Token")
  valid_593041 = validateParameter(valid_593041, JString, required = false,
                                 default = nil)
  if valid_593041 != nil:
    section.add "X-Amz-Security-Token", valid_593041
  var valid_593042 = header.getOrDefault("X-Amz-Algorithm")
  valid_593042 = validateParameter(valid_593042, JString, required = false,
                                 default = nil)
  if valid_593042 != nil:
    section.add "X-Amz-Algorithm", valid_593042
  var valid_593043 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593043 = validateParameter(valid_593043, JString, required = false,
                                 default = nil)
  if valid_593043 != nil:
    section.add "X-Amz-SignedHeaders", valid_593043
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593045: Call_CreateFieldLevelEncryptionConfig20180618_593034;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Create a new field-level encryption configuration.
  ## 
  let valid = call_593045.validator(path, query, header, formData, body)
  let scheme = call_593045.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593045.url(scheme.get, call_593045.host, call_593045.base,
                         call_593045.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593045, url, valid)

proc call*(call_593046: Call_CreateFieldLevelEncryptionConfig20180618_593034;
          body: JsonNode): Recallable =
  ## createFieldLevelEncryptionConfig20180618
  ## Create a new field-level encryption configuration.
  ##   body: JObject (required)
  var body_593047 = newJObject()
  if body != nil:
    body_593047 = body
  result = call_593046.call(nil, nil, nil, nil, body_593047)

var createFieldLevelEncryptionConfig20180618* = Call_CreateFieldLevelEncryptionConfig20180618_593034(
    name: "createFieldLevelEncryptionConfig20180618", meth: HttpMethod.HttpPost,
    host: "cloudfront.amazonaws.com", route: "/2018-06-18/field-level-encryption",
    validator: validate_CreateFieldLevelEncryptionConfig20180618_593035,
    base: "/", url: url_CreateFieldLevelEncryptionConfig20180618_593036,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListFieldLevelEncryptionConfigs20180618_593019 = ref object of OpenApiRestCall_592364
proc url_ListFieldLevelEncryptionConfigs20180618_593021(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListFieldLevelEncryptionConfigs20180618_593020(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## List all field-level encryption configurations that have been created in CloudFront for this account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##         : Use this when paginating results to indicate where to begin in your list of configurations. The results include configurations in the list that occur after the marker. To get the next page of results, set the <code>Marker</code> to the value of the <code>NextMarker</code> from the current page's response (which is also the ID of the last configuration on that page). 
  ##   MaxItems: JString
  ##           : The maximum number of field-level encryption configurations you want in the response body. 
  section = newJObject()
  var valid_593022 = query.getOrDefault("Marker")
  valid_593022 = validateParameter(valid_593022, JString, required = false,
                                 default = nil)
  if valid_593022 != nil:
    section.add "Marker", valid_593022
  var valid_593023 = query.getOrDefault("MaxItems")
  valid_593023 = validateParameter(valid_593023, JString, required = false,
                                 default = nil)
  if valid_593023 != nil:
    section.add "MaxItems", valid_593023
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
  var valid_593024 = header.getOrDefault("X-Amz-Signature")
  valid_593024 = validateParameter(valid_593024, JString, required = false,
                                 default = nil)
  if valid_593024 != nil:
    section.add "X-Amz-Signature", valid_593024
  var valid_593025 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593025 = validateParameter(valid_593025, JString, required = false,
                                 default = nil)
  if valid_593025 != nil:
    section.add "X-Amz-Content-Sha256", valid_593025
  var valid_593026 = header.getOrDefault("X-Amz-Date")
  valid_593026 = validateParameter(valid_593026, JString, required = false,
                                 default = nil)
  if valid_593026 != nil:
    section.add "X-Amz-Date", valid_593026
  var valid_593027 = header.getOrDefault("X-Amz-Credential")
  valid_593027 = validateParameter(valid_593027, JString, required = false,
                                 default = nil)
  if valid_593027 != nil:
    section.add "X-Amz-Credential", valid_593027
  var valid_593028 = header.getOrDefault("X-Amz-Security-Token")
  valid_593028 = validateParameter(valid_593028, JString, required = false,
                                 default = nil)
  if valid_593028 != nil:
    section.add "X-Amz-Security-Token", valid_593028
  var valid_593029 = header.getOrDefault("X-Amz-Algorithm")
  valid_593029 = validateParameter(valid_593029, JString, required = false,
                                 default = nil)
  if valid_593029 != nil:
    section.add "X-Amz-Algorithm", valid_593029
  var valid_593030 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593030 = validateParameter(valid_593030, JString, required = false,
                                 default = nil)
  if valid_593030 != nil:
    section.add "X-Amz-SignedHeaders", valid_593030
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593031: Call_ListFieldLevelEncryptionConfigs20180618_593019;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## List all field-level encryption configurations that have been created in CloudFront for this account.
  ## 
  let valid = call_593031.validator(path, query, header, formData, body)
  let scheme = call_593031.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593031.url(scheme.get, call_593031.host, call_593031.base,
                         call_593031.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593031, url, valid)

proc call*(call_593032: Call_ListFieldLevelEncryptionConfigs20180618_593019;
          Marker: string = ""; MaxItems: string = ""): Recallable =
  ## listFieldLevelEncryptionConfigs20180618
  ## List all field-level encryption configurations that have been created in CloudFront for this account.
  ##   Marker: string
  ##         : Use this when paginating results to indicate where to begin in your list of configurations. The results include configurations in the list that occur after the marker. To get the next page of results, set the <code>Marker</code> to the value of the <code>NextMarker</code> from the current page's response (which is also the ID of the last configuration on that page). 
  ##   MaxItems: string
  ##           : The maximum number of field-level encryption configurations you want in the response body. 
  var query_593033 = newJObject()
  add(query_593033, "Marker", newJString(Marker))
  add(query_593033, "MaxItems", newJString(MaxItems))
  result = call_593032.call(nil, query_593033, nil, nil, nil)

var listFieldLevelEncryptionConfigs20180618* = Call_ListFieldLevelEncryptionConfigs20180618_593019(
    name: "listFieldLevelEncryptionConfigs20180618", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com", route: "/2018-06-18/field-level-encryption",
    validator: validate_ListFieldLevelEncryptionConfigs20180618_593020, base: "/",
    url: url_ListFieldLevelEncryptionConfigs20180618_593021,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateFieldLevelEncryptionProfile20180618_593063 = ref object of OpenApiRestCall_592364
proc url_CreateFieldLevelEncryptionProfile20180618_593065(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateFieldLevelEncryptionProfile20180618_593064(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Create a field-level encryption profile.
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
  var valid_593066 = header.getOrDefault("X-Amz-Signature")
  valid_593066 = validateParameter(valid_593066, JString, required = false,
                                 default = nil)
  if valid_593066 != nil:
    section.add "X-Amz-Signature", valid_593066
  var valid_593067 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593067 = validateParameter(valid_593067, JString, required = false,
                                 default = nil)
  if valid_593067 != nil:
    section.add "X-Amz-Content-Sha256", valid_593067
  var valid_593068 = header.getOrDefault("X-Amz-Date")
  valid_593068 = validateParameter(valid_593068, JString, required = false,
                                 default = nil)
  if valid_593068 != nil:
    section.add "X-Amz-Date", valid_593068
  var valid_593069 = header.getOrDefault("X-Amz-Credential")
  valid_593069 = validateParameter(valid_593069, JString, required = false,
                                 default = nil)
  if valid_593069 != nil:
    section.add "X-Amz-Credential", valid_593069
  var valid_593070 = header.getOrDefault("X-Amz-Security-Token")
  valid_593070 = validateParameter(valid_593070, JString, required = false,
                                 default = nil)
  if valid_593070 != nil:
    section.add "X-Amz-Security-Token", valid_593070
  var valid_593071 = header.getOrDefault("X-Amz-Algorithm")
  valid_593071 = validateParameter(valid_593071, JString, required = false,
                                 default = nil)
  if valid_593071 != nil:
    section.add "X-Amz-Algorithm", valid_593071
  var valid_593072 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593072 = validateParameter(valid_593072, JString, required = false,
                                 default = nil)
  if valid_593072 != nil:
    section.add "X-Amz-SignedHeaders", valid_593072
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593074: Call_CreateFieldLevelEncryptionProfile20180618_593063;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Create a field-level encryption profile.
  ## 
  let valid = call_593074.validator(path, query, header, formData, body)
  let scheme = call_593074.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593074.url(scheme.get, call_593074.host, call_593074.base,
                         call_593074.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593074, url, valid)

proc call*(call_593075: Call_CreateFieldLevelEncryptionProfile20180618_593063;
          body: JsonNode): Recallable =
  ## createFieldLevelEncryptionProfile20180618
  ## Create a field-level encryption profile.
  ##   body: JObject (required)
  var body_593076 = newJObject()
  if body != nil:
    body_593076 = body
  result = call_593075.call(nil, nil, nil, nil, body_593076)

var createFieldLevelEncryptionProfile20180618* = Call_CreateFieldLevelEncryptionProfile20180618_593063(
    name: "createFieldLevelEncryptionProfile20180618", meth: HttpMethod.HttpPost,
    host: "cloudfront.amazonaws.com",
    route: "/2018-06-18/field-level-encryption-profile",
    validator: validate_CreateFieldLevelEncryptionProfile20180618_593064,
    base: "/", url: url_CreateFieldLevelEncryptionProfile20180618_593065,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListFieldLevelEncryptionProfiles20180618_593048 = ref object of OpenApiRestCall_592364
proc url_ListFieldLevelEncryptionProfiles20180618_593050(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListFieldLevelEncryptionProfiles20180618_593049(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Request a list of field-level encryption profiles that have been created in CloudFront for this account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##         : Use this when paginating results to indicate where to begin in your list of profiles. The results include profiles in the list that occur after the marker. To get the next page of results, set the <code>Marker</code> to the value of the <code>NextMarker</code> from the current page's response (which is also the ID of the last profile on that page). 
  ##   MaxItems: JString
  ##           : The maximum number of field-level encryption profiles you want in the response body. 
  section = newJObject()
  var valid_593051 = query.getOrDefault("Marker")
  valid_593051 = validateParameter(valid_593051, JString, required = false,
                                 default = nil)
  if valid_593051 != nil:
    section.add "Marker", valid_593051
  var valid_593052 = query.getOrDefault("MaxItems")
  valid_593052 = validateParameter(valid_593052, JString, required = false,
                                 default = nil)
  if valid_593052 != nil:
    section.add "MaxItems", valid_593052
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
  var valid_593053 = header.getOrDefault("X-Amz-Signature")
  valid_593053 = validateParameter(valid_593053, JString, required = false,
                                 default = nil)
  if valid_593053 != nil:
    section.add "X-Amz-Signature", valid_593053
  var valid_593054 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593054 = validateParameter(valid_593054, JString, required = false,
                                 default = nil)
  if valid_593054 != nil:
    section.add "X-Amz-Content-Sha256", valid_593054
  var valid_593055 = header.getOrDefault("X-Amz-Date")
  valid_593055 = validateParameter(valid_593055, JString, required = false,
                                 default = nil)
  if valid_593055 != nil:
    section.add "X-Amz-Date", valid_593055
  var valid_593056 = header.getOrDefault("X-Amz-Credential")
  valid_593056 = validateParameter(valid_593056, JString, required = false,
                                 default = nil)
  if valid_593056 != nil:
    section.add "X-Amz-Credential", valid_593056
  var valid_593057 = header.getOrDefault("X-Amz-Security-Token")
  valid_593057 = validateParameter(valid_593057, JString, required = false,
                                 default = nil)
  if valid_593057 != nil:
    section.add "X-Amz-Security-Token", valid_593057
  var valid_593058 = header.getOrDefault("X-Amz-Algorithm")
  valid_593058 = validateParameter(valid_593058, JString, required = false,
                                 default = nil)
  if valid_593058 != nil:
    section.add "X-Amz-Algorithm", valid_593058
  var valid_593059 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593059 = validateParameter(valid_593059, JString, required = false,
                                 default = nil)
  if valid_593059 != nil:
    section.add "X-Amz-SignedHeaders", valid_593059
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593060: Call_ListFieldLevelEncryptionProfiles20180618_593048;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Request a list of field-level encryption profiles that have been created in CloudFront for this account.
  ## 
  let valid = call_593060.validator(path, query, header, formData, body)
  let scheme = call_593060.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593060.url(scheme.get, call_593060.host, call_593060.base,
                         call_593060.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593060, url, valid)

proc call*(call_593061: Call_ListFieldLevelEncryptionProfiles20180618_593048;
          Marker: string = ""; MaxItems: string = ""): Recallable =
  ## listFieldLevelEncryptionProfiles20180618
  ## Request a list of field-level encryption profiles that have been created in CloudFront for this account.
  ##   Marker: string
  ##         : Use this when paginating results to indicate where to begin in your list of profiles. The results include profiles in the list that occur after the marker. To get the next page of results, set the <code>Marker</code> to the value of the <code>NextMarker</code> from the current page's response (which is also the ID of the last profile on that page). 
  ##   MaxItems: string
  ##           : The maximum number of field-level encryption profiles you want in the response body. 
  var query_593062 = newJObject()
  add(query_593062, "Marker", newJString(Marker))
  add(query_593062, "MaxItems", newJString(MaxItems))
  result = call_593061.call(nil, query_593062, nil, nil, nil)

var listFieldLevelEncryptionProfiles20180618* = Call_ListFieldLevelEncryptionProfiles20180618_593048(
    name: "listFieldLevelEncryptionProfiles20180618", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com",
    route: "/2018-06-18/field-level-encryption-profile",
    validator: validate_ListFieldLevelEncryptionProfiles20180618_593049,
    base: "/", url: url_ListFieldLevelEncryptionProfiles20180618_593050,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateInvalidation20180618_593108 = ref object of OpenApiRestCall_592364
proc url_CreateInvalidation20180618_593110(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "DistributionId" in path, "`DistributionId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2018-06-18/distribution/"),
               (kind: VariableSegment, value: "DistributionId"),
               (kind: ConstantSegment, value: "/invalidation")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_CreateInvalidation20180618_593109(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Create a new invalidation. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   DistributionId: JString (required)
  ##                 : The distribution's id.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `DistributionId` field"
  var valid_593111 = path.getOrDefault("DistributionId")
  valid_593111 = validateParameter(valid_593111, JString, required = true,
                                 default = nil)
  if valid_593111 != nil:
    section.add "DistributionId", valid_593111
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
  var valid_593112 = header.getOrDefault("X-Amz-Signature")
  valid_593112 = validateParameter(valid_593112, JString, required = false,
                                 default = nil)
  if valid_593112 != nil:
    section.add "X-Amz-Signature", valid_593112
  var valid_593113 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593113 = validateParameter(valid_593113, JString, required = false,
                                 default = nil)
  if valid_593113 != nil:
    section.add "X-Amz-Content-Sha256", valid_593113
  var valid_593114 = header.getOrDefault("X-Amz-Date")
  valid_593114 = validateParameter(valid_593114, JString, required = false,
                                 default = nil)
  if valid_593114 != nil:
    section.add "X-Amz-Date", valid_593114
  var valid_593115 = header.getOrDefault("X-Amz-Credential")
  valid_593115 = validateParameter(valid_593115, JString, required = false,
                                 default = nil)
  if valid_593115 != nil:
    section.add "X-Amz-Credential", valid_593115
  var valid_593116 = header.getOrDefault("X-Amz-Security-Token")
  valid_593116 = validateParameter(valid_593116, JString, required = false,
                                 default = nil)
  if valid_593116 != nil:
    section.add "X-Amz-Security-Token", valid_593116
  var valid_593117 = header.getOrDefault("X-Amz-Algorithm")
  valid_593117 = validateParameter(valid_593117, JString, required = false,
                                 default = nil)
  if valid_593117 != nil:
    section.add "X-Amz-Algorithm", valid_593117
  var valid_593118 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593118 = validateParameter(valid_593118, JString, required = false,
                                 default = nil)
  if valid_593118 != nil:
    section.add "X-Amz-SignedHeaders", valid_593118
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593120: Call_CreateInvalidation20180618_593108; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Create a new invalidation. 
  ## 
  let valid = call_593120.validator(path, query, header, formData, body)
  let scheme = call_593120.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593120.url(scheme.get, call_593120.host, call_593120.base,
                         call_593120.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593120, url, valid)

proc call*(call_593121: Call_CreateInvalidation20180618_593108;
          DistributionId: string; body: JsonNode): Recallable =
  ## createInvalidation20180618
  ## Create a new invalidation. 
  ##   DistributionId: string (required)
  ##                 : The distribution's id.
  ##   body: JObject (required)
  var path_593122 = newJObject()
  var body_593123 = newJObject()
  add(path_593122, "DistributionId", newJString(DistributionId))
  if body != nil:
    body_593123 = body
  result = call_593121.call(path_593122, nil, nil, nil, body_593123)

var createInvalidation20180618* = Call_CreateInvalidation20180618_593108(
    name: "createInvalidation20180618", meth: HttpMethod.HttpPost,
    host: "cloudfront.amazonaws.com",
    route: "/2018-06-18/distribution/{DistributionId}/invalidation",
    validator: validate_CreateInvalidation20180618_593109, base: "/",
    url: url_CreateInvalidation20180618_593110,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListInvalidations20180618_593077 = ref object of OpenApiRestCall_592364
proc url_ListInvalidations20180618_593079(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "DistributionId" in path, "`DistributionId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2018-06-18/distribution/"),
               (kind: VariableSegment, value: "DistributionId"),
               (kind: ConstantSegment, value: "/invalidation")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_ListInvalidations20180618_593078(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists invalidation batches. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   DistributionId: JString (required)
  ##                 : The distribution's ID.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `DistributionId` field"
  var valid_593094 = path.getOrDefault("DistributionId")
  valid_593094 = validateParameter(valid_593094, JString, required = true,
                                 default = nil)
  if valid_593094 != nil:
    section.add "DistributionId", valid_593094
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##         : Use this parameter when paginating results to indicate where to begin in your list of invalidation batches. Because the results are returned in decreasing order from most recent to oldest, the most recent results are on the first page, the second page will contain earlier results, and so on. To get the next page of results, set <code>Marker</code> to the value of the <code>NextMarker</code> from the current page's response. This value is the same as the ID of the last invalidation batch on that page. 
  ##   MaxItems: JString
  ##           : The maximum number of invalidation batches that you want in the response body.
  section = newJObject()
  var valid_593095 = query.getOrDefault("Marker")
  valid_593095 = validateParameter(valid_593095, JString, required = false,
                                 default = nil)
  if valid_593095 != nil:
    section.add "Marker", valid_593095
  var valid_593096 = query.getOrDefault("MaxItems")
  valid_593096 = validateParameter(valid_593096, JString, required = false,
                                 default = nil)
  if valid_593096 != nil:
    section.add "MaxItems", valid_593096
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
  var valid_593097 = header.getOrDefault("X-Amz-Signature")
  valid_593097 = validateParameter(valid_593097, JString, required = false,
                                 default = nil)
  if valid_593097 != nil:
    section.add "X-Amz-Signature", valid_593097
  var valid_593098 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593098 = validateParameter(valid_593098, JString, required = false,
                                 default = nil)
  if valid_593098 != nil:
    section.add "X-Amz-Content-Sha256", valid_593098
  var valid_593099 = header.getOrDefault("X-Amz-Date")
  valid_593099 = validateParameter(valid_593099, JString, required = false,
                                 default = nil)
  if valid_593099 != nil:
    section.add "X-Amz-Date", valid_593099
  var valid_593100 = header.getOrDefault("X-Amz-Credential")
  valid_593100 = validateParameter(valid_593100, JString, required = false,
                                 default = nil)
  if valid_593100 != nil:
    section.add "X-Amz-Credential", valid_593100
  var valid_593101 = header.getOrDefault("X-Amz-Security-Token")
  valid_593101 = validateParameter(valid_593101, JString, required = false,
                                 default = nil)
  if valid_593101 != nil:
    section.add "X-Amz-Security-Token", valid_593101
  var valid_593102 = header.getOrDefault("X-Amz-Algorithm")
  valid_593102 = validateParameter(valid_593102, JString, required = false,
                                 default = nil)
  if valid_593102 != nil:
    section.add "X-Amz-Algorithm", valid_593102
  var valid_593103 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593103 = validateParameter(valid_593103, JString, required = false,
                                 default = nil)
  if valid_593103 != nil:
    section.add "X-Amz-SignedHeaders", valid_593103
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593104: Call_ListInvalidations20180618_593077; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists invalidation batches. 
  ## 
  let valid = call_593104.validator(path, query, header, formData, body)
  let scheme = call_593104.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593104.url(scheme.get, call_593104.host, call_593104.base,
                         call_593104.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593104, url, valid)

proc call*(call_593105: Call_ListInvalidations20180618_593077;
          DistributionId: string; Marker: string = ""; MaxItems: string = ""): Recallable =
  ## listInvalidations20180618
  ## Lists invalidation batches. 
  ##   Marker: string
  ##         : Use this parameter when paginating results to indicate where to begin in your list of invalidation batches. Because the results are returned in decreasing order from most recent to oldest, the most recent results are on the first page, the second page will contain earlier results, and so on. To get the next page of results, set <code>Marker</code> to the value of the <code>NextMarker</code> from the current page's response. This value is the same as the ID of the last invalidation batch on that page. 
  ##   MaxItems: string
  ##           : The maximum number of invalidation batches that you want in the response body.
  ##   DistributionId: string (required)
  ##                 : The distribution's ID.
  var path_593106 = newJObject()
  var query_593107 = newJObject()
  add(query_593107, "Marker", newJString(Marker))
  add(query_593107, "MaxItems", newJString(MaxItems))
  add(path_593106, "DistributionId", newJString(DistributionId))
  result = call_593105.call(path_593106, query_593107, nil, nil, nil)

var listInvalidations20180618* = Call_ListInvalidations20180618_593077(
    name: "listInvalidations20180618", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com",
    route: "/2018-06-18/distribution/{DistributionId}/invalidation",
    validator: validate_ListInvalidations20180618_593078, base: "/",
    url: url_ListInvalidations20180618_593079,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePublicKey20180618_593139 = ref object of OpenApiRestCall_592364
proc url_CreatePublicKey20180618_593141(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreatePublicKey20180618_593140(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Add a new public key to CloudFront to use, for example, for field-level encryption. You can add a maximum of 10 public keys with one AWS account.
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
  var valid_593142 = header.getOrDefault("X-Amz-Signature")
  valid_593142 = validateParameter(valid_593142, JString, required = false,
                                 default = nil)
  if valid_593142 != nil:
    section.add "X-Amz-Signature", valid_593142
  var valid_593143 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593143 = validateParameter(valid_593143, JString, required = false,
                                 default = nil)
  if valid_593143 != nil:
    section.add "X-Amz-Content-Sha256", valid_593143
  var valid_593144 = header.getOrDefault("X-Amz-Date")
  valid_593144 = validateParameter(valid_593144, JString, required = false,
                                 default = nil)
  if valid_593144 != nil:
    section.add "X-Amz-Date", valid_593144
  var valid_593145 = header.getOrDefault("X-Amz-Credential")
  valid_593145 = validateParameter(valid_593145, JString, required = false,
                                 default = nil)
  if valid_593145 != nil:
    section.add "X-Amz-Credential", valid_593145
  var valid_593146 = header.getOrDefault("X-Amz-Security-Token")
  valid_593146 = validateParameter(valid_593146, JString, required = false,
                                 default = nil)
  if valid_593146 != nil:
    section.add "X-Amz-Security-Token", valid_593146
  var valid_593147 = header.getOrDefault("X-Amz-Algorithm")
  valid_593147 = validateParameter(valid_593147, JString, required = false,
                                 default = nil)
  if valid_593147 != nil:
    section.add "X-Amz-Algorithm", valid_593147
  var valid_593148 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593148 = validateParameter(valid_593148, JString, required = false,
                                 default = nil)
  if valid_593148 != nil:
    section.add "X-Amz-SignedHeaders", valid_593148
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593150: Call_CreatePublicKey20180618_593139; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Add a new public key to CloudFront to use, for example, for field-level encryption. You can add a maximum of 10 public keys with one AWS account.
  ## 
  let valid = call_593150.validator(path, query, header, formData, body)
  let scheme = call_593150.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593150.url(scheme.get, call_593150.host, call_593150.base,
                         call_593150.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593150, url, valid)

proc call*(call_593151: Call_CreatePublicKey20180618_593139; body: JsonNode): Recallable =
  ## createPublicKey20180618
  ## Add a new public key to CloudFront to use, for example, for field-level encryption. You can add a maximum of 10 public keys with one AWS account.
  ##   body: JObject (required)
  var body_593152 = newJObject()
  if body != nil:
    body_593152 = body
  result = call_593151.call(nil, nil, nil, nil, body_593152)

var createPublicKey20180618* = Call_CreatePublicKey20180618_593139(
    name: "createPublicKey20180618", meth: HttpMethod.HttpPost,
    host: "cloudfront.amazonaws.com", route: "/2018-06-18/public-key",
    validator: validate_CreatePublicKey20180618_593140, base: "/",
    url: url_CreatePublicKey20180618_593141, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPublicKeys20180618_593124 = ref object of OpenApiRestCall_592364
proc url_ListPublicKeys20180618_593126(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListPublicKeys20180618_593125(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## List all public keys that have been added to CloudFront for this account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##         : Use this when paginating results to indicate where to begin in your list of public keys. The results include public keys in the list that occur after the marker. To get the next page of results, set the <code>Marker</code> to the value of the <code>NextMarker</code> from the current page's response (which is also the ID of the last public key on that page). 
  ##   MaxItems: JString
  ##           : The maximum number of public keys you want in the response body. 
  section = newJObject()
  var valid_593127 = query.getOrDefault("Marker")
  valid_593127 = validateParameter(valid_593127, JString, required = false,
                                 default = nil)
  if valid_593127 != nil:
    section.add "Marker", valid_593127
  var valid_593128 = query.getOrDefault("MaxItems")
  valid_593128 = validateParameter(valid_593128, JString, required = false,
                                 default = nil)
  if valid_593128 != nil:
    section.add "MaxItems", valid_593128
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
  var valid_593129 = header.getOrDefault("X-Amz-Signature")
  valid_593129 = validateParameter(valid_593129, JString, required = false,
                                 default = nil)
  if valid_593129 != nil:
    section.add "X-Amz-Signature", valid_593129
  var valid_593130 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593130 = validateParameter(valid_593130, JString, required = false,
                                 default = nil)
  if valid_593130 != nil:
    section.add "X-Amz-Content-Sha256", valid_593130
  var valid_593131 = header.getOrDefault("X-Amz-Date")
  valid_593131 = validateParameter(valid_593131, JString, required = false,
                                 default = nil)
  if valid_593131 != nil:
    section.add "X-Amz-Date", valid_593131
  var valid_593132 = header.getOrDefault("X-Amz-Credential")
  valid_593132 = validateParameter(valid_593132, JString, required = false,
                                 default = nil)
  if valid_593132 != nil:
    section.add "X-Amz-Credential", valid_593132
  var valid_593133 = header.getOrDefault("X-Amz-Security-Token")
  valid_593133 = validateParameter(valid_593133, JString, required = false,
                                 default = nil)
  if valid_593133 != nil:
    section.add "X-Amz-Security-Token", valid_593133
  var valid_593134 = header.getOrDefault("X-Amz-Algorithm")
  valid_593134 = validateParameter(valid_593134, JString, required = false,
                                 default = nil)
  if valid_593134 != nil:
    section.add "X-Amz-Algorithm", valid_593134
  var valid_593135 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593135 = validateParameter(valid_593135, JString, required = false,
                                 default = nil)
  if valid_593135 != nil:
    section.add "X-Amz-SignedHeaders", valid_593135
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593136: Call_ListPublicKeys20180618_593124; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List all public keys that have been added to CloudFront for this account.
  ## 
  let valid = call_593136.validator(path, query, header, formData, body)
  let scheme = call_593136.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593136.url(scheme.get, call_593136.host, call_593136.base,
                         call_593136.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593136, url, valid)

proc call*(call_593137: Call_ListPublicKeys20180618_593124; Marker: string = "";
          MaxItems: string = ""): Recallable =
  ## listPublicKeys20180618
  ## List all public keys that have been added to CloudFront for this account.
  ##   Marker: string
  ##         : Use this when paginating results to indicate where to begin in your list of public keys. The results include public keys in the list that occur after the marker. To get the next page of results, set the <code>Marker</code> to the value of the <code>NextMarker</code> from the current page's response (which is also the ID of the last public key on that page). 
  ##   MaxItems: string
  ##           : The maximum number of public keys you want in the response body. 
  var query_593138 = newJObject()
  add(query_593138, "Marker", newJString(Marker))
  add(query_593138, "MaxItems", newJString(MaxItems))
  result = call_593137.call(nil, query_593138, nil, nil, nil)

var listPublicKeys20180618* = Call_ListPublicKeys20180618_593124(
    name: "listPublicKeys20180618", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com", route: "/2018-06-18/public-key",
    validator: validate_ListPublicKeys20180618_593125, base: "/",
    url: url_ListPublicKeys20180618_593126, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateStreamingDistribution20180618_593168 = ref object of OpenApiRestCall_592364
proc url_CreateStreamingDistribution20180618_593170(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateStreamingDistribution20180618_593169(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates a new RMTP distribution. An RTMP distribution is similar to a web distribution, but an RTMP distribution streams media files using the Adobe Real-Time Messaging Protocol (RTMP) instead of serving files using HTTP. </p> <p>To create a new web distribution, submit a <code>POST</code> request to the <i>CloudFront API version</i>/distribution resource. The request body must include a document with a <i>StreamingDistributionConfig</i> element. The response echoes the <code>StreamingDistributionConfig</code> element and returns other information about the RTMP distribution.</p> <p>To get the status of your request, use the <i>GET StreamingDistribution</i> API action. When the value of <code>Enabled</code> is <code>true</code> and the value of <code>Status</code> is <code>Deployed</code>, your distribution is ready. A distribution usually deploys in less than 15 minutes.</p> <p>For more information about web distributions, see <a href="http://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/distribution-rtmp.html">Working with RTMP Distributions</a> in the <i>Amazon CloudFront Developer Guide</i>.</p> <important> <p>Beginning with the 2012-05-05 version of the CloudFront API, we made substantial changes to the format of the XML document that you include in the request body when you create or update a web distribution or an RTMP distribution, and when you invalidate objects. With previous versions of the API, we discovered that it was too easy to accidentally delete one or more values for an element that accepts multiple values, for example, CNAMEs and trusted signers. Our changes for the 2012-05-05 release are intended to prevent these accidental deletions and to notify you when there's a mismatch between the number of values you say you're specifying in the <code>Quantity</code> element and the number of values specified.</p> </important>
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
  var valid_593171 = header.getOrDefault("X-Amz-Signature")
  valid_593171 = validateParameter(valid_593171, JString, required = false,
                                 default = nil)
  if valid_593171 != nil:
    section.add "X-Amz-Signature", valid_593171
  var valid_593172 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593172 = validateParameter(valid_593172, JString, required = false,
                                 default = nil)
  if valid_593172 != nil:
    section.add "X-Amz-Content-Sha256", valid_593172
  var valid_593173 = header.getOrDefault("X-Amz-Date")
  valid_593173 = validateParameter(valid_593173, JString, required = false,
                                 default = nil)
  if valid_593173 != nil:
    section.add "X-Amz-Date", valid_593173
  var valid_593174 = header.getOrDefault("X-Amz-Credential")
  valid_593174 = validateParameter(valid_593174, JString, required = false,
                                 default = nil)
  if valid_593174 != nil:
    section.add "X-Amz-Credential", valid_593174
  var valid_593175 = header.getOrDefault("X-Amz-Security-Token")
  valid_593175 = validateParameter(valid_593175, JString, required = false,
                                 default = nil)
  if valid_593175 != nil:
    section.add "X-Amz-Security-Token", valid_593175
  var valid_593176 = header.getOrDefault("X-Amz-Algorithm")
  valid_593176 = validateParameter(valid_593176, JString, required = false,
                                 default = nil)
  if valid_593176 != nil:
    section.add "X-Amz-Algorithm", valid_593176
  var valid_593177 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593177 = validateParameter(valid_593177, JString, required = false,
                                 default = nil)
  if valid_593177 != nil:
    section.add "X-Amz-SignedHeaders", valid_593177
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593179: Call_CreateStreamingDistribution20180618_593168;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Creates a new RMTP distribution. An RTMP distribution is similar to a web distribution, but an RTMP distribution streams media files using the Adobe Real-Time Messaging Protocol (RTMP) instead of serving files using HTTP. </p> <p>To create a new web distribution, submit a <code>POST</code> request to the <i>CloudFront API version</i>/distribution resource. The request body must include a document with a <i>StreamingDistributionConfig</i> element. The response echoes the <code>StreamingDistributionConfig</code> element and returns other information about the RTMP distribution.</p> <p>To get the status of your request, use the <i>GET StreamingDistribution</i> API action. When the value of <code>Enabled</code> is <code>true</code> and the value of <code>Status</code> is <code>Deployed</code>, your distribution is ready. A distribution usually deploys in less than 15 minutes.</p> <p>For more information about web distributions, see <a href="http://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/distribution-rtmp.html">Working with RTMP Distributions</a> in the <i>Amazon CloudFront Developer Guide</i>.</p> <important> <p>Beginning with the 2012-05-05 version of the CloudFront API, we made substantial changes to the format of the XML document that you include in the request body when you create or update a web distribution or an RTMP distribution, and when you invalidate objects. With previous versions of the API, we discovered that it was too easy to accidentally delete one or more values for an element that accepts multiple values, for example, CNAMEs and trusted signers. Our changes for the 2012-05-05 release are intended to prevent these accidental deletions and to notify you when there's a mismatch between the number of values you say you're specifying in the <code>Quantity</code> element and the number of values specified.</p> </important>
  ## 
  let valid = call_593179.validator(path, query, header, formData, body)
  let scheme = call_593179.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593179.url(scheme.get, call_593179.host, call_593179.base,
                         call_593179.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593179, url, valid)

proc call*(call_593180: Call_CreateStreamingDistribution20180618_593168;
          body: JsonNode): Recallable =
  ## createStreamingDistribution20180618
  ## <p>Creates a new RMTP distribution. An RTMP distribution is similar to a web distribution, but an RTMP distribution streams media files using the Adobe Real-Time Messaging Protocol (RTMP) instead of serving files using HTTP. </p> <p>To create a new web distribution, submit a <code>POST</code> request to the <i>CloudFront API version</i>/distribution resource. The request body must include a document with a <i>StreamingDistributionConfig</i> element. The response echoes the <code>StreamingDistributionConfig</code> element and returns other information about the RTMP distribution.</p> <p>To get the status of your request, use the <i>GET StreamingDistribution</i> API action. When the value of <code>Enabled</code> is <code>true</code> and the value of <code>Status</code> is <code>Deployed</code>, your distribution is ready. A distribution usually deploys in less than 15 minutes.</p> <p>For more information about web distributions, see <a href="http://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/distribution-rtmp.html">Working with RTMP Distributions</a> in the <i>Amazon CloudFront Developer Guide</i>.</p> <important> <p>Beginning with the 2012-05-05 version of the CloudFront API, we made substantial changes to the format of the XML document that you include in the request body when you create or update a web distribution or an RTMP distribution, and when you invalidate objects. With previous versions of the API, we discovered that it was too easy to accidentally delete one or more values for an element that accepts multiple values, for example, CNAMEs and trusted signers. Our changes for the 2012-05-05 release are intended to prevent these accidental deletions and to notify you when there's a mismatch between the number of values you say you're specifying in the <code>Quantity</code> element and the number of values specified.</p> </important>
  ##   body: JObject (required)
  var body_593181 = newJObject()
  if body != nil:
    body_593181 = body
  result = call_593180.call(nil, nil, nil, nil, body_593181)

var createStreamingDistribution20180618* = Call_CreateStreamingDistribution20180618_593168(
    name: "createStreamingDistribution20180618", meth: HttpMethod.HttpPost,
    host: "cloudfront.amazonaws.com", route: "/2018-06-18/streaming-distribution",
    validator: validate_CreateStreamingDistribution20180618_593169, base: "/",
    url: url_CreateStreamingDistribution20180618_593170,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListStreamingDistributions20180618_593153 = ref object of OpenApiRestCall_592364
proc url_ListStreamingDistributions20180618_593155(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListStreamingDistributions20180618_593154(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## List streaming distributions. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##         : The value that you provided for the <code>Marker</code> request parameter.
  ##   MaxItems: JString
  ##           : The value that you provided for the <code>MaxItems</code> request parameter.
  section = newJObject()
  var valid_593156 = query.getOrDefault("Marker")
  valid_593156 = validateParameter(valid_593156, JString, required = false,
                                 default = nil)
  if valid_593156 != nil:
    section.add "Marker", valid_593156
  var valid_593157 = query.getOrDefault("MaxItems")
  valid_593157 = validateParameter(valid_593157, JString, required = false,
                                 default = nil)
  if valid_593157 != nil:
    section.add "MaxItems", valid_593157
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
  var valid_593158 = header.getOrDefault("X-Amz-Signature")
  valid_593158 = validateParameter(valid_593158, JString, required = false,
                                 default = nil)
  if valid_593158 != nil:
    section.add "X-Amz-Signature", valid_593158
  var valid_593159 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593159 = validateParameter(valid_593159, JString, required = false,
                                 default = nil)
  if valid_593159 != nil:
    section.add "X-Amz-Content-Sha256", valid_593159
  var valid_593160 = header.getOrDefault("X-Amz-Date")
  valid_593160 = validateParameter(valid_593160, JString, required = false,
                                 default = nil)
  if valid_593160 != nil:
    section.add "X-Amz-Date", valid_593160
  var valid_593161 = header.getOrDefault("X-Amz-Credential")
  valid_593161 = validateParameter(valid_593161, JString, required = false,
                                 default = nil)
  if valid_593161 != nil:
    section.add "X-Amz-Credential", valid_593161
  var valid_593162 = header.getOrDefault("X-Amz-Security-Token")
  valid_593162 = validateParameter(valid_593162, JString, required = false,
                                 default = nil)
  if valid_593162 != nil:
    section.add "X-Amz-Security-Token", valid_593162
  var valid_593163 = header.getOrDefault("X-Amz-Algorithm")
  valid_593163 = validateParameter(valid_593163, JString, required = false,
                                 default = nil)
  if valid_593163 != nil:
    section.add "X-Amz-Algorithm", valid_593163
  var valid_593164 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593164 = validateParameter(valid_593164, JString, required = false,
                                 default = nil)
  if valid_593164 != nil:
    section.add "X-Amz-SignedHeaders", valid_593164
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593165: Call_ListStreamingDistributions20180618_593153;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## List streaming distributions. 
  ## 
  let valid = call_593165.validator(path, query, header, formData, body)
  let scheme = call_593165.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593165.url(scheme.get, call_593165.host, call_593165.base,
                         call_593165.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593165, url, valid)

proc call*(call_593166: Call_ListStreamingDistributions20180618_593153;
          Marker: string = ""; MaxItems: string = ""): Recallable =
  ## listStreamingDistributions20180618
  ## List streaming distributions. 
  ##   Marker: string
  ##         : The value that you provided for the <code>Marker</code> request parameter.
  ##   MaxItems: string
  ##           : The value that you provided for the <code>MaxItems</code> request parameter.
  var query_593167 = newJObject()
  add(query_593167, "Marker", newJString(Marker))
  add(query_593167, "MaxItems", newJString(MaxItems))
  result = call_593166.call(nil, query_593167, nil, nil, nil)

var listStreamingDistributions20180618* = Call_ListStreamingDistributions20180618_593153(
    name: "listStreamingDistributions20180618", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com", route: "/2018-06-18/streaming-distribution",
    validator: validate_ListStreamingDistributions20180618_593154, base: "/",
    url: url_ListStreamingDistributions20180618_593155,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateStreamingDistributionWithTags20180618_593182 = ref object of OpenApiRestCall_592364
proc url_CreateStreamingDistributionWithTags20180618_593184(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateStreamingDistributionWithTags20180618_593183(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Create a new streaming distribution with tags.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   WithTags: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `WithTags` field"
  var valid_593185 = query.getOrDefault("WithTags")
  valid_593185 = validateParameter(valid_593185, JBool, required = true, default = nil)
  if valid_593185 != nil:
    section.add "WithTags", valid_593185
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
  var valid_593186 = header.getOrDefault("X-Amz-Signature")
  valid_593186 = validateParameter(valid_593186, JString, required = false,
                                 default = nil)
  if valid_593186 != nil:
    section.add "X-Amz-Signature", valid_593186
  var valid_593187 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593187 = validateParameter(valid_593187, JString, required = false,
                                 default = nil)
  if valid_593187 != nil:
    section.add "X-Amz-Content-Sha256", valid_593187
  var valid_593188 = header.getOrDefault("X-Amz-Date")
  valid_593188 = validateParameter(valid_593188, JString, required = false,
                                 default = nil)
  if valid_593188 != nil:
    section.add "X-Amz-Date", valid_593188
  var valid_593189 = header.getOrDefault("X-Amz-Credential")
  valid_593189 = validateParameter(valid_593189, JString, required = false,
                                 default = nil)
  if valid_593189 != nil:
    section.add "X-Amz-Credential", valid_593189
  var valid_593190 = header.getOrDefault("X-Amz-Security-Token")
  valid_593190 = validateParameter(valid_593190, JString, required = false,
                                 default = nil)
  if valid_593190 != nil:
    section.add "X-Amz-Security-Token", valid_593190
  var valid_593191 = header.getOrDefault("X-Amz-Algorithm")
  valid_593191 = validateParameter(valid_593191, JString, required = false,
                                 default = nil)
  if valid_593191 != nil:
    section.add "X-Amz-Algorithm", valid_593191
  var valid_593192 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593192 = validateParameter(valid_593192, JString, required = false,
                                 default = nil)
  if valid_593192 != nil:
    section.add "X-Amz-SignedHeaders", valid_593192
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593194: Call_CreateStreamingDistributionWithTags20180618_593182;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Create a new streaming distribution with tags.
  ## 
  let valid = call_593194.validator(path, query, header, formData, body)
  let scheme = call_593194.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593194.url(scheme.get, call_593194.host, call_593194.base,
                         call_593194.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593194, url, valid)

proc call*(call_593195: Call_CreateStreamingDistributionWithTags20180618_593182;
          body: JsonNode; WithTags: bool): Recallable =
  ## createStreamingDistributionWithTags20180618
  ## Create a new streaming distribution with tags.
  ##   body: JObject (required)
  ##   WithTags: bool (required)
  var query_593196 = newJObject()
  var body_593197 = newJObject()
  if body != nil:
    body_593197 = body
  add(query_593196, "WithTags", newJBool(WithTags))
  result = call_593195.call(nil, query_593196, nil, nil, body_593197)

var createStreamingDistributionWithTags20180618* = Call_CreateStreamingDistributionWithTags20180618_593182(
    name: "createStreamingDistributionWithTags20180618",
    meth: HttpMethod.HttpPost, host: "cloudfront.amazonaws.com",
    route: "/2018-06-18/streaming-distribution#WithTags",
    validator: validate_CreateStreamingDistributionWithTags20180618_593183,
    base: "/", url: url_CreateStreamingDistributionWithTags20180618_593184,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCloudFrontOriginAccessIdentity20180618_593198 = ref object of OpenApiRestCall_592364
proc url_GetCloudFrontOriginAccessIdentity20180618_593200(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                value: "/2018-06-18/origin-access-identity/cloudfront/"),
               (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_GetCloudFrontOriginAccessIdentity20180618_593199(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Get the information about an origin access identity. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The identity's ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_593201 = path.getOrDefault("Id")
  valid_593201 = validateParameter(valid_593201, JString, required = true,
                                 default = nil)
  if valid_593201 != nil:
    section.add "Id", valid_593201
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
  var valid_593202 = header.getOrDefault("X-Amz-Signature")
  valid_593202 = validateParameter(valid_593202, JString, required = false,
                                 default = nil)
  if valid_593202 != nil:
    section.add "X-Amz-Signature", valid_593202
  var valid_593203 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593203 = validateParameter(valid_593203, JString, required = false,
                                 default = nil)
  if valid_593203 != nil:
    section.add "X-Amz-Content-Sha256", valid_593203
  var valid_593204 = header.getOrDefault("X-Amz-Date")
  valid_593204 = validateParameter(valid_593204, JString, required = false,
                                 default = nil)
  if valid_593204 != nil:
    section.add "X-Amz-Date", valid_593204
  var valid_593205 = header.getOrDefault("X-Amz-Credential")
  valid_593205 = validateParameter(valid_593205, JString, required = false,
                                 default = nil)
  if valid_593205 != nil:
    section.add "X-Amz-Credential", valid_593205
  var valid_593206 = header.getOrDefault("X-Amz-Security-Token")
  valid_593206 = validateParameter(valid_593206, JString, required = false,
                                 default = nil)
  if valid_593206 != nil:
    section.add "X-Amz-Security-Token", valid_593206
  var valid_593207 = header.getOrDefault("X-Amz-Algorithm")
  valid_593207 = validateParameter(valid_593207, JString, required = false,
                                 default = nil)
  if valid_593207 != nil:
    section.add "X-Amz-Algorithm", valid_593207
  var valid_593208 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593208 = validateParameter(valid_593208, JString, required = false,
                                 default = nil)
  if valid_593208 != nil:
    section.add "X-Amz-SignedHeaders", valid_593208
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593209: Call_GetCloudFrontOriginAccessIdentity20180618_593198;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Get the information about an origin access identity. 
  ## 
  let valid = call_593209.validator(path, query, header, formData, body)
  let scheme = call_593209.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593209.url(scheme.get, call_593209.host, call_593209.base,
                         call_593209.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593209, url, valid)

proc call*(call_593210: Call_GetCloudFrontOriginAccessIdentity20180618_593198;
          Id: string): Recallable =
  ## getCloudFrontOriginAccessIdentity20180618
  ## Get the information about an origin access identity. 
  ##   Id: string (required)
  ##     : The identity's ID.
  var path_593211 = newJObject()
  add(path_593211, "Id", newJString(Id))
  result = call_593210.call(path_593211, nil, nil, nil, nil)

var getCloudFrontOriginAccessIdentity20180618* = Call_GetCloudFrontOriginAccessIdentity20180618_593198(
    name: "getCloudFrontOriginAccessIdentity20180618", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com",
    route: "/2018-06-18/origin-access-identity/cloudfront/{Id}",
    validator: validate_GetCloudFrontOriginAccessIdentity20180618_593199,
    base: "/", url: url_GetCloudFrontOriginAccessIdentity20180618_593200,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteCloudFrontOriginAccessIdentity20180618_593212 = ref object of OpenApiRestCall_592364
proc url_DeleteCloudFrontOriginAccessIdentity20180618_593214(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                value: "/2018-06-18/origin-access-identity/cloudfront/"),
               (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_DeleteCloudFrontOriginAccessIdentity20180618_593213(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Delete an origin access identity. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The origin access identity's ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_593215 = path.getOrDefault("Id")
  valid_593215 = validateParameter(valid_593215, JString, required = true,
                                 default = nil)
  if valid_593215 != nil:
    section.add "Id", valid_593215
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   If-Match: JString
  ##           : The value of the <code>ETag</code> header you received from a previous <code>GET</code> or <code>PUT</code> request. For example: <code>E2QWRUHAPOMQZL</code>.
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593216 = header.getOrDefault("X-Amz-Signature")
  valid_593216 = validateParameter(valid_593216, JString, required = false,
                                 default = nil)
  if valid_593216 != nil:
    section.add "X-Amz-Signature", valid_593216
  var valid_593217 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593217 = validateParameter(valid_593217, JString, required = false,
                                 default = nil)
  if valid_593217 != nil:
    section.add "X-Amz-Content-Sha256", valid_593217
  var valid_593218 = header.getOrDefault("X-Amz-Date")
  valid_593218 = validateParameter(valid_593218, JString, required = false,
                                 default = nil)
  if valid_593218 != nil:
    section.add "X-Amz-Date", valid_593218
  var valid_593219 = header.getOrDefault("X-Amz-Credential")
  valid_593219 = validateParameter(valid_593219, JString, required = false,
                                 default = nil)
  if valid_593219 != nil:
    section.add "X-Amz-Credential", valid_593219
  var valid_593220 = header.getOrDefault("X-Amz-Security-Token")
  valid_593220 = validateParameter(valid_593220, JString, required = false,
                                 default = nil)
  if valid_593220 != nil:
    section.add "X-Amz-Security-Token", valid_593220
  var valid_593221 = header.getOrDefault("If-Match")
  valid_593221 = validateParameter(valid_593221, JString, required = false,
                                 default = nil)
  if valid_593221 != nil:
    section.add "If-Match", valid_593221
  var valid_593222 = header.getOrDefault("X-Amz-Algorithm")
  valid_593222 = validateParameter(valid_593222, JString, required = false,
                                 default = nil)
  if valid_593222 != nil:
    section.add "X-Amz-Algorithm", valid_593222
  var valid_593223 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593223 = validateParameter(valid_593223, JString, required = false,
                                 default = nil)
  if valid_593223 != nil:
    section.add "X-Amz-SignedHeaders", valid_593223
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593224: Call_DeleteCloudFrontOriginAccessIdentity20180618_593212;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Delete an origin access identity. 
  ## 
  let valid = call_593224.validator(path, query, header, formData, body)
  let scheme = call_593224.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593224.url(scheme.get, call_593224.host, call_593224.base,
                         call_593224.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593224, url, valid)

proc call*(call_593225: Call_DeleteCloudFrontOriginAccessIdentity20180618_593212;
          Id: string): Recallable =
  ## deleteCloudFrontOriginAccessIdentity20180618
  ## Delete an origin access identity. 
  ##   Id: string (required)
  ##     : The origin access identity's ID.
  var path_593226 = newJObject()
  add(path_593226, "Id", newJString(Id))
  result = call_593225.call(path_593226, nil, nil, nil, nil)

var deleteCloudFrontOriginAccessIdentity20180618* = Call_DeleteCloudFrontOriginAccessIdentity20180618_593212(
    name: "deleteCloudFrontOriginAccessIdentity20180618",
    meth: HttpMethod.HttpDelete, host: "cloudfront.amazonaws.com",
    route: "/2018-06-18/origin-access-identity/cloudfront/{Id}",
    validator: validate_DeleteCloudFrontOriginAccessIdentity20180618_593213,
    base: "/", url: url_DeleteCloudFrontOriginAccessIdentity20180618_593214,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDistribution20180618_593227 = ref object of OpenApiRestCall_592364
proc url_GetDistribution20180618_593229(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2018-06-18/distribution/"),
               (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_GetDistribution20180618_593228(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Get the information about a distribution. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The distribution's ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_593230 = path.getOrDefault("Id")
  valid_593230 = validateParameter(valid_593230, JString, required = true,
                                 default = nil)
  if valid_593230 != nil:
    section.add "Id", valid_593230
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
  var valid_593231 = header.getOrDefault("X-Amz-Signature")
  valid_593231 = validateParameter(valid_593231, JString, required = false,
                                 default = nil)
  if valid_593231 != nil:
    section.add "X-Amz-Signature", valid_593231
  var valid_593232 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593232 = validateParameter(valid_593232, JString, required = false,
                                 default = nil)
  if valid_593232 != nil:
    section.add "X-Amz-Content-Sha256", valid_593232
  var valid_593233 = header.getOrDefault("X-Amz-Date")
  valid_593233 = validateParameter(valid_593233, JString, required = false,
                                 default = nil)
  if valid_593233 != nil:
    section.add "X-Amz-Date", valid_593233
  var valid_593234 = header.getOrDefault("X-Amz-Credential")
  valid_593234 = validateParameter(valid_593234, JString, required = false,
                                 default = nil)
  if valid_593234 != nil:
    section.add "X-Amz-Credential", valid_593234
  var valid_593235 = header.getOrDefault("X-Amz-Security-Token")
  valid_593235 = validateParameter(valid_593235, JString, required = false,
                                 default = nil)
  if valid_593235 != nil:
    section.add "X-Amz-Security-Token", valid_593235
  var valid_593236 = header.getOrDefault("X-Amz-Algorithm")
  valid_593236 = validateParameter(valid_593236, JString, required = false,
                                 default = nil)
  if valid_593236 != nil:
    section.add "X-Amz-Algorithm", valid_593236
  var valid_593237 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593237 = validateParameter(valid_593237, JString, required = false,
                                 default = nil)
  if valid_593237 != nil:
    section.add "X-Amz-SignedHeaders", valid_593237
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593238: Call_GetDistribution20180618_593227; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Get the information about a distribution. 
  ## 
  let valid = call_593238.validator(path, query, header, formData, body)
  let scheme = call_593238.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593238.url(scheme.get, call_593238.host, call_593238.base,
                         call_593238.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593238, url, valid)

proc call*(call_593239: Call_GetDistribution20180618_593227; Id: string): Recallable =
  ## getDistribution20180618
  ## Get the information about a distribution. 
  ##   Id: string (required)
  ##     : The distribution's ID.
  var path_593240 = newJObject()
  add(path_593240, "Id", newJString(Id))
  result = call_593239.call(path_593240, nil, nil, nil, nil)

var getDistribution20180618* = Call_GetDistribution20180618_593227(
    name: "getDistribution20180618", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com", route: "/2018-06-18/distribution/{Id}",
    validator: validate_GetDistribution20180618_593228, base: "/",
    url: url_GetDistribution20180618_593229, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDistribution20180618_593241 = ref object of OpenApiRestCall_592364
proc url_DeleteDistribution20180618_593243(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2018-06-18/distribution/"),
               (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_DeleteDistribution20180618_593242(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Delete a distribution. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The distribution ID. 
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_593244 = path.getOrDefault("Id")
  valid_593244 = validateParameter(valid_593244, JString, required = true,
                                 default = nil)
  if valid_593244 != nil:
    section.add "Id", valid_593244
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   If-Match: JString
  ##           : The value of the <code>ETag</code> header that you received when you disabled the distribution. For example: <code>E2QWRUHAPOMQZL</code>. 
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593245 = header.getOrDefault("X-Amz-Signature")
  valid_593245 = validateParameter(valid_593245, JString, required = false,
                                 default = nil)
  if valid_593245 != nil:
    section.add "X-Amz-Signature", valid_593245
  var valid_593246 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593246 = validateParameter(valid_593246, JString, required = false,
                                 default = nil)
  if valid_593246 != nil:
    section.add "X-Amz-Content-Sha256", valid_593246
  var valid_593247 = header.getOrDefault("X-Amz-Date")
  valid_593247 = validateParameter(valid_593247, JString, required = false,
                                 default = nil)
  if valid_593247 != nil:
    section.add "X-Amz-Date", valid_593247
  var valid_593248 = header.getOrDefault("X-Amz-Credential")
  valid_593248 = validateParameter(valid_593248, JString, required = false,
                                 default = nil)
  if valid_593248 != nil:
    section.add "X-Amz-Credential", valid_593248
  var valid_593249 = header.getOrDefault("X-Amz-Security-Token")
  valid_593249 = validateParameter(valid_593249, JString, required = false,
                                 default = nil)
  if valid_593249 != nil:
    section.add "X-Amz-Security-Token", valid_593249
  var valid_593250 = header.getOrDefault("If-Match")
  valid_593250 = validateParameter(valid_593250, JString, required = false,
                                 default = nil)
  if valid_593250 != nil:
    section.add "If-Match", valid_593250
  var valid_593251 = header.getOrDefault("X-Amz-Algorithm")
  valid_593251 = validateParameter(valid_593251, JString, required = false,
                                 default = nil)
  if valid_593251 != nil:
    section.add "X-Amz-Algorithm", valid_593251
  var valid_593252 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593252 = validateParameter(valid_593252, JString, required = false,
                                 default = nil)
  if valid_593252 != nil:
    section.add "X-Amz-SignedHeaders", valid_593252
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593253: Call_DeleteDistribution20180618_593241; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Delete a distribution. 
  ## 
  let valid = call_593253.validator(path, query, header, formData, body)
  let scheme = call_593253.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593253.url(scheme.get, call_593253.host, call_593253.base,
                         call_593253.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593253, url, valid)

proc call*(call_593254: Call_DeleteDistribution20180618_593241; Id: string): Recallable =
  ## deleteDistribution20180618
  ## Delete a distribution. 
  ##   Id: string (required)
  ##     : The distribution ID. 
  var path_593255 = newJObject()
  add(path_593255, "Id", newJString(Id))
  result = call_593254.call(path_593255, nil, nil, nil, nil)

var deleteDistribution20180618* = Call_DeleteDistribution20180618_593241(
    name: "deleteDistribution20180618", meth: HttpMethod.HttpDelete,
    host: "cloudfront.amazonaws.com", route: "/2018-06-18/distribution/{Id}",
    validator: validate_DeleteDistribution20180618_593242, base: "/",
    url: url_DeleteDistribution20180618_593243,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFieldLevelEncryption20180618_593256 = ref object of OpenApiRestCall_592364
proc url_GetFieldLevelEncryption20180618_593258(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                value: "/2018-06-18/field-level-encryption/"),
               (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_GetFieldLevelEncryption20180618_593257(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Get the field-level encryption configuration information.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : Request the ID for the field-level encryption configuration information.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_593259 = path.getOrDefault("Id")
  valid_593259 = validateParameter(valid_593259, JString, required = true,
                                 default = nil)
  if valid_593259 != nil:
    section.add "Id", valid_593259
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
  var valid_593260 = header.getOrDefault("X-Amz-Signature")
  valid_593260 = validateParameter(valid_593260, JString, required = false,
                                 default = nil)
  if valid_593260 != nil:
    section.add "X-Amz-Signature", valid_593260
  var valid_593261 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593261 = validateParameter(valid_593261, JString, required = false,
                                 default = nil)
  if valid_593261 != nil:
    section.add "X-Amz-Content-Sha256", valid_593261
  var valid_593262 = header.getOrDefault("X-Amz-Date")
  valid_593262 = validateParameter(valid_593262, JString, required = false,
                                 default = nil)
  if valid_593262 != nil:
    section.add "X-Amz-Date", valid_593262
  var valid_593263 = header.getOrDefault("X-Amz-Credential")
  valid_593263 = validateParameter(valid_593263, JString, required = false,
                                 default = nil)
  if valid_593263 != nil:
    section.add "X-Amz-Credential", valid_593263
  var valid_593264 = header.getOrDefault("X-Amz-Security-Token")
  valid_593264 = validateParameter(valid_593264, JString, required = false,
                                 default = nil)
  if valid_593264 != nil:
    section.add "X-Amz-Security-Token", valid_593264
  var valid_593265 = header.getOrDefault("X-Amz-Algorithm")
  valid_593265 = validateParameter(valid_593265, JString, required = false,
                                 default = nil)
  if valid_593265 != nil:
    section.add "X-Amz-Algorithm", valid_593265
  var valid_593266 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593266 = validateParameter(valid_593266, JString, required = false,
                                 default = nil)
  if valid_593266 != nil:
    section.add "X-Amz-SignedHeaders", valid_593266
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593267: Call_GetFieldLevelEncryption20180618_593256;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Get the field-level encryption configuration information.
  ## 
  let valid = call_593267.validator(path, query, header, formData, body)
  let scheme = call_593267.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593267.url(scheme.get, call_593267.host, call_593267.base,
                         call_593267.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593267, url, valid)

proc call*(call_593268: Call_GetFieldLevelEncryption20180618_593256; Id: string): Recallable =
  ## getFieldLevelEncryption20180618
  ## Get the field-level encryption configuration information.
  ##   Id: string (required)
  ##     : Request the ID for the field-level encryption configuration information.
  var path_593269 = newJObject()
  add(path_593269, "Id", newJString(Id))
  result = call_593268.call(path_593269, nil, nil, nil, nil)

var getFieldLevelEncryption20180618* = Call_GetFieldLevelEncryption20180618_593256(
    name: "getFieldLevelEncryption20180618", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com",
    route: "/2018-06-18/field-level-encryption/{Id}",
    validator: validate_GetFieldLevelEncryption20180618_593257, base: "/",
    url: url_GetFieldLevelEncryption20180618_593258,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteFieldLevelEncryptionConfig20180618_593270 = ref object of OpenApiRestCall_592364
proc url_DeleteFieldLevelEncryptionConfig20180618_593272(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                value: "/2018-06-18/field-level-encryption/"),
               (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_DeleteFieldLevelEncryptionConfig20180618_593271(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Remove a field-level encryption configuration.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The ID of the configuration you want to delete from CloudFront.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_593273 = path.getOrDefault("Id")
  valid_593273 = validateParameter(valid_593273, JString, required = true,
                                 default = nil)
  if valid_593273 != nil:
    section.add "Id", valid_593273
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   If-Match: JString
  ##           : The value of the <code>ETag</code> header that you received when retrieving the configuration identity to delete. For example: <code>E2QWRUHAPOMQZL</code>.
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593274 = header.getOrDefault("X-Amz-Signature")
  valid_593274 = validateParameter(valid_593274, JString, required = false,
                                 default = nil)
  if valid_593274 != nil:
    section.add "X-Amz-Signature", valid_593274
  var valid_593275 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593275 = validateParameter(valid_593275, JString, required = false,
                                 default = nil)
  if valid_593275 != nil:
    section.add "X-Amz-Content-Sha256", valid_593275
  var valid_593276 = header.getOrDefault("X-Amz-Date")
  valid_593276 = validateParameter(valid_593276, JString, required = false,
                                 default = nil)
  if valid_593276 != nil:
    section.add "X-Amz-Date", valid_593276
  var valid_593277 = header.getOrDefault("X-Amz-Credential")
  valid_593277 = validateParameter(valid_593277, JString, required = false,
                                 default = nil)
  if valid_593277 != nil:
    section.add "X-Amz-Credential", valid_593277
  var valid_593278 = header.getOrDefault("X-Amz-Security-Token")
  valid_593278 = validateParameter(valid_593278, JString, required = false,
                                 default = nil)
  if valid_593278 != nil:
    section.add "X-Amz-Security-Token", valid_593278
  var valid_593279 = header.getOrDefault("If-Match")
  valid_593279 = validateParameter(valid_593279, JString, required = false,
                                 default = nil)
  if valid_593279 != nil:
    section.add "If-Match", valid_593279
  var valid_593280 = header.getOrDefault("X-Amz-Algorithm")
  valid_593280 = validateParameter(valid_593280, JString, required = false,
                                 default = nil)
  if valid_593280 != nil:
    section.add "X-Amz-Algorithm", valid_593280
  var valid_593281 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593281 = validateParameter(valid_593281, JString, required = false,
                                 default = nil)
  if valid_593281 != nil:
    section.add "X-Amz-SignedHeaders", valid_593281
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593282: Call_DeleteFieldLevelEncryptionConfig20180618_593270;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Remove a field-level encryption configuration.
  ## 
  let valid = call_593282.validator(path, query, header, formData, body)
  let scheme = call_593282.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593282.url(scheme.get, call_593282.host, call_593282.base,
                         call_593282.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593282, url, valid)

proc call*(call_593283: Call_DeleteFieldLevelEncryptionConfig20180618_593270;
          Id: string): Recallable =
  ## deleteFieldLevelEncryptionConfig20180618
  ## Remove a field-level encryption configuration.
  ##   Id: string (required)
  ##     : The ID of the configuration you want to delete from CloudFront.
  var path_593284 = newJObject()
  add(path_593284, "Id", newJString(Id))
  result = call_593283.call(path_593284, nil, nil, nil, nil)

var deleteFieldLevelEncryptionConfig20180618* = Call_DeleteFieldLevelEncryptionConfig20180618_593270(
    name: "deleteFieldLevelEncryptionConfig20180618", meth: HttpMethod.HttpDelete,
    host: "cloudfront.amazonaws.com",
    route: "/2018-06-18/field-level-encryption/{Id}",
    validator: validate_DeleteFieldLevelEncryptionConfig20180618_593271,
    base: "/", url: url_DeleteFieldLevelEncryptionConfig20180618_593272,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFieldLevelEncryptionProfile20180618_593285 = ref object of OpenApiRestCall_592364
proc url_GetFieldLevelEncryptionProfile20180618_593287(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                value: "/2018-06-18/field-level-encryption-profile/"),
               (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_GetFieldLevelEncryptionProfile20180618_593286(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Get the field-level encryption profile information.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : Get the ID for the field-level encryption profile information.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_593288 = path.getOrDefault("Id")
  valid_593288 = validateParameter(valid_593288, JString, required = true,
                                 default = nil)
  if valid_593288 != nil:
    section.add "Id", valid_593288
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
  var valid_593289 = header.getOrDefault("X-Amz-Signature")
  valid_593289 = validateParameter(valid_593289, JString, required = false,
                                 default = nil)
  if valid_593289 != nil:
    section.add "X-Amz-Signature", valid_593289
  var valid_593290 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593290 = validateParameter(valid_593290, JString, required = false,
                                 default = nil)
  if valid_593290 != nil:
    section.add "X-Amz-Content-Sha256", valid_593290
  var valid_593291 = header.getOrDefault("X-Amz-Date")
  valid_593291 = validateParameter(valid_593291, JString, required = false,
                                 default = nil)
  if valid_593291 != nil:
    section.add "X-Amz-Date", valid_593291
  var valid_593292 = header.getOrDefault("X-Amz-Credential")
  valid_593292 = validateParameter(valid_593292, JString, required = false,
                                 default = nil)
  if valid_593292 != nil:
    section.add "X-Amz-Credential", valid_593292
  var valid_593293 = header.getOrDefault("X-Amz-Security-Token")
  valid_593293 = validateParameter(valid_593293, JString, required = false,
                                 default = nil)
  if valid_593293 != nil:
    section.add "X-Amz-Security-Token", valid_593293
  var valid_593294 = header.getOrDefault("X-Amz-Algorithm")
  valid_593294 = validateParameter(valid_593294, JString, required = false,
                                 default = nil)
  if valid_593294 != nil:
    section.add "X-Amz-Algorithm", valid_593294
  var valid_593295 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593295 = validateParameter(valid_593295, JString, required = false,
                                 default = nil)
  if valid_593295 != nil:
    section.add "X-Amz-SignedHeaders", valid_593295
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593296: Call_GetFieldLevelEncryptionProfile20180618_593285;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Get the field-level encryption profile information.
  ## 
  let valid = call_593296.validator(path, query, header, formData, body)
  let scheme = call_593296.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593296.url(scheme.get, call_593296.host, call_593296.base,
                         call_593296.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593296, url, valid)

proc call*(call_593297: Call_GetFieldLevelEncryptionProfile20180618_593285;
          Id: string): Recallable =
  ## getFieldLevelEncryptionProfile20180618
  ## Get the field-level encryption profile information.
  ##   Id: string (required)
  ##     : Get the ID for the field-level encryption profile information.
  var path_593298 = newJObject()
  add(path_593298, "Id", newJString(Id))
  result = call_593297.call(path_593298, nil, nil, nil, nil)

var getFieldLevelEncryptionProfile20180618* = Call_GetFieldLevelEncryptionProfile20180618_593285(
    name: "getFieldLevelEncryptionProfile20180618", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com",
    route: "/2018-06-18/field-level-encryption-profile/{Id}",
    validator: validate_GetFieldLevelEncryptionProfile20180618_593286, base: "/",
    url: url_GetFieldLevelEncryptionProfile20180618_593287,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteFieldLevelEncryptionProfile20180618_593299 = ref object of OpenApiRestCall_592364
proc url_DeleteFieldLevelEncryptionProfile20180618_593301(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                value: "/2018-06-18/field-level-encryption-profile/"),
               (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_DeleteFieldLevelEncryptionProfile20180618_593300(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Remove a field-level encryption profile.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : Request the ID of the profile you want to delete from CloudFront.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_593302 = path.getOrDefault("Id")
  valid_593302 = validateParameter(valid_593302, JString, required = true,
                                 default = nil)
  if valid_593302 != nil:
    section.add "Id", valid_593302
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   If-Match: JString
  ##           : The value of the <code>ETag</code> header that you received when retrieving the profile to delete. For example: <code>E2QWRUHAPOMQZL</code>.
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593303 = header.getOrDefault("X-Amz-Signature")
  valid_593303 = validateParameter(valid_593303, JString, required = false,
                                 default = nil)
  if valid_593303 != nil:
    section.add "X-Amz-Signature", valid_593303
  var valid_593304 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593304 = validateParameter(valid_593304, JString, required = false,
                                 default = nil)
  if valid_593304 != nil:
    section.add "X-Amz-Content-Sha256", valid_593304
  var valid_593305 = header.getOrDefault("X-Amz-Date")
  valid_593305 = validateParameter(valid_593305, JString, required = false,
                                 default = nil)
  if valid_593305 != nil:
    section.add "X-Amz-Date", valid_593305
  var valid_593306 = header.getOrDefault("X-Amz-Credential")
  valid_593306 = validateParameter(valid_593306, JString, required = false,
                                 default = nil)
  if valid_593306 != nil:
    section.add "X-Amz-Credential", valid_593306
  var valid_593307 = header.getOrDefault("X-Amz-Security-Token")
  valid_593307 = validateParameter(valid_593307, JString, required = false,
                                 default = nil)
  if valid_593307 != nil:
    section.add "X-Amz-Security-Token", valid_593307
  var valid_593308 = header.getOrDefault("If-Match")
  valid_593308 = validateParameter(valid_593308, JString, required = false,
                                 default = nil)
  if valid_593308 != nil:
    section.add "If-Match", valid_593308
  var valid_593309 = header.getOrDefault("X-Amz-Algorithm")
  valid_593309 = validateParameter(valid_593309, JString, required = false,
                                 default = nil)
  if valid_593309 != nil:
    section.add "X-Amz-Algorithm", valid_593309
  var valid_593310 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593310 = validateParameter(valid_593310, JString, required = false,
                                 default = nil)
  if valid_593310 != nil:
    section.add "X-Amz-SignedHeaders", valid_593310
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593311: Call_DeleteFieldLevelEncryptionProfile20180618_593299;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Remove a field-level encryption profile.
  ## 
  let valid = call_593311.validator(path, query, header, formData, body)
  let scheme = call_593311.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593311.url(scheme.get, call_593311.host, call_593311.base,
                         call_593311.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593311, url, valid)

proc call*(call_593312: Call_DeleteFieldLevelEncryptionProfile20180618_593299;
          Id: string): Recallable =
  ## deleteFieldLevelEncryptionProfile20180618
  ## Remove a field-level encryption profile.
  ##   Id: string (required)
  ##     : Request the ID of the profile you want to delete from CloudFront.
  var path_593313 = newJObject()
  add(path_593313, "Id", newJString(Id))
  result = call_593312.call(path_593313, nil, nil, nil, nil)

var deleteFieldLevelEncryptionProfile20180618* = Call_DeleteFieldLevelEncryptionProfile20180618_593299(
    name: "deleteFieldLevelEncryptionProfile20180618",
    meth: HttpMethod.HttpDelete, host: "cloudfront.amazonaws.com",
    route: "/2018-06-18/field-level-encryption-profile/{Id}",
    validator: validate_DeleteFieldLevelEncryptionProfile20180618_593300,
    base: "/", url: url_DeleteFieldLevelEncryptionProfile20180618_593301,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPublicKey20180618_593314 = ref object of OpenApiRestCall_592364
proc url_GetPublicKey20180618_593316(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2018-06-18/public-key/"),
               (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_GetPublicKey20180618_593315(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Get the public key information.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : Request the ID for the public key.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_593317 = path.getOrDefault("Id")
  valid_593317 = validateParameter(valid_593317, JString, required = true,
                                 default = nil)
  if valid_593317 != nil:
    section.add "Id", valid_593317
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
  var valid_593318 = header.getOrDefault("X-Amz-Signature")
  valid_593318 = validateParameter(valid_593318, JString, required = false,
                                 default = nil)
  if valid_593318 != nil:
    section.add "X-Amz-Signature", valid_593318
  var valid_593319 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593319 = validateParameter(valid_593319, JString, required = false,
                                 default = nil)
  if valid_593319 != nil:
    section.add "X-Amz-Content-Sha256", valid_593319
  var valid_593320 = header.getOrDefault("X-Amz-Date")
  valid_593320 = validateParameter(valid_593320, JString, required = false,
                                 default = nil)
  if valid_593320 != nil:
    section.add "X-Amz-Date", valid_593320
  var valid_593321 = header.getOrDefault("X-Amz-Credential")
  valid_593321 = validateParameter(valid_593321, JString, required = false,
                                 default = nil)
  if valid_593321 != nil:
    section.add "X-Amz-Credential", valid_593321
  var valid_593322 = header.getOrDefault("X-Amz-Security-Token")
  valid_593322 = validateParameter(valid_593322, JString, required = false,
                                 default = nil)
  if valid_593322 != nil:
    section.add "X-Amz-Security-Token", valid_593322
  var valid_593323 = header.getOrDefault("X-Amz-Algorithm")
  valid_593323 = validateParameter(valid_593323, JString, required = false,
                                 default = nil)
  if valid_593323 != nil:
    section.add "X-Amz-Algorithm", valid_593323
  var valid_593324 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593324 = validateParameter(valid_593324, JString, required = false,
                                 default = nil)
  if valid_593324 != nil:
    section.add "X-Amz-SignedHeaders", valid_593324
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593325: Call_GetPublicKey20180618_593314; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Get the public key information.
  ## 
  let valid = call_593325.validator(path, query, header, formData, body)
  let scheme = call_593325.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593325.url(scheme.get, call_593325.host, call_593325.base,
                         call_593325.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593325, url, valid)

proc call*(call_593326: Call_GetPublicKey20180618_593314; Id: string): Recallable =
  ## getPublicKey20180618
  ## Get the public key information.
  ##   Id: string (required)
  ##     : Request the ID for the public key.
  var path_593327 = newJObject()
  add(path_593327, "Id", newJString(Id))
  result = call_593326.call(path_593327, nil, nil, nil, nil)

var getPublicKey20180618* = Call_GetPublicKey20180618_593314(
    name: "getPublicKey20180618", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com", route: "/2018-06-18/public-key/{Id}",
    validator: validate_GetPublicKey20180618_593315, base: "/",
    url: url_GetPublicKey20180618_593316, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeletePublicKey20180618_593328 = ref object of OpenApiRestCall_592364
proc url_DeletePublicKey20180618_593330(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2018-06-18/public-key/"),
               (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_DeletePublicKey20180618_593329(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Remove a public key you previously added to CloudFront.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The ID of the public key you want to remove from CloudFront.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_593331 = path.getOrDefault("Id")
  valid_593331 = validateParameter(valid_593331, JString, required = true,
                                 default = nil)
  if valid_593331 != nil:
    section.add "Id", valid_593331
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   If-Match: JString
  ##           : The value of the <code>ETag</code> header that you received when retrieving the public key identity to delete. For example: <code>E2QWRUHAPOMQZL</code>.
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593332 = header.getOrDefault("X-Amz-Signature")
  valid_593332 = validateParameter(valid_593332, JString, required = false,
                                 default = nil)
  if valid_593332 != nil:
    section.add "X-Amz-Signature", valid_593332
  var valid_593333 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593333 = validateParameter(valid_593333, JString, required = false,
                                 default = nil)
  if valid_593333 != nil:
    section.add "X-Amz-Content-Sha256", valid_593333
  var valid_593334 = header.getOrDefault("X-Amz-Date")
  valid_593334 = validateParameter(valid_593334, JString, required = false,
                                 default = nil)
  if valid_593334 != nil:
    section.add "X-Amz-Date", valid_593334
  var valid_593335 = header.getOrDefault("X-Amz-Credential")
  valid_593335 = validateParameter(valid_593335, JString, required = false,
                                 default = nil)
  if valid_593335 != nil:
    section.add "X-Amz-Credential", valid_593335
  var valid_593336 = header.getOrDefault("X-Amz-Security-Token")
  valid_593336 = validateParameter(valid_593336, JString, required = false,
                                 default = nil)
  if valid_593336 != nil:
    section.add "X-Amz-Security-Token", valid_593336
  var valid_593337 = header.getOrDefault("If-Match")
  valid_593337 = validateParameter(valid_593337, JString, required = false,
                                 default = nil)
  if valid_593337 != nil:
    section.add "If-Match", valid_593337
  var valid_593338 = header.getOrDefault("X-Amz-Algorithm")
  valid_593338 = validateParameter(valid_593338, JString, required = false,
                                 default = nil)
  if valid_593338 != nil:
    section.add "X-Amz-Algorithm", valid_593338
  var valid_593339 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593339 = validateParameter(valid_593339, JString, required = false,
                                 default = nil)
  if valid_593339 != nil:
    section.add "X-Amz-SignedHeaders", valid_593339
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593340: Call_DeletePublicKey20180618_593328; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Remove a public key you previously added to CloudFront.
  ## 
  let valid = call_593340.validator(path, query, header, formData, body)
  let scheme = call_593340.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593340.url(scheme.get, call_593340.host, call_593340.base,
                         call_593340.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593340, url, valid)

proc call*(call_593341: Call_DeletePublicKey20180618_593328; Id: string): Recallable =
  ## deletePublicKey20180618
  ## Remove a public key you previously added to CloudFront.
  ##   Id: string (required)
  ##     : The ID of the public key you want to remove from CloudFront.
  var path_593342 = newJObject()
  add(path_593342, "Id", newJString(Id))
  result = call_593341.call(path_593342, nil, nil, nil, nil)

var deletePublicKey20180618* = Call_DeletePublicKey20180618_593328(
    name: "deletePublicKey20180618", meth: HttpMethod.HttpDelete,
    host: "cloudfront.amazonaws.com", route: "/2018-06-18/public-key/{Id}",
    validator: validate_DeletePublicKey20180618_593329, base: "/",
    url: url_DeletePublicKey20180618_593330, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetStreamingDistribution20180618_593343 = ref object of OpenApiRestCall_592364
proc url_GetStreamingDistribution20180618_593345(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                value: "/2018-06-18/streaming-distribution/"),
               (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_GetStreamingDistribution20180618_593344(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets information about a specified RTMP distribution, including the distribution configuration.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The streaming distribution's ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_593346 = path.getOrDefault("Id")
  valid_593346 = validateParameter(valid_593346, JString, required = true,
                                 default = nil)
  if valid_593346 != nil:
    section.add "Id", valid_593346
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
  var valid_593347 = header.getOrDefault("X-Amz-Signature")
  valid_593347 = validateParameter(valid_593347, JString, required = false,
                                 default = nil)
  if valid_593347 != nil:
    section.add "X-Amz-Signature", valid_593347
  var valid_593348 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593348 = validateParameter(valid_593348, JString, required = false,
                                 default = nil)
  if valid_593348 != nil:
    section.add "X-Amz-Content-Sha256", valid_593348
  var valid_593349 = header.getOrDefault("X-Amz-Date")
  valid_593349 = validateParameter(valid_593349, JString, required = false,
                                 default = nil)
  if valid_593349 != nil:
    section.add "X-Amz-Date", valid_593349
  var valid_593350 = header.getOrDefault("X-Amz-Credential")
  valid_593350 = validateParameter(valid_593350, JString, required = false,
                                 default = nil)
  if valid_593350 != nil:
    section.add "X-Amz-Credential", valid_593350
  var valid_593351 = header.getOrDefault("X-Amz-Security-Token")
  valid_593351 = validateParameter(valid_593351, JString, required = false,
                                 default = nil)
  if valid_593351 != nil:
    section.add "X-Amz-Security-Token", valid_593351
  var valid_593352 = header.getOrDefault("X-Amz-Algorithm")
  valid_593352 = validateParameter(valid_593352, JString, required = false,
                                 default = nil)
  if valid_593352 != nil:
    section.add "X-Amz-Algorithm", valid_593352
  var valid_593353 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593353 = validateParameter(valid_593353, JString, required = false,
                                 default = nil)
  if valid_593353 != nil:
    section.add "X-Amz-SignedHeaders", valid_593353
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593354: Call_GetStreamingDistribution20180618_593343;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Gets information about a specified RTMP distribution, including the distribution configuration.
  ## 
  let valid = call_593354.validator(path, query, header, formData, body)
  let scheme = call_593354.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593354.url(scheme.get, call_593354.host, call_593354.base,
                         call_593354.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593354, url, valid)

proc call*(call_593355: Call_GetStreamingDistribution20180618_593343; Id: string): Recallable =
  ## getStreamingDistribution20180618
  ## Gets information about a specified RTMP distribution, including the distribution configuration.
  ##   Id: string (required)
  ##     : The streaming distribution's ID.
  var path_593356 = newJObject()
  add(path_593356, "Id", newJString(Id))
  result = call_593355.call(path_593356, nil, nil, nil, nil)

var getStreamingDistribution20180618* = Call_GetStreamingDistribution20180618_593343(
    name: "getStreamingDistribution20180618", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com",
    route: "/2018-06-18/streaming-distribution/{Id}",
    validator: validate_GetStreamingDistribution20180618_593344, base: "/",
    url: url_GetStreamingDistribution20180618_593345,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteStreamingDistribution20180618_593357 = ref object of OpenApiRestCall_592364
proc url_DeleteStreamingDistribution20180618_593359(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                value: "/2018-06-18/streaming-distribution/"),
               (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_DeleteStreamingDistribution20180618_593358(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Delete a streaming distribution. To delete an RTMP distribution using the CloudFront API, perform the following steps.</p> <p> <b>To delete an RTMP distribution using the CloudFront API</b>:</p> <ol> <li> <p>Disable the RTMP distribution.</p> </li> <li> <p>Submit a <code>GET Streaming Distribution Config</code> request to get the current configuration and the <code>Etag</code> header for the distribution. </p> </li> <li> <p>Update the XML document that was returned in the response to your <code>GET Streaming Distribution Config</code> request to change the value of <code>Enabled</code> to <code>false</code>.</p> </li> <li> <p>Submit a <code>PUT Streaming Distribution Config</code> request to update the configuration for your distribution. In the request body, include the XML document that you updated in Step 3. Then set the value of the HTTP <code>If-Match</code> header to the value of the <code>ETag</code> header that CloudFront returned when you submitted the <code>GET Streaming Distribution Config</code> request in Step 2.</p> </li> <li> <p>Review the response to the <code>PUT Streaming Distribution Config</code> request to confirm that the distribution was successfully disabled.</p> </li> <li> <p>Submit a <code>GET Streaming Distribution Config</code> request to confirm that your changes have propagated. When propagation is complete, the value of <code>Status</code> is <code>Deployed</code>.</p> </li> <li> <p>Submit a <code>DELETE Streaming Distribution</code> request. Set the value of the HTTP <code>If-Match</code> header to the value of the <code>ETag</code> header that CloudFront returned when you submitted the <code>GET Streaming Distribution Config</code> request in Step 2.</p> </li> <li> <p>Review the response to your <code>DELETE Streaming Distribution</code> request to confirm that the distribution was successfully deleted.</p> </li> </ol> <p>For information about deleting a distribution using the CloudFront console, see <a href="http://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/HowToDeleteDistribution.html">Deleting a Distribution</a> in the <i>Amazon CloudFront Developer Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The distribution ID. 
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_593360 = path.getOrDefault("Id")
  valid_593360 = validateParameter(valid_593360, JString, required = true,
                                 default = nil)
  if valid_593360 != nil:
    section.add "Id", valid_593360
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   If-Match: JString
  ##           : The value of the <code>ETag</code> header that you received when you disabled the streaming distribution. For example: <code>E2QWRUHAPOMQZL</code>.
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593361 = header.getOrDefault("X-Amz-Signature")
  valid_593361 = validateParameter(valid_593361, JString, required = false,
                                 default = nil)
  if valid_593361 != nil:
    section.add "X-Amz-Signature", valid_593361
  var valid_593362 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593362 = validateParameter(valid_593362, JString, required = false,
                                 default = nil)
  if valid_593362 != nil:
    section.add "X-Amz-Content-Sha256", valid_593362
  var valid_593363 = header.getOrDefault("X-Amz-Date")
  valid_593363 = validateParameter(valid_593363, JString, required = false,
                                 default = nil)
  if valid_593363 != nil:
    section.add "X-Amz-Date", valid_593363
  var valid_593364 = header.getOrDefault("X-Amz-Credential")
  valid_593364 = validateParameter(valid_593364, JString, required = false,
                                 default = nil)
  if valid_593364 != nil:
    section.add "X-Amz-Credential", valid_593364
  var valid_593365 = header.getOrDefault("X-Amz-Security-Token")
  valid_593365 = validateParameter(valid_593365, JString, required = false,
                                 default = nil)
  if valid_593365 != nil:
    section.add "X-Amz-Security-Token", valid_593365
  var valid_593366 = header.getOrDefault("If-Match")
  valid_593366 = validateParameter(valid_593366, JString, required = false,
                                 default = nil)
  if valid_593366 != nil:
    section.add "If-Match", valid_593366
  var valid_593367 = header.getOrDefault("X-Amz-Algorithm")
  valid_593367 = validateParameter(valid_593367, JString, required = false,
                                 default = nil)
  if valid_593367 != nil:
    section.add "X-Amz-Algorithm", valid_593367
  var valid_593368 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593368 = validateParameter(valid_593368, JString, required = false,
                                 default = nil)
  if valid_593368 != nil:
    section.add "X-Amz-SignedHeaders", valid_593368
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593369: Call_DeleteStreamingDistribution20180618_593357;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Delete a streaming distribution. To delete an RTMP distribution using the CloudFront API, perform the following steps.</p> <p> <b>To delete an RTMP distribution using the CloudFront API</b>:</p> <ol> <li> <p>Disable the RTMP distribution.</p> </li> <li> <p>Submit a <code>GET Streaming Distribution Config</code> request to get the current configuration and the <code>Etag</code> header for the distribution. </p> </li> <li> <p>Update the XML document that was returned in the response to your <code>GET Streaming Distribution Config</code> request to change the value of <code>Enabled</code> to <code>false</code>.</p> </li> <li> <p>Submit a <code>PUT Streaming Distribution Config</code> request to update the configuration for your distribution. In the request body, include the XML document that you updated in Step 3. Then set the value of the HTTP <code>If-Match</code> header to the value of the <code>ETag</code> header that CloudFront returned when you submitted the <code>GET Streaming Distribution Config</code> request in Step 2.</p> </li> <li> <p>Review the response to the <code>PUT Streaming Distribution Config</code> request to confirm that the distribution was successfully disabled.</p> </li> <li> <p>Submit a <code>GET Streaming Distribution Config</code> request to confirm that your changes have propagated. When propagation is complete, the value of <code>Status</code> is <code>Deployed</code>.</p> </li> <li> <p>Submit a <code>DELETE Streaming Distribution</code> request. Set the value of the HTTP <code>If-Match</code> header to the value of the <code>ETag</code> header that CloudFront returned when you submitted the <code>GET Streaming Distribution Config</code> request in Step 2.</p> </li> <li> <p>Review the response to your <code>DELETE Streaming Distribution</code> request to confirm that the distribution was successfully deleted.</p> </li> </ol> <p>For information about deleting a distribution using the CloudFront console, see <a href="http://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/HowToDeleteDistribution.html">Deleting a Distribution</a> in the <i>Amazon CloudFront Developer Guide</i>.</p>
  ## 
  let valid = call_593369.validator(path, query, header, formData, body)
  let scheme = call_593369.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593369.url(scheme.get, call_593369.host, call_593369.base,
                         call_593369.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593369, url, valid)

proc call*(call_593370: Call_DeleteStreamingDistribution20180618_593357; Id: string): Recallable =
  ## deleteStreamingDistribution20180618
  ## <p>Delete a streaming distribution. To delete an RTMP distribution using the CloudFront API, perform the following steps.</p> <p> <b>To delete an RTMP distribution using the CloudFront API</b>:</p> <ol> <li> <p>Disable the RTMP distribution.</p> </li> <li> <p>Submit a <code>GET Streaming Distribution Config</code> request to get the current configuration and the <code>Etag</code> header for the distribution. </p> </li> <li> <p>Update the XML document that was returned in the response to your <code>GET Streaming Distribution Config</code> request to change the value of <code>Enabled</code> to <code>false</code>.</p> </li> <li> <p>Submit a <code>PUT Streaming Distribution Config</code> request to update the configuration for your distribution. In the request body, include the XML document that you updated in Step 3. Then set the value of the HTTP <code>If-Match</code> header to the value of the <code>ETag</code> header that CloudFront returned when you submitted the <code>GET Streaming Distribution Config</code> request in Step 2.</p> </li> <li> <p>Review the response to the <code>PUT Streaming Distribution Config</code> request to confirm that the distribution was successfully disabled.</p> </li> <li> <p>Submit a <code>GET Streaming Distribution Config</code> request to confirm that your changes have propagated. When propagation is complete, the value of <code>Status</code> is <code>Deployed</code>.</p> </li> <li> <p>Submit a <code>DELETE Streaming Distribution</code> request. Set the value of the HTTP <code>If-Match</code> header to the value of the <code>ETag</code> header that CloudFront returned when you submitted the <code>GET Streaming Distribution Config</code> request in Step 2.</p> </li> <li> <p>Review the response to your <code>DELETE Streaming Distribution</code> request to confirm that the distribution was successfully deleted.</p> </li> </ol> <p>For information about deleting a distribution using the CloudFront console, see <a href="http://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/HowToDeleteDistribution.html">Deleting a Distribution</a> in the <i>Amazon CloudFront Developer Guide</i>.</p>
  ##   Id: string (required)
  ##     : The distribution ID. 
  var path_593371 = newJObject()
  add(path_593371, "Id", newJString(Id))
  result = call_593370.call(path_593371, nil, nil, nil, nil)

var deleteStreamingDistribution20180618* = Call_DeleteStreamingDistribution20180618_593357(
    name: "deleteStreamingDistribution20180618", meth: HttpMethod.HttpDelete,
    host: "cloudfront.amazonaws.com",
    route: "/2018-06-18/streaming-distribution/{Id}",
    validator: validate_DeleteStreamingDistribution20180618_593358, base: "/",
    url: url_DeleteStreamingDistribution20180618_593359,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateCloudFrontOriginAccessIdentity20180618_593386 = ref object of OpenApiRestCall_592364
proc url_UpdateCloudFrontOriginAccessIdentity20180618_593388(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                value: "/2018-06-18/origin-access-identity/cloudfront/"),
               (kind: VariableSegment, value: "Id"),
               (kind: ConstantSegment, value: "/config")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_UpdateCloudFrontOriginAccessIdentity20180618_593387(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Update an origin access identity. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The identity's id.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_593389 = path.getOrDefault("Id")
  valid_593389 = validateParameter(valid_593389, JString, required = true,
                                 default = nil)
  if valid_593389 != nil:
    section.add "Id", valid_593389
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   If-Match: JString
  ##           : The value of the <code>ETag</code> header that you received when retrieving the identity's configuration. For example: <code>E2QWRUHAPOMQZL</code>.
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593390 = header.getOrDefault("X-Amz-Signature")
  valid_593390 = validateParameter(valid_593390, JString, required = false,
                                 default = nil)
  if valid_593390 != nil:
    section.add "X-Amz-Signature", valid_593390
  var valid_593391 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593391 = validateParameter(valid_593391, JString, required = false,
                                 default = nil)
  if valid_593391 != nil:
    section.add "X-Amz-Content-Sha256", valid_593391
  var valid_593392 = header.getOrDefault("X-Amz-Date")
  valid_593392 = validateParameter(valid_593392, JString, required = false,
                                 default = nil)
  if valid_593392 != nil:
    section.add "X-Amz-Date", valid_593392
  var valid_593393 = header.getOrDefault("X-Amz-Credential")
  valid_593393 = validateParameter(valid_593393, JString, required = false,
                                 default = nil)
  if valid_593393 != nil:
    section.add "X-Amz-Credential", valid_593393
  var valid_593394 = header.getOrDefault("X-Amz-Security-Token")
  valid_593394 = validateParameter(valid_593394, JString, required = false,
                                 default = nil)
  if valid_593394 != nil:
    section.add "X-Amz-Security-Token", valid_593394
  var valid_593395 = header.getOrDefault("If-Match")
  valid_593395 = validateParameter(valid_593395, JString, required = false,
                                 default = nil)
  if valid_593395 != nil:
    section.add "If-Match", valid_593395
  var valid_593396 = header.getOrDefault("X-Amz-Algorithm")
  valid_593396 = validateParameter(valid_593396, JString, required = false,
                                 default = nil)
  if valid_593396 != nil:
    section.add "X-Amz-Algorithm", valid_593396
  var valid_593397 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593397 = validateParameter(valid_593397, JString, required = false,
                                 default = nil)
  if valid_593397 != nil:
    section.add "X-Amz-SignedHeaders", valid_593397
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593399: Call_UpdateCloudFrontOriginAccessIdentity20180618_593386;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Update an origin access identity. 
  ## 
  let valid = call_593399.validator(path, query, header, formData, body)
  let scheme = call_593399.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593399.url(scheme.get, call_593399.host, call_593399.base,
                         call_593399.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593399, url, valid)

proc call*(call_593400: Call_UpdateCloudFrontOriginAccessIdentity20180618_593386;
          body: JsonNode; Id: string): Recallable =
  ## updateCloudFrontOriginAccessIdentity20180618
  ## Update an origin access identity. 
  ##   body: JObject (required)
  ##   Id: string (required)
  ##     : The identity's id.
  var path_593401 = newJObject()
  var body_593402 = newJObject()
  if body != nil:
    body_593402 = body
  add(path_593401, "Id", newJString(Id))
  result = call_593400.call(path_593401, nil, nil, nil, body_593402)

var updateCloudFrontOriginAccessIdentity20180618* = Call_UpdateCloudFrontOriginAccessIdentity20180618_593386(
    name: "updateCloudFrontOriginAccessIdentity20180618",
    meth: HttpMethod.HttpPut, host: "cloudfront.amazonaws.com",
    route: "/2018-06-18/origin-access-identity/cloudfront/{Id}/config",
    validator: validate_UpdateCloudFrontOriginAccessIdentity20180618_593387,
    base: "/", url: url_UpdateCloudFrontOriginAccessIdentity20180618_593388,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCloudFrontOriginAccessIdentityConfig20180618_593372 = ref object of OpenApiRestCall_592364
proc url_GetCloudFrontOriginAccessIdentityConfig20180618_593374(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                value: "/2018-06-18/origin-access-identity/cloudfront/"),
               (kind: VariableSegment, value: "Id"),
               (kind: ConstantSegment, value: "/config")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_GetCloudFrontOriginAccessIdentityConfig20180618_593373(
    path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
    body: JsonNode): JsonNode =
  ## Get the configuration information about an origin access identity. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The identity's ID. 
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_593375 = path.getOrDefault("Id")
  valid_593375 = validateParameter(valid_593375, JString, required = true,
                                 default = nil)
  if valid_593375 != nil:
    section.add "Id", valid_593375
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
  var valid_593376 = header.getOrDefault("X-Amz-Signature")
  valid_593376 = validateParameter(valid_593376, JString, required = false,
                                 default = nil)
  if valid_593376 != nil:
    section.add "X-Amz-Signature", valid_593376
  var valid_593377 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593377 = validateParameter(valid_593377, JString, required = false,
                                 default = nil)
  if valid_593377 != nil:
    section.add "X-Amz-Content-Sha256", valid_593377
  var valid_593378 = header.getOrDefault("X-Amz-Date")
  valid_593378 = validateParameter(valid_593378, JString, required = false,
                                 default = nil)
  if valid_593378 != nil:
    section.add "X-Amz-Date", valid_593378
  var valid_593379 = header.getOrDefault("X-Amz-Credential")
  valid_593379 = validateParameter(valid_593379, JString, required = false,
                                 default = nil)
  if valid_593379 != nil:
    section.add "X-Amz-Credential", valid_593379
  var valid_593380 = header.getOrDefault("X-Amz-Security-Token")
  valid_593380 = validateParameter(valid_593380, JString, required = false,
                                 default = nil)
  if valid_593380 != nil:
    section.add "X-Amz-Security-Token", valid_593380
  var valid_593381 = header.getOrDefault("X-Amz-Algorithm")
  valid_593381 = validateParameter(valid_593381, JString, required = false,
                                 default = nil)
  if valid_593381 != nil:
    section.add "X-Amz-Algorithm", valid_593381
  var valid_593382 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593382 = validateParameter(valid_593382, JString, required = false,
                                 default = nil)
  if valid_593382 != nil:
    section.add "X-Amz-SignedHeaders", valid_593382
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593383: Call_GetCloudFrontOriginAccessIdentityConfig20180618_593372;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Get the configuration information about an origin access identity. 
  ## 
  let valid = call_593383.validator(path, query, header, formData, body)
  let scheme = call_593383.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593383.url(scheme.get, call_593383.host, call_593383.base,
                         call_593383.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593383, url, valid)

proc call*(call_593384: Call_GetCloudFrontOriginAccessIdentityConfig20180618_593372;
          Id: string): Recallable =
  ## getCloudFrontOriginAccessIdentityConfig20180618
  ## Get the configuration information about an origin access identity. 
  ##   Id: string (required)
  ##     : The identity's ID. 
  var path_593385 = newJObject()
  add(path_593385, "Id", newJString(Id))
  result = call_593384.call(path_593385, nil, nil, nil, nil)

var getCloudFrontOriginAccessIdentityConfig20180618* = Call_GetCloudFrontOriginAccessIdentityConfig20180618_593372(
    name: "getCloudFrontOriginAccessIdentityConfig20180618",
    meth: HttpMethod.HttpGet, host: "cloudfront.amazonaws.com",
    route: "/2018-06-18/origin-access-identity/cloudfront/{Id}/config",
    validator: validate_GetCloudFrontOriginAccessIdentityConfig20180618_593373,
    base: "/", url: url_GetCloudFrontOriginAccessIdentityConfig20180618_593374,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDistribution20180618_593417 = ref object of OpenApiRestCall_592364
proc url_UpdateDistribution20180618_593419(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2018-06-18/distribution/"),
               (kind: VariableSegment, value: "Id"),
               (kind: ConstantSegment, value: "/config")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_UpdateDistribution20180618_593418(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Updates the configuration for a web distribution. </p> <important> <p>When you update a distribution, there are more required fields than when you create a distribution. When you update your distribution by using this API action, follow the steps here to get the current configuration and then make your updates, to make sure that you include all of the required fields. To view a summary, see <a href="http://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/distribution-overview-required-fields.html">Required Fields for Create Distribution and Update Distribution</a> in the <i>Amazon CloudFront Developer Guide</i>.</p> </important> <p>The update process includes getting the current distribution configuration, updating the XML document that is returned to make your changes, and then submitting an <code>UpdateDistribution</code> request to make the updates.</p> <p>For information about updating a distribution using the CloudFront console instead, see <a href="http://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/distribution-web-creating-console.html">Creating a Distribution</a> in the <i>Amazon CloudFront Developer Guide</i>.</p> <p> <b>To update a web distribution using the CloudFront API</b> </p> <ol> <li> <p>Submit a <a>GetDistributionConfig</a> request to get the current configuration and an <code>Etag</code> header for the distribution.</p> <note> <p>If you update the distribution again, you must get a new <code>Etag</code> header.</p> </note> </li> <li> <p>Update the XML document that was returned in the response to your <code>GetDistributionConfig</code> request to include your changes. </p> <important> <p>When you edit the XML file, be aware of the following:</p> <ul> <li> <p>You must strip out the ETag parameter that is returned.</p> </li> <li> <p>Additional fields are required when you update a distribution. There may be fields included in the XML file for features that you haven't configured for your distribution. This is expected and required to successfully update the distribution.</p> </li> <li> <p>You can't change the value of <code>CallerReference</code>. If you try to change this value, CloudFront returns an <code>IllegalUpdate</code> error. </p> </li> <li> <p>The new configuration replaces the existing configuration; the values that you specify in an <code>UpdateDistribution</code> request are not merged into your existing configuration. When you add, delete, or replace values in an element that allows multiple values (for example, <code>CNAME</code>), you must specify all of the values that you want to appear in the updated distribution. In addition, you must update the corresponding <code>Quantity</code> element.</p> </li> </ul> </important> </li> <li> <p>Submit an <code>UpdateDistribution</code> request to update the configuration for your distribution:</p> <ul> <li> <p>In the request body, include the XML document that you updated in Step 2. The request body must include an XML document with a <code>DistributionConfig</code> element.</p> </li> <li> <p>Set the value of the HTTP <code>If-Match</code> header to the value of the <code>ETag</code> header that CloudFront returned when you submitted the <code>GetDistributionConfig</code> request in Step 1.</p> </li> </ul> </li> <li> <p>Review the response to the <code>UpdateDistribution</code> request to confirm that the configuration was successfully updated.</p> </li> <li> <p>Optional: Submit a <a>GetDistribution</a> request to confirm that your changes have propagated. When propagation is complete, the value of <code>Status</code> is <code>Deployed</code>.</p> </li> </ol>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The distribution's id.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_593420 = path.getOrDefault("Id")
  valid_593420 = validateParameter(valid_593420, JString, required = true,
                                 default = nil)
  if valid_593420 != nil:
    section.add "Id", valid_593420
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   If-Match: JString
  ##           : The value of the <code>ETag</code> header that you received when retrieving the distribution's configuration. For example: <code>E2QWRUHAPOMQZL</code>.
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593421 = header.getOrDefault("X-Amz-Signature")
  valid_593421 = validateParameter(valid_593421, JString, required = false,
                                 default = nil)
  if valid_593421 != nil:
    section.add "X-Amz-Signature", valid_593421
  var valid_593422 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593422 = validateParameter(valid_593422, JString, required = false,
                                 default = nil)
  if valid_593422 != nil:
    section.add "X-Amz-Content-Sha256", valid_593422
  var valid_593423 = header.getOrDefault("X-Amz-Date")
  valid_593423 = validateParameter(valid_593423, JString, required = false,
                                 default = nil)
  if valid_593423 != nil:
    section.add "X-Amz-Date", valid_593423
  var valid_593424 = header.getOrDefault("X-Amz-Credential")
  valid_593424 = validateParameter(valid_593424, JString, required = false,
                                 default = nil)
  if valid_593424 != nil:
    section.add "X-Amz-Credential", valid_593424
  var valid_593425 = header.getOrDefault("X-Amz-Security-Token")
  valid_593425 = validateParameter(valid_593425, JString, required = false,
                                 default = nil)
  if valid_593425 != nil:
    section.add "X-Amz-Security-Token", valid_593425
  var valid_593426 = header.getOrDefault("If-Match")
  valid_593426 = validateParameter(valid_593426, JString, required = false,
                                 default = nil)
  if valid_593426 != nil:
    section.add "If-Match", valid_593426
  var valid_593427 = header.getOrDefault("X-Amz-Algorithm")
  valid_593427 = validateParameter(valid_593427, JString, required = false,
                                 default = nil)
  if valid_593427 != nil:
    section.add "X-Amz-Algorithm", valid_593427
  var valid_593428 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593428 = validateParameter(valid_593428, JString, required = false,
                                 default = nil)
  if valid_593428 != nil:
    section.add "X-Amz-SignedHeaders", valid_593428
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593430: Call_UpdateDistribution20180618_593417; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the configuration for a web distribution. </p> <important> <p>When you update a distribution, there are more required fields than when you create a distribution. When you update your distribution by using this API action, follow the steps here to get the current configuration and then make your updates, to make sure that you include all of the required fields. To view a summary, see <a href="http://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/distribution-overview-required-fields.html">Required Fields for Create Distribution and Update Distribution</a> in the <i>Amazon CloudFront Developer Guide</i>.</p> </important> <p>The update process includes getting the current distribution configuration, updating the XML document that is returned to make your changes, and then submitting an <code>UpdateDistribution</code> request to make the updates.</p> <p>For information about updating a distribution using the CloudFront console instead, see <a href="http://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/distribution-web-creating-console.html">Creating a Distribution</a> in the <i>Amazon CloudFront Developer Guide</i>.</p> <p> <b>To update a web distribution using the CloudFront API</b> </p> <ol> <li> <p>Submit a <a>GetDistributionConfig</a> request to get the current configuration and an <code>Etag</code> header for the distribution.</p> <note> <p>If you update the distribution again, you must get a new <code>Etag</code> header.</p> </note> </li> <li> <p>Update the XML document that was returned in the response to your <code>GetDistributionConfig</code> request to include your changes. </p> <important> <p>When you edit the XML file, be aware of the following:</p> <ul> <li> <p>You must strip out the ETag parameter that is returned.</p> </li> <li> <p>Additional fields are required when you update a distribution. There may be fields included in the XML file for features that you haven't configured for your distribution. This is expected and required to successfully update the distribution.</p> </li> <li> <p>You can't change the value of <code>CallerReference</code>. If you try to change this value, CloudFront returns an <code>IllegalUpdate</code> error. </p> </li> <li> <p>The new configuration replaces the existing configuration; the values that you specify in an <code>UpdateDistribution</code> request are not merged into your existing configuration. When you add, delete, or replace values in an element that allows multiple values (for example, <code>CNAME</code>), you must specify all of the values that you want to appear in the updated distribution. In addition, you must update the corresponding <code>Quantity</code> element.</p> </li> </ul> </important> </li> <li> <p>Submit an <code>UpdateDistribution</code> request to update the configuration for your distribution:</p> <ul> <li> <p>In the request body, include the XML document that you updated in Step 2. The request body must include an XML document with a <code>DistributionConfig</code> element.</p> </li> <li> <p>Set the value of the HTTP <code>If-Match</code> header to the value of the <code>ETag</code> header that CloudFront returned when you submitted the <code>GetDistributionConfig</code> request in Step 1.</p> </li> </ul> </li> <li> <p>Review the response to the <code>UpdateDistribution</code> request to confirm that the configuration was successfully updated.</p> </li> <li> <p>Optional: Submit a <a>GetDistribution</a> request to confirm that your changes have propagated. When propagation is complete, the value of <code>Status</code> is <code>Deployed</code>.</p> </li> </ol>
  ## 
  let valid = call_593430.validator(path, query, header, formData, body)
  let scheme = call_593430.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593430.url(scheme.get, call_593430.host, call_593430.base,
                         call_593430.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593430, url, valid)

proc call*(call_593431: Call_UpdateDistribution20180618_593417; body: JsonNode;
          Id: string): Recallable =
  ## updateDistribution20180618
  ## <p>Updates the configuration for a web distribution. </p> <important> <p>When you update a distribution, there are more required fields than when you create a distribution. When you update your distribution by using this API action, follow the steps here to get the current configuration and then make your updates, to make sure that you include all of the required fields. To view a summary, see <a href="http://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/distribution-overview-required-fields.html">Required Fields for Create Distribution and Update Distribution</a> in the <i>Amazon CloudFront Developer Guide</i>.</p> </important> <p>The update process includes getting the current distribution configuration, updating the XML document that is returned to make your changes, and then submitting an <code>UpdateDistribution</code> request to make the updates.</p> <p>For information about updating a distribution using the CloudFront console instead, see <a href="http://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/distribution-web-creating-console.html">Creating a Distribution</a> in the <i>Amazon CloudFront Developer Guide</i>.</p> <p> <b>To update a web distribution using the CloudFront API</b> </p> <ol> <li> <p>Submit a <a>GetDistributionConfig</a> request to get the current configuration and an <code>Etag</code> header for the distribution.</p> <note> <p>If you update the distribution again, you must get a new <code>Etag</code> header.</p> </note> </li> <li> <p>Update the XML document that was returned in the response to your <code>GetDistributionConfig</code> request to include your changes. </p> <important> <p>When you edit the XML file, be aware of the following:</p> <ul> <li> <p>You must strip out the ETag parameter that is returned.</p> </li> <li> <p>Additional fields are required when you update a distribution. There may be fields included in the XML file for features that you haven't configured for your distribution. This is expected and required to successfully update the distribution.</p> </li> <li> <p>You can't change the value of <code>CallerReference</code>. If you try to change this value, CloudFront returns an <code>IllegalUpdate</code> error. </p> </li> <li> <p>The new configuration replaces the existing configuration; the values that you specify in an <code>UpdateDistribution</code> request are not merged into your existing configuration. When you add, delete, or replace values in an element that allows multiple values (for example, <code>CNAME</code>), you must specify all of the values that you want to appear in the updated distribution. In addition, you must update the corresponding <code>Quantity</code> element.</p> </li> </ul> </important> </li> <li> <p>Submit an <code>UpdateDistribution</code> request to update the configuration for your distribution:</p> <ul> <li> <p>In the request body, include the XML document that you updated in Step 2. The request body must include an XML document with a <code>DistributionConfig</code> element.</p> </li> <li> <p>Set the value of the HTTP <code>If-Match</code> header to the value of the <code>ETag</code> header that CloudFront returned when you submitted the <code>GetDistributionConfig</code> request in Step 1.</p> </li> </ul> </li> <li> <p>Review the response to the <code>UpdateDistribution</code> request to confirm that the configuration was successfully updated.</p> </li> <li> <p>Optional: Submit a <a>GetDistribution</a> request to confirm that your changes have propagated. When propagation is complete, the value of <code>Status</code> is <code>Deployed</code>.</p> </li> </ol>
  ##   body: JObject (required)
  ##   Id: string (required)
  ##     : The distribution's id.
  var path_593432 = newJObject()
  var body_593433 = newJObject()
  if body != nil:
    body_593433 = body
  add(path_593432, "Id", newJString(Id))
  result = call_593431.call(path_593432, nil, nil, nil, body_593433)

var updateDistribution20180618* = Call_UpdateDistribution20180618_593417(
    name: "updateDistribution20180618", meth: HttpMethod.HttpPut,
    host: "cloudfront.amazonaws.com",
    route: "/2018-06-18/distribution/{Id}/config",
    validator: validate_UpdateDistribution20180618_593418, base: "/",
    url: url_UpdateDistribution20180618_593419,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDistributionConfig20180618_593403 = ref object of OpenApiRestCall_592364
proc url_GetDistributionConfig20180618_593405(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2018-06-18/distribution/"),
               (kind: VariableSegment, value: "Id"),
               (kind: ConstantSegment, value: "/config")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_GetDistributionConfig20180618_593404(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Get the configuration information about a distribution. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The distribution's ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_593406 = path.getOrDefault("Id")
  valid_593406 = validateParameter(valid_593406, JString, required = true,
                                 default = nil)
  if valid_593406 != nil:
    section.add "Id", valid_593406
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
  var valid_593407 = header.getOrDefault("X-Amz-Signature")
  valid_593407 = validateParameter(valid_593407, JString, required = false,
                                 default = nil)
  if valid_593407 != nil:
    section.add "X-Amz-Signature", valid_593407
  var valid_593408 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593408 = validateParameter(valid_593408, JString, required = false,
                                 default = nil)
  if valid_593408 != nil:
    section.add "X-Amz-Content-Sha256", valid_593408
  var valid_593409 = header.getOrDefault("X-Amz-Date")
  valid_593409 = validateParameter(valid_593409, JString, required = false,
                                 default = nil)
  if valid_593409 != nil:
    section.add "X-Amz-Date", valid_593409
  var valid_593410 = header.getOrDefault("X-Amz-Credential")
  valid_593410 = validateParameter(valid_593410, JString, required = false,
                                 default = nil)
  if valid_593410 != nil:
    section.add "X-Amz-Credential", valid_593410
  var valid_593411 = header.getOrDefault("X-Amz-Security-Token")
  valid_593411 = validateParameter(valid_593411, JString, required = false,
                                 default = nil)
  if valid_593411 != nil:
    section.add "X-Amz-Security-Token", valid_593411
  var valid_593412 = header.getOrDefault("X-Amz-Algorithm")
  valid_593412 = validateParameter(valid_593412, JString, required = false,
                                 default = nil)
  if valid_593412 != nil:
    section.add "X-Amz-Algorithm", valid_593412
  var valid_593413 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593413 = validateParameter(valid_593413, JString, required = false,
                                 default = nil)
  if valid_593413 != nil:
    section.add "X-Amz-SignedHeaders", valid_593413
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593414: Call_GetDistributionConfig20180618_593403; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Get the configuration information about a distribution. 
  ## 
  let valid = call_593414.validator(path, query, header, formData, body)
  let scheme = call_593414.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593414.url(scheme.get, call_593414.host, call_593414.base,
                         call_593414.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593414, url, valid)

proc call*(call_593415: Call_GetDistributionConfig20180618_593403; Id: string): Recallable =
  ## getDistributionConfig20180618
  ## Get the configuration information about a distribution. 
  ##   Id: string (required)
  ##     : The distribution's ID.
  var path_593416 = newJObject()
  add(path_593416, "Id", newJString(Id))
  result = call_593415.call(path_593416, nil, nil, nil, nil)

var getDistributionConfig20180618* = Call_GetDistributionConfig20180618_593403(
    name: "getDistributionConfig20180618", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com",
    route: "/2018-06-18/distribution/{Id}/config",
    validator: validate_GetDistributionConfig20180618_593404, base: "/",
    url: url_GetDistributionConfig20180618_593405,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateFieldLevelEncryptionConfig20180618_593448 = ref object of OpenApiRestCall_592364
proc url_UpdateFieldLevelEncryptionConfig20180618_593450(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                value: "/2018-06-18/field-level-encryption/"),
               (kind: VariableSegment, value: "Id"),
               (kind: ConstantSegment, value: "/config")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_UpdateFieldLevelEncryptionConfig20180618_593449(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Update a field-level encryption configuration. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The ID of the configuration you want to update.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_593451 = path.getOrDefault("Id")
  valid_593451 = validateParameter(valid_593451, JString, required = true,
                                 default = nil)
  if valid_593451 != nil:
    section.add "Id", valid_593451
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   If-Match: JString
  ##           : The value of the <code>ETag</code> header that you received when retrieving the configuration identity to update. For example: <code>E2QWRUHAPOMQZL</code>.
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593452 = header.getOrDefault("X-Amz-Signature")
  valid_593452 = validateParameter(valid_593452, JString, required = false,
                                 default = nil)
  if valid_593452 != nil:
    section.add "X-Amz-Signature", valid_593452
  var valid_593453 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593453 = validateParameter(valid_593453, JString, required = false,
                                 default = nil)
  if valid_593453 != nil:
    section.add "X-Amz-Content-Sha256", valid_593453
  var valid_593454 = header.getOrDefault("X-Amz-Date")
  valid_593454 = validateParameter(valid_593454, JString, required = false,
                                 default = nil)
  if valid_593454 != nil:
    section.add "X-Amz-Date", valid_593454
  var valid_593455 = header.getOrDefault("X-Amz-Credential")
  valid_593455 = validateParameter(valid_593455, JString, required = false,
                                 default = nil)
  if valid_593455 != nil:
    section.add "X-Amz-Credential", valid_593455
  var valid_593456 = header.getOrDefault("X-Amz-Security-Token")
  valid_593456 = validateParameter(valid_593456, JString, required = false,
                                 default = nil)
  if valid_593456 != nil:
    section.add "X-Amz-Security-Token", valid_593456
  var valid_593457 = header.getOrDefault("If-Match")
  valid_593457 = validateParameter(valid_593457, JString, required = false,
                                 default = nil)
  if valid_593457 != nil:
    section.add "If-Match", valid_593457
  var valid_593458 = header.getOrDefault("X-Amz-Algorithm")
  valid_593458 = validateParameter(valid_593458, JString, required = false,
                                 default = nil)
  if valid_593458 != nil:
    section.add "X-Amz-Algorithm", valid_593458
  var valid_593459 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593459 = validateParameter(valid_593459, JString, required = false,
                                 default = nil)
  if valid_593459 != nil:
    section.add "X-Amz-SignedHeaders", valid_593459
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593461: Call_UpdateFieldLevelEncryptionConfig20180618_593448;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Update a field-level encryption configuration. 
  ## 
  let valid = call_593461.validator(path, query, header, formData, body)
  let scheme = call_593461.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593461.url(scheme.get, call_593461.host, call_593461.base,
                         call_593461.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593461, url, valid)

proc call*(call_593462: Call_UpdateFieldLevelEncryptionConfig20180618_593448;
          body: JsonNode; Id: string): Recallable =
  ## updateFieldLevelEncryptionConfig20180618
  ## Update a field-level encryption configuration. 
  ##   body: JObject (required)
  ##   Id: string (required)
  ##     : The ID of the configuration you want to update.
  var path_593463 = newJObject()
  var body_593464 = newJObject()
  if body != nil:
    body_593464 = body
  add(path_593463, "Id", newJString(Id))
  result = call_593462.call(path_593463, nil, nil, nil, body_593464)

var updateFieldLevelEncryptionConfig20180618* = Call_UpdateFieldLevelEncryptionConfig20180618_593448(
    name: "updateFieldLevelEncryptionConfig20180618", meth: HttpMethod.HttpPut,
    host: "cloudfront.amazonaws.com",
    route: "/2018-06-18/field-level-encryption/{Id}/config",
    validator: validate_UpdateFieldLevelEncryptionConfig20180618_593449,
    base: "/", url: url_UpdateFieldLevelEncryptionConfig20180618_593450,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFieldLevelEncryptionConfig20180618_593434 = ref object of OpenApiRestCall_592364
proc url_GetFieldLevelEncryptionConfig20180618_593436(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                value: "/2018-06-18/field-level-encryption/"),
               (kind: VariableSegment, value: "Id"),
               (kind: ConstantSegment, value: "/config")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_GetFieldLevelEncryptionConfig20180618_593435(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Get the field-level encryption configuration information.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : Request the ID for the field-level encryption configuration information.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_593437 = path.getOrDefault("Id")
  valid_593437 = validateParameter(valid_593437, JString, required = true,
                                 default = nil)
  if valid_593437 != nil:
    section.add "Id", valid_593437
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
  var valid_593438 = header.getOrDefault("X-Amz-Signature")
  valid_593438 = validateParameter(valid_593438, JString, required = false,
                                 default = nil)
  if valid_593438 != nil:
    section.add "X-Amz-Signature", valid_593438
  var valid_593439 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593439 = validateParameter(valid_593439, JString, required = false,
                                 default = nil)
  if valid_593439 != nil:
    section.add "X-Amz-Content-Sha256", valid_593439
  var valid_593440 = header.getOrDefault("X-Amz-Date")
  valid_593440 = validateParameter(valid_593440, JString, required = false,
                                 default = nil)
  if valid_593440 != nil:
    section.add "X-Amz-Date", valid_593440
  var valid_593441 = header.getOrDefault("X-Amz-Credential")
  valid_593441 = validateParameter(valid_593441, JString, required = false,
                                 default = nil)
  if valid_593441 != nil:
    section.add "X-Amz-Credential", valid_593441
  var valid_593442 = header.getOrDefault("X-Amz-Security-Token")
  valid_593442 = validateParameter(valid_593442, JString, required = false,
                                 default = nil)
  if valid_593442 != nil:
    section.add "X-Amz-Security-Token", valid_593442
  var valid_593443 = header.getOrDefault("X-Amz-Algorithm")
  valid_593443 = validateParameter(valid_593443, JString, required = false,
                                 default = nil)
  if valid_593443 != nil:
    section.add "X-Amz-Algorithm", valid_593443
  var valid_593444 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593444 = validateParameter(valid_593444, JString, required = false,
                                 default = nil)
  if valid_593444 != nil:
    section.add "X-Amz-SignedHeaders", valid_593444
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593445: Call_GetFieldLevelEncryptionConfig20180618_593434;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Get the field-level encryption configuration information.
  ## 
  let valid = call_593445.validator(path, query, header, formData, body)
  let scheme = call_593445.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593445.url(scheme.get, call_593445.host, call_593445.base,
                         call_593445.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593445, url, valid)

proc call*(call_593446: Call_GetFieldLevelEncryptionConfig20180618_593434;
          Id: string): Recallable =
  ## getFieldLevelEncryptionConfig20180618
  ## Get the field-level encryption configuration information.
  ##   Id: string (required)
  ##     : Request the ID for the field-level encryption configuration information.
  var path_593447 = newJObject()
  add(path_593447, "Id", newJString(Id))
  result = call_593446.call(path_593447, nil, nil, nil, nil)

var getFieldLevelEncryptionConfig20180618* = Call_GetFieldLevelEncryptionConfig20180618_593434(
    name: "getFieldLevelEncryptionConfig20180618", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com",
    route: "/2018-06-18/field-level-encryption/{Id}/config",
    validator: validate_GetFieldLevelEncryptionConfig20180618_593435, base: "/",
    url: url_GetFieldLevelEncryptionConfig20180618_593436,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateFieldLevelEncryptionProfile20180618_593479 = ref object of OpenApiRestCall_592364
proc url_UpdateFieldLevelEncryptionProfile20180618_593481(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                value: "/2018-06-18/field-level-encryption-profile/"),
               (kind: VariableSegment, value: "Id"),
               (kind: ConstantSegment, value: "/config")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_UpdateFieldLevelEncryptionProfile20180618_593480(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Update a field-level encryption profile. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The ID of the field-level encryption profile request. 
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_593482 = path.getOrDefault("Id")
  valid_593482 = validateParameter(valid_593482, JString, required = true,
                                 default = nil)
  if valid_593482 != nil:
    section.add "Id", valid_593482
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   If-Match: JString
  ##           : The value of the <code>ETag</code> header that you received when retrieving the profile identity to update. For example: <code>E2QWRUHAPOMQZL</code>.
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593483 = header.getOrDefault("X-Amz-Signature")
  valid_593483 = validateParameter(valid_593483, JString, required = false,
                                 default = nil)
  if valid_593483 != nil:
    section.add "X-Amz-Signature", valid_593483
  var valid_593484 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593484 = validateParameter(valid_593484, JString, required = false,
                                 default = nil)
  if valid_593484 != nil:
    section.add "X-Amz-Content-Sha256", valid_593484
  var valid_593485 = header.getOrDefault("X-Amz-Date")
  valid_593485 = validateParameter(valid_593485, JString, required = false,
                                 default = nil)
  if valid_593485 != nil:
    section.add "X-Amz-Date", valid_593485
  var valid_593486 = header.getOrDefault("X-Amz-Credential")
  valid_593486 = validateParameter(valid_593486, JString, required = false,
                                 default = nil)
  if valid_593486 != nil:
    section.add "X-Amz-Credential", valid_593486
  var valid_593487 = header.getOrDefault("X-Amz-Security-Token")
  valid_593487 = validateParameter(valid_593487, JString, required = false,
                                 default = nil)
  if valid_593487 != nil:
    section.add "X-Amz-Security-Token", valid_593487
  var valid_593488 = header.getOrDefault("If-Match")
  valid_593488 = validateParameter(valid_593488, JString, required = false,
                                 default = nil)
  if valid_593488 != nil:
    section.add "If-Match", valid_593488
  var valid_593489 = header.getOrDefault("X-Amz-Algorithm")
  valid_593489 = validateParameter(valid_593489, JString, required = false,
                                 default = nil)
  if valid_593489 != nil:
    section.add "X-Amz-Algorithm", valid_593489
  var valid_593490 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593490 = validateParameter(valid_593490, JString, required = false,
                                 default = nil)
  if valid_593490 != nil:
    section.add "X-Amz-SignedHeaders", valid_593490
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593492: Call_UpdateFieldLevelEncryptionProfile20180618_593479;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Update a field-level encryption profile. 
  ## 
  let valid = call_593492.validator(path, query, header, formData, body)
  let scheme = call_593492.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593492.url(scheme.get, call_593492.host, call_593492.base,
                         call_593492.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593492, url, valid)

proc call*(call_593493: Call_UpdateFieldLevelEncryptionProfile20180618_593479;
          body: JsonNode; Id: string): Recallable =
  ## updateFieldLevelEncryptionProfile20180618
  ## Update a field-level encryption profile. 
  ##   body: JObject (required)
  ##   Id: string (required)
  ##     : The ID of the field-level encryption profile request. 
  var path_593494 = newJObject()
  var body_593495 = newJObject()
  if body != nil:
    body_593495 = body
  add(path_593494, "Id", newJString(Id))
  result = call_593493.call(path_593494, nil, nil, nil, body_593495)

var updateFieldLevelEncryptionProfile20180618* = Call_UpdateFieldLevelEncryptionProfile20180618_593479(
    name: "updateFieldLevelEncryptionProfile20180618", meth: HttpMethod.HttpPut,
    host: "cloudfront.amazonaws.com",
    route: "/2018-06-18/field-level-encryption-profile/{Id}/config",
    validator: validate_UpdateFieldLevelEncryptionProfile20180618_593480,
    base: "/", url: url_UpdateFieldLevelEncryptionProfile20180618_593481,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFieldLevelEncryptionProfileConfig20180618_593465 = ref object of OpenApiRestCall_592364
proc url_GetFieldLevelEncryptionProfileConfig20180618_593467(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                value: "/2018-06-18/field-level-encryption-profile/"),
               (kind: VariableSegment, value: "Id"),
               (kind: ConstantSegment, value: "/config")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_GetFieldLevelEncryptionProfileConfig20180618_593466(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Get the field-level encryption profile configuration information.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : Get the ID for the field-level encryption profile configuration information.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_593468 = path.getOrDefault("Id")
  valid_593468 = validateParameter(valid_593468, JString, required = true,
                                 default = nil)
  if valid_593468 != nil:
    section.add "Id", valid_593468
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
  var valid_593469 = header.getOrDefault("X-Amz-Signature")
  valid_593469 = validateParameter(valid_593469, JString, required = false,
                                 default = nil)
  if valid_593469 != nil:
    section.add "X-Amz-Signature", valid_593469
  var valid_593470 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593470 = validateParameter(valid_593470, JString, required = false,
                                 default = nil)
  if valid_593470 != nil:
    section.add "X-Amz-Content-Sha256", valid_593470
  var valid_593471 = header.getOrDefault("X-Amz-Date")
  valid_593471 = validateParameter(valid_593471, JString, required = false,
                                 default = nil)
  if valid_593471 != nil:
    section.add "X-Amz-Date", valid_593471
  var valid_593472 = header.getOrDefault("X-Amz-Credential")
  valid_593472 = validateParameter(valid_593472, JString, required = false,
                                 default = nil)
  if valid_593472 != nil:
    section.add "X-Amz-Credential", valid_593472
  var valid_593473 = header.getOrDefault("X-Amz-Security-Token")
  valid_593473 = validateParameter(valid_593473, JString, required = false,
                                 default = nil)
  if valid_593473 != nil:
    section.add "X-Amz-Security-Token", valid_593473
  var valid_593474 = header.getOrDefault("X-Amz-Algorithm")
  valid_593474 = validateParameter(valid_593474, JString, required = false,
                                 default = nil)
  if valid_593474 != nil:
    section.add "X-Amz-Algorithm", valid_593474
  var valid_593475 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593475 = validateParameter(valid_593475, JString, required = false,
                                 default = nil)
  if valid_593475 != nil:
    section.add "X-Amz-SignedHeaders", valid_593475
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593476: Call_GetFieldLevelEncryptionProfileConfig20180618_593465;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Get the field-level encryption profile configuration information.
  ## 
  let valid = call_593476.validator(path, query, header, formData, body)
  let scheme = call_593476.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593476.url(scheme.get, call_593476.host, call_593476.base,
                         call_593476.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593476, url, valid)

proc call*(call_593477: Call_GetFieldLevelEncryptionProfileConfig20180618_593465;
          Id: string): Recallable =
  ## getFieldLevelEncryptionProfileConfig20180618
  ## Get the field-level encryption profile configuration information.
  ##   Id: string (required)
  ##     : Get the ID for the field-level encryption profile configuration information.
  var path_593478 = newJObject()
  add(path_593478, "Id", newJString(Id))
  result = call_593477.call(path_593478, nil, nil, nil, nil)

var getFieldLevelEncryptionProfileConfig20180618* = Call_GetFieldLevelEncryptionProfileConfig20180618_593465(
    name: "getFieldLevelEncryptionProfileConfig20180618",
    meth: HttpMethod.HttpGet, host: "cloudfront.amazonaws.com",
    route: "/2018-06-18/field-level-encryption-profile/{Id}/config",
    validator: validate_GetFieldLevelEncryptionProfileConfig20180618_593466,
    base: "/", url: url_GetFieldLevelEncryptionProfileConfig20180618_593467,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetInvalidation20180618_593496 = ref object of OpenApiRestCall_592364
proc url_GetInvalidation20180618_593498(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "DistributionId" in path, "`DistributionId` is a required path parameter"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2018-06-18/distribution/"),
               (kind: VariableSegment, value: "DistributionId"),
               (kind: ConstantSegment, value: "/invalidation/"),
               (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_GetInvalidation20180618_593497(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Get the information about an invalidation. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   DistributionId: JString (required)
  ##                 : The distribution's ID.
  ##   Id: JString (required)
  ##     : The identifier for the invalidation request, for example, <code>IDFDVBD632BHDS5</code>.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `DistributionId` field"
  var valid_593499 = path.getOrDefault("DistributionId")
  valid_593499 = validateParameter(valid_593499, JString, required = true,
                                 default = nil)
  if valid_593499 != nil:
    section.add "DistributionId", valid_593499
  var valid_593500 = path.getOrDefault("Id")
  valid_593500 = validateParameter(valid_593500, JString, required = true,
                                 default = nil)
  if valid_593500 != nil:
    section.add "Id", valid_593500
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
  var valid_593501 = header.getOrDefault("X-Amz-Signature")
  valid_593501 = validateParameter(valid_593501, JString, required = false,
                                 default = nil)
  if valid_593501 != nil:
    section.add "X-Amz-Signature", valid_593501
  var valid_593502 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593502 = validateParameter(valid_593502, JString, required = false,
                                 default = nil)
  if valid_593502 != nil:
    section.add "X-Amz-Content-Sha256", valid_593502
  var valid_593503 = header.getOrDefault("X-Amz-Date")
  valid_593503 = validateParameter(valid_593503, JString, required = false,
                                 default = nil)
  if valid_593503 != nil:
    section.add "X-Amz-Date", valid_593503
  var valid_593504 = header.getOrDefault("X-Amz-Credential")
  valid_593504 = validateParameter(valid_593504, JString, required = false,
                                 default = nil)
  if valid_593504 != nil:
    section.add "X-Amz-Credential", valid_593504
  var valid_593505 = header.getOrDefault("X-Amz-Security-Token")
  valid_593505 = validateParameter(valid_593505, JString, required = false,
                                 default = nil)
  if valid_593505 != nil:
    section.add "X-Amz-Security-Token", valid_593505
  var valid_593506 = header.getOrDefault("X-Amz-Algorithm")
  valid_593506 = validateParameter(valid_593506, JString, required = false,
                                 default = nil)
  if valid_593506 != nil:
    section.add "X-Amz-Algorithm", valid_593506
  var valid_593507 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593507 = validateParameter(valid_593507, JString, required = false,
                                 default = nil)
  if valid_593507 != nil:
    section.add "X-Amz-SignedHeaders", valid_593507
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593508: Call_GetInvalidation20180618_593496; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Get the information about an invalidation. 
  ## 
  let valid = call_593508.validator(path, query, header, formData, body)
  let scheme = call_593508.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593508.url(scheme.get, call_593508.host, call_593508.base,
                         call_593508.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593508, url, valid)

proc call*(call_593509: Call_GetInvalidation20180618_593496;
          DistributionId: string; Id: string): Recallable =
  ## getInvalidation20180618
  ## Get the information about an invalidation. 
  ##   DistributionId: string (required)
  ##                 : The distribution's ID.
  ##   Id: string (required)
  ##     : The identifier for the invalidation request, for example, <code>IDFDVBD632BHDS5</code>.
  var path_593510 = newJObject()
  add(path_593510, "DistributionId", newJString(DistributionId))
  add(path_593510, "Id", newJString(Id))
  result = call_593509.call(path_593510, nil, nil, nil, nil)

var getInvalidation20180618* = Call_GetInvalidation20180618_593496(
    name: "getInvalidation20180618", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com",
    route: "/2018-06-18/distribution/{DistributionId}/invalidation/{Id}",
    validator: validate_GetInvalidation20180618_593497, base: "/",
    url: url_GetInvalidation20180618_593498, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdatePublicKey20180618_593525 = ref object of OpenApiRestCall_592364
proc url_UpdatePublicKey20180618_593527(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2018-06-18/public-key/"),
               (kind: VariableSegment, value: "Id"),
               (kind: ConstantSegment, value: "/config")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_UpdatePublicKey20180618_593526(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Update public key information. Note that the only value you can change is the comment.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : ID of the public key to be updated.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_593528 = path.getOrDefault("Id")
  valid_593528 = validateParameter(valid_593528, JString, required = true,
                                 default = nil)
  if valid_593528 != nil:
    section.add "Id", valid_593528
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   If-Match: JString
  ##           : The value of the <code>ETag</code> header that you received when retrieving the public key to update. For example: <code>E2QWRUHAPOMQZL</code>.
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593529 = header.getOrDefault("X-Amz-Signature")
  valid_593529 = validateParameter(valid_593529, JString, required = false,
                                 default = nil)
  if valid_593529 != nil:
    section.add "X-Amz-Signature", valid_593529
  var valid_593530 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593530 = validateParameter(valid_593530, JString, required = false,
                                 default = nil)
  if valid_593530 != nil:
    section.add "X-Amz-Content-Sha256", valid_593530
  var valid_593531 = header.getOrDefault("X-Amz-Date")
  valid_593531 = validateParameter(valid_593531, JString, required = false,
                                 default = nil)
  if valid_593531 != nil:
    section.add "X-Amz-Date", valid_593531
  var valid_593532 = header.getOrDefault("X-Amz-Credential")
  valid_593532 = validateParameter(valid_593532, JString, required = false,
                                 default = nil)
  if valid_593532 != nil:
    section.add "X-Amz-Credential", valid_593532
  var valid_593533 = header.getOrDefault("X-Amz-Security-Token")
  valid_593533 = validateParameter(valid_593533, JString, required = false,
                                 default = nil)
  if valid_593533 != nil:
    section.add "X-Amz-Security-Token", valid_593533
  var valid_593534 = header.getOrDefault("If-Match")
  valid_593534 = validateParameter(valid_593534, JString, required = false,
                                 default = nil)
  if valid_593534 != nil:
    section.add "If-Match", valid_593534
  var valid_593535 = header.getOrDefault("X-Amz-Algorithm")
  valid_593535 = validateParameter(valid_593535, JString, required = false,
                                 default = nil)
  if valid_593535 != nil:
    section.add "X-Amz-Algorithm", valid_593535
  var valid_593536 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593536 = validateParameter(valid_593536, JString, required = false,
                                 default = nil)
  if valid_593536 != nil:
    section.add "X-Amz-SignedHeaders", valid_593536
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593538: Call_UpdatePublicKey20180618_593525; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Update public key information. Note that the only value you can change is the comment.
  ## 
  let valid = call_593538.validator(path, query, header, formData, body)
  let scheme = call_593538.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593538.url(scheme.get, call_593538.host, call_593538.base,
                         call_593538.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593538, url, valid)

proc call*(call_593539: Call_UpdatePublicKey20180618_593525; body: JsonNode;
          Id: string): Recallable =
  ## updatePublicKey20180618
  ## Update public key information. Note that the only value you can change is the comment.
  ##   body: JObject (required)
  ##   Id: string (required)
  ##     : ID of the public key to be updated.
  var path_593540 = newJObject()
  var body_593541 = newJObject()
  if body != nil:
    body_593541 = body
  add(path_593540, "Id", newJString(Id))
  result = call_593539.call(path_593540, nil, nil, nil, body_593541)

var updatePublicKey20180618* = Call_UpdatePublicKey20180618_593525(
    name: "updatePublicKey20180618", meth: HttpMethod.HttpPut,
    host: "cloudfront.amazonaws.com", route: "/2018-06-18/public-key/{Id}/config",
    validator: validate_UpdatePublicKey20180618_593526, base: "/",
    url: url_UpdatePublicKey20180618_593527, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPublicKeyConfig20180618_593511 = ref object of OpenApiRestCall_592364
proc url_GetPublicKeyConfig20180618_593513(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2018-06-18/public-key/"),
               (kind: VariableSegment, value: "Id"),
               (kind: ConstantSegment, value: "/config")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_GetPublicKeyConfig20180618_593512(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Return public key configuration informaation
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : Request the ID for the public key configuration.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_593514 = path.getOrDefault("Id")
  valid_593514 = validateParameter(valid_593514, JString, required = true,
                                 default = nil)
  if valid_593514 != nil:
    section.add "Id", valid_593514
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
  var valid_593515 = header.getOrDefault("X-Amz-Signature")
  valid_593515 = validateParameter(valid_593515, JString, required = false,
                                 default = nil)
  if valid_593515 != nil:
    section.add "X-Amz-Signature", valid_593515
  var valid_593516 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593516 = validateParameter(valid_593516, JString, required = false,
                                 default = nil)
  if valid_593516 != nil:
    section.add "X-Amz-Content-Sha256", valid_593516
  var valid_593517 = header.getOrDefault("X-Amz-Date")
  valid_593517 = validateParameter(valid_593517, JString, required = false,
                                 default = nil)
  if valid_593517 != nil:
    section.add "X-Amz-Date", valid_593517
  var valid_593518 = header.getOrDefault("X-Amz-Credential")
  valid_593518 = validateParameter(valid_593518, JString, required = false,
                                 default = nil)
  if valid_593518 != nil:
    section.add "X-Amz-Credential", valid_593518
  var valid_593519 = header.getOrDefault("X-Amz-Security-Token")
  valid_593519 = validateParameter(valid_593519, JString, required = false,
                                 default = nil)
  if valid_593519 != nil:
    section.add "X-Amz-Security-Token", valid_593519
  var valid_593520 = header.getOrDefault("X-Amz-Algorithm")
  valid_593520 = validateParameter(valid_593520, JString, required = false,
                                 default = nil)
  if valid_593520 != nil:
    section.add "X-Amz-Algorithm", valid_593520
  var valid_593521 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593521 = validateParameter(valid_593521, JString, required = false,
                                 default = nil)
  if valid_593521 != nil:
    section.add "X-Amz-SignedHeaders", valid_593521
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593522: Call_GetPublicKeyConfig20180618_593511; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Return public key configuration informaation
  ## 
  let valid = call_593522.validator(path, query, header, formData, body)
  let scheme = call_593522.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593522.url(scheme.get, call_593522.host, call_593522.base,
                         call_593522.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593522, url, valid)

proc call*(call_593523: Call_GetPublicKeyConfig20180618_593511; Id: string): Recallable =
  ## getPublicKeyConfig20180618
  ## Return public key configuration informaation
  ##   Id: string (required)
  ##     : Request the ID for the public key configuration.
  var path_593524 = newJObject()
  add(path_593524, "Id", newJString(Id))
  result = call_593523.call(path_593524, nil, nil, nil, nil)

var getPublicKeyConfig20180618* = Call_GetPublicKeyConfig20180618_593511(
    name: "getPublicKeyConfig20180618", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com", route: "/2018-06-18/public-key/{Id}/config",
    validator: validate_GetPublicKeyConfig20180618_593512, base: "/",
    url: url_GetPublicKeyConfig20180618_593513,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateStreamingDistribution20180618_593556 = ref object of OpenApiRestCall_592364
proc url_UpdateStreamingDistribution20180618_593558(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                value: "/2018-06-18/streaming-distribution/"),
               (kind: VariableSegment, value: "Id"),
               (kind: ConstantSegment, value: "/config")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_UpdateStreamingDistribution20180618_593557(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Update a streaming distribution. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The streaming distribution's id.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_593559 = path.getOrDefault("Id")
  valid_593559 = validateParameter(valid_593559, JString, required = true,
                                 default = nil)
  if valid_593559 != nil:
    section.add "Id", valid_593559
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   If-Match: JString
  ##           : The value of the <code>ETag</code> header that you received when retrieving the streaming distribution's configuration. For example: <code>E2QWRUHAPOMQZL</code>.
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593560 = header.getOrDefault("X-Amz-Signature")
  valid_593560 = validateParameter(valid_593560, JString, required = false,
                                 default = nil)
  if valid_593560 != nil:
    section.add "X-Amz-Signature", valid_593560
  var valid_593561 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593561 = validateParameter(valid_593561, JString, required = false,
                                 default = nil)
  if valid_593561 != nil:
    section.add "X-Amz-Content-Sha256", valid_593561
  var valid_593562 = header.getOrDefault("X-Amz-Date")
  valid_593562 = validateParameter(valid_593562, JString, required = false,
                                 default = nil)
  if valid_593562 != nil:
    section.add "X-Amz-Date", valid_593562
  var valid_593563 = header.getOrDefault("X-Amz-Credential")
  valid_593563 = validateParameter(valid_593563, JString, required = false,
                                 default = nil)
  if valid_593563 != nil:
    section.add "X-Amz-Credential", valid_593563
  var valid_593564 = header.getOrDefault("X-Amz-Security-Token")
  valid_593564 = validateParameter(valid_593564, JString, required = false,
                                 default = nil)
  if valid_593564 != nil:
    section.add "X-Amz-Security-Token", valid_593564
  var valid_593565 = header.getOrDefault("If-Match")
  valid_593565 = validateParameter(valid_593565, JString, required = false,
                                 default = nil)
  if valid_593565 != nil:
    section.add "If-Match", valid_593565
  var valid_593566 = header.getOrDefault("X-Amz-Algorithm")
  valid_593566 = validateParameter(valid_593566, JString, required = false,
                                 default = nil)
  if valid_593566 != nil:
    section.add "X-Amz-Algorithm", valid_593566
  var valid_593567 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593567 = validateParameter(valid_593567, JString, required = false,
                                 default = nil)
  if valid_593567 != nil:
    section.add "X-Amz-SignedHeaders", valid_593567
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593569: Call_UpdateStreamingDistribution20180618_593556;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Update a streaming distribution. 
  ## 
  let valid = call_593569.validator(path, query, header, formData, body)
  let scheme = call_593569.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593569.url(scheme.get, call_593569.host, call_593569.base,
                         call_593569.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593569, url, valid)

proc call*(call_593570: Call_UpdateStreamingDistribution20180618_593556;
          body: JsonNode; Id: string): Recallable =
  ## updateStreamingDistribution20180618
  ## Update a streaming distribution. 
  ##   body: JObject (required)
  ##   Id: string (required)
  ##     : The streaming distribution's id.
  var path_593571 = newJObject()
  var body_593572 = newJObject()
  if body != nil:
    body_593572 = body
  add(path_593571, "Id", newJString(Id))
  result = call_593570.call(path_593571, nil, nil, nil, body_593572)

var updateStreamingDistribution20180618* = Call_UpdateStreamingDistribution20180618_593556(
    name: "updateStreamingDistribution20180618", meth: HttpMethod.HttpPut,
    host: "cloudfront.amazonaws.com",
    route: "/2018-06-18/streaming-distribution/{Id}/config",
    validator: validate_UpdateStreamingDistribution20180618_593557, base: "/",
    url: url_UpdateStreamingDistribution20180618_593558,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetStreamingDistributionConfig20180618_593542 = ref object of OpenApiRestCall_592364
proc url_GetStreamingDistributionConfig20180618_593544(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                value: "/2018-06-18/streaming-distribution/"),
               (kind: VariableSegment, value: "Id"),
               (kind: ConstantSegment, value: "/config")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_GetStreamingDistributionConfig20180618_593543(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Get the configuration information about a streaming distribution. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The streaming distribution's ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_593545 = path.getOrDefault("Id")
  valid_593545 = validateParameter(valid_593545, JString, required = true,
                                 default = nil)
  if valid_593545 != nil:
    section.add "Id", valid_593545
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
  var valid_593546 = header.getOrDefault("X-Amz-Signature")
  valid_593546 = validateParameter(valid_593546, JString, required = false,
                                 default = nil)
  if valid_593546 != nil:
    section.add "X-Amz-Signature", valid_593546
  var valid_593547 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593547 = validateParameter(valid_593547, JString, required = false,
                                 default = nil)
  if valid_593547 != nil:
    section.add "X-Amz-Content-Sha256", valid_593547
  var valid_593548 = header.getOrDefault("X-Amz-Date")
  valid_593548 = validateParameter(valid_593548, JString, required = false,
                                 default = nil)
  if valid_593548 != nil:
    section.add "X-Amz-Date", valid_593548
  var valid_593549 = header.getOrDefault("X-Amz-Credential")
  valid_593549 = validateParameter(valid_593549, JString, required = false,
                                 default = nil)
  if valid_593549 != nil:
    section.add "X-Amz-Credential", valid_593549
  var valid_593550 = header.getOrDefault("X-Amz-Security-Token")
  valid_593550 = validateParameter(valid_593550, JString, required = false,
                                 default = nil)
  if valid_593550 != nil:
    section.add "X-Amz-Security-Token", valid_593550
  var valid_593551 = header.getOrDefault("X-Amz-Algorithm")
  valid_593551 = validateParameter(valid_593551, JString, required = false,
                                 default = nil)
  if valid_593551 != nil:
    section.add "X-Amz-Algorithm", valid_593551
  var valid_593552 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593552 = validateParameter(valid_593552, JString, required = false,
                                 default = nil)
  if valid_593552 != nil:
    section.add "X-Amz-SignedHeaders", valid_593552
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593553: Call_GetStreamingDistributionConfig20180618_593542;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Get the configuration information about a streaming distribution. 
  ## 
  let valid = call_593553.validator(path, query, header, formData, body)
  let scheme = call_593553.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593553.url(scheme.get, call_593553.host, call_593553.base,
                         call_593553.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593553, url, valid)

proc call*(call_593554: Call_GetStreamingDistributionConfig20180618_593542;
          Id: string): Recallable =
  ## getStreamingDistributionConfig20180618
  ## Get the configuration information about a streaming distribution. 
  ##   Id: string (required)
  ##     : The streaming distribution's ID.
  var path_593555 = newJObject()
  add(path_593555, "Id", newJString(Id))
  result = call_593554.call(path_593555, nil, nil, nil, nil)

var getStreamingDistributionConfig20180618* = Call_GetStreamingDistributionConfig20180618_593542(
    name: "getStreamingDistributionConfig20180618", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com",
    route: "/2018-06-18/streaming-distribution/{Id}/config",
    validator: validate_GetStreamingDistributionConfig20180618_593543, base: "/",
    url: url_GetStreamingDistributionConfig20180618_593544,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDistributionsByWebACLId20180618_593573 = ref object of OpenApiRestCall_592364
proc url_ListDistributionsByWebACLId20180618_593575(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "WebACLId" in path, "`WebACLId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                value: "/2018-06-18/distributionsByWebACLId/"),
               (kind: VariableSegment, value: "WebACLId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_ListDistributionsByWebACLId20180618_593574(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## List the distributions that are associated with a specified AWS WAF web ACL. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   WebACLId: JString (required)
  ##           : The ID of the AWS WAF web ACL that you want to list the associated distributions. If you specify "null" for the ID, the request returns a list of the distributions that aren't associated with a web ACL. 
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `WebACLId` field"
  var valid_593576 = path.getOrDefault("WebACLId")
  valid_593576 = validateParameter(valid_593576, JString, required = true,
                                 default = nil)
  if valid_593576 != nil:
    section.add "WebACLId", valid_593576
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##         : Use <code>Marker</code> and <code>MaxItems</code> to control pagination of results. If you have more than <code>MaxItems</code> distributions that satisfy the request, the response includes a <code>NextMarker</code> element. To get the next page of results, submit another request. For the value of <code>Marker</code>, specify the value of <code>NextMarker</code> from the last response. (For the first request, omit <code>Marker</code>.) 
  ##   MaxItems: JString
  ##           : The maximum number of distributions that you want CloudFront to return in the response body. The maximum and default values are both 100.
  section = newJObject()
  var valid_593577 = query.getOrDefault("Marker")
  valid_593577 = validateParameter(valid_593577, JString, required = false,
                                 default = nil)
  if valid_593577 != nil:
    section.add "Marker", valid_593577
  var valid_593578 = query.getOrDefault("MaxItems")
  valid_593578 = validateParameter(valid_593578, JString, required = false,
                                 default = nil)
  if valid_593578 != nil:
    section.add "MaxItems", valid_593578
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
  var valid_593579 = header.getOrDefault("X-Amz-Signature")
  valid_593579 = validateParameter(valid_593579, JString, required = false,
                                 default = nil)
  if valid_593579 != nil:
    section.add "X-Amz-Signature", valid_593579
  var valid_593580 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593580 = validateParameter(valid_593580, JString, required = false,
                                 default = nil)
  if valid_593580 != nil:
    section.add "X-Amz-Content-Sha256", valid_593580
  var valid_593581 = header.getOrDefault("X-Amz-Date")
  valid_593581 = validateParameter(valid_593581, JString, required = false,
                                 default = nil)
  if valid_593581 != nil:
    section.add "X-Amz-Date", valid_593581
  var valid_593582 = header.getOrDefault("X-Amz-Credential")
  valid_593582 = validateParameter(valid_593582, JString, required = false,
                                 default = nil)
  if valid_593582 != nil:
    section.add "X-Amz-Credential", valid_593582
  var valid_593583 = header.getOrDefault("X-Amz-Security-Token")
  valid_593583 = validateParameter(valid_593583, JString, required = false,
                                 default = nil)
  if valid_593583 != nil:
    section.add "X-Amz-Security-Token", valid_593583
  var valid_593584 = header.getOrDefault("X-Amz-Algorithm")
  valid_593584 = validateParameter(valid_593584, JString, required = false,
                                 default = nil)
  if valid_593584 != nil:
    section.add "X-Amz-Algorithm", valid_593584
  var valid_593585 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593585 = validateParameter(valid_593585, JString, required = false,
                                 default = nil)
  if valid_593585 != nil:
    section.add "X-Amz-SignedHeaders", valid_593585
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593586: Call_ListDistributionsByWebACLId20180618_593573;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## List the distributions that are associated with a specified AWS WAF web ACL. 
  ## 
  let valid = call_593586.validator(path, query, header, formData, body)
  let scheme = call_593586.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593586.url(scheme.get, call_593586.host, call_593586.base,
                         call_593586.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593586, url, valid)

proc call*(call_593587: Call_ListDistributionsByWebACLId20180618_593573;
          WebACLId: string; Marker: string = ""; MaxItems: string = ""): Recallable =
  ## listDistributionsByWebACLId20180618
  ## List the distributions that are associated with a specified AWS WAF web ACL. 
  ##   Marker: string
  ##         : Use <code>Marker</code> and <code>MaxItems</code> to control pagination of results. If you have more than <code>MaxItems</code> distributions that satisfy the request, the response includes a <code>NextMarker</code> element. To get the next page of results, submit another request. For the value of <code>Marker</code>, specify the value of <code>NextMarker</code> from the last response. (For the first request, omit <code>Marker</code>.) 
  ##   MaxItems: string
  ##           : The maximum number of distributions that you want CloudFront to return in the response body. The maximum and default values are both 100.
  ##   WebACLId: string (required)
  ##           : The ID of the AWS WAF web ACL that you want to list the associated distributions. If you specify "null" for the ID, the request returns a list of the distributions that aren't associated with a web ACL. 
  var path_593588 = newJObject()
  var query_593589 = newJObject()
  add(query_593589, "Marker", newJString(Marker))
  add(query_593589, "MaxItems", newJString(MaxItems))
  add(path_593588, "WebACLId", newJString(WebACLId))
  result = call_593587.call(path_593588, query_593589, nil, nil, nil)

var listDistributionsByWebACLId20180618* = Call_ListDistributionsByWebACLId20180618_593573(
    name: "listDistributionsByWebACLId20180618", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com",
    route: "/2018-06-18/distributionsByWebACLId/{WebACLId}",
    validator: validate_ListDistributionsByWebACLId20180618_593574, base: "/",
    url: url_ListDistributionsByWebACLId20180618_593575,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource20180618_593590 = ref object of OpenApiRestCall_592364
proc url_ListTagsForResource20180618_593592(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListTagsForResource20180618_593591(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## List tags for a CloudFront resource.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Resource: JString (required)
  ##           :  An ARN of a CloudFront resource.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `Resource` field"
  var valid_593593 = query.getOrDefault("Resource")
  valid_593593 = validateParameter(valid_593593, JString, required = true,
                                 default = nil)
  if valid_593593 != nil:
    section.add "Resource", valid_593593
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
  var valid_593594 = header.getOrDefault("X-Amz-Signature")
  valid_593594 = validateParameter(valid_593594, JString, required = false,
                                 default = nil)
  if valid_593594 != nil:
    section.add "X-Amz-Signature", valid_593594
  var valid_593595 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593595 = validateParameter(valid_593595, JString, required = false,
                                 default = nil)
  if valid_593595 != nil:
    section.add "X-Amz-Content-Sha256", valid_593595
  var valid_593596 = header.getOrDefault("X-Amz-Date")
  valid_593596 = validateParameter(valid_593596, JString, required = false,
                                 default = nil)
  if valid_593596 != nil:
    section.add "X-Amz-Date", valid_593596
  var valid_593597 = header.getOrDefault("X-Amz-Credential")
  valid_593597 = validateParameter(valid_593597, JString, required = false,
                                 default = nil)
  if valid_593597 != nil:
    section.add "X-Amz-Credential", valid_593597
  var valid_593598 = header.getOrDefault("X-Amz-Security-Token")
  valid_593598 = validateParameter(valid_593598, JString, required = false,
                                 default = nil)
  if valid_593598 != nil:
    section.add "X-Amz-Security-Token", valid_593598
  var valid_593599 = header.getOrDefault("X-Amz-Algorithm")
  valid_593599 = validateParameter(valid_593599, JString, required = false,
                                 default = nil)
  if valid_593599 != nil:
    section.add "X-Amz-Algorithm", valid_593599
  var valid_593600 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593600 = validateParameter(valid_593600, JString, required = false,
                                 default = nil)
  if valid_593600 != nil:
    section.add "X-Amz-SignedHeaders", valid_593600
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593601: Call_ListTagsForResource20180618_593590; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List tags for a CloudFront resource.
  ## 
  let valid = call_593601.validator(path, query, header, formData, body)
  let scheme = call_593601.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593601.url(scheme.get, call_593601.host, call_593601.base,
                         call_593601.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593601, url, valid)

proc call*(call_593602: Call_ListTagsForResource20180618_593590; Resource: string): Recallable =
  ## listTagsForResource20180618
  ## List tags for a CloudFront resource.
  ##   Resource: string (required)
  ##           :  An ARN of a CloudFront resource.
  var query_593603 = newJObject()
  add(query_593603, "Resource", newJString(Resource))
  result = call_593602.call(nil, query_593603, nil, nil, nil)

var listTagsForResource20180618* = Call_ListTagsForResource20180618_593590(
    name: "listTagsForResource20180618", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com", route: "/2018-06-18/tagging#Resource",
    validator: validate_ListTagsForResource20180618_593591, base: "/",
    url: url_ListTagsForResource20180618_593592,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource20180618_593604 = ref object of OpenApiRestCall_592364
proc url_TagResource20180618_593606(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_TagResource20180618_593605(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Add tags to a CloudFront resource.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Resource: JString (required)
  ##           :  An ARN of a CloudFront resource.
  ##   Operation: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `Resource` field"
  var valid_593607 = query.getOrDefault("Resource")
  valid_593607 = validateParameter(valid_593607, JString, required = true,
                                 default = nil)
  if valid_593607 != nil:
    section.add "Resource", valid_593607
  var valid_593621 = query.getOrDefault("Operation")
  valid_593621 = validateParameter(valid_593621, JString, required = true,
                                 default = newJString("Tag"))
  if valid_593621 != nil:
    section.add "Operation", valid_593621
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
  var valid_593622 = header.getOrDefault("X-Amz-Signature")
  valid_593622 = validateParameter(valid_593622, JString, required = false,
                                 default = nil)
  if valid_593622 != nil:
    section.add "X-Amz-Signature", valid_593622
  var valid_593623 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593623 = validateParameter(valid_593623, JString, required = false,
                                 default = nil)
  if valid_593623 != nil:
    section.add "X-Amz-Content-Sha256", valid_593623
  var valid_593624 = header.getOrDefault("X-Amz-Date")
  valid_593624 = validateParameter(valid_593624, JString, required = false,
                                 default = nil)
  if valid_593624 != nil:
    section.add "X-Amz-Date", valid_593624
  var valid_593625 = header.getOrDefault("X-Amz-Credential")
  valid_593625 = validateParameter(valid_593625, JString, required = false,
                                 default = nil)
  if valid_593625 != nil:
    section.add "X-Amz-Credential", valid_593625
  var valid_593626 = header.getOrDefault("X-Amz-Security-Token")
  valid_593626 = validateParameter(valid_593626, JString, required = false,
                                 default = nil)
  if valid_593626 != nil:
    section.add "X-Amz-Security-Token", valid_593626
  var valid_593627 = header.getOrDefault("X-Amz-Algorithm")
  valid_593627 = validateParameter(valid_593627, JString, required = false,
                                 default = nil)
  if valid_593627 != nil:
    section.add "X-Amz-Algorithm", valid_593627
  var valid_593628 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593628 = validateParameter(valid_593628, JString, required = false,
                                 default = nil)
  if valid_593628 != nil:
    section.add "X-Amz-SignedHeaders", valid_593628
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593630: Call_TagResource20180618_593604; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Add tags to a CloudFront resource.
  ## 
  let valid = call_593630.validator(path, query, header, formData, body)
  let scheme = call_593630.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593630.url(scheme.get, call_593630.host, call_593630.base,
                         call_593630.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593630, url, valid)

proc call*(call_593631: Call_TagResource20180618_593604; Resource: string;
          body: JsonNode; Operation: string = "Tag"): Recallable =
  ## tagResource20180618
  ## Add tags to a CloudFront resource.
  ##   Resource: string (required)
  ##           :  An ARN of a CloudFront resource.
  ##   Operation: string (required)
  ##   body: JObject (required)
  var query_593632 = newJObject()
  var body_593633 = newJObject()
  add(query_593632, "Resource", newJString(Resource))
  add(query_593632, "Operation", newJString(Operation))
  if body != nil:
    body_593633 = body
  result = call_593631.call(nil, query_593632, nil, nil, body_593633)

var tagResource20180618* = Call_TagResource20180618_593604(
    name: "tagResource20180618", meth: HttpMethod.HttpPost,
    host: "cloudfront.amazonaws.com",
    route: "/2018-06-18/tagging#Operation=Tag&Resource",
    validator: validate_TagResource20180618_593605, base: "/",
    url: url_TagResource20180618_593606, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource20180618_593634 = ref object of OpenApiRestCall_592364
proc url_UntagResource20180618_593636(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UntagResource20180618_593635(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Remove tags from a CloudFront resource.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Resource: JString (required)
  ##           :  An ARN of a CloudFront resource.
  ##   Operation: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `Resource` field"
  var valid_593637 = query.getOrDefault("Resource")
  valid_593637 = validateParameter(valid_593637, JString, required = true,
                                 default = nil)
  if valid_593637 != nil:
    section.add "Resource", valid_593637
  var valid_593638 = query.getOrDefault("Operation")
  valid_593638 = validateParameter(valid_593638, JString, required = true,
                                 default = newJString("Untag"))
  if valid_593638 != nil:
    section.add "Operation", valid_593638
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
  var valid_593639 = header.getOrDefault("X-Amz-Signature")
  valid_593639 = validateParameter(valid_593639, JString, required = false,
                                 default = nil)
  if valid_593639 != nil:
    section.add "X-Amz-Signature", valid_593639
  var valid_593640 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593640 = validateParameter(valid_593640, JString, required = false,
                                 default = nil)
  if valid_593640 != nil:
    section.add "X-Amz-Content-Sha256", valid_593640
  var valid_593641 = header.getOrDefault("X-Amz-Date")
  valid_593641 = validateParameter(valid_593641, JString, required = false,
                                 default = nil)
  if valid_593641 != nil:
    section.add "X-Amz-Date", valid_593641
  var valid_593642 = header.getOrDefault("X-Amz-Credential")
  valid_593642 = validateParameter(valid_593642, JString, required = false,
                                 default = nil)
  if valid_593642 != nil:
    section.add "X-Amz-Credential", valid_593642
  var valid_593643 = header.getOrDefault("X-Amz-Security-Token")
  valid_593643 = validateParameter(valid_593643, JString, required = false,
                                 default = nil)
  if valid_593643 != nil:
    section.add "X-Amz-Security-Token", valid_593643
  var valid_593644 = header.getOrDefault("X-Amz-Algorithm")
  valid_593644 = validateParameter(valid_593644, JString, required = false,
                                 default = nil)
  if valid_593644 != nil:
    section.add "X-Amz-Algorithm", valid_593644
  var valid_593645 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593645 = validateParameter(valid_593645, JString, required = false,
                                 default = nil)
  if valid_593645 != nil:
    section.add "X-Amz-SignedHeaders", valid_593645
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593647: Call_UntagResource20180618_593634; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Remove tags from a CloudFront resource.
  ## 
  let valid = call_593647.validator(path, query, header, formData, body)
  let scheme = call_593647.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593647.url(scheme.get, call_593647.host, call_593647.base,
                         call_593647.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593647, url, valid)

proc call*(call_593648: Call_UntagResource20180618_593634; Resource: string;
          body: JsonNode; Operation: string = "Untag"): Recallable =
  ## untagResource20180618
  ## Remove tags from a CloudFront resource.
  ##   Resource: string (required)
  ##           :  An ARN of a CloudFront resource.
  ##   Operation: string (required)
  ##   body: JObject (required)
  var query_593649 = newJObject()
  var body_593650 = newJObject()
  add(query_593649, "Resource", newJString(Resource))
  add(query_593649, "Operation", newJString(Operation))
  if body != nil:
    body_593650 = body
  result = call_593648.call(nil, query_593649, nil, nil, body_593650)

var untagResource20180618* = Call_UntagResource20180618_593634(
    name: "untagResource20180618", meth: HttpMethod.HttpPost,
    host: "cloudfront.amazonaws.com",
    route: "/2018-06-18/tagging#Operation=Untag&Resource",
    validator: validate_UntagResource20180618_593635, base: "/",
    url: url_UntagResource20180618_593636, schemes: {Scheme.Https, Scheme.Http})
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
