
import
  json, options, hashes, uri, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: Amazon CloudFront
## version: 2016-11-25
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <fullname>Amazon CloudFront</fullname> <p>This is the <i>Amazon CloudFront API Reference</i>. This guide is for developers who need detailed information about the CloudFront API actions, data types, and errors. For detailed information about CloudFront features and their associated API calls, see the <i>Amazon CloudFront Developer Guide</i>.</p>
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

  OpenApiRestCall_602466 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_602466](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_602466): Option[Scheme] {.used.} =
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
    if js.kind notin {JString, JInt, JFloat, JNull, JBool}:
      return
    head = $js
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
  Call_CreateCloudFrontOriginAccessIdentity20161125_603060 = ref object of OpenApiRestCall_602466
proc url_CreateCloudFrontOriginAccessIdentity20161125_603062(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateCloudFrontOriginAccessIdentity20161125_603061(path: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603063 = header.getOrDefault("X-Amz-Date")
  valid_603063 = validateParameter(valid_603063, JString, required = false,
                                 default = nil)
  if valid_603063 != nil:
    section.add "X-Amz-Date", valid_603063
  var valid_603064 = header.getOrDefault("X-Amz-Security-Token")
  valid_603064 = validateParameter(valid_603064, JString, required = false,
                                 default = nil)
  if valid_603064 != nil:
    section.add "X-Amz-Security-Token", valid_603064
  var valid_603065 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603065 = validateParameter(valid_603065, JString, required = false,
                                 default = nil)
  if valid_603065 != nil:
    section.add "X-Amz-Content-Sha256", valid_603065
  var valid_603066 = header.getOrDefault("X-Amz-Algorithm")
  valid_603066 = validateParameter(valid_603066, JString, required = false,
                                 default = nil)
  if valid_603066 != nil:
    section.add "X-Amz-Algorithm", valid_603066
  var valid_603067 = header.getOrDefault("X-Amz-Signature")
  valid_603067 = validateParameter(valid_603067, JString, required = false,
                                 default = nil)
  if valid_603067 != nil:
    section.add "X-Amz-Signature", valid_603067
  var valid_603068 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603068 = validateParameter(valid_603068, JString, required = false,
                                 default = nil)
  if valid_603068 != nil:
    section.add "X-Amz-SignedHeaders", valid_603068
  var valid_603069 = header.getOrDefault("X-Amz-Credential")
  valid_603069 = validateParameter(valid_603069, JString, required = false,
                                 default = nil)
  if valid_603069 != nil:
    section.add "X-Amz-Credential", valid_603069
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603071: Call_CreateCloudFrontOriginAccessIdentity20161125_603060;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Creates a new origin access identity. If you're using Amazon S3 for your origin, you can use an origin access identity to require users to access your content using a CloudFront URL instead of the Amazon S3 URL. For more information about how to use origin access identities, see <a href="http://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/PrivateContent.html">Serving Private Content through CloudFront</a> in the <i>Amazon CloudFront Developer Guide</i>.
  ## 
  let valid = call_603071.validator(path, query, header, formData, body)
  let scheme = call_603071.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603071.url(scheme.get, call_603071.host, call_603071.base,
                         call_603071.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603071, url, valid)

proc call*(call_603072: Call_CreateCloudFrontOriginAccessIdentity20161125_603060;
          body: JsonNode): Recallable =
  ## createCloudFrontOriginAccessIdentity20161125
  ## Creates a new origin access identity. If you're using Amazon S3 for your origin, you can use an origin access identity to require users to access your content using a CloudFront URL instead of the Amazon S3 URL. For more information about how to use origin access identities, see <a href="http://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/PrivateContent.html">Serving Private Content through CloudFront</a> in the <i>Amazon CloudFront Developer Guide</i>.
  ##   body: JObject (required)
  var body_603073 = newJObject()
  if body != nil:
    body_603073 = body
  result = call_603072.call(nil, nil, nil, nil, body_603073)

var createCloudFrontOriginAccessIdentity20161125* = Call_CreateCloudFrontOriginAccessIdentity20161125_603060(
    name: "createCloudFrontOriginAccessIdentity20161125",
    meth: HttpMethod.HttpPost, host: "cloudfront.amazonaws.com",
    route: "/2016-11-25/origin-access-identity/cloudfront",
    validator: validate_CreateCloudFrontOriginAccessIdentity20161125_603061,
    base: "/", url: url_CreateCloudFrontOriginAccessIdentity20161125_603062,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListCloudFrontOriginAccessIdentities20161125_602803 = ref object of OpenApiRestCall_602466
proc url_ListCloudFrontOriginAccessIdentities20161125_602805(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListCloudFrontOriginAccessIdentities20161125_602804(path: JsonNode;
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
  var valid_602917 = query.getOrDefault("Marker")
  valid_602917 = validateParameter(valid_602917, JString, required = false,
                                 default = nil)
  if valid_602917 != nil:
    section.add "Marker", valid_602917
  var valid_602918 = query.getOrDefault("MaxItems")
  valid_602918 = validateParameter(valid_602918, JString, required = false,
                                 default = nil)
  if valid_602918 != nil:
    section.add "MaxItems", valid_602918
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602919 = header.getOrDefault("X-Amz-Date")
  valid_602919 = validateParameter(valid_602919, JString, required = false,
                                 default = nil)
  if valid_602919 != nil:
    section.add "X-Amz-Date", valid_602919
  var valid_602920 = header.getOrDefault("X-Amz-Security-Token")
  valid_602920 = validateParameter(valid_602920, JString, required = false,
                                 default = nil)
  if valid_602920 != nil:
    section.add "X-Amz-Security-Token", valid_602920
  var valid_602921 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602921 = validateParameter(valid_602921, JString, required = false,
                                 default = nil)
  if valid_602921 != nil:
    section.add "X-Amz-Content-Sha256", valid_602921
  var valid_602922 = header.getOrDefault("X-Amz-Algorithm")
  valid_602922 = validateParameter(valid_602922, JString, required = false,
                                 default = nil)
  if valid_602922 != nil:
    section.add "X-Amz-Algorithm", valid_602922
  var valid_602923 = header.getOrDefault("X-Amz-Signature")
  valid_602923 = validateParameter(valid_602923, JString, required = false,
                                 default = nil)
  if valid_602923 != nil:
    section.add "X-Amz-Signature", valid_602923
  var valid_602924 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602924 = validateParameter(valid_602924, JString, required = false,
                                 default = nil)
  if valid_602924 != nil:
    section.add "X-Amz-SignedHeaders", valid_602924
  var valid_602925 = header.getOrDefault("X-Amz-Credential")
  valid_602925 = validateParameter(valid_602925, JString, required = false,
                                 default = nil)
  if valid_602925 != nil:
    section.add "X-Amz-Credential", valid_602925
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602948: Call_ListCloudFrontOriginAccessIdentities20161125_602803;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists origin access identities.
  ## 
  let valid = call_602948.validator(path, query, header, formData, body)
  let scheme = call_602948.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602948.url(scheme.get, call_602948.host, call_602948.base,
                         call_602948.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602948, url, valid)

proc call*(call_603019: Call_ListCloudFrontOriginAccessIdentities20161125_602803;
          Marker: string = ""; MaxItems: string = ""): Recallable =
  ## listCloudFrontOriginAccessIdentities20161125
  ## Lists origin access identities.
  ##   Marker: string
  ##         : Use this when paginating results to indicate where to begin in your list of origin access identities. The results include identities in the list that occur after the marker. To get the next page of results, set the <code>Marker</code> to the value of the <code>NextMarker</code> from the current page's response (which is also the ID of the last identity on that page).
  ##   MaxItems: string
  ##           : The maximum number of origin access identities you want in the response body. 
  var query_603020 = newJObject()
  add(query_603020, "Marker", newJString(Marker))
  add(query_603020, "MaxItems", newJString(MaxItems))
  result = call_603019.call(nil, query_603020, nil, nil, nil)

var listCloudFrontOriginAccessIdentities20161125* = Call_ListCloudFrontOriginAccessIdentities20161125_602803(
    name: "listCloudFrontOriginAccessIdentities20161125",
    meth: HttpMethod.HttpGet, host: "cloudfront.amazonaws.com",
    route: "/2016-11-25/origin-access-identity/cloudfront",
    validator: validate_ListCloudFrontOriginAccessIdentities20161125_602804,
    base: "/", url: url_ListCloudFrontOriginAccessIdentities20161125_602805,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDistribution20161125_603089 = ref object of OpenApiRestCall_602466
proc url_CreateDistribution20161125_603091(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateDistribution20161125_603090(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a new web distribution. Send a <code>GET</code> request to the <code>/<i>CloudFront API version</i>/distribution</code>/<code>distribution ID</code> resource.
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
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603092 = header.getOrDefault("X-Amz-Date")
  valid_603092 = validateParameter(valid_603092, JString, required = false,
                                 default = nil)
  if valid_603092 != nil:
    section.add "X-Amz-Date", valid_603092
  var valid_603093 = header.getOrDefault("X-Amz-Security-Token")
  valid_603093 = validateParameter(valid_603093, JString, required = false,
                                 default = nil)
  if valid_603093 != nil:
    section.add "X-Amz-Security-Token", valid_603093
  var valid_603094 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603094 = validateParameter(valid_603094, JString, required = false,
                                 default = nil)
  if valid_603094 != nil:
    section.add "X-Amz-Content-Sha256", valid_603094
  var valid_603095 = header.getOrDefault("X-Amz-Algorithm")
  valid_603095 = validateParameter(valid_603095, JString, required = false,
                                 default = nil)
  if valid_603095 != nil:
    section.add "X-Amz-Algorithm", valid_603095
  var valid_603096 = header.getOrDefault("X-Amz-Signature")
  valid_603096 = validateParameter(valid_603096, JString, required = false,
                                 default = nil)
  if valid_603096 != nil:
    section.add "X-Amz-Signature", valid_603096
  var valid_603097 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603097 = validateParameter(valid_603097, JString, required = false,
                                 default = nil)
  if valid_603097 != nil:
    section.add "X-Amz-SignedHeaders", valid_603097
  var valid_603098 = header.getOrDefault("X-Amz-Credential")
  valid_603098 = validateParameter(valid_603098, JString, required = false,
                                 default = nil)
  if valid_603098 != nil:
    section.add "X-Amz-Credential", valid_603098
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603100: Call_CreateDistribution20161125_603089; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new web distribution. Send a <code>GET</code> request to the <code>/<i>CloudFront API version</i>/distribution</code>/<code>distribution ID</code> resource.
  ## 
  let valid = call_603100.validator(path, query, header, formData, body)
  let scheme = call_603100.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603100.url(scheme.get, call_603100.host, call_603100.base,
                         call_603100.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603100, url, valid)

proc call*(call_603101: Call_CreateDistribution20161125_603089; body: JsonNode): Recallable =
  ## createDistribution20161125
  ## Creates a new web distribution. Send a <code>GET</code> request to the <code>/<i>CloudFront API version</i>/distribution</code>/<code>distribution ID</code> resource.
  ##   body: JObject (required)
  var body_603102 = newJObject()
  if body != nil:
    body_603102 = body
  result = call_603101.call(nil, nil, nil, nil, body_603102)

var createDistribution20161125* = Call_CreateDistribution20161125_603089(
    name: "createDistribution20161125", meth: HttpMethod.HttpPost,
    host: "cloudfront.amazonaws.com", route: "/2016-11-25/distribution",
    validator: validate_CreateDistribution20161125_603090, base: "/",
    url: url_CreateDistribution20161125_603091,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDistributions20161125_603074 = ref object of OpenApiRestCall_602466
proc url_ListDistributions20161125_603076(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListDistributions20161125_603075(path: JsonNode; query: JsonNode;
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
  var valid_603077 = query.getOrDefault("Marker")
  valid_603077 = validateParameter(valid_603077, JString, required = false,
                                 default = nil)
  if valid_603077 != nil:
    section.add "Marker", valid_603077
  var valid_603078 = query.getOrDefault("MaxItems")
  valid_603078 = validateParameter(valid_603078, JString, required = false,
                                 default = nil)
  if valid_603078 != nil:
    section.add "MaxItems", valid_603078
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603079 = header.getOrDefault("X-Amz-Date")
  valid_603079 = validateParameter(valid_603079, JString, required = false,
                                 default = nil)
  if valid_603079 != nil:
    section.add "X-Amz-Date", valid_603079
  var valid_603080 = header.getOrDefault("X-Amz-Security-Token")
  valid_603080 = validateParameter(valid_603080, JString, required = false,
                                 default = nil)
  if valid_603080 != nil:
    section.add "X-Amz-Security-Token", valid_603080
  var valid_603081 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603081 = validateParameter(valid_603081, JString, required = false,
                                 default = nil)
  if valid_603081 != nil:
    section.add "X-Amz-Content-Sha256", valid_603081
  var valid_603082 = header.getOrDefault("X-Amz-Algorithm")
  valid_603082 = validateParameter(valid_603082, JString, required = false,
                                 default = nil)
  if valid_603082 != nil:
    section.add "X-Amz-Algorithm", valid_603082
  var valid_603083 = header.getOrDefault("X-Amz-Signature")
  valid_603083 = validateParameter(valid_603083, JString, required = false,
                                 default = nil)
  if valid_603083 != nil:
    section.add "X-Amz-Signature", valid_603083
  var valid_603084 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603084 = validateParameter(valid_603084, JString, required = false,
                                 default = nil)
  if valid_603084 != nil:
    section.add "X-Amz-SignedHeaders", valid_603084
  var valid_603085 = header.getOrDefault("X-Amz-Credential")
  valid_603085 = validateParameter(valid_603085, JString, required = false,
                                 default = nil)
  if valid_603085 != nil:
    section.add "X-Amz-Credential", valid_603085
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603086: Call_ListDistributions20161125_603074; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List distributions. 
  ## 
  let valid = call_603086.validator(path, query, header, formData, body)
  let scheme = call_603086.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603086.url(scheme.get, call_603086.host, call_603086.base,
                         call_603086.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603086, url, valid)

proc call*(call_603087: Call_ListDistributions20161125_603074; Marker: string = "";
          MaxItems: string = ""): Recallable =
  ## listDistributions20161125
  ## List distributions. 
  ##   Marker: string
  ##         : Use this when paginating results to indicate where to begin in your list of distributions. The results include distributions in the list that occur after the marker. To get the next page of results, set the <code>Marker</code> to the value of the <code>NextMarker</code> from the current page's response (which is also the ID of the last distribution on that page).
  ##   MaxItems: string
  ##           : The maximum number of distributions you want in the response body.
  var query_603088 = newJObject()
  add(query_603088, "Marker", newJString(Marker))
  add(query_603088, "MaxItems", newJString(MaxItems))
  result = call_603087.call(nil, query_603088, nil, nil, nil)

var listDistributions20161125* = Call_ListDistributions20161125_603074(
    name: "listDistributions20161125", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com", route: "/2016-11-25/distribution",
    validator: validate_ListDistributions20161125_603075, base: "/",
    url: url_ListDistributions20161125_603076,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDistributionWithTags20161125_603103 = ref object of OpenApiRestCall_602466
proc url_CreateDistributionWithTags20161125_603105(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateDistributionWithTags20161125_603104(path: JsonNode;
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
  var valid_603106 = query.getOrDefault("WithTags")
  valid_603106 = validateParameter(valid_603106, JBool, required = true, default = nil)
  if valid_603106 != nil:
    section.add "WithTags", valid_603106
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603107 = header.getOrDefault("X-Amz-Date")
  valid_603107 = validateParameter(valid_603107, JString, required = false,
                                 default = nil)
  if valid_603107 != nil:
    section.add "X-Amz-Date", valid_603107
  var valid_603108 = header.getOrDefault("X-Amz-Security-Token")
  valid_603108 = validateParameter(valid_603108, JString, required = false,
                                 default = nil)
  if valid_603108 != nil:
    section.add "X-Amz-Security-Token", valid_603108
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

proc call*(call_603115: Call_CreateDistributionWithTags20161125_603103;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Create a new distribution with tags.
  ## 
  let valid = call_603115.validator(path, query, header, formData, body)
  let scheme = call_603115.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603115.url(scheme.get, call_603115.host, call_603115.base,
                         call_603115.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603115, url, valid)

proc call*(call_603116: Call_CreateDistributionWithTags20161125_603103;
          WithTags: bool; body: JsonNode): Recallable =
  ## createDistributionWithTags20161125
  ## Create a new distribution with tags.
  ##   WithTags: bool (required)
  ##   body: JObject (required)
  var query_603117 = newJObject()
  var body_603118 = newJObject()
  add(query_603117, "WithTags", newJBool(WithTags))
  if body != nil:
    body_603118 = body
  result = call_603116.call(nil, query_603117, nil, nil, body_603118)

var createDistributionWithTags20161125* = Call_CreateDistributionWithTags20161125_603103(
    name: "createDistributionWithTags20161125", meth: HttpMethod.HttpPost,
    host: "cloudfront.amazonaws.com", route: "/2016-11-25/distribution#WithTags",
    validator: validate_CreateDistributionWithTags20161125_603104, base: "/",
    url: url_CreateDistributionWithTags20161125_603105,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateInvalidation20161125_603150 = ref object of OpenApiRestCall_602466
proc url_CreateInvalidation20161125_603152(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "DistributionId" in path, "`DistributionId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2016-11-25/distribution/"),
               (kind: VariableSegment, value: "DistributionId"),
               (kind: ConstantSegment, value: "/invalidation")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_CreateInvalidation20161125_603151(path: JsonNode; query: JsonNode;
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
  var valid_603153 = path.getOrDefault("DistributionId")
  valid_603153 = validateParameter(valid_603153, JString, required = true,
                                 default = nil)
  if valid_603153 != nil:
    section.add "DistributionId", valid_603153
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
  var valid_603156 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603156 = validateParameter(valid_603156, JString, required = false,
                                 default = nil)
  if valid_603156 != nil:
    section.add "X-Amz-Content-Sha256", valid_603156
  var valid_603157 = header.getOrDefault("X-Amz-Algorithm")
  valid_603157 = validateParameter(valid_603157, JString, required = false,
                                 default = nil)
  if valid_603157 != nil:
    section.add "X-Amz-Algorithm", valid_603157
  var valid_603158 = header.getOrDefault("X-Amz-Signature")
  valid_603158 = validateParameter(valid_603158, JString, required = false,
                                 default = nil)
  if valid_603158 != nil:
    section.add "X-Amz-Signature", valid_603158
  var valid_603159 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603159 = validateParameter(valid_603159, JString, required = false,
                                 default = nil)
  if valid_603159 != nil:
    section.add "X-Amz-SignedHeaders", valid_603159
  var valid_603160 = header.getOrDefault("X-Amz-Credential")
  valid_603160 = validateParameter(valid_603160, JString, required = false,
                                 default = nil)
  if valid_603160 != nil:
    section.add "X-Amz-Credential", valid_603160
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603162: Call_CreateInvalidation20161125_603150; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Create a new invalidation. 
  ## 
  let valid = call_603162.validator(path, query, header, formData, body)
  let scheme = call_603162.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603162.url(scheme.get, call_603162.host, call_603162.base,
                         call_603162.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603162, url, valid)

proc call*(call_603163: Call_CreateInvalidation20161125_603150; body: JsonNode;
          DistributionId: string): Recallable =
  ## createInvalidation20161125
  ## Create a new invalidation. 
  ##   body: JObject (required)
  ##   DistributionId: string (required)
  ##                 : The distribution's id.
  var path_603164 = newJObject()
  var body_603165 = newJObject()
  if body != nil:
    body_603165 = body
  add(path_603164, "DistributionId", newJString(DistributionId))
  result = call_603163.call(path_603164, nil, nil, nil, body_603165)

var createInvalidation20161125* = Call_CreateInvalidation20161125_603150(
    name: "createInvalidation20161125", meth: HttpMethod.HttpPost,
    host: "cloudfront.amazonaws.com",
    route: "/2016-11-25/distribution/{DistributionId}/invalidation",
    validator: validate_CreateInvalidation20161125_603151, base: "/",
    url: url_CreateInvalidation20161125_603152,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListInvalidations20161125_603119 = ref object of OpenApiRestCall_602466
proc url_ListInvalidations20161125_603121(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "DistributionId" in path, "`DistributionId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2016-11-25/distribution/"),
               (kind: VariableSegment, value: "DistributionId"),
               (kind: ConstantSegment, value: "/invalidation")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_ListInvalidations20161125_603120(path: JsonNode; query: JsonNode;
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
  var valid_603136 = path.getOrDefault("DistributionId")
  valid_603136 = validateParameter(valid_603136, JString, required = true,
                                 default = nil)
  if valid_603136 != nil:
    section.add "DistributionId", valid_603136
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##         : Use this parameter when paginating results to indicate where to begin in your list of invalidation batches. Because the results are returned in decreasing order from most recent to oldest, the most recent results are on the first page, the second page will contain earlier results, and so on. To get the next page of results, set <code>Marker</code> to the value of the <code>NextMarker</code> from the current page's response. This value is the same as the ID of the last invalidation batch on that page. 
  ##   MaxItems: JString
  ##           : The maximum number of invalidation batches that you want in the response body.
  section = newJObject()
  var valid_603137 = query.getOrDefault("Marker")
  valid_603137 = validateParameter(valid_603137, JString, required = false,
                                 default = nil)
  if valid_603137 != nil:
    section.add "Marker", valid_603137
  var valid_603138 = query.getOrDefault("MaxItems")
  valid_603138 = validateParameter(valid_603138, JString, required = false,
                                 default = nil)
  if valid_603138 != nil:
    section.add "MaxItems", valid_603138
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603139 = header.getOrDefault("X-Amz-Date")
  valid_603139 = validateParameter(valid_603139, JString, required = false,
                                 default = nil)
  if valid_603139 != nil:
    section.add "X-Amz-Date", valid_603139
  var valid_603140 = header.getOrDefault("X-Amz-Security-Token")
  valid_603140 = validateParameter(valid_603140, JString, required = false,
                                 default = nil)
  if valid_603140 != nil:
    section.add "X-Amz-Security-Token", valid_603140
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
  if body != nil:
    result.add "body", body

proc call*(call_603146: Call_ListInvalidations20161125_603119; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists invalidation batches. 
  ## 
  let valid = call_603146.validator(path, query, header, formData, body)
  let scheme = call_603146.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603146.url(scheme.get, call_603146.host, call_603146.base,
                         call_603146.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603146, url, valid)

proc call*(call_603147: Call_ListInvalidations20161125_603119;
          DistributionId: string; Marker: string = ""; MaxItems: string = ""): Recallable =
  ## listInvalidations20161125
  ## Lists invalidation batches. 
  ##   Marker: string
  ##         : Use this parameter when paginating results to indicate where to begin in your list of invalidation batches. Because the results are returned in decreasing order from most recent to oldest, the most recent results are on the first page, the second page will contain earlier results, and so on. To get the next page of results, set <code>Marker</code> to the value of the <code>NextMarker</code> from the current page's response. This value is the same as the ID of the last invalidation batch on that page. 
  ##   MaxItems: string
  ##           : The maximum number of invalidation batches that you want in the response body.
  ##   DistributionId: string (required)
  ##                 : The distribution's ID.
  var path_603148 = newJObject()
  var query_603149 = newJObject()
  add(query_603149, "Marker", newJString(Marker))
  add(query_603149, "MaxItems", newJString(MaxItems))
  add(path_603148, "DistributionId", newJString(DistributionId))
  result = call_603147.call(path_603148, query_603149, nil, nil, nil)

var listInvalidations20161125* = Call_ListInvalidations20161125_603119(
    name: "listInvalidations20161125", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com",
    route: "/2016-11-25/distribution/{DistributionId}/invalidation",
    validator: validate_ListInvalidations20161125_603120, base: "/",
    url: url_ListInvalidations20161125_603121,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateStreamingDistribution20161125_603181 = ref object of OpenApiRestCall_602466
proc url_CreateStreamingDistribution20161125_603183(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateStreamingDistribution20161125_603182(path: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603184 = header.getOrDefault("X-Amz-Date")
  valid_603184 = validateParameter(valid_603184, JString, required = false,
                                 default = nil)
  if valid_603184 != nil:
    section.add "X-Amz-Date", valid_603184
  var valid_603185 = header.getOrDefault("X-Amz-Security-Token")
  valid_603185 = validateParameter(valid_603185, JString, required = false,
                                 default = nil)
  if valid_603185 != nil:
    section.add "X-Amz-Security-Token", valid_603185
  var valid_603186 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603186 = validateParameter(valid_603186, JString, required = false,
                                 default = nil)
  if valid_603186 != nil:
    section.add "X-Amz-Content-Sha256", valid_603186
  var valid_603187 = header.getOrDefault("X-Amz-Algorithm")
  valid_603187 = validateParameter(valid_603187, JString, required = false,
                                 default = nil)
  if valid_603187 != nil:
    section.add "X-Amz-Algorithm", valid_603187
  var valid_603188 = header.getOrDefault("X-Amz-Signature")
  valid_603188 = validateParameter(valid_603188, JString, required = false,
                                 default = nil)
  if valid_603188 != nil:
    section.add "X-Amz-Signature", valid_603188
  var valid_603189 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603189 = validateParameter(valid_603189, JString, required = false,
                                 default = nil)
  if valid_603189 != nil:
    section.add "X-Amz-SignedHeaders", valid_603189
  var valid_603190 = header.getOrDefault("X-Amz-Credential")
  valid_603190 = validateParameter(valid_603190, JString, required = false,
                                 default = nil)
  if valid_603190 != nil:
    section.add "X-Amz-Credential", valid_603190
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603192: Call_CreateStreamingDistribution20161125_603181;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Creates a new RMTP distribution. An RTMP distribution is similar to a web distribution, but an RTMP distribution streams media files using the Adobe Real-Time Messaging Protocol (RTMP) instead of serving files using HTTP. </p> <p>To create a new web distribution, submit a <code>POST</code> request to the <i>CloudFront API version</i>/distribution resource. The request body must include a document with a <i>StreamingDistributionConfig</i> element. The response echoes the <code>StreamingDistributionConfig</code> element and returns other information about the RTMP distribution.</p> <p>To get the status of your request, use the <i>GET StreamingDistribution</i> API action. When the value of <code>Enabled</code> is <code>true</code> and the value of <code>Status</code> is <code>Deployed</code>, your distribution is ready. A distribution usually deploys in less than 15 minutes.</p> <p>For more information about web distributions, see <a href="http://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/distribution-rtmp.html">Working with RTMP Distributions</a> in the <i>Amazon CloudFront Developer Guide</i>.</p> <important> <p>Beginning with the 2012-05-05 version of the CloudFront API, we made substantial changes to the format of the XML document that you include in the request body when you create or update a web distribution or an RTMP distribution, and when you invalidate objects. With previous versions of the API, we discovered that it was too easy to accidentally delete one or more values for an element that accepts multiple values, for example, CNAMEs and trusted signers. Our changes for the 2012-05-05 release are intended to prevent these accidental deletions and to notify you when there's a mismatch between the number of values you say you're specifying in the <code>Quantity</code> element and the number of values specified.</p> </important>
  ## 
  let valid = call_603192.validator(path, query, header, formData, body)
  let scheme = call_603192.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603192.url(scheme.get, call_603192.host, call_603192.base,
                         call_603192.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603192, url, valid)

proc call*(call_603193: Call_CreateStreamingDistribution20161125_603181;
          body: JsonNode): Recallable =
  ## createStreamingDistribution20161125
  ## <p>Creates a new RMTP distribution. An RTMP distribution is similar to a web distribution, but an RTMP distribution streams media files using the Adobe Real-Time Messaging Protocol (RTMP) instead of serving files using HTTP. </p> <p>To create a new web distribution, submit a <code>POST</code> request to the <i>CloudFront API version</i>/distribution resource. The request body must include a document with a <i>StreamingDistributionConfig</i> element. The response echoes the <code>StreamingDistributionConfig</code> element and returns other information about the RTMP distribution.</p> <p>To get the status of your request, use the <i>GET StreamingDistribution</i> API action. When the value of <code>Enabled</code> is <code>true</code> and the value of <code>Status</code> is <code>Deployed</code>, your distribution is ready. A distribution usually deploys in less than 15 minutes.</p> <p>For more information about web distributions, see <a href="http://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/distribution-rtmp.html">Working with RTMP Distributions</a> in the <i>Amazon CloudFront Developer Guide</i>.</p> <important> <p>Beginning with the 2012-05-05 version of the CloudFront API, we made substantial changes to the format of the XML document that you include in the request body when you create or update a web distribution or an RTMP distribution, and when you invalidate objects. With previous versions of the API, we discovered that it was too easy to accidentally delete one or more values for an element that accepts multiple values, for example, CNAMEs and trusted signers. Our changes for the 2012-05-05 release are intended to prevent these accidental deletions and to notify you when there's a mismatch between the number of values you say you're specifying in the <code>Quantity</code> element and the number of values specified.</p> </important>
  ##   body: JObject (required)
  var body_603194 = newJObject()
  if body != nil:
    body_603194 = body
  result = call_603193.call(nil, nil, nil, nil, body_603194)

var createStreamingDistribution20161125* = Call_CreateStreamingDistribution20161125_603181(
    name: "createStreamingDistribution20161125", meth: HttpMethod.HttpPost,
    host: "cloudfront.amazonaws.com", route: "/2016-11-25/streaming-distribution",
    validator: validate_CreateStreamingDistribution20161125_603182, base: "/",
    url: url_CreateStreamingDistribution20161125_603183,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListStreamingDistributions20161125_603166 = ref object of OpenApiRestCall_602466
proc url_ListStreamingDistributions20161125_603168(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListStreamingDistributions20161125_603167(path: JsonNode;
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
  var valid_603169 = query.getOrDefault("Marker")
  valid_603169 = validateParameter(valid_603169, JString, required = false,
                                 default = nil)
  if valid_603169 != nil:
    section.add "Marker", valid_603169
  var valid_603170 = query.getOrDefault("MaxItems")
  valid_603170 = validateParameter(valid_603170, JString, required = false,
                                 default = nil)
  if valid_603170 != nil:
    section.add "MaxItems", valid_603170
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603171 = header.getOrDefault("X-Amz-Date")
  valid_603171 = validateParameter(valid_603171, JString, required = false,
                                 default = nil)
  if valid_603171 != nil:
    section.add "X-Amz-Date", valid_603171
  var valid_603172 = header.getOrDefault("X-Amz-Security-Token")
  valid_603172 = validateParameter(valid_603172, JString, required = false,
                                 default = nil)
  if valid_603172 != nil:
    section.add "X-Amz-Security-Token", valid_603172
  var valid_603173 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603173 = validateParameter(valid_603173, JString, required = false,
                                 default = nil)
  if valid_603173 != nil:
    section.add "X-Amz-Content-Sha256", valid_603173
  var valid_603174 = header.getOrDefault("X-Amz-Algorithm")
  valid_603174 = validateParameter(valid_603174, JString, required = false,
                                 default = nil)
  if valid_603174 != nil:
    section.add "X-Amz-Algorithm", valid_603174
  var valid_603175 = header.getOrDefault("X-Amz-Signature")
  valid_603175 = validateParameter(valid_603175, JString, required = false,
                                 default = nil)
  if valid_603175 != nil:
    section.add "X-Amz-Signature", valid_603175
  var valid_603176 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603176 = validateParameter(valid_603176, JString, required = false,
                                 default = nil)
  if valid_603176 != nil:
    section.add "X-Amz-SignedHeaders", valid_603176
  var valid_603177 = header.getOrDefault("X-Amz-Credential")
  valid_603177 = validateParameter(valid_603177, JString, required = false,
                                 default = nil)
  if valid_603177 != nil:
    section.add "X-Amz-Credential", valid_603177
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603178: Call_ListStreamingDistributions20161125_603166;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## List streaming distributions. 
  ## 
  let valid = call_603178.validator(path, query, header, formData, body)
  let scheme = call_603178.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603178.url(scheme.get, call_603178.host, call_603178.base,
                         call_603178.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603178, url, valid)

proc call*(call_603179: Call_ListStreamingDistributions20161125_603166;
          Marker: string = ""; MaxItems: string = ""): Recallable =
  ## listStreamingDistributions20161125
  ## List streaming distributions. 
  ##   Marker: string
  ##         : The value that you provided for the <code>Marker</code> request parameter.
  ##   MaxItems: string
  ##           : The value that you provided for the <code>MaxItems</code> request parameter.
  var query_603180 = newJObject()
  add(query_603180, "Marker", newJString(Marker))
  add(query_603180, "MaxItems", newJString(MaxItems))
  result = call_603179.call(nil, query_603180, nil, nil, nil)

var listStreamingDistributions20161125* = Call_ListStreamingDistributions20161125_603166(
    name: "listStreamingDistributions20161125", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com", route: "/2016-11-25/streaming-distribution",
    validator: validate_ListStreamingDistributions20161125_603167, base: "/",
    url: url_ListStreamingDistributions20161125_603168,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateStreamingDistributionWithTags20161125_603195 = ref object of OpenApiRestCall_602466
proc url_CreateStreamingDistributionWithTags20161125_603197(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateStreamingDistributionWithTags20161125_603196(path: JsonNode;
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
  var valid_603198 = query.getOrDefault("WithTags")
  valid_603198 = validateParameter(valid_603198, JBool, required = true, default = nil)
  if valid_603198 != nil:
    section.add "WithTags", valid_603198
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603199 = header.getOrDefault("X-Amz-Date")
  valid_603199 = validateParameter(valid_603199, JString, required = false,
                                 default = nil)
  if valid_603199 != nil:
    section.add "X-Amz-Date", valid_603199
  var valid_603200 = header.getOrDefault("X-Amz-Security-Token")
  valid_603200 = validateParameter(valid_603200, JString, required = false,
                                 default = nil)
  if valid_603200 != nil:
    section.add "X-Amz-Security-Token", valid_603200
  var valid_603201 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603201 = validateParameter(valid_603201, JString, required = false,
                                 default = nil)
  if valid_603201 != nil:
    section.add "X-Amz-Content-Sha256", valid_603201
  var valid_603202 = header.getOrDefault("X-Amz-Algorithm")
  valid_603202 = validateParameter(valid_603202, JString, required = false,
                                 default = nil)
  if valid_603202 != nil:
    section.add "X-Amz-Algorithm", valid_603202
  var valid_603203 = header.getOrDefault("X-Amz-Signature")
  valid_603203 = validateParameter(valid_603203, JString, required = false,
                                 default = nil)
  if valid_603203 != nil:
    section.add "X-Amz-Signature", valid_603203
  var valid_603204 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603204 = validateParameter(valid_603204, JString, required = false,
                                 default = nil)
  if valid_603204 != nil:
    section.add "X-Amz-SignedHeaders", valid_603204
  var valid_603205 = header.getOrDefault("X-Amz-Credential")
  valid_603205 = validateParameter(valid_603205, JString, required = false,
                                 default = nil)
  if valid_603205 != nil:
    section.add "X-Amz-Credential", valid_603205
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603207: Call_CreateStreamingDistributionWithTags20161125_603195;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Create a new streaming distribution with tags.
  ## 
  let valid = call_603207.validator(path, query, header, formData, body)
  let scheme = call_603207.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603207.url(scheme.get, call_603207.host, call_603207.base,
                         call_603207.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603207, url, valid)

proc call*(call_603208: Call_CreateStreamingDistributionWithTags20161125_603195;
          WithTags: bool; body: JsonNode): Recallable =
  ## createStreamingDistributionWithTags20161125
  ## Create a new streaming distribution with tags.
  ##   WithTags: bool (required)
  ##   body: JObject (required)
  var query_603209 = newJObject()
  var body_603210 = newJObject()
  add(query_603209, "WithTags", newJBool(WithTags))
  if body != nil:
    body_603210 = body
  result = call_603208.call(nil, query_603209, nil, nil, body_603210)

var createStreamingDistributionWithTags20161125* = Call_CreateStreamingDistributionWithTags20161125_603195(
    name: "createStreamingDistributionWithTags20161125",
    meth: HttpMethod.HttpPost, host: "cloudfront.amazonaws.com",
    route: "/2016-11-25/streaming-distribution#WithTags",
    validator: validate_CreateStreamingDistributionWithTags20161125_603196,
    base: "/", url: url_CreateStreamingDistributionWithTags20161125_603197,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCloudFrontOriginAccessIdentity20161125_603211 = ref object of OpenApiRestCall_602466
proc url_GetCloudFrontOriginAccessIdentity20161125_603213(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                value: "/2016-11-25/origin-access-identity/cloudfront/"),
               (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_GetCloudFrontOriginAccessIdentity20161125_603212(path: JsonNode;
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
  var valid_603214 = path.getOrDefault("Id")
  valid_603214 = validateParameter(valid_603214, JString, required = true,
                                 default = nil)
  if valid_603214 != nil:
    section.add "Id", valid_603214
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
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603215 = header.getOrDefault("X-Amz-Date")
  valid_603215 = validateParameter(valid_603215, JString, required = false,
                                 default = nil)
  if valid_603215 != nil:
    section.add "X-Amz-Date", valid_603215
  var valid_603216 = header.getOrDefault("X-Amz-Security-Token")
  valid_603216 = validateParameter(valid_603216, JString, required = false,
                                 default = nil)
  if valid_603216 != nil:
    section.add "X-Amz-Security-Token", valid_603216
  var valid_603217 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603217 = validateParameter(valid_603217, JString, required = false,
                                 default = nil)
  if valid_603217 != nil:
    section.add "X-Amz-Content-Sha256", valid_603217
  var valid_603218 = header.getOrDefault("X-Amz-Algorithm")
  valid_603218 = validateParameter(valid_603218, JString, required = false,
                                 default = nil)
  if valid_603218 != nil:
    section.add "X-Amz-Algorithm", valid_603218
  var valid_603219 = header.getOrDefault("X-Amz-Signature")
  valid_603219 = validateParameter(valid_603219, JString, required = false,
                                 default = nil)
  if valid_603219 != nil:
    section.add "X-Amz-Signature", valid_603219
  var valid_603220 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603220 = validateParameter(valid_603220, JString, required = false,
                                 default = nil)
  if valid_603220 != nil:
    section.add "X-Amz-SignedHeaders", valid_603220
  var valid_603221 = header.getOrDefault("X-Amz-Credential")
  valid_603221 = validateParameter(valid_603221, JString, required = false,
                                 default = nil)
  if valid_603221 != nil:
    section.add "X-Amz-Credential", valid_603221
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603222: Call_GetCloudFrontOriginAccessIdentity20161125_603211;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Get the information about an origin access identity. 
  ## 
  let valid = call_603222.validator(path, query, header, formData, body)
  let scheme = call_603222.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603222.url(scheme.get, call_603222.host, call_603222.base,
                         call_603222.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603222, url, valid)

proc call*(call_603223: Call_GetCloudFrontOriginAccessIdentity20161125_603211;
          Id: string): Recallable =
  ## getCloudFrontOriginAccessIdentity20161125
  ## Get the information about an origin access identity. 
  ##   Id: string (required)
  ##     : The identity's ID.
  var path_603224 = newJObject()
  add(path_603224, "Id", newJString(Id))
  result = call_603223.call(path_603224, nil, nil, nil, nil)

var getCloudFrontOriginAccessIdentity20161125* = Call_GetCloudFrontOriginAccessIdentity20161125_603211(
    name: "getCloudFrontOriginAccessIdentity20161125", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com",
    route: "/2016-11-25/origin-access-identity/cloudfront/{Id}",
    validator: validate_GetCloudFrontOriginAccessIdentity20161125_603212,
    base: "/", url: url_GetCloudFrontOriginAccessIdentity20161125_603213,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteCloudFrontOriginAccessIdentity20161125_603225 = ref object of OpenApiRestCall_602466
proc url_DeleteCloudFrontOriginAccessIdentity20161125_603227(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                value: "/2016-11-25/origin-access-identity/cloudfront/"),
               (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_DeleteCloudFrontOriginAccessIdentity20161125_603226(path: JsonNode;
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
  var valid_603228 = path.getOrDefault("Id")
  valid_603228 = validateParameter(valid_603228, JString, required = true,
                                 default = nil)
  if valid_603228 != nil:
    section.add "Id", valid_603228
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   If-Match: JString
  ##           : The value of the <code>ETag</code> header you received from a previous <code>GET</code> or <code>PUT</code> request. For example: <code>E2QWRUHAPOMQZL</code>.
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603229 = header.getOrDefault("X-Amz-Date")
  valid_603229 = validateParameter(valid_603229, JString, required = false,
                                 default = nil)
  if valid_603229 != nil:
    section.add "X-Amz-Date", valid_603229
  var valid_603230 = header.getOrDefault("X-Amz-Security-Token")
  valid_603230 = validateParameter(valid_603230, JString, required = false,
                                 default = nil)
  if valid_603230 != nil:
    section.add "X-Amz-Security-Token", valid_603230
  var valid_603231 = header.getOrDefault("If-Match")
  valid_603231 = validateParameter(valid_603231, JString, required = false,
                                 default = nil)
  if valid_603231 != nil:
    section.add "If-Match", valid_603231
  var valid_603232 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603232 = validateParameter(valid_603232, JString, required = false,
                                 default = nil)
  if valid_603232 != nil:
    section.add "X-Amz-Content-Sha256", valid_603232
  var valid_603233 = header.getOrDefault("X-Amz-Algorithm")
  valid_603233 = validateParameter(valid_603233, JString, required = false,
                                 default = nil)
  if valid_603233 != nil:
    section.add "X-Amz-Algorithm", valid_603233
  var valid_603234 = header.getOrDefault("X-Amz-Signature")
  valid_603234 = validateParameter(valid_603234, JString, required = false,
                                 default = nil)
  if valid_603234 != nil:
    section.add "X-Amz-Signature", valid_603234
  var valid_603235 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603235 = validateParameter(valid_603235, JString, required = false,
                                 default = nil)
  if valid_603235 != nil:
    section.add "X-Amz-SignedHeaders", valid_603235
  var valid_603236 = header.getOrDefault("X-Amz-Credential")
  valid_603236 = validateParameter(valid_603236, JString, required = false,
                                 default = nil)
  if valid_603236 != nil:
    section.add "X-Amz-Credential", valid_603236
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603237: Call_DeleteCloudFrontOriginAccessIdentity20161125_603225;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Delete an origin access identity. 
  ## 
  let valid = call_603237.validator(path, query, header, formData, body)
  let scheme = call_603237.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603237.url(scheme.get, call_603237.host, call_603237.base,
                         call_603237.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603237, url, valid)

proc call*(call_603238: Call_DeleteCloudFrontOriginAccessIdentity20161125_603225;
          Id: string): Recallable =
  ## deleteCloudFrontOriginAccessIdentity20161125
  ## Delete an origin access identity. 
  ##   Id: string (required)
  ##     : The origin access identity's ID.
  var path_603239 = newJObject()
  add(path_603239, "Id", newJString(Id))
  result = call_603238.call(path_603239, nil, nil, nil, nil)

var deleteCloudFrontOriginAccessIdentity20161125* = Call_DeleteCloudFrontOriginAccessIdentity20161125_603225(
    name: "deleteCloudFrontOriginAccessIdentity20161125",
    meth: HttpMethod.HttpDelete, host: "cloudfront.amazonaws.com",
    route: "/2016-11-25/origin-access-identity/cloudfront/{Id}",
    validator: validate_DeleteCloudFrontOriginAccessIdentity20161125_603226,
    base: "/", url: url_DeleteCloudFrontOriginAccessIdentity20161125_603227,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDistribution20161125_603240 = ref object of OpenApiRestCall_602466
proc url_GetDistribution20161125_603242(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2016-11-25/distribution/"),
               (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_GetDistribution20161125_603241(path: JsonNode; query: JsonNode;
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
  var valid_603243 = path.getOrDefault("Id")
  valid_603243 = validateParameter(valid_603243, JString, required = true,
                                 default = nil)
  if valid_603243 != nil:
    section.add "Id", valid_603243
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
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603244 = header.getOrDefault("X-Amz-Date")
  valid_603244 = validateParameter(valid_603244, JString, required = false,
                                 default = nil)
  if valid_603244 != nil:
    section.add "X-Amz-Date", valid_603244
  var valid_603245 = header.getOrDefault("X-Amz-Security-Token")
  valid_603245 = validateParameter(valid_603245, JString, required = false,
                                 default = nil)
  if valid_603245 != nil:
    section.add "X-Amz-Security-Token", valid_603245
  var valid_603246 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603246 = validateParameter(valid_603246, JString, required = false,
                                 default = nil)
  if valid_603246 != nil:
    section.add "X-Amz-Content-Sha256", valid_603246
  var valid_603247 = header.getOrDefault("X-Amz-Algorithm")
  valid_603247 = validateParameter(valid_603247, JString, required = false,
                                 default = nil)
  if valid_603247 != nil:
    section.add "X-Amz-Algorithm", valid_603247
  var valid_603248 = header.getOrDefault("X-Amz-Signature")
  valid_603248 = validateParameter(valid_603248, JString, required = false,
                                 default = nil)
  if valid_603248 != nil:
    section.add "X-Amz-Signature", valid_603248
  var valid_603249 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603249 = validateParameter(valid_603249, JString, required = false,
                                 default = nil)
  if valid_603249 != nil:
    section.add "X-Amz-SignedHeaders", valid_603249
  var valid_603250 = header.getOrDefault("X-Amz-Credential")
  valid_603250 = validateParameter(valid_603250, JString, required = false,
                                 default = nil)
  if valid_603250 != nil:
    section.add "X-Amz-Credential", valid_603250
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603251: Call_GetDistribution20161125_603240; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Get the information about a distribution. 
  ## 
  let valid = call_603251.validator(path, query, header, formData, body)
  let scheme = call_603251.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603251.url(scheme.get, call_603251.host, call_603251.base,
                         call_603251.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603251, url, valid)

proc call*(call_603252: Call_GetDistribution20161125_603240; Id: string): Recallable =
  ## getDistribution20161125
  ## Get the information about a distribution. 
  ##   Id: string (required)
  ##     : The distribution's ID.
  var path_603253 = newJObject()
  add(path_603253, "Id", newJString(Id))
  result = call_603252.call(path_603253, nil, nil, nil, nil)

var getDistribution20161125* = Call_GetDistribution20161125_603240(
    name: "getDistribution20161125", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com", route: "/2016-11-25/distribution/{Id}",
    validator: validate_GetDistribution20161125_603241, base: "/",
    url: url_GetDistribution20161125_603242, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDistribution20161125_603254 = ref object of OpenApiRestCall_602466
proc url_DeleteDistribution20161125_603256(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2016-11-25/distribution/"),
               (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_DeleteDistribution20161125_603255(path: JsonNode; query: JsonNode;
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
  var valid_603257 = path.getOrDefault("Id")
  valid_603257 = validateParameter(valid_603257, JString, required = true,
                                 default = nil)
  if valid_603257 != nil:
    section.add "Id", valid_603257
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   If-Match: JString
  ##           : The value of the <code>ETag</code> header that you received when you disabled the distribution. For example: <code>E2QWRUHAPOMQZL</code>. 
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603258 = header.getOrDefault("X-Amz-Date")
  valid_603258 = validateParameter(valid_603258, JString, required = false,
                                 default = nil)
  if valid_603258 != nil:
    section.add "X-Amz-Date", valid_603258
  var valid_603259 = header.getOrDefault("X-Amz-Security-Token")
  valid_603259 = validateParameter(valid_603259, JString, required = false,
                                 default = nil)
  if valid_603259 != nil:
    section.add "X-Amz-Security-Token", valid_603259
  var valid_603260 = header.getOrDefault("If-Match")
  valid_603260 = validateParameter(valid_603260, JString, required = false,
                                 default = nil)
  if valid_603260 != nil:
    section.add "If-Match", valid_603260
  var valid_603261 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603261 = validateParameter(valid_603261, JString, required = false,
                                 default = nil)
  if valid_603261 != nil:
    section.add "X-Amz-Content-Sha256", valid_603261
  var valid_603262 = header.getOrDefault("X-Amz-Algorithm")
  valid_603262 = validateParameter(valid_603262, JString, required = false,
                                 default = nil)
  if valid_603262 != nil:
    section.add "X-Amz-Algorithm", valid_603262
  var valid_603263 = header.getOrDefault("X-Amz-Signature")
  valid_603263 = validateParameter(valid_603263, JString, required = false,
                                 default = nil)
  if valid_603263 != nil:
    section.add "X-Amz-Signature", valid_603263
  var valid_603264 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603264 = validateParameter(valid_603264, JString, required = false,
                                 default = nil)
  if valid_603264 != nil:
    section.add "X-Amz-SignedHeaders", valid_603264
  var valid_603265 = header.getOrDefault("X-Amz-Credential")
  valid_603265 = validateParameter(valid_603265, JString, required = false,
                                 default = nil)
  if valid_603265 != nil:
    section.add "X-Amz-Credential", valid_603265
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603266: Call_DeleteDistribution20161125_603254; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Delete a distribution. 
  ## 
  let valid = call_603266.validator(path, query, header, formData, body)
  let scheme = call_603266.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603266.url(scheme.get, call_603266.host, call_603266.base,
                         call_603266.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603266, url, valid)

proc call*(call_603267: Call_DeleteDistribution20161125_603254; Id: string): Recallable =
  ## deleteDistribution20161125
  ## Delete a distribution. 
  ##   Id: string (required)
  ##     : The distribution ID. 
  var path_603268 = newJObject()
  add(path_603268, "Id", newJString(Id))
  result = call_603267.call(path_603268, nil, nil, nil, nil)

var deleteDistribution20161125* = Call_DeleteDistribution20161125_603254(
    name: "deleteDistribution20161125", meth: HttpMethod.HttpDelete,
    host: "cloudfront.amazonaws.com", route: "/2016-11-25/distribution/{Id}",
    validator: validate_DeleteDistribution20161125_603255, base: "/",
    url: url_DeleteDistribution20161125_603256,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetStreamingDistribution20161125_603269 = ref object of OpenApiRestCall_602466
proc url_GetStreamingDistribution20161125_603271(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                value: "/2016-11-25/streaming-distribution/"),
               (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_GetStreamingDistribution20161125_603270(path: JsonNode;
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
  var valid_603272 = path.getOrDefault("Id")
  valid_603272 = validateParameter(valid_603272, JString, required = true,
                                 default = nil)
  if valid_603272 != nil:
    section.add "Id", valid_603272
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
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603273 = header.getOrDefault("X-Amz-Date")
  valid_603273 = validateParameter(valid_603273, JString, required = false,
                                 default = nil)
  if valid_603273 != nil:
    section.add "X-Amz-Date", valid_603273
  var valid_603274 = header.getOrDefault("X-Amz-Security-Token")
  valid_603274 = validateParameter(valid_603274, JString, required = false,
                                 default = nil)
  if valid_603274 != nil:
    section.add "X-Amz-Security-Token", valid_603274
  var valid_603275 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603275 = validateParameter(valid_603275, JString, required = false,
                                 default = nil)
  if valid_603275 != nil:
    section.add "X-Amz-Content-Sha256", valid_603275
  var valid_603276 = header.getOrDefault("X-Amz-Algorithm")
  valid_603276 = validateParameter(valid_603276, JString, required = false,
                                 default = nil)
  if valid_603276 != nil:
    section.add "X-Amz-Algorithm", valid_603276
  var valid_603277 = header.getOrDefault("X-Amz-Signature")
  valid_603277 = validateParameter(valid_603277, JString, required = false,
                                 default = nil)
  if valid_603277 != nil:
    section.add "X-Amz-Signature", valid_603277
  var valid_603278 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603278 = validateParameter(valid_603278, JString, required = false,
                                 default = nil)
  if valid_603278 != nil:
    section.add "X-Amz-SignedHeaders", valid_603278
  var valid_603279 = header.getOrDefault("X-Amz-Credential")
  valid_603279 = validateParameter(valid_603279, JString, required = false,
                                 default = nil)
  if valid_603279 != nil:
    section.add "X-Amz-Credential", valid_603279
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603280: Call_GetStreamingDistribution20161125_603269;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Gets information about a specified RTMP distribution, including the distribution configuration.
  ## 
  let valid = call_603280.validator(path, query, header, formData, body)
  let scheme = call_603280.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603280.url(scheme.get, call_603280.host, call_603280.base,
                         call_603280.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603280, url, valid)

proc call*(call_603281: Call_GetStreamingDistribution20161125_603269; Id: string): Recallable =
  ## getStreamingDistribution20161125
  ## Gets information about a specified RTMP distribution, including the distribution configuration.
  ##   Id: string (required)
  ##     : The streaming distribution's ID.
  var path_603282 = newJObject()
  add(path_603282, "Id", newJString(Id))
  result = call_603281.call(path_603282, nil, nil, nil, nil)

var getStreamingDistribution20161125* = Call_GetStreamingDistribution20161125_603269(
    name: "getStreamingDistribution20161125", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com",
    route: "/2016-11-25/streaming-distribution/{Id}",
    validator: validate_GetStreamingDistribution20161125_603270, base: "/",
    url: url_GetStreamingDistribution20161125_603271,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteStreamingDistribution20161125_603283 = ref object of OpenApiRestCall_602466
proc url_DeleteStreamingDistribution20161125_603285(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                value: "/2016-11-25/streaming-distribution/"),
               (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_DeleteStreamingDistribution20161125_603284(path: JsonNode;
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
  var valid_603286 = path.getOrDefault("Id")
  valid_603286 = validateParameter(valid_603286, JString, required = true,
                                 default = nil)
  if valid_603286 != nil:
    section.add "Id", valid_603286
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   If-Match: JString
  ##           : The value of the <code>ETag</code> header that you received when you disabled the streaming distribution. For example: <code>E2QWRUHAPOMQZL</code>.
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603287 = header.getOrDefault("X-Amz-Date")
  valid_603287 = validateParameter(valid_603287, JString, required = false,
                                 default = nil)
  if valid_603287 != nil:
    section.add "X-Amz-Date", valid_603287
  var valid_603288 = header.getOrDefault("X-Amz-Security-Token")
  valid_603288 = validateParameter(valid_603288, JString, required = false,
                                 default = nil)
  if valid_603288 != nil:
    section.add "X-Amz-Security-Token", valid_603288
  var valid_603289 = header.getOrDefault("If-Match")
  valid_603289 = validateParameter(valid_603289, JString, required = false,
                                 default = nil)
  if valid_603289 != nil:
    section.add "If-Match", valid_603289
  var valid_603290 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603290 = validateParameter(valid_603290, JString, required = false,
                                 default = nil)
  if valid_603290 != nil:
    section.add "X-Amz-Content-Sha256", valid_603290
  var valid_603291 = header.getOrDefault("X-Amz-Algorithm")
  valid_603291 = validateParameter(valid_603291, JString, required = false,
                                 default = nil)
  if valid_603291 != nil:
    section.add "X-Amz-Algorithm", valid_603291
  var valid_603292 = header.getOrDefault("X-Amz-Signature")
  valid_603292 = validateParameter(valid_603292, JString, required = false,
                                 default = nil)
  if valid_603292 != nil:
    section.add "X-Amz-Signature", valid_603292
  var valid_603293 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603293 = validateParameter(valid_603293, JString, required = false,
                                 default = nil)
  if valid_603293 != nil:
    section.add "X-Amz-SignedHeaders", valid_603293
  var valid_603294 = header.getOrDefault("X-Amz-Credential")
  valid_603294 = validateParameter(valid_603294, JString, required = false,
                                 default = nil)
  if valid_603294 != nil:
    section.add "X-Amz-Credential", valid_603294
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603295: Call_DeleteStreamingDistribution20161125_603283;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Delete a streaming distribution. To delete an RTMP distribution using the CloudFront API, perform the following steps.</p> <p> <b>To delete an RTMP distribution using the CloudFront API</b>:</p> <ol> <li> <p>Disable the RTMP distribution.</p> </li> <li> <p>Submit a <code>GET Streaming Distribution Config</code> request to get the current configuration and the <code>Etag</code> header for the distribution. </p> </li> <li> <p>Update the XML document that was returned in the response to your <code>GET Streaming Distribution Config</code> request to change the value of <code>Enabled</code> to <code>false</code>.</p> </li> <li> <p>Submit a <code>PUT Streaming Distribution Config</code> request to update the configuration for your distribution. In the request body, include the XML document that you updated in Step 3. Then set the value of the HTTP <code>If-Match</code> header to the value of the <code>ETag</code> header that CloudFront returned when you submitted the <code>GET Streaming Distribution Config</code> request in Step 2.</p> </li> <li> <p>Review the response to the <code>PUT Streaming Distribution Config</code> request to confirm that the distribution was successfully disabled.</p> </li> <li> <p>Submit a <code>GET Streaming Distribution Config</code> request to confirm that your changes have propagated. When propagation is complete, the value of <code>Status</code> is <code>Deployed</code>.</p> </li> <li> <p>Submit a <code>DELETE Streaming Distribution</code> request. Set the value of the HTTP <code>If-Match</code> header to the value of the <code>ETag</code> header that CloudFront returned when you submitted the <code>GET Streaming Distribution Config</code> request in Step 2.</p> </li> <li> <p>Review the response to your <code>DELETE Streaming Distribution</code> request to confirm that the distribution was successfully deleted.</p> </li> </ol> <p>For information about deleting a distribution using the CloudFront console, see <a href="http://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/HowToDeleteDistribution.html">Deleting a Distribution</a> in the <i>Amazon CloudFront Developer Guide</i>.</p>
  ## 
  let valid = call_603295.validator(path, query, header, formData, body)
  let scheme = call_603295.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603295.url(scheme.get, call_603295.host, call_603295.base,
                         call_603295.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603295, url, valid)

proc call*(call_603296: Call_DeleteStreamingDistribution20161125_603283; Id: string): Recallable =
  ## deleteStreamingDistribution20161125
  ## <p>Delete a streaming distribution. To delete an RTMP distribution using the CloudFront API, perform the following steps.</p> <p> <b>To delete an RTMP distribution using the CloudFront API</b>:</p> <ol> <li> <p>Disable the RTMP distribution.</p> </li> <li> <p>Submit a <code>GET Streaming Distribution Config</code> request to get the current configuration and the <code>Etag</code> header for the distribution. </p> </li> <li> <p>Update the XML document that was returned in the response to your <code>GET Streaming Distribution Config</code> request to change the value of <code>Enabled</code> to <code>false</code>.</p> </li> <li> <p>Submit a <code>PUT Streaming Distribution Config</code> request to update the configuration for your distribution. In the request body, include the XML document that you updated in Step 3. Then set the value of the HTTP <code>If-Match</code> header to the value of the <code>ETag</code> header that CloudFront returned when you submitted the <code>GET Streaming Distribution Config</code> request in Step 2.</p> </li> <li> <p>Review the response to the <code>PUT Streaming Distribution Config</code> request to confirm that the distribution was successfully disabled.</p> </li> <li> <p>Submit a <code>GET Streaming Distribution Config</code> request to confirm that your changes have propagated. When propagation is complete, the value of <code>Status</code> is <code>Deployed</code>.</p> </li> <li> <p>Submit a <code>DELETE Streaming Distribution</code> request. Set the value of the HTTP <code>If-Match</code> header to the value of the <code>ETag</code> header that CloudFront returned when you submitted the <code>GET Streaming Distribution Config</code> request in Step 2.</p> </li> <li> <p>Review the response to your <code>DELETE Streaming Distribution</code> request to confirm that the distribution was successfully deleted.</p> </li> </ol> <p>For information about deleting a distribution using the CloudFront console, see <a href="http://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/HowToDeleteDistribution.html">Deleting a Distribution</a> in the <i>Amazon CloudFront Developer Guide</i>.</p>
  ##   Id: string (required)
  ##     : The distribution ID. 
  var path_603297 = newJObject()
  add(path_603297, "Id", newJString(Id))
  result = call_603296.call(path_603297, nil, nil, nil, nil)

var deleteStreamingDistribution20161125* = Call_DeleteStreamingDistribution20161125_603283(
    name: "deleteStreamingDistribution20161125", meth: HttpMethod.HttpDelete,
    host: "cloudfront.amazonaws.com",
    route: "/2016-11-25/streaming-distribution/{Id}",
    validator: validate_DeleteStreamingDistribution20161125_603284, base: "/",
    url: url_DeleteStreamingDistribution20161125_603285,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateCloudFrontOriginAccessIdentity20161125_603312 = ref object of OpenApiRestCall_602466
proc url_UpdateCloudFrontOriginAccessIdentity20161125_603314(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                value: "/2016-11-25/origin-access-identity/cloudfront/"),
               (kind: VariableSegment, value: "Id"),
               (kind: ConstantSegment, value: "/config")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_UpdateCloudFrontOriginAccessIdentity20161125_603313(path: JsonNode;
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
  var valid_603315 = path.getOrDefault("Id")
  valid_603315 = validateParameter(valid_603315, JString, required = true,
                                 default = nil)
  if valid_603315 != nil:
    section.add "Id", valid_603315
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   If-Match: JString
  ##           : The value of the <code>ETag</code> header that you received when retrieving the identity's configuration. For example: <code>E2QWRUHAPOMQZL</code>.
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603316 = header.getOrDefault("X-Amz-Date")
  valid_603316 = validateParameter(valid_603316, JString, required = false,
                                 default = nil)
  if valid_603316 != nil:
    section.add "X-Amz-Date", valid_603316
  var valid_603317 = header.getOrDefault("X-Amz-Security-Token")
  valid_603317 = validateParameter(valid_603317, JString, required = false,
                                 default = nil)
  if valid_603317 != nil:
    section.add "X-Amz-Security-Token", valid_603317
  var valid_603318 = header.getOrDefault("If-Match")
  valid_603318 = validateParameter(valid_603318, JString, required = false,
                                 default = nil)
  if valid_603318 != nil:
    section.add "If-Match", valid_603318
  var valid_603319 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603319 = validateParameter(valid_603319, JString, required = false,
                                 default = nil)
  if valid_603319 != nil:
    section.add "X-Amz-Content-Sha256", valid_603319
  var valid_603320 = header.getOrDefault("X-Amz-Algorithm")
  valid_603320 = validateParameter(valid_603320, JString, required = false,
                                 default = nil)
  if valid_603320 != nil:
    section.add "X-Amz-Algorithm", valid_603320
  var valid_603321 = header.getOrDefault("X-Amz-Signature")
  valid_603321 = validateParameter(valid_603321, JString, required = false,
                                 default = nil)
  if valid_603321 != nil:
    section.add "X-Amz-Signature", valid_603321
  var valid_603322 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603322 = validateParameter(valid_603322, JString, required = false,
                                 default = nil)
  if valid_603322 != nil:
    section.add "X-Amz-SignedHeaders", valid_603322
  var valid_603323 = header.getOrDefault("X-Amz-Credential")
  valid_603323 = validateParameter(valid_603323, JString, required = false,
                                 default = nil)
  if valid_603323 != nil:
    section.add "X-Amz-Credential", valid_603323
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603325: Call_UpdateCloudFrontOriginAccessIdentity20161125_603312;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Update an origin access identity. 
  ## 
  let valid = call_603325.validator(path, query, header, formData, body)
  let scheme = call_603325.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603325.url(scheme.get, call_603325.host, call_603325.base,
                         call_603325.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603325, url, valid)

proc call*(call_603326: Call_UpdateCloudFrontOriginAccessIdentity20161125_603312;
          Id: string; body: JsonNode): Recallable =
  ## updateCloudFrontOriginAccessIdentity20161125
  ## Update an origin access identity. 
  ##   Id: string (required)
  ##     : The identity's id.
  ##   body: JObject (required)
  var path_603327 = newJObject()
  var body_603328 = newJObject()
  add(path_603327, "Id", newJString(Id))
  if body != nil:
    body_603328 = body
  result = call_603326.call(path_603327, nil, nil, nil, body_603328)

var updateCloudFrontOriginAccessIdentity20161125* = Call_UpdateCloudFrontOriginAccessIdentity20161125_603312(
    name: "updateCloudFrontOriginAccessIdentity20161125",
    meth: HttpMethod.HttpPut, host: "cloudfront.amazonaws.com",
    route: "/2016-11-25/origin-access-identity/cloudfront/{Id}/config",
    validator: validate_UpdateCloudFrontOriginAccessIdentity20161125_603313,
    base: "/", url: url_UpdateCloudFrontOriginAccessIdentity20161125_603314,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCloudFrontOriginAccessIdentityConfig20161125_603298 = ref object of OpenApiRestCall_602466
proc url_GetCloudFrontOriginAccessIdentityConfig20161125_603300(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                value: "/2016-11-25/origin-access-identity/cloudfront/"),
               (kind: VariableSegment, value: "Id"),
               (kind: ConstantSegment, value: "/config")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_GetCloudFrontOriginAccessIdentityConfig20161125_603299(
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
  var valid_603301 = path.getOrDefault("Id")
  valid_603301 = validateParameter(valid_603301, JString, required = true,
                                 default = nil)
  if valid_603301 != nil:
    section.add "Id", valid_603301
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
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603302 = header.getOrDefault("X-Amz-Date")
  valid_603302 = validateParameter(valid_603302, JString, required = false,
                                 default = nil)
  if valid_603302 != nil:
    section.add "X-Amz-Date", valid_603302
  var valid_603303 = header.getOrDefault("X-Amz-Security-Token")
  valid_603303 = validateParameter(valid_603303, JString, required = false,
                                 default = nil)
  if valid_603303 != nil:
    section.add "X-Amz-Security-Token", valid_603303
  var valid_603304 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603304 = validateParameter(valid_603304, JString, required = false,
                                 default = nil)
  if valid_603304 != nil:
    section.add "X-Amz-Content-Sha256", valid_603304
  var valid_603305 = header.getOrDefault("X-Amz-Algorithm")
  valid_603305 = validateParameter(valid_603305, JString, required = false,
                                 default = nil)
  if valid_603305 != nil:
    section.add "X-Amz-Algorithm", valid_603305
  var valid_603306 = header.getOrDefault("X-Amz-Signature")
  valid_603306 = validateParameter(valid_603306, JString, required = false,
                                 default = nil)
  if valid_603306 != nil:
    section.add "X-Amz-Signature", valid_603306
  var valid_603307 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603307 = validateParameter(valid_603307, JString, required = false,
                                 default = nil)
  if valid_603307 != nil:
    section.add "X-Amz-SignedHeaders", valid_603307
  var valid_603308 = header.getOrDefault("X-Amz-Credential")
  valid_603308 = validateParameter(valid_603308, JString, required = false,
                                 default = nil)
  if valid_603308 != nil:
    section.add "X-Amz-Credential", valid_603308
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603309: Call_GetCloudFrontOriginAccessIdentityConfig20161125_603298;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Get the configuration information about an origin access identity. 
  ## 
  let valid = call_603309.validator(path, query, header, formData, body)
  let scheme = call_603309.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603309.url(scheme.get, call_603309.host, call_603309.base,
                         call_603309.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603309, url, valid)

proc call*(call_603310: Call_GetCloudFrontOriginAccessIdentityConfig20161125_603298;
          Id: string): Recallable =
  ## getCloudFrontOriginAccessIdentityConfig20161125
  ## Get the configuration information about an origin access identity. 
  ##   Id: string (required)
  ##     : The identity's ID. 
  var path_603311 = newJObject()
  add(path_603311, "Id", newJString(Id))
  result = call_603310.call(path_603311, nil, nil, nil, nil)

var getCloudFrontOriginAccessIdentityConfig20161125* = Call_GetCloudFrontOriginAccessIdentityConfig20161125_603298(
    name: "getCloudFrontOriginAccessIdentityConfig20161125",
    meth: HttpMethod.HttpGet, host: "cloudfront.amazonaws.com",
    route: "/2016-11-25/origin-access-identity/cloudfront/{Id}/config",
    validator: validate_GetCloudFrontOriginAccessIdentityConfig20161125_603299,
    base: "/", url: url_GetCloudFrontOriginAccessIdentityConfig20161125_603300,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDistribution20161125_603343 = ref object of OpenApiRestCall_602466
proc url_UpdateDistribution20161125_603345(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2016-11-25/distribution/"),
               (kind: VariableSegment, value: "Id"),
               (kind: ConstantSegment, value: "/config")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_UpdateDistribution20161125_603344(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Update a distribution. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The distribution's id.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_603346 = path.getOrDefault("Id")
  valid_603346 = validateParameter(valid_603346, JString, required = true,
                                 default = nil)
  if valid_603346 != nil:
    section.add "Id", valid_603346
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   If-Match: JString
  ##           : The value of the <code>ETag</code> header that you received when retrieving the distribution's configuration. For example: <code>E2QWRUHAPOMQZL</code>.
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603347 = header.getOrDefault("X-Amz-Date")
  valid_603347 = validateParameter(valid_603347, JString, required = false,
                                 default = nil)
  if valid_603347 != nil:
    section.add "X-Amz-Date", valid_603347
  var valid_603348 = header.getOrDefault("X-Amz-Security-Token")
  valid_603348 = validateParameter(valid_603348, JString, required = false,
                                 default = nil)
  if valid_603348 != nil:
    section.add "X-Amz-Security-Token", valid_603348
  var valid_603349 = header.getOrDefault("If-Match")
  valid_603349 = validateParameter(valid_603349, JString, required = false,
                                 default = nil)
  if valid_603349 != nil:
    section.add "If-Match", valid_603349
  var valid_603350 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603350 = validateParameter(valid_603350, JString, required = false,
                                 default = nil)
  if valid_603350 != nil:
    section.add "X-Amz-Content-Sha256", valid_603350
  var valid_603351 = header.getOrDefault("X-Amz-Algorithm")
  valid_603351 = validateParameter(valid_603351, JString, required = false,
                                 default = nil)
  if valid_603351 != nil:
    section.add "X-Amz-Algorithm", valid_603351
  var valid_603352 = header.getOrDefault("X-Amz-Signature")
  valid_603352 = validateParameter(valid_603352, JString, required = false,
                                 default = nil)
  if valid_603352 != nil:
    section.add "X-Amz-Signature", valid_603352
  var valid_603353 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603353 = validateParameter(valid_603353, JString, required = false,
                                 default = nil)
  if valid_603353 != nil:
    section.add "X-Amz-SignedHeaders", valid_603353
  var valid_603354 = header.getOrDefault("X-Amz-Credential")
  valid_603354 = validateParameter(valid_603354, JString, required = false,
                                 default = nil)
  if valid_603354 != nil:
    section.add "X-Amz-Credential", valid_603354
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603356: Call_UpdateDistribution20161125_603343; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Update a distribution. 
  ## 
  let valid = call_603356.validator(path, query, header, formData, body)
  let scheme = call_603356.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603356.url(scheme.get, call_603356.host, call_603356.base,
                         call_603356.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603356, url, valid)

proc call*(call_603357: Call_UpdateDistribution20161125_603343; Id: string;
          body: JsonNode): Recallable =
  ## updateDistribution20161125
  ## Update a distribution. 
  ##   Id: string (required)
  ##     : The distribution's id.
  ##   body: JObject (required)
  var path_603358 = newJObject()
  var body_603359 = newJObject()
  add(path_603358, "Id", newJString(Id))
  if body != nil:
    body_603359 = body
  result = call_603357.call(path_603358, nil, nil, nil, body_603359)

var updateDistribution20161125* = Call_UpdateDistribution20161125_603343(
    name: "updateDistribution20161125", meth: HttpMethod.HttpPut,
    host: "cloudfront.amazonaws.com",
    route: "/2016-11-25/distribution/{Id}/config",
    validator: validate_UpdateDistribution20161125_603344, base: "/",
    url: url_UpdateDistribution20161125_603345,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDistributionConfig20161125_603329 = ref object of OpenApiRestCall_602466
proc url_GetDistributionConfig20161125_603331(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2016-11-25/distribution/"),
               (kind: VariableSegment, value: "Id"),
               (kind: ConstantSegment, value: "/config")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_GetDistributionConfig20161125_603330(path: JsonNode; query: JsonNode;
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
  var valid_603332 = path.getOrDefault("Id")
  valid_603332 = validateParameter(valid_603332, JString, required = true,
                                 default = nil)
  if valid_603332 != nil:
    section.add "Id", valid_603332
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
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603333 = header.getOrDefault("X-Amz-Date")
  valid_603333 = validateParameter(valid_603333, JString, required = false,
                                 default = nil)
  if valid_603333 != nil:
    section.add "X-Amz-Date", valid_603333
  var valid_603334 = header.getOrDefault("X-Amz-Security-Token")
  valid_603334 = validateParameter(valid_603334, JString, required = false,
                                 default = nil)
  if valid_603334 != nil:
    section.add "X-Amz-Security-Token", valid_603334
  var valid_603335 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603335 = validateParameter(valid_603335, JString, required = false,
                                 default = nil)
  if valid_603335 != nil:
    section.add "X-Amz-Content-Sha256", valid_603335
  var valid_603336 = header.getOrDefault("X-Amz-Algorithm")
  valid_603336 = validateParameter(valid_603336, JString, required = false,
                                 default = nil)
  if valid_603336 != nil:
    section.add "X-Amz-Algorithm", valid_603336
  var valid_603337 = header.getOrDefault("X-Amz-Signature")
  valid_603337 = validateParameter(valid_603337, JString, required = false,
                                 default = nil)
  if valid_603337 != nil:
    section.add "X-Amz-Signature", valid_603337
  var valid_603338 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603338 = validateParameter(valid_603338, JString, required = false,
                                 default = nil)
  if valid_603338 != nil:
    section.add "X-Amz-SignedHeaders", valid_603338
  var valid_603339 = header.getOrDefault("X-Amz-Credential")
  valid_603339 = validateParameter(valid_603339, JString, required = false,
                                 default = nil)
  if valid_603339 != nil:
    section.add "X-Amz-Credential", valid_603339
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603340: Call_GetDistributionConfig20161125_603329; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Get the configuration information about a distribution. 
  ## 
  let valid = call_603340.validator(path, query, header, formData, body)
  let scheme = call_603340.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603340.url(scheme.get, call_603340.host, call_603340.base,
                         call_603340.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603340, url, valid)

proc call*(call_603341: Call_GetDistributionConfig20161125_603329; Id: string): Recallable =
  ## getDistributionConfig20161125
  ## Get the configuration information about a distribution. 
  ##   Id: string (required)
  ##     : The distribution's ID.
  var path_603342 = newJObject()
  add(path_603342, "Id", newJString(Id))
  result = call_603341.call(path_603342, nil, nil, nil, nil)

var getDistributionConfig20161125* = Call_GetDistributionConfig20161125_603329(
    name: "getDistributionConfig20161125", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com",
    route: "/2016-11-25/distribution/{Id}/config",
    validator: validate_GetDistributionConfig20161125_603330, base: "/",
    url: url_GetDistributionConfig20161125_603331,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetInvalidation20161125_603360 = ref object of OpenApiRestCall_602466
proc url_GetInvalidation20161125_603362(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "DistributionId" in path, "`DistributionId` is a required path parameter"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2016-11-25/distribution/"),
               (kind: VariableSegment, value: "DistributionId"),
               (kind: ConstantSegment, value: "/invalidation/"),
               (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_GetInvalidation20161125_603361(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Get the information about an invalidation. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The identifier for the invalidation request, for example, <code>IDFDVBD632BHDS5</code>.
  ##   DistributionId: JString (required)
  ##                 : The distribution's ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_603363 = path.getOrDefault("Id")
  valid_603363 = validateParameter(valid_603363, JString, required = true,
                                 default = nil)
  if valid_603363 != nil:
    section.add "Id", valid_603363
  var valid_603364 = path.getOrDefault("DistributionId")
  valid_603364 = validateParameter(valid_603364, JString, required = true,
                                 default = nil)
  if valid_603364 != nil:
    section.add "DistributionId", valid_603364
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
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603365 = header.getOrDefault("X-Amz-Date")
  valid_603365 = validateParameter(valid_603365, JString, required = false,
                                 default = nil)
  if valid_603365 != nil:
    section.add "X-Amz-Date", valid_603365
  var valid_603366 = header.getOrDefault("X-Amz-Security-Token")
  valid_603366 = validateParameter(valid_603366, JString, required = false,
                                 default = nil)
  if valid_603366 != nil:
    section.add "X-Amz-Security-Token", valid_603366
  var valid_603367 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603367 = validateParameter(valid_603367, JString, required = false,
                                 default = nil)
  if valid_603367 != nil:
    section.add "X-Amz-Content-Sha256", valid_603367
  var valid_603368 = header.getOrDefault("X-Amz-Algorithm")
  valid_603368 = validateParameter(valid_603368, JString, required = false,
                                 default = nil)
  if valid_603368 != nil:
    section.add "X-Amz-Algorithm", valid_603368
  var valid_603369 = header.getOrDefault("X-Amz-Signature")
  valid_603369 = validateParameter(valid_603369, JString, required = false,
                                 default = nil)
  if valid_603369 != nil:
    section.add "X-Amz-Signature", valid_603369
  var valid_603370 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603370 = validateParameter(valid_603370, JString, required = false,
                                 default = nil)
  if valid_603370 != nil:
    section.add "X-Amz-SignedHeaders", valid_603370
  var valid_603371 = header.getOrDefault("X-Amz-Credential")
  valid_603371 = validateParameter(valid_603371, JString, required = false,
                                 default = nil)
  if valid_603371 != nil:
    section.add "X-Amz-Credential", valid_603371
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603372: Call_GetInvalidation20161125_603360; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Get the information about an invalidation. 
  ## 
  let valid = call_603372.validator(path, query, header, formData, body)
  let scheme = call_603372.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603372.url(scheme.get, call_603372.host, call_603372.base,
                         call_603372.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603372, url, valid)

proc call*(call_603373: Call_GetInvalidation20161125_603360; Id: string;
          DistributionId: string): Recallable =
  ## getInvalidation20161125
  ## Get the information about an invalidation. 
  ##   Id: string (required)
  ##     : The identifier for the invalidation request, for example, <code>IDFDVBD632BHDS5</code>.
  ##   DistributionId: string (required)
  ##                 : The distribution's ID.
  var path_603374 = newJObject()
  add(path_603374, "Id", newJString(Id))
  add(path_603374, "DistributionId", newJString(DistributionId))
  result = call_603373.call(path_603374, nil, nil, nil, nil)

var getInvalidation20161125* = Call_GetInvalidation20161125_603360(
    name: "getInvalidation20161125", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com",
    route: "/2016-11-25/distribution/{DistributionId}/invalidation/{Id}",
    validator: validate_GetInvalidation20161125_603361, base: "/",
    url: url_GetInvalidation20161125_603362, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateStreamingDistribution20161125_603389 = ref object of OpenApiRestCall_602466
proc url_UpdateStreamingDistribution20161125_603391(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                value: "/2016-11-25/streaming-distribution/"),
               (kind: VariableSegment, value: "Id"),
               (kind: ConstantSegment, value: "/config")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_UpdateStreamingDistribution20161125_603390(path: JsonNode;
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
  var valid_603392 = path.getOrDefault("Id")
  valid_603392 = validateParameter(valid_603392, JString, required = true,
                                 default = nil)
  if valid_603392 != nil:
    section.add "Id", valid_603392
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   If-Match: JString
  ##           : The value of the <code>ETag</code> header that you received when retrieving the streaming distribution's configuration. For example: <code>E2QWRUHAPOMQZL</code>.
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603393 = header.getOrDefault("X-Amz-Date")
  valid_603393 = validateParameter(valid_603393, JString, required = false,
                                 default = nil)
  if valid_603393 != nil:
    section.add "X-Amz-Date", valid_603393
  var valid_603394 = header.getOrDefault("X-Amz-Security-Token")
  valid_603394 = validateParameter(valid_603394, JString, required = false,
                                 default = nil)
  if valid_603394 != nil:
    section.add "X-Amz-Security-Token", valid_603394
  var valid_603395 = header.getOrDefault("If-Match")
  valid_603395 = validateParameter(valid_603395, JString, required = false,
                                 default = nil)
  if valid_603395 != nil:
    section.add "If-Match", valid_603395
  var valid_603396 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603396 = validateParameter(valid_603396, JString, required = false,
                                 default = nil)
  if valid_603396 != nil:
    section.add "X-Amz-Content-Sha256", valid_603396
  var valid_603397 = header.getOrDefault("X-Amz-Algorithm")
  valid_603397 = validateParameter(valid_603397, JString, required = false,
                                 default = nil)
  if valid_603397 != nil:
    section.add "X-Amz-Algorithm", valid_603397
  var valid_603398 = header.getOrDefault("X-Amz-Signature")
  valid_603398 = validateParameter(valid_603398, JString, required = false,
                                 default = nil)
  if valid_603398 != nil:
    section.add "X-Amz-Signature", valid_603398
  var valid_603399 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603399 = validateParameter(valid_603399, JString, required = false,
                                 default = nil)
  if valid_603399 != nil:
    section.add "X-Amz-SignedHeaders", valid_603399
  var valid_603400 = header.getOrDefault("X-Amz-Credential")
  valid_603400 = validateParameter(valid_603400, JString, required = false,
                                 default = nil)
  if valid_603400 != nil:
    section.add "X-Amz-Credential", valid_603400
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603402: Call_UpdateStreamingDistribution20161125_603389;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Update a streaming distribution. 
  ## 
  let valid = call_603402.validator(path, query, header, formData, body)
  let scheme = call_603402.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603402.url(scheme.get, call_603402.host, call_603402.base,
                         call_603402.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603402, url, valid)

proc call*(call_603403: Call_UpdateStreamingDistribution20161125_603389;
          Id: string; body: JsonNode): Recallable =
  ## updateStreamingDistribution20161125
  ## Update a streaming distribution. 
  ##   Id: string (required)
  ##     : The streaming distribution's id.
  ##   body: JObject (required)
  var path_603404 = newJObject()
  var body_603405 = newJObject()
  add(path_603404, "Id", newJString(Id))
  if body != nil:
    body_603405 = body
  result = call_603403.call(path_603404, nil, nil, nil, body_603405)

var updateStreamingDistribution20161125* = Call_UpdateStreamingDistribution20161125_603389(
    name: "updateStreamingDistribution20161125", meth: HttpMethod.HttpPut,
    host: "cloudfront.amazonaws.com",
    route: "/2016-11-25/streaming-distribution/{Id}/config",
    validator: validate_UpdateStreamingDistribution20161125_603390, base: "/",
    url: url_UpdateStreamingDistribution20161125_603391,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetStreamingDistributionConfig20161125_603375 = ref object of OpenApiRestCall_602466
proc url_GetStreamingDistributionConfig20161125_603377(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                value: "/2016-11-25/streaming-distribution/"),
               (kind: VariableSegment, value: "Id"),
               (kind: ConstantSegment, value: "/config")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_GetStreamingDistributionConfig20161125_603376(path: JsonNode;
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
  var valid_603378 = path.getOrDefault("Id")
  valid_603378 = validateParameter(valid_603378, JString, required = true,
                                 default = nil)
  if valid_603378 != nil:
    section.add "Id", valid_603378
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
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603379 = header.getOrDefault("X-Amz-Date")
  valid_603379 = validateParameter(valid_603379, JString, required = false,
                                 default = nil)
  if valid_603379 != nil:
    section.add "X-Amz-Date", valid_603379
  var valid_603380 = header.getOrDefault("X-Amz-Security-Token")
  valid_603380 = validateParameter(valid_603380, JString, required = false,
                                 default = nil)
  if valid_603380 != nil:
    section.add "X-Amz-Security-Token", valid_603380
  var valid_603381 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603381 = validateParameter(valid_603381, JString, required = false,
                                 default = nil)
  if valid_603381 != nil:
    section.add "X-Amz-Content-Sha256", valid_603381
  var valid_603382 = header.getOrDefault("X-Amz-Algorithm")
  valid_603382 = validateParameter(valid_603382, JString, required = false,
                                 default = nil)
  if valid_603382 != nil:
    section.add "X-Amz-Algorithm", valid_603382
  var valid_603383 = header.getOrDefault("X-Amz-Signature")
  valid_603383 = validateParameter(valid_603383, JString, required = false,
                                 default = nil)
  if valid_603383 != nil:
    section.add "X-Amz-Signature", valid_603383
  var valid_603384 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603384 = validateParameter(valid_603384, JString, required = false,
                                 default = nil)
  if valid_603384 != nil:
    section.add "X-Amz-SignedHeaders", valid_603384
  var valid_603385 = header.getOrDefault("X-Amz-Credential")
  valid_603385 = validateParameter(valid_603385, JString, required = false,
                                 default = nil)
  if valid_603385 != nil:
    section.add "X-Amz-Credential", valid_603385
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603386: Call_GetStreamingDistributionConfig20161125_603375;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Get the configuration information about a streaming distribution. 
  ## 
  let valid = call_603386.validator(path, query, header, formData, body)
  let scheme = call_603386.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603386.url(scheme.get, call_603386.host, call_603386.base,
                         call_603386.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603386, url, valid)

proc call*(call_603387: Call_GetStreamingDistributionConfig20161125_603375;
          Id: string): Recallable =
  ## getStreamingDistributionConfig20161125
  ## Get the configuration information about a streaming distribution. 
  ##   Id: string (required)
  ##     : The streaming distribution's ID.
  var path_603388 = newJObject()
  add(path_603388, "Id", newJString(Id))
  result = call_603387.call(path_603388, nil, nil, nil, nil)

var getStreamingDistributionConfig20161125* = Call_GetStreamingDistributionConfig20161125_603375(
    name: "getStreamingDistributionConfig20161125", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com",
    route: "/2016-11-25/streaming-distribution/{Id}/config",
    validator: validate_GetStreamingDistributionConfig20161125_603376, base: "/",
    url: url_GetStreamingDistributionConfig20161125_603377,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDistributionsByWebACLId20161125_603406 = ref object of OpenApiRestCall_602466
proc url_ListDistributionsByWebACLId20161125_603408(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "WebACLId" in path, "`WebACLId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                value: "/2016-11-25/distributionsByWebACLId/"),
               (kind: VariableSegment, value: "WebACLId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_ListDistributionsByWebACLId20161125_603407(path: JsonNode;
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
  var valid_603409 = path.getOrDefault("WebACLId")
  valid_603409 = validateParameter(valid_603409, JString, required = true,
                                 default = nil)
  if valid_603409 != nil:
    section.add "WebACLId", valid_603409
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##         : Use <code>Marker</code> and <code>MaxItems</code> to control pagination of results. If you have more than <code>MaxItems</code> distributions that satisfy the request, the response includes a <code>NextMarker</code> element. To get the next page of results, submit another request. For the value of <code>Marker</code>, specify the value of <code>NextMarker</code> from the last response. (For the first request, omit <code>Marker</code>.) 
  ##   MaxItems: JString
  ##           : The maximum number of distributions that you want CloudFront to return in the response body. The maximum and default values are both 100.
  section = newJObject()
  var valid_603410 = query.getOrDefault("Marker")
  valid_603410 = validateParameter(valid_603410, JString, required = false,
                                 default = nil)
  if valid_603410 != nil:
    section.add "Marker", valid_603410
  var valid_603411 = query.getOrDefault("MaxItems")
  valid_603411 = validateParameter(valid_603411, JString, required = false,
                                 default = nil)
  if valid_603411 != nil:
    section.add "MaxItems", valid_603411
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603412 = header.getOrDefault("X-Amz-Date")
  valid_603412 = validateParameter(valid_603412, JString, required = false,
                                 default = nil)
  if valid_603412 != nil:
    section.add "X-Amz-Date", valid_603412
  var valid_603413 = header.getOrDefault("X-Amz-Security-Token")
  valid_603413 = validateParameter(valid_603413, JString, required = false,
                                 default = nil)
  if valid_603413 != nil:
    section.add "X-Amz-Security-Token", valid_603413
  var valid_603414 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603414 = validateParameter(valid_603414, JString, required = false,
                                 default = nil)
  if valid_603414 != nil:
    section.add "X-Amz-Content-Sha256", valid_603414
  var valid_603415 = header.getOrDefault("X-Amz-Algorithm")
  valid_603415 = validateParameter(valid_603415, JString, required = false,
                                 default = nil)
  if valid_603415 != nil:
    section.add "X-Amz-Algorithm", valid_603415
  var valid_603416 = header.getOrDefault("X-Amz-Signature")
  valid_603416 = validateParameter(valid_603416, JString, required = false,
                                 default = nil)
  if valid_603416 != nil:
    section.add "X-Amz-Signature", valid_603416
  var valid_603417 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603417 = validateParameter(valid_603417, JString, required = false,
                                 default = nil)
  if valid_603417 != nil:
    section.add "X-Amz-SignedHeaders", valid_603417
  var valid_603418 = header.getOrDefault("X-Amz-Credential")
  valid_603418 = validateParameter(valid_603418, JString, required = false,
                                 default = nil)
  if valid_603418 != nil:
    section.add "X-Amz-Credential", valid_603418
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603419: Call_ListDistributionsByWebACLId20161125_603406;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## List the distributions that are associated with a specified AWS WAF web ACL. 
  ## 
  let valid = call_603419.validator(path, query, header, formData, body)
  let scheme = call_603419.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603419.url(scheme.get, call_603419.host, call_603419.base,
                         call_603419.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603419, url, valid)

proc call*(call_603420: Call_ListDistributionsByWebACLId20161125_603406;
          WebACLId: string; Marker: string = ""; MaxItems: string = ""): Recallable =
  ## listDistributionsByWebACLId20161125
  ## List the distributions that are associated with a specified AWS WAF web ACL. 
  ##   Marker: string
  ##         : Use <code>Marker</code> and <code>MaxItems</code> to control pagination of results. If you have more than <code>MaxItems</code> distributions that satisfy the request, the response includes a <code>NextMarker</code> element. To get the next page of results, submit another request. For the value of <code>Marker</code>, specify the value of <code>NextMarker</code> from the last response. (For the first request, omit <code>Marker</code>.) 
  ##   MaxItems: string
  ##           : The maximum number of distributions that you want CloudFront to return in the response body. The maximum and default values are both 100.
  ##   WebACLId: string (required)
  ##           : The ID of the AWS WAF web ACL that you want to list the associated distributions. If you specify "null" for the ID, the request returns a list of the distributions that aren't associated with a web ACL. 
  var path_603421 = newJObject()
  var query_603422 = newJObject()
  add(query_603422, "Marker", newJString(Marker))
  add(query_603422, "MaxItems", newJString(MaxItems))
  add(path_603421, "WebACLId", newJString(WebACLId))
  result = call_603420.call(path_603421, query_603422, nil, nil, nil)

var listDistributionsByWebACLId20161125* = Call_ListDistributionsByWebACLId20161125_603406(
    name: "listDistributionsByWebACLId20161125", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com",
    route: "/2016-11-25/distributionsByWebACLId/{WebACLId}",
    validator: validate_ListDistributionsByWebACLId20161125_603407, base: "/",
    url: url_ListDistributionsByWebACLId20161125_603408,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource20161125_603423 = ref object of OpenApiRestCall_602466
proc url_ListTagsForResource20161125_603425(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListTagsForResource20161125_603424(path: JsonNode; query: JsonNode;
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
  var valid_603426 = query.getOrDefault("Resource")
  valid_603426 = validateParameter(valid_603426, JString, required = true,
                                 default = nil)
  if valid_603426 != nil:
    section.add "Resource", valid_603426
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603427 = header.getOrDefault("X-Amz-Date")
  valid_603427 = validateParameter(valid_603427, JString, required = false,
                                 default = nil)
  if valid_603427 != nil:
    section.add "X-Amz-Date", valid_603427
  var valid_603428 = header.getOrDefault("X-Amz-Security-Token")
  valid_603428 = validateParameter(valid_603428, JString, required = false,
                                 default = nil)
  if valid_603428 != nil:
    section.add "X-Amz-Security-Token", valid_603428
  var valid_603429 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603429 = validateParameter(valid_603429, JString, required = false,
                                 default = nil)
  if valid_603429 != nil:
    section.add "X-Amz-Content-Sha256", valid_603429
  var valid_603430 = header.getOrDefault("X-Amz-Algorithm")
  valid_603430 = validateParameter(valid_603430, JString, required = false,
                                 default = nil)
  if valid_603430 != nil:
    section.add "X-Amz-Algorithm", valid_603430
  var valid_603431 = header.getOrDefault("X-Amz-Signature")
  valid_603431 = validateParameter(valid_603431, JString, required = false,
                                 default = nil)
  if valid_603431 != nil:
    section.add "X-Amz-Signature", valid_603431
  var valid_603432 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603432 = validateParameter(valid_603432, JString, required = false,
                                 default = nil)
  if valid_603432 != nil:
    section.add "X-Amz-SignedHeaders", valid_603432
  var valid_603433 = header.getOrDefault("X-Amz-Credential")
  valid_603433 = validateParameter(valid_603433, JString, required = false,
                                 default = nil)
  if valid_603433 != nil:
    section.add "X-Amz-Credential", valid_603433
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603434: Call_ListTagsForResource20161125_603423; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List tags for a CloudFront resource.
  ## 
  let valid = call_603434.validator(path, query, header, formData, body)
  let scheme = call_603434.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603434.url(scheme.get, call_603434.host, call_603434.base,
                         call_603434.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603434, url, valid)

proc call*(call_603435: Call_ListTagsForResource20161125_603423; Resource: string): Recallable =
  ## listTagsForResource20161125
  ## List tags for a CloudFront resource.
  ##   Resource: string (required)
  ##           :  An ARN of a CloudFront resource.
  var query_603436 = newJObject()
  add(query_603436, "Resource", newJString(Resource))
  result = call_603435.call(nil, query_603436, nil, nil, nil)

var listTagsForResource20161125* = Call_ListTagsForResource20161125_603423(
    name: "listTagsForResource20161125", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com", route: "/2016-11-25/tagging#Resource",
    validator: validate_ListTagsForResource20161125_603424, base: "/",
    url: url_ListTagsForResource20161125_603425,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource20161125_603437 = ref object of OpenApiRestCall_602466
proc url_TagResource20161125_603439(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_TagResource20161125_603438(path: JsonNode; query: JsonNode;
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
  var valid_603440 = query.getOrDefault("Resource")
  valid_603440 = validateParameter(valid_603440, JString, required = true,
                                 default = nil)
  if valid_603440 != nil:
    section.add "Resource", valid_603440
  var valid_603454 = query.getOrDefault("Operation")
  valid_603454 = validateParameter(valid_603454, JString, required = true,
                                 default = newJString("Tag"))
  if valid_603454 != nil:
    section.add "Operation", valid_603454
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603455 = header.getOrDefault("X-Amz-Date")
  valid_603455 = validateParameter(valid_603455, JString, required = false,
                                 default = nil)
  if valid_603455 != nil:
    section.add "X-Amz-Date", valid_603455
  var valid_603456 = header.getOrDefault("X-Amz-Security-Token")
  valid_603456 = validateParameter(valid_603456, JString, required = false,
                                 default = nil)
  if valid_603456 != nil:
    section.add "X-Amz-Security-Token", valid_603456
  var valid_603457 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603457 = validateParameter(valid_603457, JString, required = false,
                                 default = nil)
  if valid_603457 != nil:
    section.add "X-Amz-Content-Sha256", valid_603457
  var valid_603458 = header.getOrDefault("X-Amz-Algorithm")
  valid_603458 = validateParameter(valid_603458, JString, required = false,
                                 default = nil)
  if valid_603458 != nil:
    section.add "X-Amz-Algorithm", valid_603458
  var valid_603459 = header.getOrDefault("X-Amz-Signature")
  valid_603459 = validateParameter(valid_603459, JString, required = false,
                                 default = nil)
  if valid_603459 != nil:
    section.add "X-Amz-Signature", valid_603459
  var valid_603460 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603460 = validateParameter(valid_603460, JString, required = false,
                                 default = nil)
  if valid_603460 != nil:
    section.add "X-Amz-SignedHeaders", valid_603460
  var valid_603461 = header.getOrDefault("X-Amz-Credential")
  valid_603461 = validateParameter(valid_603461, JString, required = false,
                                 default = nil)
  if valid_603461 != nil:
    section.add "X-Amz-Credential", valid_603461
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603463: Call_TagResource20161125_603437; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Add tags to a CloudFront resource.
  ## 
  let valid = call_603463.validator(path, query, header, formData, body)
  let scheme = call_603463.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603463.url(scheme.get, call_603463.host, call_603463.base,
                         call_603463.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603463, url, valid)

proc call*(call_603464: Call_TagResource20161125_603437; Resource: string;
          body: JsonNode; Operation: string = "Tag"): Recallable =
  ## tagResource20161125
  ## Add tags to a CloudFront resource.
  ##   Resource: string (required)
  ##           :  An ARN of a CloudFront resource.
  ##   Operation: string (required)
  ##   body: JObject (required)
  var query_603465 = newJObject()
  var body_603466 = newJObject()
  add(query_603465, "Resource", newJString(Resource))
  add(query_603465, "Operation", newJString(Operation))
  if body != nil:
    body_603466 = body
  result = call_603464.call(nil, query_603465, nil, nil, body_603466)

var tagResource20161125* = Call_TagResource20161125_603437(
    name: "tagResource20161125", meth: HttpMethod.HttpPost,
    host: "cloudfront.amazonaws.com",
    route: "/2016-11-25/tagging#Operation=Tag&Resource",
    validator: validate_TagResource20161125_603438, base: "/",
    url: url_TagResource20161125_603439, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource20161125_603467 = ref object of OpenApiRestCall_602466
proc url_UntagResource20161125_603469(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UntagResource20161125_603468(path: JsonNode; query: JsonNode;
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
  var valid_603470 = query.getOrDefault("Resource")
  valid_603470 = validateParameter(valid_603470, JString, required = true,
                                 default = nil)
  if valid_603470 != nil:
    section.add "Resource", valid_603470
  var valid_603471 = query.getOrDefault("Operation")
  valid_603471 = validateParameter(valid_603471, JString, required = true,
                                 default = newJString("Untag"))
  if valid_603471 != nil:
    section.add "Operation", valid_603471
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603472 = header.getOrDefault("X-Amz-Date")
  valid_603472 = validateParameter(valid_603472, JString, required = false,
                                 default = nil)
  if valid_603472 != nil:
    section.add "X-Amz-Date", valid_603472
  var valid_603473 = header.getOrDefault("X-Amz-Security-Token")
  valid_603473 = validateParameter(valid_603473, JString, required = false,
                                 default = nil)
  if valid_603473 != nil:
    section.add "X-Amz-Security-Token", valid_603473
  var valid_603474 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603474 = validateParameter(valid_603474, JString, required = false,
                                 default = nil)
  if valid_603474 != nil:
    section.add "X-Amz-Content-Sha256", valid_603474
  var valid_603475 = header.getOrDefault("X-Amz-Algorithm")
  valid_603475 = validateParameter(valid_603475, JString, required = false,
                                 default = nil)
  if valid_603475 != nil:
    section.add "X-Amz-Algorithm", valid_603475
  var valid_603476 = header.getOrDefault("X-Amz-Signature")
  valid_603476 = validateParameter(valid_603476, JString, required = false,
                                 default = nil)
  if valid_603476 != nil:
    section.add "X-Amz-Signature", valid_603476
  var valid_603477 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603477 = validateParameter(valid_603477, JString, required = false,
                                 default = nil)
  if valid_603477 != nil:
    section.add "X-Amz-SignedHeaders", valid_603477
  var valid_603478 = header.getOrDefault("X-Amz-Credential")
  valid_603478 = validateParameter(valid_603478, JString, required = false,
                                 default = nil)
  if valid_603478 != nil:
    section.add "X-Amz-Credential", valid_603478
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603480: Call_UntagResource20161125_603467; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Remove tags from a CloudFront resource.
  ## 
  let valid = call_603480.validator(path, query, header, formData, body)
  let scheme = call_603480.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603480.url(scheme.get, call_603480.host, call_603480.base,
                         call_603480.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603480, url, valid)

proc call*(call_603481: Call_UntagResource20161125_603467; Resource: string;
          body: JsonNode; Operation: string = "Untag"): Recallable =
  ## untagResource20161125
  ## Remove tags from a CloudFront resource.
  ##   Resource: string (required)
  ##           :  An ARN of a CloudFront resource.
  ##   Operation: string (required)
  ##   body: JObject (required)
  var query_603482 = newJObject()
  var body_603483 = newJObject()
  add(query_603482, "Resource", newJString(Resource))
  add(query_603482, "Operation", newJString(Operation))
  if body != nil:
    body_603483 = body
  result = call_603481.call(nil, query_603482, nil, nil, body_603483)

var untagResource20161125* = Call_UntagResource20161125_603467(
    name: "untagResource20161125", meth: HttpMethod.HttpPost,
    host: "cloudfront.amazonaws.com",
    route: "/2016-11-25/tagging#Operation=Untag&Resource",
    validator: validate_UntagResource20161125_603468, base: "/",
    url: url_UntagResource20161125_603469, schemes: {Scheme.Https, Scheme.Http})
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
